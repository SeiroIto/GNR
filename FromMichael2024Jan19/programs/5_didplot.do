

cap program drop didplot_base 
program didplot_base 	  
foreach var in `1' {
   local lab: variable label `var'
 *indicate the treatment variable to use
 local treat fa_use 
 
 
 
 *run the difference in differences regression 
if "`treat'"=="t"{
  qui reg `1' c.`treat'##ib(2013).taxyear i.taxyear /*lmn_cap_lab*/ /*lmn_cap_lab*/ lmn_rainfall lmn_revenue i.busprov_geo_num_imp  i.imp_mic_sic7_3d i.size_ctype_adj
  est store reg1 
 coefplot reg1, keep(1.`treat'#*) vertical baselevels omitted rename( 1.`treat'#2011.taxyear="-2"  1.`treat'#2012.taxyear="-1"  1.`treat'#2013.taxyear="0" 1.`treat'#2014.taxyear="1" 1.`treat'#2015.taxyear="2" 1.`treat'#2016.taxyear="3" 1.`treat'#2017.taxyear="4" ) ciopts(lcolor("118 152 160")) yline(0, lcolor("106 208 200") lpattern(dash)) xline(3, lcolor("236 196 77")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("0 51 102")) yscale(lcolor("0 51 102")) xlabel(, labcolor("0 51 102") noticks) ylabel(, labcolor("0 51 102") noticks nogrid) title("`lab'") saving ("$saveaddress_grahs\\`1' did", replace)
}
else{
 xtset n_fid taxyear 
 sort n_fid taxyear 
 qui reg `1' c.`treat'##ib(2012).taxyear i.taxyear /*lmn_cap_lab lmn_cap_lab*/ lmn_rainfall lmn_revenue i.busprov_geo_num_imp  i.imp_mic_sic7_3d i.size_ctype_adj
 est store reg1
 
 coefplot reg1, keep(*.taxyear#c.`treat') vertical baselevels omitted rename(2011.taxyear#c.`treat'="-1"  2012.taxyear#c.`treat'="0"  2013.taxyear#c.`treat'="1" 2014.taxyear#c.`treat'="2" 2015.taxyear#c.`treat'="3" 2016.taxyear#c.`treat'="4" 2017.taxyear#c.`treat'="5" ) ciopts(lcolor("gs1")) yline(0, lcolor("gs10") lpattern(dash)) /*xline(3, lcolor("gs1"))*/ graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1") noticks nogrid) title("`lab'") saving ("$saveaddress_grahs\\`1' did", replace) scheme(plotplain)
 
 

} 

} 
end 


cap program drop didplot_cluster  
program didplot_cluster 	  
foreach var in `1' {
   local lab: variable label `var'
 *indicate the treatment variable to use
 local treat fa_use 
 
 
 
 *run the difference in differences regression 
if "`treat'"=="t"{
     qui reg `1' c.`treat'##ib(2013).taxyear i.taxyear lmn_cap_lab lmn_rainfall lmn_revenue i.busprov_geo_num_imp  i.imp_mic_sic7_3d i.size_ctype_adj , cluster(n_fid) 
   est store reg1 
 coefplot reg1, keep(1.`treat'#*) vertical baselevels omitted rename( 1.`treat'#2011.taxyear="-1"  1.`treat'#2012.taxyear="0"  1.`treat'#2013.taxyear="1" 1.`treat'#2014.taxyear="2" 1.`treat'#2015.taxyear="3" 1.`treat'#2016.taxyear="4" 1.`treat'#2017.taxyear="5" ) ciopts(lcolor("118 152 160")) yline(0, lcolor("106 208 200") lpattern(dash)) xline(3, lcolor("236 196 77")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("0 51 102")) yscale(lcolor("0 51 102")) xlabel(, labcolor("0 51 102") noticks) ylabel(, labcolor("0 51 102") noticks nogrid) title("`lab'") saving ("$saveaddress_grahs\\`1' did", replace)
}
else{
 xtset n_fid taxyear 
 sort n_fid taxyear 
 qui reg `1' c.`treat'##ib(2012).taxyear i.taxyear /*lmn_cap_lab*/ lmn_rainfall lmn_revenue i.busprov_geo_num_imp  i.imp_mic_sic7_3d i.size_ctype_adj , cluster(n_fid) 
 est store reg1
 
 coefplot reg1, keep(*.taxyear#c.`treat') vertical baselevels omitted rename(2011.taxyear#c.`treat'="-2"  2012.taxyear#c.`treat'="-1"  2013.taxyear#c.`treat'="0" 2014.taxyear#c.`treat'="1" 2015.taxyear#c.`treat'="2" 2016.taxyear#c.`treat'="3" 2017.taxyear#c.`treat'="4" ) ciopts(lcolor("gs1")) yline(0, lcolor("gs10") lpattern(dash)) /*xline(3, lcolor("gs1"))*/ graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1") noticks nogrid) title("`lab'") saving ("$saveaddress_grahs\\`1' did", replace) scheme(plotplain)
 
 

} 

} 
end 

cap program drop didplot_cluster_weight   
program didplot_cluster_weight 	  
foreach var in `1' {
   local lab: variable label `var'
 *indicate the treatment variable to use
 local treat fa_use 
 
 
 
 *run the difference in differences regression 
if "`treat'"=="t"{
  qui reg `1' c.`treat'##ib(201).taxyear i.taxyear lmn_cap_lab lmn_rainfall lmn_revenue i.busprov_geo_num_imp  i.imp_mic_sic7_3d i.size_ctype_adj [pw=lmn_employment], cluster(n_fid)
  est store reg1 
 coefplot reg1, keep(1.`treat'#*) vertical baselevels omitted rename( 1.`treat'#2011.taxyear="-2"  1.`treat'#2012.taxyear="-1"  1.`treat'#2013.taxyear="0" 1.`treat'#2014.taxyear="1" 1.`treat'#2015.taxyear="2" 1.`treat'#2016.taxyear="3" 1.`treat'#2017.taxyear="4" ) ciopts(lcolor("118 152 160")) yline(0, lcolor("106 208 200") lpattern(dash)) xline(3, lcolor("236 196 77")) graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("0 51 102")) yscale(lcolor("0 51 102")) xlabel(, labcolor("0 51 102") noticks) ylabel(, labcolor("0 51 102") noticks nogrid) title("`lab'") saving ("$saveaddress_grahs\\`1' did", replace)
}
else{
 xtset n_fid taxyear 
 sort n_fid taxyear 
 qui reg `1' c.`treat'##ib(2012).taxyear i.taxyear /*lmn_cap_lab*/ lmn_rainfall lmn_revenue i.busprov_geo_num_imp  i.imp_mic_sic7_3d i.size_ctype_adj [pw=lmn_employment], cluster(n_fid) 
 est store reg1
 
 coefplot reg1, keep(*.taxyear#c.`treat') vertical baselevels omitted rename(2011.taxyear#c.`treat'="-2"  2012.taxyear#c.`treat'="-1"  2013.taxyear#c.`treat'="0" 2014.taxyear#c.`treat'="1" 2015.taxyear#c.`treat'="2" 2016.taxyear#c.`treat'="3" 2017.taxyear#c.`treat'="4" ) ciopts(lcolor("gs1")) yline(0, lcolor("gs10") lpattern(dash)) /*xline(3, lcolor("gs1"))*/ graphregion(fcolor(white)) fcolor(white) lcolor(white) xscale(lcolor("gs1")) yscale(lcolor("gs1")) xlabel(, labcolor("gs1") noticks) ylabel(, labcolor("gs1") noticks nogrid) title("`lab'") saving ("$saveaddress_grahs\\`1' did", replace) scheme(plotplain)
 
 

} 

} 
end 
