/*******************************************************************************
DO FILE NAME:			sens4-ecz-anx-time-updated-variables.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	16/08/22

TASK:					Time-updated variables for sensitivity analysis 4 
						(not censoring at alternative diagnosis) anxiety
						cohort
						
DATASET(S)/FILES USED:	
						variables-ecz-harmfulalcohol
						variables-ecz-asthma
						variables-ecz-sleep
						variables-ecz-severity
						outcome-ecz-anx-definite
						eth-paths.do
						

DATASETS CREATED:		sens4-ecz-anx-time-updated-variables
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
global filename "sens4-ecz-anx-time-updated-variables"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
#1:Append info on time-updated variables
*******************************************************************************/
use "${pathIn}/variables-ecz-severity", clear 
append using "${pathIn}/variables-ecz-harmfulalcohol"
append using "${pathIn}/variables-ecz-asthma"
append using "${pathIn}/variables-ecz-sleep-definite"
append using "${pathIn}/outcome-ecz-anx-definite"
append using "${pathIn}/variables-ecz-steroids"

keep if date>=(d(01apr2006))
sort patid date
order patid date

*collapse on patid and date so there is one record per patient
collapse (firstnm) modsevere harmfulalcohol asthma sleep anxiety steroids, by(patid date)

sort patid date

bysort patid: gen obs=_n
bysort patid: gen maxobs=_N
*check a patient id with complicated variables -chose 1017

local update " "modsevere" "harmfulalcohol" "asthma" "sleep" "anxiety" "steroids" "

foreach a in `update' {
	gen state`a'=`a'
	replace state`a' = state`a'[_n-1] if 	/// set the `var' flag to the same as the record (i.e. previous date) before 
		state`a'==.	&						/// IF the flag is missing and
		patid == patid[_n-1] 				// IF this is same patient
} /*end foreach a in `toupdate' */

drop sleep modsevere harmfulalcohol asthma anxiety steroids

rename statemodsevere modsevere
rename statesleep sleep
rename stateharmfulalcohol harmfulalcohol
rename stateasthma asthma
rename stateanxiety anxiety
rename statesteroids steroids

drop obs maxobs

*save
save "${pathCohort}/sens4-ecz-anx-time-updated-variables", replace

log close
exit