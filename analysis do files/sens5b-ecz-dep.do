/*******************************************************************************
DO FILE NAME:			sens5b-ecz-dep.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	17/08/22

TASK:					sensitivity analysis 5b - new study population of people 
						with imputed missing ethnicity data
						
DATASET(S)/FILES USED:	getmatchedcohort-'eczema'-main-mhealth.dta
						outcome-ecz-dep-definite
						outcome-ecz-dep-censor
						variables-'eczema'-age-sex-gp
						variables-'eczema'-BMI
						variables-'eczema'-smoking
						variables-'eczema'-ethnicity
						ecz-dep-time-updated-variables
						eth-paths.do
						

DATASETS CREATED:		sens5b-cohort-dep-ecz
						sens5b-ecz-dep.xls
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
global filename "sens5b-ecz-dep"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
BUILD THE COHORT
*******************************************************************************/
/*******************************************************************************
#1.1: DEAL WITH EXPOSED GROUP FIRST
*******************************************************************************/
*load extracted eczema patient info (contains exposed and unexposed)
use "${pathIn}/getmatchedcohort-eczema-main-mhealth.dta", clear

drop bign
label var setid "matched set id"
label var patid "patient id"
label var exposed "1: eczema exposed; 0: unexposed"
label def exposed 1"exposed" 0"unexposed"
label values exposed exposed
label var enddate "end of follow-up as exposed/unexposed"
label var indexdate "start of follow-up"

keep if exposed==1
keep if indexdate>=(d(01apr2006))

sort patid indexdate
order patid indexdate enddate

*add in depression outcome dates
merge 1:1 patid using "${pathIn}/outcome-ecz-dep-definite.dta"
rename date depression_date
drop if _merge==2 
*people from using

*identify those with depression before indexdate (need to be excluded)
gen earlydepression=1 if depression_date<=indexdate 

drop if earlydepression==1
drop _merge

*add in censoring outcome dates - those with severe mental illness prior are excluded 
merge 1:1 patid using "${pathIn}/outcome-ecz-dep-censor.dta"
rename date censor_date
drop if _merge==2 
*people from using

*identify those with smi before indexdate (need to be excluded)
gen earlysmi=1 if censor_date<=indexdate 
count if earlysmi==1
*number of people = 0
drop if earlysmi==1
* 0 people dropped 
drop earlysmi censor_date

*create new enddate taking date of depression code into account
gen enddate_incdep=min(enddate, depression_date)
format %td enddate_incdep

*drop individuals who aren't exposed 
drop if exposed==.

*drop variables no longer needed
drop earlydepression depression _merge depression_date

*add in depression censor dates (alternative diagnosis i.e.,  severe mental illness)
merge 1:1 patid using "${pathIn}/outcome-ecz-dep-censor.dta"
rename date censor_date

*create new enddate taking date of censoring into account
gen enddate_inccensor=min(enddate_incdep, censor_date)
format %td enddate_inccensor

*drop individuals who aren't exposed 
drop if exposed==.

*drop variables no longer needed
drop depression_censor _merge censor_date enddate_incdep


*save the dataset
save "${pathCohort}/sens5b-cohort-dep-ecz-exposed", replace

/*******************************************************************************
#1.2: Deal with time-updated variables
*******************************************************************************/
*merge in time-updated variables dataset
merge 1:m patid using "${pathCohort}/ecz-dep-time-updated-variables"

keep if exposed==1

sort patid date

*formatting
*recode those with severity missing as having mild severity
recode modsevere (.=0)
label define severe 0 "mild" 1"moderate" 2"severe"
label values modsevere severe
*recode those with missing harmful alcohol, asthma, sleep and depression as not having them
recode depression (.=0)

drop _merge

*drop records before index date and after follow-up
order patid date indexdate end*
sort patid date  

drop if date<indexdate

drop if date!=. & date>enddate_inccensor

*merge in exposed cohort 
merge m:1 patid using "${pathCohort}/sens5b-cohort-dep-ecz-exposed"

recode modsevere (.=0)

drop _merge depression_censor

*save the dataset
save "${pathCohort}/sens5b-cohort-dep-ecz-exposed", replace

/*******************************************************************************
#2.1: DEAL WITH UNEXPOSED GROUP 
*******************************************************************************/
*load extracted eczema patient info (contains exposed and unexposed)
use "${pathIn}/getmatchedcohort-eczema-main-mhealth.dta", clear

drop bign
label var setid "matched set id"
label var patid "patient id"
label var exposed "1: eczema exposed; 0: unexposed"
label def exposed 1"exposed" 0"unexposed"
label values exposed exposed
label var enddate "end of follow-up as exposed/unexposed"
label var indexdate "start of follow-up"

keep if exposed==0
keep if indexdate>=(d(01apr2006))

sort patid indexdate
order patid indexdate enddate

*add in depression outcome dates
merge 1:1 patid using "${pathIn}/outcome-ecz-dep-definite.dta"
rename date depression_date
drop if _merge==2 
*pople from using

*identify those with depression before indexdate (need to be excluded)
gen earlydepression=1 if depression_date<=indexdate 

drop if earlydepression==1
drop _merge

*add in censoring outcome dates - those with severe mental illness prior are excluded 
merge 1:1 patid using "${pathIn}/outcome-ecz-dep-censor.dta"
rename date censor_date
drop if _merge==2 
*people from using

*identify those with smi before indexdate (need to be excluded)
gen earlysmi=1 if censor_date<=indexdate 
count if earlysmi==1
*number of people = 0
drop if earlysmi==1
* 0 people dropped 
drop earlysmi censor_date

*create new enddate taking date of depression code into account
gen enddate_incdep=min(enddate, depression_date)
format %td enddate_incdep

*drop individuals who exposed is missing
drop if exposed==.

*drop variables no longer needed
drop earlydepression depression _merge depression_date

*add in depression censor dates (alternative diagnosis i.e.,  severe mental illness)
merge 1:1 patid using "${pathIn}/outcome-ecz-dep-censor.dta"
rename date censor_date

*create new enddate taking date of censoring into account
gen enddate_inccensor=min(enddate_incdep, censor_date)
format %td enddate_inccensor

*drop individuals who aren't exposed 
drop if exposed==.

*drop variables no longer needed
drop depression_censor _merge censor_date enddate_incdep

*save the dataset
save "${pathCohort}/sens5b-cohort-dep-ecz-unexposed", replace

/*******************************************************************************
#2.2: Deal with time-updated variables
*******************************************************************************/
*merge in time-updated variables dataset
merge 1:m patid using "${pathCohort}/ecz-dep-time-updated-variables"

keep if exposed==0
drop modsevere
*as this is unexposed

sort patid date

*formatting
*recode those with missing harmful alcohol, sleep and depression as not having them
recode depression (.=0)

drop _merge

*drop records before index date and after follow-up
order patid date indexdate end*
sort patid date  

drop if date<indexdate

drop if date!=. & date>enddate_inccensor

*merge in unexposed cohort 
merge m:1 patid using "${pathCohort}/sens5b-cohort-dep-ecz-unexposed"

drop _merge depression_censor

*save the dataset
save "${pathCohort}/sens5b-cohort-dep-ecz-unexposed", replace

/*******************************************************************************
#3: Create a dataset including data for both exposed and unexposed
*******************************************************************************/
append using "${pathCohort}/sens5b-cohort-dep-ecz-exposed"

*recode those with missing harmful alcohol, sleep and depression as not having them
recode depression(.=0)

/*******************************************************************************
#4: Preserve matching
*******************************************************************************/
bysort setid: egen set_exposed_mean = mean(exposed) 

*if mean of exposure var is 0 then only unexposed in set, if 1 then only exposed in set
gen valid_set = (set_exposed_mean>0 & set_exposed_mean<1)

*==1 is valid set containing both exposed and unexposed
tab valid_set, miss
tab valid_set exposed, col
keep if valid_set==1


*save the dataset
save "${pathCohort}/sens5b-cohort-dep-ecz", replace

*delete interim datasets
erase "${pathCohort}/sens5b-cohort-dep-ecz-exposed.dta"
erase "${pathCohort}/sens5b-cohort-dep-ecz-unexposed.dta"

drop valid_set set_exposed_mean

/*******************************************************************************
#5: Merge in ethnicity variable 
*******************************************************************************/
*merge in ethnicity
merge m:1 patid using "${pathIn}/variables-ecz-ethnicity.dta"
keep if _merge==3
drop _merge

/*recode ethnicity and create a new variable that will be used in main analysis
*0=white, 1=south asian 2=black 3=other 4=mixed 5=not stated
want to create a binary variable where 1=white and 2=minority ethnic 
*/
recode eth5 0=0 1=1 2=1 3=1 4=1 5=., gen(ethnicity)
label define ethnicity  0"White" 1"Minority ethnic" 
label values ethnicity ethnicity
tab ethnicity eth5, miss
label var ethnicity "Ethnicity"

/*******************************************************************************
#6: Merge in other variables
*******************************************************************************/
* merge in age, sex and gp data
merge m:1 patid using "${pathIn}/variables-ecz-age-sex-gp.dta"
keep if _merge==3
drop _merge

*merge in patient level carstairs
merge m:1 patid using "${pathIn}/variables-patient-carstairs.dta"
drop if _merge==2
drop _merge
*(patid from using file)

*merge in practice level carstairs 
merge m:1 pracid using "${pathIn}/variables-practice-carstairs.dta"
keep if _merge==3
drop _merge

*use practice level carstairs for people with missing patient-level
gen carstairs_deprivation=patient_carstairs
replace carstairs_deprivation=practice_carstairs if carstairs_deprivation==.

*merge in BMI 
merge m:1 patid using "${pathIn}/variables-ecz-BMI-all.dta"
keep if _merge==3
drop _merge

*merge in smoking data 
merge m:1 patid using "${pathIn}/variables-ecz-smoke-all.dta"
keep if _merge==3
drop _merge

*merge in charlson comorbidity 
merge m:1 patid using "${pathIn}/variables_ecz_cci.dta"
keep if _merge==3
drop _merge

*merge in asthma
merge m:1 patid using "${pathIn}/variables-ecz-asthma.dta"
drop if _merge==2
drop _merge
*(patid from using file)

*merge in harmful alcohol use
merge m:1 patid using "${pathIn}/variables-ecz-harmfulalcohol.dta"
drop if _merge==2
drop _merge
*(patid from using file)

*merge in problems with sleep
merge m:1 patid using "${pathIn}/variables-ecz-sleep-definite.dta"
drop if _merge==2
drop _merge
*(patid from using file)

*save the dataset
save "${pathCohort}/sens5b-cohort-dep-ecz", replace

/*******************************************************************************
#7: Formatting variables
*******************************************************************************/
*categorise BMI 
gen bmi_cat=1 if bmi<18.5
replace bmi_cat=2 if bmi>=18.5 & bmi<=24.9
replace bmi_cat=3 if bmi>=25.0 & bmi<=29.9
replace bmi_cat=4 if bmi>=30
replace bmi_cat=. if bmi==.
label var bmi_cat "BMI category"
label define bmi_cat 1"underweight" 2"normal weight" 3"overweight" 4"obese"
label values bmi_cat bmi_cat

*generate age at cohort entry
*map index date to year and subtract yob to calculate age at indexdate
gen year_index=year(indexdate)
gen age_entry=year_index-realyob
drop year_index

gen age_grp=1 if age_entry>=18 & age_entry<=29
replace age_grp=2 if age_entry>=30 & age_entry<=39
replace age_grp=3 if age_entry>=40 & age_entry<=49
replace age_grp=4 if age_entry>=50 & age_entry<=59
replace age_grp=5 if age_entry>=60 & age_entry<=69
replace age_grp=6 if age_entry>=70  

label var age_grp "Age group at cohort entry (index date)"
label define age_grp 1"18-29" 2"30-39" 3"40-49" 4"50-59" 5"60-69" 6"70+"
label values age_grp age_grp

*rename variables
rename modsevere eczema_severity
rename gender sex

recode asthma (.=0)
recode sleep (.=0)
recode harmfulalcohol (.=0)

*label variables
label var harmfulalcohol "Harmful alcohol 0=No, 1=Yes"
label var sleep "sleep problems 0=No, 1=Yes"
label var asthma "Asthma 0=No, 1=Yes"

*Get rid of variables I no longer need 
drop constype readcode readterm patient_carstairs practice_carstairs dobmi eth5 eth16 eventdate cci_*

*save the dataset
save "${pathCohort}/sens5b-cohort-dep-ecz", replace

/*******************************************************************************
#8: Create an end date for each record to take multiple records into account
*******************************************************************************/
sort patid indexdate date // make sure it's in the correct order
gen end=date[_n+1]-1 /// the end of record will be the day before the start of the next record
	if patid==patid[_n+1] & /// if it's the same person
	indexdate==indexdate[_n+1] /// and the same indexdate
	
format %td end

replace end=enddate_inccensor+1 if end==. & depression==1 
*will end the day after depression outcome/censoring - prevents stata from not including multiple observations

replace end=enddate_inccensor if end==.
*will end at regular enddate

*save the dataset
save "${pathCohort}/sens5b-cohort-dep-ecz", replace

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

save "${pathCohort}/sens5b-cohort-dep-ecz", replace



/*******************************************************************************
IMPUTATION OF MISSING ETHNICITY FOR CONFOUNDER ADJUSTED MODEL
*******************************************************************************/
use "${pathCohort}/sens5b-cohort-dep-ecz", clear

*mi set the data
mi set mlong 

*mi register the data 
mi register imputed ethnicity

mi impute logit ethnicity depression i.exposed i.carstairs_deprivation, add(10) rseed(312) force 

*mi stset
mi stset end, fail(depression==1) origin(realyob) enter(indexdate) id(patid) scale(365.25)

*mi stsplit
sort patid indexdate

/*
split on calendar time 
Study period runs from 1apr2006 to 31jan2020
2006-2010
2011-2015
2016-2020
*/

mi stsplit calendarperiod, after(time=d(1/1/1900)) at(106,111,116)
replace calendarperiod=calendarperiod+1900
label define period 2006"2006-2010" 2011"2011-2015" 2016"2016-2020" 
label values calendarperiod period
label var calendarperiod "calendarperiod: observation interval"


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
#1. Model 2 - CONFOUNDER ADJUSTED MODEL (adjusted for deprivation and calendar period)
*******************************************************************************/
* Ethnicity INTERACTION

* pull out N's pyar and number of events
* White (W)
stdescribe if ethnicity==0
getNs ethWC 
stdescribe if ethnicity==0 & exposed==0
getNs ethWCexpN 
stdescribe if ethnicity==0 & exposed==1
getNs ethWCexpY 
	
* Minority ethnic (M)
stdescribe if ethnicity==1
getNs ethMC 
stdescribe if ethnicity==1 & exposed==0
getNs ethMCexpN 
stdescribe if ethnicity==1 & exposed==1
getNs ethMCexpY 



*run analysis in white ethnic group
display in red "**************** White ********************************"
mi estimate, esampvaryok hr dots: stcox i.exposed i.calendarperiod i.carstairs_deprivation if ethnicity==0, strata(setid) level(95) base
matrix table = r(table) 
gethr table ethWC
/*
estimate is 1.20 (1.19,1.22)
*/

*run analysis in minority ethnic group
display in red "**************** Minority ethnic ********************************"
mi estimate, noisily esampvaryok hr: stcox i.exposed i.calendarperiod i.carstairs_deprivation if ethnicity==1, strata(setid) level(95) base
matrix table = r(table) 
gethr table ethMC
/*
generating an estimate in the minority ethnic group is not possible as the set 
of omitted variables is not consistent between imputations
*/

*run interaction analysis 
display in red "**************** ethnicity interaction ********************************"
mi estimate, esampvaryok hr dots: stcox i.exposed##i.ethnicity i.calendarperiod i.carstairs_deprivation, strata(setid) level(95) base
matrix table = r(table) 
global ethCI : display %04.2f table[4,8]

/*----------------------------------------------------------------------------*/
* PUT CONFOUNDER ADJUSTED MODEL IN EXCEL FILE

* create excel file
putexcel set "${pathResults}/sens5b-ecz-dep-regression.xlsx", sheet(confounder) modify

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


log close
exit 



