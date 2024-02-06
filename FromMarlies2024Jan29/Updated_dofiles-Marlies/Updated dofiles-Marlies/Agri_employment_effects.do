** See full IRP5 dataset that created this firm level data
** this only includes stats on agri firms
** Question: Did the min wage shock affect new hires & number of exits?
** Merge with Kilumelume sample to identify where employment change differences arise
** 29 Jan 2024

	clear all 
	cap log close 

	gl D : di %tdCYND daily("$S_DATE", "DMY") 
	

	use "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\firm_level_entry_exit.dta"
	log using "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\firm_level_entry_exit_analysis.smcl", replace 
	cd "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)"
	cap drop if taxrefno==""
	
// Merge in the CIT indicators from MK sample
		
	merge 1:1 taxrefno taxyear using "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Full_CIT_sample_cleaned.dta", gen(merge_CIT) 	
	
	gegen fid=group(taxrefno)
	xtset fid taxyear
	
	egen years_alive=count(taxyear), by(fid)
	egen firm_year_entry=min(taxyear), by(fid)
	egen firm_year_exit=max(taxyear), by(fid)
	
	gen non_survivor=0
	replace non_survivor=1 if firm_year_exit==2014 | firm_year_exit==2015 | firm_year_exit==2016  
	
	gen survivor=0 
	replace survivor=1 if years_alive==7 
	replace survivor=1 if firm_year_entry==2012 & years_alive==6
	
	tab years_alive merge_CIT
	
	tsfill, full // we need to do this so that we can move up exit figures by a year
	
	label variable entry_agri "Number of entrants into agri by firm"
	label variable exit_agri "Number of exits out of agri by firm"
	
// Merge in rainfall data and clean province info
	
	merge m:1 taxyear mode_prov using "Z:\Workbenches\widerinequality\marlies_piek\updated_employment_paper\out_files\2022\_20220204\Rainfall_data_merge_ready.dta" 

	 
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
	
	
********************************************************************************
* 				Fraction affected, wage gaps & treatment indicators							*
********************************************************************************
	
	summ frac if agri==1, de // p25 at 63%, median is at 85% 
	label variable frac "Employee's fraction of year worked, averaged by firm & year" 

	drop if agri==0 // these firms are non-agri
	
	gen l_leg_min_w_2014=l_leg_r_min_wage if taxyear==2014
	gegen l_leg_min_w_2014_a=max(l_leg_min_w_2014)
	drop l_leg_min_w_2014
	
	
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
    sort fid taxyear 
	gen exit_agri_new=.
	replace exit_agri_new= L.exit_agri2 if fid==L.fid
	
	table taxyear, cont(sum entry_agri sum exit_agri_new)

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
* Negative ninomial
	* using proportion affected (prop_affected_all) as the treatment variable 
	* using offset variable (firm size: either in 2013 or dynamically)

/*
Run for CIT and non-CIT samples:
- survivors (present in all years 2011-2017)
- unbalanced (present for less than 7 years)
*/


**# Reg analysis: CIT Survivors
	
********************************************************************************
* 		Total employment - using LAGGED dynamic firm size as an offset variable	*
********************************************************************************
	cap mkdir "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\CIT Survivors"
	cd "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\CIT Survivors"
	preserve 
	keep if merge_CIT==3 & survivor==1 // CIT survivors
	
* nbreg unweighted

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  rainfall, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg7
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg8
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using nb_empl_uw_CIT_Survivor.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

	* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg8, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all)  coeflabels(2012.taxyear#c.prop_affected_all = "-2" 2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" 2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2))  baselevels omitted nolabel xtitle(Event time) /*ytitle(Interaction coefficient)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks) 
	
	graph export "nb_empl_uw_CIT_Survivor.png", replace as(png)
	graph save "nb_empl_uw_CIT_Survivor.gph", replace 
	
* nbreg weighted

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_*  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  rainfall  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg7
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg8
summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using nb_empl_w_CIT_Survivor.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg8, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" 2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" 2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) baselevels omitted nolabel xtitle(Event time) /*ytitle(Interaction coefficient)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks) 
	
	graph export "nb_empl_w_CIT_Survivor.png", replace as(png)
	graph save "nb_empl_w_CIT_Survivor.gph", replace 

********************************************************************************
* 									Entry										*
********************************************************************************
*nbreg unweighted
	estimates clear
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg1 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg2
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg3
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg4
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg5
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_entr_uw_CIT_Survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" 2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" 2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) baselevels omitted nolabel xtitle(Event time) /*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_entr_uw_CIT_Survivor.png", replace
	graph save "nb_entr_uw_CIT_Survivor.gph", replace 

	
*nbreg weighted
	estimates clear
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg1 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill [pw=firm_size_year] , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg2
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg3
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* [pw=firm_size_year] , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg4
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg5
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_entr_w_CIT_Survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" 2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" 2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) baselevels omitted nolabel xtitle(Event time) /*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_entr_w_CIT_Survivor.png", replace
	graph save "nb_entr_w_CIT_Survivor.gph", replace 
	

		
********************************************************************************
* 									Exit										*
********************************************************************************
	
*nbreg unweighted
	estimates clear
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg1 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg2
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg3
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg4
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg5
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_exit_uw_CIT_Survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" 2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" 2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) baselevels omitted nolabel xtitle(Event time) /*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_exit_uw_CIT_Survivor.png", replace
	graph save "nb_exit_uw_CIT_Survivor.gph", replace 

	
*nbreg weighted
	estimates clear
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg1 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill [pw=firm_size_year] , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg2
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg3
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* [pw=firm_size_year] , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg4
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg5
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_exit_w_CIT_Survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" 2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" 2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) baselevels omitted nolabel xtitle(Event time) /*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_exit_w_CIT_Survivor.png", replace
	graph save "nb_exit_w_CIT_Survivor.gph", replace 
	
	restore
	
**# Reg analysis: Non CIT Survivors
	
********************************************************************************
* 							Total employment									*
********************************************************************************
	cap mkdir "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\Non CIT Survivors"
	cd "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\Non CIT Survivors"

	preserve 
	keep if merge_CIT==1 & survivor==1 // these are the non-CIT firms that are in the panel for all 7 years 

* nbreg unweighted

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  rainfall, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg7
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg8
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using nb_empl_uw_non_NON_CIT_Survivor.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


	* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg8, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" 2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" 2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) baselevels omitted nolabel xtitle(Event time) /*ytitle(Interaction coefficient)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks) 
	
	graph export "nb_empl_uw_NON_CIT_Survivor.png", replace as(png)
	graph save "nb_empl_uw_NON_CIT_Survivor.gph", replace 
	
* nbreg weighted

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_*  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  rainfall  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg7
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg8
summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using nb_empl_w_NON_CIT_Survivor.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg8, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" 2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" 2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) baselevels omitted nolabel xtitle(Event time) /*ytitle(Interaction coefficient)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks) 
	
	graph export "nb_empl_w_NON_CIT_Survivor.png", replace as(png)
	graph save "nb_empl_w_NON_CIT_Survivor.gph", replace 

********************************************************************************
* 									Entry										*
********************************************************************************
*nbreg unweighted
	estimates clear
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg1 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg2
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg3
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg4
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg5
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_entr_uw_NON_CIT_Survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_entr_uw_NON_CIT_Survivor.png", replace
	graph save "nb_entr_uw_NON_CIT_Survivor.gph", replace 

	
*nbreg weighted
	estimates clear
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg1 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill [pw=firm_size_year] , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg2
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg3
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* [pw=firm_size_year] , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg4
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg5
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_entr_w_NON_CIT_Survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_entr_w_NON_CIT_Survivor.png", replace
	graph save "nb_entr_w_NON_CIT_Survivor.gph", replace 
	

		
********************************************************************************
* 									Exit										*
********************************************************************************
	
*nbreg unweighted
	estimates clear
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg1 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg2
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg3
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg4
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg5
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_exit_uw_NON_CIT_Survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_exit_uw_NON_CIT_Survivor.png", replace
	graph save "nb_exit_uw_NON_CIT_Survivor.gph", replace 

	
*nbreg weighted
	estimates clear
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg1 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill [pw=firm_size_year] , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg2
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg3
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* [pw=firm_size_year] , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg4
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg5
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_exit_w_NON_CIT_Survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_exit_w_NON_CIT_Survivor.png", replace
	graph save "nb_exit_w_NON_CIT_Survivor.gph", replace

	
	restore

**# Reg analysis: CIT Non Survivors

********************************************************************************
* 							Total employment									*
********************************************************************************
	cap mkdir "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\CIT NON Survivors"
	cd "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\CIT NON Survivors"

	preserve 
	keep if merge_CIT==3 & non_survivor==1 // CIT, non survivor 
	
		* nbreg unweighted

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  rainfall, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg7
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg8
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using nb_empl_uw_non_CIT_Non_survivor.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


	* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg8, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) /*ytitle(Interaction coefficient)*/ ///
	/*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks) 
	
	graph export "nb_empl_uw_CIT_Non_survivor.png", replace as(png)
	graph save "nb_empl_uw_CIT_Non_survivor.gph", replace 
	
* nbreg weighted

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_*  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  rainfall  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg7
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg8
summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using nb_empl_w_CIT_Non_survivor.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg8, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) /*ytitle(Interaction coefficient)*/ ///
	/*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks) 
	
	graph export "nb_empl_w_CIT_Non_survivor.png", replace as(png)
	graph save "nb_empl_w_CIT_Non_survivor.gph", replace 

********************************************************************************
* 									Entry										*
********************************************************************************
*nbreg unweighted
	estimates clear
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg1 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg2
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg3
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg4
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg5
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_entr_uw_CIT_Non_survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_entr_uw_CIT_Non_survivor.png", replace
	graph save "nb_entr_uw_CIT_Non_survivor.gph", replace 

	
*nbreg weighted
	estimates clear
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg1 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill [pw=firm_size_year] , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg2
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg3
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* [pw=firm_size_year] , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg4
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg5
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_entr_w_CIT_Non_survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_entr_w_CIT_Non_survivor.png", replace
	graph save "nb_entr_w_CIT_Non_survivor.gph", replace 
	

		
********************************************************************************
* 									Exit										*
********************************************************************************
	
*nbreg unweighted
	estimates clear
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg1 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg2
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg3
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg4
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg5
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_exit_uw_CIT_Non_survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_exit_uw_CIT_Non_survivor.png", replace
	graph save "nb_exit_uw_CIT_Non_survivor.gph", replace 

	
*nbreg weighted
	estimates clear
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg1 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill [pw=firm_size_year] , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg2
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg3
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* [pw=firm_size_year] , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg4
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg5
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_exit_w_CIT_Non_survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_exit_w_CIT_Non_survivor.png", replace
	graph save "nb_exit_w_CIT_Non_survivor.gph", replace

	restore
	
	********************************************************************************
* 							Total employment									*
********************************************************************************
	cap mkdir "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\NON CIT NON Survivors"
	cd "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage\datasets for Marlies\Analysis using Marlies code and Michael's samples\Agri as a whole (not split by seasonal and non-seasonal)\NON CIT NON Survivors"

	preserve 
	keep if merge_CIT==1 & non_survivor==1 // Non CIT, non survivor 
	
* nbreg unweighted

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  rainfall, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg7
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg8
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using nb_empl_uw_Non_CIT_Non_survivor.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


	* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg8, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) /*ytitle(Interaction coefficient)*/ ///
	/*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks) 
	
	graph export "nb_empl_uw_Non_CIT_Non_survivor.png", replace as(png)
	graph save "nb_empl_uw_Non_CIT_Non_survivor.gph", replace 
	
* nbreg weighted

	estimates clear 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg1 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg2
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg3 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_*  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg4 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg5 
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  rainfall  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg6
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg7
	nbreg count_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall  [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year) 
	estimates store reg8
summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using nb_empl_w_Non_CIT_Non_survivor.xls, replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 


* coef plot - full model with LAGGED dynamic offset variable
	coefplot reg8, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) /*ytitle(Interaction coefficient)*/ ///
	/*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks) 
	
	graph export "nb_empl_w_Non_CIT_Non_survivor.png", replace as(png)
	graph save "nb_empl_w_Non_CIT_Non_survivor.gph", replace 

********************************************************************************
* 									Entry										*
********************************************************************************
*nbreg unweighted
	estimates clear
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg1 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg2
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg3
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg4
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg5
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_entr_uw_Non_CIT_Non_survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_entr_uw_Non_CIT_Non_survivor.png", replace
	graph save "nb_entr_uw_Non_CIT_Non_survivor.gph", replace 

	
*nbreg weighted
	estimates clear
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg1 
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill [pw=firm_size_year] , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg2
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_female_fill [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg3
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* [pw=firm_size_year] , cluster(taxrefno) exposure(firm_size_year)
		estimates store reg4
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg5
	nbreg entry_agri c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall [pw=firm_size_year], cluster(taxrefno) exposure(firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_entr_w_Non_CIT_Non_survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_entr_w_Non_CIT_Non_survivor.png", replace
	graph save "nb_entr_w_Non_CIT_Non_survivor.gph", replace 
	

		
********************************************************************************
* 									Exit										*
********************************************************************************
	
*nbreg unweighted
	estimates clear
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg1 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg2
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg3
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg4
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg5
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall, cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_exit_uw_Non_CIT_Non_survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_exit_uw_Non_CIT_Non_survivor.png", replace
	graph save "nb_exit_uw_Non_CIT_Non_survivor.gph", replace 

	
*nbreg weighted
	estimates clear
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg1 
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill [pw=firm_size_year] , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg2
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_female_fill [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg3
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear   prop_age_cat_* [pw=firm_size_year] , cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg4
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  i.mode_prov_num [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg5
	nbreg exit_agri_new c.prop_affected_all##ib(2013).taxyear  prop_male_fill prop_female_fill  prop_age_cat_* i.mode_prov_num rainfall [pw=firm_size_year], cluster(taxrefno) exposure(L.firm_size_year)
		estimates store reg6
	summ prop_affected_all if taxyear==2013 & e(sample)==1
	estout reg* using "nb_exit_w_Non_CIT_Non_survivor.xls", replace  cells(b(star fmt(3)) se(par)) stats(r2_p N ,fmt(3 0 0 0) label ("Pseudo R-squared" "N" )) nobaselevels varlabels(_cons Constant) starlevels(* 0.1 ** 0.05 *** 0.01) 

* coef plot - full model with dynamic offset variable
	coefplot reg6, vertical keep(2012.taxyear#c.prop_affected_all 2013.taxyear#c.prop_affected_all 2014.taxyear#c.prop_affected_all 2015.taxyear#c.prop_affected_all 2016.taxyear#c.prop_affected_all 2017.taxyear#c.prop_affected_all) coeflabels(2012.taxyear#c.prop_affected_all = "-2" ///
	2013.taxyear#c.prop_affected_all = "-1"  2014.taxyear#c.prop_affected_all = "0" 2015.taxyear#c.prop_affected_all = "1" ///
	2016.taxyear#c.prop_affected_all = "2"  2017.taxyear#c.prop_affected_all = "3" , wrap(2)) ///
	baselevels omitted nolabel xtitle(Event time) ///
	/*ytitle(Entry)*/ /*scheme(plotplain)*/ msymbol(O) title("") mcolor(gs1) yline(0, lcolor("gs10") lpattern(dash)) ciopts(lcolor("gs1")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1")  grid glcolor(gs10) glwidth(vvthin) noticks)
	
	graph export "nb_exit_w_Non_CIT_Non_survivor.png", replace
	graph save "nb_exit_w_Non_CIT_Non_survivor.gph", replace

	restore
	
	log close 
	
	
