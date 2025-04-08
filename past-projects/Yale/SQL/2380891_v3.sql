/*
Data elements needed:
MRN; date of bi rth; sex; race/ethnicity; eye operated on (L vs R); date of cataract operation (CPT 66982, 66984);
type of operation (CPT 66982 vs 66984); date of diagnosis of cataract (ICD-10 H25, H26, H28); date of diagnosis of anterior chamber inflammation (ICD-10 H20);
date of each clinic visit; diabetes (ICD-10 E08-13); hypertension (ICD-10 I10-16); congestive heart failure (ICD-10 I50); chronic kidney disease (ICD-10 N18);
diabetic retinopathy (ICD-10 E08.311-359, E09.311-359, E10.311-359, E11.311-359, E13.311-359); dry macular degeneration (ICD-10 H35.31); wet macular degeneration (ICD-10 H35.32);
recent intravitreal injection (CPT 67028); intraocular pressure; pre-operative visual acuity; post-operative visual acuity; visual acuity after resolution of inflammation;
PPV (CPT 67036); retinal detachment repair (CPT 67101, 67105, 67107, 67108, 67110, 67113); pre-operative hemoglobin A1c; grade of cataract; MIGS procedure (CPT 66989, 66991); floppy iris (ICD-10 H21.81)

Criteria:

What date range would you like to search? November 1, 2017 to present

Which departments would you like to search?  YM Ophthalmology (105290026)
											 YM Ophthalmology Stratford (106490001)
											 YM Ophthalmology Guilford (106280001)

Please list your inclusion criteria: Patients >18 years old diagnosed with anterior chamber inflammation following cataract surgery within the Yale New Haven Health System.
										- ICD-10: H25, H26, H28 - cataract
										- CPT: 66982, 66984 - cataract procedures
Please list your exclusion criteria: <18 years old

*/


/*
Changelog:

- Adding updated criteria (provided on 1/4/23)


*/

USE CLARITY

---------------------------------------------------------------------------------------------------
-----------Creating patient list driver based on ICD-10 code and Department ID---------------------
---------------------------------------------------------------------------------------------------

IF OBJECT_ID('TEMPDB..#PB_List') IS NOT NULL
  DROP TABLE #PB_List;

SELECT DISTINCT vdi.PAT_ID,
				p.PAT_MRN_ID,
				p.PAT_NAME,
				p.BIRTH_DATE,
				FLOOR(DATEDIFF(dd,p.BIRTH_DATE,GETDATE())/365.25) 'CURRENT_AGE',
				zs.NAME as 'Gender',
				eth.name AS 'Ethnicity',
				zrace.NAME AS 'Race',
				vdi.DX_ID, 
				eci.CODE 'ICD10_CODE', 
				ce.DX_NAME, 
				CAST(FIRST_DATE as date) 'FIRST_DX_DATE',
				d.DEPARTMENT_NAME,
				CAST(pe.CHECKIN_TIME as date) 'CHECKIN_TIME'
INTO   #PB_List
FROM       RADB.DBO.V_DIAGNOSIS_INFO_COPY vdi 
  INNER JOIN CLARITY.DBO.CLARITY_EDG ce ON vdi.DX_ID = ce.DX_ID
  INNER JOIN CLARITY.DBO.EDG_CURRENT_ICD10 eci ON ce.DX_ID = eci.DX_ID
  INNER JOIN Clarity.dbo.PATIENT p ON vdi.PAT_ID = p.PAT_ID
  INNER JOIN Clarity.dbo.PROBLEM_LIST pl ON pl.PAT_ID = p.PAT_ID 
  LEFT JOIN	PATIENT_TYPE PT  ON PT.PAT_ID = P.PAT_ID
  LEFT JOIN	ZC_PATIENT_TYPE	ZPT ON ZPT.PATIENT_TYPE_C = PT.PATIENT_TYPE_C 
  LEFT JOIN Clarity.dbo.PROBLEM_LIST_HX hx ON hx.PROBLEM_LIST_ID = pl.PROBLEM_LIST_ID
  LEFT JOIN Clarity.dbo.PAT_ENC pe ON pe.PAT_ENC_CSN_ID = hx.HX_PROBLEM_EPT_CSN
  LEFT JOIN Clarity.dbo.CLARITY_DEP d ON d.DEPARTMENT_ID = pe.DEPARTMENT_ID 
  LEFT JOIN ZC_Sex zs ON p.SEX_C = zs.RCPT_MEM_SEX_C
  LEFT JOIN ZC_ETHNIC_GROUP eth on p.ETHNIC_GROUP_C = eth.ETHNIC_GROUP_C
  LEFT JOIN patient_race race on p.PAT_ID = race.PAT_ID
  LEFT JOIN ZC_PATIENT_RACE zrace on race.PATIENT_RACE_C = zrace.PATIENT_RACE_C
WHERE
(ZPT.NAME <> 'Opt Out Research'  
OR
ZPT.NAME is NULL
)
AND
(
p.PAT_STATUS_C = '1'		--alive
OR
p.PAT_STATUS_C  IS NULL
)
AND (
	NUM_ENC_DX <> 0
	OR NUM_HSP_ACT_DX <> 0
	OR NUM_PROBLEM_LIST <> 0
	)
AND
p.PAT_NAME NOT LIKE 'zz%'
AND (
	eci.CODE LIKE 'H25.%' 
	OR eci.CODE LIKE 'H26.%' 
	OR eci.CODE LIKE 'H28.%' 
	)														--> Dx criteria (cataract)
AND (DATEDIFF(dd,p.BIRTH_DATE,GETDATE())/365.25) > 17			--> age >= 18 at time of query
AND d.DEPARTMENT_ID IN ('105290026', '106490001', '106280001')		--> Dept filter
AND pe.ENC_TYPE_C IN ('101', '2502', '1000', '1003', '2520', '50', '11')		--> clinic visits only: excluding orders (111), abstract (150), Erroneous Encounters (2505, 2506), Documentation (2515), Telephone (70) & Telemedicine (76)
;

/* (132,639 rows affected) */

--SELECT * FROM #PB_List
--SELECT COUNT(DISTINCT PAT_ID) FROM #PB_List --> 16214 patients

/*frequency table of encounter types*/
 --select distinct enc_type_c, count(distinct pat_id) from #PB_List	
 --group by enc_type_c
 --order by count(distinct pat_id) desc





--------------------------------------------------------------------
-----------Concatenating #PB_List into #PATBASE---------------------
--------------------------------------------------------------------
DROP TABLE IF EXISTS #PATBASE

SELECT DISTINCT
pbl.PAT_MRN_ID, pbl.PAT_ID, pbl.PAT_NAME, pbl.Gender, pbl.BIRTH_DATE,
	STUFF((    SELECT DISTINCT '; ' + CAST(A.Ethnicity AS varchar) AS [text()]
							FROM  #PB_List AS A
							WHERE A.PAT_MRN_ID = pbl.PAT_MRN_ID                
							FOR XML PATH('')
							), 1, 1, '' )
				AS Ethnicity,
	STUFF((    SELECT DISTINCT '; ' + CAST(A.Race AS varchar) AS [text()]
							FROM  #PB_List AS A
							WHERE A.PAT_MRN_ID = pbl.PAT_MRN_ID                
							FOR XML PATH('')
							), 1, 1, '' )
				AS Race,
	STUFF((    SELECT DISTINCT '; ' + CAST(A.ICD10_CODE AS varchar) AS [text()]
							FROM  #PB_List AS A
							WHERE A.PAT_MRN_ID = pbl.PAT_MRN_ID                
							FOR XML PATH('')
							), 1, 1, '' )
				AS ICD10_CODES,
	STUFF((    SELECT DISTINCT '; ' + CAST(A.DX_ID AS varchar) AS [text()]
							FROM  #PB_List AS A
							WHERE A.PAT_MRN_ID = pbl.PAT_MRN_ID                
							FOR XML PATH('')
							), 1, 1, '' )
				AS DX_ID,
	STUFF((    SELECT DISTINCT '; ' + A.DX_NAME AS [text()]
							FROM  #PB_List AS A
							WHERE A.PAT_MRN_ID = pbl.PAT_MRN_ID                
							FOR XML PATH('')
							), 1, 1, '' )
				AS DX_NAME,
	--STUFF((    SELECT DISTINCT '; ' + CAST(A.FIRST_DX_DATE as varchar)  AS [text()]
	--						FROM  #PB_List AS A
	--						WHERE A.PAT_MRN_ID = pbl.PAT_MRN_ID             
	--						FOR XML PATH('')
	--						), 1, 1, '' )
	--			AS CATARACT_DX_DATES,
	STUFF((    SELECT DISTINCT '; ' + CAST(A.CHECKIN_TIME as varchar)  AS [text()]
							FROM  #PB_List AS A
							WHERE A.PAT_MRN_ID = pbl.PAT_MRN_ID             
							FOR XML PATH('')
							), 1, 1, '' )
				AS CLINIC_VISIT_DATES
INTO #PATBASE
FROM #PB_List AS pbl;

/*(15837 rows affected)*/



/*Debug*/
--select * from #patbase where pat_id in ('Z3808175','Z3808175')

--SELECT pat_id FROM #PATBASE 
--group by pat_id
--having count(pat_id) > 1


/*********************************************************************************************************************
						Step 2 - Opt-out check of #PATBASE
*********************************************************************************************************************/

DROP TABLE IF EXISTS #opt_out

SELECT DISTINCT p.PAT_MRN_ID ,roptout.PAT_ID 'RESEARCH OPT_OUT' ,soptout.PAT_MRN_ID 'STUDENT_STATUS'
INTO #opt_out
FROM CLARITY.DBO.PATIENT p 
LEFT OUTER JOIN RADB.dbo.OPT_OUT_PATIENTS_JDAT_RESEARCH_TEAM roptout ON p.PAT_ID = roptout.PAT_ID -- Checks for research opt out
LEFT OUTER JOIN RADB.dbo.OPT_OUT_STUDENTS_JDAT_RESEARCH_TEAM soptout ON p.PAT_MRN_ID = soptout.PAT_MRN_ID --checks for student status
WHERE p.PAT_MRN_ID IN (SELECT PAT_MRN_ID FROM #PATBASE) 
AND (soptout.PAT_MRN_ID IS NOT NULL OR roptout.PAT_ID IS NOT NULL )

-- 24 patients have opted-out

DELETE FROM #PATBASE WHERE PAT_MRN_ID IN (SELECT PAT_MRN_ID FROM #opt_out);
--(24 rows affected)
DELETE FROM #PB_List WHERE PAT_MRN_ID IN (SELECT PAT_MRN_ID FROM #opt_out);
--(144 rows affected)


--SELECT * FROM #opt_out
--SELECT COUNT(*) FROM #PATBASE /* 14,974 rows */




---------------------------------------------------
---------------CATARACT PROCEDURES-----------------
---------------------------------------------------


IF OBJECT_ID('TEMPDB..#PROC_LIST') IS NOT NULL
  DROP TABLE #PROC_LIST;

SELECT	
  a.CPT_CODE,
  a.PROC_DATE,
  a.PAT_ENC_CSN_ID,
  a.PAT_ID,
  a.PAT_MRN_ID

INTO #PROC_LIST

FROM (
  SELECT
  e.PAT_ENC_CSN_ID,
  e.PAT_ID,
  d.PAT_MRN_ID,
  cpt.CPT_CODE,
  CAST(cpt.ORIG_SERVICE_DATE AS DATE)	'PROC_DATE'
FROM #PATBASE d
  INNER JOIN Clarity.dbo.PAT_ENC e ON e.PAT_ID = d.PAT_ID
  INNER JOIN Clarity.dbo.CLARITY_TDL_TRAN cpt ON cpt.PAT_ENC_CSN_ID = e.PAT_ENC_CSN_ID
WHERE 1=1

UNION ALL

SELECT
  e.PAT_ENC_CSN_ID,
  e.PAT_ID,
  d.PAT_MRN_ID,
  cpt.CPT_CODE,
  CAST(cpt.SERVICE_DATE AS DATE)	'PROC_DATE'
FROM #PATBASE d
  INNER JOIN Clarity.dbo.PAT_ENC e ON e.PAT_ID = d.PAT_ID
  INNER JOIN Clarity.dbo.ARPB_TRANSACTIONS cpt ON cpt.PAT_ENC_CSN_ID = e.PAT_ENC_CSN_ID
WHERE 1=1

UNION ALL

SELECT
  e.PAT_ENC_CSN_ID,
  e.PAT_ID,
  d.PAT_MRN_ID,
  cpt.CPT_CODE,
  CAST(cpt.SERVICE_DATE AS DATE)	'PROC_DATE'
FROM #PATBASE d
  INNER JOIN Clarity.dbo.PAT_ENC e ON e.PAT_ID = d.PAT_ID
  INNER JOIN Clarity.dbo.HSP_TRANSACTIONS cpt ON cpt.HSP_ACCOUNT_ID = e.HSP_ACCOUNT_ID
WHERE 1=1

UNION ALL

SELECT
  e.PAT_ENC_CSN_ID,
  e.PAT_ID,
  d.PAT_MRN_ID,
  cpt.CPT_CODE,
  CAST(cpt.CPT_CODE_DATE AS DATE)	'PROC_DATE'
FROM #PATBASE d
  INNER JOIN Clarity.dbo.PAT_ENC e ON e.PAT_ID = d.PAT_ID
  INNER JOIN Clarity.dbo.HSP_ACCT_CPT_CODES cpt ON cpt.HSP_ACCOUNT_ID = e.HSP_ACCOUNT_ID
WHERE 1=1

	) a
WHERE a.PAT_ID IN (SELECT PAT_ID FROM #PATBASE)
AND a.CPT_CODE IN ('66982', '66984')
AND a.PROC_DATE > '10/31/2017';			--> date range filter (11/1/17 to present)

/* (79,777 rows affected) */

--SELECT * from #PROC_LIST;
--SELECT COUNT(DISTINCT PAT_ID) FROM #PROC_LIST --> 4,113 patients


--------------------------------------------------------------------
-----------Concatenating #PROC_List into #Cataract_Surg_POP-------------
--------------------------------------------------------------------
DROP TABLE IF EXISTS #Cataract_Surg_POP

SELECT DISTINCT
pl.PAT_ID, pl.PAT_MRN_ID, CAST(pl.PROC_DATE as date) 'PROC_DATE',
STUFF((    SELECT DISTINCT '; ' + A.CPT_CODE AS [text()]
                        FROM  #PROC_LIST AS A
						WHERE A.PAT_ID = pl.PAT_ID                
                        FOR XML PATH('')
                        ), 1, 1, '' )
            AS CPT_CODES,
STUFF((    SELECT DISTINCT '; ' + CAST(A.FIRST_DX_DATE as varchar)  AS [text()]
						FROM  #PB_List AS A
						WHERE A.PAT_MRN_ID = pl.PAT_MRN_ID
						AND A.FIRST_DX_DATE <= pl.PROC_DATE
						FOR XML PATH('')
						), 1, 1, '' )
			AS CATARACT_DX_DATES
INTO #Cataract_Surg_POP
FROM #PROC_LIST AS pl;


/*(6,417 rows affected)*/

--SELECT * FROM #Cataract_Surg_POP




--------------------------------------------------------------------
------------------Operated Eye (R or L)-----------------------------
--------------------------------------------------------------------

DROP TABLE IF EXISTS #list_arpb;
DROP TABLE IF EXISTS #cataract_eye;

SELECT
p.PAT_ID
,at.*
,ce.PROC_NAME
INTO #list_arpb 
FROM  dbo.ARPB_TRANSACTIONS at INNER JOIN clarity_eap ce ON ce.PROC_ID = at.PROC_ID
                               INNER JOIN patient p ON p.pat_id = at.PATIENT_ID
							   INNER JOIN #PATBASE pb on pb.PAT_ID = at.PATIENT_ID
WHERE at.TX_TYPE_C = '1'		--charge
AND at.CPT_CODE IN ('66982', '66984');

SELECT DISTINCT PAT_ID, PAT_ENC_CSN_ID, SERVICE_DATE, la.modifier_one, la.modifier_two, la.modifier_three, la.modifier_four,
CASE WHEN la.modifier_one LIKE '%RT%' OR la.modifier_two LIKE '%RT%' OR la.modifier_three LIKE '%RT%' OR la.modifier_four LIKE '%RT%'
       THEN 'Y' ELSE '' end 'Probable_right_laterality',
CASE WHEN la.modifier_one LIKE '%LT%' OR la.modifier_two LIKE '%LT%' OR la.modifier_three LIKE '%LT%' OR la.modifier_four LIKE '%LT%'
       THEN 'Y' ELSE '' end 'Probable_left_laterality'

INTO #cataract_eye
FROM #list_arpb la;

/*(8764 rows affected)*/
--select * from #list_arpb where pat_id = 'Z100015'
--select * from #cataract_eye where pat_id = 'Z100015'


--> Check if this lines up with OR_PROC.OPERATING_REGION_C



--------------------------------------------------------------------
------------------Anterior Chamber Inflammation---------------------
--------------------------------------------------------------------

DROP TABLE IF EXISTS #H20_DX

SELECT DISTINCT vdi.PAT_ID, MIN(FIRST_DATE) 'H20_DX_DATE'
INTO #H20_DX
FROM RADB.DBO.V_DIAGNOSIS_INFO_COPY vdi 
INNER JOIN Clarity.dbo.CLARITY_EDG ce ON vdi.DX_ID = ce.DX_ID
INNER JOIN Clarity.dbo.EDG_CURRENT_ICD10 eci ON ce.DX_ID = eci.DX_ID
INNER JOIN #PATBASE pb ON pb.PAT_ID = vdi.PAT_ID
WHERE eci.CODE LIKE 'H20.%'					--> anterior chamber inflammation
GROUP BY vdi.PAT_ID;

/*(780 rows affected)*/
--SELECT COUNT(DISTINCT PAT_ID) FROM #H20_DX --> 780 patients
-- select * from #H20_DX





---------------------------------------------------
--------------------HB-A1C-------------------------
---------------------------------------------------

--DROP TABLE IF EXISTS #temp

--SELECT DISTINCT
--   res.PAT_ENC_CSN_ID
--  ,res.RESULT_DATE
--  ,pb.PAT_ID
--  ,pb.PAT_MRN_ID
--  ,cc.COMPONENT_ID
--  ,cc.NAME COMP
--  ,res.ORD_NUM_VALUE
--  ,res.ORD_VALUE
--INTO #temp
--FROM Clarity.dbo.ORDER_RESULTS res
--  INNER JOIN Clarity.dbo.ORDERS ord ON ord.ORDER_ID = res.ORDER_PROC_ID
--  INNER JOIN Clarity.dbo.ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID 
--  INNER JOIN Clarity.dbo.CLARITY_COMPONENT cc ON cc.COMPONENT_ID = res.COMPONENT_ID
--  INNER JOIN Clarity.dbo.PAT_ENC pe ON res.PAT_ENC_CSN_ID = pe.PAT_ENC_CSN_ID
--  INNER JOIN #PATBASE AS pb ON pb.PAT_ID = pe.PAT_ID
--  	WHERE upper(cc.EXTERNAL_NAME) like '%A1C%'
--	or upper(cc.COMMON_NAME) like '%A1C%'

----select count(*) from #temp

--select distinct component_id, comp, count(ORD_VALUE) 'RES_COUNT', count(distinct PAT_MRN_ID) 'PAT_COUNT'
--from #temp
--group by component_id, comp
--order by pat_count desc

--13943
--1558024
--720000058
--28664
--720000059
--28777
--409
--1810006

--select * from #temp where COMPONENT_ID in ('13943','1558024','720000058','28664','720000059','28777','409','1810006')



DROP TABLE IF EXISTS #Hb_A1C_List

-- tables used: ORDER_RESULTS, ORDER_PROC, ORDERS
SELECT DISTINCT
  res.PAT_ENC_CSN_ID
  ,PL.PAT_ID
  ,PL.PAT_MRN_ID
  ,cc.COMPONENT_ID
  ,cc.NAME 'LAB_NAME'
  ,res.RESULT_DATE
  ,res.ORD_NUM_VALUE
  ,res.ORD_VALUE
INTO #Hb_A1C_List
FROM Clarity.dbo.ORDER_RESULTS res
  INNER JOIN Clarity.dbo.ORDERS ord ON ord.ORDER_ID = res.ORDER_PROC_ID
  INNER JOIN Clarity.dbo.ORDER_PROC op ON res.ORDER_PROC_ID = op.ORDER_PROC_ID 
  INNER JOIN Clarity.dbo.CLARITY_COMPONENT cc ON cc.COMPONENT_ID = res.COMPONENT_ID
    AND cc.COMPONENT_ID IN ('13943','1558024','720000058','28664','720000059','28777','409','1810006')
    --AND res.ORD_NUM_VALUE > 30		-- not needed
    --AND res.ORD_NUM_VALUE <> 9999999	-- not needed
  INNER JOIN Clarity.dbo.PAT_ENC pe ON res.PAT_ENC_CSN_ID = pe.PAT_ENC_CSN_ID
  INNER JOIN #PROC_LIST AS PL ON PL.PAT_ID = pe.PAT_ID
  LEFT OUTER JOIN CLARITY.DBO.RES_DB_MAIN OVR ON op.ORDER_PROC_ID = OVR.RES_ORDER_ID
	AND ovr.RES_VAL_STATUS_C IN  ('9','1','20') 

  /*(16,227 rows affected)*/

--select * from #Hb_A1C_List


--------------------------------------------------------------------
--------Getting latest lab result from #Hb_A1C_List-----------------
--------------------------------------------------------------------
DROP TABLE IF EXISTS #Hb_A1C


SELECT distinct pl.PAT_ID, pl.PROC_DATE, hal.RESULT_DATE 'A1C_Date', hal.ORD_VALUE 'A1C_PreOp'
INTO #Hb_A1C
FROM
(
  SELECT hal.*, RN = ROW_NUMBER() OVER (PARTITION BY hal.PAT_ID ORDER BY hal.RESULT_DATE DESC) --> asc = earliest, desc = latest
  FROM #Hb_A1C_List AS hal
) AS hal
INNER JOIN #PROC_LIST pl on pl.PAT_ID = hal.PAT_ID
WHERE hal.RN = 1
and hal.RESULT_DATE < pl.PROC_DATE;

/*(900 rows affected)*/







--------------------------------------------------------------------
-------------COMORBIDITIES AND ASSOCIATED PROCEDURES----------------
--------------------------------------------------------------------

DROP TABLE IF EXISTS #Agg_Dx_Proc;

WITH comorb_check AS (
SELECT DISTINCT vdi.PAT_ID, eci.CODE, CAST(FIRST_DATE as date) 'DX_DATE'
FROM RADB.DBO.V_DIAGNOSIS_INFO_COPY vdi 
INNER JOIN Clarity.dbo.CLARITY_EDG ce ON vdi.DX_ID = ce.DX_ID
INNER JOIN Clarity.dbo.EDG_CURRENT_ICD10 eci ON ce.DX_ID = eci.DX_ID
INNER JOIN #PATBASE pb ON pb.PAT_ID = vdi.PAT_ID
WHERE  eci.CODE LIKE 'E08.%'		
	OR eci.CODE LIKE 'E09.%'	
	OR eci.CODE LIKE 'E10.%'	
	OR eci.CODE LIKE 'E11.%'	
	OR eci.CODE LIKE 'E13.%'		--> DM
	OR eci.CODE LIKE 'I10.%'	
	OR eci.CODE LIKE 'I11.%'
	OR eci.CODE LIKE 'I12.%'
	OR eci.CODE LIKE 'I13.%'
	OR eci.CODE LIKE 'I15.%'
	OR eci.CODE LIKE 'I16.%'		--> HTN
	OR eci.CODE LIKE 'I50.%'		--> congestive heart failure
	OR eci.CODE LIKE 'N18.%'		--> chronic kidney disease
	OR eci.CODE LIKE 'H35.31%'		--> dry macular degeneration
	OR eci.CODE LIKE 'H35.32%'		--> wet macular degeneration
	OR eci.CODE LIKE 'H21.81%'		--> floppy iris

	/* New additions from 1/4/23 */
	OR eci.CODE LIKE 'H20.0%'		--> Traumatic iritis diagnosis 
	OR eci.CODE LIKE 'H44.0%'		
	OR eci.CODE LIKE 'H44.1%'		--> Endophthalmitis 
	OR eci.CODE LIKE 'H59.0%'		--> Disorders of the eye following cataract surgery
	OR eci.CODE LIKE 'H59.01%'		--> Keratopathy 
	OR eci.CODE LIKE 'H59.02%'		--> Lens fragment in eye
	OR eci.CODE LIKE 'H59.03%'		--> Cystoid macular edema
	OR eci.CODE LIKE 'H59.09%'		--> Other disorders of the eye following cataract surgery
	OR eci.CODE LIKE 'E10.3%'		--> Type 1 diabetes mellitus with ophthalmic complications
	OR eci.CODE LIKE 'E11.3%'		--> Type 2 diabetes mellitus with ophthalmic complications

	

)	-- End CTE

-- select * from comorb_check




, proc_check AS (
SELECT	
  a.CPT_CODE,
  a.PROC_DATE,
  a.PAT_ENC_CSN_ID,
  a.PAT_ID,
  a.PAT_MRN_ID

FROM (
  SELECT
  e.PAT_ENC_CSN_ID,
  e.PAT_ID,
  d.PAT_MRN_ID,
  cpt.CPT_CODE,
  CAST(cpt.ORIG_SERVICE_DATE AS DATE)	'PROC_DATE'
FROM #PATBASE d
  INNER JOIN Clarity.dbo.PAT_ENC e ON e.PAT_ID = d.PAT_ID
  INNER JOIN Clarity.dbo.CLARITY_TDL_TRAN cpt ON cpt.PAT_ENC_CSN_ID = e.PAT_ENC_CSN_ID
WHERE 1=1

UNION ALL

SELECT
  e.PAT_ENC_CSN_ID,
  e.PAT_ID,
  d.PAT_MRN_ID,
  cpt.CPT_CODE,
  CAST(cpt.SERVICE_DATE AS DATE)	'PROC_DATE'
FROM #PATBASE d
  INNER JOIN Clarity.dbo.PAT_ENC e ON e.PAT_ID = d.PAT_ID
  INNER JOIN Clarity.dbo.ARPB_TRANSACTIONS cpt ON cpt.PAT_ENC_CSN_ID = e.PAT_ENC_CSN_ID
WHERE 1=1

UNION ALL

SELECT
  e.PAT_ENC_CSN_ID,
  e.PAT_ID,
  d.PAT_MRN_ID,
  cpt.CPT_CODE,
  CAST(cpt.SERVICE_DATE AS DATE)	'PROC_DATE'
FROM #PATBASE d
  INNER JOIN Clarity.dbo.PAT_ENC e ON e.PAT_ID = d.PAT_ID
  INNER JOIN Clarity.dbo.HSP_TRANSACTIONS cpt ON cpt.HSP_ACCOUNT_ID = e.HSP_ACCOUNT_ID
WHERE 1=1

UNION ALL

SELECT
  e.PAT_ENC_CSN_ID,
  e.PAT_ID,
  d.PAT_MRN_ID,
  cpt.CPT_CODE,
  CAST(cpt.CPT_CODE_DATE AS DATE)	'PROC_DATE'
FROM #PATBASE d
  INNER JOIN Clarity.dbo.PAT_ENC e ON e.PAT_ID = d.PAT_ID
  INNER JOIN Clarity.dbo.HSP_ACCT_CPT_CODES cpt ON cpt.HSP_ACCOUNT_ID = e.HSP_ACCOUNT_ID
WHERE 1=1

	) a
WHERE a.PAT_ID IN (SELECT PAT_ID FROM #PATBASE)
AND a.CPT_CODE IN  ('67028',		-- intravitreal injection
					'67036',		-- Pars plana vitrectomy
					'67101',
					'67105',
					'67107',
					'67108',
					'67110',
					'67113',		-- retinal detachment repair
					'66989',
					'66991', 		-- Minimally Invasive Glaucoma Surgery

				/* New additions from 1/4/23 */
					'65285',		-- Ruptured globe repair 
					'67005',
					'67010',		-- Anterior vitrectomy	
					'66999',		-- Femtosecond laser-assisted
					'65820' 		-- Goniotomy 
					)
)	-- End CTE

--select * from proc_check


, Agg_Dx_Proc AS (
SELECT DISTINCT cc.PAT_ID, cc.CODE 'DX_CODES', cc.DX_DATE 'DX_DATES', pc.CPT_CODE 'PROC_CODES', pc.PROC_DATE 'PROC_DATES' 
FROM comorb_check cc
INNER JOIN proc_check pc ON cc.PAT_ID = pc.PAT_ID
)


SELECT * INTO #Agg_Dx_Proc FROM Agg_Dx_Proc;


/*(268,643 rows affected)*/
--SELECT * FROM #Agg_Dx_Proc




--------------------------------------------------------------------
-----------------------INTRAOCULAR PRESSURE-------------------------
--------------------------------------------------------------------



-- From req. 221321



-- get grade of cataract, visual acuities, Hemoglobin A1c as well





---------------------------------------------------
--------------------VISUAL ACUITY------------------
---------------------------------------------------

---------------------------------------------------------------------------------
/*checking surgery dates*/
--SELECT distinct t.PAT_ID, t.PAT_ENC_CSN_ID, t.PROC_DATE
--FROM
--(
--  SELECT t.*, RN = ROW_NUMBER() OVER (PARTITION BY t.PAT_ID ORDER BY t.PROC_DATE ASC) --> earliest, desc = latest
--  FROM #PROC_LIST AS t
--) AS t
--WHERE t.RN = 1;

--select distinct * from #proc_list where pat_id = 'Z100015' order by proc_date;
---------------------------------------------------------------------------------


/*best uncorrected visual acuities*/

DROP TABLE IF EXISTS #BUVA_List

select distinct pl.PAT_MRN_ID, oed.PAT_ENC_CSN_ID 'Encounter_ID', proc_date 'Surgery_Date', cast(contact_date as date) 'BUVA_Date',
(case when oed.contact_date < pl.PROC_DATE then OPHTH_BUVA_OD ELSE NULL END) AS 'BUVA_OD_PreOp',
(case when oed.contact_date < pl.PROC_DATE then OPHTH_BUVA_OS ELSE NULL END) AS 'BUVA_OS_PreOp',
(case when (DATEDIFF(dd, pl.PROC_DATE, oed.contact_date)) <= 30 then OPHTH_BUVA_OD ELSE NULL END) AS 'BUVA_OD_PostOp <=1 month',
(case when (DATEDIFF(dd, pl.PROC_DATE, oed.contact_date)) <= 30 then OPHTH_BUVA_OS ELSE NULL END) AS 'BUVA_OS_PostOp <=1 month',
(case when (DATEDIFF(dd, pl.PROC_DATE, oed.contact_date)) > 30 then OPHTH_BUVA_OD ELSE NULL END) AS 'BUVA_OD_PostOp >1 month',
(case when (DATEDIFF(dd, pl.PROC_DATE, oed.contact_date)) > 30 then OPHTH_BUVA_OS ELSE NULL END) AS 'BUVA_OS_PostOp >1 month'
into #BUVA_list
from OPH_EXAM_DATA oed
inner join #H20_DX hd on hd.PAT_ID = oed.PAT_ID
left join #Cataract_Surg_POP pl on pl.PAT_ID = hd.PAT_ID
and (oed.OPHTH_BUVA_OD is not null or oed.OPHTH_BUVA_OS is not null); --> rerun and add to sheet 2
--and pl.pat_id = 'Z100015'
--order by surgery_date, buva_date;

/*(440127 rows affected)*/
--select distinct * from #buva_list where pat_mrn_id is not null order by pat_mrn_id, surgery_date, buva_date;	--> Use for Visual acuity sheet, ignore #BUVA stuff below
--select count(distinct pat_mrn_id) from #buva_list;		--> 246 patients


--------------------------------------------------------------------
-----------Concatenating #BUVA_List into #BUVA----------------------
--------------------------------------------------------------------
--DROP TABLE IF EXISTS #BUVA

--SELECT DISTINCT
--bl.PAT_ID, bl.Surgery_Date, bl.BUVA_Date,
--case when BUVA_date < Surgery_Date then(
--STUFF((    SELECT DISTINCT '; ' + CAST(A.BUVA_OD_PreOp as varchar) AS [text()]--, '|' + CAST(A.BUVA_OS_PreOp as varchar) AS [text()]
--                        FROM  #BUVA_List AS A
--						WHERE A.PAT_ID = bl.PAT_ID                
--                        FOR XML PATH('')
--                        ), 1, 1, '' )) ELSE NULL END
--            AS PREOP,
--case when BUVA_date > Surgery_Date then(
--STUFF((    SELECT DISTINCT '; ' + CAST(A.BUVA_OD_PostOp as varchar) AS [text()]--, '|' + CAST(A.BUVA_OS_PostOp as varchar) AS [text()]
--                        FROM  #BUVA_List AS A
--						WHERE A.PAT_ID = bl.PAT_ID                
--                        FOR XML PATH('')
--                        ), 1, 1, '' )) ELSE NULL END
--            AS POSTOP
----INTO #BUVA
--FROM #BUVA_list AS bl
--where bl.pat_id = 'Z100015';


/*(3,506 rows affected)*/

--SELECT * FROM #BUVA








---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------Bringing it all together------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

-- visual acuities (#BUVA_List) in seperate sheet, not part of output. did not use row number partitioning to avoid excluding relevant results.
-- Y/N for associated comorbidities and procedures


DROP TABLE IF EXISTS #Output

SELECT DISTINCT 
P.PAT_MRN_ID,
PB.GENDER,
PB.ETHNICITY,
PB.RACE,
CAST(PB.BIRTH_DATE as date) 'DOB',
--(CASE 	WHEN (CE.Probable_left_laterality = 'Y' AND CE.Probable_right_laterality <> 'Y') THEN 'Left' 
--		WHEN (CE.Probable_right_laterality = 'Y' AND CE.Probable_left_laterality <> 'Y') THEN 'Right'
--		WHEN (CE.Probable_right_laterality = 'Y' AND CE.Probable_left_laterality = 'Y') THEN 'Both'
--		ELSE NULL
--END) AS 'Operated_eye',
FLOOR(DATEDIFF(dd,PB.BIRTH_DATE,CP.PROC_DATE)/365.25) 'PROCEDURE_AGE',
CE.Probable_left_laterality 'Left eye',
CE.Probable_right_laterality 'Right eye',
CP.PROC_DATE 'Surgery_Date',
CP.CPT_CODES,
CP.CATARACT_DX_DATES,
HD.H20_DX_DATE,
PB.CLINIC_VISIT_DATES,
(CASE WHEN ADP.DX_CODES LIKE 'E08.%'		
		OR ADP.DX_CODES LIKE 'E09.%'	
		OR ADP.DX_CODES LIKE 'E10.%'	
		OR ADP.DX_CODES LIKE 'E11.%'	
		OR ADP.DX_CODES LIKE 'E13.%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Diabetes',
(CASE WHEN ADP.DX_CODES LIKE 'I10.%'	
		OR ADP.DX_CODES LIKE 'I11.%'
		OR ADP.DX_CODES LIKE 'I12.%'
		OR ADP.DX_CODES LIKE 'I13.%'
		OR ADP.DX_CODES LIKE 'I15.%'
		OR ADP.DX_CODES LIKE 'I16.%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Hypertension',
(CASE WHEN ADP.DX_CODES LIKE 'I50.%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Congestive Heart Failure',
(CASE WHEN ADP.DX_CODES LIKE 'N18.%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Chronic Kidney Disease',
(CASE WHEN ADP.DX_CODES LIKE 'H35.31%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Dry Macular Degeneration',
(CASE WHEN ADP.DX_CODES LIKE 'H35.32%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Wet Macular Degeneration',
(CASE WHEN ADP.DX_CODES LIKE 'H21.81%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Floppy Iris',
	/* New additions from 1/4/23 */
(CASE WHEN ADP.DX_CODES LIKE 'H20.0%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Traumatic iritis diagnosis',
(CASE WHEN ADP.DX_CODES LIKE 'H44.0%'
		OR ADP.DX_CODES LIKE 'H44.1%'	
	THEN ADP.DX_DATES ELSE NULL END) AS 'Endophthalmitis',
(CASE WHEN ADP.DX_CODES LIKE 'H59.0%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Disorders of the eye following cataract surgery',
(CASE WHEN ADP.DX_CODES LIKE 'H59.01%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Keratopathy',
(CASE WHEN ADP.DX_CODES LIKE 'H59.02%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Lens fragment in eye',
(CASE WHEN ADP.DX_CODES LIKE 'H59.03%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Cystoid macular edema',
(CASE WHEN ADP.DX_CODES LIKE 'H59.09%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Other disorders of the eye following cataract surgery',
(CASE WHEN ADP.DX_CODES LIKE 'E10.3%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Type 1 diabetes mellitus with ophthalmic complications',
(CASE WHEN ADP.DX_CODES LIKE 'E11.3%'
	THEN ADP.DX_DATES ELSE NULL END) AS 'Type 2 diabetes mellitus with ophthalmic complications',
(CASE WHEN ADP.DX_CODES LIKE 'E10.3%'
		OR ADP.DX_CODES LIKE 'E11.3%'
	THEN ADP.DX_CODES ELSE NULL END) AS 'DM_ICD_10_CODE',
(CASE WHEN ADP.PROC_CODES LIKE '67028'
	THEN ADP.PROC_DATES ELSE NULL END) AS 'Intravitreal Injection',
(CASE WHEN ADP.PROC_CODES LIKE '67036'
	THEN ADP.PROC_DATES ELSE NULL END) AS 'Pars Plana Vitrectomy (PPV)',
(CASE WHEN ADP.PROC_CODES LIKE '67101'	
		OR ADP.PROC_CODES LIKE '67105'
		OR ADP.PROC_CODES LIKE '67107'
		OR ADP.PROC_CODES LIKE '67108'
		OR ADP.PROC_CODES LIKE '67110'
		OR ADP.PROC_CODES LIKE '67113'
	THEN ADP.PROC_DATES ELSE NULL END) AS 'Retinal Detachment Repair',
(CASE WHEN ADP.PROC_CODES LIKE '66989'	
		OR ADP.PROC_CODES LIKE '66991'
	THEN ADP.PROC_DATES ELSE NULL END) AS 'Minimally Invasive Glaucoma Surgery (MIGS)',
	/* New additions from 1/4/23 */
(CASE WHEN ADP.PROC_CODES LIKE '65285'
	THEN ADP.PROC_DATES ELSE NULL END) AS 'Ruptured globe repair',
(CASE WHEN ADP.PROC_CODES LIKE '67005'	
		OR ADP.PROC_CODES LIKE '67010'
	THEN ADP.PROC_DATES ELSE NULL END) AS 'Anterior vitrectomy',
(CASE WHEN ADP.PROC_CODES LIKE '66999'
	THEN ADP.PROC_DATES ELSE NULL END) AS 'Femtosecond laser-assisted',
(CASE WHEN ADP.PROC_CODES LIKE '65820'
	THEN ADP.PROC_DATES ELSE NULL END) AS 'Goniotomy',
CAST(HA.A1C_Date as date) 'A1C_Date',
HA.A1C_PreOp

INTO #Output
FROM PATIENT AS P
INNER JOIN	#Cataract_Surg_POP		AS CP ON P.PAT_MRN_ID = CP.PAT_MRN_ID
LEFT JOIN	#PATBASE				AS PB ON P.PAT_MRN_ID = PB.PAT_MRN_ID
LEFT JOIN	#cataract_eye			AS CE ON P.PAT_ID = CE.PAT_ID
LEFT JOIN	#H20_DX					AS HD ON P.PAT_ID = HD.PAT_ID
LEFT JOIN	#Agg_Dx_Proc			AS ADP ON P.PAT_ID = ADP.PAT_ID
LEFT JOIN	#Hb_A1C					AS HA ON P.PAT_ID = HA.PAT_ID
LEFT JOIN	ZC_PATIENT_STATUS		AS ZPS ON ZPS.PATIENT_STATUS_C = P.PAT_STATUS_C
LEFT JOIN	PATIENT_TYPE			AS PT  ON PT.PAT_ID = P.PAT_ID
LEFT JOIN	ZC_PATIENT_TYPE			AS ZPT ON ZPT.PATIENT_TYPE_C = PT.PATIENT_TYPE_C
WHERE
(ZPT.NAME <> 'Opt Out Research'  
OR
ZPT.NAME is NULL
)
AND
(
P.PAT_STATUS_C = '1'		--alive
OR
P.PAT_STATUS_C  IS NULL
)
AND
P.PAT_NAME NOT LIKE 'zz%'
--AND HD.H20_DX_DATE > CP.PROC_DATE			--> request only needs pts diagnosed with Ant Ch. Inflammation after cataract surgery
ORDER BY P.PAT_MRN_ID

/*(21,773 rows affected)*/


--SELECT count(distinct pat_mrn_id) FROM #Output where h20_dx_date is not null	--4,113 patients, 251 with H20 DX
--SELECT distinct * FROM #Output where DM_ICD_10_CODE is not null
--select * from #output where PAT_MRN_ID NOT IN (select PAT_MRN_ID from #table)
