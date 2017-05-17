## mha_data_foundation
Standard definition of mental health and addictions (MHA) service access based on available data in the IDI

## Overview
This folder contains all the code necessary to build the MHA data foundation definition. The detailed data definition documentation is being finalised and will be uploaded before the end of May.

The code for the MHA phase 1 analysis will be made available when the results are published.

## Dependencies
* Since we are looking at the MHA population in the IDI it is necessary to have an IDI project if you wish to run the code. Visit the Stats NZ website for more information about this.
* The MHA code requires access to the following schemas in IDI_Clean
	* data
	* moh_clean
	* msd_clean
	* security

and also IDI_Metadata.clean_read_CLASSIFICATIONS.


## Folder descriptions
**include:** This folder contains scripts necessary for the SIU themes and pieces of code that are generic i.e. can be used outside of MHA.
**logs:** This folder is used to store the output logs that SAS generates. This is used for the cross agency outcomes that have a lot of code to run.
**output:** This folder is used to store graphical and tabular output.
**rprogs:** This folder contains r scripts for carrying out plots and R based analysis.
**sasautos:** This folder contains SAS macros. All scripts in here will be loaded into the SAS environment during the running of setup in the main script.
**sasprogs:** This folder contains SAS programs. The main script that builds the dataset is located in here.
**sql:** This folder contains the sql scripts. These are often used by the R scripts to query the database.

## Installation
1. Ensure you have an IDI project so you can run the code.
2. Download the zipped file for the MHA phase 1 from Github.
3. Email the zipped file(s) to access2microdata@stats.govt.nz and ask them to move it into your project folder.
4. Unzip the files into your project. You can rename the project if you wish.


## Instructions to build the MHA data foundation
1. Open sasprogs/main.sas
2. In the set up variable and macros section you will find two variables that you need to specify called `use_case_path` and `schemaname`
3. Change `use_case_path` to the full path location of the project e.g. \\..\MAA2016-15 Supporting the Social Investment Unit\github_mental_health
4. Change `schemaname` to the name of your schema  e.g. the SIU project schema is DL-MAA2016-15
5. Once you have changed the variables you can run main.sas (this should build the data foundation in under 30 minutes)

The hierarchy is shown below for anyone who wishes to make particular modifications to the data foundation

Setup Libnames ---> setup formats for access   ---> build MHA events

Since the database does not allow the option of tables being replaced, the script always drops database tables before writing to the database. Expect warnings if these tables do not exist. They will not affect the build of the final table.


## Getting Help
More information to come. For now email info@siu.govt.nz

Tracking number: SIU-2017-0138


