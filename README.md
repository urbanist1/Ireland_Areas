# Ireland_Areas

This R project identifies and constructs a common spatial boundary between the **2016 and 2022 Small Areas** in Ireland using publicly available geospatial data.

## 🔍 Objective

To create a **many-to-many mapping** between 2016 and 2022 small areas and derive a set of **common spatial units** for longitudinal or comparative analysis across census years.

---

## 📁 Project Structure

├── data/
│ └── spat_files/ # Downloaded and cleaned GeoJSON/shapefiles (ignored in Git)
├── output/ # Output shapefiles and key mapping tables
├── scripts/
│ └── match_small_areas.R # Main analysis script
├── .gitignore
├── README.md
├── Ireland_Areas.Rproj


## 📦 Requirements

Install the following R packages:

```r
install.packages(c("sf", "dplyr", "ggplot2", "httr", "smoothr", "here"))
🚀 Usage
Run the main script:

r
Copy
Edit
source("scripts/match_small_areas.R")
It will:

Download 2016 and 2022 small area boundaries from Irish government sources

Reproject and clean geometries

Perform spatial intersection and eliminate minor overlaps

Create a shared aggregation key linking small areas across years

Output:

Cleaned shapefiles

Aggregated spatial units

Mapping tables (key16.csv, key22.csv)

📂 Output Files
Saved to the output/ folder:

ire_common_16_22.shp: Aggregated common boundaries

ire_sa_16.shp, ire_sa_22.shp: Cleaned input boundaries

key16.csv, key22.csv: Mapping tables

🔒 Notes
The folder data/spat_files/ is ignored in Git (.gitignore) to avoid uploading large files.

You can run the script multiple times — files will only download if not already present.

📚 Data Sources
Central Statistics Office (CSO) Small Area Boundaries

Tailte Éireann / Ordnance Survey Ireland Open Data Portal

🧑‍💻 Author
Paul Kilgarriff
Feel free to fork, use, or contribute!