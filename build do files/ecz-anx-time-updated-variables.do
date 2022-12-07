/*******************************************************************************
DO FILE NAME:			ecz-anx-time-updated-variables.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	28/06/22

TASK:					Create a dataset containing all the information
						on time-updated variables for the anxiety cohort
						(main analysis)
						
DATASET(S)/FILES USED:	
						variables-ecz-harmfulalcohol
						variables-ecz-asthma
						variables-ecz-sleep
						variables-ecz-severity
						outcome-ecz-anx-definite
						outcome-ecz-anx-censor
						eth-paths.do
						

DATASETS CREATED:		ecz-anx-time-updated-variables
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
global filename "ecz-anx-time-updated-variables"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
#1:Append info on time-updated variables
*******************************************************************************/
use "${pathIn}/variables-ecz-severity", clear 
append using "${pathIn}/outcome-ecz-anx-definite"
append using "${pathIn}/outcome-ecz-anx-censor"
append using "${pathIn}/variables-ecz-steroids"

keep if date>=(d(01apr2006))
sort patid date
order patid date

*collapse on patid and date so there is one record per patient
collapse (firstnm) modsevere anxiety anxiety_censor steroids, by(patid date)

sort patid date

bysort patid: gen obs=_n
bysort patid: gen maxobs=_N
*check a patient id with complicated variables -chose 

local update " "modsevere" "anxiety" "anxiety_censor" "steroids" "

foreach a in `update' {
	gen state`a'=`a'
	replace state`a' = state`a'[_n-1] if 	/// set the `var' flag to the same as the record (i.e. previous date) before 
		state`a'==.	&						/// IF the flag is missing and
		patid == patid[_n-1] 				// IF this is same patient
} /*end foreach a in `toupdate' */

drop modsevere anxiety anxiety_censor steroids

rename statemodsevere modsevere
rename stateanxiety anxiety
rename stateanxiety_censor anxiety_censor
rename statesteroids steroids

drop obs maxobs

*save
save "${pathCohort}/ecz-anx-time-updated-variables", replace

log close
exit