/*******************************************************************************
DO FILE NAME:			main-ecz-anx-severityfollowup.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	20/07/22

TASK:					describe the proportions of total follow up each ethnic group (white or minority
						spends at each level of atopic eczema (mild, moderate or severe) severity during follow up.
						
DATASET(S)/FILES USED:	cohort-anx-ecz-main.dta
						
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
global filename "main-ecz-anx-severityfollowup"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
Generate follow up variables
*******************************************************************************/
use "${pathCohort}/cohort-anx-ecz-main", clear

*keep only individuals with atopic eczema as we are interested in severity
keep if exposed==1

* fu for each level of eczema severity, overall and for different ethnic groups
*overall
gen fu_time_total=_t-_t0
*white ethnicity 
gen fu_time_white=_t-_t0 if ethnicity==1 
*minority ethnic 
gen fu_time_ethnic=_t-_t0 if ethnicity==2
*mild
gen fu_time_mild=_t-_t0 if eczema_severity==0
*moderate
gen fu_time_mod=_t-_t0 if eczema_severity==1
*severe 
gen fu_time_sev=_t-_t0 if eczema_severity==2

*sum follow up time by patid 
collapse (sum) fu_time_total fu_time_white fu_time_ethnic fu_time_mild fu_time_mod fu_time_sev, by(patid)

*merge in ethnicity data 
merge m:1 patid using "${pathIn}/variables-ecz-ethnicity.dta"
keep if _merge==3
drop _merge

recode eth5 0=1 1=2 2=2 3=2 4=2 5=., gen(ethnicity)
label define ethnicity1  1"White" 2"Minority ethnic" 
label values ethnicity ethnicity1
tab ethnicity eth5, miss
label var ethnicity "Ethnicity"

drop eth5 eth16

/*******************************************************************************
Calculating follow up (totals)
*******************************************************************************/
*total follow up in exposed
sum fu_time_total
display r(sum)
*970,230.12

/*******************************************************************************
Calculating follow up (white ethnic group)
*******************************************************************************/
*total follow up in white ethnic group
sum fu_time_white
display r(sum)
*848,896.39

*total follow up when severity is mild and ethnicity is White
sum fu_time_mild if ethnicity==1
display r(sum)
* 655,936.6

*total follow up when severity is moderate and ethnicity is White
sum fu_time_mod if ethnicity==1
display r(sum)
* 182,098.21

*total follow up when severity is severe and ethnicity is White
sum fu_time_sev if ethnicity==1
display r(sum)
* 10,861.578

/*******************************************************************************
Calculating follow up (minority ethnic group)
*******************************************************************************/

*total follow up in minority ethnic group
sum fu_time_ethnic
display r(sum)
*121,333.73

*total follow up when severity is mild and ethnicity is Minority ethnic
sum fu_time_mild if ethnicity==2
display r(sum)
* 93,680.659

*total follow up when severity is moderate and ethnicity is Minority ethnic
sum fu_time_mod if ethnicity==2
display r(sum)
* 25,819.476

*total follow up when severity is severe and ethnicity is Minority ethnic
sum fu_time_sev if ethnicity==2
display r(sum)
* 1,833.5962

log close
exit 



