libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';

proc format
 	cntlin=neiss.neiss_fmt;
run;
/* index(narrative,'FELL') > 0 */
data neiss_code; set neiss.neiss2017 neiss.neiss2016 neiss.neiss2015 neiss.neiss2014 neiss.neiss2013;
	where age > 4 and age < 19;
 	format bdpt bdypt.;
 	format diag diag.;
 	format disp disp.;
 	format fmv fire.;
 	format loc loc.;
 	format prod1 prod2 prod.;
 	format race race.;
 	format sex gender.;
 	
/* 	New date format */
	format new_date mmddyy10.;
	
	year_var=year(trmt_date);
	month_var=month(trmt_date);
	day_var=day(trmt_date);
	week_var=week(trmt_date);
	new_date=mdy(month_var,1,year_var);
	
	randno=rand('uniform');
run;

title 'Falling Caused Fracture';
title2 'Falling Caused Fracture';
proc freq data=neiss_code order=freq;
	where diag= 57 and narr1 like '%FELL%' and age < 10;
	table bdpt diag disp fmv loc race sex;
run;
title;

/* proc sql; */
/* 	create table classifier_baseball as	 */
/* 		select bdpt diag disp fmv loc race sex */
/* 		from neiss_code */
/* 		where prod1 = 5041 */
/* 		group by sex; */
/* quit; */

title 'Top Products for My Case Definition';
proc sql outobs=20;
	select prod1, sum(wt) as sum_wt label='Estimated Cases' format comma20.,
		count(*) as freq label='Frequency' format comma20.
	from neiss_code
	group by prod1
	order by sum_wt desc;
quit;
title;

proc sql outobs=1;
	select prod1, sum(wt) as sum_wt label='Estimated Cases' format comma20.,
		count(*) as freq label='Frequency' format comma20.
	from neiss_code
	where Prod1 = 5041
	order by sum_wt desc;
quit;
title;



data classifier; set neiss_code;
	if diag=57 and (index(narr1,'FELL') > 0 or index(narr2,'FELL') > 0) then mydef=1;
		else mydef=0;
run;

title 'Annual Frequency';
proc freq data=classifier;
	tables mydef*year_var /norow nocum;
run;
title;

title 'Monthly Injuries - Last 24 Months';
proc sql outobs=24;	
		select new_date label='Month',
			count(*) as freq label='Frequency' format comma20., 
			sum(wt) as tot_wt 
				format comma20. label 'Total Estimated Injuries',
			sum(case when mydef=1 then wt else 0 end) as case_wt 
				format comma20. label 'Estimated Cases',
			sum(case when mydef=0 then wt else 0 end) as noncase_wt 
				format comma20. label 'Estimated Non-Cases',
			sum(case when mydef=1 then wt else 0 end)/
				sum(case when mydef=0 then wt else 0 end) as ratio_to_other 
				format 8.4 label 'Ratio to Other'
		from classifier
		group by new_date
		order by new_date desc;
quit;
title;

proc sql;
	create table classifier_daily as	
		select trmt_date,
			count(*) as freq format comma20., 
			sum(wt) as tot_wt format comma20.,
			sum(case when mydef=1 then wt else 0 end) as case_wt format comma20.,
			sum(case when mydef=0 then wt else 0 end) as noncase_wt format comma20.,
			sum(case when mydef=1 then wt else 0 end)/
				sum(case when mydef=0 then wt else 0 end) as ratio_to_other 
				format 8.4
		from classifier
		group by trmt_date
		order by trmt_date;
quit;

title "Injuries: Ratio to Other";
title2 "with Linear Regression + 99% CI";
proc gplot data=classifier_daily;
	format ratio_to_other 20.4;
	label ratio_to_other="Ratio-to-Other";
	plot (ratio_to_other ratio_to_other)*trmt_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1 regeqn;
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue		h=1 i=rlclm99	w=1;
run;
quit;
title;

title "Injuries: Ratio to Other";
title2 " with Linear Regression + 99% CI";
proc gplot data=classifier_daily;
	where year(trmt_date)=2017; 
	format ratio_to_other 20.4;
	label ratio_to_other="Ratio-to-Other";
	plot (ratio_to_other ratio_to_other)*trmt_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1 regeqn;
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue		h=1 i=rlclm99	w=1;
run;
quit;
title;

/*Create a 7-day lag*/
/*Calculate the 7-day mean*/
/* Use WHERE statement to adjust for ramp-up period */
/* moving to ratio change */
/* start from 2013/1/9, so the previous ratio is meaningless. We cannot see much things before that date(less than 10 days). */
data classifier_rto_lag; set classifier_daily;
	where trmt_date > mdy(1,9,2013);
	format avg_cases_7day 8.4;
	avg_cases_7day=mean(ratio_to_other, lag1(ratio_to_other), 
		lag2(ratio_to_other), lag3(ratio_to_other), 
		lag4(ratio_to_other), lag5(ratio_to_other), 
		lag6(ratio_to_other));
run;

/*Plot the RTO, 7-day moving average*/
proc gplot data=classifier_rto_lag;
	format avg_cases_7day ratio_to_other comma20.4;
	label avg_cases_7day="7-day Average";
	plot (ratio_to_other avg_cases_7day)*trmt_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1;
	title "Injuries: 7-day Moving Average (Ratio to Other)";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue		h=1 i=join	w=1;
run;
quit;

/*Create a 7-day lagged SD*/
/*Calculate the 7-day mean and standard deviation*/
/*Perform a simple calculation to test if observed RTO exceeds 2 standard deviations*/
/*If exceeded, write the RTO value to a variable called flag95*/
data classifier_rto_flag; set classifier_rto_lag;
	std_cases_7day=std(ratio_to_other, lag1(ratio_to_other), lag2(ratio_to_other), lag3(ratio_to_other), lag4(ratio_to_other),
		lag5(ratio_to_other), lag6(ratio_to_other));
	ci95_cases=2*std_cases_7day;
	upper95=sum(avg_cases_7day, ci95_cases);
	if ratio_to_other > upper95 then flag95=ratio_to_other;
run;

title "Injuries: 7-day Moving Average (Ratio to Other)";
/*Plot the RTO, 7-day moving average, and flags (if any)*/
proc gplot data=classifier_rto_flag;
	format avg_cases_7day ratio_to_other comma20.4;
	label avg_cases_7day="7-day Average";
	plot (ratio_to_other avg_cases_7day flag95)*trmt_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1;
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue		h=1 i=join	w=1;
	symbol3 v=star	c=red		h=2 i=none	w=2;
run;
quit;
title;

/*Focus on 2015 with a WHERE Statement*/
title "Single-year Injuries: 7-day Moving Average (Ratio to Other)";
proc gplot data=classifier_rto_flag;
	where year(trmt_date)=2015;
	format avg_cases_7day ratio_to_other comma20.4;
	label avg_cases_7day="7-day Average";
	plot (ratio_to_other avg_cases_7day flag95)*trmt_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1;
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue		h=1 i=join	w=1;
	symbol3 v=star	c=red		h=2 i=none	w=2;
run;
quit;
title;

/*Focus on 2017 with a WHERE Statement*/
showing the biggest signal. There should definitely be a signal in the middle.
	proc sql outobs=1;
		create table max_flag as
		select trmt_date, max(flag95) as max_flag
		from classifier_rto_flag
		where year(trmt_date)=2015
		group by trmt_date
		order by max_flag desc;
		
	proc sql noprint; select intnx('day',trmt_date,-42) into :plot_start from max_flag; quit;
	proc sql noprint; select intnx('day',trmt_date, 48) into :plot_end from max_flag; quit;
	
	proc sql;
		create table max_flag_dates as	
			select * from classifier_rto_flag where trmt_date between &plot_start and &plot_end;

title "Largest Significant Increase: 7-day Moving Average";	
	proc gplot data=max_flag_dates;
		label avg_cases_7day="Moving Average (7-day)";
		plot (ratio_to_other avg_cases_7day flag95)*trmt_date / 
			overlay hminor=0 caxis=black ctext=black legend=legend1 vaxis=axis1;
		legend1 label=(position=(top left) j=l);
		symbol1 v=none	c=lightblue		h=1 i=join	w=1;
		symbol2 v=none	c=darkblue		h=1 i=join	w=1;
		symbol3 v=star	c=red			h=2 i=none	w=2;
		axis1 label=(a=90);
	run;
	quit;
title;

/* creating a random selection of 25 cases (people) in the max signal */
title 'Line-listing: 25 Sample Cases';
	proc sql outobs=25; 
		select bdpt, loc, diag, NEK, b.trmt_date label='Treatment Date', age label='Age', 
			sex label='Sex', race label='Race', disp label='Disposition',  
			prod1 label='Product', narr1, narr2, randno label='Random Number'
		from max_flag a join classifier b
			on a.trmt_date=b.trmt_date
		where mydef=1
		order by randno;
quit;
title;







