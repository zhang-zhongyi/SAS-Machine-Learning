/* OnDemand: Map library to NEISS folder under my_courses folder using shortcut */
libname neiss '/courses/dc41eb55ba27fe300/lib/neiss';

/* Local: Map library to NEISS folder under my_courses folder using shortcut */
/* Check your path may differ */
/* libname neiss 'C:/SAS/lib/neiss'; */

/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Formatting steps */
/* Applies formats to coded data for readability */
/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

/* Read in NEISS formats from neiss download file*/
proc format
 	cntlin=neiss.neiss_fmt;
run;

title 'Frequency of NEISS formats';
title2 'Note: PROD N=1,115';
proc freq data=neiss.neiss_fmt;
	tables fmtname;
run;

/* Example of creating a new format */
proc format;
 	value dowf
 		1 = 'Sunday'
 		2 = 'Monday'
 		3 = 'Tuesday'
 		4 = 'Wednesday'
 		5 = 'Thursday'
 		6 = 'Friday'
 		7 = 'Saturday';
	value myfmt
		1 = 'Case'
		0 = 'Non-Case';
run;

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Combine three years of NEISS data */
/* Drop variables not needed for analysis to save disk */
/* Apply formats */
/* Combine NARR1 and NARR2 fields into one with CAT function */
/* Create date variable with WEEKDAY,WEEK,MONTH,YEAR functions */
/* These are useful for weekend/weekday effects and visualizing results */
/* Note: Sunday=1, Saturday=7 in the WEEKDAY function */
/* Create a random number to pick a selection of injuries.  */
/* Note: Labelling Prod1 or Prod2 breaks HPSPLIT due to unexpected special characters */
/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

data injuries; 
	length narr1 $72.;
	set neiss.neiss2015 neiss.neiss2016 neiss.neiss2017;
/* 	drop fmv race raceoth diagoth; */

	format sex gender.;
	format race race.;
 	format bdpt bdypt.;
 	format diag diag.;
 	format disp disp.;
 	format loc loc.;
	format dow dowf.;
	format prod1 prod.;
	format fmv fire.;
	
	narrative=cat(narr1,narr2);
	dow=weekday(trmt_date);
	week=week(trmt_date);
	month=month(trmt_date);
	year=year(trmt_date);
	if dow in (1,7) then we=1; else we=0;
	if dow in (2,3,4,5,6) then wd=1; else wd=0; 
	call streaminit(4567);
	randno=rand('uniform');
run;

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Query the injury table to understand what terms are relevant to the injury
/* Note that DIAG and PROD1 are numeric and should not be in quotes
/* This helps understand which terms to select */
/* Below bdpt=75 and prod1=1211 are selected. Edit to reflect a case of interest. */
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

title 'Random Selection of Injury Narratives';
proc sql outobs=25;
	select randno, bdpt label='Body Part', prod1, narr1, narr2
	from injuries
	where bdpt=75 and prod1=1211
	order by randno;
quit;

title 'Distribution of Injuries by Sampling Stratum';
title2 'Note: National Estimate is the Sum of the wt Variable';
title3 'Check the Coding Manual for Descriptions';
proc sql outobs=25;
	select stratum label='Sampling Stratum', 
		count(*) as freq label='Frequency', 
		sum(wt) as sum_wt label='National Estimate'
	from injuries
	where bdpt=75 and prod1=1211
	group by stratum
	order by freq desc;
quit;
	
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Note: WHERE clause will limit the data set to rows meeting the criteria */
/* Combine two narrative fields narr1 and narr2 with CAT function */
/* Find terms related to cuts using INDEX function*/
/* Code a mydef variable using variables like diag, bdpt, or Prod1
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

data classifier; set injuries;
	where prod1=1211 AND (age > 4 AND age < 19);
	if index(narrative,'CONCUSSION') > 0 then narr_concussion=1;
		else narr_concussion=0;
	if index(narrative,'FOOTBALL') > 0 then narr_football=1;
		else narr_football=0;
	if index(narrative,'PLAY') > 0 then narr_play=1;
		else narr_play=0;
	if index(narrative,'HELMET') > 0 then narr_helmet=1;
		else narr_helmet=0;
	if index(narrative,'HEAD')>0 then narr_head=1;
		else narr_head=0;
	if  bdpt=75 then mydef=1;
		else mydef=0;
run;

title 'Frequency of Injuries';
proc freq data=classifier;
	tables mydef;
run;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* HPSPLIT Code starts here */
/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Note: Do Not include variables from WHERE statement or case definition [MYDEF] */
proc hpsplit data=classifier cvcc cvmodelfit
	assignmissing=similar
	cvmethod=random (10);
	prune reducederror;
	id NEK psu wt stratum;
	weight wt;
	class mydef disp dow fmv loc month prod1 prod2 race sex wd we week year narr_:;
	model mydef(event='1') = disp dow fmv loc month prod1 prod2 race sex wd we week year narr_:;
	output out=mydef_cvxx_modelxx;
run;

data mydef_code; set mydef_cvxx_modelxx;
	format mydef myfmt.;
	if P_mydef1 > 0.50 then mytest=1;
		else mytest=0;
run;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Run Bootstrap analysis 100 times */
/* Incorporate the statistical weight [WT] of the observation */
/* Incorporate the type of hospital [STRATUM] */
/* Incorporate the Primary Statistical Unit [PSU] which corresponds to hospital ID */
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

title 'Bootstrap Analysis 100 reps';
proc surveyfreq data=mydef_code varmethod=bootstrap (reps=100);
   	tables  mydef*mytest / row column cl alpha=0.05 plots=all;
   	weight wt;
   	strata stratum;
	cluster psu;
run;

title 'Bootstrap Analysis - 1000 Reps';
proc surveyfreq data=mydef_code varmethod=bootstrap (reps=1000);
   	tables  mydef*mytest / row column cl alpha=0.05 plots=all;
   	weight wt;
   	strata stratum;
	cluster psu;
run;