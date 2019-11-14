/* Open the library for the data set */
/* libname dsc 'c:/sas/lib/isl'; */
libname dsc  '/courses/dc41eb55ba27fe300/lib/isl';

/* Understand the contents of the data set */
proc contents data=dsc.boston;
run;

/* Run simple model */
proc reg data=DSC.BOSTON alpha=0.05 plots(only)=(diagnostics residuals fitplot 
		observedbypredicted);
	model medv=lstat /;
	run;
quit;

/* Add Confidence Limits */
proc reg data=DSC.BOSTON alpha=0.05 plots(only)=(diagnostics residuals fitplot 
		observedbypredicted);
	model medv=lstat / clb;
	run;
quit;

/* Add confidence intervals and prediction intervals */
/* For instance, the 95% confidence interval associated with a lstat value of */
/* 10 is (24.47, 25.63), and the 95% prediction interval is (12.828, 37.28). As */
/* expected, the confidence and prediction intervals are centered around the */
/* same point (a predicted value of 25.05 for medv when lstat equals 10), but */
/* the latter are substantially wider. */

proc reg data=DSC.BOSTON alpha=0.05 plots(only)=(diagnostics residuals fitplot 
		observedbypredicted);
	model medv=lstat / clb;
	output out=work.Reg_stats p=p_ lcl=lcl_ ucl=ucl_;
	run;
quit;

/* Add Leverage */
/* Largest Leverage value =0.0268651665	 */
proc reg data=DSC.BOSTON alpha=0.05 plots(only)=(diagnostics residuals fitplot 
		observedbypredicted);
	model medv=lstat / clb;
	output out=work.Reg_stats h=h_ p=p_ lcl=lcl_ ucl=ucl_;
	run;
quit;

/* Add residuals and studentized residuals */
proc reg data=DSC.BOSTON alpha=0.05 plots(only)=(diagnostics residuals 
		rstudentbypredicted fitplot observedbypredicted);
	model medv=lstat / clb;
	output out=work.Reg_stats h=h_ p=p_ lcl=lcl_ ucl=ucl_ r=r_ student=student_;
	run;
quit;