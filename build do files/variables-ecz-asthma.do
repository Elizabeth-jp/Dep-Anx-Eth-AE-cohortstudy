/*******************************************************************************
DO FILE NAME:			variables-ecz-asthma.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	12/07/22

TASK:					Aim is to create asthma variable
						
DATASET(S)/FILES USED:	variables-ecz-asthma
						eth-paths
						

DATASETS CREATED:		variables-ecz-asthma
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
global filename "variables-asthma"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
Create asthma variable
*******************************************************************************/
*load asthma data for eczema cohort
use "${pathDatain}/variables-ecz-asthma.dta", clear

*check if there are duplicates 
duplicates report patid		// no duplicates

*generate asthma variable
gen asthma=1
label variable asthma "Asthma comorbidity"
recode asthma(.=0)

*create labels for the anxiety data
label define asthmalabel 0 "no" 1 "yes"
label values asthma anxietylabel

*rename eventdate variable
rename eventdate date

*save the dataset
compress
save "${pathIn}/variables-ecz-asthma", replace

log close
exit