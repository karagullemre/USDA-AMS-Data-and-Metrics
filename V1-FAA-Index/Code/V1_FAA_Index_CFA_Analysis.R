#Recommended Citation:
#[Yang Cheng, Naveen Abedin, Yunus Emre Karagulle]. [(2023)]. [FAA Index CFA Analysis, (Version 1)]. USDA AMS Data Warehouse. [https://github.com/karagullemre/USDA-AMS-Data-and-Metrics/tree/8686fccb8b22966027bb4879fabe77a318be5aea/V1-FAA-Index].

#load libraries
library(foreign) 
library(lavaan)
# Load libraries
library(tigris)
library(sf)
library(ggplot2)
library(dplyr)
library(readxl)
#setwd("C:/Users/cheng/OneDrive - Virginia Tech/PhD/Academic/Project/Food Security/Data/Final data")
#setwd("C:/Users/Naveen Abedin/OneDrive - Virginia Tech/Food Security/Data/Final data")
setwd("/Users/emrekaragulle/Library/CloudStorage/OneDrive-VirginiaTech/Food Security/Data/Final data")

# Data -------------
# 🚩: filter data for the Appalachian region ------
## Appalachia counties
Appalachian <- readxl::read_excel("Appalachian-Counties-Served-by-ARC_2021.xlsx", skip = 3)

## Add Population of counties in Applacia (2020 population estimates)
pop <- readxl::read_excel("est2022-population-counties.xlsx", sheet = "Sheet1")
Appalachian <- merge(Appalachian, pop, by = c( "COUNTY", "STATE"), all.x = TRUE)

## Replace the Estimates for certain counties manually
Appalachian[Appalachian$COUNTY == "Alleghany + Covington city", "Estimates"] <- 15186 + 5742
Appalachian[Appalachian$COUNTY == "Carroll + Galax city", "Estimates"] <- 29142 + 6714
Appalachian[Appalachian$COUNTY == "Henry + Martinsville city", "Estimates"] <- 50846 + 13479
Appalachian[Appalachian$COUNTY == "Montgomery + Radford city", "Estimates"] <- 99561 + 16119
Appalachian[Appalachian$COUNTY == "Rockbridge + Buena Vista city + Lexington city", "Estimates"] <- 22645 + 6621 + 7321
Appalachian[Appalachian$COUNTY == "Washington + Bristol city", "Estimates"] <- 53889 + 17295
Appalachian[Appalachian$COUNTY == "Wise + Norton city", "Estimates"] <- 36061 + 3680
# Replace the Estimates for certain FIPS
Appalachian[Appalachian$FIPS == "01049", "Estimates"] <- 71648
Appalachian[Appalachian$FIPS == "47041", "Estimates"] <- 20187

## 🚩: Read in data for FAA and Data for Appalachia----
all_data_imputed <- read.csv("all_data_imputed.csv") %>% 
  filter(fips %in% as.numeric( Appalachian$FIPS))  # Data for Appalachia
Appalachian$FIPS <- as.numeric( Appalachian$FIPS)


## Merge population & FAA data------
all_data_imputed <- merge(all_data_imputed, Appalachian, by.x = "fips", by.y = "FIPS", all.x = TRUE)

# Divide by population
all_data_imputed$vannual_avg_estabs_count <-  (all_data_imputed$vannual_avg_estabs_count / all_data_imputed$Estimates) * 1000
all_data_imputed$vfood_banks <- all_data_imputed$vfood_banks/ all_data_imputed$Estimates  * 1000
all_data_imputed$vfood_desert_1and10 <- (all_data_imputed$vfood_desert_1and10 /all_data_imputed$Estimates) * 1000 
all_data_imputed$vnumber_CSAs <- all_data_imputed$vnumber_CSAs/ all_data_imputed$Estimates  * 1000
all_data_imputed$vnbr_col_univ <- all_data_imputed$vnbr_col_univ/ all_data_imputed$Estimates  * 1000
all_data_imputed$vnumber_meat_processors <- all_data_imputed$vnumber_meat_processors / all_data_imputed$Estimates  * 1000

# using z-scores of incomes
all_data_imputed$mean_household_incomes <-  (all_data_imputed$mean_household_incomes - min(all_data_imputed$mean_household_incomes))/(max(all_data_imputed$mean_household_incomes) - min(all_data_imputed$hours_worked ))
all_data_imputed$hours_worked   <- (all_data_imputed$hours_worked  - min(all_data_imputed$hours_worked ))/(max(all_data_imputed$hours_worked - min(all_data_imputed$hours_worked )))

# convert to decimals percentage 
all_data_imputed$snap_participation <-   all_data_imputed$snap_participation /100
all_data_imputed$unemployment_rate <-  all_data_imputed$unemployment_rate/100
all_data_imputed$poverty <-  all_data_imputed$poverty /100


## Combine varietals-------------
# Combine the variables to create 'stores' column
all_data_imputed$stores  <- all_data_imputed$vgrocpth + all_data_imputed$vsupercpth + all_data_imputed$vconvspth + all_data_imputed$vfmrktpth
# Combine the variables to create 'restaurant' column
all_data_imputed$restaurant  <-  all_data_imputed$vannual_avg_estabs_count  + all_data_imputed$vffrpth  # does not work as we though evern thoug we tried to use onely one of them


# 🚩: Flip the direction of selected variables in all_data_imputed-----
## Flip variables -----------
all_data_imputed$vpct_laccess_hhnv <- 1- all_data_imputed$vpct_laccess_hhnv
all_data_imputed$vfood_insecurity_rate <-  1- all_data_imputed$vfood_insecurity_rate
all_data_imputed$snap_participation <- 1- all_data_imputed$snap_participation
all_data_imputed$unemployment_rate <- 1- all_data_imputed$unemployment_rate
all_data_imputed$travel_time_90_or_more_minutes_p <- 1- all_data_imputed$travel_time_90_or_more_minutes_p
all_data_imputed$hours_worked <-  1 - all_data_imputed$hours_worked
all_data_imputed$vlaccess_pop <- 1 - all_data_imputed$vlaccess_pop
all_data_imputed$poverty <- 1 - all_data_imputed$poverty
all_data_imputed$vfood_desert_1and10  <-  max(all_data_imputed$vfood_desert_1and10) -  all_data_imputed$vfood_desert_1and10  
# Low income and low access tract measured at 1 mile for urban areas and 10 miles for rural areas  /1000 people 
# 0.4562044 the maximal cvalue of this 0.4562044 =  max(all_data_imputed$vfood_desert_1and10)
min_max_values <- sapply(all_data_imputed, function(x) c(min(x), max(x)))


# 🚩(Fixed by adding food banks & food dessert): Add variables back to the script (state level variables) -----
# #number of food hub, public and private refrigerate storage and warehouse, snap participation eligibility(missing)
vars <- c( "stores", "restaurant", "vsnapspth", "vnumber_CSAs", 
           "vnbr_col_univ", "vnumber_meat_processors", "vhighway_km",   "vpct_laccess_hhnv", "vfood_insecurity_rate",
           "snap_participation", "unemployment_rate", "mean_household_incomes", "travel_time_90_or_more_minutes_p",
           "hours_worked",  "poverty", "vfood_banks", "vfood_desert_1and10")

f1 <- c(  "stores", "restaurant", "vsnapspth",   "vfood_banks", "vfood_desert_1and10","vnumber_CSAs", 
          "vnbr_col_univ", "vnumber_meat_processors", "vhighway_km" )


f2 <- c( "vpct_laccess_hhnv", "vfood_insecurity_rate",
         "snap_participation", "unemployment_rate", "mean_household_incomes", "travel_time_90_or_more_minutes_p",
         "hours_worked",   "poverty" )
#remove the combined varibles
#vars_to_remove <- c("vgrocpth", "vsupercpth", "vconvspth", "vfmrktpth", "vannual_avg_estabs_count", "vffrpth" , "vlaccess_pop")


min_max_values <- sapply(all_data_imputed, function(x) c(min(x), max(x)))



# 🚩: correlated with the same directions, positive -------
corr <- cor(all_data_imputed[vars]) %>% round(2)
corr[lower.tri(corr)] = ""
View(corr)

corr_f1 <- cor(all_data_imputed[f1])  %>% round(2)
corr_f1[lower.tri(corr_f1)] = ""
View(corr_f1)

corr_f2 <- cor(all_data_imputed[f2])  %>% round(2)
corr_f2[lower.tri(corr_f2)] = ""
View(corr_f2) 

# Standardizing variables
all_data_imputed[vars] <- scale(all_data_imputed[vars])



# dropped the small loadings --+vnumber_CSAs + hours_worked + vsnapspth    + travel_time_90_or_more_minutes_p  + poverty
M <- 'f1 =~  stores   +vnbr_col_univ + vnumber_meat_processors 
        f2 =~ vpct_laccess_hhnv + vfood_insecurity_rate + snap_participation +   mean_household_incomes+ unemployment_rate '
FAA_a <- cfa(M, data=all_data_imputed, std.lv=TRUE) 
summary(FAA_a,fit.measures=TRUE, standardized=TRUE)


## Diagram----
library(semPlot)
graph <- semPaths(FAA_a, whatLabels = "std", style = "Mx", layout = "tree", curveAdjacent = FALSE, rotation = 2, edge.width = 0.5,
                  shapeMan = "rectangle", shapeLat = "ellipse", 
                  sizeMan = 6, sizeInt = 2, sizeLat =  8, 
                  curve=2)

my_label_list <- list(
  list(node = 'str', to = 'Stores'),
  list(node = 'vnb__', to = '# of College'),
  list(node = 'vnm__', to = '# of Meat Processors'),
  list(node = 'vp__', to = 'Low Access to Stores/No Vehicle'),
  list(node = 'vf__', to = 'Food Insecurity Rate'),
  list(node = 'sn_', to = 'SNAP Participation'),
  list(node = 'm__', to = 'Mean Household Incomes'),  
  list(node = 'un_', to = 'Unemployment Rate'),
  #list(node = 'pvr', to = 'Poverty Rate'),
  list(node = 'f1', to = 'Availability'),
  list(node = 'f2', to = 'Accessibility')
)

graph_final <- semptools::change_node_label(
  graph,
  my_label_list, 
  label.cex = 2.5
)

plot(graph_final)



# --------------------------#3. The FAA Index -----------------------------------


# 🚩: Need to confirm-----
## Extract the standardized loadings----
std_loadings <- as.data.frame(inspect(FAA_a, "Std.all")$lambda)

## Calculate the weighted sum for each factor and store it in new variables-------
all_data_imputed$FAA_f1 <- rowSums(sapply(c("stores", "vnbr_col_univ", "vnumber_meat_processors"),
                                          function(var) all_data_imputed[[var]] * std_loadings[var, "f1"]), na.rm = TRUE)

all_data_imputed$FAA_f2 <- rowSums(sapply(c("vpct_laccess_hhnv", "vfood_insecurity_rate", "snap_participation",
                                            "unemployment_rate", "mean_household_incomes"),
                                          function(var) all_data_imputed[[var]] * std_loadings[var, "f2"]), na.rm = TRUE)

all_data_imputed$FAA <- all_data_imputed$FAA_f1 + all_data_imputed$FAA_f2

## Subset FAA 
FAA_data <- all_data_imputed[, c(grep("^FAA", colnames(all_data_imputed)), which(colnames(all_data_imputed) == "fips"))]

## Save the FAA data----
save(FAA_data, file = "FAA_data.Rdata")


#---------------------------# 4. The Visualization ------------------------------

## Geo Data -------------
### Download US counties data------
options(tigris_use_cache = TRUE, tigris_class = "sf") # Set options to download data for the map
us_counties <- counties(  cb = TRUE, year = 2020) # we can change years later once we decide which year we use
### Download US states data, to add contextal information for the map-------
us_states <- tigris::states(cb = TRUE, year = 2020)  # Adjust year as necessary
# Have to process the GEOID, Add leading zeros to fips in FAA data frame
FAA_data$fips <- sprintf("%05d", FAA_data$fips)
# Perform the left join, geometry + FAA
map_data  <- left_join(FAA_data, us_counties, by = c("fips" = "GEOID"))
map_data <- st_as_sf(map_data)


# Filter the map_data for only Appalachian counties
map_appalachia <- map_data  
# 
### Define the Appalachian states to add the states for Appalachia ------
appalachian_states <- c("Alabama", "Georgia", "Kentucky", "Maryland", "Mississippi", "New York", 
                        "North Carolina", "Ohio", "Pennsylvania", "South Carolina", "Tennessee", 
                        "Virginia", "West Virginia")

### Filter the US states data to include only the Appalachian states ----------
us_states_appalachia <- us_states %>% filter(NAME %in% appalachian_states)

state_labels <- data.frame(
  NAME = us_states_appalachia$NAME,
  x = st_coordinates(st_centroid(us_states_appalachia$geometry))[, "X"],
  y = st_coordinates(st_centroid(us_states_appalachia$geometry))[, "Y"]
)

## Calculate quantiles for each variable -----
map_appalachia$FAA_pct <- cut(map_appalachia$FAA, breaks = quantile(map_appalachia$FAA, probs = seq(0, 1, by = 0.2), na.rm = TRUE), include.lowest = TRUE)
map_appalachia$FAA_f1_pct <- cut(map_appalachia$FAA_f1, breaks = quantile(map_appalachia$FAA_f1, probs = seq(0, 1, by = 0.2), na.rm = TRUE), include.lowest = TRUE)
map_appalachia$FAA_f2_pct <- cut(map_appalachia$FAA_f2, breaks = quantile(map_appalachia$FAA_f2, probs = seq(0, 1, by = 0.2), na.rm = TRUE), include.lowest = TRUE)

## Plot the maps ----
### Plot FAA map --------
ggplot() +
  geom_sf(data = map_appalachia, aes(fill = FAA_pct)) +
  scale_fill_viridis_d(name =  "Percentiles", labels = c("0-20%", "20-40%", "40-60%", "60-80%", "80-100%")) +
  labs(title = "",
       caption = "") +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks = element_blank(),
    axis.text = element_blank(),
    plot.title = element_text(hjust = 0.5)  
  ) +
  geom_sf(data = us_states_appalachia, fill = NA, color = 'black') +
  geom_text(data = state_labels, aes(x = x, y = y, label = NAME),
            color = "black", size = 2, fontface = "bold") +
  theme_void() +
  theme(plot.margin = margin(0, 0, 0, 0)) 



### Plot FAA_f1 Availability map ------
ggplot() +
  geom_sf(data = map_appalachia, aes(fill = FAA_f1_pct)) +
  scale_fill_viridis_d(name =  "Percentiles", labels = c("0-20%", "20-40%", "40-60%", "60-80%", "80-100%")) +
  labs(title = "",
       caption = "") +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks = element_blank(),
    axis.text = element_blank(),
    plot.title = element_text(hjust = 0.5)  
  ) +
  geom_sf(data = us_states_appalachia, fill = NA, color = 'black') +
  geom_text(data = state_labels, aes(x = x, y = y, label = NAME),
            color = "black", size = 2, fontface = "bold") +
  theme_void() +
  theme(plot.margin = margin(0, 0, 0, 0)) 


### Plot FAA_f2 Accessibility map ---------
ggplot() +
  geom_sf(data = map_appalachia, aes(fill = FAA_f2_pct)) +
  scale_fill_viridis_d(name =  "Percentiles", labels = c("0-20%", "20-40%", "40-60%", "60-80%", "80-100%")) +
  labs(title = "",
       caption = "") +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.ticks = element_blank(),
    axis.text = element_blank(),
    plot.title = element_text(hjust = 0.5)  
  ) +
  geom_sf(data = us_states_appalachia, fill = NA, color = 'black') +
  geom_text(data = state_labels, aes(x = x, y = y, label = NAME),
            color = "black", size = 2, fontface = "bold") +
  theme_void() +
  theme(plot.margin = margin(0, 0, 0, 0)) 


