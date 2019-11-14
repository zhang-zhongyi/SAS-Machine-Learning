libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';
/* libname neiss 'c:/sas/lib/neiss'; */

/* Read in NEISS formats */
proc format
 	cntlin=neiss.neiss_fmt;
run;

/* Apply NEISS formats */
/* Use CAT function to create narrative variable */
data injuries; set neiss.neiss2016;
	format age 8.2;
	if age ge 201 AND age le 223 then age=(age-200)/12;
 		else age=age;
 	narrative=cat(narr1,narr2);
 	format bdpt bdypt.;
 	format diag diag.;
 	format disp disp.;
 	format fmv fire.;
 	format loc loc.;
 	format prod1 prod2 prod.;
 	format race race.;
 	format sex gender.;
 	call streaminit(4567);
	randno=rand('uniform');
run;

title 'Frequency of Diagnosis and Body Part';
proc freq data=injuries order=freq;
	tables diag bdpt;
run;

title 'Examine random sample of laceration (diag=59) narratives';
proc sql outobs=25;
	select randno, diag, narrative
	from injuries
	where diag=59
	order by randno;
quit;
	
/* Example of creating a new format */
proc format;
 	value casef
 		1 = 'Case'
 		2 = 'Non-Case';
run;

/* Code the narrative using INDEX function */
data classifier; set injuries;
	format mydef mytest casef.;
	if index(narrative,'CUT') > 0 then mytest = 1;
		else mytest=2;
	if diag=59 then mydef=1;
		else mydef=2;
	if mydef=1 and mytest=1 then class='A';
		else if mydef=2 and mytest=1 then class='B';
		else if mydef=1 and mytest=2 then class='C';
		else if mydef=2 and mytest=2 then class='D';
		else class='Other';	
run;

/* Calculate frequency of MYTEST in narrative */
/* 2x2 table of MYTEST and MYDEF */
/* This table is a shortcut to sensitivity and specificity */
title 'Calculate Sensitivity, Specificity, PPV, NPV';
proc freq data=classifier; 
	table mytest;
	tables mytest*mydef /nocum;
	tables class;
run;

title 'Examine mydef=1 narratives';
proc sql outobs=25;
	select randno, mydef, mytest, diag, narrative
	from classifier
	where mydef=1
	order by randno;
quit;	

/* Code the narrative using INDEX function */
data classifier02; set injuries;
	format mydef mytest casef.;
	if index(narrative,'CUT') > 0 
		OR index(narrative,'LAC') > 0
		then mytest = 1;
		else mytest=2;
	if diag=59 then mydef=1;
		else mydef=2;
	if mydef=1 and mytest=1 then class='A';
		else if mydef=2 and mytest=1 then class='B';
		else if mydef=1 and mytest=2 then class='C';
		else if mydef=2 and mytest=2 then class='D';
		else class='Other';	
run;

/* Calculate frequency of MYTEST in narrative */
/* 2x2 table of MYTEST and MYDEF */
/* This table is a shortcut to sensitivity and specificity */
title 'Classifier2: Calculate Sensitivity, Specificity, PPV, NPV';
proc freq data=classifier02; 
	table mytest;
	tables mytest*mydef /nocum;
	tables class;
run;

title 'Examine random sample of mydef=1, mytest=2 narratives';
proc sql outobs=25;
	select randno, mydef, mytest, diag, narrative
	from classifier02
	where mydef=1 and mytest=2
	order by randno;
quit;	