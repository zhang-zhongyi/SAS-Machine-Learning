/* +++++++++++++++++++++++++++++++++ */
/* Uncomment or edit the appropriate path for your libname */
/* Note: SAS On-Demand libname*/
libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';
libname entropy  '/courses/dc41eb55ba27fe300/lib/entropy';

/* Note: Windows path*/
/* libname neiss 'c:\sas\lib\neiss\'; */
/* libname entropy 'C:\sas\lib\temp\entropy'; */

/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Read in NEISS formats */
/* Create a day of week format with PROC FORMAT */
/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
proc format
 	cntlin=neiss.neiss_fmt;
run;

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

title 'Frequency of Injury';
proc freq data=entropy.tree;
	tables mydef;
run;

title 'Analysis of Terms Predictive of Head Injury';
proc hpsplit data=entropy.tree cvcc nodes
	seed=20001
	cvmodelfit
	assignmissing=similar
	cvmethod=random (10);
	grow entropy;
	prune reducederror (leaves=20);
	id NEK psu wt stratum;
	weight wt;
	class mydef disp fmv race sex dow var:;
	model mydef (event='1') = age disp fmv race sex 
		week dow month var:;
	output out=mydef_leaves;
run;

proc hpforest data=entropy.tree maxtrees=10;
	input var: /level=binary;
	target mydef/level=binary;
	ods output FitStatistics=fitstats
		(rename=(Ntrees=Trees));
run;

data fitstats;
   set fitstats;
   label Trees = 'Number of Trees';
   label MiscAll = 'Full Data';
   label Miscoob = 'OOB';
run;

proc sgplot data=fitstats;
   	title "OOB vs Training";
   	series x=Trees y=MiscAll;
   	series x=Trees y=MiscOob/
   		lineattrs=(pattern=shortdash thickness=2);
   	yaxis label='Misclassification Rate';
run;
title;

%macro hpforest(Vars=);
proc hpforest data=entropy.tree maxtrees=100
   	vars_to_try=&Vars.;
	input var: /level=binary;
	target mydef/level=binary;
   	ods output
   	FitStatistics = fitstats_vars&Vars.
   		(rename=(Miscoob=VarsToTry&Vars.));
run;
%mend;

%hpforest(vars=all);
%hpforest(vars=40);
%hpforest(vars=26);
%hpforest(vars=7);
%hpforest(vars=2);

data fitstats; set fitstats_varsall 
		fitstats_vars40 fitstats_vars26 
   		fitstats_vars7 fitstats_vars2;
	rename Ntrees=Trees;
	label VarsToTryAll="Vars=All" 
		VarsToTry40="Vars=40" 
		VarsToTry26="Vars=26" 
		VarsToTry7="Vars=7" 
		VarsToTry2="Vars=2";
run;

proc sgplot data=fitstats;
   	title "Misclassification Rate for Various 
   		VarsToTry Values";
	series x=Trees y = VarsToTryAll/
   		lineattrs=(Color=black);
   	series x=Trees y=VarsToTry40/
   		lineattrs=
   			(Pattern=ShortDash Thickness=2);
   	series x=Trees y=VarsToTry26/
   		lineattrs=
   			(Pattern=ShortDash Thickness=2);
   	series x=Trees y=VarsToTry7/
   		lineattrs=
   			(Pattern=MediumDashDotDot Thickness=2);
   	series x=Trees y=VarsToTry2/
   		lineattrs=(Pattern=LongDash Thickness=2);
   	yaxis label='OOB Misclassification Rate';
run;
title;

%macro hpforest(f=, output_suffix=);
proc hpforest data=entropy.tree maxtrees=5 
		vars_to_try=26
   	trainfraction=&f;
	input var: /level=binary;
	target mydef/level=binary;
   	ods output
   	FitStatistics = fitstats_f&output_suffix.
   		(rename=(Miscoob=fraction&output_suffix.));
run;
%mend;

%hpforest(f=0.8, output_suffix=08);
%hpforest(f=0.6, output_suffix=06);
%hpforest(f=0.4, output_suffix=04);

data fitstats;
   	set fitstats_f08 fitstats_f06 fitstats_f04;
   	rename Ntrees=Trees;
   	label fraction08="Fraction=0.8" 
   		fraction06="Fraction=0.6" 
   		fraction04="Fraction=0.4";
run;

/* In this example, INBAGFRACTION=0.4 and INBAGFRACTION=0.6 produce the best OOB misclassification rate initially, with few trees.  */
/* When more trees are used, INBAGFRACTION=0.8 is best. */

proc sgplot data=fitstats;
   title "Misclassification Rate for Various Fractions of Training Data";
   series x=Trees y=fraction08/lineattrs=(Pattern=ShortDash Thickness=2);
   series x=Trees y=fraction06/lineattrs=(Pattern=MediumDashDotDot Thickness=2);
   series x=Trees y=fraction04/lineattrs=(Pattern=LongDash Thickness=2);
   yaxis label='OOB Misclassification Rate';
run;
title;

%macro hpforest(f=, output_suffix=);
proc hpforest data=entropy.tree maxtrees=75
		vars_to_try=26
   	trainfraction=&f;
	input var: /level=binary;
	target mydef/level=binary;
   	ods output
   	FitStatistics = fitstats_f&output_suffix.
   		(rename=(Miscoob=fraction&output_suffix.));
run;
%mend;

%hpforest(f=0.8, output_suffix=5008);
%hpforest(f=0.6, output_suffix=5006);
%hpforest(f=0.4, output_suffix=5004);

data fitstats50;
   	set fitstats_f5008 fitstats_f5006 fitstats_f5004;
   	rename Ntrees=Trees;
   	label fraction5008="Fraction=0.8" 
   		fraction5006="Fraction=0.6" 
   		fraction5004="Fraction=0.4";
run;

/* In this example, INBAGFRACTION=0.4 and INBAGFRACTION=0.6 produce the best OOB misclassification rate initially, with few trees.  */
/* When more trees are used, INBAGFRACTION=0.8 is best. */

proc sgplot data=fitstats50;
   title "Misclassification Rate for Various Fractions of Training Data";
   series x=Trees y=fraction5008/lineattrs=(Pattern=ShortDash Thickness=2);
   series x=Trees y=fraction5006/lineattrs=(Pattern=MediumDashDotDot Thickness=2);
   series x=Trees y=fraction5004/lineattrs=(Pattern=LongDash Thickness=2);
   yaxis label='OOB Misclassification Rate';
run;
title;

