use "C:\Users\mkthi\OneDrive\Documents\2024 PHD final touch\Minimum wage\Min Wage paper _ Updated results\Min Wage paper _ Updated results\data\analysis_unbalanced.dta", clear 
*EXIT
	sort taxrefno taxyear 

	cap drop n 
	cap drop N 
	bys n_fid: gen n = _n 
	bys n_fid: gen N = _N
	tab taxyear 
	br taxrefno n_fid taxyear n N
	
	xtset n_fid taxyear 
	tsfill, full 
	
	gen entry = 0 
	replace entry = 1 if n ==1 
	label var entry "Firm entry"
	
	
	bys taxyear : egen mean_entry = mean(entry)
	tab taxyear,  sum(mean_entry)

	
	
	gen exit =0 
	replace exit = 1 if N==n & n!=.
	labe var exit "Firm exit"
	
	keep taxyear n_fid employment exit 
	
	*get total employment 
	bys taxyear : egen tot_emp = total(employment)
	
	*get total employment of exiters 
	gen emp_exit = employment if exit ==1 
	bys taxyear: egen tot_emp_exit = total(emp_exit)
	
	*collapse by taxyear 
	bys taxyear : gen n =_n 
	keep if n == 1 
	drop n 
	keep taxyear tot_emp tot_emp_exit 
	
	gen emp_exit_lag = tot_emp_exit[_n-1]
	
	gen prop_emp_lost = emp_exit_lag/tot_emp
	