
/*
Request: 2548380
Name: Association of peri-operative factors, surgical and pathological details
		with long-term clinical outcomes in patients with endocrine tumors
PI: Ramirez, Adriana
Requestor: Ramirez, Adriana
IRB #: 2000024931
Completed by: Harris Wadson
Created on: 06/04/24
Purpose: Abstract/Publication

Details:
- MRN list provided (adult patients), demographics needed:

First name 
Last name
MRN
DOS 
Case number (path)
DOB
Age 
Race
Ethnicity 
Sex
Insurance
CCI 
Pre-op TSH (closest to surgery date)
Thyroid hormone medication prior to DOS (Y/N)
ASA
BMI
Height 
Weight

*/



--select top 100 * from or_log where CASE_REQUEST_ID like '%SR22%'

--select top 100 * from surgical_hx;
--select top 100 * from or_case where or_case_id like '%SR22%' --> consult needed for surgery_dates, or ask john


--select distinct * from RADB.rsh.Task2548380_PatientList
--	where diagnosis not like '%thyroid%'	--> 0
--		and diagnosis not like '%thryoid%';	--> 2


--select distinct * from [RADB].[dbo].[CoPath_PatientSpecimens]
--where SpecimenNumber in (select distinct case_num from RADB.rsh.Task2548380_PatientList)

DROP TABLE IF EXISTS #final_pat;
SELECT DISTINCT 
p.PAT_ID,
p.PAT_FIRST_NAME,
p.PAT_LAST_NAME,
p.PAT_NAME,
pl.CASE_NUM 'CASE_NUMBER',
cps.SpecimenNumber,
cps.SpecimenDate,
pl.MRN 'PAT_MRN_ID',
p.BIRTH_DATE 'DOB',
zpr.NAME 'RACE',
eth.NAME 'ETHNICITY',
zs.NAME 'GENDER'

INTO #final_pat

FROM RADB.rsh.Task2548380_PatientList pl
INNER JOIN CLARITY.DBO.PATIENT p ON p.PAT_MRN_ID = pl.MRN 
----Check if a valid research patient who is not deceased -------------
INNER JOIN RADB.RSH.ValidResearchPatient vrp ON vrp.pat_id=p.pat_id 
                                             AND vrp.exclude_research_yn=0 
											 AND LIVING_YN = 1 
											 
LEFT OUTER JOIN CLARITY.DBO.ZC_SEX	zs				ON p.SEX_C			=	zs.RCPT_MEM_SEX_C
LEFT OUTER JOIN CLARITY.DBO.PATIENT_RACE	pr		ON p.PAT_ID			=	pr.PAT_ID 
                                                    AND pr.LINE = 1
LEFT OUTER JOIN CLARITY.DBO.ZC_PATIENT_RACE	zpr	ON pr.PATIENT_RACE_C = zpr.PATIENT_RACE_C
LEFT OUTER JOIN CLARITY.DBO.ZC_ETHNIC_GROUP	eth	ON p.ETHNIC_GROUP_C	=	eth.ETHNIC_GROUP_C
LEFT JOIN [RADB].[dbo].[CoPath_PatientSpecimens] cps on pl.case_num = cps.SpecimenNumber
LEFT OUTER JOIN RADB.dbo.OPT_OUT_PATIENTS_JDAT_RESEARCH_TEAM roptout ON p.PAT_ID = roptout.PAT_ID -- Checks for research opt out
LEFT OUTER JOIN RADB.dbo.OPT_OUT_STUDENTS_JDAT_RESEARCH_TEAM soptout ON p.PAT_MRN_ID = soptout.PAT_MRN_ID --checks for student status
WHERE (soptout.PAT_MRN_ID IS NULL AND roptout.PAT_ID IS NULL)	--> opt-out check
ORDER BY pl.MRN
;

-- select * from #final_pat;









	




/* SURGERIES /INTERVENTIONS + ASA STATUS */

DROP TABLE IF EXISTS #surg2;
SELECT DISTINCT
		 orlp.PAT_ID
		,orlp.PAT_MRN_ID
		,orlp.CSN
		,orlp.SURGERY_DATE
		--,orlp.HSP_ACCOUNT_ID
		--,orlp.LOSDays
		--,orlp.LOSHours
		,orlp.HOSP_ADMSN_TIME
		,orlp.HOSP_DISCH_TIME
		,orlp.DischargeDisposition
		--,orlp.SurgicalCSN
		--,orlp.AnesCSN
		,orlp.PROC_NAME
		,orlp.CPTCODE
		--,orlp.[Admission Type] 'ADMISSION_TYPE'
		--,orlp.ORService
		--,SurgeryLocation
		,zr.NAME ASA_STATUS
		,zr.ASA_RATING_C
INTO #surg2
FROM 
 (SELECT DISTINCT PAT_ID FROM #final_pat )  fp 
INNER JOIN RADB.DBO.vw_orl_allproc orlp ON orlp.PAT_ID = fp.PAT_ID
LEFT OUTER JOIN CLARITY.DBO.OR_LOG orl 	ON orlp.LOG_ID = orl.LOG_ID
LEFT OUTER JOIN CLARITY.DBO.ZC_OR_ASA_RATING zr ON zr.ASA_RATING_C = orl.ASA_RATING_C
WHERE orlp.PROC_NAME LIKE '%THYROID%' and orlp.PROC_NAME NOT LIKE '%PARA%'
 ORDER BY PAT_MRN_ID,SURGERY_DATE
;
-- select distinct * from #surg2;	--313 w/ pat_id, 0 w/ pat_mrn_id...








/* Get the insurance info */
DROP TABLE IF EXISTS #ins
SELECT DISTINCT p.PAT_ID,epm.PAYOR_NAME,
ROW_NUMBER() OVER(PARTITION BY p.PAT_ID ORDER BY PAYOR_NAME) INS_NO 
INTO #ins
FROM  #final_pat fp
INNER JOIN CLARITY.DBO.PATIENT p ON p.PAT_MRN_ID = fp.PAT_MRN_ID
INNER JOIN CLARITY.DBO.PAT_ACCT_CVG cvg ON cvg.PAT_ID = p.PAT_ID
                                             AND cvg.ACCOUNT_ACTIVE_YN = 'Y'
											 AND cvg.ACCOUNT_TYPE_C = 1
LEFT OUTER JOIN CLARITY.DBO.COVERAGE c ON c.COVERAGE_ID = cvg.COVERAGE_ID
LEFT OUTER JOIN CLARITY.DBO.CLARITY_EPM epm ON epm.PAYOR_ID = c.PAYOR_ID
LEFT JOIN #surg2 s2 on fp.PAT_ID = s2.pat_id
WHERE epm.PAYOR_NAME IS NOT NULL
--AND (c.CVG_EFF_DT <= s2.surgery_date) OR (c.CVG_EFF_DT <= fp.SpecimenDate)	--> null values for CVG_EFF_DT
ORDER BY p.PAT_ID
;
/*(1055 rows affected)*/
-- select * from #ins;









/* Get the most recent BMI, and height/weight*/
DROP TABLE IF EXISTS #pat_enc
select distinct *, ROW_NUMBER() OVER (PARTITION BY PAT_ID ORDER BY CONTACT_DATE DESC) ROWNO
into #pat_enc from (
SELECT DISTINCT fp.PAT_ID, fp.PAT_MRN_ID,
pe.PAT_ENC_CSN_ID,
cast(pe.CONTACT_DATE as date) 'CONTACT_DATE',
pe.BMI,
pe.HEIGHT,
pe.[WEIGHT]
FROM  #final_pat fp
INNER JOIN  CLARITy.DBO.PAT_ENC pe ON pe.PAT_ID = fp.PAT_ID
LEFT JOIN #surg2 s2 on fp.PAT_ID = s2.pat_id
WHERE BMI IS NOT NULL 
AND (pe.CONTACT_DATE < s2.surgery_date) OR (pe.CONTACT_DATE < fp.SpecimenDate)
) pat_enc
where height is not null
;
/*(2613 rows affected)*/

--SELECT distinct * FROM #pat_enc
--WHERE rowno = 1
--ORDER BY PAT_MRN_ID













/* Charlson Comorbidity Index (CCI) */

-- From 155432_d._2020_version.sql

--ccmi:
--select TOTAL_SCORE As CCI, CONTACT_DATE, rdc.PAT_CSN, OR_CASE_ID, oc.AdmitCSN, oc.PAT_ENC_CSN_ID
--,row_number() OVER (PARTITION BY OR_CASE_ID ORDER BY CONTACT_DATE DESC) as RowNum
DROP TABLE IF EXISTS #cci;
select 
distinct
row_number() OVER (PARTITION BY pe.pat_id ORDER BY pe.CONTACT_DATE DESC) 'row'
,pe.PAT_ID
,pe.PAT_ENC_CSN_ID
,cast(pe.CONTACT_DATE as date) 'CONTACT_DATE'
,TOTAL_SCORE As CCI
INTO #cci
from #final_pat fp inner join pat_enc pe on fp.pat_id = pe.pat_id
					inner join rdi_pat_csn rpc on rpc.PAT_CSN = pe.PAT_ENC_CSN_ID

					LEFT OUTER JOIN QM_GEN_INFO qmi ON rpc.REGISTRY_DATA_ID = qmi.REGISTRY_DATA_ID
					LEFT OUTER JOIN ACUITY_SCORE_SPECIFIC acs on rpc.REGISTRY_DATA_ID = acs.REGISTRY_DATA_ID
					LEFT JOIN #surg2 s2 on fp.PAT_ID = s2.pat_id

WHERE qmi.ACUITY_SYSTEM_ID = 100048 -- Charlson Comorbidity score HDA ID
AND (pe.CONTACT_DATE < s2.surgery_date)
AND (cast(pe.CONTACT_DATE as date) BETWEEN DATEADD(day, -(365), s2.surgery_date) AND s2.surgery_date
OR cast(pe.CONTACT_DATE as date) BETWEEN DATEADD(day, -(365), fp.SpecimenDate) AND fp.SpecimenDate)
;
/*(133 rows affected)*/
--SELECT * FROM #cci;
--SELECT COUNT(distinct pat_id) FROM #cci -->99
--SELECT * FROM #cci where row = 1
--SELECT COUNT(*) FROM #cci where row = 1




/* Pre-op TSH (closest to surgery date) */
drop table if exists #tsh;
select * into #tsh from (
	SELECT DISTINCT 
OP.PAT_ID, CC.[NAME], ORR.ORD_VALUE 'RESULT', ORR.RESULT_DATE, OP.PAT_ENC_CSN_ID,
	ROW_NUMBER() OVER (PARTITION BY OP.PAT_ID ORDER BY ORR.RESULT_TIME DESC  ) R1
	FROM ORDER_PROC OP
	INNER JOIN #final_pat fp on fp.pat_id = OP.pat_id
	--LEFT JOIN #surg1 s1 on fp.pat_id = s1.pat_id
	LEFT JOIN #surg2 s2 on fp.PAT_ID = s2.pat_id
	LEFT OUTER JOIN ORDER_RESULTS ORR ON OP.ORDER_PROC_ID=ORR.ORDER_PROC_ID
	LEFT OUTER JOIN CLARITY_COMPONENT CC ON CC.COMPONENT_ID=ORR.COMPONENT_ID
	WHERE (CC.NAME LIKE '%THYROID%' OR CC.NAME LIKE '%TSH%')
	--AND (ORR.RESULT_DATE < s1.SURGICAL_HX_DATE)
	AND ((ORR.RESULT_DATE < s2.surgery_date) OR (ORR.RESULT_DATE < fp.SpecimenDate))
	) lab
	where r1 = 1
;
	--> 246 w/ s2.surgery_date, 0 with s1.SURGICAL_HX_DATE
			--Error: Conversion failed when converting date and/or time from character string.

	-- select * from #tsh;







/*Thyroid hormone medication prior to DOS (Y/N)*/


drop table if exists #meds;
select distinct 
fp.PAT_ID,
fp.PAT_MRN_ID,
s2.SURGERY_DATE,
om.ORDERING_DATE	 
,om2.RX_WRITTEN_DATE [RX Written Date]
,cm.NAME [Medication Name]
,cm.GENERIC_NAME [Generic Name]
,om.AMB_MED_DISP_NAME [Display Name],
OM.START_DATE,
OM.END_DATE,
OM.DISCON_TIME,
ZC.NAME AS 'THERAPEUTIC_CLASS',
ZPC.NAME AS 'PHARM_CLASS',
ZP.NAME AS 'PHARM_SUBCLASS',
OM.SIG, 
OM.QUANTITY,
OM.REFILLS_REMAINING AS 'TOTAL_REFILLS_ORDERED',
ZAR.NAME AS 'ROA'
into #meds
from #final_pat fp
inner join order_med om on fp.PAT_ID = om.PAT_ID
inner join ORDER_MED_2 om2 on om.ORDER_MED_ID = om2.ORDER_ID
inner join clarity_medication cm on cm.MEDICATION_ID = om.MEDICATION_ID
LEFT JOIN   Clarity.dbo.RX_MED_TWO          rx2 ON  rx2.MEDICATION_ID   =   cm.MEDICATION_ID
LEFT JOIN   Clarity.dbo.ZC_ADMIN_ROUTE      zar ON  zar.MED_ROUTE_C     =   rx2.ADMIN_ROUTE_C
LEFT JOIN ZC_THERA_CLASS AS ZC ON ZC.THERA_CLASS_C = CM.THERA_CLASS_C
LEFT JOIN ZC_PHARM_SUBCLASS AS ZP ON ZP.PHARM_SUBCLASS_C = CM.PHARM_SUBCLASS_C
LEFT JOIN ZC_PHARM_CLASS AS ZPC ON ZPC.PHARM_CLASS_C = CM.PHARM_CLASS_C
LEFT JOIN #surg2 s2 on fp.PAT_ID = s2.pat_id
WHERE 
--(om.IS_PENDING_ORD_YN is null or om.IS_PENDING_ORD_YN <>'Y')
--AND (OM.ORDER_STATUS_C in ('2', '3', '5','9', '10', '11' ) OR OM.ORDER_STATUS_C is NULL)
cm.GENERIC_NAME like '%levothyroxine%' OR cm.GENERIC_NAME like '%liothyronine%'
--and om.ORDERING_MODE_C = 1 --outpatient ordering mode
and cast(om2.RX_WRITTEN_DATE as date) < s2.surgery_date OR cast(om2.RX_WRITTEN_DATE as date) < fp.SpecimenDate
;

/*(3069 rows affected)*/
--select distinct * from #meds;










/* Bringing it all together */
-- 'All Patients'
drop table if exists #output;
select distinct fp.*,
FLOOR(DATEDIFF(dd,fp.DOB,s2.SURGERY_DATE)/365.25) 'AGE_AT_PROCEDURE',
i.PAYOR_NAME 'INSURANCE',
pe.CONTACT_DATE,
pe.BMI,
pe.HEIGHT,
CAST(CAST(pe.WEIGHT AS NUMERIC(18,8))/16 AS NUMERIC(18,8)) 'WEIGHT',
(CASE WHEN m.PAT_MRN_ID is not null then 'YES' ELSE 'NO' END) AS 'THYROID_MEDS_PRE-OP'
into #output
from #final_pat fp
LEFT JOIN (SELECT * FROM #ins WHERE INS_NO = 1	) i ON i.PAT_ID = fp.PAT_ID	
LEFT JOIN (SELECT * FROM #pat_enc WHERE ROWNO = 1) pe ON pe.PAT_ID = fp.PAT_ID
LEFT JOIN #meds m on m.PAT_MRN_ID = fp.PAT_MRN_ID
LEFT JOIN #surg2 s2 on fp.PAT_ID = s2.pat_id
;

--select * from #output;
--select distinct pat_mrn_id from #output;
