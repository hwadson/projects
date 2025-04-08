
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE rsh.sp_COLSTAT_SSIS 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	set transaction isolation level read uncommitted; 

    -- Insert statements for procedure here






/***************************************************************************************************************
                    DROP TABLE CHECK
***************************************************************************************************************/

DROP TABLE IF EXISTS #component ;           --lab components
DROP TABLE IF EXISTS #medlist ;             --colchicine/rosuvastatin
DROP TABLE IF EXISTS #list ;                --patient/encounter list
DROP TABLE IF EXISTS #icu ;                 --ICU stays
DROP TABLE IF EXISTS #vent ;                --vent episodes
DROP TABLE IF EXISTS #dialysis ;            --dialysis orders
DROP TABLE IF EXISTS #labs ;                --all labs from encounter
DROP TABLE IF EXISTS #labsum ;              --summary of creatinine/ALT/AST/troponin
DROP TABLE IF EXISTS #mar ;                 --all med admins from encounter
DROP TABLE IF EXISTS #medsum ;              --summary of colchicine/rosuvastatin admins
DROP TABLE IF EXISTS #vitals ;              --BP/pulse/Sp02/resp/weight/height
DROP TABLE IF EXISTS #dx0 ;                 --all diagnoses (all time)
DROP TABLE IF EXISTS #dx ;                  --#dx0 summarized/flagged by DX source
DROP TABLE IF EXISTS #dxsum ;               --#dx summarized by first/last date
DROP TABLE IF EXISTS #dxsumicd ;            --#dx summarized by first/last date and ICD (rather than DX_ID)
DROP TABLE IF EXISTS #socialhx ;            --all social history indicating smoking status
DROP TABLE IF EXISTS #smokingcurrent ;      --current smoking status
DROP TABLE IF EXISTS #smokingenc ;          --smoking status at time of encounter
DROP TABLE IF EXISTS #advevent ;            --adverse events from Research Adverse Event activity
DROP TABLE IF EXISTS #sofa ;                --all SOFA scores from encounter


/***************************************************************************************************************
                    REF
***************************************************************************************************************/

/*  2021-02-03: Adding components for which they want baseline and max (creatinine, troponin, ALT, AST). I
    found two types of troponin -- troponin I and troponin T -- and am not sure which one is correct. I'm 
    checking, but I'll also make subgroups so I can report those separately for clarity.    
    
    2021-02-08: Adding reference for colchicine and rosuvastatin meds.                                      */

----------------drop table #component
SELECT          CASE WHEN cc.BASE_NAME = 'CREATININE'               THEN 'CREATININE'
                     WHEN cc.BASE_NAME IN ('TROPONINI','TROPONINT') THEN 'TROPONIN'
                     WHEN cc.BASE_NAME = 'ALT'                      THEN 'ALT'
                     WHEN cc.BASE_NAME = 'AST'                      THEN 'AST'
                     ELSE NULL END  'COMPONENT_GROUP',
                CASE WHEN cc.BASE_NAME = 'CREATININE'               THEN 'CREATININE'
                     WHEN cc.BASE_NAME = 'TROPONINI'                THEN 'TROPONIN_I'
                     WHEN cc.BASE_NAME = 'TROPONINT'                THEN 'TROPONIN_T'
                     WHEN cc.BASE_NAME = 'ALT'                      THEN 'ALT'
                     WHEN cc.BASE_NAME = 'AST'                      THEN 'AST'
                     ELSE NULL END  'COMPONENT_SUBGROUP',
                cc.*

INTO            #component

FROM            Clarity.dbo.CLARITY_COMPONENT cc

WHERE           cc.BASE_NAME IN (
                             ----Creatinine
                                 'CREATININE',

                             ----Troponin
                                'TROPONINI', --[2021-02-03: not sure of difference]
                                'TROPONINT', --[2021-02-03: not sure of difference]

                             ----Alanine aminotransferase (ALT)
                                'ALT',

                             ----Aspartate aminotransferase (AST)
                                'AST')

----------------drop table #medlist     --[2021-02-08] colchicine/rosuvastatin
SELECT          CASE 
                  ---Colchicine
                     WHEN cm.NAME         LIKE '%COLCHICINE%'
                       OR cm.GENERIC_NAME LIKE '%COLCHICINE%'
                       OR zg.NAME         LIKE '%COLCHICINE%'
                       OR rx2.SHORT_NAME  LIKE '%COLCHICINE%'
                       OR cm.NAME         LIKE '%MITIGARE%'
                       OR rx2.SHORT_NAME  LIKE '%MITIGARE%'
                       OR cm.NAME         LIKE '%COLCRYS%'
                       OR rx2.SHORT_NAME  LIKE '%COLCRYS%'
                    THEN 'C'

                  ---Rosuvastatin
                     WHEN cm.NAME         LIKE '%ROSUVASTATIN%'
                       OR cm.GENERIC_NAME LIKE '%ROSUVASTATIN%'
                       OR zg.NAME         LIKE '%ROSUVASTATIN%'
                       OR rx2.SHORT_NAME  LIKE '%ROSUVASTATIN%'
                       OR cm.NAME         LIKE '%CRESTOR%'
                       OR rx2.SHORT_NAME  LIKE '%CRESTOR%'
                    THEN 'R'
                    ELSE NULL END       'MED_GROUP',        --[2021-02-08]

                CASE WHEN cm.NAME LIKE 'HIC 2000027950%'
                    THEN 1 ELSE 0 END   'STUDY_DRUG_YN',    --[2021-02-08]

                cm.MEDICATION_ID,
                cm.NAME                 'MEDICATION_NAME',
                rx2.SHORT_NAME,
                cm.GENERIC_NAME,
                cm.SIMPLE_GENERIC_C,
                zg.NAME                 'SIMPLE_GENERIC',
                zt.THERA_CLASS_C,
                zt.NAME                 'THERA_CLASS',
                zp.PHARM_CLASS_C,
                zp.NAME                 'PHARM_CLASS',
                zs.PHARM_SUBCLASS_C,
                zs.NAME                 'PHARM_SUBCLASS',

                cm.GPI,                     --Generic Product Identifier for the medication: first line of Item ERX 210.
                cm.STRENGTH,
                cm.CONTROLLED_MED_YN,       --Y (Yes) if the DEA has designated this medication as a controlled substance; otherwise N (No)
                cm.DEA_CLASS_CODE_C,        --DEA Controlled Substance Code, which indicates this drug�s abuse and dependency potentials
                zdc.NAME                'DEA_CLASS_CODE',
                cm.INVESTIGATL_MED_YN,      --Y (Yes) if this medication is considered to be investigational; otherwise N (No)

                rx1.GROUPER_ID,             --ERX ID of the non-specific medication record for this medication [this is a MEDICATION, not a grouper]
                cmg.NAME                'GROUPER_MED_NAME',
                rx2.FORM_C,                 --Form for each unit dose of this medication
                zf.NAME                 'FORM',
                rx2.ADMIN_ROUTE_C,
                zar.NAME                'ADMIN_ROUTE',
                rx2.DISCRETE_DOSE,          --Default dose
                rx2.DISCRETE_STR_UNITS,
                rx2.DEFAULT_FREQ_ID,
                frq.FREQ_NAME           'DEFAULT_FREQ_NAME',
                frq.DISPLAY_NAME        'DEFAULT_FREQ_DISPLAY_NAME',
                rx2.MED_UNIT_C,             --Medication unit
                zum.NAME                'MED_UNIT',
                rx2.DISPENSE_UNIT_C,        --Unit in which the medication will be dispensed
                zud.NAME                'DISPENSE_UNIT',
                rx2.ADMIN_UNIT_C,           --Unit in which the medication is administered
                zua.NAME                'ADMIN_UNIT',
                rx2.SPECIAL_MED_TYPE_C,     --Type of the medication (non-specific, orderable, simple generic, blood-transfuse, etc.)
                zst.NAME                'SPECIAL_MED_TYPE',
                rx3.RECORD_STATE_C,         --Indicates if the medication is inactive, deleted, or hidden (NULL also = active)
                zds.NAME                'RECORD_STATE'

INTO            #medlist

FROM            Clarity.dbo.CLARITY_MEDICATION  cm
    LEFT JOIN   Clarity.dbo.ZC_SIMPLE_GENERIC   zg  ON  zg.SIMPLE_GENERIC_C     =   cm.SIMPLE_GENERIC_C
    LEFT JOIN   Clarity.dbo.ZC_THERA_CLASS      zt  ON  zt.THERA_CLASS_C        =   cm.THERA_CLASS_C
    LEFT JOIN   Clarity.dbo.ZC_PHARM_CLASS      zp  ON  zp.PHARM_CLASS_C        =   cm.PHARM_CLASS_C
    LEFT JOIN   Clarity.dbo.ZC_PHARM_SUBCLASS   zs  ON  zs.PHARM_SUBCLASS_C     =   cm.PHARM_SUBCLASS_C
    LEFT JOIN   Clarity.dbo.ZC_DEA_CLASS_CODE   zdc ON  zdc.DEA_CLASS_CODE_C    =   cm.DEA_CLASS_CODE_C

    LEFT JOIN   Clarity.dbo.RX_MED_ONE          rx1 ON  rx1.MEDICATION_ID       =   cm.MEDICATION_ID
    LEFT JOIN   Clarity.dbo.CLARITY_MEDICATION  cmg ON  cmg.MEDICATION_ID       =   rx1.GROUPER_ID  --actually a medication (not a grouper)

    LEFT JOIN   Clarity.dbo.RX_MED_TWO          rx2 ON  rx2.MEDICATION_ID       =   cm.MEDICATION_ID
    LEFT JOIN   Clarity.dbo.ZC_FORM             zf  ON  zf.FORM_C               =   rx2.FORM_C
    LEFT JOIN   Clarity.dbo.ZC_ADMIN_ROUTE      zar ON  zar.MED_ROUTE_C         =   rx2.ADMIN_ROUTE_C
    LEFT JOIN   Clarity.dbo.IP_FREQUENCY        frq ON  frq.FREQ_ID             =   rx2.DEFAULT_FREQ_ID
    LEFT JOIN   Clarity.dbo.ZC_MED_UNIT         zum ON  zum.DISP_QTYUNIT_C      =   rx2.MED_UNIT_C
    LEFT JOIN   Clarity.dbo.ZC_MED_UNIT         zud ON  zud.DISP_QTYUNIT_C      =   rx2.DISPENSE_UNIT_C
    LEFT JOIN   Clarity.dbo.ZC_MED_UNIT         zua ON  zua.DISP_QTYUNIT_C      =   rx2.ADMIN_UNIT_C
    LEFT JOIN   Clarity.dbo.ZC_ERX_SP_MED_TYPE  zst ON  zst.ERX_SP_MED_TYPE_C   =   rx2.SPECIAL_MED_TYPE_C

    LEFT JOIN   Clarity.dbo.RX_MED_THREE        rx3 ON  rx3.MEDICATION_ID       =   cm.MEDICATION_ID
    LEFT JOIN   Clarity.dbo.ZC_DEL_STATUS       zds ON  zds.DEL_STATUS_C        =   rx3.RECORD_STATE_C

WHERE           
    ------------Colchicine
                cm.NAME         LIKE '%COLCHICINE%'
    OR          cm.GENERIC_NAME LIKE '%COLCHICINE%'
    OR          zg.NAME         LIKE '%COLCHICINE%'
    OR          rx2.SHORT_NAME  LIKE '%COLCHICINE%'
    OR          cm.NAME         LIKE '%MITIGARE%'
    OR          rx2.SHORT_NAME  LIKE '%MITIGARE%'
    OR          cm.NAME         LIKE '%COLCRYS%'
    OR          rx2.SHORT_NAME  LIKE '%COLCRYS%'

    ------------Rosuvastatin
    OR          cm.NAME         LIKE '%ROSUVASTATIN%'
    OR          cm.GENERIC_NAME LIKE '%ROSUVASTATIN%'
    OR          zg.NAME         LIKE '%ROSUVASTATIN%'
    OR          rx2.SHORT_NAME  LIKE '%ROSUVASTATIN%'
    OR          cm.NAME         LIKE '%CRESTOR%'
    OR          rx2.SHORT_NAME  LIKE '%CRESTOR%'


/***************************************************************************************************************
                    PATIENT/ENCOUNTER LIST
***************************************************************************************************************/

/*  2021-01-05: First going to get initial list of patients and associated encounters along with time of first
    consent (we may need only variables after that time). I can't find a direct link to the CSN in which the
    patient was consented, but, because they're all inpatients, I'm going to just find the primary CSN for the
    hospital encounter at the time of consent. Will not need all the details here, but figure I may as well
    start pulling them in. (May make this into a proc that updates the table.)                              */

----------------drop table #list
SELECT      
            ----Patient info
                p.PAT_ID,
                p.PAT_MRN_ID,
                p.PAT_NAME,
                CAST(p.BIRTH_DATE AS DATE)                      'BIRTH_DATE',
                CAST(p.DEATH_DATE AS DATE)                      'DEATH_DATE',
                radb.dbo.Age_Years(CAST(p.BIRTH_DATE AS DATE),CAST(COALESCE(p.DEATH_DATE,GETDATE()) AS DATE))
                                                                'AGE_DEATH_OR_RUN_DATE',
                p.SEX_C,
                zsx.NAME                                        'SEX',
            --  p.ETHNIC_GROUP_C,
            --  zeg.NAME                                        'ETHNICITY',
            --  pr.PATIENT_RACE_C,
            --  zpr.NAME                                        'PRIMARY_RACE',
            --  xa.PATIENT_RACE_ALL,            
                pr.PATIENT_ETHNICITY,
                pr.ETHNICITY_HISPANIC_OR_LATINO_YN,
                pr.ETHNICITY_NON_HISPANIC_YN,
                pr.ETHNICITY_UNKNOWN_YN,
                pr.PATIENT_RACE_ALL,
                pr.MULTI_RACIAL_YN,
                pr.RACE_AMERICAN_INDIAN_OR_ALASKA_NATIVE_YN,
                pr.RACE_ASIAN_YN,
                pr.RACE_BLACK_OR_AFRICAN_AMERICAN_YN,
                pr.RACE_NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER_YN,
                pr.RACE_OTHER_YN,
                pr.RACE_WHITE_OR_CAUCASIAN_YN,
                pr.RACE_UNKNOWN_YN,
                el.EDU_LEVEL_C,
                el.EDU_LEVEL,
                ey.YEARS_EDUCATION,

            ----Enrollment info
                pre.LINE,
                pre.ENROLLMENT_ID,
                ei.STUDY_BRANCH_ID, --[2021-02-03]
                ei.RESEARCH_STUDY_ID,
                rsh.RESEARCH_NAME                               'RESEARCH_STUDY_NAME',
                rsh.STUDY_CODE,
                rsh.IRB_APPROVAL_NUM,
                rsh.RESEARCH_STATUS_C,
                zrs.NAME                                        'RESEARCH_STUDY_STATUS', --for STUDY, not patient
                ei.ENROLL_STATUS_C,
                zes.NAME                                        'ENROLL_STATUS',
                CAST(ei.ENROLL_START_DT AS DATE)                'ENROLL_START_DT',
                CAST(ei.ENROLL_END_DT AS DATE)                  'ENROLL_END_DATE',
                CONVERT(VARCHAR(16),c.FIRST_CONSENTED_DTTM,20)  'FIRST_CONSENTED_DTTM',
                CAST(c.FIRST_CONSENTED_DTTM AS DATE)            'FIRST_CONSENTED_DATE',

            ----Encounter info
                peh.HSP_ACCOUNT_ID,
                peh.PAT_ENC_CSN_ID,
                peh.PAT_ENC_DATE_REAL,
                peh.INPATIENT_DATA_ID,
                peh.ED_EPISODE_ID,
                CONVERT(VARCHAR(16),peh.HOSP_ADMSN_TIME,20)     'HOSP_ADMSN_TIME',
                CAST(peh.HOSP_ADMSN_TIME AS DATE)               'HOSP_ADMSN_DATE',
                CONVERT(VARCHAR(16),peh.HOSP_DISCH_TIME,20)     'HOSP_DISCH_TIME',
                CAST(peh.HOSP_DISCH_TIME AS DATE)               'HOSP_DISCH_DATE',
                CONVERT(VARCHAR(16),peh.ADT_ARRIVAL_TIME,20)    'ADT_ARRIVAL_TIME',
                CAST(peh.ADT_ARRIVAL_TIME AS DATE)              'ADT_ARRIVAL_DATE',
                CONVERT(VARCHAR(16),peh.EMER_ADM_DATE,20)       'EMER_ADM_TIME',
                CAST(peh.EMER_ADM_DATE AS DATE)                 'EMER_ADM_DATE',
                CONVERT(VARCHAR(16),peh.OP_ADM_DATE,20)         'OP_ADM_TIME',
                CAST(peh.OP_ADM_DATE AS DATE)                   'OP_ADM_DATE',
                CONVERT(VARCHAR(16),peh.INP_ADM_DATE,20)        'INP_ADM_TIME',
                CAST(peh.INP_ADM_DATE AS DATE)                  'INP_ADM_DATE',
                CONVERT(VARCHAR(16),peh.ED_DEPARTURE_TIME,20)   'ED_DEPARTURE_TIME',
                CAST(peh.ED_DEPARTURE_TIME AS DATE)             'ED_DEPARTURE_DATE',
                peh.HOSPITAL_AREA_ID,
                cl.LOC_NAME                                     'HOSPITAL_AREA_NAME',
                peh.DEPARTMENT_ID                               'ENC_DEPT_ID', --last department patient was in
                cd.DEPARTMENT_NAME                              'ENC_DEPT',
                cd.EXTERNAL_NAME                                'ENC_DEPT_EXTERNAL_NAME',
                cd.SPECIALTY                                    'ENC_DEPT_SPECIALTY',
                ha.ACCT_BASECLS_HA_C,
                zbc.NAME                                        'ACCT_BASECLS_HA',
                ha.ACCT_CLASS_HA_C,
                zch.NAME                                        'ACCT_CLASS_HA',
                peh.ADT_PAT_CLASS_C,
                zpc.NAME                                        'ADT_PAT_CLASS',
                ha.PRIM_SVC_HA_C,
                zsv.NAME                                        'PRIM_SVC_HA',
                peh.ADMIT_SOURCE_C,
                zas.NAME                                        'ADMIT_SOURCE',
                peh.ED_DISPOSITION_C,
                zed.NAME                                        'ED_DISPOSITION',
                peh.DISCH_DISP_C,
                zdd.NAME                                        'DISCH_DISP'

INTO            #list

FROM            Clarity.dbo.PATIENT             p
    INNER JOIN  Clarity.dbo.VALID_PATIENT       vp  ON  vp.PAT_ID               =   p.PAT_ID
                                                    AND vp.IS_VALID_PAT_YN      =   'Y'
    INNER JOIN  radb.rsh.PatientRaceEthnicity   pr  ON  pr.PAT_ID               =   p.PAT_ID

    ------------Study enrollment details
    INNER JOIN  Clarity.dbo.PAT_RSH_ENROLL      pre ON  pre.PAT_ID              =   p.PAT_ID
    INNER JOIN  Clarity.dbo.ENROLL_INFO         ei  ON  ei.ENROLL_ID            =   pre.ENROLLMENT_ID
    INNER JOIN  Clarity.dbo.CLARITY_RSH         rsh ON  rsh.RESEARCH_ID         =   ei.RESEARCH_STUDY_ID
                                                    AND rsh.RESEARCH_ID         =   3853    --COLSTAT Covid
    INNER JOIN  Clarity.dbo.ZC_RESEARCH_STATUS  zrs ON  zrs.RESEARCH_STATUS_C   =   rsh.RESEARCH_STATUS_C
    INNER JOIN  Clarity.dbo.ZC_ENROLL_STATUS    zes ON  zes.ENROLL_STATUS_C     =   ei.ENROLL_STATUS_C

    ------------First consented time
    OUTER APPLY (
                    SELECT  MIN(x.HX_MOD_DTTM) 'FIRST_CONSENTED_DTTM'
                    FROM    Clarity.dbo.ENROLL_INFO_HX x
                    WHERE   x.ENROLL_ID = ei.ENROLL_ID
                        AND x.HX_MOD_STATUS_C = 1100 --Consented
                )                               c

    ------------Encounter details
    INNER JOIN  Clarity.dbo.PAT_ENC_HSP         peh ON  peh.PAT_ID              =   p.PAT_ID
                                                    AND peh.HOSP_ADMSN_TIME     <=  c.FIRST_CONSENTED_DTTM
                                                    AND ISNULL(peh.HOSP_DISCH_TIME,GETDATE())
                                                                                >=  c.FIRST_CONSENTED_DTTM
    INNER JOIN  Clarity.dbo.HSP_ACCOUNT         ha  ON  ha.HSP_ACCOUNT_ID       =   peh.HSP_ACCOUNT_ID
                                                    AND ha.PRIM_ENC_CSN_ID      =   peh.PAT_ENC_CSN_ID --primary CSN
    LEFT JOIN   Clarity.dbo.CLARITY_LOC         cl  ON  cl.LOC_ID               =   peh.HOSPITAL_AREA_ID
    LEFT JOIN   Clarity.dbo.CLARITY_DEP         cd  ON  cd.DEPARTMENT_ID        =   peh.DEPARTMENT_ID
    LEFT JOIN   Clarity.dbo.ZC_ACCT_BASECLS_HA  zbc ON  zbc.ACCT_BASECLS_HA_C   =   ha.ACCT_BASECLS_HA_C
    LEFT JOIN   Clarity.dbo.ZC_ACCT_CLASS_HA    zch ON  zch.ACCT_CLASS_HA_C     =   ha.ACCT_CLASS_HA_C
    LEFT JOIN   Clarity.dbo.ZC_PAT_CLASS        zpc ON  zpc.ADT_PAT_CLASS_C     =   peh.ADT_PAT_CLASS_C
    LEFT JOIN   Clarity.dbo.ZC_ER_PAT_STS_HA    zep ON  zep.ER_PAT_STS_HA_C     =   ha.ER_PAT_STS_HA_C
    LEFT JOIN   Clarity.dbo.ZC_PAT_SERVICE      zsv ON  zsv.HOSP_SERV_C         =   ha.PRIM_SVC_HA_C
    LEFT JOIN   Clarity.dbo.ZC_ADM_SOURCE       zas ON  zas.ADMIT_SOURCE_C      =   peh.ADMIT_SOURCE_C
    LEFT JOIN   Clarity.dbo.ZC_DISCH_DISP       zdd ON  zdd.DISCH_DISP_C        =   peh.DISCH_DISP_C
    LEFT JOIN   Clarity.dbo.ZC_ED_DISPOSITION   zed ON  zed.ED_DISPOSITION_C    =   peh.ED_DISPOSITION_C

    ------------Patient details
--  LEFT JOIN   Clarity.dbo.PATIENT_RACE        pr  ON  pr.PAT_ID               =   p.PAT_ID
--                                                  AND pr.LINE                 =   1   --primary
--  LEFT JOIN   Clarity.dbo.ZC_PATIENT_RACE     zpr ON  zpr.PATIENT_RACE_C      =   pr.PATIENT_RACE_C
    LEFT JOIN   Clarity.dbo.ZC_SEX              zsx ON  zsx.RCPT_MEM_SEX_C      =   p.SEX_C
--  LEFT JOIN   Clarity.dbo.ZC_ETHNIC_GROUP     zeg ON  zeg.ETHNIC_GROUP_C      =   p.ETHNIC_GROUP_C

    ------------[2020-01-05] Education level/years (if available)
    OUTER APPLY (
                    SELECT TOP 1 x.EDU_LEVEL_C, z.NAME 'EDU_LEVEL'
                    FROM    Clarity.dbo.SOCIAL_HX    x
                    JOIN    Clarity.dbo.ZC_EDU_LEVEL z ON z.EDU_LEVEL_C = x.EDU_LEVEL_C
                    WHERE   x.PAT_ID = p.PAT_ID
                        AND x.EDU_LEVEL_C IS NOT NULL
                        AND x.CONTACT_DATE <= COALESCE(peh.HOSP_DISCH_TIME,GETDATE())
                    ORDER BY x.PAT_ENC_DATE_REAL DESC --most recent
                )                               el

    OUTER APPLY (
                    SELECT TOP 1 x.YEARS_EDUCATION
                    FROM    Clarity.dbo.SOCIAL_HX    x
                    JOIN    Clarity.dbo.ZC_EDU_LEVEL z ON z.EDU_LEVEL_C = x.EDU_LEVEL_C
                    WHERE   x.PAT_ID = p.PAT_ID
                        AND x.YEARS_EDUCATION IS NOT NULL
                        AND x.CONTACT_DATE <= COALESCE(peh.HOSP_DISCH_TIME,GETDATE())
                    ORDER BY x.PAT_ENC_DATE_REAL DESC --most recent
                )                               ey

    -------------[2021-01-20] All 
    CROSS APPLY (
                    SELECT
                        STUFF((
                                SELECT  '; ' + z.NAME
                                FROM    Clarity.dbo.PATIENT_RACE    x
                                JOIN    Clarity.dbo.ZC_PATIENT_RACE z ON z.PATIENT_RACE_C = x.PATIENT_RACE_C
                                WHERE   x.PAT_ID = p.PAT_ID
                                ORDER BY z.NAME
                                FOR XML PATH, TYPE).value(N'.[1]', N'nvarchar(max)')
                            ,1,2,'') 'PATIENT_RACE_ALL'
                )                               xa (PATIENT_RACE_ALL)

--  SELECT * FROM #list l ORDER BY l.PAT_ID, l.HOSP_ADMSN_TIME


/***************************************************************************************************************
                    ICU
***************************************************************************************************************/

/*  2021-01-29: Think all they really want for now is the 'adverse outcomes,' which includes ICU. I am using
    the ICU data mart and will flag whether the ICU start time was after the first consented time (but report
    overall + if they went to the ICU after consented).                                                     */

----------------drop table #icu
SELECT          e.PAT_ID,
                e.PAT_MRN_ID,
                e.BIRTH_DATE,
                e.DEATH_DATE,
                e.AGE_DEATH_OR_RUN_DATE,
                e.HSP_ACCOUNT_ID,
                e.PAT_ENC_CSN_ID,
                e.ED_EPISODE_ID,
                e.HOSP_ADMSN_TIME,
                e.HOSP_DISCH_TIME,
                e.FIRST_CONSENTED_DTTM,
    
            ----ICU stay(s) 
                ROW_NUMBER() OVER (PARTITION BY e.PAT_ENC_CSN_ID ORDER BY icu.ICU_STAY_START_DTTM)
                                            'ICU_LINE', --can have multiple admission blocks
                CASE WHEN icu.ICU_STAY_START_DTTM > e.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END       'AFTER_CONSENTED_YN',
                icu.RECORD_ID,
                icu.ICU_STAY_BLOCK_ID,
                icu.ICU_LENGTH_OF_STAY_DAYS,
                icu.DEPARTMENT_ID           'ICU_DEPARTMENT_ID',
                cdc.DEPARTMENT_NAME         'ICU_DEPARTMENT_NAME',
                icu.PREV_DEPARTMENT_ID,
                cdp.DEPARTMENT_NAME         'PREV_DEPARTMENT_NAME',
                icu.PREV_ICU_DEPARTMENT_ID,
                cdi.DEPARTMENT_NAME         'PREV_ICU_DEPARTMENT_NAME',
                icu.NEXT_DEPARTMENT_ID,
                cdn.DEPARTMENT_NAME         'NEXT_DEPARTMENT_NAME',
                icu.IS_ICU_READMISSION_BOOL,
                icu.READMIT_IN_5_DAYS_BOOL,
                icu.ICU_STAY_START_DTTM,
                icu.ICU_STAY_END_DTTM,
                icu.CROSS_ICU_STAY_START_DTTM,
                icu.CROSS_ICU_STAY_END_DTTM,
            --  icu.PRIMARY_ADMISSION_DX_ID,    --this does not match what I found above on HSP_ACCOUNT_ADMIT_DX...? at all?
                ce.CURRENT_ICD9_LIST        'PRIMARY_ADMISSION_DX_ICD9_CODES',
                ce.CURRENT_ICD10_LIST       'PRIMARY_ADMISSION_DX_ICD10_CODES',
                ce.DX_ID                    'PRIMARY_ADMISSION_DX_ID',
                ce.DX_NAME                  'PRIMARY_ADMISSION_DX_NAME',
            --  e.PRIMARY_ADMIT_DX_ID,
            --  e.PRIMARY_ADMIT_DX_NAME,
            --  e.SECONDARY_ADMIT_DX_ID,
            --  e.TERTIARY_ADMIT_DX_ID,
                icu.ICU_LAST_READMIT_RISK_SCORE,
                icu.ICU_LAST_MORTALITY_RISK_SCORE

INTO            #icu

FROM            #list                   e
    INNER JOIN  Clarity.dbo.DM_ICU_STAY icu ON  icu.PAT_ENC_CSN_ID  =   e.PAT_ENC_CSN_ID
    LEFT JOIN   Clarity.dbo.CLARITY_DEP cdc ON  cdc.DEPARTMENT_ID   =   icu.DEPARTMENT_ID
    LEFT JOIN   Clarity.dbo.CLARITY_DEP cdp ON  cdp.DEPARTMENT_ID   =   icu.PREV_DEPARTMENT_ID
    LEFT JOIN   Clarity.dbo.CLARITY_DEP cdi ON  cdi.DEPARTMENT_ID   =   icu.PREV_ICU_DEPARTMENT_ID
    LEFT JOIN   Clarity.dbo.CLARITY_DEP cdn ON  cdn.DEPARTMENT_ID   =   icu.NEXT_DEPARTMENT_ID
    LEFT JOIN   Clarity.dbo.CLARITY_EDG ce  ON  ce.DX_ID            =   icu.PRIMARY_ADMISSION_DX_ID


/***************************************************************************************************************
                    VENT
***************************************************************************************************************/

/*  2021-01-29: Adding this for the adverse events data -- they requested intubation but I believe intubation
    always means vent and vice versa. Soundari does have a VENT_YN column in [RSH_COVID19_INPAT_TREATMENT],
    but not all these patients are in there for some reason (also, I want to flag whether it started/ended
    after the first consented time).                                                                        */

----------------drop table #vent
SELECT          e.PAT_ID,
                e.PAT_MRN_ID,
                e.FIRST_CONSENTED_DTTM,
                e.PAT_ENC_CSN_ID,
                e.INPATIENT_DATA_ID,
                e.HOSP_ADMSN_TIME,
                e.HOSP_DISCH_TIME,
                v.ASSUMED_VENT_START_DTTM,
                v.ASSUMED_VENT_END_DTTM,
                
                CASE WHEN v.ASSUMED_VENT_START_DTTM >= e.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END   'START_AFTER_CONSENTED_YN',
                CASE WHEN ISNULL(v.ASSUMED_VENT_END_DTTM,GETDATE()) >= e.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END   'END_AFTER_CONSENTED_YN'

INTO            #vent

FROM            #list                       e
    INNER JOIN  Clarity.dbo.F_VENT_EPISODES v   ON  v.PAT_ID            =   e.PAT_ID
                                                AND v.INPATIENT_DATA_ID =   e.INPATIENT_DATA_ID


/***************************************************************************************************************
                    HEMODIALYSIS
***************************************************************************************************************/

/*  2021-02-03: Not entirely sure this is the best way to get at it, but I'm flagging hemodialysis based on an
    order type of [46] DIALYSIS with an associated proc start/end time. One thing I'm not sure of is whether
    dialysis gets its own CSN under the same hospital account (like surgery) -- will assume 'maybe' and  join
    on hospital account rather than CSN. Currently getting none from this encounter list.                   */

----------------drop table #dialysis    --[2021-02-03]
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.PAT_ENC_CSN_ID,
                op.ORDER_PROC_ID,
                op.PROC_ID,
                op.DESCRIPTION,
                CASE WHEN op.ORDER_INST > l.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END                       'ORDERED_AFTER_CONSENTED_YN',
                CASE WHEN op.PROC_START_TIME > l.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END                       'STARTED_AFTER_CONSENTED_YN',
                CONVERT(VARCHAR(16),op.ORDER_INST,20)       'ORDER_INST',
                CONVERT(VARCHAR(16),op.PROC_START_TIME,20)  'PROC_START_TIME',
                CONVERT(VARCHAR(16),op.PROC_ENDING_TIME,20) 'PROC_ENDING_TIME'              

INTO            #dialysis

FROM            #list                   l
    INNER JOIN  Clarity.dbo.PAT_ENC_HSP peh ON  peh.HSP_ACCOUNT_ID  =   l.HSP_ACCOUNT_ID
    INNER JOIN  Clarity.dbo.ORDER_PROC  op  ON  op.PAT_ENC_CSN_ID   =   peh.PAT_ENC_CSN_ID

WHERE           op.ORDER_TYPE_C = 46 --DIALYSIS
    AND         op.PROC_START_TIME  IS NOT NULL
    AND         op.PROC_ENDING_TIME IS NOT NULL


/***************************************************************************************************************
                    LABS
***************************************************************************************************************/

/*  2021-01-20: Same as above -- going to get all the labs and flag whether they were ordered/collected/etc.
    after the consented date/time.                                                                          

    2021-02-03: Think they're going to be getting most of the lab data elsewhere, but they do want baseline and
    max for some components (creatinine, troponin, ALT, AST), so I'll find those here. I found two types of
    troponin -- troponin I and troponin T -- and am not sure which one is correct. I'm  checking, but I'll also
    make subgroups so I can report those separately for clarity.    
    
    Some values are coming in as, e.g., '<0.1,' which doesn't have an associated numeric value. What I'm going
    to do for the purpose of finding the max value is tweak the numeric value column and not include 9999999.
    For the values that are a '<,' I'll convert that to a numeric value that is just slightly lower than the
    value that it's 'less than,' but then actually report the regular ORD_VALUE so it's clear that the number
    I'm using for calculation isn't a real measured value.                                                  */

----------------drop table #labs
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.BIRTH_DATE,
                l.ENROLLMENT_ID,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
                l.FIRST_CONSENTED_DATE,
                l.HSP_ACCOUNT_ID,
                l.PAT_ENC_CSN_ID,
                l.HOSP_ADMSN_TIME,
                l.HOSP_DISCH_TIME,

            ----Order/result info
                op.ORDER_PROC_ID,
                CAST(op.ORDERING_DATE AS DATE)          'ORDERING_DATE',
                CONVERT(VARCHAR(16),op.ORDER_INST,20)   'ORDER_INST',
                CASE WHEN op.ORDER_INST >= l.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END                   'ORDERED_AFTER_CONSENT_DTTM_YN',
                CASE WHEN op.ORDERING_DATE >= l.FIRST_CONSENTED_DATE
                    THEN 1 ELSE 0 END                   'ORDERED_AFTER_CONSENT_DATE_YN',
                CAST(op2.SPECIMN_TAKEN_TIME AS DATE)    'SPECIMN_TAKEN_DATE',
                CONVERT(VARCHAR(16),op2.SPECIMN_TAKEN_TIME,20)
                                                        'SPECIMN_TAKEN_TIME',
                CASE WHEN op2.SPECIMN_TAKEN_TIME >= l.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END                   'SPECIMEN_AFTER_CONSENT_DTTM_YN',
                CASE WHEN CAST(op2.SPECIMN_TAKEN_TIME AS DATE) >= l.FIRST_CONSENTED_DATE
                    THEN 1 ELSE 0 END                   'SPECIMEN_AFTER_CONSENT_DATE_YN',
                CAST(orr.RESULT_TIME AS DATE)           'RESULT_DATE',
                CONVERT(VARCHAR(16),orr.RESULT_TIME,20) 'RESULT_TIME',
                CASE WHEN orr.RESULT_TIME >= l.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END                   'RESULT_AFTER_CONSENT_DTTM_YN',
                CASE WHEN CAST(orr.RESULT_TIME AS DATE) >= l.FIRST_CONSENTED_DATE
                    THEN 1 ELSE 0 END                   'RESULT_AFTER_CONSENT_DATE_YN',
                op.ORDER_TYPE_C,
                zot.NAME                                'ORDER_TYPE',
                zt.NAME                                 'SPECIMEN_TYPE',
                ce.PROC_ID,
                ce.PROC_NAME,
                op.DISPLAY_NAME,
                op.ABNORMAL_YN, 
                orr.LINE                                'RESULT_LINE',  --as there can be more than one result per order
                c.COMPONENT_GROUP,      --[2021-02-03]
                c.COMPONENT_SUBGROUP,   --[2021-02-03]
                cc.COMPONENT_ID,    
                cc.NAME                                 'COMPONENT_NAME',
                cc.COMMON_NAME,
                cc.BASE_NAME,
                orr.ORD_VALUE,
                orr.ORD_NUM_VALUE                       'ORD_NUM_VALUE_RAW',                
                CASE WHEN orr.ORD_VALUE LIKE '<%' THEN TRY_CAST(REPLACE(orr.ORD_VALUE,'<','') AS NUMERIC(18,10)) - 0.00000001
                     WHEN orr.ORD_VALUE LIKE '>%' THEN TRY_CAST(REPLACE(orr.ORD_VALUE,'>','') AS NUMERIC(18,10)) + 0.00000001
                     WHEN orr.ORD_NUM_VALUE = 9999999 THEN NULL
                     ELSE orr.ORD_NUM_VALUE END         'ORD_NUM_VALUE',    --[2021-02-03 -- notes in section header]
                orr.RESULT_FLAG_C,                      
                zrf.NAME                                'RESULT_FLAG',
                orr.REFERENCE_UNIT,                     
                orr.COMPONENT_COMMENT

INTO            #labs 

FROM            #list                           l
    INNER JOIN  Clarity.dbo.ORDER_PROC          op  ON  op.PAT_ENC_CSN_ID   =   l.PAT_ENC_CSN_ID
    INNER JOIN  Clarity.dbo.ORDER_RESULTS       orr ON  orr.ORDER_PROC_ID   =   op.ORDER_PROC_ID --[2021-01-20: for now, only doing resulted]
    INNER JOIN  Clarity.dbo.CLARITY_COMPONENT   cc  ON  cc.COMPONENT_ID     =   orr.COMPONENT_ID --[2021-05-18: changing to all labs]
    LEFT JOIN   #component                      c   ON  c.COMPONENT_ID      =   orr.COMPONENT_ID --[2021-02-03: troponin, ALT, AST, and creatinine)
    LEFT JOIN   Clarity.dbo.ORDER_PROC_2        op2 ON  op2.ORDER_PROC_ID   =   op.ORDER_PROC_ID 
    LEFT JOIN   Clarity.dbo.CLARITY_EAP         ce  ON  ce.PROC_ID          =   op.PROC_ID
    LEFT JOIN   Clarity.dbo.ZC_ORDER_TYPE       zot ON  zot.ORDER_TYPE_C    =   op.ORDER_TYPE_C
    LEFT JOIN   Clarity.dbo.ZC_SPECIMEN_TYPE    zt  ON  zt.SPECIMEN_TYPE_C  =   op.SPECIMEN_TYPE_C
    LEFT JOIN   Clarity.dbo.ZC_RESULT_FLAG      zrf ON  zrf.RESULT_FLAG_C   =   orr.RESULT_FLAG_C

WHERE           
    ------------[2021-02-08] Only results with a numeric value we can use
                (TRY_CAST(REPLACE(orr.ORD_VALUE,'<','') AS NUMERIC(18,10)) IS NOT NULL
                 OR TRY_CAST(REPLACE(orr.ORD_VALUE,'>','') AS NUMERIC(18,10)) IS NOT NULL) --[2021-03-03] changed to OR

----------------drop table #labsum  --[2021-02-03]
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.PAT_ENC_CSN_ID,
                cf.FIRST_CREATININE,
                ch.HIGHEST_CREATININE,
                atf.FIRST_ALT,
                ath.HIGHEST_ALT,
                asf.FIRST_AST,
                ash.HIGHEST_AST,
                tf.FIRST_TROPONIN,
                th.HIGHEST_TROPONIN,
                tif.FIRST_TROPONIN_I,
                tih.HIGHEST_TROPONIN_I,
                ttf.FIRST_TROPONIN_T,
                tth.HIGHEST_TROPONIN_T

INTO            #labsum

FROM            #list l
    
    ------------Creatinine
    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'FIRST_CREATININE'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_GROUP = 'CREATININE'
                    ORDER BY x.RESULT_TIME
                )     cf

    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'HIGHEST_CREATININE'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_GROUP = 'CREATININE'
                    ORDER BY x.ORD_NUM_VALUE DESC 
                )     ch

    ------------ALT
    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'FIRST_ALT'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_GROUP = 'ALT'
                    ORDER BY x.RESULT_TIME
                )     atf

    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'HIGHEST_ALT'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_GROUP = 'ALT'
                    ORDER BY x.ORD_NUM_VALUE DESC 
                )     ath

    ------------AST
    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'FIRST_AST'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_GROUP = 'AST'
                    ORDER BY x.RESULT_TIME
                )     asf

    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'HIGHEST_AST'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_GROUP = 'AST'
                    ORDER BY x.ORD_NUM_VALUE DESC 
                )     ash

    ------------Troponin - overall
    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'FIRST_TROPONIN'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_GROUP = 'TROPONIN'
                    ORDER BY x.RESULT_TIME
                )     tf

    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'HIGHEST_TROPONIN'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_GROUP = 'TROPONIN'
                    ORDER BY x.ORD_NUM_VALUE DESC 
                )     th

    ------------Troponin I
    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'FIRST_TROPONIN_I'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_SUBGROUP = 'TROPONIN_I'
                    ORDER BY x.RESULT_TIME
                )     tif

    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'HIGHEST_TROPONIN_I'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_SUBGROUP = 'TROPONIN_I'
                    ORDER BY x.ORD_NUM_VALUE DESC 
                )     tih

    ------------Troponin T
    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'FIRST_TROPONIN_T'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_SUBGROUP = 'TROPONIN_T'
                    ORDER BY x.RESULT_TIME
                )     ttf

    OUTER APPLY (
                    SELECT TOP 1 x.ORD_VALUE 'HIGHEST_TROPONIN_T'
                    FROM    #labs x
                    WHERE   x.PAT_ENC_CSN_ID  = l.PAT_ENC_CSN_ID
                        AND x.COMPONENT_SUBGROUP = 'TROPONIN_T'
                    ORDER BY x.ORD_NUM_VALUE DESC 
                )     tth


/***************************************************************************************************************
                    MEDICATIONS (ALL MAR RECORDS)
***************************************************************************************************************/

/*  2021-01-20: Going to just get the raw data about all medication orders/MAR records while in the hospital.
    I originally had the understanding that they only wanted the data points during the encounter but after
    they were consented, so I'll put a flag for that. Will also flag the study medications.             
    
    2021-02-08: Had taken this out because we ended up only needing to provide adverse event data; putting it
    back in because that now includes discontinuation of medication. I have no idea how to define that as I
    assume all patients will 'discontinue' at some point because they will have had the full course, but they
    really mean 'discontinued early.' They said everyone in the trial should receive the meds but also noted
    that in some cases a patient consented but ultimately they did nto give the meds for some reason. I told
    them I would provide a flag for each patient indicating whether I was able to find an admin for both meds
    as well as first/last time of administration. Will also put in reason for discontinue.                  */

/*
    SELECT  'l.' + c.name + ',' 'select'
    FROM    tempdb.sys.columns c
    WHERE   c.object_id = OBJECT_ID(N'tempdb.dbo.#list')
    ORDER BY c.column_id
*/

----------------drop table #mar
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.BIRTH_DATE,
                l.ENROLLMENT_ID,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
                l.FIRST_CONSENTED_DATE,
                l.HSP_ACCOUNT_ID,
                l.PAT_ENC_CSN_ID,
                l.HOSP_ADMSN_TIME,
                l.HOSP_DISCH_TIME,

            ----Medication order
                om.ORDER_MED_ID,
                CONVERT(VARCHAR(16),om.ORDER_INST,20)       'ORDER_INST',
                CAST(om.ORDERING_DATE AS DATE)              'ORDERING_DATE',
                CASE WHEN om.ORDER_INST >= l.FIRST_CONSENTED_DTTM
                    THEN 1 ELSE 0 END                       'ORDERED_AFTER_CONSENT_DTTM_YN',
                CASE WHEN om.ORDERING_DATE >= l.FIRST_CONSENTED_DATE
                    THEN 1 ELSE 0 END                       'ORDERED_AFTER_CONSENT_DATE_YN',
                om.ORDER_CLASS_C,
                zoc.NAME                                    'ORDER_CLASS',
                om.ORDERING_MODE_C,
                zom.NAME                                    'ORDERING_MODE',
                mt.ORDER_SOURCE_C,
                zsc.NAME                                    'ORDER_SOURCE',
                mt.USER_OVERRIDE_YN,
                mt.REORDERED_YN,
                mt.MODIFIED_YN,
                mt.ORDER_MODE,
                mt.DISCONTINUE_MODE,
                CONVERT(VARCHAR(16),om.DISCON_TIME,20)      'DISCON_TIME',
                om.RSN_FOR_DISCON_C,
                zrd.NAME                                    'REASON_FOR_DISCONTINUE',
                om.ORD_PROV_ID                              'ORDERING_PROV_ID',
                cso.PROV_NAME                               'ORD_PROV_NAME',
                cso.PROV_TYPE                               'ORD_PROV_TYPE',
                om.AUTHRZING_PROV_ID                        'AUTHORIZING_PROV_ID',
                csa.PROV_NAME                               'AUTHORIZING_PROV_NAME',
                csa.PROV_TYPE                               'AUTHORIZING_PROV_TYPE',
                m.MED_GROUP,        --[2021-02-08] 'C' = colchacine; 'R' = rosuvastatin
                m.STUDY_DRUG_YN,    --[2021-02-08] med name has this IRB protocol #
                cm.MEDICATION_ID, 
                cm.NAME                                     'MEDICATION_NAME',
                cm.GENERIC_NAME,
                cm.SIMPLE_GENERIC_C,
                zsg.NAME                                    'SIMPLE_GENERIC',
                zt.THERA_CLASS_C,
                zt.NAME                                     'THERA_CLASS', 
                zp.PHARM_CLASS_C, 
                zp.NAME                                     'PHARM_CLASS', 
                zs.PHARM_SUBCLASS_C, 
                zs.NAME                                     'PHARM_SUBCLASS', 

            ----MAR/admin
                mar.LINE                                    'MAR_LINE',
                zca.NAME                                    'MAR_ACTION',
                CASE WHEN zca.RESULT_C IN (1,   --Given
                                           6,   --New Bag
                                           7,   --Restarted
                                           9,   --Rate Change
                                           114, --Started During Downtime
                                           117, --Bolus from Bag
                                           118, --Given by Other.
                                           119, --Given During Downtime.
                                           123, --Bolus from Pump
                                           124, --Bolus from Bottle
                                           129, --Rate/Dose Change
                                           130, --Self Administered
                                           147) --Bolus from Vial
                    THEN 1 ELSE 0 END                       'GIVEN_YN', --[2021-02-08] valid "this was administered" actions    

                CONVERT(VARCHAR(16),mar.TAKEN_TIME,20)      'MAR_ACTION_TAKEN_TIME',
                CASE WHEN mar.TAKEN_TIME >= l.FIRST_CONSENTED_DTTM THEN 1
                     WHEN mar.TAKEN_TIME < l.FIRST_CONSENTED_DTTM  THEN 0
                    ELSE NULL END                           'MAR_ACTION_AFTER_CONSENT_DTTM_YN',
                CASE WHEN CAST(mar.TAKEN_TIME AS DATE) >= l.FIRST_CONSENTED_DATE THEN 1
                     WHEN CAST(mar.TAKEN_TIME AS DATE) < l.FIRST_CONSENTED_DATE  THEN 0
                    ELSE NULL END                           'MAR_ACTION_AFTER_CONSENT_DATE_YN',         
                CONVERT(VARCHAR(16),
                        CASE WHEN mar.MAR_DURATION_UNIT_C = 1 THEN DATEADD(mi,CAST(mar.MAR_DURATION AS NUMERIC(18,1)),mar.TAKEN_TIME)   --if in minutes
                             WHEN mar.MAR_DURATION_UNIT_C = 2 THEN DATEADD(hh,CAST(mar.MAR_DURATION AS NUMERIC(18,1)),mar.TAKEN_TIME)   --if in hours
                             WHEN mar.MAR_DURATION_UNIT_C = 3 THEN DATEADD(dd,CAST(mar.MAR_DURATION AS NUMERIC(18,1)),mar.TAKEN_TIME)   --if in days
                             ELSE NULL END,
                        20)                                 'INFUSION_END_TIME',            
                mar.ROUTE_C,
                zcr.NAME                                    'MEDICATION_ROUTE',
                mar.SIG                                     'MEDICATION_DOSE',
                mar.DOSE_UNIT_C,
                zcm.NAME                                    'MEDICATION_UNIT', 
                fr.FREQ_ID,
                fr.FREQ_NAME                                'FREQUENCY',
                mar.INFUSION_RATE,
                zci.NAME                                    'INFUSION_RATE_UNIT', 
                mar.MAR_DURATION                            'DURATION',
                mar.MAR_DURATION_UNIT_C,
                zmd.NAME                                    'DURATION_UNIT'

INTO            #mar

FROM            #list                           l       
    INNER JOIN  Clarity.dbo.ORDER_MED           om  ON  om.PAT_ENC_CSN_ID       =   l.PAT_ENC_CSN_ID            
    LEFT JOIN   Clarity.dbo.ORDER_METRICS       mt  ON  mt.ORDER_ID             =   om.ORDER_MED_ID
    LEFT JOIN   Clarity.dbo.MAR_ADMIN_INFO      mar ON  mar.ORDER_MED_ID        =   om.ORDER_MED_ID 
    LEFT JOIN   Clarity.dbo.ZC_ORDER_CLASS      zoc ON  zoc.ORDER_CLASS_C       =   om.ORDER_CLASS_C    
    LEFT JOIN   Clarity.dbo.ZC_ORDERING_MODE    zom ON  zom.ORDERING_MODE_C     =   om.ORDERING_MODE_C
    LEFT JOIN   Clarity.dbo.ZC_ORDER_SOURCE     zsc ON  zsc.ORDER_SOURCE_C      =   mt.ORDER_SOURCE_C
    LEFT JOIN   Clarity.dbo.CLARITY_SER         cso ON  cso.PROV_ID             =   om.ORD_PROV_ID
    LEFT JOIN   Clarity.dbo.CLARITY_SER         csa ON  csa.PROV_ID             =   om.AUTHRZING_PROV_ID
    LEFT JOIN   Clarity.dbo.CLARITY_MEDICATION  cm  ON  cm.MEDICATION_ID        =   om.MEDICATION_ID
    LEFT JOIN   #medlist                        m   ON  m.MEDICATION_ID         =   cm.MEDICATION_ID    --[2021-02-08] colchicine and rosuvastatin
    LEFT JOIN   Clarity.dbo.ZC_SIMPLE_GENERIC   zsg ON  zsg.SIMPLE_GENERIC_C    =   cm.SIMPLE_GENERIC_C
    LEFT JOIN   Clarity.dbo.ZC_THERA_CLASS      zt  ON  zt.THERA_CLASS_C        =   cm.THERA_CLASS_C
    LEFT JOIN   Clarity.dbo.ZC_PHARM_CLASS      zp  ON  zp.PHARM_CLASS_C        =   cm.PHARM_CLASS_C
    LEFT JOIN   Clarity.dbo.ZC_PHARM_SUBCLASS   zs  ON  zs.PHARM_SUBCLASS_C     =   cm.PHARM_SUBCLASS_C
    LEFT JOIN   Clarity.dbo.ZC_DISPENSE_ROUTE   zcr ON  zcr.DISPENSE_ROUTE_C    =   mar.ROUTE_C 
    LEFT JOIN   Clarity.dbo.ZC_MED_UNIT         zcm ON  zcm.DISP_QTYUNIT_C      =   mar.DOSE_UNIT_C
    LEFT JOIN   Clarity.dbo.ZC_MAR_RSLT         zca ON  zca.RESULT_C            =   mar.MAR_ACTION_C
    LEFT JOIN   Clarity.dbo.ZC_MED_UNIT         zci ON  zci.DISP_QTYUNIT_C      =   mar.MAR_INF_RATE_UNIT_C 
    LEFT JOIN   Clarity.dbo.ZC_MED_DURATION_UN  zmd ON  zmd.MED_DURATION_UN_C   =   mar.MAR_DURATION_UNIT_C
    LEFT JOIN   Clarity.dbo.IP_FREQUENCY        fr  ON  fr.FREQ_ID              =   om.HV_DISCR_FREQ_ID
    LEFT JOIN   Clarity.dbo.ZC_RSN_FOR_DISCON   zrd ON  zrd.RSN_FOR_DISCON_C    =   om.RSN_FOR_DISCON_C     

--  SELECT * FROM #mar m ORDER BY m.PAT_ID, m.HOSP_ADMSN_TIME, m.ORDER_INST, m.ORDER_MED_ID, m.MAR_LINE

----------------drop table #medsum
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.PAT_ENC_CSN_ID,

            ----Med summary
                CASE WHEN co.FIRST_COLCHICINE_ORDER_TIME IS NOT NULL
                    THEN 1 ELSE 0 END   'COLCHICINE_ORDER_YN',
                CASE WHEN ro.FIRST_ROSUVASTATIN_ORDER_TIME IS NOT NULL
                    THEN 1 ELSE 0 END   'ROSUVASTATIN_ORDER_YN',
                co.FIRST_COLCHICINE_ORDER_TIME,
                ro.FIRST_ROSUVASTATIN_ORDER_TIME,
                CASE WHEN cg.FIRST_COLCHICINE_GIVEN_TIME IS NOT NULL
                    THEN 1 ELSE 0 END   'COLCHICINE_GIVEN_YN',
                CASE WHEN rg.FIRST_ROSUVASTATIN_GIVEN_TIME IS NOT NULL
                    THEN 1 ELSE 0 END   'ROSUVASTATIN_GIVEN_YN',
                cg.FIRST_COLCHICINE_GIVEN_TIME,
                cg.LAST_COLCHICINE_GIVEN_TIME,
                rg.FIRST_ROSUVASTATIN_GIVEN_TIME,
                rg.LAST_ROSUVASTATIN_GIVEN_TIME,
                cd.FIRST_COLCHICINE_DISCONTINUE_TIME,
                cd.LAST_COLCHICINE_DISCONTINUE_TIME,
                rd.FIRST_ROSUVASTATIN_DISCONTINUE_TIME,
                rd.LAST_ROSUVASTATIN_DISCONTINUE_TIME

INTO            #medsum

FROM            #list l

    ------------[2021-02-08] First order time
    OUTER APPLY ( --Colchicine
                    SELECT  MIN(x.ORDER_INST) 'FIRST_COLCHICINE_ORDER_TIME'
                    FROM    #mar x
                    WHERE   x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID
                        AND x.MED_GROUP = 'C'
                )     co

    OUTER APPLY ( --Rosuvastatin
                    SELECT  MIN(x.ORDER_INST) 'FIRST_ROSUVASTATIN_ORDER_TIME'
                    FROM    #mar x
                    WHERE   x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID
                        AND x.MED_GROUP = 'R'
                )     ro

    ------------[2021-02-08] First/last given time
    OUTER APPLY ( --Colchicine
                    SELECT  MIN(x.MAR_ACTION_TAKEN_TIME) 'FIRST_COLCHICINE_GIVEN_TIME',
                            MAX(x.MAR_ACTION_TAKEN_TIME) 'LAST_COLCHICINE_GIVEN_TIME'
                    FROM    #mar x
                    WHERE   x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID
                        AND x.MED_GROUP = 'C'
                )     cg

    OUTER APPLY ( --Rosuvastatin
                    SELECT  MIN(x.MAR_ACTION_TAKEN_TIME) 'FIRST_ROSUVASTATIN_GIVEN_TIME',
                            MAX(x.MAR_ACTION_TAKEN_TIME) 'LAST_ROSUVASTATIN_GIVEN_TIME'
                    FROM    #mar x
                    WHERE   x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID
                        AND x.MED_GROUP = 'R'
                )     rg

    ------------[2021-02-08] First/last discontinue time
    OUTER APPLY ( --Colchicine
                    SELECT  MIN(x.DISCON_TIME) 'FIRST_COLCHICINE_DISCONTINUE_TIME',
                            MAX(x.DISCON_TIME) 'LAST_COLCHICINE_DISCONTINUE_TIME'
                    FROM    #mar x
                    WHERE   x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID
                        AND x.MED_GROUP = 'C'
                )     cd

    OUTER APPLY ( --Rosuvastatin
                    SELECT  MIN(x.DISCON_TIME) 'FIRST_ROSUVASTATIN_DISCONTINUE_TIME',
                            MAX(x.DISCON_TIME) 'LAST_ROSUVASTATIN_DISCONTINUE_TIME'
                    FROM    #mar x
                    WHERE   x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID
                        AND x.MED_GROUP = 'R'
                )     rd

/*
SELECT          COUNT(DISTINCT a.PAT_ENC_CSN_ID)    'TOTAL',                    
                
                COUNT(DISTINCT CASE WHEN a.COLCHICINE_ORD_YN = 1                        
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE_ORD',               
                COUNT(DISTINCT CASE WHEN a.ROSUVASTATIN_ORD_YN = 1                      
                    THEN a.PAT_ID ELSE NULL END)    'ROSUVASTATIN_ORD',             
                COUNT(DISTINCT CASE WHEN a.COLCHICINE_ORD_YN + a.ROSUVASTATIN_ORD_YN > 0                        
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE_OR_ROSUVASTATIN_ORD',               
                COUNT(DISTINCT CASE WHEN a.COLCHICINE_ORD_YN + a.ROSUVASTATIN_ORD_YN = 2                        
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE_AND_ROSUVASTATIN_ORD',  

                COUNT(DISTINCT CASE WHEN a.COLCHICINE_GIVEN_YN = 1                      
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE_GIVEN',             
                COUNT(DISTINCT CASE WHEN a.ROSUVASTATIN_GIVEN_YN = 1                        
                    THEN a.PAT_ID ELSE NULL END)    'ROSUVASTATIN_GIVEN',               
                COUNT(DISTINCT CASE WHEN a.COLCHICINE_GIVEN_YN + a.ROSUVASTATIN_GIVEN_YN > 0                        
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE_OR_ROSUVASTATIN_GIVEN',             
                COUNT(DISTINCT CASE WHEN a.COLCHICINE_GIVEN_YN + a.ROSUVASTATIN_GIVEN_YN = 2                        
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE_AND_ROSUVASTATIN_GIVEN' 

FROM
    (
        SELECT DISTINCT l.PAT_ID,
                        l.PAT_ENC_CSN_ID,
                        CASE WHEN EXISTS (SELECT 1 FROM #mar x WHERE x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID AND x.MED_GROUP = 'C')
                            THEN 1 ELSE 0 END   'COLCHICINE_ORD_YN',
                        CASE WHEN EXISTS (SELECT 1 FROM #mar x WHERE x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID AND x.MED_GROUP = 'C' AND x.GIVEN_YN = 1)
                            THEN 1 ELSE 0 END   'COLCHICINE_GIVEN_YN',
                        CASE WHEN EXISTS (SELECT 1 FROM #mar x WHERE x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID AND x.MED_GROUP = 'R')
                            THEN 1 ELSE 0 END   'ROSUVASTATIN_ORD_YN',
                        CASE WHEN EXISTS (SELECT 1 FROM #mar x WHERE x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID AND x.MED_GROUP = 'R' AND x.GIVEN_YN = 1)
                            THEN 1 ELSE 0 END   'ROSUVASTATIN_GIVEN_YN'

        FROM    #list l
    ) a

SELECT          COUNT(DISTINCT a.PAT_ID)            'TOTAL',                        --[n = 76 as of 2021-02-03]
                COUNT(DISTINCT CASE WHEN a.COLCHICINE_YN = 1                        
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE',                   --[n = 32 as of 2021-02-03]
                COUNT(DISTINCT CASE WHEN a.ROSUVASTATIN_YN = 1                      
                    THEN a.PAT_ID ELSE NULL END)    'ROSUVASTATIN',                 --[n = 53 as of 2021-02-03]
                COUNT(DISTINCT CASE WHEN a.COLCHICINE_YN + a.ROSUVASTATIN_YN > 0    
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE_OR_ROSUVASTATIN',   --[n = 53 as of 2021-02-03]
                COUNT(DISTINCT CASE WHEN a.COLCHICINE_YN + a.ROSUVASTATIN_YN = 2    
                    THEN a.PAT_ID ELSE NULL END)    'COLCHICINE_AND_ROSUVASTATIN'   --[n = 32 as of 2021-02-03]

FROM
    (
        SELECT DISTINCT l.PAT_ID,
                        CASE WHEN EXISTS 
                                    (
                                        SELECT  1
                                        FROM    #mar x
                                        WHERE   x.PAT_ID = l.PAT_ID
                                        AND     (x.MEDICATION_NAME   LIKE '%COLCHICINE%'
                                                 OR x.GENERIC_NAME   LIKE '%COLCHICINE%'
                                                 OR x.SIMPLE_GENERIC LIKE '%COLCHICINE%')
                                    )
                            THEN 1 ELSE 0 END   'COLCHICINE_YN',

                        CASE WHEN EXISTS 
                                    (
                                        SELECT  1
                                        FROM    #mar x
                                        WHERE   x.PAT_ID = l.PAT_ID
                                        AND     (x.MEDICATION_NAME   LIKE '%ROSUVASTATIN%'
                                                 OR x.GENERIC_NAME   LIKE '%ROSUVASTATIN%'
                                                 OR x.SIMPLE_GENERIC LIKE '%ROSUVASTATIN%')
                                    )
                            THEN 1 ELSE 0 END   'ROSUVASTATIN_YN'

        FROM    #list l
    ) a
*/


/*********************************************************************************************************************
                    VITALS
*********************************************************************************************************************/

----------------drop table #vitals
SELECT          e.PAT_ID,
                e.PAT_MRN_ID,
                e.PAT_ENC_CSN_ID,
                ifr.FSD_ID,
                ifm.LINE,
                CAST(ifr.RECORD_DATE AS DATE)   'RECORD_DATE',
                CONVERT(VARCHAR(16),ifm.RECORDED_TIME,20)
                                                'RECORDED_TIME',
                ifg.FLO_MEAS_ID,
                ifg.FLO_MEAS_NAME,
                ifg.DISP_NAME,
                ifm.MEAS_VALUE,
            --  'FIRST_' + UPPER(ifg.DISP_NAME) 'P_VITALS_FIRST', --[2020-12-16] to pivot
            --  'LAST_' + UPPER(ifg.DISP_NAME)  'P_VITALS_LAST',  --[2020-12-16] to pivot
                CASE WHEN ifg.FLO_MEAS_ID = '14' THEN 'oz'
                     WHEN ifg.FLO_MEAS_ID = '11' THEN 'inches'
                     ELSE ifg.UNITS END         'UNITS',
            --  ifg.UNITS,
                ifg.VAL_TYPE_C,
                zvt.NAME                        'VAL_TYPE'
                
INTO            #vitals

FROM            #list                       e
    INNER JOIN  Clarity.dbo.IP_FLWSHT_REC   ifr ON  ifr.INPATIENT_DATA_ID   =   e.INPATIENT_DATA_ID
    INNER JOIN  Clarity.dbo.IP_DATA_STORE   ids ON  ids.INPATIENT_DATA_ID   =   ifr.INPATIENT_DATA_ID   --adding 2019-10-??: going through this, I can join to the actual CSN (INPATIENT_DATA_ID can be associated with more than one)
                                                AND ids.EPT_CSN             =   e.PAT_ENC_CSN_ID        --join to specific CSN
    INNER JOIN  Clarity.dbo.IP_FLWSHT_MEAS  ifm ON  ifm.FSD_ID              =   ifr.FSD_ID
                                                AND ifm.MEAS_VALUE          IS NOT NULL
                                                AND ifm.FLO_MEAS_ID         IN  ('5',   --BLOOD PRESSURE
                                                                                 '8',   --PULSE
                                                                                 '9',   --RESPIRATIONS
                                                                                 '10',  --PULSE OXIMETRY
                                                                                 '11',  --HEIGHT
                                                                                 '14')  --WEIGHT/SCALE [oz]
    INNER JOIN  Clarity.dbo.IP_FLO_GP_DATA  ifg ON  ifg.FLO_MEAS_ID         =   ifm.FLO_MEAS_ID
--  LEFT JOIN   Clarity.dbo.IP_FLT_DATA     ifd ON  ifd.TEMPLATE_ID         =   ifm.FLT_ID  
    LEFT JOIN   Clarity.dbo.ZC_VAL_TYPE     zvt ON  zvt.VAL_TYPE_C          =   ifg.VAL_TYPE_C  


/*********************************************************************************************************************
                    ALL DIAGNOSES (ALL TIME)
*********************************************************************************************************************/

/*  2021-05-18: I'm not sure what they actually want but we discussed me sending just all the diagnoses the patient
    has ever had, so I'll just do that -- it will be a big file but the population isn't HUGE.                  */

----------------drop table if exists #dx0
SELECT          a.PAT_MRN_ID,
                a.PAT_ID,
                a.DX_SOURCE_ID,
                a.DX_SOURCE,        
                CAST(a.DX_DATE AS DATE) 'DX_DATE',
                CAST(REPLACE(a.PAT_ID,'Z','') + '000' + CAST(a.DX_ID AS VARCHAR) AS NUMERIC(25,0))
                                    'COMBINED_DX_ID', --[2021-04-27: faster to search on this below]
                a.CURRENT_ICD9_LIST,
                a.CURRENT_ICD10_LIST,
                a.DX_ID,
                a.DX_NAME

INTO            #dx0

FROM
    (
        SELECT      'ENCDX'             'DX_SOURCE',
                    1                   'DX_SOURCE_ID', --[2021-04-27: found this was faster than joining on DX_SOURCE]
                    l.PAT_MRN_ID,
                    l.PAT_ID,
                    ce.CURRENT_ICD9_LIST,
                    ce.CURRENT_ICD10_LIST,
                    ce.DX_ID,
                    ce.DX_NAME,
                    COALESCE(pe.HOSP_ADMSN_TIME,pe.CONTACT_DATE) 'DX_DATE'

        FROM        #list                   l
        INNER JOIN  Clarity.dbo.PAT_ENC     pe  ON  pe.PAT_ID           =   l.PAT_ID
        INNER JOIN  Clarity.dbo.PAT_ENC_DX  pdx ON  pdx.PAT_ENC_CSN_ID  =   pe.PAT_ENC_CSN_ID
        INNER JOIN  Clarity.dbo.CLARITY_EDG ce  ON  ce.DX_ID            =   pdx.DX_ID

        UNION ALL
        SELECT      'HDX'               'DX_SOURCE',
                    2                   'DX_SOURCE_ID',
                    l.PAT_MRN_ID,
                    l.PAT_ID,
                    ce.CURRENT_ICD9_LIST,
                    ce.CURRENT_ICD10_LIST,
                    ce.DX_ID,
                    ce.DX_NAME,
                    COALESCE(pe.HOSP_ADMSN_TIME,pe.CONTACT_DATE) 'DX_DATE'

        FROM        #list                           l
        INNER JOIN  Clarity.dbo.PAT_ENC             pe  ON  pe.PAT_ID           =   l.PAT_ID
        INNER JOIN  Clarity.dbo.HSP_ACCT_DX_LIST    hdx ON  hdx.HSP_ACCOUNT_ID  =   pe.HSP_ACCOUNT_ID
        INNER JOIN  Clarity.dbo.CLARITY_EDG         ce  ON  ce.DX_ID            =   hdx.DX_ID

        UNION ALL
        SELECT      'ARPB'              'DX_SOURCE',
                    3                   'DX_SOURCE_ID',
                    l.PAT_MRN_ID,
                    l.PAT_ID,
                    ce.CURRENT_ICD9_LIST,
                    ce.CURRENT_ICD10_LIST,
                    ce.DX_ID,
                    ce.DX_NAME,
                    COALESCE(pe.HOSP_ADMSN_TIME,pe.CONTACT_DATE) 'DX_DATE'

        FROM        #list                           l
        INNER JOIN  Clarity.dbo.PAT_ENC             pe  ON  pe.PAT_ID           =   l.PAT_ID
        INNER JOIN  Clarity.dbo.ARPB_TRANSACTIONS   art ON  art.PAT_ENC_CSN_ID  =   pe.PAT_ENC_CSN_ID
        INNER JOIN  Clarity.dbo.TX_DIAG             tdx ON  tdx.TX_ID           =   art.TX_ID
        INNER JOIN  Clarity.dbo.CLARITY_EDG         ce  ON  ce.DX_ID            =   tdx.DX_ID

        UNION ALL
        SELECT      'PL'            'DX_SOURCE',
                    4               'DX_SOURCE_ID',
                    l.PAT_MRN_ID,
                    l.PAT_ID,
                    ce.CURRENT_ICD9_LIST,
                    ce.CURRENT_ICD10_LIST,
                    ce.DX_ID,
                    ce.DX_NAME,
                    pl.NOTED_DATE   'DX_DATE'

        FROM        #list                       l
        INNER JOIN  Clarity.dbo.PROBLEM_LIST    pl  ON  pl.PAT_ID   =   l.PAT_ID
        INNER JOIN  Clarity.dbo.CLARITY_EDG     ce  ON  ce.DX_ID    =   pl.DX_ID
    )   a

GROUP BY        a.PAT_MRN_ID,
                a.PAT_ID,
                a.DX_SOURCE_ID,
                a.DX_SOURCE,        
                CAST(a.DX_DATE AS DATE),
                a.CURRENT_ICD9_LIST,
                a.CURRENT_ICD10_LIST,
                a.DX_ID,
                a.DX_NAME

-- SELECT TOP 100 * FROM #dx0

----------------drop table #dx
SELECT          dx.PAT_ID,
                dx.PAT_MRN_ID,
                dx.CURRENT_ICD9_LIST,
                dx.CURRENT_ICD10_LIST,
                dx.DX_ID,
                dx.DX_NAME,
                dx.DX_DATE,
                CASE WHEN EXISTS (SELECT 1 FROM #dx0 x WHERE x.COMBINED_DX_ID = dx.COMBINED_DX_ID AND x.DX_SOURCE_ID = 1)
                    THEN 1 ELSE 0 END   'ENCOUNTER_DX_YN',
                CASE WHEN EXISTS (SELECT 1 FROM #dx0 x WHERE x.COMBINED_DX_ID = dx.COMBINED_DX_ID AND x.DX_SOURCE_ID = 2)
                    THEN 1 ELSE 0 END   'HOSP_BILLING_DX_YN',
                CASE WHEN EXISTS (SELECT 1 FROM #dx0 x WHERE x.COMBINED_DX_ID = dx.COMBINED_DX_ID AND x.DX_SOURCE_ID = 3)
                    THEN 1 ELSE 0 END   'ARPB_DX_YN',
                CASE WHEN EXISTS (SELECT 1 FROM #dx0 x WHERE x.COMBINED_DX_ID = dx.COMBINED_DX_ID AND x.DX_SOURCE_ID = 4)
                    THEN 1 ELSE 0 END   'PROB_LIST_DX_YN'

INTO            #dx

FROM            #dx0 dx

GROUP BY        dx.PAT_ID,
                dx.PAT_MRN_ID,
                dx.CURRENT_ICD9_LIST,
                dx.CURRENT_ICD10_LIST,
                dx.COMBINED_DX_ID,
                dx.DX_ID,
                dx.DX_NAME,
                dx.DX_DATE

--  SELECT TOP 100 * FROM #dx

----------------drop table #dxsum
SELECT          dx.PAT_ID,
                dx.PAT_MRN_ID,
                dx.CURRENT_ICD9_LIST,
                dx.CURRENT_ICD10_LIST,
                dx.DX_ID,
                dx.DX_NAME,
                MIN(dx.DX_DATE)             'FIRST_DX_DATE',
                MAX(dx.DX_DATE)             'LAST_DX_DATE',
                MAX(dx.ENCOUNTER_DX_YN)     'ENCOUNTER_DX_YN',
                MAX(dx.PROB_LIST_DX_YN)     'PROB_LIST_DX_YN',
                MAX(dx.HOSP_BILLING_DX_YN)  'HOSP_BILLING_DX_YN',
                MAX(dx.ARPB_DX_YN)          'ARPB_DX_YN'

INTO            #dxsum

FROM            #dx dx

GROUP BY        dx.PAT_ID,
                dx.PAT_MRN_ID,
                dx.CURRENT_ICD9_LIST,
                dx.CURRENT_ICD10_LIST,
                dx.DX_ID,
                dx.DX_NAME

----------------drop table #dxsumicd
SELECT          a.PAT_ID,
                a.PAT_MRN_ID,
                a.ICD_VERSION,
                a.ICD_CODE,
                a.FIRST_DX_DATE,
                a.LAST_DX_DATE,
                a.ENCOUNTER_DX_YN,
                a.PROB_LIST_DX_YN,
                a.HOSP_BILLING_DX_YN,
                a.ARPB_DX_YN

INTO            #dxsumicd

FROM
    (
        SELECT      dx.PAT_ID,
                    dx.PAT_MRN_ID,
                    9                           'ICD_VERSION',
                    i.CODE                      'ICD_CODE',
                    MIN(dx.DX_DATE)             'FIRST_DX_DATE',
                    MAX(dx.DX_DATE)             'LAST_DX_DATE',
                    MAX(dx.ENCOUNTER_DX_YN)     'ENCOUNTER_DX_YN',
                    MAX(dx.PROB_LIST_DX_YN)     'PROB_LIST_DX_YN',
                    MAX(dx.HOSP_BILLING_DX_YN)  'HOSP_BILLING_DX_YN',
                    MAX(dx.ARPB_DX_YN)          'ARPB_DX_YN'

        FROM        #dx                          dx
        INNER JOIN  Clarity.dbo.EDG_CURRENT_ICD9 i ON i.DX_ID = dx.DX_ID

        GROUP BY    dx.PAT_ID,
                    dx.PAT_MRN_ID,
                    i.CODE 

        UNION ALL
        SELECT      dx.PAT_ID,
                    dx.PAT_MRN_ID,
                    10                          'ICD_VERSION',
                    i.CODE                      'ICD_CODE',
                    MIN(dx.DX_DATE)             'FIRST_DX_DATE',
                    MAX(dx.DX_DATE)             'LAST_DX_DATE',
                    MAX(dx.ENCOUNTER_DX_YN)     'ENCOUNTER_DX_YN',
                    MAX(dx.PROB_LIST_DX_YN)     'PROB_LIST_DX_YN',
                    MAX(dx.HOSP_BILLING_DX_YN)  'HOSP_BILLING_DX_YN',
                    MAX(dx.ARPB_DX_YN)          'ARPB_DX_YN'

        FROM        #dx                           dx
        INNER JOIN  Clarity.dbo.EDG_CURRENT_ICD10 i ON i.DX_ID = dx.DX_ID

        GROUP BY    dx.PAT_ID,
                    dx.PAT_MRN_ID,
                    i.CODE 
    ) a


/*********************************************************************************************************************
                    SMOKING STATUS
*********************************************************************************************************************/

/*  2021-04-21: Adding current smoking status and status at time of admission.                                      */

----------------drop table #socialhx        --all social HX records 
SELECT DISTINCT x.PAT_ID,
                x.PAT_MRN_ID,
                x.SOCIAL_HX_CSN,
                x.PAT_ENC_DATE_REAL,
                x.SOCIAL_HX_DATE,

        --------2019-05-01: changing to abbreviations to reduce the likelihood I'll misspell any of this
                CASE WHEN NEVER_SMOKER = 1   THEN 'N'       --N = Never
                     WHEN FORMER_SMOKER = 1  THEN 'F'       --F = Former
                     WHEN CURRENT_SMOKER = 1 THEN 'C'       --C = Current
                     ELSE 'U' END       'SMOKING_STATUS',   --U = Unknown

        --------2019-05-01: also adding a new field '_NAME' so I can return this without having to hard code in the status finder query below
                CASE WHEN NEVER_SMOKER = 1   THEN 'Never smoker'
                     WHEN FORMER_SMOKER = 1  THEN 'Former smoker'
                     WHEN CURRENT_SMOKER = 1 THEN 'Current smoker'
                     ELSE 'Unknown' END 'SMOKING_STATUS_NAME',

                x.SMOKING_QUIT_DATE,
                x.SMOKELESS_QUIT_DATE,
                x.TOBACCO_COMMENT

INTO            #socialhx

FROM
    (
        SELECT      p.PAT_ID,
                    p.PAT_MRN_ID,
                    a.PAT_ENC_CSN_ID                    'SOCIAL_HX_CSN',
                    a.PAT_ENC_DATE_REAL,
                    CAST(a.CONTACT_DATE AS DATE)        'SOCIAL_HX_DATE',

                ----Never smoker
                    CASE WHEN ISNULL(a.TOBACCO_USED_YEARS,'0') = '0'        --this would include smokeless, should it count?
                          AND ISNULL(a.TOBACCO_USER_C,2)       IN (2,3,5)   --Never, Not Asked, Passive
                          AND ISNULL(a.TOBACCO_PAK_PER_DY,'0') = '0'
                          AND ISNULL(a.SMOKING_TOB_USE_C,5)    IN (5,6,7,8) --Never, Never Assessd, Passive Smoke Exposure - Never Smoker, Unkown if Ever Smoked
                          AND ISNULL(a.CIGARETTES_YN,'N')      = 'N'
                          AND ISNULL(a.CIGARS_YN,'N')          = 'N'
                          AND ISNULL(a.PIPES_YN,'N')           = 'N'
                          AND a.SMOKING_QUIT_DATE IS NULL 
                        THEN 1 ELSE 0 END               'NEVER_SMOKER',

                ----Former smoker
                    CASE WHEN (a.SMOKING_TOB_USE_C    = 4                   --Former Smoker
                               OR a.TOBACCO_USER_C    = 4                   --Quit (might be a problem if quit smokeless but not smoking, but seems unlikely)
                               OR a.SMOKING_QUIT_DATE IS NOT NULL)
                          AND a.SMOKING_TOB_USE_C     NOT IN (1,2,3,9,10)   --Current Every Day Smoker; Current Some Day Smoker; Smoker, Current Status Unknown; Heavy Tobacco Smoker; Light Tobacco Smoker
                        THEN 1 ELSE 0 END               'FORMER_SMOKER',

                ----Current smoker
                    CASE WHEN 
                        ----Step 1: At least one condition must be true
                              (a.SMOKING_TOB_USE_C           IN (1,2,3,9,10)    --Current Every Day Smoker; Current Some Day Smoker; Smoker, Current Status Unknown; Heavy Tobacco Smoker; Light Tobacco Smoker
                               OR a.TOBACCO_USER_C           =  1               --Yes (but wondering how this would work with those who have only used smokeless tobacco)
                               OR a.TOBACCO_PAK_PER_DY       <> '0')
                        ----Step 2: Limitations on the conditions above to prevent 'false positives'/former smokers
                          AND (ISNULL(a.SMOKING_TOB_USE_C,1) IN (1,2,3,9,10)    --Current Every Day Smoker; Current Some Day Smoker; Smoker, Current Status Unknown; Heavy Tobacco Smoker; Light Tobacco Smoker
                               OR a.SMOKING_QUIT_DATE IS NULL)                  --because if they have a quit date but also explicitly are listed as 'current smoker' maybe they quit but started again
                          AND ISNULL(a.TOBACCO_USER_C,1)     = 1                --Yes
                          AND ISNULL(a.SMOKING_TOB_USE_C,1)  IN (1,2,3,9,10)    --Current Every Day Smoker; Current Some Day Smoker; Smoker, Current Status Unknown; Heavy Tobacco Smoker; Light Tobacco Smoker
                        THEN 1 ELSE 0 END               'CURRENT_SMOKER',

                ----Raw variables for verification
                    CAST(a.SMOKING_QUIT_DATE AS DATE)   'SMOKING_QUIT_DATE',
                    CAST(a.SMOKELESS_QUIT_DATE AS DATE) 'SMOKELESS_QUIT_DATE',
                    a.TOBACCO_COMMENT

        FROM        #list                 p
        INNER JOIN  Clarity.dbo.SOCIAL_HX a ON a.PAT_ID = p.PAT_ID

        WHERE       COALESCE(a.SMOKING_TOB_USE_C,a.IS_TOBACCO_USER,a.TOBACCO_USER_C) IS NOT NULL 
    )   x

----------------drop table #smokingcurrent  --current smoking status
SELECT DISTINCT p.PAT_ID,
                p.PAT_MRN_ID,
                CASE WHEN EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = p.PAT_ID)
                    THEN 1 ELSE 0 END                   'ANY_SOCIAL_HX_YN',

        --------Categorizing smoking status

            ----NEVER: If patient has a record of 'never smoker' and DOES NOT have a record of 'former' or 'current'
                CASE WHEN EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = p.PAT_ID AND x.SMOKING_STATUS = 'N')
                      AND NOT EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = p.PAT_ID AND x.SMOKING_STATUS IN ('F','C'))
                      THEN 'Never smoker' 
                    
            ----CURRENT: If last status before encounter is 'current' OR if no status before encounter but first status after is 'current'
                     WHEN lb.SMOKING_STATUS = 'C'
                      THEN 'Current smoker' 

            ----FORMER: If patient has a history of 'former' or 'current' AND most recent status is 'former' or 'never'; OR recorded quit date
                     WHEN (EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = p.PAT_ID AND x.SMOKING_STATUS IN ('F','C'))
                           AND lb.SMOKING_STATUS IN ('F','N'))
                       OR EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = p.PAT_ID AND x.SMOKING_QUIT_DATE IS NOT NULL) 
                      THEN 'Former smoker'

                    ELSE 'Unknown smoking status' END   'MOST_RECENT_SMOKING_STATUS'

INTO            #smokingcurrent

FROM            #list p

    ------------Most recent status
    OUTER APPLY (
                    SELECT TOP 1 
                            x.SMOKING_STATUS,
                            x.SMOKING_STATUS_NAME,
                            x.SMOKING_QUIT_DATE,
                            x.TOBACCO_COMMENT
                    FROM    #socialhx x
                    WHERE   x.PAT_ID = p.PAT_ID
                    ORDER BY x.PAT_ENC_DATE_REAL DESC
                )    lb

----------------drop table #smokingenc      --smoking status at time of encounter
SELECT          pe.PAT_ID,
                pe.PAT_MRN_ID,
            --  CAST(pe.CONTACT_DATE AS DATE)           'CONTACT_DATE',
                pe.PAT_ENC_CSN_ID,
                pe.PAT_ENC_DATE_REAL,
                CASE WHEN EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = pe.PAT_ID)
                    THEN 1 ELSE 0 END                   'ANY_SOCIAL_HX_YN',
                CASE WHEN EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = pe.PAT_ID AND x.PAT_ENC_DATE_REAL <= pe.PAT_ENC_DATE_REAL)
                    THEN 1 ELSE 0 END                   'ANY_SOCIAL_HX_BEFORE_ENC',

        --------Categorizing smoking status

            ----NEVER: If patient has record above indicating 'never' and DOES NOT have records in social HX before encounter date indicate 'former' or 'current'
                CASE WHEN EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = pe.PAT_ID AND x.SMOKING_STATUS = 'N')
                      AND NOT EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = pe.PAT_ID AND x.PAT_ENC_DATE_REAL <= pe.PAT_ENC_DATE_REAL AND x.SMOKING_STATUS IN ('F','C'))
                      THEN 'Never smoker' 
                    
            ----FORMER: If patient has a history of 'former' or 'current' AND status closest to encounter is 'former' or 'never'; OR recorded quit date before encounter
                     WHEN (EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = pe.PAT_ID AND x.PAT_ENC_DATE_REAL <= pe.PAT_ENC_DATE_REAL AND x.SMOKING_STATUS IN ('F','C'))
                            AND lb.SMOKING_STATUS IN ('F','N'))
                       OR EXISTS (SELECT 1 FROM #socialhx x WHERE x.PAT_ID = pe.PAT_ID AND x.SMOKING_QUIT_DATE <= pe.HOSP_ADMSN_DATE) 
                      THEN 'Former smoker'

            ----CURRENT: If last status before encounter is 'current' OR if no status before encounter but first status after is 'current'
                     WHEN lb.SMOKING_STATUS = 'C'
                       OR (lb.SMOKING_STATUS IS NULL --nothing recorded before encounter
                           AND fa.SMOKING_STATUS = 'C')
                      THEN 'Current smoker' 

                    ELSE 'Unknown smoking status' END   'SMOKING_STATUS_AT_ENCOUNTER'

INTO            #smokingenc

FROM            #list           pe

    ------------Last status before encounter
    OUTER APPLY (
                    SELECT TOP 1 
                            x.SMOKING_STATUS,
                            x.SMOKING_STATUS_NAME,
                            x.SMOKING_QUIT_DATE,
                            x.TOBACCO_COMMENT
                    FROM    #socialhx x
                    WHERE   x.PAT_ID = pe.PAT_ID
                        AND x.PAT_ENC_DATE_REAL <= pe.PAT_ENC_DATE_REAL
                    ORDER BY x.PAT_ENC_DATE_REAL DESC
                )    lb

    ------------First status after encounter
    OUTER APPLY (
                    SELECT TOP 1 
                            x.SMOKING_STATUS,
                            x.SMOKING_STATUS_NAME,
                            x.SMOKING_QUIT_DATE,
                            x.TOBACCO_COMMENT
                    FROM    #socialhx x
                    WHERE   x.PAT_ID = pe.PAT_ID
                        AND x.PAT_ENC_DATE_REAL >= pe.PAT_ENC_DATE_REAL
                    ORDER BY x.PAT_ENC_DATE_REAL
                )    fa


/***************************************************************************************************************
                    ADVERSE EVENTS
***************************************************************************************************************/

----------------drop table #advevent
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.ENROLLMENT_ID,
                l.STUDY_BRANCH_ID,
                l.RESEARCH_STUDY_ID,
                l.RESEARCH_STUDY_NAME,
                l.STUDY_CODE,
                l.IRB_APPROVAL_NUM,
                l.RESEARCH_STATUS_C,
                l.RESEARCH_STUDY_STATUS,
                l.ENROLL_STATUS_C,
                l.ENROLL_STATUS,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
                l.FIRST_CONSENTED_DATE,
                l.HSP_ACCOUNT_ID,
                l.PAT_ENC_CSN_ID,

            ----Adverse events
                ae.ADVERSE_EVENT_ID,
                ae.DX_ID,
                ce.DX_NAME,
                ce.CURRENT_ICD9_LIST,
                ce.CURRENT_ICD10_LIST,
                ae.RESEARCH_ATTRIBUTION_C,  --whether problem was attributed to participation in study
                zra.NAME                        'RESEARCH_ATTRIBUTION',
                ae.EXPECTED_YN,             --whether the event was one researchers expected might happen to study participants
                ae.SERIOUS_YN,
                rg.MOST_RECENT_GRADE,
                rg.MOST_RECENT_GRADE_NAME,
                rg.MOST_RECENT_GRADE_START_DATE,
                rg.MOST_RECENT_GRADE_EDIT_TIME,
                rg.MOST_RECENT_GRADE_EDIT_USER_ID,
                rg.MOST_RECENT_GRADE_EDIT_USER_NAME,
                ae.STATUS_C                     'ADVERSE_EVENT_STATUS_C',
                zps.NAME                        'ADVERSE_EVENT_STATUS',
                CAST(pl.NOTED_DATE AS DATE)     'NOTED_DATE',
                CAST(pl.DATE_OF_ENTRY AS DATE)  'DATE_OF_ENTRY',
                CAST(ae.RESOLVED_DATE AS DATE)  'RESOLVED_DATE',    
                ae.NOTE_ID,
                c.HX_NOTE_CSN,
                n.NOTE_TEXT

INTO            #advevent

FROM            #list                               l

    ------------Adverse events
    INNER JOIN  Clarity.dbo.ADVERSE_EVENT_INFO      ae  ON  ae.PAT_ID                   =   l.PAT_ID
                                                        AND ae.RESEARCH_ID              =   l.RESEARCH_STUDY_ID
    LEFT JOIN   Clarity.dbo.PROBLEM_LIST            pl  ON  pl.PROBLEM_LIST_ID          =   ae.ADVERSE_EVENT_ID
    LEFT JOIN   Clarity.dbo.CLARITY_EDG             ce  ON  ce.DX_ID                    =   ae.DX_ID
    LEFT JOIN   Clarity.dbo.ZC_RESEARCH_ATTRIBUTION zra ON  zra.RESEARCH_ATTRIBUTION_C  =   ae.RESEARCH_ATTRIBUTION_C
    LEFT JOIN   Clarity.dbo.ZC_PROBLEM_STATUS       zps ON  zps.PROBLEM_STATUS_C        =   ae.STATUS_C

    ------------Most recent event grade
    OUTER APPLY (
                    SELECT TOP 1
                            x.ADVERSE_EVENT_GRADE_C     'MOST_RECENT_GRADE',
                            z.NAME                      'MOST_RECENT_GRADE_NAME',
                            CAST(x.START_DATE AS DATE)  'MOST_RECENT_GRADE_START_DATE',
                            CONVERT(VARCHAR(16),Clarity.EPIC_UTIL.EFN_UTC_TO_LOCAL(h.EDIT_UTC_DTTM),20) 'MOST_RECENT_GRADE_EDIT_TIME',
                            h.EDIT_USER_ID                          'MOST_RECENT_GRADE_EDIT_USER_ID',
                            u.NAME                                  'MOST_RECENT_GRADE_EDIT_USER_NAME'
                    FROM    Clarity.dbo.ADVERSE_EVENT_GRADE    x
                    JOIN    Clarity.dbo.ZC_ADVERSE_EVENT_GRADE z ON z.ADVERSE_EVENT_GRADE_C = x.ADVERSE_EVENT_GRADE_C
                    LEFT JOIN   Clarity.dbo.ADVERSE_EVENT_HISTORY h ON  h.ADVERSE_EVENT_ID = x.ADVERSE_EVENT_ID
                                                                    AND h.LINE             = h.LINE
                    LEFT JOIN   Clarity.dbo.CLARITY_EMP           u ON  u.USER_ID          = h.EDIT_USER_ID
                    WHERE   x.ADVERSE_EVENT_ID = ae.ADVERSE_EVENT_ID
                    ORDER BY x.LINE DESC
                )                                   rg

    ------------Most recent note CSN
    OUTER APPLY (
                    SELECT TOP 1 x.HX_NOTE_CSN
                    FROM    Clarity.dbo.ADVERSE_EVENT_HISTORY x
                    WHERE   x.ADVERSE_EVENT_ID = ae.ADVERSE_EVENT_ID
                    ORDER BY x.LINE DESC
                )                                   c
                    
    ------------Text from most recent version of note
    CROSS APPLY (
                    SELECT
                        STUFF((
                                SELECT  ' ' + radb.rsh.TextClean(x.NOTE_TEXT)
                                FROM    Clarity.dbo.HNO_NOTE_TEXT x
                                WHERE   x.NOTE_CSN_ID = c.HX_NOTE_CSN
                                ORDER BY x.LINE
                                FOR XML PATH, TYPE).value(N'.[1]', N'nvarchar(max)')
                            ,1,1,'')    'NOTE_TEXT'
                )                                   n (NOTE_TEXT)


/***************************************************************************************************************
                    SOFA SCORES
***************************************************************************************************************/

----------------drop table #sofa
SELECT          pe.PAT_ID,
                pe.PAT_MRN_ID,
                pe.PAT_ENC_CSN_ID,
                rdc.REGISTRY_DATA_ID,
                CAST(qmi.PAT_DATE AS DATE)                      'PAT_DATE',      --The patient encounter date for this registry data record. Each registry data record in this table will correspond to only one encounter. To link to that encounter, use the first line of RDI_PAT_CSN.PAT_CSN.
                qmi.ACUITY_SYSTEM_ID,                                            --This item stores the scoring system record ID from which the scores are calculated and stored, if applicable. This item is populated when the RDI record is created.
                ac.ACUITY_SYSTEM_NAME,
                ac.DISPLAY_NAME                                 'ACUITY_SYSTEM_DISPLAY_NAME',   
                CONVERT(VARCHAR(16),acs.SCORE_FILE_LOC_DTTM,20) 'SCORE_TIME_LOC', --This column stores the instant at which the scoring system information is filed in local time. It is calculated from the UTC rule filing instant.
                acs.TOTAL_SCORE

INTO            #sofa

FROM            #list                               pe
    INNER JOIN  Clarity.dbo.RDI_PAT_CSN             rdc ON  rdc.PAT_CSN             =   pe.PAT_ENC_CSN_ID
    INNER JOIN  Clarity.dbo.QM_GEN_INFO             qmi ON  qmi.REGISTRY_DATA_ID    =   rdc.REGISTRY_DATA_ID
                                                        AND qmi.ACUITY_SYSTEM_ID    =   100101  --SOFA
    INNER JOIN  Clarity.dbo.ACUITY_SCORE_SPECIFIC   acs ON  acs.REGISTRY_DATA_ID    =   qmi.REGISTRY_DATA_ID
    INNER JOIN  Clarity.dbo.ACUITY_CONFIG           ac  ON  ac.ACUITY_SYSTEM_ID     =   qmi.ACUITY_SYSTEM_ID










/***************************************************************************************************************
                    DROP TABLE CHECK - REPORTS
***************************************************************************************************************/

DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_1 ;             --Basic info/demographics
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_2 ;             --Adverse events
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_3 ;             --Research adverse events
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_4 ;             --Labs
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_5 ;             --Medications
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_6 ;             --Vitals
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_7 ;             --SOFA
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_8 ;             --All DX - ICD-9
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_9 ;             --All DX - ICD-10
DROP TABLE IF EXISTS radb.rsh.COLSTAT_Report_10 ;            --All DX - Detail



/***************************************************************************************************************
                    REPORTS
***************************************************************************************************************/

/*  2021-01-20: Not sure what data points specifically I'm sending (or to whom) -- also need to check whether
    there are restrictions on timing (before/after consented) and/or PHI (i.e., if certain variables would un-
    blind the data).                                                                                        */

/*
    Box:

    Export log:
        -   2021-01-20: Have run 4 files (basic/demographics, medications, labs, vitals) but have not yet
            sent them to anyone.
*/

/*
    SELECT  'l.' + c.name + ',' 'select'
    FROM    tempdb.sys.columns c
    WHERE   c.object_id = OBJECT_ID(N'tempdb.dbo.#sofa')
    ORDER BY c.column_id
*/

----------------Basic info/demographics [file name: 155165_COLSTAT_Patient_List_With_Demographics_2021_04_21.txt]
SET NOCOUNT ON ;
--truncate table radb.rsh.COLSTAT_Report_1;
--insert into radb.rsh.COLSTAT_Report_1
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
            --  l.PAT_NAME,
                l.BIRTH_DATE,
                l.DEATH_DATE,
                l.AGE_DEATH_OR_RUN_DATE,
            --  l.SEX_C,
                l.SEX,
                l.ENROLLMENT_ID,
            --  l.RESEARCH_STUDY_ID,
            --  l.RESEARCH_STUDY_NAME,
            --  l.STUDY_CODE,
            --  l.IRB_APPROVAL_NUM,
            --  l.RESEARCH_STATUS_C,
            --  l.RESEARCH_STUDY_STATUS,
            --  l.ENROLL_STATUS_C,
                l.STUDY_BRANCH_ID,
                l.ENROLL_STATUS,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
            --  l.ETHNIC_GROUP_C,
            --  l.ETHNICITY,
            --  l.PATIENT_RACE_C,
            --  l.PRIMARY_RACE,
                l.MULTI_RACIAL_YN,
                l.PATIENT_RACE_ALL,
                l.RACE_AMERICAN_INDIAN_OR_ALASKA_NATIVE_YN,
                l.RACE_ASIAN_YN,
                l.RACE_BLACK_OR_AFRICAN_AMERICAN_YN,
                l.RACE_NATIVE_HAWAIIAN_OR_OTHER_PACIFIC_ISLANDER_YN,
                l.RACE_OTHER_YN,               
                l.RACE_WHITE_OR_CAUCASIAN_YN,
                l.RACE_UNKNOWN_YN,
                l.PATIENT_ETHNICITY 'ETHNICITY',
                l.ETHNICITY_HISPANIC_OR_LATINO_YN,
                l.ETHNICITY_NON_HISPANIC_YN,
                l.ETHNICITY_UNKNOWN_YN,
            --  l.EDU_LEVEL_C,
            --  l.EDU_LEVEL,
            --  l.YEARS_EDUCATION,
            --  l.LINE,
                se.SMOKING_STATUS_AT_ENCOUNTER,
                sc.MOST_RECENT_SMOKING_STATUS,
            --  l.FIRST_CONSENTED_DATE,
                l.PAT_ENC_CSN_ID,
                l.HSP_ACCOUNT_ID,
                l.HOSPITAL_AREA_ID,
                l.HOSPITAL_AREA_NAME,
            --  l.INPATIENT_DATA_ID,
            --  l.ED_EPISODE_ID,
                l.HOSP_ADMSN_TIME,
            --  l.HOSP_ADMSN_DATE,
                l.HOSP_DISCH_TIME,
            --  l.HOSP_DISCH_DATE,
                l.ADT_ARRIVAL_TIME,
            --  l.ADT_ARRIVAL_DATE,
            --  l.EMER_ADM_TIME,
            --  l.EMER_ADM_DATE,
            --  l.OP_ADM_TIME,
            --  l.OP_ADM_DATE,
            --  l.INP_ADM_TIME,
            --  l.INP_ADM_DATE,
                l.ED_DEPARTURE_TIME,
            --  l.ED_DEPARTURE_DATE,            
            --  l.ENC_DEPT_ID,
            --  l.ENC_DEPT,
            --  l.ENC_DEPT_EXTERNAL_NAME,
            --  l.ENC_DEPT_SPECIALTY,
            --  l.ACCT_BASECLS_HA_C,
            --  l.ACCT_BASECLS_HA,
            --  l.ACCT_CLASS_HA_C,
            --  l.ACCT_CLASS_HA,
            --  l.ADT_PAT_CLASS_C,
            --  l.ADT_PAT_CLASS,
            --  l.PRIM_SVC_HA_C,
            --  l.PRIM_SVC_HA,
            --  l.ADMIT_SOURCE_C,
                l.ADMIT_SOURCE,
            --  l.ED_DISPOSITION_C,
                l.ED_DISPOSITION,
            --  l.DISCH_DISP_C,
                l.DISCH_DISP

INTO radb.rsh.COLSTAT_Report_1

FROM            #list           l
--  LEFT JOIN   #pr             pr ON pr.PAT_ID         = l.PAT_ID
    LEFT JOIN   #smokingcurrent sc ON sc.PAT_ID         = l.PAT_ID
    LEFT JOIN   #smokingenc     se ON se.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID

ORDER BY        l.PAT_ID,
                l.HOSP_ADMSN_TIME,
                l.PAT_ENC_CSN_ID

----------------Adverse events [file name: 155165_COLSTAT_Adverse_Events_2021_01_29.txt]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
            --  l.PAT_NAME,
                l.BIRTH_DATE,
                l.DEATH_DATE,
                l.AGE_DEATH_OR_RUN_DATE,
                l.STUDY_BRANCH_ID,  --[2021-02-03]
                l.ENROLL_STATUS,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
            --  l.FIRST_CONSENTED_DATE,
                l.PAT_ENC_CSN_ID,
                l.HSP_ACCOUNT_ID,
                l.HOSPITAL_AREA_ID,
                l.HOSPITAL_AREA_NAME,
            --  l.INPATIENT_DATA_ID,
            --  l.ED_EPISODE_ID,
                l.HOSP_ADMSN_TIME,
            --  l.HOSP_ADMSN_DATE,
                l.HOSP_DISCH_TIME,
            --  l.HOSP_DISCH_DATE,
            --  l.ADT_ARRIVAL_TIME,
            --  l.ADT_ARRIVAL_DATE,
            --  l.EMER_ADM_TIME,
            --  l.EMER_ADM_DATE,
            --  l.OP_ADM_TIME,
            --  l.OP_ADM_DATE,
            --  l.INP_ADM_TIME,
            --  l.INP_ADM_DATE,
            --  l.ED_DEPARTURE_TIME,
            --  l.ED_DEPARTURE_DATE,            
            --  l.ENC_DEPT_ID,
            --  l.ENC_DEPT,
            --  l.ENC_DEPT_EXTERNAL_NAME,
            --  l.ENC_DEPT_SPECIALTY,
            --  l.ACCT_BASECLS_HA_C,
            --  l.ACCT_BASECLS_HA,
            --  l.ACCT_CLASS_HA_C,
            --  l.ACCT_CLASS_HA,
            --  l.ADT_PAT_CLASS_C,
            --  l.ADT_PAT_CLASS,
            --  l.PRIM_SVC_HA_C,
            --  l.PRIM_SVC_HA,
            --  l.ADMIT_SOURCE_C,
                l.ADMIT_SOURCE,
            --  l.ED_DISPOSITION_C,
                l.ED_DISPOSITION,
            --  l.DISCH_DISP_C,
                l.DISCH_DISP,

            ----ICU flags
                CASE WHEN EXISTS (SELECT 1 FROM #icu x WHERE x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID)
                    THEN 1 ELSE 0 END   'ICU_ANY_TIME_YN',
                CASE WHEN EXISTS (SELECT 1 FROM #icu x WHERE x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID AND x.AFTER_CONSENTED_YN = 1)
                    THEN 1 ELSE 0 END   'ICU_AFTER_CONSENTED_YN',

            ----Vent flags
                CASE WHEN v.VENT_STARTED_AFTER_CONSENTED_YN IS NOT NULL
                    THEN 1 ELSE 0 END   'VENT_ANY_TIME_YN',
                v.VENT_STARTED_AFTER_CONSENTED_YN,
                v.VENT_ENDED_AFTER_CONSENTED_YN,

            ----[2021-02-03] Dialysis flags
                CASE WHEN d.DIALYSIS_ORD_AFTER_CONSENTED_YN IS NOT NULL
                    THEN 1 ELSE 0 END   'DIALYSIS_YN',
                d.DIALYSIS_ORD_AFTER_CONSENTED_YN,
                d.DIALYSIS_STARTED_AFTER_CONSENTED_YN,

            ----[2021-02-03] Lab sum
                s.FIRST_CREATININE,
                s.HIGHEST_CREATININE,
                s.FIRST_ALT,
                s.HIGHEST_ALT,
                s.FIRST_AST,
                s.HIGHEST_AST,
                s.FIRST_TROPONIN,
                s.HIGHEST_TROPONIN,
                s.FIRST_TROPONIN_I,
                s.HIGHEST_TROPONIN_I,
                s.FIRST_TROPONIN_T,
                s.HIGHEST_TROPONIN_T,

            ----[2021-02-08] Medication sum
                m.COLCHICINE_ORDER_YN,
                m.ROSUVASTATIN_ORDER_YN,
                m.FIRST_COLCHICINE_ORDER_TIME,
                m.FIRST_ROSUVASTATIN_ORDER_TIME,
                m.COLCHICINE_GIVEN_YN,
                m.ROSUVASTATIN_GIVEN_YN,
                m.FIRST_COLCHICINE_GIVEN_TIME,
                m.LAST_COLCHICINE_GIVEN_TIME,
                m.FIRST_ROSUVASTATIN_GIVEN_TIME,
                m.LAST_ROSUVASTATIN_GIVEN_TIME,
                m.FIRST_COLCHICINE_DISCONTINUE_TIME,
                m.LAST_COLCHICINE_DISCONTINUE_TIME,
                m.FIRST_ROSUVASTATIN_DISCONTINUE_TIME,
                m.LAST_ROSUVASTATIN_DISCONTINUE_TIME

INTO radb.rsh.COLSTAT_Report_2


FROM            #list   l
    LEFT JOIN   #labsum s ON s.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID --[2021-02-03]
    LEFT JOIN   #medsum m ON m.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID --[2021-02-08]

    ------------[2021-01-29] Vent flag
    OUTER APPLY (
                    SELECT  MAX(x.START_AFTER_CONSENTED_YN) 'VENT_STARTED_AFTER_CONSENTED_YN',
                            MAX(x.END_AFTER_CONSENTED_YN)   'VENT_ENDED_AFTER_CONSENTED_YN'
                    FROM    #vent x
                    WHERE   x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID
                )       v

    ------------[2021-02-03] Dialysis flag
    OUTER APPLY (
                    SELECT  MAX(x.ORDERED_AFTER_CONSENTED_YN) 'DIALYSIS_ORD_AFTER_CONSENTED_YN',
                            MAX(x.STARTED_AFTER_CONSENTED_YN) 'DIALYSIS_STARTED_AFTER_CONSENTED_YN'
                    FROM    #dialysis x
                    WHERE   x.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID
                )       d

ORDER BY        l.PAT_ID,
                l.HOSP_ADMSN_TIME,
                l.PAT_ENC_CSN_ID

----------------Research adverse events (from research activity) [file name: 155165_COLSTAT_Research_Adverse_Events.txt] [2021-05-28]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.ENROLLMENT_ID,
            --  l.STUDY_BRANCH_ID,
                l.RESEARCH_STUDY_ID,
                l.RESEARCH_STUDY_NAME,
            --  l.STUDY_CODE,
            --  l.IRB_APPROVAL_NUM,
            --  l.RESEARCH_STATUS_C,
            --  l.RESEARCH_STUDY_STATUS,
            --  l.ENROLL_STATUS_C,
            --  l.ENROLL_STATUS,
            --  l.ENROLL_START_DT,
            --  l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
                l.FIRST_CONSENTED_DATE,
                l.HSP_ACCOUNT_ID,
                l.PAT_ENC_CSN_ID,
                l.ADVERSE_EVENT_ID,
                l.DX_ID,
                l.DX_NAME,
                l.CURRENT_ICD9_LIST,
                l.CURRENT_ICD10_LIST,
                l.RESEARCH_ATTRIBUTION_C,
                l.RESEARCH_ATTRIBUTION,
                l.EXPECTED_YN,
                l.SERIOUS_YN,
                l.MOST_RECENT_GRADE,
                l.MOST_RECENT_GRADE_NAME,
                l.MOST_RECENT_GRADE_START_DATE,
                l.MOST_RECENT_GRADE_EDIT_TIME,
                l.MOST_RECENT_GRADE_EDIT_USER_ID,
                l.MOST_RECENT_GRADE_EDIT_USER_NAME,
                l.ADVERSE_EVENT_STATUS_C,
                l.ADVERSE_EVENT_STATUS,
                l.NOTED_DATE,
                l.DATE_OF_ENTRY,
                l.RESOLVED_DATE,
                l.NOTE_ID,
                l.HX_NOTE_CSN,
                l.NOTE_TEXT

INTO radb.rsh.COLSTAT_Report_3

FROM            #advevent l

ORDER BY        l.PAT_ID,
                l.PAT_ENC_CSN_ID,
                l.DX_NAME

----------------Labs [file name: 155165_COLSTAT_Labs_2021_01_20.txt]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.BIRTH_DATE,
                l.ENROLLMENT_ID,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
            --  l.FIRST_CONSENTED_DATE,
                l.PAT_ENC_CSN_ID,
                l.HSP_ACCOUNT_ID,
                l.HOSP_ADMSN_TIME,
                l.HOSP_DISCH_TIME,
                l.ORDER_PROC_ID,
            --  l.ORDERING_DATE,
                l.ORDER_INST,
                l.ORDERED_AFTER_CONSENT_DTTM_YN,
            --  l.ORDERED_AFTER_CONSENT_DATE_YN,
            --  l.SPECIMN_TAKEN_DATE,
                l.SPECIMN_TAKEN_TIME,
                l.SPECIMEN_AFTER_CONSENT_DTTM_YN,
            --  l.SPECIMEN_AFTER_CONSENT_DATE_YN,
            --  l.RESULT_DATE,
                l.RESULT_TIME,
                l.RESULT_AFTER_CONSENT_DTTM_YN,
            --  l.RESULT_AFTER_CONSENT_DATE_YN,
            --  l.ORDER_TYPE_C,
                l.ORDER_TYPE,
                l.SPECIMEN_TYPE,
                l.PROC_ID,
                l.PROC_NAME,
                l.DISPLAY_NAME,
                l.ABNORMAL_YN,
                l.RESULT_LINE,
                l.COMPONENT_ID,
                l.COMPONENT_NAME,
                l.COMMON_NAME,
                l.BASE_NAME,
                l.ORD_VALUE,
                l.ORD_NUM_VALUE,
            --  l.RESULT_FLAG_C,
                l.RESULT_FLAG,
                l.REFERENCE_UNIT,
                l.COMPONENT_COMMENT
            --  l.ORDER_NARRATIVE

INTO radb.rsh.COLSTAT_Report_4

FROM            #labs l

ORDER BY        l.PAT_ID,
                l.HOSP_ADMSN_TIME,
                l.PAT_ENC_CSN_ID,
                l.ORDER_INST,
                l.ORDER_PROC_ID,
                l.RESULT_LINE

----------------Medications [file name: 155165_COLSTAT_Medications_2021_01_20.txt]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.BIRTH_DATE,
                l.ENROLLMENT_ID,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
            --  l.FIRST_CONSENTED_DATE,
                l.PAT_ENC_CSN_ID,
                l.HSP_ACCOUNT_ID,
                l.HOSP_ADMSN_TIME,
                l.HOSP_DISCH_TIME,
                l.ORDER_MED_ID,
                l.ORDER_INST,
            --  l.ORDERING_DATE,
                l.ORDERED_AFTER_CONSENT_DTTM_YN,
            --  l.ORDERED_AFTER_CONSENT_DATE_YN,
            --  l.ORDER_CLASS_C,
                l.ORDER_CLASS,
            --  l.ORDERING_MODE_C,
                l.ORDERING_MODE,
            --  l.ORDER_SOURCE_C,
                l.ORDER_SOURCE,
                l.USER_OVERRIDE_YN,
                l.REORDERED_YN,
                l.MODIFIED_YN,
                l.ORDER_MODE,
                l.DISCONTINUE_MODE,
                l.ORDERING_PROV_ID,
                l.ORD_PROV_NAME,
                l.ORD_PROV_TYPE,
                l.AUTHORIZING_PROV_ID,
                l.AUTHORIZING_PROV_NAME,
                l.AUTHORIZING_PROV_TYPE,
                l.MEDICATION_ID,
                l.MEDICATION_NAME,
                l.GENERIC_NAME,
            --  l.SIMPLE_GENERIC_C,
                l.SIMPLE_GENERIC,
            --  l.THERA_CLASS_C,
                l.THERA_CLASS,
            --  l.PHARM_CLASS_C,
                l.PHARM_CLASS,
            --  l.PHARM_SUBCLASS_C,
                l.PHARM_SUBCLASS,
                l.MAR_LINE,
                l.MAR_ACTION,
                l.MAR_ACTION_TAKEN_TIME,
                l.MAR_ACTION_AFTER_CONSENT_DTTM_YN,
            --  l.MAR_ACTION_AFTER_CONSENT_DATE_YN,
                l.INFUSION_END_TIME,
            --  l.ROUTE_C,
                l.MEDICATION_ROUTE,
                l.MEDICATION_DOSE,
            --  l.DOSE_UNIT_C,
                l.MEDICATION_UNIT,
            --  l.FREQ_ID,
                l.FREQUENCY,
                l.INFUSION_RATE,
                l.INFUSION_RATE_UNIT,
                l.DURATION,
            --  l.MAR_DURATION_UNIT_C,
                l.DURATION_UNIT

INTO radb.rsh.COLSTAT_Report_5

FROM            #mar l

ORDER BY        l.PAT_ID,
                l.HOSP_ADMSN_TIME,
                l.PAT_ENC_CSN_ID,
                l.ORDER_INST,
                l.ORDER_MED_ID,
                l.MAR_LINE

----------------Vitals [file name: 155165_COLSTAT_Vitals_2021_01_20.txt]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.BIRTH_DATE,
                l.ENROLLMENT_ID,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
            --  l.FIRST_CONSENTED_DATE,
                l.PAT_ENC_CSN_ID,
                l.HSP_ACCOUNT_ID,
                l.HOSP_ADMSN_TIME,
                l.HOSP_DISCH_TIME,
                f.RECORDED_TIME,
            --  f.RECORDED_AFTER_CONSENT_DTTM_YN,
            --  f.RECORDED_AFTER_CONSENT_DATE_YN,
                f.FLO_MEAS_ID,
                f.FLO_MEAS_NAME,
                f.DISP_NAME,
                f.MEAS_VALUE,
                f.UNITS,
            --  f.UNIT,
            --  f.VAL_TYPE_C,
                f.VAL_TYPE

INTO radb.rsh.COLSTAT_Report_6

FROM            #list   l
    INNER JOIN  #vitals f ON f.PAT_ENC_CSN_ID = l.PAT_ENC_CSN_ID

ORDER BY        l.PAT_ID,
                l.HOSP_ADMSN_TIME,
                l.PAT_ENC_CSN_ID,
                f.RECORDED_TIME,
                f.FLO_MEAS_NAME

----------------SOFA [file name: 155165_COLSTAT_SOFA_2021_05_28.txt] [2021-05-28]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.PAT_ENC_CSN_ID,
                l.REGISTRY_DATA_ID,
            --  l.PAT_DATE,
                l.ACUITY_SYSTEM_ID,
                l.ACUITY_SYSTEM_NAME,
                l.ACUITY_SYSTEM_DISPLAY_NAME,
                l.SCORE_TIME_LOC,
                l.TOTAL_SCORE

INTO radb.rsh.COLSTAT_Report_7


FROM            #sofa l

ORDER BY        l.PAT_ID,
                l.PAT_ENC_CSN_ID,
                l.SCORE_TIME_LOC,
                l.TOTAL_SCORE

----------------All DX - ICD-9 [file name: 155165_COLSTAT_All_DX_ICD9.txt]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.BIRTH_DATE,
                l.ENROLLMENT_ID,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
            --  l.FIRST_CONSENTED_DATE,
                l.PAT_ENC_CSN_ID,
                l.HSP_ACCOUNT_ID,
                l.HOSP_ADMSN_TIME,
                l.HOSP_DISCH_TIME,
                dx.ICD_CODE 'ICD9_CODE',
                dx.FIRST_DX_DATE,
                dx.LAST_DX_DATE,
                dx.ENCOUNTER_DX_YN,
                dx.PROB_LIST_DX_YN,
                dx.HOSP_BILLING_DX_YN,
                dx.ARPB_DX_YN


INTO radb.rsh.COLSTAT_Report_8


FROM            #list     l
    INNER JOIN  #dxsumicd dx ON dx.PAT_ID = l.PAT_ID

WHERE           dx.ICD_VERSION = 9

ORDER BY        l.PAT_ID,
                l.HOSP_ADMSN_TIME,
                l.PAT_ENC_CSN_ID,
                dx.ICD_CODE
    
----------------All DX - ICD-10 [file name: 155165_COLSTAT_All_DX_ICD10.txt]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.BIRTH_DATE,
                l.ENROLLMENT_ID,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
            --  l.FIRST_CONSENTED_DATE,
                l.PAT_ENC_CSN_ID,
                l.HSP_ACCOUNT_ID,
                l.HOSP_ADMSN_TIME,
                l.HOSP_DISCH_TIME,
                dx.ICD_CODE 'ICD10_CODE',
                dx.FIRST_DX_DATE,
                dx.LAST_DX_DATE,
                dx.ENCOUNTER_DX_YN,
                dx.PROB_LIST_DX_YN,
                dx.HOSP_BILLING_DX_YN,
                dx.ARPB_DX_YN

INTO radb.rsh.COLSTAT_Report_9


FROM            #list     l
    INNER JOIN  #dxsumicd dx ON dx.PAT_ID = l.PAT_ID

WHERE           dx.ICD_VERSION = 10

ORDER BY        l.PAT_ID,
                l.HOSP_ADMSN_TIME,
                l.PAT_ENC_CSN_ID,
                dx.ICD_CODE

----------------All DX - Detail [file name: 155165_COLSTAT_All_DX_Detail.txt]
SET NOCOUNT ON ;
SELECT          l.PAT_ID,
                l.PAT_MRN_ID,
                l.BIRTH_DATE,
                l.ENROLLMENT_ID,
                l.ENROLL_START_DT,
                l.ENROLL_END_DATE,
                l.FIRST_CONSENTED_DTTM,
            --  l.FIRST_CONSENTED_DATE,
                l.PAT_ENC_CSN_ID,
                l.HSP_ACCOUNT_ID,
                l.HOSP_ADMSN_TIME,
                l.HOSP_DISCH_TIME,
                dx.CURRENT_ICD9_LIST,
                dx.CURRENT_ICD10_LIST,
                dx.DX_ID,
                dx.DX_NAME,
                dx.FIRST_DX_DATE,
                dx.LAST_DX_DATE,
                dx.ENCOUNTER_DX_YN,
                dx.PROB_LIST_DX_YN,
                dx.HOSP_BILLING_DX_YN,
                dx.ARPB_DX_YN

INTO radb.rsh.COLSTAT_Report_10


FROM            #list  l
    INNER JOIN  #dxsum dx ON dx.PAT_ID = l.PAT_ID

ORDER BY        l.PAT_ID,
                l.HOSP_ADMSN_TIME,
                l.PAT_ENC_CSN_ID,
                dx.DX_NAME




END
GO
