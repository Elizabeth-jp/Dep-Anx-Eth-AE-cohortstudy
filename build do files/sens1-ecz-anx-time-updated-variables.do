/*******************************************************************************
DO FILE NAME:			sens1-ecz-anx-time-updated-variables.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	28/06/22

TASK:					Create a dataset containing all the information
						on time-updated variables for the anxiety cohort
						(sensitivity analysis 1) alternative code list for anxiety
						
DATASET(S)/FILES USED:	
						variables-ecz-harmfulalcohol
						variables-ecz-asthma
						variables-ecz-sleep
						variables-ecz-severity
						outcome-ecz-anx-all
						outcome-ecz-anx-censor
						eth-paths.do
						

DATASETS CREATED:		sens1-ecz-anx-time-updated-variables
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
global filename "sens1-ecz-anx-time-updated-variables"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
#1:Append info on time-updated variables
*******************************************************************************/
use "${pathIn}/variables-ecz-severity", clear 
append using "${pathIn}/variables-ecz-harmfulalcohol"
append using "${pathIn}/variables-ecz-asthma"
append using "${pathIn}/variables-ecz-sleep-definite"
append using "${pathIn}/outcome-ecz-anx-all"
append using "${pathIn}/outcome-ecz-anx-censor"
append using "${pathIn}/variables-ecz-steroids"

keep if date>=(d(01apr2006))
sort patid date
order patid date

*collapse on patid and date so there is one record per patient
collapse (firstnm) modsevere harmfulalcohol asthma sleep anxiety_all anxiety_censor steroids, by(patid date)

sort patid date

bysort patid: gen obs=_n
bysort patid: gen maxobs=_N
*check a patient id with complicated variables -chose 1017

local update " "modsevere" "harmfulalcohol" "asthma" "sleep" "anxiety_all" "anxiety_censor" "steroids" "

foreach a in `update' {
	gen state`a'=`a'
	replace state`a' = state`a'[_n-1] if 	/// set the `var' flag to the same as the record (i.e. previous date) before 
		state`a'==.	&						/// IF the flag is missing and
		patid == patid[_n-1] 				// IF this is same patient
} /*end foreach a in `toupdate' */

drop sleep modsevere harmfulalcohol asthma anxiety_all anxiety_censor steroids

rename statemodsevere modsevere
rename statesleep sleep
rename stateharmfulalcohol harmfulalcohol
rename stateasthma asthma
rename stateanxiety_all anxiety_all
rename stateanxiety_censor anxiety_censor
rename statesteroids steroids

drop obs maxobs

*save
save "${pathCohort}/sens1-ecz-anx-time-updated-variables", replace

log close
exit