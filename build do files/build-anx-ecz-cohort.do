/*******************************************************************************
DO FILE NAME:			build-anx-ecz-cohort.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	28/06/22

TASK:					Aim is to create eczema anxiety cohort
						
DATASET(S)/FILES USED:	getmatchedcohort-'eczema'-main-mhealth.dta
						outcome-ecz-anx-definite
						outcome-ecz-anx-censor
						variables-'eczema'-age-sex-gp
						variables-'eczema'-BMI
						variables-'eczema'-smoking
						variables-'eczema'-ethnicity
						ecz-anx-time-updated-variables
						eth-paths.do
						

DATASETS CREATED:		cohort-anx-ecz-main
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
global filename "build-anx-ecz-cohort"

*open log file
log using "${pathLogs}/${filename}", text replace 

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
unique patid 
*number of exposed individuals is 597,117

sort patid indexdate
order patid indexdate enddate

*add in anxiety outcome dates
merge 1:1 patid using "${pathIn}/outcome-ecz-anx-definite.dta"
rename date anxiety_date
drop if _merge==2 
*people from using

*identify those with anxiety before indexdate (need to be excluded)
gen earlyanxiety=1 if anxiety_date<=indexdate 
count if earlyanxiety==1
*number of people = 106,760

drop if earlyanxiety==1
drop _merge

*add in censoring outcome dates - those with severe mental illness prior are excluded 
merge 1:1 patid using "${pathIn}/outcome-ecz-anx-censor.dta"
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

*create new enddate taking date of anxiety code into account
gen enddate_incanx=min(enddate, anxiety_date)
format %td enddate_incanx

*drop individuals who aren't exposed 
drop if exposed==.

*drop variables no longer needed
drop earlyanxiety anxiety _merge anxiety_date

*add in anxiety censor dates (alternative diagnosis i.e.,  severe mental illness)
merge 1:1 patid using "${pathIn}/outcome-ecz-anx-censor.dta"
rename date censor_date

*create new enddate taking date of censoring into account
gen enddate_inccensor=min(enddate_incanx, censor_date)
format %td enddate_inccensor

*drop individuals who aren't exposed 
drop if exposed==.

*drop variables no longer needed
drop anxiety_censor _merge censor_date enddate_incanx

unique patid
*number of exposed individuals left = 490,357

*save the dataset
save "${pathCohort}/cohort-anx-ecz-exposed", replace

/*******************************************************************************
#1.2: Deal with time-updated variables
*******************************************************************************/
*merge in time-updated variables dataset
merge 1:m patid using "${pathCohort}/ecz-anx-time-updated-variables"

keep if exposed==1

sort patid date

*formatting
*recode those with severity missing as having mild severity
recode modsevere (.=0)
label define severe 0 "mild" 1"moderate" 2"severe"
label values modsevere severe
*recode those with missing anxiety as not having them
recode anxiety (.=0)

drop _merge

*drop records before index date and after follow-up
order patid date indexdate end*
sort patid date  

drop if date<indexdate

drop if date!=. & date>enddate_inccensor

*merge in exposed cohort 
merge m:1 patid using "${pathCohort}/cohort-anx-ecz-exposed"

recode modsevere (.=0)

drop _merge anxiety_censor

unique patid
*number of exposed individuals left = 490,357

*save the dataset
save "${pathCohort}/cohort-anx-ecz-exposed", replace

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
unique patid 
*number of unexposed individuals is 2,844,120

sort patid indexdate
order patid indexdate enddate

*add in anxiety outcome dates
merge 1:1 patid using "${pathIn}/outcome-ecz-anx-definite.dta"
rename date anxiety_date
drop if _merge==2 
*pople from using

*identify those with anxiety before indexdate (need to be excluded)
gen earlyanxiety=1 if anxiety_date<=indexdate 
count if earlyanxiety==1
*number of people = 369,767

drop if earlyanxiety==1
drop _merge

*add in censoring outcome dates - those with severe mental illness prior are excluded 
merge 1:1 patid using "${pathIn}/outcome-ecz-anx-censor.dta"
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

*create new enddate taking date of anxiety code into account
gen enddate_incanx=min(enddate, anxiety_date)
format %td enddate_incanx

*drop individuals who exposed is missing
drop if exposed==.

*drop variables no longer needed
drop earlyanxiety anxiety _merge anxiety_date

*add in anxiety censor dates (alternative diagnosis i.e.,  severe mental illness)
merge 1:1 patid using "${pathIn}/outcome-ecz-anx-censor.dta"
rename date censor_date

*create new enddate taking date of censoring into account
gen enddate_inccensor=min(enddate_incanx, censor_date)
format %td enddate_inccensor

*drop individuals who aren't exposed 
drop if exposed==.

*drop variables no longer needed
drop anxiety_censor _merge censor_date enddate_incanx

unique patid
*number of exposed individuals left = 2,474,353

*save the dataset
save "${pathCohort}/cohort-anx-ecz-unexposed", replace

/*******************************************************************************
#2.2: Deal with time-updated variables
*******************************************************************************/
*merge in time-updated variables dataset
merge 1:m patid using "${pathCohort}/ecz-anx-time-updated-variables"

keep if exposed==0
drop modsevere
*as this is unexposed

sort patid date

*formatting
*recode those with missing anxiety as not having them
recode anxiety (.=0)

drop _merge

*drop records before index date and after follow-up
order patid date indexdate end*
sort patid date  

drop if date<indexdate

drop if date!=. & date>enddate_inccensor

*merge in unexposed cohort 
merge m:1 patid using "${pathCohort}/cohort-anx-ecz-unexposed"

drop _merge anxiety_censor

unique patid
*number of exposed individuals left = 2,474,353

*save the dataset
save "${pathCohort}/cohort-anx-ecz-unexposed", replace

/*******************************************************************************
#3: Create a dataset including data for both exposed and unexposed
*******************************************************************************/
append using "${pathCohort}/cohort-anx-ecz-exposed"

*recode those with missing anxiety as not having them
recode anxiety(.=0)

unique patid
*Total number of people is 2,908,311

unique patid if exposed==1
*Number of unique values of patid is 490,357

unique patid if exposed==0
*Number of unique values of patid is 2,474,353

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

*2,511 exposed individuals dropped
*416,777 unexposed individuals dropped

unique patid 
*Total number of people is 2,498,718

unique patid if exposed==1
*Number of unique values of patid is  487,846

unique patid if exposed==0
*Number of unique values of patid is  2,057,576

*save the dataset
save "${pathCohort}/cohort-anx-ecz-main", replace

*delete interim datasets
erase "${pathCohort}/cohort-anx-ecz-exposed.dta"
erase "${pathCohort}/cohort-anx-ecz-unexposed.dta"

drop valid_set set_exposed_mean

/*******************************************************************************
#5: Merge in ethnicity variable and drop people with missing ethnicity
*******************************************************************************/
*merge in ethnicity
merge m:1 patid using "${pathIn}/variables-ecz-ethnicity.dta"
keep if _merge==3
drop _merge

/*recode ethnicity and create a new variable that will be used in main analysis
*0=white, 1=south asian 2=black 3=other 4=mixed 5=not stated
want to create a binary variable where 1=white and 2=minority ethnic 
*/
recode eth5 0=1 1=2 2=2 3=2 4=2 5=., gen(ethnicity)
label define ethnicity  1"White" 2"Minority ethnic" 
label values ethnicity ethnicity
tab ethnicity eth5, miss
label var ethnicity "Ethnicity"

unique patid if ethnicity==.
*Total number of people with missing ethnicity is 1,185,642

unique patid if ethnicity==. & exposed==1
*Total number of exposed individuals with missing ethnicity is 227,545

unique patid if ethnicity==. & exposed==0
*Total number of unexposed individuals with missing ethnicity is 979,616

keep if ethnicity<.

unique patid 
*Total number of people is 1,313,076

unique patid if exposed==1
*Number of unique values of patid is  260,301

unique patid if exposed==0
*Number of unique values of patid is 1,077,960

* Preserve matching, keep valid sets only
bysort setid: egen set_exposed_mean = mean(exposed)
gen valid_set = (set_exposed_mean>0 & set_exposed_mean<1) 
tab valid_set, miss
tab valid_set exposed, col
keep if valid_set==1
drop valid_set set_exposed_mean

/*
17,703 exposed removed
303,847 unexposed
*/

unique patid 
*Total number of people is 999,430

unique patid if exposed==1
*Number of unique values of patid is   242,598

unique patid if exposed==0
*Number of unique values of patid is 774,113

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
save "${pathCohort}/cohort-anx-ecz-main", replace

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
label var asthma "Asthma 0=No, 1=Yes"
label var sleep "Sleep problems 0=No, 1=Yes"

*Get rid of variables I no longer need 
drop constype readcode readterm patient_carstairs practice_carstairs dobmi eth5 eth16 eventdate cci_*

*save the dataset
save "${pathCohort}/cohort-anx-ecz-main", replace

/*******************************************************************************
#8: Create an end date for each record to take multiple records into account
*******************************************************************************/
sort patid indexdate date // make sure it's in the correct order
gen end=date[_n+1]-1 /// the end of record will be the day before the start of the next record
	if patid==patid[_n+1] & /// if it's the same person
	indexdate==indexdate[_n+1] /// and the same indexdate
	
format %td end

replace end=enddate_inccensor+1 if end==. & anxiety==1 
*will end the day after anxiety outcome/censoring - prevents stata from not including multiple observations

replace end=enddate_inccensor if end==.
*will end at regular enddate

*save the dataset
save "${pathCohort}/cohort-anx-ecz-main", replace

/*******************************************************************************
#9: stset the data with age as the underlying timescale
*******************************************************************************/
stset end, fail(anxiety==1) origin(realyob) enter(indexdate) id(patid) scale(365.25) 

/*
17 observation end on or before enter 
- this means that one of the records for the participants ends on the index date 
 999,430  subjects
     58,563  failures in single-failure-per-subject data
(no participants are excluded from analysis)
*/

*save the dataset
save "${pathCohort}/cohort-anx-ecz-main", replace

/*******************************************************************************
#10: stsplit the data
*******************************************************************************/
sort patid indexdate

/*
split on calendar time 
Study period runs from 1apr2006 to 31jan2020
2006-2010
2011-2015
2016-2020
*/

stsplit calendarperiod, after(time=d(1/1/1900)) at(106,111,116)
replace calendarperiod=calendarperiod+1900
label define period 2006"2006-2010" 2011"2011-2015" 2016"2016-2020" 
label values calendarperiod period
label var calendarperiod "calendarperiod: observation interval"

label data "stset data for anxiety outcome"
notes: stset data for anxiety outcome

*save the dataset
save "${pathCohort}/cohort-anx-ecz-main", replace

/*******************************************************************************
#11: more tidying up of data
*******************************************************************************/
*recode those with missing harmful alcohol, sleep, steroids and anxiety as not having them
recode harmfulalcohol (.=0)
recode asthma (.=0)
recode sleep (.=0)
recode anxiety (.=0)
recode steroids (.=0)

*save the dataset
save "${pathCohort}/cohort-anx-ecz-main", replace

log close
exit
