/*
NOTES: This dofile creates the firm-level analysis dataset
Author: Michael Kilumelume 
Last updated: 21.01.2022 
*/

 cap log close 
 log using "$log_save\create_firm_level", replace 

use "$saveaddress_data\merged_ind_panel", clear 
cap drop n 
cap drop n_id 
egen n_id=group(id_new)
cap drop n_fid 
egen n_fid=group(taxrefno) 
*Code from Marlies 
gen totalperiodsinyearofassessment1 = subinstr(totalperiodsinyearofassessment, ".", " ", .)
cap drop totpy 
destring totalperiodsinyearofassessment1 , gen(totpy) force 
gen totalperiodsworked1 = subinstr(totalperiodsworked, ".", " ", .)
cap drop totpwork 
destring totalperiodsworked1, gen(totpwork) force 

replace totpy=abs(totpy)
replace totpwork=abs(totpwork)
   
gen frac=totpwork/totpy
	
	
gen totpy_annual=totpy
replace totpy_annual=totpy*2 if totpy==26 
gen frac_annual= totpwork/totpy_annual
	 
* create monthly earnings 
gen monthly_earnings=(a3601_income/frac)/12

*create total wages per firm
bys n_fid taxyear: egen double tot_3601 = total(a3601_income) 
bys n_fid taxyear: egen double tot_kerr = total(kerr_income) if kerr_emp_inc==1 
	
*identify minimum wage workers (workers earning below 2274 in 2012)
sort id_new taxyear 
br id_new taxyear monthly_earnings 
drop if id_new == ""
cap drop mw_worker_2012 
gen mw_worker_2012 = monthly_earnings<2274 & taxyear ==2013 
	
cap drop mw_worker_2012_tg 
by id_new: egen mw_worker_2012_tg = max(mw_worker_2012)
	
* number of workers in firm 
bysort n_fid taxyear: egen firm_size=count(n_id)
	
*gen fraction affected - which min wage value to take?
cap drop FA 
bysort n_fid taxyear: egen FA=count(n_id) if monthly_earnings<2274
cap drop mw_count_2012
gen mw_count_2012 = FA if taxyear == 2013
replace mw_count_2012 = 0 if mw_count_2012 ==. 
cap drop mw_count_2013
gen mw_count_2013 = FA if taxyear == 2014
replace mw_count_2013 = 0 if mw_count_2013==. 
	
cap drop mw_count_2012_tag 
bys taxrefno: egen mw_count_2012_tag = max(mw_count_2012)
	
cap drop mw_count_2013_tag 
bys taxrefno: egen mw_count_2013_tag = max(mw_count_2013)
	
*Compliance is the proportion of minimum wage workers who recieved and the minimum wage 
cap drop compliance 
gen compliance = mw_count_2013_tag/mw_count_2012_tag
	
tab taxyear 
	
br id_new taxyear FA mw_count_2012 

gen fraction_affected=FA/firm_size
egen prop_affected=max(fraction_affected),by(n_fid taxyear)
replace prop_affected=0 if prop_affected==. & FA==.

bro n_id n_fid taxyear FA fraction_affected prop_affected
cap drop  prop_affected_2012 
gen  prop_affected_2012  =0 
replace prop_affected_2012 = prop_affected if taxyear==2013 
cap drop fa_use 
bys taxrefno: egen fa_use = max(prop_affected_2012)
	
cap drop n_fid 
egen n_fid = group(taxrefno)

cap drop n 
bys n_fid taxyear : gen n = _n 


keep if n ==1 
cap drop n 
tab taxyear 
*SAVE ANALYSIS DATASET. 
save  "$saveaddress_data\analysis_firm.dta", replace 

cap log close 