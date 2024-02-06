


*GENERAL RESULTS 
cap mkdir "$saveaddress_grahs\general results"

foreach dataset in unbalanced balanced survivors {
    foreach modification in base cluster cluster_weight {
    
use "$saveaddress_data\\analysis_`dataset'.dta", clear 
cap  mkdir "$saveaddress_grahs\general results\\`dataset'"
gl graph_save  "$saveaddress_grahs\general results\\`dataset'"

local keep_log = "ltrain lnon_wage_labcosts lawage llabcost_pe llabcost_capcost loprofit lmaterials l_labcost  loprofits_pe lcap_lab lrev_pe lrevenue k l "

foreach var of local keep_log  {
    local lab : variable label `var'
    didplot_`modification'  `var'
  graph export "$graph_save\\`lab'-`modification'.png", replace     
}

	} 

} 


/*

*RESULTS BY FIRM-SIZE [MICRO ; SMALL AND MEDIUM TO LARGE AS DEFINED BY THE CIT C_TYPE VARIABLE]
cap mkdir "$saveaddress_grahs\results by firm size"

forvalues size = 1/3 {
    if "`size'" == "1"{
	    local size_lab = "Micro"
	}
	if "`size '" == "2" {
	    local size_lab = "Small"
	}
	if "`size'" == "3" {
	    local size_lab = "Medium_large"
	}
	
	cap mkdir"$saveaddress_grahs\results by firm size\\`size_lab'"
	
foreach dataset in unbalanced balanced survivors {
    foreach modification in base cluster cluster_weight {
    
use "$saveaddress_data\\analysis_`dataset'.dta", clear 
*keep if size_ctype_adj == `size'
keep if size_emp == `size'

cap  mkdir "$saveaddress_grahs\results by firm size\\`size_lab'\\`dataset'"
gl graph_save   "$saveaddress_grahs\results by firm size\\`size_lab'\\`dataset'"

local keep_log = "ltrain lnon_wage_labcosts lawage llabcost_pe llabcost_capcost loprofit lmaterials l_labcost  loprofits_pe lcap_lab lrev_pe lrevenue k l "

foreach var of local keep_log  {
    local lab : variable label `var'
    cap noisily  didplot_`modification'  `var'
   cap noisily graph export "$graph_save\\`lab'-`modification'.png", replace     
}

	} 

} 

} 
*/
