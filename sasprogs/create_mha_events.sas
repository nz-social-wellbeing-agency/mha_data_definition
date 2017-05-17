/******************************************************************************
TITLE:	create_mha_events.sas

DESCRIPTION: This script extracts mental health (MH) and Alcohol and Other Drugs 
(AOD) abuse from various MoH datasets and one MSD dataset:

	(1) Programme for the Integration of Mental Health Data (PRIMHD) 
	(2) National Minimum Dataset (NMDS) national collection of publicly 
	  funded hospital discharge information, including clinical information, 
	  for inpatients and day patients. **Privately funded hospital** events have 
	  been **excluded** from this dataset due to lack of completeness. 
	(3) The Pharmaceutical Collection (PHARMAC) is a data mart that supports 
	  the management of pharmaceutical subsidies
	(4) The Laboratory Claims (LAB) collection contains claim and payment 
	  information for laboratory tests
	(5) MSD incapacity events (from medical certificates related to 
		incapacity-related benefit receipt).

INPUT:

OUTPUT: sand.moh_diagnosis

AUTHOR: V Benny and C MacCormick. Adapted from MoH_mh_aod_events.sas created by 
S Johnston and M Cronin (MOH) and adapted by Rissa Ota (MSD).

DATE: October 2016

DEPENDENCIES:

NOTES:

HISTORY:
29 Aug 2016 Rissa Ota - initial code
5 Oct 2016 CM - Removed 'Pregnancy and complications of puerperum' and
	'Congenital abnormalities' as categories from incapacity code	
10 Oct 2016 CM - minor updates
13 Oct 2016 VB - changed the code into a pass-through SQL version, and removed the 
	filters on specific team types. As a result, all records that do not have a
	diagnosis on the basis of the business rules are listed as 'Other MH'
26 Jan 2017 VB - moved Chemical ID s 2636 and 6009 into Mood Disorders from Other MH
	on the advice of Anthony Duncan and Tom Love.
28 Feb 2017	CM - added disability format to this program so no longer dependent on 
	other script. Also commented out incapacity code that doesn't actually 
	get used in final events table
10 May 2017	VB - Added Methadone (Chemical ID 1795) into the list of potential MH		
	drugs, based on feedback from MoH.
15 May 2017    EW - Added three more chemicals lamotrigine, carbamazepine and sodium 
                    valproate (chem id 1002, 1217, 2166) based on feedback from SJ, MOH
*/

/********************************************************************************
(1) Programme for the Integration of Mental Health Data (PRIMHD) 
********************************************************************************/

proc sql;
	connect to odbc(dsn=idi_clean_archive_srvprd);

	create table primhd_team as
		select 
		   snz_uid
		   ,'MOH' as department
		   ,'PRIMHD' as datamart
		   ,'MH' as subject_area
		   ,input(start_date, yymmdd10.) as start_date format = ddmmyy10.
		   ,input(end_date, yymmdd10.) as end_date format = ddmmyy10. 
		   ,event_type
		   ,moh_mhd_activity_type_code as event_type_2
		   ,team_type as event_type_3
	from connection to odbc(
		select 
			primhd.snz_uid
			,cast(primhd.moh_mhd_activity_start_date as date) as start_date
			,cast(primhd.moh_mhd_activity_end_date as date) as end_date
			,team.team_type
			,primhd.moh_mhd_activity_type_code
			,case 
				when primhd.moh_mhd_activity_type_code = 'T09' then 'Psychotic'
				when team.team_type = '16' then 'Eating'
				when team.team_type = '12' then 'Intellectual'
				when team.team_type in ('03','10','11','21','23') or 
					primhd.moh_mhd_activity_type_code in ('T16','T17','T18','T19','T20') 
					then 'Substance use'
				when primhd.moh_mhd_activity_type_code <> '' then 'Other MH'
			end as event_type
		from IDI_Clean.moh_clean.primhd primhd	
		left join IDI_Sandpit.clean_read_MOH_PRIMHD.moh_PRIMHD_TEAM_LOOKUP as team
			on primhd.moh_mhd_team_code = team.team_code
	);

	
	disconnect from odbc;

quit;

/**************************************************************************************************
(2) National Minimum Dataset (NMDS) - Public Hospital Discharges
**************************************************************************************************/

proc sql;
   create table hospEvents
   as select
		 snz_uid
	   ,snz_moh_uid as moh_uid
      ,moh_evt_event_id_nbr as event_id
      ,input(compress(moh_evt_evst_date,"-"),yymmdd8.) format yymmdd10. as start_date
      ,input(compress(moh_evt_even_date,"-"),yymmdd8.) format yymmdd10. as end_date

   from moh.pub_fund_hosp_discharges_event;

quit;


/* Extract diagnosis information*/
data diag;
   format event_type $50.;
   set moh.pub_fund_hosp_discharges_diag
			(keep=moh_dia_event_id_nbr moh_dia_clinical_code moh_dia_clinical_sys_code 
				  moh_dia_submitted_system_code
	         rename=(moh_dia_event_id_nbr=event_id moh_dia_clinical_code=code)
	   		 where=(moh_dia_submitted_system_code = moh_dia_clinical_sys_code));

   /* Hospitalisations 1999 to 2014 */

   /* ADHD */
   if substr(code,1,4) = 'F900' then do event_type = 'ADHD'; output; end;

   /* Anxiety disorders */
   if 'F40' <= substr(code,1,3) <= 'F48' then do event_type = 'Anxiety'; output; end;

   /* Autism spectrum */
   if substr(code,1,3) = 'F84' then do event_type = 'Autism'; output; end;

   /* Dementia */
   if 'F00' <= substr(code,1,3) <= 'F03' then do event_type = 'Dementia'; output; end;

   /* Eating disorders */
   if substr(code,1,3) = 'F50' then do event_type = 'Eating'; output;end;

   /* Gender Identity */
   if substr(code,1,4) in ('F640','F642','F648','F649') 
		then do event_type = 'Gender identity'; output; end;

   /* Mood disorders */
   if 'F30' <= substr(code,1,3) <= 'F39' then do event_type = 'Mood'; output; end;

   /* Intellectual diabilility (Mental retardation) */
   if 'F70' <= substr(code,1,3) <= 'F79' then do event_type = 'Intellectual'; output; end;

   /* Other MH disorders */
   if 'F04' <= substr(code,1,3) <= 'F09' then do event_type = 'Other MH'; output; end;
   if 'F51' <= substr(code,1,3) <= 'F53' then do event_type = 'Other MH'; output; end;
   if substr(code,1,3) in ('F59', 'F63','F68','F69','F99') 
		then do event_type = 'Other MH'; output; end;
   if substr(code,1,4) in ('F930','F931','F932') then do event_type = 'Other MH'; output; end;

   /* Personality disorders */
   if 'F60' <= substr(code,1,3) <= 'F62' then do event_type = 'Personality'; output; end;

   /* Psychotic disorders */
   if 'F20' <= substr(code,1,3) <= 'F29' then do event_type = 'Psychotic'; output; end;

   /* Substance use */
   if 'F10' <= substr(code,1,3) <= 'F16' then do event_type = 'Substance use'; output; end;
   if 'F18' <= substr(code,1,3) <= 'F19' then do event_type = 'Substance use'; output; end;
   if substr(code,1,3) in ('F55') then do event_type = 'Substance use'; output; end;


   /* Hospitalisations 1988 to 1999 */

   /* ADHD */
   if substr(code,1,5) in ('31400','31401') then do event_type = 'ADHD';  output; end; 

   /* Anxiety disorders */
   if '30000' <= substr(code,1,5) <= '30015' then do event_type = 'Anxiety'; output; end; 
   if substr(code,1,4) in ('3002','3003'/*,'3099' captured below*/) 
		then do event_type = 'Anxiety'; output; end;
   if '3005' <= substr(code,1,4) <= '3009' then do event_type = 'Anxiety'; output; end;
   if '3060' <= substr(code,1,4) <= '3064' then do event_type = 'Anxiety'; output; end;
   if substr(code,1,5) in ('30650','30652','30653','30659','30780','30789','30989') 
		then do event_type = 'Anxiety'; output; end;
   if '3066' <= substr(code,1,4) <= '3069' then do event_type = 'Anxiety'; output; end;
   if '3080' <= substr(code,1,4) <= '3091' then do event_type = 'Anxiety'; output; end;
   if '30922' <= substr(code,1,4) <= '30982' then do event_type = 'Anxiety'; output; end;

   /* Autism spectrum */
   if substr(code,1,5) in ('29900','29901','29910') then do event_type = 'Autism'; output; end;

   /* Dementia */
   if substr(code,1,3) = '290' then do event_type = 'Dementia'; output; end;
   if substr(code,1,4) = '2941' then do event_type = 'Dementia'; output; end;

   /* Eating disorders */
   if substr(code,1,4) = '3071' then do event_type = 'Eating'; output; end;
   if substr(code,1,5) in ('30750','30751','30754','30759') 
		then do event_type = 'Eating'; output; end;

   /* Gender Identity */
   if substr(code,1,4) = '3026' then do event_type = 'Gender identity'; output; end;
   if substr(code,1,5) in ('30250','30251','30252','30253','30285') 
		then do event_type = 'Gender identity'; output; end;

   /* Mood disorders */
   if substr(code,1,3) in ('296','311') then do event_type = 'Mood'; output; end;
   if substr(code,1,4) = '3004' then do event_type = 'Mood'; output; end;
   if substr(code,1,5) = '30113' then do event_type = 'Mood'; output; end;

   /* Intellectual diabilility (Mental retardation) */
   if '317' <= substr(code,1,3) <= '319' then do event_type = 'Intellectual'; output; end;

   /* Other MH disorders */
   if '2930' <= substr(code,1,4) <= '2940' then do event_type = 'Other MH'; output; end;
   if substr(code,1,4) in ('2948','2949','3027','3074','3123','3130','3131') 
		then do event_type = 'Other MH'; output; end;
   if '29911' <= substr(code,1,5) <= '29991' then do event_type = 'Other MH'; output; end;
   if substr(code,1,5) in ('30016','30019','30151','30651','30921') 
		then do event_type = 'Other MH'; output; end;
   if substr(code,1,3) in ('310') then do event_type = 'Other MH'; output; end;

   /* Personality disorders */
   if substr(code,1,4) = '3010' then do event_type = 'Personality'; output; end;
   if substr(code,1,5) in ('30110','30111','30112','30159') 
		then do event_type = 'Personality'; output; end;
   if '30120' <= substr(code,1,5) <= '30150' then do event_type = 'Personality'; output; end;
   if '3016' <= substr(code,1,4) <= '3019' then do event_type = 'Personality'; output; end;

   /* Psychotic disorders */
   if '2950' <= substr(code,1,4) <= '2959' then do event_type = 'Psychotic'; output; end;
   if '2970' <= substr(code,1,4) <= '2989' then do event_type = 'Psychotic'; output; end;

   /* Substance use */
   if substr(code,1,3) in ('291','292') then do event_type = 'Substance use'; output; end;
   if '3030' <= substr(code,1,4) <= '3050' then do event_type = 'Substance use'; output; end;
   if '3052' <= substr(code,1,4) <= '3059' then do event_type = 'Substance use'; output; end;
   keep event_id event_type code moh_dia_clinical_sys_code;
run;

/* Remove obvious duplicates*/
proc sort data=diag 
		  out=diagnosis(keep=event_id event_type code)
		  nodupkey; 
	by event_id event_type code; 
run;

proc sql;
   create table NMDS_MentalHealth as
	select 'MOH' as department
		,'NMDS' as datamart
		,'MH' as subject_area
		,a.moh_uid
		,a.snz_uid
		,a.start_date
		,a.end_date
		,b.event_type 
		,b.code as event_type_2
		,"NA" as event_type_3
	from HospEvents as a join diagnosis as b on
         (a.event_id=b.event_id);
quit;

/**************************************************************************************************
(3) PHARMACEUTICALS
**************************************************************************************************/

/* Extract PHARMAC records for the drugs we are interested in */
proc sql;

	connect to odbc(dsn=idi_clean_archive_srvprd);

	create table pharmac1 as
	select
		snz_uid,
		input(moh_pha_dispensed_date,yymmdd10.) as start_date,
		input(moh_pha_dispensed_date,yymmdd10.) as end_date,
		chemical_id
	from connection to odbc(
	select 
			pharm.snz_uid as snz_uid, 
			pharm.moh_pha_dispensed_date as moh_pha_dispensed_date, 
			form.CHEMICAL_ID as chemical_id
			from IDI_Clean.moh_clean.pharmaceutical pharm
			inner join IDI_Metadata.clean_read_CLASSIFICATIONS.moh_dim_form_pack_subsidy_code form 
				on (pharm.moh_pha_dim_form_pack_code = form.DIM_FORM_PACK_SUBSIDY_KEY)
			where form.CHEMICAL_ID in 
				(
					3887,1809,3880,
					1166,6006,1780,
					3750,3923,
					1069,1193,1437,1438,1642,2466,3753,1824,1125,2285,1955,2301,3901,
					1080,1729,1731,2295,2484,
					3884,3878,1078,1532,2820,1732,1990,1994,2255,2260,
					2367,1432,3793,
					2632,1315,3926,2636,1533,1535,1760,2638,1140,1911,6009,1950,1183,1011,3927,
					1030,1180,3785,3873										
					/*potential inclusion*/
					,1007,1013,1059,1111,1190,1226,1252,1273,1283,1316,1379,1389,1397,1578,1583,
					1730,1799,1841,1865,1876,1956,2224,2298,2436,2530,2539,3248,3248,3722,3735,
					3803,3892,3898,3920,3935,3940,3950,4025,4037,6007,8792,1795
					/* additional potential inclusion post moh feedback */
					,1002,1217,2166
				)
);
	
	disconnect from odbc;
quit;

data pharmac2;
	informat code $4.;
	format code $4.;
	set pharmac1; 

	code = put(chemical_id,4.);
run;

/* Assigning event_types*/
data pharmac;
	format event_type $50. start_date end_date yymmdd10.;
	set pharmac2(keep=snz_uid start_date end_date chemical_id code);

	start_date = start_date;
	end_date = start_date;

	datamart = 'PHARM';

	/* ADHD */
	if code in ('3887','1809','3880') then event_type = 'ADHD';

	/* Anxiety disorders */
	if code in ('1166','6006','1780') then event_type = 'Anxiety';

	/* Dementia */
	if code in ('3750','3923') then event_type = 'Dementia';

	/* Mood disorders */
	/* We've added 2636 and 6009 to Mood Disorders on the advice of Anthony 
		Duncan and Tom Love*/
	if code in ('1069','1437','1438','2466','3753','1824','1125','2285','1955','2301',
		'3901', '2636','6009') then event_type = 'Mood';

	/* Citalopram */
	/* Citalopram is used to treat both Mood-Anxiety and Dementia. Hence we can 
		definitively determine the diagnosis to be Mood anxiety only if there are 
		no other recorded cases of dementia for the individual.*/
	/* So we flag this separately and then apply at end as Moodanx event_type 
		in case of no dementia event_type */
	if code in ('1193') then event_type = 'Citalopram';		

	/* Psychotic disorder */
	if code in ('3884','3878','1078','1532','2820','1732','1990','1994','2255','2260') 
		then event_type = 'Psychotic';

	/* Substance use */
	if code in ('2367','1432','3793') then event_type = 'Substance use';

	/* Combined Mood and Anxiety */
	if code in ('2632','3926','1760','2638','3927','1030','1180','3785')
		then event_type = 'Mood anxiety';

	/* Other MH disorders */
	if code in ('1080','1729','1731','2295','2484') then event_type = 'Other MH';

	if code in ('1315','1533','1535','1140','1911','1950','1183','1011','3873','1642')
		then event_type = 'Other MH';
	
	/* Added 1795 Methadone into the potentials list */
	/* Added 1002 lamotrigine, 1217 carbamazepine, 2166 sodium valporate based on MOH feedback */
	if code in ('1007','1013','1059','1111','1190','1226','1252','1273','1283','1316',
				'1379','1389','1397','1578','1583','1730','1799','1841','1865','1876',
				'1956','2224','2298','2436','2530','2539','3248','3248','3722','3735',
				'3803','3892','3898','3920','3935','3940','3950','4025','4037','6007','8792',
				'1795','1002','1217','2166')
		then event_type = 'Potential MH';

	event_type_3 = "NA";
	keep snz_uid datamart start_date end_date event_type code event_type_3;
	rename code=event_type_2;
run;


/**************************************************************************************************
(4) LAB Data 
**************************************************************************************************/

/* Extract labs claims data for the population cohort */
proc sql;
   create table lab_mast
   as select
		snz_uid
		,snz_moh_uid as mast_enc
		,moh_lab_test_code as test_code
		,input(compress(moh_lab_visit_date,"-"),yymmdd8.) format yymmdd10. as start_date
   from moh.lab_claims
   where test_code = 'BM2'
   order by mast_enc, start_date;
quit;

/* Assign an episode variable where an episode is made up of tests that occurred less than
four months apart between each */
data labs_episode(keep=snz_uid start_date mast_enc episode weight);
   format lagdate yymmdd10.;
   retain episode;
   set lab_mast(keep=snz_uid start_date mast_enc);
   by mast_enc;

   weight = 1;

   lagdate = lag(start_date);

   if first.mast_enc then episode = 1;
   else do;
      if start_date < (lagdate + 120) then episode = episode;
      else episode = episode + 1;
   end;

run;

proc sort data=labs_episode;
	by snz_uid mast_enc episode;
quit;

/* Summarise to find people with more than two tests in an episode */
proc summary data = labs_episode(keep=snz_uid mast_enc episode weight);
   by snz_uid mast_enc episode;
   var weight;
   output out = labs_episode_summary (drop = _freq_ _type_) 
   sum = tests;
run;

data labs_hcus(keep= mast_enc episode tests);
   set labs_episode_summary(keep=mast_enc episode tests);
   where tests > 2;
run;

/* Restrict the main labs dataset to just these people and their episodes 
	(where number of tests greater than two) */
proc sql;
   create table labs_list as
   select a.mast_enc as mast_1,
		  a.episode as episode_1,
		  b.*
   from labs_hcus as a left join labs_episode as b on
	      a.mast_enc = b.mast_enc and
	      a.episode = b.episode
	      where a.mast_enc is not null;
quit;

data Labs_MentalHealth;
   format start_date end_date yymmdd10.;
   set labs_list(keep=snz_uid mast_1 start_date);

   datamart = 'LAB'; 
   event_type = "Mood";
   event_type_2 = "BM2";
   event_type_3="NA";

   start_date = start_date;
   end_date = start_date;

   keep snz_uid start_date end_date datamart event_type event_type_2 event_type_3;
run;

/**************************************************************************************************
(5) MSD Incapacity
**************************************************************************************************/

/* Set up parameters and create format */

%let mh_categories = 'Mental retardation' 'Drug abuse'
'Other psychological/psychiatric conditions' 
'Affective psychoses';

/* Create events dataset and change names */

/* Renamed the following to align with the health tables' diagnoses:
Mental retardation = Intellectual
Affective psychoses = Psychotic
Other psychological/psychiatric conditions = Other
Drug abuse = Substance use */

proc sql noprint;
	create table msd_inc_mha_events as
		select snz_uid
			,'MSD' as department
			,'ICP' as datamart
			,'ICP' as subject_area
			,input(msd_incp_incp_from_date, yymmdd10.) as start_date format = yymmdd10.
			,input(msd_incp_incp_to_date, yymmdd10.) as end_date format = yymmdd10.
			,0.00 as cost
			,case
				when put(msd_incp_incapacity_code, $icd9sgl.) = 'Mental retardation' then 'Intellectual'
				when put(msd_incp_incapacity_code, $icd9sgl.) = 'Affective psychoses' then 'Psychotic'
				when put(msd_incp_incapacity_code, $icd9sgl.) = 'Other psychological/psychiatric conditions' 
					then 'Other MH'
				when put(msd_incp_incapacity_code, $icd9sgl.) = 'Drug abuse' then 'Substance use'
			end as event_type
			,msd_incp_incapacity_code as event_type_2
			,'NA' as event_type_3
		from  msd.msd_incapacity
		where
			put(msd_incp_incapacity_code, $icd9sgl.) in (&mh_categories.)
		order by 
			snz_uid, 		
			start_date, 
			end_date;
quit;

/**************************************************************************************************
(6) Combining data and creating final event_type datasets 
**************************************************************************************************/

/* Combine mental health event_types from all data sources */

options varlenchk=nowarn;

%let keep_vars = snz_uid start_date end_date event_type event_type_2 event_type_3
			     datamart;

data mh1;
   length event_type event_type_2 event_type_3 datamart $50. /*code*/ ;
   set Labs_MentalHealth (keep=&keep_vars.)
       NMDS_MentalHealth (keep=&keep_vars.)
       pharmac          (keep=&keep_vars.)
       primhd_team       (keep=&keep_vars.)
	   msd_inc_mha_events (keep=&keep_vars.)
;
	if datamart = 'ICP' then department = 'MSD';
	else department = 'MOH';
	subject_area = 'MHA';
run;

/* Reorder columns */

proc sql;
	create table 
		mh2
	as
	select
		snz_uid
		,department
		,datamart
		,subject_area
		,start_date
		,end_date
		,event_type
		,event_type_2
		,event_type_3
	from
		mh1
	order by
		snz_uid
	 	,start_date	;


	create index idx_a on mh2(snz_uid,department, datamart, subject_area, start_date, 
		end_date, event_type_2, event_type_3);
quit;


proc sql; 
	
	/*Drop the target table if it exists in sand */
	drop table sand.moh_diagnosis;

	create table sand.moh_diagnosis 
	as select * from mh2;
 
quit;

/***************************************************************************************************
The 'Citalopram conflict' is resolved in the following section. Alternatively we could use the
"citalopram_diagnosis_resolution.sql" code.
***************************************************************************************************/

proc sql;
connect to odbc(dsn=idi_clean_archive_srvprd);
execute(
	update [IDI_Sandpit].[&schemaname.].moh_diagnosis set event_type='Dementia'
	from
	[IDI_Sandpit].[&schemaname.].moh_diagnosis mhd 
	inner join 
	(select b.snz_uid, b.department, b.datamart, b.subject_area, b.start_date, b.end_date, 
			'Dementia' as event_type, b.event_type_2, b.event_type_3
		from (select *  from [IDI_Sandpit].[&schemaname.].moh_diagnosis where event_type='Citalopram') b 
		where exists 
			(select 1 from [IDI_Sandpit].[&schemaname.].moh_diagnosis a where a.event_type='Dementia' 
				and a.snz_uid=b.snz_uid and a.start_date <= b.start_date)
	) a on( mhd.snz_uid=a.snz_uid 
			and mhd.department=a.department
			and mhd.datamart=a.datamart
			and mhd.subject_area=a.subject_area
			and mhd.start_date=a.start_date 
			and mhd.end_date=a.end_date
			and mhd.event_type='Citalopram'
			and mhd.event_type_2 = a.event_type_2
			and mhd.event_type_3 = a.event_type_3 )
) by odbc;

execute(
	update [IDI_Sandpit].[&schemaname.].moh_diagnosis set event_type='Mood anxiety'
	where event_type='Citalopram'
)by odbc;

execute(
	create index idx1_moh_diag_uid_enddt on [IDI_Sandpit].[&schemaname.].moh_diagnosis(snz_uid, end_date)
) by odbc;

disconnect from odbc;
quit;

proc sql;
	drop table work.diag;
	drop table work.diagnosis;
	drop table work.hospevents;
	drop table work.lab_mast;
	drop table work.labs_episode;
	drop table work.labs_episode_summary;
	drop table work.labs_hcus;
	drop table work.labs_list;
	drop table work.labs_mentalhealth;
	drop table work.mh1;
	drop table work.mh2;
	drop table work.msd_inc_mha_events;
	drop table work.nmds_mentalhealth;
	drop table work.pharmac;
	drop table work.pharmac1;
	drop table work.pharmac2;
	drop table work.primhd_team;
quit;
