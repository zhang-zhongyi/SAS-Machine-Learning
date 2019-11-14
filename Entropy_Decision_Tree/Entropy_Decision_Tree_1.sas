/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Uncomment or edit the appropriate path for your libname */
/* Note: SAS On-Demand libname*/
libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';
libname entropy  '/courses/dc41eb55ba27fe300/lib/entropy';

/* Note: Windows path */
/* libname neiss 'c:\sas\lib\neiss\'; */
/* libname entropy 'c:\sas\lib\entropy'; */

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
/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Build trees */
/* Rules output */
/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
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
/* 	rules file='/home/nicholassoulakis0/my_content/out/entropy/football_rules.txt'; */
run;

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Code results of Classification Tree Analysis */
/* If the probability of an injury [P_mydef_1] is  */
/* greater than 0.50 TEST is positive. */
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

data mydef_code; set mydef_leaves;
	if P_mydef1 > 0.50 then test=1;
		else test=0;
	call streaminit(30003);
	randno=rand('uniform');
run;

/* 		JOIN cases to assigned node */
proc sql;
	create table injuries_nodes as	
		select a.*, b.*
		from entropy.tree a left join mydef_code b
			on a.NEK=b.NEK;
quit;

data investigate_nodes; set injuries_nodes;
	drop var:;
run;

proc sql;
	create table node_stat as
	select _node_,_leaf_,
		sum(case when mydef=1 then 1 else 0 end) as cases 
			format comma20. label "Cases (N)",
		sum(case when mydef=1 then 1 else 0 end)/count(*) as pct_cases 
			format percent8.2 label "Cases (%)",
		sum(case when mydef=0 then 1 else 0 end) as non_cases 
			format comma20. label "Non-Cases (N)",
		sum(case when mydef=0 then 1 else 0 end)/count(*) as pct_noncases 
			format percent8.2 label 'Non-Cases (%)',
		count(*) as freq format comma20. label "Total Number of Injuries"
	from investigate_nodes
	group by _node_, _leaf_
	order by freq desc;
quit;

/* ************************************************************************ */			
/* Summarize nodes */
/* Some nodes have high percentage of cases, others controls			 */
/* ************************************************************************ */
proc sql;
	title 'Node Summary';
	select _node_,
		min(age) as min_age format 8.2 label "Minimum Age",
		mean(age) as mean_age format 8.2 label  "Mean Age",
		max(age) as max_age format 8.2 label "Maximum Age",
		sum(case when mydef=1 then 1 else 0 end) as cases format comma20. label "Cases (N)",
		sum(case when mydef=0 then 1 else 0 end) as non_cases 
			format comma20. label "Non-Cases (N)",
		sum(case when mydef=0 then 1 else 0 end)/count(*) as pct_noncases 
			format percent8.2 label 'Non-Cases (%)'
	from investigate_nodes
	group by _node_, _leaf_
	order by cases desc;
quit;

/*	Customize line list for your scenario and needs*/
/*	Add a CREATE TABLE statement to output the data to a table for export*/
proc sql;
	title 'Missclassification (Case=1, Test=0): Simple Line List for Follow-up';
	select NEK, randno, mydef label="Injury?", test, diag, P_mydef1,
		dow, _Node_,trmt_date, 
		bdpt, loc, age, sex, narrative, narr1, narr2
	from investigate_nodes
	where mydef = 1 and test=0
	order by randno, trmt_date desc;
quit;

/*	Customize line list for your scenario and needs*/
/*	Add a CREATE TABLE statement to output the data to a table for export*/
proc sql;
	title 'Missclassification (Case=0, Test=1): Simple Line List for Follow-up';
	select randno, mydef label="Injury?", test, diag, P_mydef1,
		dow, _Node_,trmt_date, 
		bdpt, loc, age, sex, narrative
	from investigate_nodes
	where mydef = 0 and test=1
	order by randno, trmt_date desc;
quit;

proc sql outobs=10;
	title 'Random Sample All Nodes: Line List for Follow-up';
	select randno, mydef label="Injury?", psu label="Hospital ID", wt, diag, P_mydef1,
		dow, a.week, month, 
		a._Node_, a._leaf_, a.trmt_date, 
		bdpt, loc, age, sex, narrative
	from injuries_nodes a
	order by randno, a.trmt_date, P_mydef1 desc;
quit;

/*	Customize line list for your scenario and needs*/
/*	Add a CREATE TABLE statement to output the data to a table for export*/
proc sql outobs=10;
	title 'High Case % Nodes: Simple Line List for Follow-up';
	select randno, mydef label="Injury?", diag, P_mydef1,
		dow, a._Node_,a.trmt_date, 
		bdpt, loc, age, sex, narrative
	from investigate_nodes a left join node_stat b
		on a._node_=b._node_
		and a._leaf_=b._leaf_
	where pct_noncases > 0
	order by randno, a.trmt_date, P_mydef1 desc;
quit;