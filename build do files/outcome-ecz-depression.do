/*******************************************************************************
DO FILE NAME:			outcome-ecz-depression.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	28/06/22

TASK:					Aim is to create depression outcome variables
						(and censor variables) that will be used to build the
						cohort
						
DATASET(S)/FILES USED:	variables-ecz-depression-all
						variables-ecz-depression-definite
						variables-ecz-depression-censor
						eth-paths
						

DATASETS CREATED:		outcome-ecz-dep-definite
						outcome-ecz-dep-all
						outcome-ecz-dep-censor
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
global filename "outcome-depression"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
Create depression outcome variable for main analysis - definite depression
*******************************************************************************/
*load definite depression data for eczema cohort
use "${pathDatain}/variables-ecz-depression-definite.dta", clear

*check if there are duplicates 
duplicates report patid		// no duplicates
count if missing(eventdate) // no missing eventdates

*generate definite depression variable
gen depression=1
label variable depression "Definite depression diagnosis"
recode depression(.=0)

*create labels for the depression data
label define depressionlabel 0 "no" 1 "yes"
label values depression depressionlabel

*rename eventdate variable
rename eventdate date

*save the dataset
compress
save "${pathIn}/outcome-ecz-dep-definite", replace

/*******************************************************************************
Create censoring variable for main depression analysis - depression censor
*******************************************************************************/
*load censoring depression data for eczema cohort
use "${pathDatain}/variables-ecz-depression-censor.dta", clear

*check if there are duplicates 
duplicates report patid		// no duplicates
count if missing(eventdate) // no missing eventdates

*generate definite depression variable
gen depression_censor=1
label variable depression_censor "Censor depression analysis"
recode depression_censor(.=0)

*create labels for the depression_censor data
label define depressioncensorlabel 0 "no" 1 "yes"
label values depression_censor depressioncensorlabel

*rename eventdate variable
rename eventdate date

*save the dataset
compress
save "${pathIn}/outcome-ecz-dep-censor", replace

/*******************************************************************************
Create depression outcome variable for sensitivity analysis - all depression
*******************************************************************************/
*load all depression data for eczema cohort
use "${pathDatain}/variables-ecz-depression-all.dta", clear

*check if there are duplicates 
duplicates report patid		// no duplicates
count if missing(eventdate) // no missing eventdates

*generate definite depression variable
gen depression_all=1
label variable depression_all "All depression diagnosis"
recode depression_all(.=0)

*create labels for all the depression data
label define depressionalllabel 0 "no" 1 "yes"
label values depression_all depressionalllabel

*rename eventdate variable
rename eventdate date

*save the dataset
compress
save "${pathIn}/outcome-ecz-dep-all", replace

log close
exit