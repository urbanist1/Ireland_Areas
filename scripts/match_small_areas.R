# ---- Load Required Packages ----
library(sf)
library(ggplot2)
library(dplyr)
library(httr)
library(smoothr)
library(here)

# ---- Setup: Clear Environment and Create Folders ----
rm(list = ls())

data_dir <- here("data", "spat_files")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

# ---- Download GeoJSON Files (Small Areas 2016 & 2022) ----
urls <- c(
  "https://data-osi.opendata.arcgis.com/api/download/v1/items/70a33cbb8bd7406da0d571be28624721/geojson?layers=0",
  "https://data-osi.opendata.arcgis.com/api/download/v1/items/51b0644d257143ba953f56b34558a4e0/geojson?layers=0"
)

files <- c("sa22.geojson", "sa16.geojson")

for (i in seq_along(urls)) {
  file_path <- file.path(data_dir, files[i])
  
  if (!file.exists(file_path)) {
    message("Downloading: ", files[i])
    GET(urls[i], write_disk(file_path, overwrite = TRUE))
  } else {
    message("File already exists: ", files[i])
  }
}

message("Download process completed.")

# ---- Load and Clean Spatial Data ----
d_16 <- st_read(file.path(data_dir, "sa16.geojson"))
d_22 <- st_read(file.path(data_dir, "sa22.geojson"))

# Reproject to EPSG:3035
d_16 <- st_transform(d_16, crs = 3035)
d_22 <- st_transform(d_22, crs = 3035)

# Validate and repair geometries
d_16 <- st_make_valid(d_16)
d_22 <- st_make_valid(d_22)

# Save cleaned shapefiles
st_write(d_16, file.path(data_dir, "sa16_clean.geojson"), append = FALSE, driver = "ESRI Shapefile")
st_write(d_22, file.path(data_dir, "sa22_clean.geojson"), append = FALSE, driver = "ESRI Shapefile")

# ---- Prepare Geometry and Area Calculations ----
d_16 <- d_16["GUID"]
colnames(d_16)[1] <- "guid_16"
d_16$area_16 <- as.numeric(st_area(d_16))

d_22 <- d_22["GUID"]
colnames(d_22)[1] <- "guid_22"
d_22$area_22 <- as.numeric(st_area(d_22))

# ---- Perform Spatial Intersection ----
g_inter <- st_intersection(d_16, d_22)
g_inter$area_int <- as.numeric(st_area(g_inter))
g_inter$shr_area <- round(100 * (g_inter$area_int / g_inter$area_22), 1)

# Filter overlaps > 1%
g_inter <- g_inter[g_inter$shr_area > 1, ]

# ---- Build Unique ID Key Between guid_16 and guid_22 ----
g_sub <- g_inter[c("guid_16", "guid_22")]
g_sub <- st_drop_geometry(g_sub) %>% distinct()
g_sub$rank <- seq_len(nrow(g_sub))

val_key <- g_sub

for (i in 1:50) {
  val_key <- val_key %>%
    group_by(guid_16) %>%
    mutate(rank = min(rank)) %>%
    ungroup() %>%
    group_by(guid_22) %>%
    mutate(rank = min(rank)) %>%
    ungroup() %>%
    distinct(guid_16, guid_22, rank)
}

val_key$agg_key <- paste0("A_", val_key$rank)

# ---- Create Mapping Keys ----
key16 <- val_key %>% select(guid_16, agg_key) %>% distinct()
key22 <- val_key %>% select(guid_22, agg_key) %>% distinct()

# ---- Sanity Check: One Key Per GUID ----
keycount16 <- key16 %>% group_by(guid_16) %>% summarise(n = n())
keycount22 <- key22 %>% group_by(guid_22) %>% summarise(n = n())

# ---- Dissolve SA 2022 Geometries Based on agg_key ----
grid_22 <- merge(d_22, key22, by = "guid_22")

dissolved <- grid_22 %>%
  group_by(agg_key) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")

# ---- Save All Output Files into spat_files ----
st_write(dissolved, file.path(data_dir, "ire_common_16_22.shp"), append = FALSE)
st_write(d_16, file.path(data_dir, "ire_sa_16.shp"), append = FALSE)
st_write(d_22, file.path(data_dir, "ire_sa_22.shp"), append = FALSE)

write.csv(key16, file.path(data_dir, "key16.csv"), row.names = FALSE)
write.csv(key22, file.path(data_dir, "key22.csv"), row.names = FALSE)

message("✅ All outputs saved to data/spat_files/")

