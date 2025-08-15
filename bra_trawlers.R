#### Exploring industrial brazilian fisheries...

## importing packages 

library(gfwr)
library(sf)
library(tidyverse)
library(leaflet)
library(curl)

## deal with data time requisition 

h <- new_handle(timeout = 700000)
curl_fetch_memory("https://gateway.api.globalfishingwatch.org", handle = h)


## keys 

key <- Sys.getenv("chave")                                        ## global fishing watch API key

## set directory 

setwd("your_directory")

## datasets 

#-- vessel information ----
bra_vessels <- get_vessel_info(
  where = "flag='BRA' AND geartypes='TRAWLERS'",
  search_type = "search",
  quiet = TRUE,
  key=key
)

# gathering vessel ID
each_BRA_trawler <- bra_vessels$selfReportedInfo[,c('index','vesselId')]

# get events of brazilian trawlers from 2024
fishing_events <- get_event(event_type = "FISHING",
                            vessels = each_BRA_trawler$vesselId,
                            start_date = "2024-01-01",
                            end_date = "2024-12-31", key=key)


#----
#-- shapefiles ----
eez_shp <- st_read("/amazonia_azul.fgb")
#----

##


## Cleaning, trasforming and visualize operational locations

# widering features in list format
fishing_events_wide <- fishing_events %>%
  unnest_wider(c(distances,event_info),names_sep = "_") %>%
  filter(vessel_flag == "BRA", lon < 0)

# vessel events map 

map_events <- leaflet() %>%
  addTiles() %>%
  addCircleMarkers(
    data = fishing_events_wide,
    ~lon, ~lat,
    popup = ~as.character(vessel_name),
    radius = 1,
    color = "blue",
    fillOpacity = 0.7
  ) %>%
  addPolygons(data = eez_shp, color = "darkolivegreen", weight  = 1, opacity = 0.8) %>%
  
  addLegend(
    position = "bottomright",
    colors = c("blue"),
    labels = c("Brazilian trawlers"),
    opacity = 0.8,
    title = "Event points"
  )

map_events

print("Well done! Now you know where trawlers operate in Brazilian Waters")



