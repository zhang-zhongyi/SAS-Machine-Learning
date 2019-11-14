/* libname neiss 'c:/sas/lib/neiss'; */
libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';

ods graphics on;


data classifier; set neiss.neiss2016 neiss.neiss2015 neiss.neiss2014;
	if diag=52 and (prod1=1211 OR prod2=1211) then mydef=1;
		else mydef=0;
	where trmt_date between mdy(1,1,2014) and mdy(12,31,2016); 
run;

proc sql;
	create table classifier_daily as	
		select trmt_date,
			min(trmt_date) as min_date format mmddyy10. label="Week Start Date",
			max(trmt_date) as max_date format mmddyy10. label="Week End Date",
			year(trmt_date) as year,
			week(trmt_date) as week,
			count(*) as freq format comma20., 
			sum(wt) as tot_wt 
				format comma20. label 'Estimated Number of Cases',
			sum(case when mydef=1 then wt end) as case_wt 
				format comma20. label 'Case wt',
			sum(case when mydef=0 then wt end) as noncase_wt 
				format comma20. label 'Non-Case wt',
			sum(case when mydef=1 then wt end)/
				sum(case when mydef=0 then wt end) as ratio_to_other 
				format 8.4 label 'Ratio to Other'
		from classifier
		group by trmt_date, year, week
		order by trmt_date, year, week;
quit;

data classifier_lag; set classifier_daily;
	avg_cases_7day=mean(case_wt, lag1(case_wt), lag2(case_wt), lag3(case_wt), lag4(case_wt),
		lag5(case_wt), lag6(case_wt));
run;

proc gplot data=classifier_lag;
	format avg_cases_7day case_wt comma20.;
	label avg_cases_7day="7-day Average";
	label case_wt="National Estimate";
	plot (case_wt avg_cases_7day )*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1;
	title "Injuries: 7-day Moving Average (wt)";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue		h=1 i=join	w=1;
	symbol2 v=none	c=darkblue		h=1 i=join	w=2;
	
proc gplot data=classifier_lag;
	format avg_cases_7day case_wt comma20.;
	label avg_cases_7day="7-day Average";
	label case_wt="National Estimate";
	plot (case_wt avg_cases_7day case_wt)*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1 regeqn;
	title "Injuries: 7-day Moving Average (wt)";
	title2 "With 95% Increases Flagged - 2x SD Method";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue	h=1 i=join	w=2;
/* 	symbol3 v=star	c=red		h=2 i=none	w=2; */
/* 	symbol3 v=none	c=darkred	h=1 i=none	w=3; */

	
proc gplot data=classifier_lag;
	format avg_cases_7day case_wt comma20.;
	label avg_cases_7day="7-day Average";
	plot (case_wt avg_cases_7day case_wt)*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1 regeqn;
	title "Injuries: 7-day Moving Average (wt)";
	title2 "With 95% Increases Flagged - Regression Method";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue	h=1 i=join	w=2;
	symbol3 v=none	c=darkred	h=1 i= RL0CLI95	w=3;
	
proc gplot data=classifier_lag;
	format avg_cases_7day case_wt comma20.;
	label avg_cases_7day="7-day Average";
	label case_wt="National Estimate";
	plot (case_wt avg_cases_7day case_wt)*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1 regeqn;
	title "Injuries: 7-day Moving Average (wt)";
	title2 "With 95% Increases Flagged - Both Methods";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join		w=1;
	symbol2 v=none	c=darkblue	h=1 i=join		w=2;
/* 	symbol3 v=star	c=red		h=2 i=none	 	w=2; */
	symbol3 v=none	c=darkred	h=1 i=RL0CLI95	w=3;
	
proc sql;
	create table classifier_weekly as	
		select
			min(trmt_date) as min_date format mmddyy10. label="Week Start Date",
			max(trmt_date) as max_date format mmddyy10. label="Week End Date",
			year(trmt_date) as year,
			week(trmt_date) as week,
			sum(wt) as tot_wt 
				format comma20. label 'Estimated Number of Cases',
			sum(case when mydef=1 then wt end) as case_wt 
				format comma20. label 'Case wt',
			sum(case when mydef=0 then wt end) as noncase_wt 
				format comma20. label 'Non-Case wt',
			sum(case when mydef=1 then wt end)/
				sum(case when mydef=0 then wt end) as ratio_to_other 
				format 8.4 label 'Ratio to Other'
		from classifier
		group by year, week
		order by year, week;
quit;

data classifier_w_lag; set classifier_weekly;
	avg_cases_7day=mean(case_wt, lag1(case_wt), lag2(case_wt), lag3(case_wt), lag4(case_wt),
		lag5(case_wt), lag6(case_wt));
	std_cases_7day=std(case_wt, lag1(case_wt), lag2(case_wt), lag3(case_wt), lag4(case_wt),
		lag5(case_wt), lag6(case_wt));
	ci95_cases=2*std_cases_7day;
	upper95=sum(avg_cases_7day, ci95_cases);
	if case_wt > upper95 then flag95=case_wt;
run;

proc gplot data=classifier_w_lag;
	format avg_cases_7day case_wt comma20.;
	label avg_cases_7day="7-week Average";
	plot (avg_cases_7day case_wt)*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1;
	title "Injuries: 7-week Moving Average (wt)";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=darkblue		h=1 i=join	w=2;
	symbol2 v=none	c=blue	h=1 i=join	w=1;
	
proc gplot data=classifier_w_lag;
	format avg_cases_7day case_wt comma20.;
	label avg_cases_7day="7-week Average";
	plot (case_wt avg_cases_7day flag95 case_wt)*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1 regeqn;
	title "Injuries: 7-week Moving Average (wt)";
	title2 "With 95% Increases Flagged - 2x SD Method";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=blue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue	h=1 i=join	w=2;
	symbol3 v=star	c=red		h=2 i=none	w=2;
	symbol4 v=none	c=darkred	h=1 i= none	w=3;

proc gplot data=classifier_w_lag;
	format avg_cases_7day case_wt comma20.;
	label avg_cases_7day="7-week Average";
	plot (case_wt avg_cases_7day case_wt)*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1 regeqn;
	title "Injuries: 7-week Moving Average (wt)";
	title2 "With 95% Increases Flagged - Regression Method";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=blue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue	h=1 i=join	w=2;
	symbol3 v=none	c=darkred	h=1 i= RL0CLI95	w=3;
	
proc gplot data=classifier_w_lag;
	format avg_cases_7day case_wt comma20.;
	label avg_cases_7day="7-week Average";
	plot (case_wt avg_cases_7day flag95 case_wt)*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1 regeqn;
	title "Injuries: 7-week Moving Average (wt)";
	title2 "With 95% Increases Flagged - Both Methods";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=blue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue	h=1 i=join	w=2;
	symbol3 v=star	c=red		h=2 i=none	w=2;
	symbol4 v=none	c=darkred	h=1 i= RL0CLI95	w=3;

data classifier_rto_lag; set classifier_daily;
	avg_cases_7day=mean(ratio_to_other, lag1(ratio_to_other), lag2(ratio_to_other), lag3(ratio_to_other), lag4(ratio_to_other),
		lag5(ratio_to_other), lag6(ratio_to_other));
	std_cases_7day=std(ratio_to_other, lag1(ratio_to_other), lag2(ratio_to_other), lag3(ratio_to_other), lag4(ratio_to_other),
		lag5(ratio_to_other), lag6(ratio_to_other));
	ci95_cases=2*std_cases_7day;
	upper95=sum(avg_cases_7day, ci95_cases);
	if ratio_to_other > upper95 then flag95=ratio_to_other;
run;

proc gplot data=classifier_rto_lag;
	format avg_cases_7day ratio_to_other comma20.4;
	label avg_cases_7day="7-day Average";
	plot (avg_cases_7day ratio_to_other)*min_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1;
	title "Injuries: 7-day Moving Average (Ratio to Other)";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=darkblue		h=1 i=join	w=2;
	symbol2 v=none	c=blue	h=1 i=join	w=1;
