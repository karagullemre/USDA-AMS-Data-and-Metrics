*Recommended Citation:
*[Yang Chen, Naveen Abedin, Yunus Emre Karagulle]. [(2023)]. [FAA Index Imputation of Missing Data, (Version 1)]. USDA AMS Data Warehouse. [https://github.com/karagullemre/USDA-AMS-Data-and-Metrics/tree/8686fccb8b22966027bb4879fabe77a318be5aea/V1-FAA-Index].

* Imputing the data
* Yang Cheng
* Set Working Directory
cd "C:\Users\cheng\OneDrive - Virginia Tech\PhD\Academic\Project\Food Security\Data"

* I updated the travel time ratio, as the RMD file has lots of missing values
use "food_availibility_and_accessibility.dta",clear

merge 1:1 fips using "travel_time_ACS.dta"
 *   not matched                            91      
  *      from master                        13  (_merge==1) Does not have information in the using file or cities.
   *     from using                         78  (_merge==2) Puerto Rico counties

    *matched                             3,142  (_merge==3)
drop if _merge==2
drop _merge



********************************************************************************
* check the missing variables
foreach var of varlist vannual_avg_estabs_count vbelow_poverty_percent vconvspth vffrpth vfmrktpth vfood_insecurity_rate vgrocpth vhighway_km vlaccess_pop vnbr_col_univ vnumber_CSAs vnumber_farmers_markets vnumber_meat_processors vpct_laccess_hhnv vsnapspth vsupercpth vtravel_time_90_more hours_worked poverty_employed poverty poverty_unemployed mean_household_incomes median_earnings snap_participation unemployment_rate travel_time_90_or_more_minutes_p{
    di as text "Tabulating state_name for variable: `var'"
    tab state_name if missing(`var')
}


* repalce NA with "" for three varibles
replace poverty_unemployed="" if poverty_unemployed=="NA"
destring poverty_unemployed, replace ignore(",")

replace median_earnings="" if median_earnings=="NA"
destring median_earnings, replace ignore(",")

replace hours_worked="" if hours_worked=="NA"
destring hours_worked, replace  


********************************************************************************

* impute with  state average level
foreach var in vbelow_poverty_percent vconvspth vffrpth vfmrktpth vfood_insecurity_rate vgrocpth vhighway_km vlaccess_pop vnbr_col_univ vnumber_CSAs vnumber_farmers_markets vnumber_meat_processors vpct_laccess_hhnv vsnapspth vsupercpth vtravel_time_90_more hours_worked poverty_employed poverty poverty_unemployed mean_household_incomes median_earnings snap_participation unemployment_rate vhighway_km vtravel_time_90_more travel_time_90_or_more_minutes_p{
    bys state_name: egen temp = mean(`var')  
    replace `var' = temp if mi(`var')
    drop temp
}

* impute with  national average level
egen temp = mean(vhighway_km)  
replace vhighway_km = temp if mi(vhighway_km)
drop temp
 

*Imputing with 0s
foreach var in vannual_avg_estabs_count vnbr_col_univ vnumber_meat_processors {
    replace `var' = 0 if `var' ==.
}

drop vtravel_time_90_more /*duplicate */
********************************************************************************
save "/Users/emrekaragulle/Library/CloudStorage/OneDrive-VirginiaTech/Food Security/Data/Final data/all_data_imputed.dta",replace


