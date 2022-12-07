/*******************************************************************************
DO FILE NAME:			variables-${ABBRVexp}-anxiety-all.do
AUTHOR:					Elizabeth Adesanya
VERSION:				v1
DATE VERSION CREATED: 	12/04/2021
TASK:					Aim is to create an anxety variable for the ${exposure} cohort
DATASET(S)/FILES USED:	${ABBRVexp}-Clinical-anxiety//${exposure} anxiety records from clinical file
						${ABBRVexp}-Referral-anxiety//${exposure} anxiety records from clinical file
						SkinEpiExtract-paths.do
						
DATASETS CREATED:	${ABBRVexp}-anxiety-all//definite and possible anxiety (sensitivity analysis)
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
global filename "variables-${ABBRVexp}-anxiety-all"

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
		codelist("${pathCodelists}/medcodes-anxiety-nohistory") /// 
		diagnosis(anxiety) ///
		savefile("${pathOut}/${ABBRVexp}-`filetype'-anxiety")
} /*end foreach file in Clinical Referral*/


/*******************************************************************************
#2. ALL
*******************************************************************************/
* append data sources
use "${pathOut}/${ABBRVexp}-Clinical-anxiety", clear
append using "${pathOut}/${ABBRVexp}-Referral-anxiety"

count if eventdate==.
*2,751 variables with missing eventdate

*deal with date variables
replace eventdate=sysdate if eventdate==. & medcode!=.

count if eventdate==.
*no variables with missing eventdate

*only keep first event for each patient
keep patid eventdate constype readcode readterm //only keep useful data
sort patid eventdate 
bysort patid: keep if _n==1

*label and save
label data "${exposure} - earliest definite or possible anxiety diagnosis"
notes: ${exposure} - earliest definite or possible anxiety diagnosis
notes: ${filename} / TS		
compress
save ${pathOut}/variables-${ABBRVexp}-anxiety-all, replace

/*******************************************************************************
#3. DEFINITE
*******************************************************************************/
* append data sources
use "${pathOut}/${ABBRVexp}-Clinical-anxiety", clear
append using "${pathOut}/${ABBRVexp}-Referral-anxiety"

*only keep CPRD records for definite anxiety 
drop if possibleanxiety==1

count if possibleanxiety==1 
*0 found

count if eventdate==.
*2,606 variables with missing eventdate

*deal with date variables
replace eventdate=sysdate if eventdate==. & medcode!=.

count if eventdate==.
*no variables with missing eventdate

*only keep first event for each patient
keep patid eventdate constype readcode readterm //only keep useful data
sort patid eventdate 
bysort patid: keep if _n==1

*label and save
label data "${exposure} - earliest definite anxiety diagnosis"
notes: ${exposure} - earliest definite anxiety diagnosis
notes: ${filename} / TS		
compress
save ${pathOut}/variables-${ABBRVexp}-anxiety-definite, replace

/*******************************************************************************
#4. CENSORED
*******************************************************************************/
* append data sources
use "${pathOut}/${ABBRVexp}-Clinical-anxiety", clear
append using "${pathOut}/${ABBRVexp}-Referral-anxiety"

*only keep censoring codes
keep if censoring==1

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
label data "${exposure} - diagnosis to censor at for anxiety outcome"
notes: ${exposure} - diagnosis to censor at for anxiety outcome
notes: ${filename} / TS		
compress
save ${pathOut}/variables-${ABBRVexp}-anxiety-censor, replace


// Clean up
cap erase "${pathOut}/${ABBRVexp}-Clinical-anxiety.dta"
cap erase "${pathOut}/${ABBRVexp}-Referral-anxiety.dta"

log close
exit