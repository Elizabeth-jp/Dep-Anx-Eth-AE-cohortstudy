/*******************************************************************************
DO FILE NAME:			outcome-ecz-anxiety.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	28/06/22

TASK:					Aim is to create anxiety outcome variables
						(and censor variables) that will be used to build the
						cohort
						
DATASET(S)/FILES USED:	variables-ecz-anxiety-all
						variables-ecz-anxiety-definite
						variables-ecz-anxiety-censor
						eth-paths
						

DATASETS CREATED:		outcome-ecz-anx-definite
						outcome-ecz-anx-all
						outcome-ecz-anx-censor
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
global filename "outcome-anxiety"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
Create anxiety outcome variable for main analysis - definite anxiety
*******************************************************************************/
*load definite anxiety data for eczema cohort
use "${pathDatain}/variables-ecz-anxiety-definite.dta", clear

*check if there are duplicates 
duplicates report patid		// no duplicates
count if missing(eventdate) // no missing eventdates

*generate definite anxiety variable
gen anxiety=1
label variable anxiety "Definite anxiety diagnosis"
recode anxiety(.=0)

*create labels for the anxiety data
label define anxietylabel 0 "no" 1 "yes"
label values anxiety anxietylabel

*rename eventdate variable
rename eventdate date

*save the dataset
compress
save "${pathIn}/outcome-ecz-anx-definite", replace

/*******************************************************************************
Create censoring variable for main anxiety analysis - anxiety censor
*******************************************************************************/
*load censoring anxiety data for eczema cohort
use "${pathDatain}/variables-ecz-anxiety-censor.dta", clear

*check if there are duplicates 
duplicates report patid		// no duplicates
count if missing(eventdate) // no missing eventdates

*generate definite anxiety variable
gen anxiety_censor=1
label variable anxiety_censor "Censor anxiety analysis"
recode anxiety_censor(.=0)

*create labels for the depression_censor data
label define anxietycensorlabel 0 "no" 1 "yes"
label values anxiety_censor anxietycensorlabel

*rename eventdate variable
rename eventdate date

*save the dataset
compress
save "${pathIn}/outcome-ecz-anx-censor", replace

/*******************************************************************************
Create anxiety outcome variable for sensitivity analysis - all anxiety
*******************************************************************************/
*load all anxiety data for eczema cohort
use "${pathDatain}/variables-ecz-anxiety-all.dta", clear

*check if there are duplicates 
duplicates report patid		// no duplicates
count if missing(eventdate) // no missing eventdates

*generate definite anxiety variable
gen anxiety_all=1
label variable anxiety_all "All anxiety diagnosis"
recode anxiety_all(.=0)

*create labels for all the anxiety data
label define anxietyalllabel 0 "no" 1 "yes"
label values anxiety_all anxietyalllabel

*rename eventdate variable
rename eventdate date

*save the dataset
compress
save "${pathIn}/outcome-ecz-anx-all", replace

log close
exit