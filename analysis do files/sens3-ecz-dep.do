/*******************************************************************************
DO FILE NAME:			sens3-ecz-dep.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	16/08/22

TASK:					sensitivity analysis 3 - restricting
						to individuals with at least one consultation with their GP
						
DATASET(S)/FILES USED:	cohort-dep-ecz-main.dta
						eth-paths.do
						

DATASETS CREATED:		sens3-ecz-dep.xls
*******************************************************************************/
/*******************************************************************************
HOUSEKEEPING
*******************************************************************************/
capture log close
version 16
clear all
set linesize 80

*change directory to the location of the paths file and run the file
run eth_paths

* create a filename global that can be used throughout the file
global filename "sens3-ecz-dep"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
REGRESSION ANALYSIS
*******************************************************************************/

/*******************************************************************************
Utility program
Define a program to get the number of subjects, person years at risk, number of
failures and HR(95% CIs) out in the appropriate format as local macros from the
r(table) returned by a regression command
Called by giving:
- matrix name containing r(table) contents 
- the name of the analysis to be used in the name of global macros containing the 
output 
To call: results matrixname analysis
*******************************************************************************/
cap prog drop gethr
program define gethr
	local matrixname `1'
	local analysis `2'
	
	* pull out HR (95% CI)
	local r : display %04.2f table[1,2]
	local lc : display %04.2f table[5,2]
	local uc : display %04.2f table[6,2]
	
	global `analysis'_hr "`r' (`lc', `uc')"	
end/ /*end of gethr program*/
	
* program to pull out n's, pyars and failures
cap prog drop getNs
program define getNs
	local analysis `1'
		global `analysis'_n = string(`r(N_sub)', "%12.0gc") // number of subjects
		global `analysis'_pyar = string(`r(tr)', "%9.0fc") // total time at risk
		global `analysis'_fail = string(`r(N_fail)', "%12.0gc") // total number of failures	
end /*end of getNs program*/

/*******************************************************************************
ANALYSIS
*******************************************************************************/
*open analysis dataset
use "${pathCohort}/cohort-dep-ecz-main", clear

*use eczema consultation dates identified from previous study

*merge in consultation data 
merge m:1 patid indexdate using ${pathOut}/ecz_consultation_dates, keep(match master) keepusing(consyrbeforeindex) nogen

keep if consyrbeforeindex==1
drop consyrbeforeindex

* Preserve matching, keep valid sets only
bysort setid: egen set_exposed_mean = mean(exposed)
gen valid_set = (set_exposed_mean>0 & set_exposed_mean<1) 
tab valid_set, miss
tab valid_set exposed, col
keep if valid_set==1
drop valid_set set_exposed_mean


/*******************************************************************************
#1. Model 2 - CONFOUNDER ADJUSTED MODEL (adjusted for deprivation and calendar period)
*******************************************************************************/

/*
As there is missing carstairs data:
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

* Ethnicity INTERACTION

* pull out N's pyar and number of events
* White (W)
stdescribe if ethnicity==1
getNs ethWC 
stdescribe if ethnicity==1 & exposed==0
getNs ethWCexpN 
stdescribe if ethnicity==1 & exposed==1
getNs ethWCexpY 
	
* Minority ethnic (M)
stdescribe if ethnicity==2
getNs ethMC 
stdescribe if ethnicity==2 & exposed==0
getNs ethMCexpN 
stdescribe if ethnicity==2 & exposed==1
getNs ethMCexpY 

*run analysis in white ethnic group
display in red "**************** White ********************************"
stcox i.exposed i.calendarperiod i.carstairs_deprivation if ethnicity==1, strata(setid) level(95) base
matrix table = r(table) 
gethr table ethWC

*run analysis in minority ethnic group
display in red "**************** Minority ethnic ********************************"
stcox i.exposed i.calendarperiod i.carstairs_deprivation if ethnicity==2, strata(setid) level(95) base
matrix table = r(table) 
gethr table ethMC

*run interaction analysis 
display in red "**************** ethnicity interaction ********************************"
stcox i.exposed##i.ethnicity i.calendarperiod i.carstairs_deprivation, strata(setid) level(95) base
matrix table = r(table) 
global ethCI : display %04.2f table[4,8]

/*******************************************************************************
#2. Model 3 - MEDIATOR ADJUSTED MODEL (adjusted for all mediators)
comorbidity burden,asthma, sleep problems, smoking status,high dose steroids, harmful alcohol use, BMI
*******************************************************************************/
*open analysis dataset
use "${pathCohort}/cohort-dep-ecz-main", clear

*use eczema consultation dates identified from previous study

*merge in consultation data 
merge m:1 patid indexdate using ${pathOut}/ecz_consultation_dates, keep(match master) keepusing(consyrbeforeindex) nogen

keep if consyrbeforeindex==1
drop consyrbeforeindex

* Preserve matching, keep valid sets only
bysort setid: egen set_exposed_mean = mean(exposed)
gen valid_set = (set_exposed_mean>0 & set_exposed_mean<1) 
tab valid_set, miss
tab valid_set exposed, col
keep if valid_set==1
drop valid_set set_exposed_mean

recode bmi_cat 1=0 2=1 3=2 4=3 
label define bmicat4 0"Underweight (<18.5)" 1"Normal (18.5-<=24.9)" 2"Overweight (25-<=29.9)" 3"Obese (30+)" 
label values bmi_cat bmicat4

* recode smoking status var >> assume current/ex smokers are current smokers
*currently 0=non smoker, 1=current 2=ex 12=current or ex
recode smokstatus 0=0 1=1 2=1 12=1 
label define smok3 0"Non-smoker" 1"Current or ex-smoker" 
label values smokstatus smok3

/*
Need to drop exposed individuals with missing data and any controls no longer
matched to an included case
This means that we'll have complete cases and will preserve matching
*/

*look for missing values of carstairs, smoking and bmi 
gen exposed_nm = (exposed<.)
gen carstairs_nm = (carstairs_deprivation<.)
gen smokstatus_nm = (smokstatus<.)
gen bmi_nm = (bmi_cat<.)
gen complete = (exposed_nm==1 & carstairs_nm==1 & smokstatus_nm==1 & bmi_nm==1)
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

* Ethnicity INTERACTION

* pull out N's pyar and number of events
* White (W)
stdescribe if ethnicity==1
getNs ethWE 
stdescribe if ethnicity==1 & exposed==0
getNs ethWEexpN 
stdescribe if ethnicity==1 & exposed==1
getNs ethWEexpY 
	
* Minority ethnic (M)
stdescribe if ethnicity==2
getNs ethME 
stdescribe if ethnicity==2 & exposed==0
getNs ethMEexpN 
stdescribe if ethnicity==2 & exposed==1
getNs ethMEexpY 

*run analysis in white ethnic group
display in red "**************** White ********************************"
stcox i.exposed i.calendarperiod i.carstairs_deprivation i.cci i.asthma i.sleep i.harmfulalcohol i.smokstatus i.bmi_cat i.steroids if ethnicity==1, strata(setid) level(95) base
matrix table = r(table) 
gethr table ethWE

*run analysis in minority ethnic group
display in red "**************** Minority ethnic ********************************"
stcox i.exposed i.calendarperiod i.carstairs_deprivation i.cci i.asthma i.sleep i.harmfulalcohol i.smokstatus i.bmi_cat i.steroids if ethnicity==2, strata(setid) level(95) base
matrix table = r(table) 
gethr table ethME

*run interaction analysis 
display in red "**************** ethnicity interaction ********************************"
stcox i.exposed##i.ethnicity i.calendarperiod i.carstairs_deprivation i.cci i.asthma i.sleep i.harmfulalcohol i.smokstatus i.bmi_cat i.steroids, strata(setid) level(95) base
matrix table = r(table) 
global ethEI : display %04.2f table[4,8]

/*******************************************************************************
#4. Put results in an excel file
*******************************************************************************/
*put results for confounder adjusted and mediator adjusted into separate worksheets 

/*----------------------------------------------------------------------------*/
* CONFOUNDER ADJUSTED MODEL

* create excel file
putexcel set "${pathResults}/sens3-ecz-dep-regression.xlsx", sheet(confounder) modify

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Hazard ratios (95% CIs) for the association between atopic eczema and depression, stratified by ethnicity (adjusted for deprivation and calendar period).", bold
local ++rowcount 
putexcel A`rowcount'="Fitted to patients with complete data for all variables included in each model and from valid matched sets*"
local ++rowcount

* create table headers
putexcel A`rowcount'="Outcome", bold border(bottom, thin, black)
putexcel B`rowcount'="Number of individuals", bold border(bottom, thin, black)
putexcel C`rowcount'="PYAR", bold border(bottom, thin, black)
putexcel D`rowcount'="Number of events", bold border(bottom, thin, black)
putexcel E`rowcount'="HR (95% CI)**", bold border(bottom, thin, black)
putexcel F`rowcount'="Interaction p-value", bold border(bottom, thin, black)

local ++rowcount

* format table header cells
putexcel A3:F3, overwritefmt border(bottom, thin, black)
putexcel A4:F4, overwritefmt bold border(bottom, thin, black) txtwrap

*include interaction value in table
putexcel F`rowcount'="${ethCI}"
local ++rowcount

* loop through men and women
foreach eth in WC MC {
	if "`eth'"=="WC" putexcel A`rowcount'="White", italic
	if "`eth'"=="MC" putexcel A`rowcount'="Minority ethnic", italic
	local ++rowcount
		
* exposed and unexposed
	foreach exp in N Y {
	if "`exp'"=="N" putexcel A`rowcount'="No eczema"
	if "`exp'"=="Y" putexcel A`rowcount'="Eczema"			
	putexcel B`rowcount'="${eth`eth'exp`exp'_n}" // n
	putexcel C`rowcount'="${eth`eth'exp`exp'_pyar}" // pyar
	putexcel D`rowcount'="${eth`eth'exp`exp'_fail}" // failures
			
	if "`exp'"=="N" putexcel E`rowcount'="1 (ref)"
	if "`exp'"=="Y" putexcel E`rowcount'="${eth`eth'_hr}"
		
			local ++rowcount
		} /*end foreach exp in Y N*/
	} /*end foreach eth in WC MC*/

* add top border
putexcel A`rowcount':F`rowcount', overwritefmt border(top, thin, black)

local ++rowcount

*Footnotes
putexcel A`rowcount'="*Matched sets including one exposed patient and at least one unexposed patient"
local ++rowcount
putexcel A`rowcount'="**Estimated hazard ratios from Cox regression with current age as underlying timescale, stratified by matched set (matched on age at cohort entry, sex, general practice, and date at cohort entry)."
local ++rowcount

/*----------------------------------------------------------------------------*/
* MEDIATOR ADJUSTED MODEL

* create excel file
putexcel set "${pathResults}/sens3-ecz-dep-regression.xlsx", sheet(mediator) modify

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Hazard ratios (95% CIs) for the association between atopic eczema and depression, stratified by ethnicity (adjusted for confounders and all mediators).", bold
local ++rowcount 
putexcel A`rowcount'="Fitted to patients with complete data for all variables included in each model and from valid matched sets*"
local ++rowcount

* create table headers
putexcel A`rowcount'="Outcome", bold border(bottom, thin, black)
putexcel B`rowcount'="Number of individuals", bold border(bottom, thin, black)
putexcel C`rowcount'="PYAR", bold border(bottom, thin, black)
putexcel D`rowcount'="Number of events", bold border(bottom, thin, black)
putexcel E`rowcount'="HR (95% CI)**", bold border(bottom, thin, black)
putexcel F`rowcount'="Interaction p-value", bold border(bottom, thin, black)

local ++rowcount

* format table header cells
putexcel A3:F3, overwritefmt border(bottom, thin, black)
putexcel A4:F4, overwritefmt bold border(bottom, thin, black) txtwrap

*include interaction value in table
putexcel F`rowcount'="${ethEI}"
local ++rowcount

* loop through men and women
foreach eth in WE ME {
	if "`eth'"=="WE" putexcel A`rowcount'="White", italic
	if "`eth'"=="ME" putexcel A`rowcount'="Minority ethnic", italic
	local ++rowcount
		
* exposed and unexposed
	foreach exp in N Y {
	if "`exp'"=="N" putexcel A`rowcount'="No eczema"
	if "`exp'"=="Y" putexcel A`rowcount'="Eczema"			
	putexcel B`rowcount'="${eth`eth'exp`exp'_n}" // n
	putexcel C`rowcount'="${eth`eth'exp`exp'_pyar}" // pyar
	putexcel D`rowcount'="${eth`eth'exp`exp'_fail}" // failures
			
	if "`exp'"=="N" putexcel E`rowcount'="1 (ref)"
	if "`exp'"=="Y" putexcel E`rowcount'="${eth`eth'_hr}"
		
			local ++rowcount
		} /*end foreach exp in Y N*/
	} /*end foreach eth in WE ME*/

* add top border
putexcel A`rowcount':F`rowcount', overwritefmt border(top, thin, black)

local ++rowcount

*Footnotes
putexcel A`rowcount'="*Matched sets including one exposed patient and at least one unexposed patient"
local ++rowcount
putexcel A`rowcount'="**Estimated hazard ratios from Cox regression with current age as underlying timescale, stratified by matched set (matched on age at cohort entry, sex, general practice, and date at cohort entry)."
local ++rowcount

log close
exit 




