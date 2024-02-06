** See full IRP5 dataset that created this firm level data
** this only includes stats on agri firms
** Question: Did the min wage shock affect new hires & number of exits?


	clear all 
	cap log close 

	gl D : di %tdCYND daily("$S_DATE", "DMY") 										

	use "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\firm_level_entry_exit.dta"
	log using "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\firm_level_entry_exit_analysis.smcl", replace 
	cd "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)"
	cap drop if taxrefno==""
	
	// Merge in the CIT indicators
		
merge 1:1 taxrefno taxyear using "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Full_CIT_sample_cleaned.dta", gen(merge_CIT) 	
	
	gegen fid=group(taxrefno)
	xtset fid taxyear
	
	egen years_alive=count(taxyear), by(fid)
	tab years_alive merge_CIT
	
	tsfill, full // we need to do this so that we can move up exit figures by a year
	
	label variable entry_agri "Number of entrants into agri by firm"
	label variable exit_agri "Number of exits out of agri by firm"
	 
	gen mode_prov_num=1 if mode_prov=="Eastern Cape"
	replace mode_prov_num=2 if mode_prov=="Free State"
	replace mode_prov_num=3 if mode_prov=="Gauteng"
	replace mode_prov_num=4 if mode_prov=="KwaZulu-Natal"
	replace mode_prov_num=5 if mode_prov=="Limpopo"
	replace mode_prov_num=6 if mode_prov=="Mpumalanga"
	replace mode_prov_num=7 if mode_prov=="North West"
	replace mode_prov_num=8 if mode_prov=="Northern Cape"
	replace mode_prov_num=9 if mode_prov=="Western Cape"
	
	tab mode_prov_num
	label define prov 1 "Eastern Cape" 2 "Free State" 3 "Gauteng" 4 "KwaZulu-Natal" 5 "Limpopo" 6 "Mpumalanga" 7 "North West" 8 "Northern Cape" 9 "Western Cape"
	label values mode_prov_num prov 
	tab mode_prov_num
	
	summ frac if agri==1, de // p25 at 63%, median is at 85% 
	label variable frac "Employee's fraction of year worked, averaged by firm & year" 
	
	/*
	gen frac_cat=1 if frac<0.66
	replace frac_cat=2 if frac>0.65 & frac!=.
	label define frac_cat_label 1 "<0.66% of the year" 2 ">0.65% of the year"
	label values frac_cat frac_cat_label 
	tab frac_cat
	
	xttrans frac_cat
	xttrans frac_cat if taxyear >2012 & taxyear<2015
	xttrans frac_cat if taxyear >2012 & taxyear<2016
	*/

********************************************************************************
* 				Firm wage gaps & treatment indicators							*
********************************************************************************
	drop if agri==0 // these firms are non-agri
	
	gen l_leg_min_w_2014=l_leg_r_min_wage if taxyear==2014
	gegen l_leg_min_w_2014_a=max(l_leg_min_w_2014)
	drop l_leg_min_w_2014
	
	/*
	
	gen l_mean_firm_wage=ln(mean_firm_wage)
	gen l_median_firm_wage=ln(median_firm_wage)

* Wagegap based on firm's mean wage in 2013
	gen wagegap_mean_wage=l_leg_min_w_2014_a-l_mean_firm_wage if taxyear==2013
	replace wagegap_mean_wage= 0 if wagegap_mean_wage<0
	gegen wagegap_mean_all=max(wagegap_mean_wage), by(fid)
	label variable wagegap_mean_all "Firm wage gap based on firm's mean wage 2013 taxyear"
	
* Wagegap based on firm's median wage in 2013
	gen wagegap_median_wage=l_leg_min_w_2014_a-l_median_firm_wage if taxyear==2013
	replace wagegap_median_wage= 0 if wagegap_median_wage<0
	gegen wagegap_median_all=max(wagegap_median_wage), by(fid)
	label variable wagegap_median_all "Firm wage gap based on firm's median wage 2013 taxyear"
	
* Treated vs non treated
	gen treated=1 if prop_affected_all>0 & prop_affected_all!=. 
	replace treated=0 if prop_affected_all==0 
	label variable treated "Firm has at least one affected worker"
	*/
	
* Treatment indicator (proportion of workers affected in 2013)
	gegen prop_affected_all=max(prop_affected), by(fid)
	label variable prop_affected_all "Proportion of workers in 2013 that earned below the 2014 min wage"

	
********************************************************************************
* 								Entry & exit stats								*
********************************************************************************
	table taxyear, cont(sum entry_agri sum exit_agri2)

	replace entry_agri=. if taxyear==2011 // first year of panel, thus all entered 2011
	table taxyear, cont(sum entry_agri sum exit_agri2)

* exit_agri2 was defined in the year the person was last seen in agri but actually, this should 
* be 1 in the year after their last year; thus we want to move exit_agri2 one year later

	gen exit_agri_new=.
	replace exit_agri_new= L.exit_agri2 if fid==L.fid
	
	table taxyear, cont(sum entry_agri sum exit_agri_new)

/*
* log transformation
	gen entry_agri_trans=entry_agri+0.00001
	gen l_entry_agri=ln(entry_agri_trans)
	
	gen exit_agri_trans=exit_agri2+0.00001
	gen l_exit_agri=ln(exit_agri_trans)
	
	gen exit_agri_new_trans=exit_agri_new+0.00001
	gen l_exit_agri_new_trans=ln(exit_agri_new_trans)
*/
	
	gen post=0 if taxyear<2014
	replace post=1 if taxyear>2013
	
********************************************************************************
* 									Stats on zeros 								*
********************************************************************************
tab taxyear 
tab taxyear if mean_firm_wage!=.
tab taxyear if entry_agri==0 // 20% in 2012, 26% in 2017

tab taxyear if exit_agri_new==0 // 21% in 2012, 23% in 2017


********************************************************************************
* 								Regression analysis								*
********************************************************************************

/*
Run for CIT and non-CIT samples:
- survivors (present in all years 2011-2017)
- unbalanced (present for less than 7 years)
*/


* Negative ninomial
	* using proportion affected (prop_affected_all) as the treatment variable 
	* add offset variable (firm size: either in 2013 or dynamically)
	
********************************************************************************
* 							Total employment									*
********************************************************************************
	preserve 
	keep if merge_CIT==3 & years_alive==7 // CIT survivors
	
	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) 
	estimates store reg6
	estout reg* using total_empl_no_restriction_no_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


* prop_affected_all - using dynamic firm size as an offset variable // all coef are essentially 0
	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg6
	estout reg* using total_empl_no_restriction_dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* prop_affected_all - using LAGGED dynamic firm size as an offset variable 

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	estout reg* using total_empl_no_restriction_L.dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg6, vertical drop(_cons ln(L.firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Employment) scheme(plotplain) msymbol(O) title(Employment treatment effects ) yline(0)
	
	graph export "Empl_CIT_survivors.png", replace
	graph save "Empl_CIT_survivors.gph", replace 
********************************************************************************
* 									Entry										*
********************************************************************************
* prop_affected_all
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno)  
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno)
	
/*	
* prop_affected_all - using 2013 firm size as an offset variable 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
*/
	
* prop_affected_all - using dynamic firm size as an offset variable 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store entry_no_restriction
	estout entry_no_restriction using entry_no_restriction_dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot entry_no_restriction, vertical drop(_cons ln(firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Entry) scheme(plotplain) msymbol(O) title(Entry treatment effects ) yline(0)
	
	graph export "Entry_CIT_survivors.png", replace
	graph save   "Entry_CIT_survivors.gph", replace 

		
********************************************************************************
* 									Exit										*
********************************************************************************
	
	* prop_affected_all
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno)  
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno)

/*	
* prop_affected_all - using 2013 firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
*/

* prop_affected_all - using dynamic firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	
* prop_affected_all - using LAGGED dynamic firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
	estimates store exit_no_restriction
	estout exit_no_restriction using exit_no_restriction_L.dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	
* coef plot - full model with dynamic offset variable
	coefplot exit_no_restriction, vertical drop(_cons ln(L.firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Exit) scheme(plotplain) msymbol(O) title(Exit treatment effects ) yline(0)
	
	graph export "Exit_CIT_survivors.png", replace
	graph save   "Exit_CIT_survivors.gph", replace 
	
	restore
	
********************************************************************************
* 							Total employment									*
********************************************************************************
	preserve 
	keep if merge_CIT==1 & years_alive==7 // these are the non-CIT firms that are in the panel for all 7 years 
	
	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) 
	estimates store reg6
	estout reg* using total_empl_no_restriction_no_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


* prop_affected_all - using dynamic firm size as an offset variable // all coef are essentially 0
	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg6
	estout reg* using total_empl_no_restriction_dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* prop_affected_all - using LAGGED dynamic firm size as an offset variable 

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	estout reg* using total_empl_no_restriction_L.dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg6, vertical drop(_cons ln(L.firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Employment) scheme(plotplain) msymbol(O) title(Employment treatment effects ) yline(0)
	
	graph export "Empl_non_CIT_survivors.png", replace
	graph save "Empl_non_CIT_survivors.gph", replace 
********************************************************************************
* 									Entry										*
********************************************************************************
* prop_affected_all
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno)  
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno)
	
/*	
* prop_affected_all - using 2013 firm size as an offset variable 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
*/
	
* prop_affected_all - using dynamic firm size as an offset variable 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store entry_no_restriction
	estout entry_no_restriction using entry_no_restriction_dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot entry_no_restriction, vertical drop(_cons ln(firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Entry) scheme(plotplain) msymbol(O) title(Entry treatment effects ) yline(0)
	
	graph export "Entry_non_CIT_survivors.png", replace
	graph save   "Entry_non_CIT_survivors.gph", replace 

		
********************************************************************************
* 									Exit										*
********************************************************************************
	
	* prop_affected_all
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno)  
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno)

/*	
* prop_affected_all - using 2013 firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
*/

* prop_affected_all - using dynamic firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	
* prop_affected_all - using LAGGED dynamic firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
	estimates store exit_no_restriction
	estout exit_no_restriction using exit_no_restriction_L.dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	
* coef plot - full model with dynamic offset variable
	coefplot exit_no_restriction, vertical drop(_cons ln(L.firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Exit) scheme(plotplain) msymbol(O) title(Exit treatment effects ) yline(0)
	
	graph export "Exit_non_CIT_survivors.png", replace
	graph save "Exit_non_CIT_survivors.gph", replace 
	
	restore

********************************************************************************
* 							Total employment									*
********************************************************************************
	preserve 
	keep if merge_CIT==3 & years_alive<7 // CIT, unbalanced 
	
	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) 
	estimates store reg6
	estout reg* using total_empl_no_restriction_no_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


* prop_affected_all - using dynamic firm size as an offset variable // all coef are essentially 0
	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg6
	estout reg* using total_empl_no_restriction_dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* prop_affected_all - using LAGGED dynamic firm size as an offset variable 

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	estout reg* using total_empl_no_restriction_L.dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg6, vertical drop(_cons ln(L.firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Employment) scheme(plotplain) msymbol(O) title(Employment treatment effects ) yline(0)
	
	graph export "Empl_CIT_unbalanced.png", replace
	graph save "Empl_CIT_unbalanced.gph", replace 
********************************************************************************
* 									Entry										*
********************************************************************************
* prop_affected_all
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno)  
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno)
	
/*	
* prop_affected_all - using 2013 firm size as an offset variable 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
*/
	
* prop_affected_all - using dynamic firm size as an offset variable 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store entry_no_restriction
	estout entry_no_restriction using entry_no_restriction_dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot entry_no_restriction, vertical drop(_cons ln(firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Entry) scheme(plotplain) msymbol(O) title(Entry treatment effects ) yline(0)
	
	graph export "Entry_CIT_unbalanced.png", replace
	graph save   "Entry_CIT_unbalanced.gph", replace 

		
********************************************************************************
* 									Exit										*
********************************************************************************
	
	* prop_affected_all
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno)  
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno)

/*	
* prop_affected_all - using 2013 firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
*/

* prop_affected_all - using dynamic firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	
* prop_affected_all - using LAGGED dynamic firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
	estimates store exit_no_restriction
	estout exit_no_restriction using exit_no_restriction_L.dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	
* coef plot - full model with dynamic offset variable
	coefplot exit_no_restriction, vertical drop(_cons ln(L.firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Exit) scheme(plotplain) msymbol(O) title(Exit treatment effects ) yline(0)
	
	graph export "Exit_CIT_unbalanced.png", replace
	graph save   "Exit_CIT_unbalanced.gph", replace 
	
	restore
	
********************************************************************************
* 							Total employment									*
********************************************************************************
	preserve 
	keep if merge_CIT==1 & years_alive<7 // non-CIT unbalanced 
	
	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) 
	estimates store reg6
	estout reg* using total_empl_no_restriction_no_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


* prop_affected_all - using dynamic firm size as an offset variable // all coef are essentially 0
	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store reg6
	estout reg* using total_empl_no_restriction_dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* prop_affected_all - using LAGGED dynamic firm size as an offset variable 

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	estout reg* using total_empl_no_restriction_L.dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg6, vertical drop(_cons ln(L.firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Employment) scheme(plotplain) msymbol(O) title(Employment treatment effects ) yline(0)
	
	graph export "Empl_non_CIT_unbalanced.png", replace
	graph save "Empl_non_CIT_unbalanced.gph", replace 
********************************************************************************
* 									Entry										*
********************************************************************************
* prop_affected_all
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno)  
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno)
	
/*	
* prop_affected_all - using 2013 firm size as an offset variable 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
*/
	
* prop_affected_all - using dynamic firm size as an offset variable 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	estimates store entry_no_restriction
	estout entry_no_restriction using entry_no_restriction_dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot entry_no_restriction, vertical drop(_cons ln(firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Entry) scheme(plotplain) msymbol(O) title(Entry treatment effects ) yline(0)
	
	graph export "Entry_non_CIT_unbalanced.png", replace
	graph save   "Entry_non_CIT_unbalanced.gph", replace 

		
********************************************************************************
* 									Exit										*
********************************************************************************
	
	* prop_affected_all
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno)  
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno)

/*	
* prop_affected_all - using 2013 firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_2013_fill)
*/

* prop_affected_all - using dynamic firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
	
* prop_affected_all - using LAGGED dynamic firm size as an offset variable 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill , cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
	estimates store exit_no_restriction
	estout exit_no_restriction using exit_no_restriction_L.dyn_offset.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2 N ,fmt(3 0 0 0) label ("R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	
* coef plot - full model with dynamic offset variable
	coefplot exit_no_restriction, vertical drop(_cons ln(L.firm_size_year) prop_affected_all *.taxyear prop_male_fill prop_female_fill prop_age_cat_1_fill prop_age_cat_2_fill prop_age_cat_3_fill prop_age_cat_4_fill *.mode_prov_num) ///
	coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	ytitle(Exit) scheme(plotplain) msymbol(O) title(Exit treatment effects ) yline(0)
	
	graph export "Exit_non_CIT_unbalanced.png", replace
	graph save "Exit_non_CIT_unbalanced.gph", replace 
	
	restore	
	
	log close 
	
	
