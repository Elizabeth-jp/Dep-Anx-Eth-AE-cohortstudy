/*******************************************************************************
DO FILE NAME:			main-ecz-dep-regression-severity.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	13/07/22

TASK:					Aim is to create an excel file containing the regression analysis
						association between eczema severity and depression modified by ethnicity?
						
DATASET(S)/FILES USED:	cohort-dep-ecz-main.dta
						

DATASETS CREATED:		main-ecz-dep-severity.xls
						(worksheet severity_minimally,severity_confounder,severity_mediator)
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
global filename "main-ecz-dep-regression-severity"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
Utility program
Define a program to get the number of subjects, person years at risk, number of
failures 
To call: results matrixname analysis
*******************************************************************************/
* program to pull out n's, pyars and failures
cap prog drop getNs
program define getNs
	local analysis `1'
		global `analysis'_n = string(`r(N_sub)', "%12.0gc") // number of subjects
		global `analysis'_pyar = string(`r(tr)', "%9.0fc") // total time at risk
		global `analysis'_fail = string(`r(N_fail)', "%12.0gc") // total number of failures	
end /*end of getNs program*/

/*******************************************************************************
#1. Model 1 - MINIMALLY ADJUSTED MODEL (adjusted for matched variables due to stratification by matched set)
*******************************************************************************/
*open analysis dataset
use "${pathCohort}/cohort-dep-ecz-main", clear

*Deal with severity variable 
*set to 0 for unexposed and 1-3 for exposed
*create our new exposure variable which is severity
recode eczema_severity 0=1 1=2 2=3, gen(severity)
tab eczema_severity severity, missing
replace severity=0 if exposed==0 
label define severity 0"Unexposed" 1"Mild eczema" 2"Moderate eczema" 3 "Severe eczema"
label values severity severity
tab severity exposed, missing 

* Ethnicity INTERACTION

* pull out N's pyar and number of events
* White (W)
stdescribe if ethnicity==1
getNs ethWM 
stdescribe if ethnicity==1 & severity==0
getNs ethWMsevN 
stdescribe if ethnicity==1 & severity==1
getNs ethWMsevMI
stdescribe if ethnicity==1 & severity==2
getNs ethWMsevMO
stdescribe if ethnicity==1 & severity==3
getNs ethWMsevSE

* Minority ethnic (M)
stdescribe if ethnicity==2
getNs ethMM 
stdescribe if ethnicity==2 & severity==0
getNs ethMMsevN
stdescribe if ethnicity==2 & severity==1
getNs ethMMsevMI
stdescribe if ethnicity==2 & severity==2
getNs ethMMsevMO
stdescribe if ethnicity==2 & severity==3
getNs ethMMsevSE

*run analysis in white ethnic group
display in red "**************** White ********************************"
stcox i.severity if ethnicity==1, strata(setid) level(95) base

/*
-------------------------------------------------------------------------------
           _t | Haz. ratio   Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
     severity |
   Unexposed  |          1  (base)
 Mild eczema  |   1.085221    .012512     7.09   0.000     1.060973    1.110023
Moderate e..  |   1.390586   .0306605    14.95   0.000     1.331773    1.451997
Severe ecz..  |   1.306556   .1158846     3.01   0.003     1.098072    1.554623
-------------------------------------------------------------------------------


*/

*run analysis in minority ethnic group
display in red "**************** Minority ethnic ********************************"
stcox i.severity if ethnicity==2, strata(setid) level(95) base

/*
-------------------------------------------------------------------------------
           _t | Haz. ratio   Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
     severity |
   Unexposed  |          1  (base)
 Mild eczema  |   1.186593   .0602293     3.37   0.001     1.074227    1.310712
Moderate e..  |   1.912682   .1819144     6.82   0.000     1.587397    2.304625
Severe ecz..  |   1.547473   .5600575     1.21   0.228     .7613042    3.145486
-------------------------------------------------------------------------------


*/

*run interaction analysis (need to do a likelihood ratio test due to ordered categorical variables)
display in red "**************** ethnicity interaction ********************************"
*simple model
stcox i.severity, strata(setid) level(95) base
est store A
*interaction model
stcox i.severity##i.ethnicity, strata(setid) level(95) base
est store B
lrtest A B
global ethMI :  display %04.2f r(p) // pull out p-value


/*******************************************************************************
#2. Model 2 - CONFOUNDER ADJUSTED MODEL (adjusted for deprivation and calendar period)
*******************************************************************************/
*open analysis dataset
use "${pathCohort}/cohort-dep-ecz-main", clear

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

*Deal with severity variable 
*set to 0 for unexposed and 1-3 for exposed
*create our new exposure variable which is severity
recode eczema_severity 0=1 1=2 2=3, gen(severity)
tab eczema_severity severity, missing
replace severity=0 if exposed==0 
label define severity 0"Unexposed" 1"Mild eczema" 2"Moderate eczema" 3 "Severe eczema"
label values severity severity
tab severity exposed, missing 

* Ethnicity INTERACTION

* pull out N's pyar and number of events
* White (W)
stdescribe if ethnicity==1
getNs ethWC 
stdescribe if ethnicity==1 & severity==0
getNs ethWCsevN 
stdescribe if ethnicity==1 & severity==1
getNs ethWCsevMI
stdescribe if ethnicity==1 & severity==2
getNs ethWCsevMO
stdescribe if ethnicity==1 & severity==3
getNs ethWCsevSE

* Minority ethnic (M)
stdescribe if ethnicity==2
getNs ethMC 
stdescribe if ethnicity==2 & severity==0
getNs ethMCsevN
stdescribe if ethnicity==2 & severity==1
getNs ethMCsevMI
stdescribe if ethnicity==2 & severity==2
getNs ethMCsevMO
stdescribe if ethnicity==2 & severity==3
getNs ethMCsevSE

*run analysis in white ethnic group
display in red "**************** White ********************************"
stcox i.severity i.calendarperiod i.carstairs_deprivation if ethnicity==1, strata(setid) level(95) base

/*
-------------------------------------------------------------------------------
           _t | Haz. ratio   Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
     severity |
   Unexposed  |          1  (base)
 Mild eczema  |   1.085923   .0126479     7.08   0.000     1.061414    1.110997
Moderate e..  |   1.384853   .0309245    14.58   0.000     1.325549     1.44681
Severe ecz..  |   1.376177   .1234378     3.56   0.000     1.154316     1.64068



*/

*run analysis in minority ethnic group
display in red "**************** Minority ethnic ********************************"
stcox i.severity i.calendarperiod i.carstairs_deprivation if ethnicity==2, strata(setid) level(95) base

/*
-------------------------------------------------------------------------------
           _t | Haz. ratio   Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
     severity |
   Unexposed  |          1  (base)
 Mild eczema  |   1.195893   .0608768     3.51   0.000     1.082336    1.321365
Moderate e..  |   1.902925    .181168     6.76   0.000     1.579003    2.293297
Severe ecz..  |   1.601092   .5820752     1.29   0.195     .7851687    3.264899



*/

*run interaction analysis (need to do a likelihood ratio test due to ordered categorical variables)
display in red "**************** ethnicity interaction ********************************"
*simple model
stcox i.severity i.calendarperiod i.carstairs_deprivation, strata(setid) level(95) base
est store A
*interaction model
stcox i.severity##i.ethnicity i.calendarperiod i.carstairs_deprivation, strata(setid) level(95) base
est store B
lrtest A B
global ethCI :  display %04.2f r(p) // pull out p-value

/*******************************************************************************
#3. Model 3 - MEDIATOR ADJUSTED MODEL (adjusted for all mediators)
comorbidity burden,asthma, sleep problems, smoking status,high dose steroids, harmful alcohol use, BMI
*******************************************************************************/
*open analysis dataset
use "${pathCohort}/cohort-dep-ecz-main", clear

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

*Deal with severity variable 
*set to 0 for unexposed and 1-3 for exposed
*create our new exposure variable which is severity
recode eczema_severity 0=1 1=2 2=3, gen(severity)
tab eczema_severity severity, missing
replace severity=0 if exposed==0 
label define severity 0"Unexposed" 1"Mild eczema" 2"Moderate eczema" 3 "Severe eczema"
label values severity severity
tab severity exposed, missing 

* Ethnicity INTERACTION

* pull out N's pyar and number of events
* White (W)
stdescribe if ethnicity==1
getNs ethWE 
stdescribe if ethnicity==1 & severity==0
getNs ethWEsevN 
stdescribe if ethnicity==1 & severity==1
getNs ethWEsevMI
stdescribe if ethnicity==1 & severity==2
getNs ethWEsevMO
stdescribe if ethnicity==1 & severity==3
getNs ethWEsevSE

* Minority ethnic (M)
stdescribe if ethnicity==2
getNs ethME 
stdescribe if ethnicity==2 & severity==0
getNs ethMEsevN
stdescribe if ethnicity==2 & severity==1
getNs ethMEsevMI
stdescribe if ethnicity==2 & severity==2
getNs ethMEsevMO
stdescribe if ethnicity==2 & severity==3
getNs ethMEsevSE

*run analysis in white ethnic group
display in red "**************** White ********************************"
stcox i.severity i.calendarperiod i.carstairs_deprivation i.cci i.asthma i.sleep i.harmfulalcohol i.smokstatus i.bmi_cat i.steroids if ethnicity==1, strata(setid) level(95) base

/*
-------------------------------------------------------------------------------
           _t | Haz. ratio   Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
     severity |
   Unexposed  |          1  (base)
 Mild eczema  |   1.069987   .0147047     4.92   0.000     1.041551    1.099199
Moderate e..  |    1.21735   .0310669     7.71   0.000     1.157957    1.279788
Severe ecz..  |   1.321209   .1367118     2.69   0.007     1.078682    1.618264



*/

*run analysis in minority ethnic group
display in red "**************** Minority ethnic ********************************"
stcox i.severity i.calendarperiod i.carstairs_deprivation i.cci i.asthma i.sleep i.harmfulalcohol i.smokstatus i.bmi_cat i.steroids if ethnicity==2, strata(setid) level(95) base

/*
-------------------------------------------------------------------------------
           _t | Haz. ratio   Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
     severity |
   Unexposed  |          1  (base)
 Mild eczema  |   1.110376   .0669839     1.74   0.083      .986554    1.249738
Moderate e..  |   1.525865   .1733222     3.72   0.000     1.221317    1.906354
Severe ecz..  |    1.29262   .5462351     0.61   0.544     .5646386    2.959181


*/

*run interaction analysis (need to do a likelihood ratio test due to ordered categorical variables)
display in red "**************** ethnicity interaction ********************************"
*simple model
stcox i.severity i.calendarperiod i.carstairs_deprivation i.cci i.asthma i.sleep i.harmfulalcohol i.smokstatus i.bmi_cat i.steroids, strata(setid) level(95) base
est store A
*interaction model 
stcox i.severity##i.ethnicity i.calendarperiod i.carstairs_deprivation i.cci i.asthma i.sleep i.harmfulalcohol i.smokstatus i.bmi_cat i.steroids, strata(setid) level(95) base
est store B
lrtest A B
global ethEI : display %04.2f r(p) // pull out p-value

/*******************************************************************************
#4. Put results in an excel file
*******************************************************************************/
*put results for minimally, confounder adjusted and mediator adjusted into separate worksheets 

/*----------------------------------------------------------------------------*/
* MINIMAL MODEL

* create excel file
putexcel set "${pathResults}/main-ecz-dep-severity.xlsx", sheet(severity_minimally) modify

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Hazard ratios (95% CIs) for the association between atopic eczema severity and depression, stratified by ethnicity (minimally adjusted).", bold
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
putexcel F`rowcount'="${ethMI}"
local ++rowcount

* loop through white ethnic group and minority ethnic group
foreach eth in WM MM {
	if "`eth'"=="WM" putexcel A`rowcount'="White", italic
	if "`eth'"=="MM" putexcel A`rowcount'="Minority ethnic", italic
	local ++rowcount
		
* severity (unexposed, mild, moderate, severe)
	foreach sev in N MI MO SE {
	if "`sev'"=="N" putexcel A`rowcount'="unexposed"
	if "`sev'"=="MI" putexcel A`rowcount'="Mild eczema"
	if "`sev'"=="MO" putexcel A`rowcount'="Moderate eczema"
	if "`sev'"=="SE" putexcel A`rowcount'="Severe eczema"
	putexcel B`rowcount'="${eth`eth'sev`sev'_n}" // n
	putexcel C`rowcount'="${eth`eth'sev`sev'_pyar}" // pyar
	putexcel D`rowcount'="${eth`eth'sev`sev'_fail}" // failures

			local ++rowcount
		} /*end foreach sev in Y MI MO SE*/
	} /*end foreach eth in WM MM*/

* add top border
putexcel A`rowcount':F`rowcount', overwritefmt border(top, thin, black)

local ++rowcount

*Footnotes
putexcel A`rowcount'="*Matched sets including one exposed patient and at least one unexposed patient"
local ++rowcount
putexcel A`rowcount'="**Estimated hazard ratios from Cox regression with current age as underlying timescale, stratified by matched set (matched on age at cohort entry, sex, general practice, and date at cohort entry)."
local ++rowcount

/*----------------------------------------------------------------------------*/
* CONFOUNDER ADJUSTED MODEL

* create excel file
putexcel set "${pathResults}/main-ecz-dep-severity.xlsx", sheet(severity_confounder) modify

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Hazard ratios (95% CIs) for the association between atopic eczema severity and depression, stratified by ethnicity (adjusted for deprivation and calendar period).", bold
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

* loop through white ethnic group and minority ethnic group
foreach eth in WC MC {
	if "`eth'"=="WC" putexcel A`rowcount'="White", italic
	if "`eth'"=="MC" putexcel A`rowcount'="Minority ethnic", italic
	local ++rowcount
		
* severity (unexposed, mild, moderate, severe)
	foreach sev in N MI MO SE {
	if "`sev'"=="N" putexcel A`rowcount'="unexposed"
	if "`sev'"=="MI" putexcel A`rowcount'="Mild eczema"
	if "`sev'"=="MO" putexcel A`rowcount'="Moderate eczema"
	if "`sev'"=="SE" putexcel A`rowcount'="Severe eczema"
	putexcel B`rowcount'="${eth`eth'sev`sev'_n}" // n
	putexcel C`rowcount'="${eth`eth'sev`sev'_pyar}" // pyar
	putexcel D`rowcount'="${eth`eth'sev`sev'_fail}" // failures
		
			local ++rowcount
		} /*end foreach sev in Y MI MO SE*/
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
putexcel set "${pathResults}/main-ecz-dep-severity.xlsx", sheet(severity_mediator) modify

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Hazard ratios (95% CIs) for the association between atopic eczema severity and depression, stratified by ethnicity (adjusted for confounders and all mediators).", bold
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

* loop through white ethnic group and minority ethnic group
foreach eth in WE ME {
	if "`eth'"=="WE" putexcel A`rowcount'="White", italic
	if "`eth'"=="ME" putexcel A`rowcount'="Minority ethnic", italic
	local ++rowcount
		
* severity (unexposed, mild, moderate, severe)
	foreach sev in N MI MO SE {
	if "`sev'"=="N" putexcel A`rowcount'="unexposed"
	if "`sev'"=="MI" putexcel A`rowcount'="Mild eczema"
	if "`sev'"=="MO" putexcel A`rowcount'="Moderate eczema"
	if "`sev'"=="SE" putexcel A`rowcount'="Severe eczema"
	putexcel B`rowcount'="${eth`eth'sev`sev'_n}" // n
	putexcel C`rowcount'="${eth`eth'sev`sev'_pyar}" // pyar
	putexcel D`rowcount'="${eth`eth'sev`sev'_fail}" // failures
		
			local ++rowcount
		} /*end foreach sev in Y MI MO SE*/
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

