/* Comments and Video Forthcoming */
/* Name: Troy Zhongyi Zhang */
/* Netid: zhongyiz@uchicago.edu */

/* Lab02_Part 2: Submit Assignment. (30 points) */
libname yelp  '/courses/dc41eb55ba27fe300/lib/yelp';

title 'Listing of Variable Names with Output set to WORK';
proc contents data=yelp.lv_inspection_tree out=contents_lv_inspection_tree; run;

title 'Analysis of Yelp Tip Terms + Structured Variables Predictive of Restaurant Violations';
title2 'Edit path and uncomment RULES statement to output a rules file';


/* I used min_demerits for binary classification to calculate the sensitivity, specificity, etc. */
data demerits; set yelp.lv_inspection_tree;
	if min_demerits>0 then mydef=1;
	else mydef=0;
run;


title 'Frequency of Demerits';
proc freq data=demerits;
	tables mydef;
run;

/* HPSPLIT Code starts here */
/* 50/50 train/test split */
proc hpsplit data=demerits cvcc cvmodelfit
	assignmissing=similar
	cvmethod=random (2);
	prune reducederror(leaves=20);
	id business_id permit_number;
	class mydef is_open  neighborhood;
	model mydef(event='1') = is_open stars review_count neighborhood  var:;
	output out=yelp_leaves_lv;
run;

/* 5 cross-validation */
proc hpsplit data=demerits cvcc cvmodelfit
	assignmissing=similar
	cvmethod=random (5);
	prune reducederror(leaves=20);
	id business_id permit_number;
	class mydef is_open  neighborhood;
	model mydef(event='1') = is_open stars review_count neighborhood  var:;
	output out=yelp_leaves_lv;
run;

/* 10 cross-validation */
proc hpsplit data=demerits cvcc cvmodelfit
	assignmissing=similar
	cvmethod=random (10);
	prune reducederror(leaves=20);
	id business_id permit_number;
	class mydef is_open  neighborhood;
	model mydef(event='1') = is_open stars review_count neighborhood  var:;
	output out=yelp_leaves_lv;
run;

data mydef_code; set yelp_leaves_lv;
	format mydef myfmt.;
	if P_mydef1 > 0.50 then mytest=1;
		else mytest=0;
run;

/* Compare the results of 100 bootstrapping samples and 1,000 bootstrapping samples */
/* 100 bootstrapping samples */
title 'Bootstrap Analysis 100 reps';
proc surveyfreq data=mydef_code varmethod=bootstrap (reps=100);
   	tables  mydef*mytest / row column cl alpha=0.05 plots=all;
run;

/* 1,000 bootstrapping samples */
title 'Bootstrap Analysis - 1000 Reps';
proc surveyfreq data=mydef_code varmethod=bootstrap (reps=1000);
   	tables  mydef*mytest / row column cl alpha=0.05 plots=all;
run;

/* ---------------------------------------------------------------------------------- */
/* Compare the decision tree model and the random forest model for restaurants of Las Vegas */

/* The Decision Tree Model */
proc hpsplit data=yelp.lv_inspection_tree cvcc 
	seed=20001
	cvmodelfit
	assignmissing=similar;
	prune reducederror (leaves=20);
	id business_id permit_number;
	class is_open  neighborhood;
	model sum_demerits = is_open stars review_count neighborhood  var:;
	output out=yelp_leaves_lv;
/* 	rules file='/courses/dc41eb55ba27fe300/out/yelp/lv_rules_00.txt'; */
run;

title 'Node Summary';
proc sql;
	select _leaf_, _node_, count(*) as freq label='Frequency',
		avg(p_sum_demerits) as pred_demerits label='Predicted Demerits',
		min(sum_demerits) as min_p_sum_demerits label='Minimum Demerits',
		std(sum_demerits) as std_p_sum_demerits label='Std Deviation',
		max(sum_demerits) as max_p_sum_demerits label='Maximum Demerits'
	from yelp_leaves_lv
	group by _leaf_, _node_
	order by pred_demerits desc;
quit;

/* The Random Forest Models */

title 'Random Forest Model';
title2 'Note output of Fit Statistics (fitstats) Variable Importance (VarImportance)';
title3 'and Score (score_restaurants)';
/* My Original Random Forest Model */
proc hpforest data=yelp.lv_inspection_tree maxtrees=100 vars_to_try=26 trainfraction=0.6;
	input categories neighborhood /level=nominal;
	input is_open /level=binary;
	input stars review_count var: /level=interval;
	target sum_demerits;
	score out=score_restaurants;
	id permit_number business_id;
	ods output FitStatistics=fitstats
		(rename=(Ntrees=Trees));
	ods output VariableImportance=VarImportance;
run;

/* To increase or decrease the number of trees with keeping the number of features constant as 26 features: */
/* To test the model performance change: */
/* With 75 trees: */
proc hpforest data=yelp.lv_inspection_tree maxtrees=75 vars_to_try=26 trainfraction=0.6;
	input categories neighborhood /level=nominal;
	input is_open /level=binary;
	input stars review_count var: /level=interval;
	target sum_demerits;
	score out=score_restaurants;
	id permit_number business_id;
	ods output FitStatistics=fitstats
		(rename=(Ntrees=Trees));
	ods output VariableImportance=VarImportance;
run;

/* With 150 trees: */
proc hpforest data=yelp.lv_inspection_tree maxtrees=150 vars_to_try=26 trainfraction=0.6;
	input categories neighborhood /level=nominal;
	input is_open /level=binary;
	input stars review_count var: /level=interval;
	target sum_demerits;
	score out=score_restaurants;
	id permit_number business_id;
	ods output FitStatistics=fitstats
		(rename=(Ntrees=Trees));
	ods output VariableImportance=VarImportance;
run;


/* To increase or decrease the number of variables with keeping the number of trees constant as 100 trees: */
/* To test the model performance change: */
/* With 16 variables: */
proc hpforest data=yelp.lv_inspection_tree maxtrees=100 vars_to_try=16 trainfraction=0.6;
	input categories neighborhood /level=nominal;
	input is_open /level=binary;
	input stars review_count var: /level=interval;
	target sum_demerits;
	score out=score_restaurants;
	id permit_number business_id;
	ods output FitStatistics=fitstats
		(rename=(Ntrees=Trees));
	ods output VariableImportance=VarImportance;
run;

/* With 50 variables: */
proc hpforest data=yelp.lv_inspection_tree maxtrees=100 vars_to_try=50 trainfraction=0.6;
	input categories neighborhood /level=nominal;
	input is_open /level=binary;
	input stars review_count var: /level=interval;
	target sum_demerits;
	score out=score_restaurants;
	id permit_number business_id;
	ods output FitStatistics=fitstats
		(rename=(Ntrees=Trees));
	ods output VariableImportance=VarImportance;
run;

/* --------------------------------------------------------------------------------- */
/*  */
/* data score_restaurants_rand; set score_restaurants; */
/* 	call streaminit(1905161525); */
/* 	randno=rand('uniform'); */
/* run; */
/*  */
/* data fitstats; */
/*    set fitstats; */
/*    label Trees = 'Number of Trees'; */
/*    label MiscAll = 'Full Data'; */
/*    label Miscoob = 'OOB'; */
/* run; */
/*  */
/* proc sgplot data=fitstats; */
/*    	title "OOB vs Training"; */
/*    	series x=Trees y=PredAll; */
/*    	series x=Trees y=PredOob/ */
/*    		lineattrs=(pattern=shortdash thickness=2); */
/*    	yaxis label='Error'; */
/* run; */
/* title; */
/*  */
/* ods graphics / reset width=6.4in height=4.8in imagemap; */
/*  */
/* proc sgplot data=score_restaurants; */
/* 	reg x=P_sum_demerits y=R_sum_demerits / nomarkers cli alpha=0.01; */
/* 	scatter x=P_sum_demerits y=R_sum_demerits /; */
/* 	xaxis grid; */
/* 	yaxis grid; */
/* run; */

/* ++++++++++++++Sample Line Lists For Inspection++++++++++++++++++++ */
/* proc sql outobs=1; */
/* 	create table rand_sum_demerits as */
/* 		select distinct randno, a.business_id, sum_demerits, P_sum_demerits, R_sum_demerits, is_open */
/* 		from score_restaurants_rand a left join yelp.business b */
/* 			on a.business_id=b.business_id */
/* 		where is_open=1 */
/* 		order by randno, P_sum_demerits desc, sum_demerits desc; */
/* quit; */
/* 		 */
/* title 'Randomly Select - Predicted Demerits - Yelp Tips'; */
/* title2 'Twenty Most Recent Yelp Tips'; */
/* proc sql outobs=20; */
/* 	select b.name, categories, b.is_open, neighborhood, review_count,  */
/* 		stars, date, sum_demerits, P_sum_demerits, R_sum_demerits, text, likes */
/* 	from rand_sum_demerits a  */
/* 		left join yelp.business b */
/* 			on a.business_id=b.business_id */
/* 		left join yelp.tips c */
/* 			on a.business_id=c.business_id */
/* 	order by sum_demerits desc, date desc; */
/* quit; */
/*  */
/* proc sql outobs=1; */
/* 	create table hi_sum_demerits as */
/* 		select distinct a.business_id, sum_demerits, P_sum_demerits, R_sum_demerits, is_open, randno */
/* 		from score_restaurants_rand a left join yelp.business b */
/* 			on a.business_id=b.business_id */
/* 		where is_open=1 */
/* 		order by sum_demerits desc, P_sum_demerits desc; */
/* quit; */
/* 		 */
/* proc sql outobs=1; */
/* 	create table hi_P_sum_demerits as */
/* 		select distinct randno, a.business_id, sum_demerits, P_sum_demerits, R_sum_demerits, is_open */
/* 		from score_restaurants_rand a left join yelp.business b */
/* 			on a.business_id=b.business_id */
/* 		where is_open=1 and (R_sum_demerits < 1 and R_sum_demerits > -1) */
/* 		order by randno, sum_demerits desc; */
/* quit; */
/* 		 */
/* title 'Randomly Selected Near-Perfect Prediction (Residual < 1) - Yelp Tips'; */
/* title2 'Twenty Most Recent Yelp Tips'; */
/* proc sql outobs=20; */
/* 	select b.name, categories, b.is_open, neighborhood, review_count,  */
/* 		stars, date, sum_demerits, P_sum_demerits, R_sum_demerits, text, likes */
/* 	from hi_P_sum_demerits a  */
/* 		left join yelp.business b */
/* 			on a.business_id=b.business_id */
/* 		left join yelp.tips c */
/* 			on a.business_id=c.business_id */
/* 	order by sum_demerits desc, date desc; */
/* quit; */
/*  */
/* title 'Top Demerits - Yelp Tips'; */
/* title2 'Most Recent Yelp Tips'; */
/* proc sql; */
/* 	select b.name, categories, b.is_open, neighborhood, review_count,  */
/* 		stars, date, sum_demerits, P_sum_demerits, R_sum_demerits, text, likes */
/* 	from hi_sum_demerits a  */
/* 		left join yelp.business b */
/* 			on a.business_id=b.business_id */
/* 		left join yelp.tips c */
/* 			on a.business_id=c.business_id */
/* 	order by date desc, P_sum_demerits desc; */
/* quit; */