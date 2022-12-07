/*******************************************************************************
DO FILE NAME:			appendix-ecz-anx-table1-pyars.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	20/09/22

TASK:					Aim is to create an excel file containing figures for
						table 1 (pyars(%)) for the eczema depression cohort appendix
						
DATASET(S)/FILES USED:	cohort-anx-ecz-main.dta
						

DATASETS CREATED:		appendix-ecz-anx-table1-pyars.xls

*******************************************************************************/
/*******************************************************************************
HOUSEKEEPING
*******************************************************************************/
capture log close
version 16
clear all
macro drop _all
set linesize 80

*change directory to the location of the paths file and run the file
run eth_paths

* create a filename global that can be used throughout the file
global filename "appendix-ecz-anx-table1-pyars"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
TABLE 1 PYARS
*******************************************************************************/
*open dataset
use "${pathCohort}/cohort-anx-ecz-main", clear

/*******************************************************************************
#1. Person years at risk (total and median)
*******************************************************************************/
* fu for each observation
gen fu_time=_t-_t0 // fu time duration

* loop through exposed and unexposed
foreach group in exp unexp {
	preserve
		* keep relevant patids
		if "`group'"=="exp" keep if exposed==1
		if "`group'"=="unexp" keep if exposed==0
		
		* collapse
		collapse (sum)fu_time, by(patid)
		summ fu_time, detail 
		
		* total
		global `group'_pyar=`r(sum)'
		
		* median
		local p50=string(`r(p50)', "%4.1f")
		local p25=string(`r(p25)', "%4.1f")
		local p75=string(`r(p75)', "%4.1f")
		global `group'_median "`p50' (`p25'-`p75')"	
	restore
} /*end foreach group in  exp unexp*/

/*******************************************************************************
#2. label and recode variables
*******************************************************************************/
*Label variables
label var sleep "Problems with sleep"
label var asthma "Asthma"
label var steroids "High dose oral glucocorticoids"
label var sex "Sex"
label var carstairs_deprivation "Carstairs index quintile"
label var cci "Charlson comorbidity index"
label var smokstatus "Smoking status"

recode bmi_cat 1=0 2=1 3=2 4=3 .=4
label define bmicat4 0"Underweight (<18.5)" 1"Normal (18.5-24.9)" 2"Overweight (25-29.9)" 3"Obese (30+)" 4"Missing"
label values bmi_cat bmicat4

* recode smoking status var >> assume current/ex smokers are current smokers
*currently 0=non smoker, 1=current 2=ex 12=current or ex
recode smokstatus 0=0 1=1 2=1 12=1 .=13
label define smok2 0"Non-smoker" 1"Current or ex-smoker" 13"Missing"
label values smokstatus smok2

*recode carstairs_deprivation
recode carstairs_deprivation 1=1 2=2 3=3 4=4 5=5 .=6, gen(deprivation)
label define carstairs3 1"Least deprived" 2"two" 3"three" 4"four" 5"most deprived" 6"Missing"
label values deprivation carstairs3  

/*******************************************************************************
#3. loop through exposed and unexposed and identify tect for each table cell
*******************************************************************************/
foreach group in exp unexp {
	preserve
		* keep relevant patids
		if "`group'"=="exp" keep if exposed==1
		if "`group'"=="unexp" keep if exposed==0
		
	
		/*--------------------------------------------------------------------------
		#3.1 Binary covariates (except sex)
		--------------------------------------------------------------------------*/
		local bincv " "asthma" "harmfulalcohol" "sleep" "steroids" "
		foreach cv in `bincv' {
			summ fu_time if `cv'==1
			local pyar=string(`r(sum)',"%9.0fc")
			local percent=string((`r(sum)' / ${`group'_pyar}) * 100, "%4.1f" )
			
			* create string for output
			global `cv'_`group' "`pyar' (`percent'%)" 
		}/*end foreach cv in `bincv'*/
		
		/*--------------------------------------------------------------------------
		#3.1.1 Sex
		--------------------------------------------------------------------------*/
		local sexcv " "sex" "
		foreach cv in `sexcv' {
			summ fu_time if `cv'==2
			local pyar=string(`r(sum)',"%9.0fc")
			local percent=string((`r(sum)' / ${`group'_pyar}) * 100, "%4.1f" )
			
			* create string for output
			global `cv'_`group' "`pyar' (`percent'%)" 
		}/*end foreach cv in `sexcv'*/
		
		
		/*--------------------------------------------------------------------------
		#3.2 multilevel covariates
		--------------------------------------------------------------------------*/	
		local multicv ""deprivation" "ethnicity" "smokstatus" "bmi_cat" "cci" "
		local multicv "`multicv' "age_grp" "calendarperiod" "
		foreach cv in `multicv' {
			levelsof `cv', local(levels)
			foreach i of local levels {
				summ fu_time if `cv'==`i'
				
				* use returned results
				local pyar=string(`r(sum)',"%9.0fc") 
				local percent=string((`r(sum)' / ${`group'_pyar}) * 100, "%4.1f")
				
				* create string for output
				global `cv'_`group'_`i' "`pyar' (`percent'%)"
			} /*end foreach i of local levels*/
		}/*end foreach cv in `multicv'*/
		
/*******************************************************************************
>> end loop and restore dataset
*******************************************************************************/
	restore
} /*end foreach group in exp unexp*/

/*******************************************************************************
#4. put data in excel
*******************************************************************************/
* create new excel file
putexcel set "${pathResults}/appendix-ecz-anx-table1-pyars.xlsx", replace

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Person-time under follow-up broken down by individual-level characteristics and atopic eczema exposure status for depression cohort." 
local ++rowcount // increment row couter variable
putexcel A`rowcount'="Values are pyar (percentages) unless stated otherwise"
local ++rowcount // increment row couter variable

* set up column headers
putexcel A`rowcount'="", border(top, thin, black)
putexcel B`rowcount'="With atopic eczema", bold hcenter border(top, thin, black)
putexcel C`rowcount'="Without atopic eczema", bold hcenter border(top, thin, black)

local ++rowcount

* put data in excel file
* total person years
putexcel A`rowcount'="Total person-years", border(top, thin, black)
foreach group in exp unexp {
	if "`group'"=="exp" local col "B"
	if "`group'"=="unexp" local col "C"

	local pyar ${`group'_pyar}
	putexcel `col'`rowcount'=`pyar', hcenter nformat(#,###0) border(top, thin, black)
} /*end foreach group in exp unexp*/
local ++rowcount

* median
putexcel A`rowcount'="Median (IQR) duration of follow-up (years)"
foreach group in exp unexp {
	if "`group'"=="exp" local col "B"
	if "`group'"=="unexp" local col "C"

	local median "${`group'_median}"
	putexcel `col'`rowcount'="`median'", hcenter
} /*end foreach group in exp unexp*/
local ++rowcount

/*----------------------------------------------------------------------------*/
* sex
putexcel A`rowcount'="Sex", bold
local ++rowcount

putexcel A`rowcount'="Female (%)"
putexcel B`rowcount'="${sex_exp}",  hcenter
putexcel C`rowcount'="${sex_unexp}",  hcenter
local ++rowcount

/*----------------------------------------------------------------------------*/
* age group
putexcel A`rowcount'="Age (years)", bold
local ++rowcount

levelsof age_grp, local(levels)
foreach i of local levels {
	putexcel A`rowcount'="`: label (age_grp) `i''" // use variable label for row caption
	putexcel B`rowcount'="${age_grp_exp_`i'}",  hcenter
	putexcel C`rowcount'="${age_grp_unexp_`i'}",  hcenter
	
	local ++rowcount // increment row counter so that next iteration of loop put on next row
} /*end foreach i of local levels*/

/*----------------------------------------------------------------------------*/
* Ethnicity
* row caption
putexcel A`rowcount'="Ethnicity", bold
local ++rowcount

* loop through each ethnicity cat
levelsof ethnicity, local(levels)
foreach i of local levels {
	putexcel A`rowcount'="`: label (ethnicity) `i''" // use variable label for row caption
	putexcel B`rowcount'="${ethnicity_exp_`i'}",  hcenter
	putexcel C`rowcount'="${ethnicity_unexp_`i'}",  hcenter
	
	local ++rowcount // increment row counter so that next iteration of loop put on next row
} /*end foreach i of local levels*/

/*----------------------------------------------------------------------------*/
* Carstairs
putexcel A`rowcount'="Qunitiles of carstairs deprivation index**", bold
local ++rowcount

* loop through each quintile
forvalues x=1/6 {
	putexcel A`rowcount'="`: label (deprivation) `x''" // use variable label for row caption
	putexcel B`rowcount'="${deprivation_exp_`x'}",  hcenter
	putexcel D`rowcount'="${deprivation_unexp_`x'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/5*/

/*----------------------------------------------------------------------------*/
* BMI
putexcel A`rowcount'="Body mass index (kg/m2)***", bold
local ++rowcount

* loop through each BMI cat
levelsof bmi_cat, local(levels)
foreach i of local levels {
	putexcel A`rowcount'="`: label (bmi_cat) `i''" // use variable label for row caption
	putexcel B`rowcount'="${bmi_cat_exp_`i'}",  hcenter
	putexcel C`rowcount'="${bmi_cat_unexp_`i'}",  hcenter
	
	local ++rowcount // increment row counter so that next iteration of loop put on next row
} /*end foreach i of local levels*/

/*----------------------------------------------------------------------------*/
* Smoking
putexcel A`rowcount'="Smoking***", bold
local ++rowcount

* loop through each smoking cat
levelsof smokstatus, local(levels)
foreach i of local levels {
	putexcel A`rowcount'="`: label (smokstatus) `i''" // use variable label for row caption
	putexcel B`rowcount'="${smokstatus_exp_`i'}",  hcenter
	putexcel C`rowcount'="${smokstatus_unexp_`i'}",  hcenter
	
	local ++rowcount // increment row counter so that next iteration of loop put on next row
} /*end foreach i of local levels*/

/*----------------------------------------------------------------------------*/
* Charlson comorbidity index
* row caption
putexcel A`rowcount'="Charlson comorbidity index***", bold
local ++rowcount

* loop through each cci cat
levelsof cci, local(levels)
foreach i of local levels {
	putexcel A`rowcount'="`: label (cci) `i''" // use variable label for row caption
	putexcel B`rowcount'="${cci_exp_`i'}",  hcenter
	putexcel C`rowcount'="${cci_unexp_`i'}",  hcenter
	
	local ++rowcount // increment row counter so that next iteration of loop put on next row
} /*end foreach i of local levels*/

/*----------------------------------------------------------------------------*/
* Calendar period
* row caption
putexcel A`rowcount'="Calendar period", bold
local ++rowcount

* loop through each Calendar period cat
levelsof calendarperiod, local(levels)
foreach i of local levels {
	putexcel A`rowcount'="`: label (calendarperiod) `i''" // use variable label for row caption
	putexcel B`rowcount'="${calendarperiod_exp_`i'}",  hcenter
	putexcel C`rowcount'="${calendarperiod_unexp_`i'}",  hcenter
	
	local ++rowcount // increment row counter so that next iteration of loop put on next row
} /*end foreach i of local levels*/

/*----------------------------------------------------------------------------*/
* Asthma
putexcel A`rowcount'="Asthma (%)", bold

putexcel B`rowcount'="${asthma_exp}",  hcenter
putexcel C`rowcount'="${asthma_unexp}",  hcenter
local ++rowcount 


/*----------------------------------------------------------------------------*/
* Harmful alcohol 
putexcel A`rowcount'="Harmful alcohol use (%)", bold

putexcel B`rowcount'="${harmfulalcohol_exp}",  hcenter
putexcel C`rowcount'="${harmfulalcohol_unexp}",  hcenter
local ++rowcount 


/*----------------------------------------------------------------------------*/
* Problems with sleep
putexcel A`rowcount'="Problems with sleep (%)", bold

putexcel B`rowcount'="${sleep_exp}",  hcenter
putexcel C`rowcount'="${sleep_unexp}",  hcenter
local ++rowcount 

/*----------------------------------------------------------------------------*/
* Steroids 
putexcel A`rowcount'="High-dose oral glucocorticoids (20mg+ prednisolone equivalent dose)", bold

putexcel B`rowcount'="${steroids_exp}",  hcenter
putexcel C`rowcount'="${steroids_unexp}",  hcenter
local ++rowcount 

* put top border on next row
foreach col in A B C D {
	putexcel `col'`rowcount'="" , border(top, thin, black)
}

local ++rowcount


/*----------------------------------------------------------------------------*/
* Footnotes 
putexcel A`rowcount'="IQR: Interquartile range"
local ++rowcount

putexcel A`rowcount'="Individuals can contribute data as both eczema exposed and unexposed. Therefore, pyar for exposed/unexposed do not total the whole cohort, as individuals may be included in more than one column."
local ++rowcount

putexcel A`rowcount'="* Follow-up based on censoring at the earliest of: death, no longer registered with practice, practice no longer contributing to CPRD, or severe mental illness diagnosis"
local ++rowcount

putexcel A`rowcount'="** Carstairs deprivation index based on practice-level data (from 2011)"
local ++rowcount

putexcel A`rowcount'="*** Based on records closest to index date."
local ++rowcount


log close
exit
