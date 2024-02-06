gl dir "Z:\Workbenches\epadmin\michael_kilumelume\2024 projects\minimum wage"

cap mkdir "$dir\data"
cap mkdir "$dir\notes and tables"
cap mkdir "$dir\log"
cap mkdir "$dir\graphs"
cap mkdir "$dir\graphs\use"
cap mkdir  "Z:\Workbenches\epadmin\michael_kilumelume\out_files\27Jan2022"
*file address  
gl irp5_ind "D:\Researchers\Master Data\IRP5\Job level\v4\Job level\v4"
gl citirp5_v4 "D:\Researchers\Master Data\CIT-IRP5 Panel\citirp5_v4.0.dta"
gl saveaddress_data "$dir\data\"
gl saveaddress_notes "$dir\notes and tables"
gl saveaddress_grahs "$dir\graphs"
gl saveaddress_grahs_use "$dir\graphs\use"
gl log_save "$dir\log"

/*******************************************************************************
TO OUTFILES 
********************************************************************************/
/*
cap mkdir "Z:\Workbenches\epadmin\michael_kilumelume\out_files\25jan2023"
gl graph_save  "Z:\Workbenches\epadmin\michael_kilumelume\out_files\27Jan2022"
*/