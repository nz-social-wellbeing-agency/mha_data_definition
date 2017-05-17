/****************************************************
TITLE: get_cpi_values.sas

DESCRIPTION: Macro to apply inflation adjustment to dollar values

INPUT: 
ss =    full path to comma separated csv from Stats NZ containing 
        the CPI  quarters in the first column and then 
        the CPI adjustment in the second column
itype = index type e.g. cpi, ppi and so on. This is used to
        name columns and tables appropriately to avoid confusion

OUTPUT:
work.temp_cpi_values = SAS table of CPI values

DEPENDENCIES: 
sand.inflation_index (part of SIAL)

NOTES: 
Inflation index data comes from Stats Infoshare > Economic indicators
> CPI > CPI all groups for NZ (Qtrly-Mar/Jun/Sep/Dec). This needs to be added to 
a table in the user schema as part of SIAL.

This script can be used only for dates between 1925Q3 & 2016Q4 for CPI, 
between 1989 & 2016 for QEX and 1977 & 2016 for PPI.


AUTHOR: 
C Wright

DATE: 01 Aug 2016

HISTORY: 
20 Feb 2017		VB	Changed the source of data into a SQL table
					Added CPI, PPI and QEX as dynamic inputs.
24 Oct 2016 	EW 	added health PPI inputs spreadsheet
02 Aug 2016 	EW 	repurposed to be more generic and meet
               		coding conventions
01 Aug 2016 	CW 	v1
****************************************************/


/* Gets the appropriate price index table that the amounts need to be adjusted to*/
%macro get_pi_values(itype=);

	proc sql;
		create table work.temp_&itype._values(where=(yq ne '')) as 
			select quarter as yq, value as &itype. from sand.inflation_index
				where inflation_type= "&itype.";
	quit;

%mend;


/****************************************************
TITLE: get_pi_adjustment

DESCRIPTION: perform the pi adjustment on the 
appropriate column

INPUT: 
inds = input event table containing a dollar column
cost = name of the cost variable (or revenue variable)
itype = type of price index used for column and table names
ref_yyq = the pi baseline year
ctype_in = cost type in input dataset D(aily) or L(umpsum)
ctype_out = cost type on output table D(aily) or L(umpsum)

OUTPUT:
inds = input dataset with CPI adjusted column appended

DEPENDENCIES: 
requires get_pi_values to be run first to build the
pi table

NOTES: 


AUTHOR: 
C Wright

DATE: 01 Aug 2016

HISTORY: 
20 Feb 2017	VB	Changed the source of data into a SQL table
				Added CPI, PPI and QEX as dynamic inputs.
24 Oct 2016 EW made more generic for any price index
02 Aug 2016 EW repurposed to be more generic and meet
               coding conventions
01 Aug 2016 CW v1
****************************************************/

%macro get_pi_adjustment(inds,cost,itype,ref_yyq,ctype_in,ctype_out);

%get_pi_values(itype=&itype.);

/* Remove earlier records of cpi and readjust cpi based on the reference year quarter */
proc sql;
	create table work.temp_&itype._values_trunc as 
		select a.*,
			(a.&itype./b.&itype.) as adj_&itype.
		from work.temp_&itype._values(where=(yq >= '1925Q3')) as a,
			work.temp_&itype._values(where=(yq="&ref_yyq")) as b;
quit;

/* Quarter-ise  the events table */
data work.temp_quarterise (keep= snz_uid _id_ temp_amount yyq);
	length sdate edate 4;
/*	format start_date end_date ddmmyy10.;*/
	set &inds.;

	/* note events tables store their start and end dates in
	date time format */
	sdate=datepart(start_date);
	edate=datepart(end_date);
	start_date=.;
	end_date=.;

	/*row id for aggregating back up costs*/
	_id_=_n_;

	/* work out how many quarters an event spans */

	diff=(intck('quarter',sdate,edate));

	do i=0 to diff;
		d_begin = intnx('quarter',sdate,i,'begin');
		d_end = intnx('quarter',sdate,i,'end');

		/* if an event spans multiple quarters create a new record for each quarter */
		if i=0 then
			start_date=sdate;

		if i=diff then
			end_date=edate;

		if i ne 0 then
			start_date=d_begin;

		if i ne diff then
			end_date=d_end;
		yyq=put(start_date,yyq6.);
		d1=1+(end_date-start_date);
		d2=1+(edate-sdate);

		/* the rollup can calculate either a daily cost or a lump sum cost for an event */
		/* note event though we refer to cost this can still be applied to a revenue column */
		if "&ctype_in"='D' then
			temp_amount=d1*&cost.;
		else if "&ctype_in"='L' then
			temp_amount=(d1/d2)*&cost.;
		output;
	end;


run;


/* Inflation adjust the cost variable */
proc sql;
	create table work.temp_events_&itype._adj as
		select a._id_,
			sum(a.temp_amount/b.adj_&itype.) as &cost._&itype._&ref_yyq
		from  work.temp_quarterise as a 
			left join work.temp_&itype._values_trunc as b
				on a.yyq=b.yq
			group by a._id_	;
quit;

/* Double-check that the output column doesnt already exist in the input dataset */
%macro var_exist (ds,var);
	%local rc dsid result;
	%let dsid=%sysfunc(open(&ds.));
	%put dsid macro variable = &dsid;
	%put ds macro variable = &ds.;

	%if %sysfunc(varnum(&dsid.,&var.)) %then
		%do;
			%let result=1;
			%put ERROR: variable &var already exists in dataset;
		%end;
	%else
		%do;
			%let result=0;
			%put NOTE: writing cpi adjusted cost to file;
		%end;

	%let rc=%sysfunc(close(&dsid.));
%mend var_exist;

/* test */
/*%var_exist(ds=&inds.,var=cost_cpi_2014Q4);*/
/* actual one wil call the explicit macro variable */
%var_exist(ds=&inds.,var=&cost._&itype._&ref_yyq);

/* add the cpi adjusted column to the input table */
data &inds.;
	merge &inds. work.temp_events_&itype._adj (drop=_id_);

	/* by default the cpi adjusted costs are lump sum */
	/* if you require a daily rate then use ctype_out */
	if "&ctype_out"='D' then
		&cost._&itype._&ref_yyq=&cost._&itype._&ref_yyq/(1+end_date-start_date);
run;



/* clean up delete the temp datasets */
proc datasets lib=work;
	delete temp_events_&itype._adj;
	delete temp_quarterise;
run;

%mend;
