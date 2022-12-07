/*******************************************************************************
DO FILE NAME:			variables-${ABBRVexp}-depression-all.do
AUTHOR:					Elizabeth Adesanya
VERSION:				v1
DATE VERSION CREATED: 	12/04/2021
TASK:					Aim is to create a depression variable for the ${exposure} cohort
DATASET(S)/FILES USED:	${ABBRVexp}-Clinical-depression//${exposure} anxiety records from clinical file
						${ABBRVexp}-Referral-depression//${exposure} anxiety records from clinical file
						SkinEpiExtract-paths.do
						
DATASETS CREATED:	${ABBRVexp}-depression-all//definite and possible depression (sensitivity analysis)
*******************************************************************************/
/*******************************************************************************
HOUSEKEEPING
*******************************************************************************/
capture log close
version 15
clear all
set linesize 80

* change directory to the location of the paths file and run the file	
skinepipaths_v2

* create a filename global that can be used throughout the file
global filename "variables-${ABBRVexp}-depression-all"

*open log file
log using "${pathLogs}/${filename}", text replace 
/*******************************************************************************
#1. Extract data from files in the CPRD Clinical or Referral files
*******************************************************************************/
* run program
run ${pathPrograms}/prog_getCodeCPRD

foreach filetype in Clinical Referral {
	if "`filetype'"=="Clinical" {
		local nfiles=$totalClinicalFiles
	}
	if "`filetype'"=="Referral" {
		local nfiles=$totalReferralFiles
	} 
	prog_getCodeCPRD, clinicalfile("${pathIn}/`filetype'_extract_${ABBRVexp}_extract3") ///
		clinicalfilesnum(`nfiles') ///
		codelist("${pathCodelists}/medcodes-depression-nohistory") /// 
		diagnosis(depression) ///
		savefile("${pathOut}/${ABBRVexp}-`filetype'-depression")
} /*end foreach file in Clinical Referral*/

/*******************************************************************************
#1. Append ${exposure} anxiety data from all sources
*******************************************************************************/
* append data sources
use "${pathOut}/${ABBRVexp}-Clinical-depression", clear
append using "${pathOut}/${ABBRVexp}-Referral-depression"

count if eventdate==.

*deal with date variables
replace eventdate=sysdate if eventdate==. & medcode!=.

count if eventdate==.
*no variables with missing eventdate

*only keep first event for each patient
keep patid eventdate constype readcode readterm //only keep useful data
sort patid eventdate 
bysort patid: keep if _n==1

*label and save
label data "${exposure} - earliest definite or possible depression diagnosis"
notes: ${exposure} - earliest definite or possible depression diagnosis
notes: ${filename} / TS		
compress
save ${pathOut}/variables-${ABBRVexp}-depression-all, replace


/*******************************************************************************
#1. CENSORING
*******************************************************************************/
* append data sources
use "${pathOut}/${ABBRVexp}-Clinical-depression", clear
append using "${pathOut}/${ABBRVexp}-Referral-depression"

*only keep censoring codes
keep if censoring==1

count if eventdate==.

*deal with date variables
replace eventdate=sysdate if eventdate==. & medcode!=.

count if eventdate==.
*no variables with missing eventdate

*only keep first event for each patient
keep patid eventdate constype readcode readterm   //only keep useful data
sort patid eventdate 
bysort patid: keep if _n==1

*label and save
label data "${exposure} - diagnosis to censor at for depression outcome"
notes: ${exposure} - diagnosis to censor at for depression outcome
notes: ${filename} / TS		
compress
save ${pathOut}/variables-${ABBRVexp}-depression-censor, replace

/*******************************************************************************
#1. definite
*******************************************************************************/
* append data sources
use "${pathOut}/${ABBRVexp}-Clinical-depression", clear
append using "${pathOut}/${ABBRVexp}-Referral-depression"

*only keep CPRD records for definite anxiety 
drop if possibledepression==1

count if eventdate==.

*deal with date variables
replace eventdate=sysdate if eventdate==. & medcode!=.

count if eventdate==.
*no variables with missing eventdate

*only keep first event for each patient
keep patid eventdate constype readcode readterm   //only keep useful data
sort patid eventdate 
bysort patid: keep if _n==1

*label and save
label data "${exposure} - earliest definite depression diagnosis"
notes: ${exposure} - earliest definite depression diagnosis
notes: ${filename} / TS		
compress
save ${pathOut}/variables-${ABBRVexp}-depression-definite, replace


// Clean up
cap erase "${pathOut}/${ABBRVexp}-Clinical-depression.dta"
cap erase "${pathOut}/${ABBRVexp}-Referral-depression.dta"

log close
exit