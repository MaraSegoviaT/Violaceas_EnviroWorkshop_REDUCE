#-------------------------------------------------------------------------------
#
# Title: Download data from CMEMS
# Course: Environmental Data Extraction and Analysis from Satellite Telemetry and Other Sources
#
# Author: David Ruiz-García
# Email: david.ruiz-garcia@uv.es
# Last revision: 2025/03/13
#
#-------------------------------------------------------------------------------
library(readxl)

# 1.Prepare your dataset--------------------------------------------------------

# 1.1. Open your dataset:
data <- read_excel("E:/DINACON/Paper violaceas/EnviroRWorkshop_REDUCE/R/input/avistamientos_violacea_med_esp.xlsx")
View(data)
head(data)

# How many dates do we have?
# Convertir a solo fecha (sin hora)
library(dplyr)
data <- data %>%
  mutate(Fecha_solo = as.Date(Fecha))
data <- data %>%
  filter(!is.na(Fecha_solo)) %>%  # eliminar filas sin fecha
  mutate(
    start_datetime = paste0(Fecha_solo, "T00:00:00Z"),
    end_datetime   = paste0(Fecha_solo, "T23:59:59Z")
  )

# Contar fechas únicas
num_fechas_unicas <- n_distinct(data$Fecha_solo)
print(num_fechas_unicas)
# Response: 288


# Plot data to have a reference:
library(rnaturalearth)
library(rnaturalearthdata)
library(ggplot2)
library(rlang)
library(viridis)

# Load land mask:
world <- ne_countries(scale = "medium", returnclass = "sf")
# Make plot:

# Zoom in:
ggplot() +
  geom_sf(data = world, fill = "gray90", color = "gray40") +
  geom_point(data = data, aes(x = Long, y = Lat, color = Inds), size = 1) +
  scale_color_viridis_c(name = "Inds", option = "D", direction = -1) +
  coord_sf(xlim = range(data$Long, na.rm = TRUE) + c(-1, 1),
           ylim = range(data$Lat, na.rm = TRUE) + c(-1, 1), expand = FALSE) +
  theme_minimal() +
  labs(title = "Observation Locations",
       x = "Longitude", y = "Latitude")

# Zoom out:
ggplot() +
  geom_sf(data = world, fill = "gray90", color = "gray40") +
  geom_point(data = data, aes(x = Long, y = Lat, color = Inds), size = 0.5) +
  scale_color_viridis_c(name = "Inds", option = "D", direction = -1) +
  coord_sf(xlim = range(data$Long, na.rm = TRUE) + c(-10, 15),
           ylim = range(data$Lat, na.rm = TRUE) + c(-10, 10), expand = FALSE) +
  theme_minimal() +
  labs(title = "Observation Locations",
       x = "Longitude", y = "Latitude")


# 1.2. Make a dataset with your dates:
# We are going to work with a daily resolution, then we want to adjust the download to those days in which you have data. 
# Set date format as "date" (year-moth-day)
# Usar la columna que ya convertiste a Date
Days <- unique(data$Fecha_solo)
# Crear dataframe con las fechas únicas
Days_df <- data.frame(Days = Days)
# Asegurar el formato Date (por si acaso)
Days_df$Days <- as.Date(Days_df$Days)
# Ver las primeras filas
head(Days_df)

# We may want to have a year, month and day columns to later organise the downloading of files
# Add a new column with the year information
Days_df <- Days_df %>%
  mutate(Year = format(Days, "%Y"),
         Month = format(Days, "%m"),
         Day = format(Days, "%d"))
head(Days_df)


# 2. Prepare your catalog------------------------------------------------------

# 2.1. Import data catalog
# Remember, the catalog is where you have the required information for download
catalog <- read.csv2("E:/DINACON/Paper violaceas/EnviroRWorkshop_REDUCE/R/input/Catalog_CMEMS_05-25.csv", sep=";")
View(catalog)

# Check it out and ensure numerical variables are numeric
str(catalog) 

# Convert to numerical if they aren't:
catalog <- catalog %>%
  mutate(
    xmin = as.numeric(gsub(",", ".", xmin)),
    xmax = as.numeric(gsub(",", ".", xmax)),
    ymin = as.numeric(gsub(",", ".", ymin)),
    ymax = as.numeric(gsub(",", ".", ymax)))
str(catalog)


# 3. Log-in in CMEMS through Command Line Interface (CLI) ----------------------
# For more info: https://help.marine.copernicus.eu/en/articles/8638253-how-to-download-data-via-the-copernicus-marine-toolbox-in-r

# 3.1. Install python (you should have done this in the package installing part)
library(reticulate)
#install_python() 
# 3.2. Create an environment (you should have done this in the package installing part)
#virtualenv_create(envname = "cmems")
#virtualenv_install("cmems", packages = c("copernicusmarine"))

# 3.3. Load into your environment
use_virtualenv("cmems", required = TRUE)
cm <- import("copernicusmarine")
username <- "masetru@alumni.uv.es"
password <- "Carryon9"

cred_file <- "C:/Users/maras/.copernicusmarine/.copernicusmarine-credentials"
if (file.exists(cred_file)) {
  file.remove(cred_file)  # Borra el archivo viejo para evitar el prompt
}

cm$login(username, password)

# 4. Download CMEMS data -------------------------------------------------------
# 4.1. Download a single file:
# Let's start with the first product on the first date:
cat <- catalog %>%
  filter(id_product  %in% c("1")) 

# Required information for download:
dataset_id <- cat$dataset_id
print(dataset_id)

start_datetime <- min(Days_df$start_datetime)
print(start_datetime)

end_datetime <- max(Days_df$end_datetime)
print(end_datetime)

# Variables (soporta 1 o varias, ej. "uo, vo")
variables <- as.list(strsplit(cat$var[1], ",\\s*")[[1]])
print(variables)
str(variables)

minimum_longitude <- cat$xmin
print(minimum_longitude)

maximum_longitude <-  cat$xmax
print(maximum_longitude)

minimum_latitude <-  cat$ymin
print(minimum_latitude)

maximum_latitude <- cat$ymax
print(maximum_latitude)

#minimum_depth <- cat$depth_min
#3print(minimum_depth)

#maximum_depth <- cat$depth_max
#print(maximum_depth)

# Naming the file:
output_filename <- paste0(cat$var_name, "_", Days_df$Days[1], ".nc")
print(output_filename)

# Selecting where to save it:
# Generate a folder within input
destination_folder <- paste0("R/input/cmems_02_25")
if (!dir.exists(destination_folder)) dir.create(destination_folder, recursive = TRUE)
print(destination_folder)

# Generate a folder for the product
output_directory <- file.path(
  destination_folder,
  Days_df$Year[1],
  Days_df$Month[1],
  Days_df$Day[1]
)

if (!dir.exists(output_directory)) {
  dir.create(output_directory, recursive = TRUE)
}

# Download:
cm$subset(dataset_id = dataset_id,
          start_datetime = df_dates$start_datetime[j],
          end_datetime   = df_dates$end_datetime[j],
          variables = variables,
          minimum_longitude = minimum_longitude,
          maximum_longitude = maximum_longitude,
          minimum_latitude = minimum_latitude,
          maximum_latitude = maximum_latitude,
          #minimum_depth = minimum_depth,
          #maximum_depth = maximum_depth,
          output_filename = output_filename,
          output_directory = output_directory)

# Check the file:
library(ncdf4)
library(raster)

# 2D netCDF files:
path <- paste0(output_directory, "/", output_filename)
nc <- nc_open(path)
nc

# extract data to check it out:
lon <- nc$dim$lon$vals
print(lon)

lat <- nc$dim$lat$vals
print(lat)

depth <- nc$dim$depth$vals
print(depth)

time <- nc$dim$time$vals
print(time)

# Convert format
reference_date <- as.POSIXct("1950-01-01 00:00:00", tz = "UTC")
# Convert hours to seconds and add to reference date
time_converted <- reference_date + time * 3600  # 1 hour = 3600 seconds
print(time_converted)

# Calculate the resolution in latitude and longitude
lat_resolution <- abs(lat[2] - lat[1])
lon_resolution <- abs(lon[2] - lon[1])
print(lat_resolution)
print(lon_resolution)



# 4.2. Download a group of variables and/or dates-------------------------------
# Subset dates and products if you wish:
# Define the time subset you want:
df <- Days_df 
head(df)

# Define the catalog subset you want:
cat <- catalog
head(cat)
#cat <- catalog %>%
#  filter(dimensions %in% c("2D")) 

# Create folder where you are going to save to files:
# Carpeta de destino
destination_folder <- "R/input/cmems_trial"
if (!dir.exists(destination_folder)) dir.create(destination_folder, recursive = TRUE)

# Bucle por producto
for(i in 1:nrow(catalog)) {
  
  # Subset del catálogo
  cat <- catalog[i, ]
  
  # Separar variables si hay varias
  variables <- strsplit(cat$var, ",\\s*")[[1]]
  
  # Fechas de ese producto
  start_date <- as.Date(cat$date_min_total, format="%d/%m/%Y")
  end_date   <- as.Date(cat$date_max_total, format="%d/%m/%Y")
  
  # Subset de Days_df que coincidan
  df_dates <- Days_df %>% filter(Days >= start_date & Days <= end_date)
  
  for(j in 1:nrow(df_dates)) {
    
    day <- df_dates$Days[j]
    day_with_time <- df_dates$Days_with_time[j]
    
    # Carpeta por año/mes/día
    date_dir <- file.path(destination_folder,
                          df_dates$Year[j],
                          df_dates$Month[j],
                          df_dates$Day[j])
    if(!dir.exists(date_dir)) dir.create(date_dir, recursive = TRUE)
    
    # Nombre del archivo
    file_name <- paste0(cat$var_name, "_", day, ".nc")
    
    # Subset
    cm$subset(
      dataset_id = cat$dataset_id,
      start_datetime = day_with_time,
      end_datetime   = day_with_time,
      variables      = as.list(variables),
      minimum_longitude = cat$xmin,
      maximum_longitude = cat$xmax,
      minimum_latitude  = cat$ymin,
      maximum_latitude  = cat$ymax,
      output_filename   = file_name,
      output_directory  = date_dir
    )
    
    cat(paste("Descargado:", file_name, "\n"))
  }
}

Sys.time() - t 


# Check the 3D file:
path <- paste0(output_directory, "/CHL_Analysis_3D_2024-12-25.nc")
nc <- nc_open(path)
nc

# extract data to check it out:
lon <- nc$dim$lon$vals
print(lon)

lat <- nc$dim$lat$vals
print(lat)

depth <- nc$dim$depth$vals
print(depth)

time <- nc$dim$time$vals
print(time)

# Convert format
reference_date <- as.POSIXct("1950-01-01 00:00:00", tz = "UTC")
# Convert hours to seconds and add to reference date
time_converted <- reference_date + time * 3600  # 1 hour = 3600 seconds
print(time_converted)

# Calculate the resolution in latitude and longitude
lat_resolution <- abs(lat[2] - lat[1])
lon_resolution <- abs(lon[2] - lon[1])
print(lat_resolution)
print(lon_resolution)
