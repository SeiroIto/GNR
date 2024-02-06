	*DROP 2008 2009  2010 and 2018 
		drop if taxyear == 2008 | taxyear == 2009 | taxyear== 2010 |  taxyear ==2018 
		tab taxyear 

	*DROP DUPLICATES 
	*VALUE-ADDED  
		cap drop value_added
		drop if g_cos == 0 | g_cos==. 
		drop if g_sales == 0 | g_sales == .
		drop if value_added== 0 | value_added ==. 
	*EMPLOYMENT
		cap drop employment
		drop if irp5_kerr_weight_b == 0 | irp5_kerr_weight_b==. 
	*COST OF SALE  
		cap drop cost_sales  
		drop if g_cos == 0 | g_cos == . 
	*LABOUR COST 
		sum x_labcost
		drop if x_labcost==0 | x_labcost== .
*DROP FIRMS ENTERING AFTER THE POLICY 

		sort n_fid taxyear 
		br n_fid taxyear  
		cap drop n
		bys n_fid: gen n= _n 

		gen entry_after_tg = 0
		replace entry_after_tg = 1 if n==1 & taxyear > 2013 

		bys n_fid: egen drop_afer = max(entry_after_tg)
		drop if drop_afer== 1
	*create rectangular dataset for a balanced panel 
		drop if taxrefno ==""
