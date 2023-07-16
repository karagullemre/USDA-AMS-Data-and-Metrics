*Recommended Citation:
*[Yang Chen, Naveen Abedin, Yunus Emre Karagulle]. [(2023)]. [FAA Index Formatting USDA AMS Data, (Version 1)]. USDA AMS Data Warehouse. [https://github.com/karagullemre/USDA-AMS-Data-and-Metrics/tree/8686fccb8b22966027bb4879fabe77a318be5aea/V1-FAA-Index].

/******************
Formatting the Data
 ******************/
* Set Working Directory 
global input "/Users/emrekaragulle/Library/CloudStorage/OneDrive-VirginiaTech/Food Security/Data"
cd "$input"

clear all
import delimited "ACS.csv",  colrange(:10) numericcols(3 4 5 6 7 8 9 10) clear 

 save "ACS",replace
 
 
clear all 
set more off
local csvfiles:dir"All_csv_files"files"*.csv"

foreach file in `csvfiles' {
	preserve
	import delimited "All_csv_files/`file'",clear colrange(:8) numericcols(6) varnames(1)
	gen sourcefile="`file'"
	save temp,replace
	restore
	append using temp,force
	}
	
replace year=2019 if sourcefile=="business_development_infrastructure.csv" & year==.	/* Correcting year variable due to nuemric/string issue in the csv file. */
	
unique variable_name
keep if (variable_name=="annual_avg_estabs_count_NAICS 722511 Full-service restaurants" & year==2021) | /*
*/ (variable_name=="grocpth" & year==2016) | (variable_name=="convspth"& year==2016) | /* 
*/ (variable_name=="number_farmers_markets" & year==2022) | (variable_name=="fmrktpth" & year==2018) | /*
*/ (variable_name=="snapspth" & year==2017 ) | (variable_name=="supercpth"& year==2016 )| /*
*/ (variable_name=="food_banks" & year==2018) | (variable_name=="food_desert_1and10"& year==2019 ) | /* 
*/ (variable_name=="number_CSAs" & year==2022) | /* (variable_name=="number_food_hubs" & year==2022) Not suitable- only few states and counties have obs |*/ /*
*/ (variable_name=="number_colleges_universities"& year==2022) | (variable_name=="number_meat_processors" & year==2022 )| /*
*/ (variable_name=="public_refrigerated_warehouses" & year==2021 ) | (variable_name=="private_semi_private_refrigerated_warehouses"& year==2021) | /* 
*/ (variable_name=="highway_km" & year==2007 ) | (variable_name=="ffrpth" & year==2016) | /*
*/ (variable_name=="pct_laccess_hhnv" & year==2015) | (variable_name=="food_insecurity_rate" & year==2019) | /*
*/ (variable_name=="snap_par_all_eligible_people" & year==2019 ) | (variable_name=="SNAP_participation" & year==2019 ) | /* 
*/ (variable_name=="unemployment_rate" & year==2019)| (variable_name=="mean_househousehold_incomes" & year==2019) | /*
*/ (variable_name=="travel_time_90_or_more_minutes_pct" & year==2018 ) | (variable_name=="hours_worked" & year==2019 ) | /*
*/ (variable_name=="laccess_pop" & year==2015 )| (variable_name=="poverty_unemployed" & year==2019 ) | /* 
*/ (variable_name=="poverty" & year==2018 )| (variable_name=="poverty_employed" & year==2019 )| /*
*/ (variable_name=="pct_laccess_hhnv" & year==2019) | (variable_name=="below_poverty_level_percent_population_16_years_and_over" & year==2020 )


unique variable_name

/*Deal with long variable names */
replace variable_name="annual_avg_estabs_count" if variable_name=="annual_avg_estabs_count_NAICS 722511 Full-service restaurants"
replace variable_name="nbr_col_univ" if variable_name=="number_colleges_universities"
replace variable_name="public_ref_warehouses" if variable_name=="public_refrigerated_warehouses"
replace variable_name="private_ref_warehouses" if variable_name=="private_semi_private_refrigerated_warehouses"
replace variable_name="snap_par_all_eligible" if variable_name=="snap_par_all_eligible_people"
replace variable_name="travel_time_90_more" if variable_name=="travel_time_90_or_more_minutes_pct"
replace variable_name="below_poverty_percent" if variable_name=="below_poverty_level_percent_population_16_years_and_over"


/*Drop State level variables for now */
drop if variable_name=="private_ref_warehouses" | variable_name=="public_ref_warehouses" | variable_name=="snap_par_all_eligible"
drop if county_name=="NA"


*variables names : fips county_name state_name category topic_area year variable_name value sourcefile
drop if year==. /*Drop variables that have no year information. Drops 4 variables from community_wealth.csv, but we dont use them.   */

/*Drop Puerto rico, american samoa and guam, missing almost all obs. */	
drop if state_name=="American Samoa" | state_name=="Guam" | /*
*/ state_name=="Northern Mariana Islands"  | state_name=="Puerto Rico" | /*
*/ state_name=="U.S. Minor Outlying Islands"  | state_name=="U.S. Virgin Islands" 

/*
Reshape from long to wide
*/
drop category topic_area  sourcefile year
rename value v
reshape wide v, i( fips county_name state_name) j(variable_name) string

merge 1:1 fips using "ACS.dta"
 *   not matched                            91      
  *      from master                        13  (_merge==1) Does not have information in the using file or cities.
   *     from using                         78  (_merge==2) Puerto Rico counties

    *matched                             3,142  (_merge==3)
drop if _m==2
drop _m

destring hours_worked, replace
drop name

save "food_availibility_and_accessibility.dta",replace
	
	
