/**********************************************************************
 Project: Working Hours and Unmet Medical Needs (KNHANES 2015–2023)
 Author: (anonymous)
 Purpose: 
   - Merge KNHANES data across years
   - Construct labor, health, and socioeconomic variables
   - Analyze the association between working hours and unmet medical care
   - Difference-in-Differences (DID) and Triple-Differences (DDD) analysis
 Notes:
   - Raw data were originally downloaded as SPSS (.sav) files
   - Converted to .dta using R (haven::read_sav, write_dta)
**********************************************************************/

clear all
set more off

*------------------------------------------------------------*
* Directory setup
*------------------------------------------------------------*
cd "C:\대학원\3학기\국건영"

* Korean encoding (for variable labels)
set locale_ui ko_KR
set locale_functions ko_KR

/**********************************************************************
 STEP 1. Define variables to keep
**********************************************************************/
local keepvars ///
    year ID sex age incm5 educ occp ///
    marri_1 region D_1_1 BP1 ///
    EC1_1 EC_occp EC_stt_1 EC_stt_2 EC_wht_0 EC_wht_23 ///
    EC_lgw_2 EC_lgw_4 EC_lgw_5 ///
    DI1_dg DI2_dg DE1_dg ///
    M_2_yr M_2_rs ///
    MH1_1 MO1_1 ///
    LQ4_00 wt_itvex wt_hs npins allownc region psu kstrata town_t

/**********************************************************************
 STEP 2. Initialize empty dataset for merging
**********************************************************************/
tempfile full_merged
save `full_merged', emptyok replace

/**********************************************************************
 STEP 3. Loop over survey years and append
**********************************************************************/
local years 15 16 17 18 19 20 21 22 23

foreach y of local years {

    use HN`y'_ALL.dta, clear

    * Generate survey year
    capture drop year
    gen year = 2000 + `y'

    * Ensure variables exist (if not, create as missing)
    foreach v in M_2_yr M_2_rs MH1_1 MO1_1 LQ4_00 {
        capture confirm variable `v'
        if _rc != 0 {
            gen `v' = .
            di in yellow "→ Year 20`y': variable `v' not found, created as missing"
        }
    }

    * Keep selected variables only
    keep `keepvars'

    * Append to cumulative dataset
    append using `full_merged'
    save `full_merged', replace
}

* Save merged dataset
save "C:\대학원\3학기\국건영\knhanes_merged_15_23.dta", replace

/**********************************************************************
 STEP 4. Variable construction
**********************************************************************/

* Weekly working hours group
gen workhour_5group = .
replace workhour_5group = 1  if EC_wht_23 < 20
replace workhour_5group = 2  if EC_wht_23 >= 20 & EC_wht_23 < 25
replace workhour_5group = 3  if EC_wht_23 >= 25 & EC_wht_23 < 30
replace workhour_5group = 4  if EC_wht_23 >= 30 & EC_wht_23 < 35
replace workhour_5group = 5  if EC_wht_23 >= 35 & EC_wht_23 < 40
replace workhour_5group = 6  if EC_wht_23 >= 40 & EC_wht_23 < 45
replace workhour_5group = 7  if EC_wht_23 >= 45 & EC_wht_23 < 50
replace workhour_5group = 8  if EC_wht_23 >= 50 & EC_wht_23 < 55
replace workhour_5group = 9  if EC_wht_23 >= 55 & EC_wht_23 < 60
replace workhour_5group = 10 if EC_wht_23 >= 60

label define workhour_5_lbl ///
    1 "0–19 hours" ///
    2 "20–24 hours" ///
    3 "25–29 hours" ///
    4 "30–34 hours" ///
    5 "35–39 hours" ///
    6 "40–44 hours" ///
    7 "45–49 hours" ///
    8 "50–54 hours" ///
    9 "55–59 hours" ///
    10 "60+ hours"
label values workhour_5group workhour_5_lbl

* Chronic disease indicator
gen has_chronic = (DI1_dg==1 | DI2_dg==1 | DE1_dg==1)

* Education recoding
replace educ = . if educ==88 | educ==99
replace educ = 1 if inlist(educ,1,2,3)
replace educ = 2 if educ==4
replace educ = 3 if educ==5
replace educ = 4 if inlist(educ,6,7)
replace educ = 5 if educ==8

label define educ_lbl ///
    1 "Elementary" ///
    2 "Middle school" ///
    3 "High school" ///
    4 "University" ///
    5 "Graduate school"
label values educ educ_lbl

* Gender
label define sex_lbl 1 "Male" 2 "Female"
label values sex sex_lbl

gen women = (sex==2)

* Marital status
gen married = (marri_1==1)

* Private health insurance
gen is_privins = (npins==1)

* Basic livelihood recipient
gen is_recipient = (allownc==10)

* Seoul residence
gen is_seoul = (region==1)

* Regular worker
gen is_regularw = (EC_wht_0==1)

* Economically active
gen is_worker = (EC1_1==1)

* Paid worker
gen is_paidworker = (EC_stt_1==1)

* Self-rated health
rename D_1_1 selfrep_hstatus
replace selfrep_hstatus = . if selfrep_hstatus==9

* Weekly working hours
rename EC_wht_23 workhour
replace workhour = . if workhour==999
replace workhour = 0 if workhour==888

* Activity limitation
gen capmove = (LQ4_00==1)

* Urban/rural
gen is_town = (town_t==1)

* Unmet medical care reason
gen unmet_reason = M_2_rs
replace unmet_reason = . if unmet_reason==99
replace unmet_reason = 0 if unmet_reason==88

* Sampling weight
rename wt_itvex weight

save "C:\대학원\국건영\knhanes_merged_15_23.dta", replace

/**********************************************************************
 STEP 5. Analysis sample restriction
**********************************************************************/
use "C:\대학원\국건영\knhanes_merged_15_23.dta", clear

keep if age >= 18
keep if is_worker == 1
drop if year > 2020   // exclude COVID period

* Survey design
svyset psu [pw=wt_hs], strata(kstrata) singleunit(centered)

* Unmet medical care
gen unmet_med = .
replace unmet_med = 1 if M_2_yr==1
replace unmet_med = 0 if inlist(M_2_yr,2,3)
label define unmet_lbl 0 "Met" 1 "Unmet"
label values unmet_med unmet_lbl
drop if unmet_med==.

/**********************************************************************
 STEP 6. Regression analysis
**********************************************************************/

* Control variables
local control_var ///
    i.women ib2.age_group i.married ib3.educ ///
    ib3.incm5 i.is_privins i.is_recipient ib2.occp ///
    i.is_seoul i.is_town i.has_chronic i.capmove

* Baseline logistic regression
svy: logit unmet_med i.workhour_5group `control_var'

* Interaction: working hours × chronic condition
local cross_control_var = subinstr("`control_var'", "i.has_chronic", "", .)
svy: logit unmet_med i.workhour_5group##i.has_chronic `cross_control_var'

/**********************************************************************
 STEP 7. Difference-in-Differences (DID)
**********************************************************************/

* Treatment: regular full-time workers
gen treat = (EC_stt_2==1 & is_regularw==1)

* Post period (2018 reform)
gen post = (year>=2018)

* DID model
svy: logit unmet_med i.treat##i.post `control_var'

* Triple differences by unmet reason
svy: logit unmet_med i.treat##i.post##i.unmet_reason `control_var'

/**********************************************************************
 STEP 8. Pre-trend check
**********************************************************************/
gen pretrend = year
replace pretrend = . if year > 2017

svy: reg workhour i.treat##c.pretrend ///
    i.women ib2.age_group i.married ib3.educ ///
    ib3.incm5 i.is_privins i.is_recipient ib2.occp ///
    i.is_seoul i.is_town i.has_chronic i.capmove

/**********************************************************************
 End of do-file
**********************************************************************/
