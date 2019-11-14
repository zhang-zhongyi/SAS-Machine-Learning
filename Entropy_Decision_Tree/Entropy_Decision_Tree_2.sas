/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Uncomment or edit the appropriate path for your libname */
/* Note: SAS On-Demand libname*/
libname neiss  '/courses/dc41eb55ba27fe300/lib/neiss';

/* Note: Windows path*/
/* libname neiss 'c:\sas\lib\neiss\'; */
/* libname entropy 'C:\SAS\lib\temp\entropy'; */
/* ++++++++++++++++++++++++++++++++++++++++++++++++ */

/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
/*	Add additional years of data here if desired*/
/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
data data_sets;  set neiss.neiss2017; 
run;

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

/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Note: Processing of age variable to account for  */
/* children less than 2 years-old. */
/* ++++++++++++++++++++++++++++++++++++++++++++++++ */

data injuries;  set data_sets;
	length clean_trim_prod1 clean_trim_prod2 $40;
	format age 8.2;
 	format sex gender.;
 	format bdpt bdypt.;
 	format diag diag.;
 	format disp disp.;
 	format fmv fire.;
 	format loc loc.;
 	format race race.;
 	format prod1 prod2 prod.;
	format dow dowf.;
	narrative=cat(narr1,narr2);
	clean_trim_prod1 = left(trim(put(prod1, prod.)));
	clean_trim_prod2 = left(trim(put(prod2, prod.)));
	dow=weekday(trmt_date);
	week=week(trmt_date);
	month=month(trmt_date);
	if age ge 201 AND age le 223 then age=(age-200)/12;
 		else age=age;
run;

/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
/*	Define case definition*/
/*	Note use of WHERE clause to subset entire population*/
/*	Remove it if not necessary*/
/* ++++++++++++++++++++++++++++++++++++++++++++++++ */
data classifier; set injuries;
/*	Define WHERE clause*/
	where prod1=1211 and (age > 4 and age < 19);
/*	Define case definition structured variables*/
	if bdpt=75 then mydef=1; else mydef=0;
	call streaminit(0005);
	randno=rand('uniform');
run;

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Clean words for HPSPLIT analysis */
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
data injuries_words_coded; set classifier;
	clean_sen=compress(narrative, ':-,?@#.');
	num_words=countw(clean_sen);
	do i = 1 to num_words;
		word = scan(clean_sen, i);
		word_wt=wt/num_words;
		output;
	end;
run;

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Select and join words for both mydef=1 and mydef=0 */
/* Calculate their weight by summing total weight for the case and  */
/* dividing by total number of words */
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
proc sql noprint;
	select sum(case when mydef=1 then word_wt else 0 end) into :mydef1_word_wt from injuries_words_coded;
	select sum(case when mydef=0 then word_wt else 0 end) into :mydef0_word_wt from injuries_words_coded;

	create table word_sum as	
		select mydef, 
			word, 
			count(*) as freq, 
			sum(word_wt) as sum_word_wt,
			sum(word_wt)/&mydef1_word_wt as word_wt_pct
		from injuries_words_coded
		where mydef=1
		group by mydef, word
		union
		select mydef, 
			word, 
			count(*) as freq, 
			sum(word_wt) as sum_word_wt,
			sum(word_wt)/&mydef0_word_wt as word_wt_pct
		from injuries_words_coded
		where mydef=0
		group by mydef, word
		order by mydef, word_wt_pct;
quit;

/*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/* Adjust cum_pct to include more words. */
/* e.g. words with 0.20 cum_pct account for 80% of the case wt */
/* Number variables for HPSPLIT variable range 1-N */
/* The HIGHER cumpct value, the longer HPSPLIT will take to run */
/* More than 0.80 will produce very few terms usually */
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */

data word_wt_cum; set word_sum;	
	by mydef word_wt_pct;
	retain cumwt cumpct;
	if first.mydef then do; 
		i=1;
		cumwt=sum_word_wt;
		cumpct=word_wt_pct; 
	end;
		else do;
			i+1;
			cumwt+sum_word_wt;
			cumpct+word_wt_pct;
			if (cumpct < 0.16) then delete;
		end;
	if i=1 then delete;
run;

proc sql;
	create table word_wt_distinct as
		select distinct word
		from word_wt_cum;
quit;

data word_wt_var; set word_wt_distinct;
	j+1;
	var_name=cats('var_',j);
run;

/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
/* Macro to create binary variables for all the words  */
/* DO NOT MODIFY UNLESS YOU UNDERSTAND MACRO PROGRAMMING */
/* Simply checks if the word is present (1) or not (0) for a case_num */
/* A MAX operation collects all the 1's for a case_num since 1 is higher than 0*/
/* The word variables are joined back to the matched set for mydef outcome */
/* Another steps can be to sum the total of all words instead of binary  */
/* HPSPLIT is run over a range of variable var_1-var_N */
/* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ */
%macro factorgen;

proc sql noprint;
	select distinct word, var_name into :word1 - :word999, :var1 - :var999
	from word_wt_var;
quit;

data output1; set injuries_words_coded;
	%do i=1 %to &sqlobs;
		label &&var&i="&&word&i";
		if word="&&word&i" then &&var&i=1; else &&var&i=0;
	%end;

%let N_1=%eval(&sqlobs - 1);
%let N=%eval(&sqlobs);

%put &sqlobs;

proc sql;
	create table output2 as 
		select distinct NEK, wt,
			%do i=1 %to &N_1;
				max(&&var&i) as &&var&i label "&&word&i",
			%end;
				max(&&var&N) as &&var&N label "&&word&i"
		from output1
		group by NEK, wt;

quit;	

%mend factorgen;

%factorgen; run;
proc sql;
	create table tree as	
		select a.mydef, b.*, c.*
		from classifier a 
			left join output2 b 
				on a.NEK=b.NEK
			left join classifier c
				on a.NEK=c.NEK;
quit;