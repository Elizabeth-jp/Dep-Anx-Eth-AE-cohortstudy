/*******************************************************************************
DO FILE NAME:			appendix-ecz-anx-prophazards.do

AUTHOR:					Elizabeth Adesanya
						

VERSION:				v1
DATE VERSION CREATED: 	21/09/22

TASK:					Testing the proportional hazards assumption for the
						eczema anxiety cohort
						
DATASET(S)/FILES USED:	cohort-anx-ecz-main.dta
						

*******************************************************************************/
/*******************************************************************************
HOUSEKEEPING
*******************************************************************************/
capture log close
version 16
clear all
macro drop _all
set linesize 80

*change directory to the location of the paths file and run the file
run eth_paths

* create a filename global that can be used throughout the file
global filename "appendix-ecz-anx-prophazards"

*open log file
log using "${pathLogs}/${filename}", text replace 

/*******************************************************************************
TESTING THE ASSUMPTION on the confounder-adjusted model
*******************************************************************************/
*open analysis dataset
use "${pathCohort}/cohort-anx-ecz-main", clear

/*
As there is missing carstairs data:
Need to drop exposed individuals with missing data and any controls no longer
matched to an included case
This means that we'll have complete cases and will preserve matching
*/

*look for missing values of carstairs_deprivation
gen exposed_nm = (exposed<.)
gen carstairs_nm = (carstairs_deprivation<.)
gen complete = (exposed_nm==1 & carstairs_nm==1)
tab complete
tab complete exposed, col
keep if complete==1
drop complete

* Preserve matching, keep valid sets only
bysort setid: egen set_exposed_mean = mean(exposed)
gen valid_set = (set_exposed_mean>0 & set_exposed_mean<1) 
tab valid_set, miss
tab valid_set exposed, col
keep if valid_set==1
drop valid_set set_exposed_mean

*test separately for the white and minority ethnic groups

*white ethnic group 
stcox i.exposed i.calendarperiod i.carstairs_deprivation if ethnicity==1, strata(setid) level(95) base
estat phtest, detail
* p value is 0.9953 - there is no evidence that the proportional hazards assumption has been violated

*draw graph in white ethnic group 
*exposed
estat phtest, plot(1.exposed) bwidth(0.5) recast(scatter) mcolor(black) msize(small) msymbol(point) lineopts(lwidth(thin))
graph save "${pathResults}/appendix-ecz-anx-prophazards-white.gph",replace

*minority ethnic group
stcox i.exposed i.calendarperiod i.carstairs_deprivation if ethnicity==2, strata(setid) level(95) base
estat phtest, detail
* p value is 0.9381 - there is no evidence that the proportional hazards assumption has been violated

*draw graph in minority ethnic group 
*exposed
estat phtest, plot(1.exposed) bwidth(0.5) recast(scatter) mcolor(black) msize(small) msymbol(point) lineopts(lwidth(thin))
graph save "${pathResults}/appendix-ecz-anx-prophazards-minorityethnic.gph",replace

log close 
exit 
