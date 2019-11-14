/* Comments and Video Forthcoming */
libname yelp  '/courses/dc41eb55ba27fe300/lib/yelp';

title 'Listing of Variable Names with Output set to WORK';
proc contents data=yelp.lv_inspection_tree out=contents_lv_inspection_tree; run;

title 'Analysis of Yelp Tip Terms + Structured Variables Predictive of Restaurant Violations';
title2 'Edit path and uncomment RULES statement to output a rules file';
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

title 'Random Forest Model';
title2 'Note output of Fit Statistics (fitstats) Variable Importance (VarImportance)';
title3 'and Score (score_restaurants)';
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

data score_restaurants_rand; set score_restaurants;
	call streaminit(1905161525);
	randno=rand('uniform');
run;

data fitstats;
   set fitstats;
   label Trees = 'Number of Trees';
   label MiscAll = 'Full Data';
   label Miscoob = 'OOB';
run;

proc sgplot data=fitstats;
   	title "OOB vs Training";
   	series x=Trees y=PredAll;
   	series x=Trees y=PredOob/
   		lineattrs=(pattern=shortdash thickness=2);
   	yaxis label='Error';
run;
title;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=score_restaurants;
	reg x=P_sum_demerits y=R_sum_demerits / nomarkers cli alpha=0.01;
	scatter x=P_sum_demerits y=R_sum_demerits /;
	xaxis grid;
	yaxis grid;
run;

/* ++++++++++++++Sample Line Lists For Inspection++++++++++++++++++++ */
proc sql outobs=1;
	create table rand_sum_demerits as
		select distinct randno, a.business_id, sum_demerits, P_sum_demerits, R_sum_demerits, is_open
		from score_restaurants_rand a left join yelp.business b
			on a.business_id=b.business_id
		where is_open=1
		order by randno, P_sum_demerits desc, sum_demerits desc;
quit;
		
title 'Randomly Select - Predicted Demerits - Yelp Tips';
title2 'Twenty Most Recent Yelp Tips';
proc sql outobs=20;
	select b.name, categories, b.is_open, neighborhood, review_count, 
		stars, date, sum_demerits, P_sum_demerits, R_sum_demerits, text, likes
	from rand_sum_demerits a 
		left join yelp.business b
			on a.business_id=b.business_id
		left join yelp.tips c
			on a.business_id=c.business_id
	order by sum_demerits desc, date desc;
quit;

proc sql outobs=1;
	create table hi_sum_demerits as
		select distinct a.business_id, sum_demerits, P_sum_demerits, R_sum_demerits, is_open, randno
		from score_restaurants_rand a left join yelp.business b
			on a.business_id=b.business_id
		where is_open=1
		order by sum_demerits desc, P_sum_demerits desc;
quit;
		
proc sql outobs=1;
	create table hi_P_sum_demerits as
		select distinct randno, a.business_id, sum_demerits, P_sum_demerits, R_sum_demerits, is_open
		from score_restaurants_rand a left join yelp.business b
			on a.business_id=b.business_id
		where is_open=1 and (R_sum_demerits < 1 and R_sum_demerits > -1)
		order by randno, sum_demerits desc;
quit;
		
title 'Randomly Selected Near-Perfect Prediction (Residual < 1) - Yelp Tips';
title2 'Twenty Most Recent Yelp Tips';
proc sql outobs=20;
	select b.name, categories, b.is_open, neighborhood, review_count, 
		stars, date, sum_demerits, P_sum_demerits, R_sum_demerits, text, likes
	from hi_P_sum_demerits a 
		left join yelp.business b
			on a.business_id=b.business_id
		left join yelp.tips c
			on a.business_id=c.business_id
	order by sum_demerits desc, date desc;
quit;

title 'Top Demerits - Yelp Tips';
title2 'Most Recent Yelp Tips';
proc sql;
	select b.name, categories, b.is_open, neighborhood, review_count, 
		stars, date, sum_demerits, P_sum_demerits, R_sum_demerits, text, likes
	from hi_sum_demerits a 
		left join yelp.business b
			on a.business_id=b.business_id
		left join yelp.tips c
			on a.business_id=c.business_id
	order by date desc, P_sum_demerits desc;
quit;