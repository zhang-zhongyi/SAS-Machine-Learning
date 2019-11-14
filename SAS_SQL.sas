libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';

data x;
    today = date();
    format today mmddyy10.;
run;

proc freq data=neiss.neiss2017 order=freq;
	tables diag bdpt;
run;

data x2; set neiss.neiss2017 neiss.neiss2016;
	if bdpt = 30 then mydef = 1;
		else mydef = 0;
	format new_date1 mmddyy10.;
	format new_date2 mmddyy10.;
	format new_date3 mmddyy10.;
	week=week(trmt_date);
	month =month (trmt_date);
    year = year(trmt_date);
	day = day(trmt_date);
	new_date1 = mdy(11,6,2019);
	new_date2 = mdy(month,day,year);
	new_date3 = mdy(month,1,year);
run;

proc sql;
	create table neiss2 as
	select distinct trmt_date
	from neiss.neiss2017;
quit;

proc sql;
	create table neiss3 as
	select NEK, Age, Sex, Race, bdpt, diag
	from neiss.neiss2017
	where narr1 like '%KNEE%';
quit;

proc sql;
	create table neiss_daily as
		select trmt_date, count(*) as freq
		from neiss.neiss2017
		group by trmt_date;
quit;

proc sql;
	create table play as
		select NEK, Age, Sex, Race, bdpt, diag
		from
		(select NEK, Age, Sex, Race, bdpt, diag, 
		row_number() over (partition by Age order by NEK) as rownum 
		  from neiss.neiss2017
	      where narr1 like '%KNEE%')  as t1
        where rownum = 1;
quit;

proc sql;
	create table neiss_monthly as
		select month, count(*) as monthly_freq
		from x2
		group by month;
quit;

proc sql;
	create table neiss_monthly as
		select year, month, count(*) as freq,
		from x2
		group by year, month;
quit;


proc sql;
	create table neiss_monthly2 as
		select year, month, count(*) as freq format comma20.,
			min(trmt_date) as min_date format mmddyy10.,
			max(trmt_date) as max_date format mmddyy10.
		from x2
		group by year, month;
quit;


proc sql;
	create table cases as
		select year, month, 					
		    sum(mydef) as num_cases format comma20.,
			count(*) as freq format comma20.,
			min(trmt_date) as min_date format mmddyy10.,
			max(trmt_date) as max_date format mmddyy10.
		from x2
		group by year, month;
quit;

title 'Frequency of BDPT=30 Injuries';
proc sql;
/* 	create table cases2 as */
		select year label='Year', month label='Month', 					
		    sum(mydef) as num_cases format comma20. label = 'Number of Cases',
		    sum(mydef)/count(*) as pct_cases format percent8.2 label='Percent Cases',
			count(*) as freq format comma20. label = 'Frequency',
			min(trmt_date) as min_date format mmddyy10. label='Minimum Date',
			max(trmt_date) as max_date format mmddyy10. label = 'Maximum Date'
		from x2
		group by year, month
		order by year desc, month desc;
quit;
title;

title 'Frequency of BDPT=30 Injuries2';
proc sql;
/* 	create table cases2 as */
		select year label='Year', month label='Month', 
			sum(case when mydef=1 then 1 end) as case_freq 
				format comma20. label 'Case Frequency',
			sum(case when mydef=0 then 1 end) as other_freq 
				format comma20. label 'Other Frequency',
			sum(case when mydef=1 then 1 end)/sum(case when mydef=0 then 1 end)
			as rto label='Ratio to Other' format 8.4,
		    sum(mydef) as num_cases format comma20. label = 'Number of Cases',
		    sum(mydef)/count(*) as pct_cases format percent8.2 label='Percent Cases',
			count(*) as freq format comma20. label = 'Frequency',
			min(trmt_date) as min_date format mmddyy10. label='Minimum Date',
			max(trmt_date) as max_date format mmddyy10. label = 'Maximum Date'
		from x2
		group by year, month
		order by year desc, month desc;
quit;
title;

