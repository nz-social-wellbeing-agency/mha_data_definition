/*********************************************************************************************************
TITLE: main.sas

DESCRIPTION: Build the MHA data foundation for all subsequent analysis.

INPUT:
NA

OUTPUT:
sand.moh_diagnosis

AUTHOR: E Walsh

DATE: 19 Jan 2017

DEPENDENCIES: 
SIAL tables must exist

NOTES: Runtime ~ 30 minutes

HISTORY:
02 Aug 2019 AK Updated to meet new SAS Grid Standards
07 Apr 2017 VB Added the workflow sequence to main script
06 Apr 2017 EW reordered to separate the data part from the analysis part 
26 Feb 2017 EW moved everything out of the dev area
19 Jan 2017 EW v1
*********************************************************************************************************/





/******************************* SET UP VARIABLES AND MACROS ********************************************/
/* Define any macro variables */
%let use_case_path = /nas/DataLab/MAA/MAA2016-15 Supporting the Social Investment Unit/mha_data_definition;

/* Define the schema into which the output tables need to be written into*/
%let schemaname = DL-MAA2016-15;

/* Load all the sofie macros */
options obs=MAX mvarsize=max pagesize=132
        append=(sasautos=("&use_case_path/sasautos"));

/* Set any other options */
ods graphics on;

/* Set up the libraries */
%include "&use_case_path./include/libnames.sas";
libname sand ODBC dsn= idi_sandpit_srvprd schema="&schemaname.";

/*Include the macros to create the cpi adjustment*/
%include "&use_case_path./include/cpi_macros.sas";

/***********************************************************************************************************/




/******************************* SET UP MHA ACCESS DATA ****************************************************/
/*Estimated completion : 30 minutes*/

/* Retrieve the formats needed for the scripts */
%include "&use_case_path./sasprogs/get_formats_mha_events.sas";

/* Build the table with all MHA events */
%include "&use_case_path./sasprogs/create_mha_events.sas";
/***********************************************************************************************************/


/* Now that the MHA data foundation is complete you can refer to the readme to do a particular analysis outlined
in the technical report or you can do your own analysis */

