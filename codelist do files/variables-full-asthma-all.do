/*******************************************************************************
DO FILE NAME:			variables-cluster-asthma.do
AUTHOR:					Elizabeth Adesanya
						
VERSION:				v1
DATE VERSION CREATED: 	04/06/2021
TASK:					Aim is to extract morbidity coded data for asthma
						and use it to create a asthma variable
						
DATASET(S)/FILES USED:	Clinical_extract_ecz_extract3_`x'//CPRD clinical extract files 1 to 2
						Referral_extract_ecz_extract3_`x'//CPRD referral extract files 1 
						definite_asthma_codes
						prog_getCodeCPRD
						skinepipaths
						
DATASETS CREATED:		variables-cluster-asthma
*******************************************************************************/
/*******************************************************************************
HOUSEKEEPING
*******************************************************************************/
capture log close
version 15
clear all
set linesize 80

*find path file location and run it
skinepipaths_v2

* create a filename global that can be used throughout the file
global filename "variables-${ABBRVexp}-asthma"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
#1. Extract data from files in the CPRD Clinical or Referral files
*******************************************************************************/
* run program
run ${pathPrograms}/prog_getCodeCPRD

filelist , dir(${pathOut}) pattern("variable-${ABBRVexp}-Clinical-asthma*")
if `r(N)' < 1 {
	foreach filetype in Clinical Referral {
		if "`filetype'"=="Clinical" {
			local nfiles=$totalClinicalFiles
		}
		if "`filetype'"=="Referral" {
			local nfiles=$totalReferralFiles
		} 
		prog_getCodeCPRD, clinicalfile("${pathIn}/`filetype'_extract_${ABBRVexp}_extract3") ///
			clinicalfilesnum(`nfiles') ///
			codelist("${pathCodelists}/definite_asthma_codes") /// 
			diagnosis(asthma) ///
			savefile("${pathOut}/variable-${ABBRVexp}-`filetype'-asthma")
	} /*end foreach file in Clinical Referral*/
}
/*******************************************************************************
#2. Append data from all sources and identify all asthma
*******************************************************************************/
* append data sources
use "${pathOut}/variable-${ABBRVexp}-Clinical-asthma", clear
append using "${pathOut}/variable-${ABBRVexp}-Referral-asthma"

count if eventdate==.

*deal with date variables
replace eventdate=sysdate if eventdate==. & medcode!=.

count if eventdate==.
*no variables with missing eventdate

*only keep first event for each patient
keep patid eventdate //only keep useful data
sort patid eventdate 
bysort patid: keep if _n==1

*label and save
label data "${exposure} cohort - earliest asthma diagnosis"
notes: earliest asthma diagnosis
notes: ${filename} / TS		
compress
save ${pathOut}/variables-${ABBRVexp}-asthma, replace

/*******************************************************************************
#3. Erase interim datasets
*******************************************************************************/
cap erase ${pathOut}/variable-${ABBRVexp}-Clinical-asthma.dta
cap erase ${pathOut}/variable-${ABBRVexp}-Referral-asthma.dta

log close
exit