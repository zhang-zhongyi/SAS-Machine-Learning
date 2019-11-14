/* OnDemand: Map library to NEISS folder under my_courses folder using shortcut */
/* libname neiss '/courses/dc41eb55ba27fe300/lib/neiss'; */
libname neiss 'C:/SAS/lib/neiss';

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
title;

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
/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

data injuries; set neiss.neiss2015 neiss.neiss2016 neiss.neiss2017;
	drop fmv race raceoth diagoth;
	format sex gender.;
	format race race.;
 	format bdpt bdypt.;
 	format diag diag.;
 	format disp disp.;
 	format loc loc.;
	format dow dowf.;
	format prod1 prod.;
	
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
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

title 'Random Selection of Football Head Injuries Narratives';
proc sql outobs=25;
	select randno, bdpt label='Body Part', prod1, narr1, narr2
	from injuries
	where bdpt=75 and prod1=1211
	order by randno;
quit;

title 'Distribution of Head injuries by Sampling Stratum';
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
/* Combine two narrative fields narr1 and narr2 with CAT function */
/* Find terms related to cuts using INDEX function*/
/* Code a football_head variable if the patient has a diagnosis [52] and a FOOTBALL product 1
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

data football; set injuries;
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
	if  bdpt=75 then football_head=1;
		else football_head=0;
run;

title 'Frequency of Football Head Injuries among 5-18 year-olds';
proc freq data=football;
	tables football_head;
run;
title;

/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* HPSPLIT Code starts here */
/* +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
proc hpsplit data=football cvcc cvmodelfit
	assignmissing=similar
	cvmethod=random (2);
	prune reducederror (leaves=all);
	id NEK psu wt stratum;
	weight wt;
	class football_head narr_:;
	model football_head(event='1') =narr_:;
	output out=football_cv02_model01;
run;

proc hpsplit data=football cvcc
	cvmodelfit
	assignmissing=similar
	cvmethod=random (2);
	prune reducederror (leaves=all);
	id NEK psu wt stratum;
	weight wt;
	class football_head narr_: loc;
	model football_head(event='1') =narr_: loc;
	output out=football_cv02_model02;
run;

proc hpsplit data=football cvcc
	cvmodelfit
	assignmissing=similar
	cvmethod=random (2);
	prune reducederror (leaves=all);
	id NEK psu wt stratum;
	weight wt;
	class football_head narr_: loc sex;
	model football_head(event='1') =narr_: loc sex;
	output out=football_cv02_model03;
run;

proc hpsplit data=football cvcc
	cvmodelfit
	assignmissing=similar
	cvmethod=random (2);
	prune reducederror (leaves=all);
	id NEK psu wt stratum;
	weight wt;
	class football_head narr_: loc sex disp;
	model football_head(event='1') =narr_: loc sex disp;
	output out=football_cv02_model04;
run;

proc hpsplit data=football cvcc
	cvmodelfit
	assignmissing=similar
	cvmethod=random (2);
	prune reducederror (leaves=all);
	id NEK psu wt stratum;
	weight wt;
	class football_head narr_: loc sex disp prod2;
	model football_head(event='1') =narr_: loc sex disp prod2;
	output out=football_cv02_model05;
run;

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Code results of Classification Tree Analysis */
/* If the probability of a football head injury [P_football_head1] is  */
/* greater than 0.50 TEST is positive. */
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

data football_code; set football_cv02_model05;
	if P_football_head1 > 0.50 then test=1;
		else test=0;
run;