/* Open the library for the data set */
libname dsc 'c:/sas/lib/isl';
/* libname dsc  '/courses/dc41eb55ba27fe300/lib/isl'; */

/* Multiple Linear Regression */
ods noproctitle;
ods graphics / imagemap=on;

proc reg data=DSC.BOSTON alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	model medv=age lstat /;
	run;
quit;

/* Add all the variables */
proc reg data=DSC.BOSTON alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	model medv=age lstat crim zn indus chas nox rm dis rad tax ptratio black /;
	run;
quit;

/* Add collinearity analysis */

proc reg data=DSC.BOSTON alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	model medv=age lstat crim zn indus chas nox rm dis rad tax ptratio black / 
		collin vif;
	run;
quit;

/* Add interaction term */
proc glmselect data=DSC.BOSTON outdesign(addinputvars)=Work.reg_design;
	model medv=age lstat age*lstat / showpvalues selection=none;
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	ods select DiagnosticsPanel ResidualPlot ObservedByPredicted;
	model medv=&_GLSMOD /;
	run;
quit;

proc delete data=Work.reg_design;
run;

/* Polynomial Transformation */

proc glmselect data=DSC.BOSTON outdesign(addinputvars)=Work.reg_design;
	model medv=lstat lstat*lstat / showpvalues selection=none;
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	ods select DiagnosticsPanel ResidualPlot ObservedByPredicted;
	model medv=&_GLSMOD /;
	run;
quit;

proc delete data=Work.reg_design;
run;

/* Qualitative Variables */
ods noproctitle;
ods graphics / imagemap=on;

proc glmselect data=DSC.CARSEATS outdesign(addinputvars)=Work.reg_design parmlabelstyle=interlaced;
	class ShelveLoc Urban US / param=glm lprefix=15 ;
	model Sales=CompPrice Income Advertising Population Price Age Education 
		ShelveLoc Income*Advertising Price*Age / showpvalues selection=none;
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	where ShelveLoc is not missing and Urban is not missing and US is not missing;
	ods select DiagnosticsPanel ResidualPlot ObservedByPredicted;
	model Sales=&_GLSMOD /;
	run;
quit;

proc delete data=Work.reg_design;

/* Variable Selection Procedure */
ods noproctitle;
ods graphics / imagemap=on;

proc glmselect data=DSC.CARSEATS outdesign(addinputvars)=Work.reg_design 
		plots=(criterionpanel);
	class ShelveLoc Urban US / param=glm;
	model Sales=CompPrice Income Advertising Population Price Age Education 
		ShelveLoc Income*Advertising Price*Age / showpvalues selection=stepwise
    
   (select=adjrsq);
run;

proc reg data=Work.reg_design alpha=0.05 plots(only)=(diagnostics residuals 
		observedbypredicted);
	where ShelveLoc is not missing and Urban is not missing and US is not missing;
	ods select DiagnosticsPanel ResidualPlot ObservedByPredicted;
	model Sales=&_GLSMOD /;
	run;
quit;

proc delete data=Work.reg_design;
run;