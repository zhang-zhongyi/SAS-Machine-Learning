/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*Note: UNIX Libname*/
/*libname neiss  '/courses/dc41eb55ba27fe300/neiss';*/
/*	Note: Windows path*/
libname neiss 'c:\sas\lib\neiss\';

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*	UNIX Path*/
/*%let path = /courses/dc41eb55ba27fe300/investigation_example;*/
/*	Note: Windows path*/
%let path = C:\Users\nds616\Box Sync\SAS\sas\class08\;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*	Read in formats and code variables*/
/*	Create analytical data set WORK.INJURIES*/
/*	Add additional years of data here if desired*/
data data_sets;  set neiss.neiss2017 neiss.neiss2016 
	neiss.neiss2015 neiss.neiss2014 neiss.neiss2013; 
run;
/*%include "&path\PHI_001_Formats_180905_1827.sas";*/
%include "&path/PHI_001_Formats_180905_1827.sas";

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*	Pick a default title for tables and graphs*/
/*	Avoid using spaces*/
%let injury_label = Pediatric_Home_Injuries;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*	Define case definition*/
/*	Note use of WHERE clause to subset entire population*/
/*	Remove it not necessary*/
data classifier; set injuries;
/*	Define WHERE clause*/
	where age<18;
/*	Define case definition structured variables*/
	if loc=1 then mydef=1; else mydef=0;
run;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/* 	Generate Baseline files */
/*%include "&path/PHI_040_Baseline_Signals_180905_1827.sas";*/
%include "&path/PHI_040_Baseline_Signals_180905_1827.sas";

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/* 	Choose an underlying outbreak detection rate which matches the objectives of the system. */
/*	This can be cut-and-pasted multiple times for sensistivity analysis*/
/*	Test affect of changing Baseline(N=) and Threshold (STD=)*/
/*	OUTOBS_VAL controls the length of the line list*/
%lag (data=classifier_sum, n=14, var_lag=ratio_to_other, std=3.75); run; quit;
%lag_sum (data=classifier_sum, int=Day, n=14, var_lag=ratio_to_other, std=3.75, title1=&injury_label RTO,outobs_val=25); run; quit;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/* 	Match cases to controls */
/*%include "&path/PHI_020_Matching_180905_1827.sas";*/
%include "&path\PHI_020_Matching_180905_1827.sas";

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*/* 	Prepare narrative for HPSPLIT*/
/*%include "&path/PHI_030_HPSPLIT_Narrative_Var_180905_1827.sas";*/
%include "&path\PHI_030_HPSPLIT_Narrative_Var_180905_1827.sas";

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/* 	Adjust cum_pct to include more words. */
/* 	e.g. words with 0.80 cum_pct account for 20% of the case wt */
/* 	Number variables for HPSPLIT variable range 1-N */
/* 	The HIGHER cumpct value, the longer HPSPLIT will take to run*/
/* 	Less than 0.20 will produce very few terms usually*/
data word_wt_cum; set word_sum;	
	retain j;
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
			if (cumpct < 0.50) then delete;
		end;
	if i=1 then delete;
	j+1;
	var_name=cats('var_',j);
run;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*	Generate the variables for HPSPLIT analysis*/
/*	This can be a long step*/
/*%include "&path/PHI_030_HPSPLIT_Narrative_Factorgen_180905_1827.sas";*/
%include "&path\PHI_030_HPSPLIT_Narrative_Factorgen_180905_1827.sas";

ods graphics on; 

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*	Adjust variable selection depending on variable choices for case definition or scenario */
/*	Note path to output RULES file*/
/*	Uncomment CODE file if you will use it for SAS programming*/
/*	Modify LEAVES statement for more or less terminal nodes*/
/*	Too many terminal nodes will create sparse time series in the next step*/
/*NOTE: SAS default tree takes 20 minutes on 5 years of data*/
proc hpsplit data=injuries_join_words;
	weight wt;
	id NEK;
/*	prune costcomplexity (leaves=10);*/
 	RULES FILE="&path\hpsplit_all_var_rules.txt"; 
	class mydef bdpt diag disp fmv race psu sex week dow month var:;
	model mydef (event='1') = age bdpt diag disp fmv race psu sex week dow month var:;
	output out=HPSPLIT_ALL_VAR;
/* 	code file="&path\hpsplit_all_var_code.sas"; */
run;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
/* 	Further investigate signals with custom PROC GPLOT and Line list */
%include "&path/PHI_051_Investigate_180905_1828.sas";

/*	MACRO can be cut-and-pasted mutiple times for senstivity analysis*/
/*	Test affect of changing Baseline(N=) and Threshold (STD=)*/
%investigate (data=injuries_sum, int=Day, n=14, var_lag=mydef_sum, std=3.3, title1=&injury_label Sum); run; quit;

/*	Customize line list for your scenario and needs*/
/*	Add a CREATE TABLE statement to output the data to a table for export*/
proc sql;
	title 'Line List for Follow-up';
	select mydef label="Injury?", psu label="Hospital ID", wt, diag, P_mydef1,
		dow, a.week, month, 
		a._Node_, a._leaf_, a.trmt_date, 
		bdpt, loc, age, sex, narr1, narr2
	from injuries_nodes a, mm_flag b 
		where a.trmt_date between b.min_date and b.max_date
			and a._node_=b._node_
			and a._leaf_=b._leaf_
	order by a.trmt_date, P_mydef1 desc;
quit;