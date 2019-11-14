libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';
/* libname neiss 'c:/sas/lib/neiss'; */

/* Code the narrative using INDEX function */
data lacerations; set neiss.neiss2016;
	keep nek narrative cut diag lac class;
	narrative=cat(narr1,narr2);
	if index(narrative,'CUT') > 0 then cut = 1;
		else cut=2;
	if diag=59 then lac=1;
		else lac=2;
	if lac=1 and cut=1 then class='A';
		else if lac=2 and cut=1 then class='B';
		else if lac=1 and cut=2 then class='C';
		else if lac=2 and cut=2 then class='D';
		else class='Other';	
run;

/* Calculate frequency of CUT in narrative */
/* 2x2 table of CUT and lacerations */
/* This table is a shortcut to sensitivity and specificity */
title 'CUT';
proc freq data=lacerations; 
	table cut;
	tables cut*lac /nocum;
	tables class;
run;

/* Code a LAC variable if the patient has a diagnosis of laceration */
data lacerations02; set neiss.neiss2016;
	keep nek narrative cut diag lac class;
	narrative=cat(narr1,narr2);
	if (index(narrative,'CUT') > 0 
		OR index(narrative,'LAC') > 0)
			then cut = 1;
		else cut=2;
	if diag=59 then lac=1;
		else lac=2;
	if lac=1 and cut=1 then class='A';
		else if lac=2 and cut=1 then class='B';
		else if lac=1 and cut=2 then class='C';
		else if lac=2 and cut=2 then class='D';
		else class='Other';	
run;

title 'CUT OR LAC';
/* Frequency of CUT and Lacerations */
proc freq data=lacerations02;
	tables cut lac;
	tables class;
run;

/* Frequency of CUT and Lacerations */
proc freq data=lacerations02;
	tables cut*lac /nocum;
run;

/* Add CLASS variable to show count in each cell of 2x2 table */
data lacerations03; set neiss.neiss2016;
	keep nek narrative cut diag lac class;
	narrative=cat(narr1,narr2);
	if (index(narrative,'CUT') > 0 
		OR index(narrative,'LAC') > 0)
		AND index(narrative,'SCISSORS')=0
			then cut = 1;
		else cut=2;
	if diag=59 then lac=1;
		else lac=2;
	if lac=1 and cut=1 then class='A';
		else if lac=2 and cut=1 then class='B';
		else if lac=1 and cut=2 then class='C';
		else if lac=2 and cut=2 then class='D';
			else class='Other';	
run;

title '(CUT OR LAC) NOT SCISSORS';
proc freq data=lacerations03;
	tables cut lac;
	tables cut*lac /nocum;
	tables class;
run;

/* Add CLASS variable to show count in each cell of 2x2 table */
data lacerations04; set neiss.neiss2016;
	keep nek narrative cut diag lac class;
	narrative=cat(narr1,narr2);
	if (index(narrative, 'CUT') > 0 
		OR index(narrative, 'LAC') > 0)
		AND index(narrative,'SCISSORS')=0
		AND index(narrative, 'KNIFE') > 0
			then cut = 1;
		else cut=2;
	if diag=59 then lac=1;
		else lac=2;
	if lac=1 and cut=1 then class='A';
		else if lac=2 and cut=1 then class='B';
		else if lac=1 and cut=2 then class='C';
		else if lac=2 and cut=2 then class='D';
			else class='Other';	
run;

title '((CUT OR LAC) AND KNIFE) NOT SCISSORS';
proc freq data=lacerations04;
	tables cut lac;
	tables cut*lac /nocum;
	tables class;
run;

/* Add CLASS variable to show count in each cell of 2x2 table */
data lacerations05; set neiss.neiss2016;
	keep nek narrative cut diag lac class;
	narrative=cat(narr1,narr2);
	if (index(narrative,'CUT') > 0 
		OR index(narrative,'LAC')>0)
		AND index(narrative,'SCISSORS')=0
		AND index(narrative,'KNIFE') > 0
		AND index(narrative,'FALL')=0
			then cut = 1;
		else cut=2;
	if diag=59 then lac=1;
		else lac=2;
	if lac=1 and cut=1 then class='A';
		else if lac=2 and cut=1 then class='B';
		else if lac=1 and cut=2 then class='C';
		else if lac=2 and cut=2 then class='D';
			else class='Other';	
run;

title '((CUT OR LAC) AND KNIFE) NOT (SCISSORS OR FALL)';
proc freq data=lacerations05;
	tables cut lac;
	tables cut*lac /nocum;
	tables class;
run;