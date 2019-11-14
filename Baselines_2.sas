libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';

ods output;

/* Read in NEISS formats */
proc format
 	cntlin=neiss.neiss_fmt;
run;

/* Apply NEISS formats */
/* Use CAT function to create narrative variable */
data character_formatted; set neiss.neiss2016;
 	format bdpt bdypt.;
 	format diag diag.;
 	format disp disp.;
 	format fmv fire.;
 	format loc loc.;
 	format prod1 prod2 prod.;
 	format race race.;
 	format sex gender.;
run;

title;
/* PROC FREQ becomes more informative with formatted variables */
proc freq data=character_formatted order=freq;
	where bdpt=75 and loc=9;
	table bdpt diag disp fmv loc prod1 race sex;
run;

/*Read in 5 years of data*/
/* Code an injury */
data classifier; set neiss.neiss2017 neiss.neiss2016 neiss.neiss2015 neiss.neiss2014 neiss.neiss2013;
 	narrative=cat(narr1,narr2);
	year=year(trmt_date);
	if bdpt=75 and loc=9 then mydef=1;
		else mydef=0;
run;

/*Verify the annual volume of the injury*/
/*At least 3650 will give a reasonable baseline*/
proc freq data=classifier;
	tables mydef*year /norow nocum;
run;

/*Calculate the daily frequency, national estimate, and ratio to other of national estimate*/
proc sql;
	create table classifier_daily as	
		select trmt_date,
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
		group by trmt_date
		order by trmt_date;
quit;

/*Create a 7-day lag*/
/*Calculate the 7-day mean and standard deviation*/
/*Perform a simple calculation to test if observed RTO exceeds 2 standard deviations*/
/*If exceeded, write the RTO value to a variable called flag95*/
data classifier_rto_lag; set classifier_daily;
	avg_cases_7day=mean(ratio_to_other, lag1(ratio_to_other), lag2(ratio_to_other), lag3(ratio_to_other), lag4(ratio_to_other),
		lag5(ratio_to_other), lag6(ratio_to_other));
	std_cases_7day=std(ratio_to_other, lag1(ratio_to_other), lag2(ratio_to_other), lag3(ratio_to_other), lag4(ratio_to_other),
		lag5(ratio_to_other), lag6(ratio_to_other));
	ci95_cases=2*std_cases_7day;
	upper95=sum(avg_cases_7day, ci95_cases);
	if ratio_to_other > upper95 then flag95=ratio_to_other;
run;

/*Plot the RTO, 7-day moving average, and flags (if any)*/
proc gplot data=classifier_rto_lag;
	format avg_cases_7day ratio_to_other comma20.4;
	label avg_cases_7day="7-day Average";
	plot (ratio_to_other avg_cases_7day flag95)*trmt_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1;
	title "Injuries: 7-day Moving Average (Ratio to Other)";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue		h=1 i=join	w=2;
	symbol3 v=star	c=red		h=2 i=none	w=2;
run;

/*Focus on 2017 with a WHERE Statement*/
proc gplot data=classifier_rto_lag;
	where year(trmt_date)=2017;
	format avg_cases_7day ratio_to_other comma20.4;
	label avg_cases_7day="7-day Average";
	plot (ratio_to_other avg_cases_7day flag95)*trmt_date / 
		overlay hminor=0 caxis=black ctext=black legend=legend1;
	title "Injuries: 7-day Moving Average (Ratio to Other)";
	legend1 label=(position=(top left) j=l);
	symbol1 v=none	c=lightblue	h=1 i=join	w=1;
	symbol2 v=none	c=darkblue		h=1 i=join	w=2;
	symbol3 v=star	c=red		h=2 i=none	w=2;
run;

/*Focus on 2017 with a WHERE Statement*/
	proc sql outobs=1;
		create table max_flag as
		select trmt_date, max(flag95) as max_flag
		from classifier_rto_lag
		where year(trmt_date)=2017
		group by trmt_date
		order by flag95 desc;
		
	proc sql noprint; select intnx('day',trmt_date,-45) into :plot_start from max_flag; quit;
	proc sql noprint; select intnx('day',trmt_date, 45) into :plot_end from max_flag; quit;
	
	proc sql;
		create table max_flag_dates as	
			select * from classifier_rto_lag where trmt_date between &plot_start and &plot_end;
	
	proc gplot data=max_flag_dates;
		label avg_cases_7day="Moving Average (7-day)";
		plot (ratio_to_other avg_cases_7day flag95)*trmt_date / 
			overlay hminor=0 caxis=black ctext=black legend=legend1 vaxis=axis1;
		title "Largest Significant Increase: 7-day Moving Average";
		title2 "Title";
		legend1 label=(position=(top left) j=l);
		symbol1 v=none	c=lightblue		h=1 i=join	w=1;
		symbol2 v=none	c=darkblue		h=1 i=join	w=2;
		symbol3 v=star	c=red			h=2 i=none	w=2;
		axis1 label=(a=90);
	run;

	proc sql; 
		select diag, bdpt, NEK, b.trmt_date, age, sex, race, disp,  
			prod1, narr1, narr2
		from max_flag a join classifier b
			on a.trmt_date=b.trmt_date
		where mydef=1
		order by prod1;