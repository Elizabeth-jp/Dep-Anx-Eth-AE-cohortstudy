/*******************************************************************************
DO FILE NAME:			confound-ecz-table1.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	26/09/22

TASK:					Aim is to create an excel file containing figures for
						table 1 (n(%)) for the eczema depression and anxiety cohorts
						used in the main (confounder-adjusted) analyses
						
DATASET(S)/FILES USED:	cohort-dep-ecz-main.dta
						cohort-anx-ecz-main.dta
						

DATASETS CREATED:		confound-ecz-dep-table1.xls
						confound-ecz-anx-table1.xls

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
global filename "confound-ecz-table1"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
CHARACTERISTICS OF DEPRESSION COHORT
*******************************************************************************/
use "${pathCohort}/cohort-dep-ecz-main", clear
/*******************************************************************************
GET RID OF THOSE WIH MISSING CARSTAIRS AS THIS IS THE CONFOUNDER-ADJUSTED MODEL
*******************************************************************************/
/*
As there is missing carstairs data 
Need to drop exposed individuals with missing data and any controls no longer
matched to an included case
This means that we'll have complete cases and will preserve matching
*/

*look for missing values of carstairs_deprivation
gen exposed_nm = (exposed<.)
gen carstairs_nm = (carstairs_deprivation<.)
gen complete = (exposed_nm==1 & carstairs_nm==1)
tab complete
tab complete exposed, col
keep if complete==1
drop complete

* Preserve matching, keep valid sets only
bysort setid: egen set_exposed_mean = mean(exposed)
gen valid_set = (set_exposed_mean>0 & set_exposed_mean<1) 
tab valid_set, miss
tab valid_set exposed, col
keep if valid_set==1
drop valid_set set_exposed_mean


*Label variables
label var sleep "Problems with sleep"
label var asthma "Asthma"
label var steroids "High dose oral glucocorticoids"
label var sex "Sex"
label var carstairs_deprivation "Carstairs index quintile"
label var cci "Charlson comorbidity index"
label var smokstatus "Smoking status"

* create excel file
putexcel set "${pathResults}/confound-ecz-dep-table1.xlsx", replace

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Characteristics of the study population (main analysis) at cohort entry stratified by atopic eczema exposure status (depression cohort)." 
local ++rowcount // increment row couter variable
putexcel A`rowcount'="Values are numbers (percentages) unless stated otherwise"
local ++rowcount // increment row couter variable

* set up column headers
putexcel A`rowcount'="", border(top, thin, black)
putexcel B`rowcount'="With atopic eczema", bold hcenter border(top, thin, black)
putexcel C`rowcount'="Without atopic eczema", bold hcenter border(top, thin, black)

local ++rowcount

*Totals
* border on first cell
putexcel A`rowcount'="", border(bottom, thin, black)

* exposed
unique patid if exposed==1
global nexp=r(unique)
local n = string(`r(unique)',"%12.0gc")
putexcel B`rowcount'="n=`n'", hcenter border(bottom, thin, black)

* unexposed
unique patid if exposed==0
global nunexp=r(unique)
local n = string(`r(unique)',"%12.0gc")
putexcel C`rowcount'="n=`n'", hcenter border(bottom, thin, black)

local ++rowcount

*Person years at risk (total and median)
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
} /*end foreach group in exp unexp*/

* put data in excel file
putexcel A`rowcount'="Follow-up*", bold
local ++rowcount

* total person years
putexcel A`rowcount'="Total person-years"
foreach group in exp unexp {
	if "`group'"=="exp" local col "B"
	if "`group'"=="unexp" local col "C"

	local pyar ${`group'_pyar}
	putexcel `col'`rowcount'=`pyar', hcenter nformat(#,###0)
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

*Sex
putexcel A`rowcount'="Sex", bold
local ++rowcount

putexcel A`rowcount'="Female (%)"

* loop through cohort, exp and unexp
foreach group in exp unexp {
	if "`group'"=="exp" { // exposed
		unique patid if sex==2 & exposed==1
		local denom=$nexp
		local col "B"
	}
	if "`group'"=="unexp" { // unexp
		unique patid if sex==2 & exposed==0
		local denom=$nunexp
		local col "C"
	}
	local n=string(`r(unique)',"%12.0gc")
	local percent=string((`r(unique)'/`denom')*100, "%4.1f")
	local female "`n' (`percent'%)"
	
	putexcel `col'`rowcount'="`female'",  hcenter
} /*end foreach group in exp unexp*/

local ++rowcount

*Age
* keep first record for each patid/indexdate combination
sort patid indexdate date
bysort patid indexdate: keep if _n==1

putexcel A`rowcount'="Age (years)**", bold
local ++rowcount

* loop through each age group
* so that we end up with the ageband covariates in vars: age_`group'_`agegroup'
* where group is: cohort, exp or unexp
* and where age_grp is 1-6
levelsof age_grp, local(levels)
foreach i of local levels {
	foreach group in exp unexp {
		if "`group'"=="exp" unique patid if age_grp==`i' & exposed==1
		if "`group'"=="unexp" unique patid if age_grp==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)',"%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global age_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/
	
	putexcel A`rowcount'="`: label (age_grp) `i''" // use variable label for row caption
	putexcel B`rowcount'="${age_exp_`i'}",  hcenter
	putexcel C`rowcount'="${age_unexp_`i'}",  hcenter
	
	local ++rowcount // increment row counter so that next iteration of loop put on next row
} /*end foreach i of local levels*/

/*
Ethnicity 
needs to be recoded to show people that are missing 
*/

putexcel A`rowcount'="Ethnicity", bold
local ++rowcount

* loop through each ethnicity
levelsof ethnicity, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if ethnicity==`i' & exposed==1
		if "`group'"=="unexp" unique patid if ethnicity==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global eth_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (eth) `i''" // use variable label for row caption
	putexcel B`rowcount'="${eth_exp_`i'}",  hcenter
	putexcel C`rowcount'="${eth_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*Carstairs
putexcel A`rowcount'="Qunitiles of carstairs deprivation index***", bold
local ++rowcount

*recode carstairs_deprivation
recode carstairs_deprivation 1=1 2=2 3=3 4=4 5=5 .=6, gen(deprivation)
label define carstairs3 1"Least deprived" 2"two" 3"three" 4"four" 5"most deprived" 6"Missing"
label values deprivation carstairs3 

* loop through each quintile
levelsof deprivation, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if deprivation==`i' & exposed==1
		if "`group'"=="unexp" unique patid if deprivation==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global deprivation_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (deprivation) `i''" // use variable label for row caption
	putexcel B`rowcount'="${deprivation_exp_`i'}",  hcenter
	putexcel C`rowcount'="${deprivation_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*BMI 
putexcel A`rowcount'="Body mass index (kg/m2)****", bold
local ++rowcount

recode bmi_cat 1=0 2=1 3=2 4=3 .=4
label define bmicat4 0"Underweight (<18.5)" 1"Normal (18.5-24.9)" 2"Overweight (25-29.9)" 3"Obese (30+)" 4"Missing"
label values bmi_cat bmicat4

* loop through each quintile
levelsof bmi_cat, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if bmi_cat==`i' & exposed==1
		if "`group'"=="unexp" unique patid if bmi_cat==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global bmi_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (bmi) `i''" // use variable label for row caption
	putexcel B`rowcount'="${bmi_exp_`i'}",  hcenter
	putexcel C`rowcount'="${bmi_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*Smoking status 
putexcel A`rowcount'="Smoking status****", bold
local ++rowcount

* recode smoking status var >> assume current/ex smokers are current smokers
*currently 0=non smoker, 1=current 2=ex 12=current or ex
recode smokstatus 0=0 1=1 2=1 12=1 .=13
label define smok2 0"Non-smoker" 1"Current or ex-smoker" 13"Missing"
label values smokstatus smok2

* loop through each smoking cat
levelsof smokstatus, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if smokstatus==`i' & exposed==1
		if "`group'"=="unexp" unique patid if smokstatus==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global smok_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (smok) `i''" // use variable label for row caption
	putexcel B`rowcount'="${smok_exp_`i'}",  hcenter
	putexcel C`rowcount'="${smok_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*Charlson 
putexcel A`rowcount'="Charlson Comorbidity Index****", bold
local ++rowcount

* loop through each cci cat
levelsof cci, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if cci==`i' & exposed==1
		if "`group'"=="unexp" unique patid if cci==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global cci_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (cci) `i''" // use variable label for row caption
	putexcel B`rowcount'="${cci_exp_`i'}",  hcenter
	putexcel C`rowcount'="${cci_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*Asthma 
putexcel A`rowcount'="Asthma (%)****", bold

* loop through exp and unexp
foreach group in exp unexp {
	if "`group'"=="exp" { 
		unique patid if asthma==1 & exposed==1
		local denom=$nexp
		local col "B"
	}
	if "`group'"=="unexp" { 
		unique patid if asthma==1 & exposed==0
		local denom=$nunexp
		local col "C"
	}
	local n=string(`r(unique)',"%12.0gc")
	local percent=string((`r(unique)'/`denom')*100, "%4.1f")
	local asthma "`n' (`percent'%)"
	
	putexcel `col'`rowcount'="`asthma'",  hcenter
} /*end foreach group in exp unexp*/

local ++rowcount

*Hamrful alcohol 
putexcel A`rowcount'="Harmful alcohol use (%)****", bold

* loop through exp and unexp
foreach group in exp unexp {
	if "`group'"=="exp" { 
		unique patid if harmfulalcohol==1 & exposed==1
		local denom=$nexp
		local col "B"
	}
	if "`group'"=="unexp" { 
		unique patid if harmfulalcohol==1 & exposed==0
		local denom=$nunexp
		local col "C"
	}
	local n=string(`r(unique)',"%12.0gc")
	local percent=string((`r(unique)'/`denom')*100, "%4.1f")
	local harmfulalcohol "`n' (`percent'%)"
	
	putexcel `col'`rowcount'="`harmfulalcohol'",  hcenter
} /*end foreach group in exp unexp*/

local ++rowcount

*Sleep problems 
putexcel A`rowcount'="Problems with sleep (%)****", bold

* loop through exp and unexp
foreach group in exp unexp {
	if "`group'"=="exp" { // exposed
		unique patid if sleep==1 & exposed==1
		local denom=$nexp
		local col "B"
	}
	if "`group'"=="unexp" { // unexp
		unique patid if sleep==1 & exposed==0
		local denom=$nunexp
		local col "C"
	}
	local n=string(`r(unique)',"%12.0gc")
	local percent=string((`r(unique)'/`denom')*100, "%4.1f")
	local sleep "`n' (`percent'%)"
	
	putexcel `col'`rowcount'="`sleep'",  hcenter
} /*end foreach group in exp unexp*/

local ++rowcount

/*******************************************************************************
CHARACTERISTICS OF ANXIETY COHORT
*******************************************************************************/
use "${pathCohort}/cohort-anx-ecz-main", clear
/*******************************************************************************
GET RID OF THOSE WIH MISSING CARSTAIRS AS THIS IS THE CONFOUNDER-ADJUSTED MODEL
*******************************************************************************/
/*
As there is missing carstairs data 
Need to drop exposed individuals with missing data and any controls no longer
matched to an included case
This means that we'll have complete cases and will preserve matching
*/

*look for missing values of carstairs_deprivation
gen exposed_nm = (exposed<.)
gen carstairs_nm = (carstairs_deprivation<.)
gen complete = (exposed_nm==1 & carstairs_nm==1)
tab complete
tab complete exposed, col
keep if complete==1
drop complete

* Preserve matching, keep valid sets only
bysort setid: egen set_exposed_mean = mean(exposed)
gen valid_set = (set_exposed_mean>0 & set_exposed_mean<1) 
tab valid_set, miss
tab valid_set exposed, col
keep if valid_set==1
drop valid_set set_exposed_mean


*Label variables
label var sleep "Problems with sleep"
label var asthma "Asthma"
label var steroids "High dose oral glucocorticoids"
label var sex "Sex"
label var carstairs_deprivation "Carstairs index quintile"
label var cci "Charlson comorbidity index"
label var smokstatus "Smoking status"

* create excel file
putexcel set "${pathResults}/confound-ecz-anx-table1.xlsx", replace

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Characteristics of the study population (main analysis) at cohort entry stratified by atopic eczema exposure status (anxiety cohort)." 
local ++rowcount // increment row couter variable
putexcel A`rowcount'="Values are numbers (percentages) unless stated otherwise"
local ++rowcount // increment row couter variable

* set up column headers
putexcel A`rowcount'="", border(top, thin, black)
putexcel B`rowcount'="With atopic eczema", bold hcenter border(top, thin, black)
putexcel C`rowcount'="Without atopic eczema", bold hcenter border(top, thin, black)

local ++rowcount

*Totals
* border on first cell
putexcel A`rowcount'="", border(bottom, thin, black)

* exposed
unique patid if exposed==1
global nexp=r(unique)
local n = string(`r(unique)',"%12.0gc")
putexcel B`rowcount'="n=`n'", hcenter border(bottom, thin, black)

* unexposed
unique patid if exposed==0
global nunexp=r(unique)
local n = string(`r(unique)',"%12.0gc")
putexcel C`rowcount'="n=`n'", hcenter border(bottom, thin, black)

local ++rowcount

*Person years at risk (total and median)
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
} /*end foreach group in exp unexp*/

* put data in excel file
putexcel A`rowcount'="Follow-up*", bold
local ++rowcount

* total person years
putexcel A`rowcount'="Total person-years"
foreach group in exp unexp {
	if "`group'"=="exp" local col "B"
	if "`group'"=="unexp" local col "C"

	local pyar ${`group'_pyar}
	putexcel `col'`rowcount'=`pyar', hcenter nformat(#,###0)
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

*Sex
putexcel A`rowcount'="Sex", bold
local ++rowcount

putexcel A`rowcount'="Female (%)"

* loop through cohort, exp and unexp
foreach group in exp unexp {
	if "`group'"=="exp" { // exposed
		unique patid if sex==2 & exposed==1
		local denom=$nexp
		local col "B"
	}
	if "`group'"=="unexp" { // unexp
		unique patid if sex==2 & exposed==0
		local denom=$nunexp
		local col "C"
	}
	local n=string(`r(unique)',"%12.0gc")
	local percent=string((`r(unique)'/`denom')*100, "%4.1f")
	local female "`n' (`percent'%)"
	
	putexcel `col'`rowcount'="`female'",  hcenter
} /*end foreach group in exp unexp*/

local ++rowcount

*Age
* keep first record for each patid/indexdate combination
sort patid indexdate date
bysort patid indexdate: keep if _n==1

putexcel A`rowcount'="Age (years)**", bold
local ++rowcount

* loop through each age group
* so that we end up with the ageband covariates in vars: age_`group'_`agegroup'
* where group is: cohort, exp or unexp
* and where age_grp is 1-6
levelsof age_grp, local(levels)
foreach i of local levels {
	foreach group in exp unexp {
		if "`group'"=="exp" unique patid if age_grp==`i' & exposed==1
		if "`group'"=="unexp" unique patid if age_grp==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)',"%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global age_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/
	
	putexcel A`rowcount'="`: label (age_grp) `i''" // use variable label for row caption
	putexcel B`rowcount'="${age_exp_`i'}",  hcenter
	putexcel C`rowcount'="${age_unexp_`i'}",  hcenter
	
	local ++rowcount // increment row counter so that next iteration of loop put on next row
} /*end foreach i of local levels*/

/*
Ethnicity 
*/

putexcel A`rowcount'="Ethnicity", bold
local ++rowcount

* loop through each ethnicity
levelsof ethnicity, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if ethnicity==`i' & exposed==1
		if "`group'"=="unexp" unique patid if ethnicity==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global eth_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (eth) `i''" // use variable label for row caption
	putexcel B`rowcount'="${eth_exp_`i'}",  hcenter
	putexcel C`rowcount'="${eth_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*Carstairs
putexcel A`rowcount'="Qunitiles of carstairs deprivation index***", bold
local ++rowcount

*recode carstairs_deprivation
recode carstairs_deprivation 1=1 2=2 3=3 4=4 5=5 .=6, gen(deprivation)
label define carstairs3 1"Least deprived" 2"two" 3"three" 4"four" 5"most deprived" 6"Missing"
label values deprivation carstairs3 

* loop through each quintile
levelsof deprivation, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if deprivation==`i' & exposed==1
		if "`group'"=="unexp" unique patid if deprivation==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global deprivation_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (deprivation) `i''" // use variable label for row caption
	putexcel B`rowcount'="${deprivation_exp_`i'}",  hcenter
	putexcel C`rowcount'="${deprivation_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*BMI 
putexcel A`rowcount'="Body mass index (kg/m2)****", bold
local ++rowcount

recode bmi_cat 1=0 2=1 3=2 4=3 .=4
label define bmicat4 0"Underweight (<18.5)" 1"Normal (18.5-24.9)" 2"Overweight (25-29.9)" 3"Obese (30+)" 4"Missing"
label values bmi_cat bmicat4

* loop through each quintile
levelsof bmi_cat, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if bmi_cat==`i' & exposed==1
		if "`group'"=="unexp" unique patid if bmi_cat==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global bmi_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (bmi) `i''" // use variable label for row caption
	putexcel B`rowcount'="${bmi_exp_`i'}",  hcenter
	putexcel C`rowcount'="${bmi_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*Smoking status 
putexcel A`rowcount'="Smoking status****", bold
local ++rowcount

* recode smoking status var >> assume current/ex smokers are current smokers
*currently 0=non smoker, 1=current 2=ex 12=current or ex
recode smokstatus 0=0 1=1 2=1 12=1 .=13
label define smok2 0"Non-smoker" 1"Current or ex-smoker" 13"Missing"
label values smokstatus smok2

* loop through each smoking cat
levelsof smokstatus, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if smokstatus==`i' & exposed==1
		if "`group'"=="unexp" unique patid if smokstatus==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global smok_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (smok) `i''" // use variable label for row caption
	putexcel B`rowcount'="${smok_exp_`i'}",  hcenter
	putexcel C`rowcount'="${smok_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*Charlson 
putexcel A`rowcount'="Charlson Comorbidity Index****", bold
local ++rowcount

* loop through each cci cat
levelsof cci, local(levels)
foreach i of local levels {
	foreach group in exp unexp { 
		if "`group'"=="exp" unique patid if cci==`i' & exposed==1
		if "`group'"=="unexp" unique patid if cci==`i' & exposed==0
		
		* use returned results
		local n=string(`r(unique)', "%12.0gc") 
		local percent=string((`r(unique)' / ${n`group'}) * 100, "%4.1f")
		
		* create string for output
		global cci_`group'_`i' "`n' (`percent'%)"	
	} /*end foreach group in exp unexp*/	
	
	* put output strings in excel file
	putexcel A`rowcount'="`: label (cci) `i''" // use variable label for row caption
	putexcel B`rowcount'="${cci_exp_`i'}",  hcenter
	putexcel C`rowcount'="${cci_unexp_`i'}",  hcenter
	
	local ++rowcount
} /*end forvalues x=1/6*/

*Asthma 
putexcel A`rowcount'="Asthma (%)****", bold

* loop through exp and unexp
foreach group in exp unexp {
	if "`group'"=="exp" { 
		unique patid if asthma==1 & exposed==1
		local denom=$nexp
		local col "B"
	}
	if "`group'"=="unexp" { 
		unique patid if asthma==1 & exposed==0
		local denom=$nunexp
		local col "C"
	}
	local n=string(`r(unique)',"%12.0gc")
	local percent=string((`r(unique)'/`denom')*100, "%4.1f")
	local asthma "`n' (`percent'%)"
	
	putexcel `col'`rowcount'="`asthma'",  hcenter
} /*end foreach group in exp unexp*/

local ++rowcount

*Hamrful alcohol 
putexcel A`rowcount'="Harmful alcohol use (%)****", bold

* loop through exp and unexp
foreach group in exp unexp {
	if "`group'"=="exp" { 
		unique patid if harmfulalcohol==1 & exposed==1
		local denom=$nexp
		local col "B"
	}
	if "`group'"=="unexp" { 
		unique patid if harmfulalcohol==1 & exposed==0
		local denom=$nunexp
		local col "C"
	}
	local n=string(`r(unique)',"%12.0gc")
	local percent=string((`r(unique)'/`denom')*100, "%4.1f")
	local harmfulalcohol "`n' (`percent'%)"
	
	putexcel `col'`rowcount'="`harmfulalcohol'",  hcenter
} /*end foreach group in exp unexp*/

local ++rowcount

*Sleep problems 
putexcel A`rowcount'="Problems with sleep (%)****", bold

* loop through exp and unexp
foreach group in exp unexp {
	if "`group'"=="exp" { // exposed
		unique patid if sleep==1 & exposed==1
		local denom=$nexp
		local col "B"
	}
	if "`group'"=="unexp" { // unexp
		unique patid if sleep==1 & exposed==0
		local denom=$nunexp
		local col "C"
	}
	local n=string(`r(unique)',"%12.0gc")
	local percent=string((`r(unique)'/`denom')*100, "%4.1f")
	local sleep "`n' (`percent'%)"
	
	putexcel `col'`rowcount'="`sleep'",  hcenter
} /*end foreach group in exp unexp*/

local ++rowcount