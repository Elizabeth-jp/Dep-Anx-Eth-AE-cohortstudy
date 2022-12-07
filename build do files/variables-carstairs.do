/*******************************************************************************
DO FILE NAME:			variables-carstairs.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	28/06/22

TASK:					Aim is to create carstairs ddeprivation variable
						from linked data
						
DATASET(S)/FILES USED:	patient_carstairs_20_051.txt
						practice_carstairs_20_051.txt
						eth-paths.do
						

DATASETS CREATED:		variables-patient-carstairs
						variables-practice-carstairs
						
*******************************************************************************/
/*******************************************************************************
HOUSEKEEPING
*******************************************************************************/
capture log close
clear all
set linesize 80

*change directory to the location of the paths file and run the file
run eth_paths

* create a filename global that can be used throughout the file
global filename "variables-linkage"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
Create carstairs variables
*******************************************************************************/
import delimited "${pathLinkage}/patient_carstairs_20_051.txt", clear

rename carstairs2011_5 patient_carstairs 

/*
Carstairs scores are in quintiles
1 being the least deprived and 5 the most deprived
*/

*save the dataset
compress
save "${pathIn}/variables-patient-carstairs", replace

import delimited "${pathLinkage}/practice_carstairs_20_051.txt", clear
rename carstairs2011_5 practice_carstairs
drop country

*save the dataset
compress
save "${pathIn}/variables-practice-carstairs", replace

log close
exit
