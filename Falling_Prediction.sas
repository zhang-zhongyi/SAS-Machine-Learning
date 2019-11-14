libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';
/* libname neiss 'c:/sas/lib/neiss'; */

/* Read in NEISS formats */
proc format
 	cntlin=neiss.neiss_fmt;
run;

/* Apply NEISS formats */
/* Use CAT function to create narrative variable */
data classifier0; set neiss.neiss2016;
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
proc freq data=classifier0 order=freq;
	tables diag bdpt;
run;

title 'Examine random sample of FELL (diag=57) narratives';
proc sql outobs=25;
	select randno, diag, narrative
	from classifier0
	where diag=57
	order by randno;
quit;
	
/* Example of creating a new format */
proc format;
 	value casef
 		1 = 'Case'
 		2 = 'Non-Case';
run;

/* Original sensitivity and specificity */

/* Code the narrative using INDEX function */
data classifier2; set classifier0;
	format mydef mytest casef.;
	if index(narrative,'FELL') > 0 then mytest = 1;
		else mytest=2;
	if diag=57 then mydef=1;
		else mydef=2;
	if mydef=1 and mytest=1 then class='A';
		else if mydef=2 and mytest=1 then class='C';
		else if mydef=1 and mytest=2 then class='B';
		else if mydef=2 and mytest=2 then class='D';
		else class='Other';	
run;

title 'Calculate Sensitivity, Specificity, PPV, NPV';
proc freq data=classifier2; 
	table mytest;
	tables mytest*mydef /nocum;
	tables class;
run;

/* SQL queries to extract tables */
title 'Examine mydef=1 narratives';
proc sql outobs=25;
	select randno, mydef, mytest, diag, narrative
	from classifier2
	where mydef=1 and mytest=2
	order by randno;
quit;	

/* First iteration: */

data classifier3; set classifier0;
	format mydef mytest casef.;
	if (index(narrative,'FELL') > 0 or index(narrative,'FRACT') > 0)
	and index(narrative,'LAC') = 0 then mytest = 1;
		else mytest=2;
	if diag=57 then mydef=1;
		else mydef=2;
	if mydef=1 and mytest=1 then class='A';
		else if mydef=2 and mytest=1 then class='C';
		else if mydef=1 and mytest=2 then class='B';
		else if mydef=2 and mytest=2 then class='D';
		else class='Other';	
run;

title 'Calculate Sensitivity, Specificity, PPV, NPV';
proc freq data=classifier3; 
	table mytest;
	tables mytest*mydef /nocum;
	tables class;
run;

/* SQL queries to extract tables */
title 'Examine mydef=1 narratives';
proc sql outobs=40;
	select randno, mydef, mytest, diag, narrative
	from classifier3
	where mydef=1 and mytest=2
	order by randno;
quit;	

/* Second iteration: */

data classifier4; set classifier0;
	format mydef mytest casef.;
	if (index(narrative,'FELL') > 0 or index(narrative,'FRACT') > 0 or index(narrative,'BONE') > 0)
	and index(narrative,'LAC') = 0 and index(narrative,'BURN') = 0
	then mytest = 1;
		else mytest=2;
	if diag=57 then mydef=1;
		else mydef=2;
	if mydef=1 and mytest=1 then class='A';
		else if mydef=2 and mytest=1 then class='C';
		else if mydef=1 and mytest=2 then class='B';
		else if mydef=2 and mytest=2 then class='D';
		else class='Other';	
run;

title 'Calculate Sensitivity, Specificity, PPV, NPV';
proc freq data=classifier4; 
	table mytest;
	tables mytest*mydef /nocum;
	tables class;
run;

/* SQL queries to extract tables */
title 'Examine mydef=1 narratives';
proc sql outobs=40;
	select randno, mydef, mytest, diag, narrative
	from classifier4
	where mydef=1 and mytest=2
	order by randno;
quit;

/* Third iteration: */

data classifier5; set classifier0;
	format mydef mytest casef.;
	if (index(narrative,'FELL') > 0 or index(narrative,'FRACT') > 0 or index(narrative,'BONE') > 0 
	or index(narrative,'DX') > 0) and index(narrative,'LAC') = 0 and index(narrative,'CONTU') = 0
	and index(narrative,'ABRA') = 0 and index(narrative,'HEAD') = 0
	and index(narrative,'PAIN') = 0 and index(narrative,'STRAI') = 0 
	then mytest=1;
	     else mytest=2;
	if diag=57 then mydef=1;
		else mydef=2;
	if mydef=1 and mytest=1 then class='A';
		else if mydef=2 and mytest=1 then class='C';
		else if mydef=1 and mytest=2 then class='B';
		else if mydef=2 and mytest=2 then class='D';
		else class='Other';	
run;

title 'Calculate Sensitivity, Specificity, PPV, NPV';
proc freq data=classifier5; 
	table mytest;
	tables mytest*mydef /nocum;
	tables class;
run;

/* SQL queries to extract tables */
title 'Examine mydef=1 narratives';
proc sql outobs=40;
	select randno, mydef, mytest, diag, narrative
	from classifier5
	where mydef=1 and mytest=2
	order by randno;
quit;

/* Fourth iteration: */

data classifier6; set classifier0;
	format mydef mytest casef.;
	if (index(narrative,'FELL') > 0 or index(narrative,'FRACT') > 0 or index(narrative,'FX') > 0) 
    and index(narrative,'LAC') = 0 and index(narrative,'CONTU') = 0 and index(narrative,'ABRA') = 0 
    and index(narrative,'LOC') = 0  and index(narrative,'STRAI') = 0 
    and index(narrative,'SPRAI') = 0 then mytest = 1;
		else mytest=2;
	if diag=57 then mydef=1;
		else mydef=2;
	if mydef=1 and mytest=1 then class='A';
		else if mydef=2 and mytest=1 then class='C';
		else if mydef=1 and mytest=2 then class='B';
		else if mydef=2 and mytest=2 then class='D';
		else class='Other';	
run;

title 'Calculate Sensitivity, Specificity, PPV, NPV';
proc freq data=classifier6; 
	table mytest;
	tables mytest*mydef /nocum;
	tables class;
run;

/* SQL queries to extract tables */
title 'Examine mydef=1 narratives';
proc sql outobs=40;
	select randno, mydef, mytest, diag, narrative
	from classifier6
	where (mydef=2 and mytest=1) or (mydef=1 and mytest=2)
	order by randno;
quit;

/* Fifth iteration: */

data classifier7; set classifier0;
	format mydef mytest casef.;
	if (index(narrative,'FELL') > 0 or index(narrative,'FRAC') > 0 or index(narrative,'FX') > 0) 
    and index(narrative,'LAC') = 0 and index(narrative,'CONTU') = 0 and index(narrative,'ABRA') = 0 
    and index(narrative,'LOC') = 0  and index(narrative,'STRAI') = 0 
    and index(narrative,'SPRAI') = 0 and index(narrative,'EYE') = 0 and index(narrative,'FOREIG') = 0
    then mytest = 1;
		else mytest=2;
	if diag=57 then mydef=1;
		else mydef=2;
	if mydef=1 and mytest=1 then class='A';
		else if mydef=2 and mytest=1 then class='C';
		else if mydef=1 and mytest=2 then class='B';
		else if mydef=2 and mytest=2 then class='D';
		else class='Other';	
run;

title 'Calculate Sensitivity, Specificity, PPV, NPV';
proc freq data=classifier7; 
	table mytest;
	tables mytest*mydef /nocum;
	tables class;
run;

/* SQL queries to extract tables */
title 'Examine mydef=1 narratives';
proc sql outobs=40;
	select randno, mydef, mytest, diag, narrative
	from classifier7
	where mydef=2 and mytest=1
	order by randno;
quit;

















/*  */
/* data classifier7; set classifier0; */
/* 	format mydef mytest casef.; */
/* 	if index(narrative,'FELL') > 0 and index(narrative,'LAC') = 0 and index(narrative,'CONTU') = 0 */
/* 	and index(narrative,'ABRA') = 0 and index(narrative,'HEAD') = 0 and index(narrative,'LOC') = 0 */
/* 	and index(narrative,'PAIN') = 0 and index(narrative,'STRAI') = 0 and index(narrative,'SPRAI') = 0 */
/* 	and index(narrative,'CONTS') = 0 and index(narrative,'KNEE') = 0 and index(narrative,'HAND') = 0 */
/* 	and index(narrative,'EYE') = 0 and index(narrative,'EAR') = 0 */
/* 	and index(narrative,'FOREIG') = 0 */
/* 	then mytest = 1; */
/* 		else mytest=2; */
/* 	if diag=57 then mydef=1; */
/* 		else mydef=2; */
/* 	if mydef=1 and mytest=1 then class='A'; */
/* 		else if mydef=2 and mytest=1 then class='C'; */
/* 		else if mydef=1 and mytest=2 then class='B'; */
/* 		else if mydef=2 and mytest=2 then class='D'; */
/* 		else class='Other';	 */
/* run; */
/*  */
/* title 'Calculate Sensitivity, Specificity, PPV, NPV'; */
/* proc freq data=classifier7;  */
/* 	table mytest; */
/* 	tables mytest*mydef /nocum; */
/* 	tables class; */
/* run; */
/*  */
/* SQL queries to extract tables */
/* title 'Examine mydef=1 narratives'; */
/* proc sql outobs=40; */
/* 	select randno, mydef, mytest, diag, narrative */
/* 	from classifier7 */
/* 	where mydef=1 and mytest=2 */
/* 	order by randno; */
/* quit; */


