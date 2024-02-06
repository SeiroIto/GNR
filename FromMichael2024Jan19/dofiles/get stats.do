 
 
 *OPEN DOCUMENNT 
 putdocx clear 
 putdocx begin 
 
 
 foreach set in no_win win {
 
 use "$saveaddress_data\sumstat_data.dta", clear 
 local keep_level = "employment capital revenue labour_cost cost_sales fa_use"

 
 
if "`set'" =="win"{
    local tb_name = "Distribution after winsorizing (1%)"
	
	
	
 levelsof taxyear, loca(levels)  
 foreach level of local levels{
     foreach var of local keep_level{
	     sum `var' if taxyear == `level', d
		 
		 replace `var' = r(p1) if `var'< r(p1) & taxyear == `level '
		 replace `var' = r(p99) if `var' > r(p99) & taxyear== `level'
		 
		 
	 }
 }
 
 
}
else {
    local tb_name = "Distribution before winsorizing"
}
 

  
 local font	 = 	"font(calibri light, 9)"
 local bt	 = 	"border(top)"
 local bb 	 = 	"border(bottom)"
 
 putdocx table tbl1=(1,7) , border(all, nil)
 putdocx table tbl1(1,1) = ("Variable"), `bt' `bb' `font'
 putdocx table tbl1(1,2) = ("N")  , `bt' `bb' `font' 
 putdocx table tbl1(1,3) = ("Mean ") , `bt' `bb' `font'
 putdocx table tbl1(1,4) = ("St.Dev ") , `bt' `bb' `font' 
 putdocx table tbl1(1,5) = ("Min ") , `bt' `bb' `font' 
 putdocx table tbl1(1,6) = ("Med") , `bt' `bb' `font' 
 putdocx table tbl1(1,7) = ("Max ") , `bt' `bb' `font' 
 
 local row =1 
 
 foreach var of local keep_level{
     local vname : variable label `var'
     
     putdocx table tbl1(`row', . ) , addrows(1)
	 local ++row 
	 
	 sum `var', d 
	 local N = r(N)
	 local mean = string(r(mean), "%25.2gc")
	 local sd = string(r(sd), "%25.2gc")
	 local min =string(r(min), "%25.2gc")
	 local med =string(r(p50), "%25.2gc")
	 local max =string(r(max), "%25.2gc")
	 
	 putdocx table tbl1(`row', 1) = ("`vname'") , `font'
	 putdocx table tbl1(`row', 2) = ("`N'") , `font'
	 putdocx table tbl1(`row', 3) = ("`mean'") , `font'
	 putdocx table tbl1(`row', 4) = ("`sd'") , `font'
	 putdocx table tbl1(`row', 5) = ("`min'") , `font'
	 putdocx table tbl1(`row', 6) = ("`med'") , `font'
	 putdocx table tbl1(`row', 7) = ("`max'") , `font'
 }
 putdocx table tbl1(`row', .) , addrows(1)
 local ++row 
 
 putdocx table tbl1(`row', 1 ) =(" ") , `bt' colspan(7)
 
 putdocx table tbl1(1,.) , addrows(1, before)
 putdocx table tbl1(1,1) = ("`tb_name'") , `font' colspan(7)
 
 
 } 
 
 *EXITER AND SURVIVOR TABLE 
 	use "$saveaddress_data\sumstat_data", clear 
	order taxrefno taxyear 
	sort taxrefno taxyear 
	numlabel , add 

	*DEFINE EXITER AND SURVIVOR VARIABLE 
	cap drop n 
	bys taxrefno : gen n = _n 
	
	cap drop N 
	bys taxrefno : gen N = _N 
	
	gen survivor = 0 
	replace survivor = 1 if N ==7 
	
	egen FID = group(taxrefno)
	xtset FID taxyear 
	
	
	 keep if n== 1
 
   
   *Column totals 
   count if survivor== 0 & size_ctype_adj !=. 
   local tot_ext = string(r(N), "%10.0gc") 
   count if survivor == 1 & size_ctype_adj !=. 
   local tot_sur = string(r(N), "%10.0gc") 
   
   count if size_ctype_adj! = . & survivor!= . 
   local grand_tot = string(r(N), "%10.0gc") 

   
   
	local font	 = 	"font(calibri light, 9)"
	local bt	 = 	"border(top)"
	local bb 	 = 	"border(bottom)" 
 
	
	putdocx table tbl1 = (1, 4) , border(all, nil)
	putdocx table tbl1(1,1) = (" ") , `bt' `bb' `font'
	putdocx table tbl1(1,2) = ("Exited") , `bt' `bb' `font' 
	putdocx table tbl1(1,3) = ("Survived") , `bt' `bb' `font'
	putdocx table tbl1(1,4) = ("Total") , `bt' `bb' `font'
	
	local row = 1 
	levelsof size_ctype_adj, local(levels )
	foreach level of local levels{
	    if "`level'" == "1"{
		    local lname = "Micro firms"
		}
		  if "`level'" == "2"{
		    local lname = "Small firms"
		}
		  if "`level'" == "3"{
		    local lname = "Medium to large firms"
		}
		
		count if size_ctype_adj== `level' &  survivor == 0 
		local ex =  string(r(N), "%10.0gc") 
		
		count if size_ctype_adj== `level' &  survivor ==1 
		
		local su =  string(r(N), "%10.0gc") 
		
		count if  size_ctype_adj== `level' &  survivor !=. 
		local tt = string(r(N), "%10.0gc")
		
		
	    putdocx table tbl1(`row', . ) , addrows(1)
		local ++row 
		
		putdocx table tbl1(`row', 1) = ("`lname'") , `font'
		putdocx table tbl1(`row', 2) = ("`ex'") , `font'
		putdocx table tbl1(`row', 3) = ("`su'") , `font'
		putdocx table tbl1(`row', 4) = ("`tt'") , `font'
		
		
	}
	putdocx table tbl1(`row', .) , addrows(1)
    local ++row 
	putdocx table tbl1(`row', 1) = ("Total") , `font'  `bb'
	putdocx table tbl1(`row', 2) = ("`tot_ext'") , `font'  `bb'
	putdocx table tbl1(`row', 3) = ("`tot_sur'") , `font' `bb'
	putdocx table tbl1(`row', 4) = ("`grand_tot'") , `font' `bb'
	
	
	putdocx table tbl1(1,.) , addrows(1, before)
	putdocx table tbl1(1,1) = ("Exit and survivor frequencies") , `font' colspan(7)
 
 
 
 
	*EXPOSURE INTENSITY 
	use "$saveaddress_data\sumstat_data", clear 
	bys taxrefno : gen n =_n 
	keep if n ==1 
	
	cap drop exposure 
	gen exposure = .
	sum fa_use, d 
	replace exposure = 1 if fa_use <= r(p25)
	replace exposure = 2 if fa_use> r(p25) &  fa_use<=r(p75)
	replace exposure = 3 if fa_use >r(p75)
	
	
	
	
   *Column totals 
   count if exposure== 1 & size_ctype_adj !=. 
   local tot_1 = string(r(N), "%10.0gc") 
   count if exposure == 2 & size_ctype_adj !=. 
   local tot_2 = string(r(N), "%10.0gc") 
   count if exposure == 3 & size_ctype_adj !=. 
   local tot_3 = string(r(N), "%10.0gc") 
   
   count if size_ctype_adj! = . & exposure!= . 
   local grand_tot = string(r(N), "%10.0gc") 

   
   
	local font	 = 	"font(calibri light, 9)"
	local bt	 = 	"border(top)"
	local bb 	 = 	"border(bottom)" 
 
  

 
	sum fa_use,d 

	local less = string(r(p25) ,"%10.2gc") 
	local mod_up = string(r(p75) ,"%10.2gc")
	
	putdocx table tbl1 = (1, 5) , border(all, nil)
	putdocx table tbl1(1,1) = (" ") , `bt' `bb' `font'
	putdocx table tbl1(1,2) = ("FA<=`less'") , `bt' `bb' `font' 
	putdocx table tbl1(1,3) = ("`less' <FA =< `mod_up'") , `bt' `bb' `font'
	putdocx table tbl1(1,4) = ("FA> `mod_up'") , `bt' `bb' `font'
	putdocx table tbl1(1,5) = ("Total") , `bt' `bb' `font'
	
	local row = 1 
	levelsof size_ctype_adj, local(levels )
	foreach level of local levels{
	    if "`level'" == "1"{
		    local lname = "Micro firms"
		}
		  if "`level'" == "2"{
		    local lname = "Small firms"
		}
		  if "`level'" == "3"{
		    local lname = "Medium to large firms"
		}
		
		count if size_ctype_adj== `level' &  exposure == 1
		local c1t =  string(r(N), "%10.0gc") 
		
		count if size_ctype_adj== `level' &  exposure==2 
		
		local c2t =  string(r(N), "%10.0gc") 
		
		count if size_ctype_adj== `level' &  exposure ==3 
		
		local c3t =  string(r(N), "%10.0gc")
		
		count if  size_ctype_adj== `level' &  exposure !=. 
		local tt = string(r(N), "%10.0gc")
		
		
	    putdocx table tbl1(`row', . ) , addrows(1)
		local ++row 
		
		putdocx table tbl1(`row', 1) = ("`lname'") , `font'
		putdocx table tbl1(`row', 2) = ("`c1t'") , `font'
		putdocx table tbl1(`row', 3) = ("`c2t'") , `font'
		putdocx table tbl1(`row', 4) = ("`c3t'") , `font'
		putdocx table tbl1(`row', 5) = ("`tt'") , `font'
		
		
	}
	putdocx table tbl1(`row', .) , addrows(1)
    local ++row 
	putdocx table tbl1(`row', 1) = ("Total") , `font'  `bb'
	putdocx table tbl1(`row', 2) = ("`tot_1'") , `font'  `bb'
	putdocx table tbl1(`row', 3) = ("`tot_2'") , `font' `bb'
	putdocx table tbl1(`row', 4) = ("`tot_3'") , `font' `bb'
	putdocx table tbl1(`row', 5) = ("`grand_tot'") , `font' `bb'
	
	
	putdocx table tbl1(1,.) , addrows(1, before)
	putdocx table tbl1(1,1) = ("Exposure intensity") , `font' colspan(5)
 
  putdocx save "$saveaddress_notes\distributions", replace 
 
 

 
 