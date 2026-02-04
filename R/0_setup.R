#-------------------------------------------------------------------------------
#
# Title: Setup project directories
# Course: Environmental Data Extraction and Analysis from Satellite Telemetry and Other Sources
#
# Authors: Sarah Saldanha, David March, David Ruiz-García
# Last revision: 2025/03/13
#
#-------------------------------------------------------------------------------
#--------------------------------------------------------------------------------
# setup.R         Setup project
#--------------------------------------------------------------------------------

# 1. Set main data paths--------elegir------------------------------------------------
cpu <- "maraIRTA"  #IRTA
cpu <- "maraPC"  #IRTA

# 1.1. Write the path to the folder where you have your data:
#####IRTA
if(cpu == "maraIRTA") main_dir <- "C:/Users/MSEGOVIA/Desktop/EnviroRWorkshop_REDUCE"
if(cpu == "maraPC") main_dir <- "E:/DINACON/Paper violaceas/EnviroRWorkshop_REDUCE"
print(main_dir)


# If directory doesn't exist yet, create it:
if (!dir.exists(main_dir)) dir.create(main_dir, recursive = TRUE)
# Set as main directory (so you don't need to write the full path anymore)
setwd(main_dir)


# 1.2. Create data paths:
# input is where you will save your data
input_data <- paste(main_dir, "input", sep="/")
if (!dir.exists(input_data)) dir.create(input_data, recursive = TRUE)

# output is where you will save the analyses done based on your data
output_data <- paste(main_dir, "output", sep="/")
if (!dir.exists(output_data)) dir.create(output_data, recursive = TRUE)

# 1.3. load CEMEMS username / password
# To avoid writing your user and password here (visible to anyone with access) keep it a txt file
if(cpu == "maraIRTA") path <- "C:/Users/MSEGOVIA/Desktop/SDM/CEMEMSuser.txt"
username <- paste(readLines(path, warn = FALSE), collapse = "")
if(cpu == "maraIRTA") path <- "C:/Users/MSEGOVIA/Desktop/SDM/CEMEMSpsw.txt"
password <- paste(readLines(path, warn = FALSE), collapse = "")

if(cpu == "maraPC") path <- "E:/DINACON/Paper violaceas/SDM/CEMEMSuser.txt"
username <- paste(readLines(path, warn = FALSE), collapse = "")
if(cpu == "maraPC") path <- "E:/DINACON/Paper violaceas/SDM/CEMEMSpsw.txt"
password <- paste(readLines(path, warn = FALSE), collapse = "")
