/*******************************************************************************
DO FILE NAME:			main-ecz-anx-regression-severity.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	13/07/22

TASK:					Aim is to create an excel file containing the regression analysis
						association between eczema severity and anxiety modified by ethnicity?
						
DATASET(S)/FILES USED:	cohort-anx-ecz-main.dta
						

DATASETS CREATED:		main-ecz-anx-severity.xls
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
global filename "main-ecz-anx-regression-severity"

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
use "${pathCohort}/cohort-anx-ecz-main", clear

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
 Mild eczema  |   1.101279   .0134923     7.87   0.000     1.075149    1.128043
Moderate e..  |   1.431073   .0333117    15.40   0.000     1.367251    1.497875
Severe ecz..  |   1.341619   .1245473     3.17   0.002     1.118431    1.609346
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
 Mild eczema  |   1.304813   .0725576     4.78   0.000     1.170078    1.455062
Moderate e..  |   1.828883   .1914172     5.77   0.000     1.489691    2.245306
Severe ecz..  |   1.153088   .5310376     0.31   0.757     .4675785    2.843615
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
use "${pathCohort}/cohort-anx-ecz-main", clear

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
 Mild eczema  |   1.100942   .0136155     7.78   0.000     1.074577    1.127954
Moderate e..  |   1.428839   .0336972    15.13   0.000     1.364297    1.496435
Severe ecz..  |   1.335904   .1253495     3.09   0.002     1.111491    1.605627
              |



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
 Mild eczema  |   1.316955   .0733983     4.94   0.000     1.180676    1.468965
Moderate e..  |   1.832283    .191927     5.78   0.000     1.492215    2.249851
Severe ecz..  |    1.11046   .5135711     0.23   0.821     .4485752    2.748975


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
use "${pathCohort}/cohort-anx-ecz-main", clear

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
 Mild eczema  |   1.082141   .0154923     5.51   0.000     1.052199    1.112936
Moderate e..  |   1.236621   .0328618     7.99   0.000     1.173862    1.302736
Severe ecz..  |   1.239041   .1322159     2.01   0.045     1.005206     1.52727



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
 Mild eczema  |   1.257205   .0820963     3.51   0.000     1.106171    1.428862
Moderate e..  |   1.426088   .1687795     3.00   0.003     1.130852    1.798404
Severe ecz..  |   .6913849   .4279264    -0.60   0.551     .2055306    2.325751


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
putexcel set "${pathResults}/main-ecz-anx-severity.xlsx", sheet(severity_minimally) modify

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Hazard ratios (95% CIs) for the association between atopic eczema severity and anxiety, stratified by ethnicity (minimally adjusted).", bold
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
putexcel set "${pathResults}/main-ecz-anx-severity.xlsx", sheet(severity_confounder) modify

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Hazard ratios (95% CIs) for the association between atopic eczema severity and anxiety, stratified by ethnicity (adjusted for deprivation and calendar period).", bold
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
putexcel set "${pathResults}/main-ecz-anx-severity.xlsx", sheet(severity_mediator) modify

* set row count variable
local rowcount=1

* Table title
putexcel A`rowcount'="Table x. Hazard ratios (95% CIs) for the association between atopic eczema severity and anxiety, stratified by ethnicity (adjusted for confounders and all mediators).", bold
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

