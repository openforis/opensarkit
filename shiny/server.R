library(shiny)
library(shinydashboard)
library(shinyFiles)
library(RSQLite)
library(RColorBrewer)

server <- function(input, output, session) {
  
   #------------------------------------------------------------------------------------------------
   # Source Alos K&C
   source(file.path("server","ALOS_KC_tab_server.R"), local=TRUE)$value
   #------------------------------------------------------------------------------------------------
   
   #------------------------------------------------------------------------------------------------
   # source S1 server files
   source(file.path("server","S1_inv_tab_server.R"), local=TRUE)$value
   #------------------------------------------------------------------------------------------------
   
   #------------------------------------------------------------------------------------------------
   #mapviewOptions(raster.palette = colorRampPalette(brewer.pal(9, "Greys")))
   #n=mapview(raster("/home/avollrath/Projects/UGA/DEM/DEM_SRTM3V4.1.tif"), legend = TRUE)
   #output$mapplot <- renderMapview(n)
   #------------------------------------------------------------------------------------------------
      
   #------------------------------------------------------------------------------------------------
   # end session by 
   session$onSessionEnded(stopApp)
} # EOF
