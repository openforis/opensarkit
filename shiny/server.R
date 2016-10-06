library(shiny)
library(shinydashboard)
library(shinyFiles)
library(RSQLite)
library(RColorBrewer)

server <- function(input, output, session) {
  
   #------------------------------------------------------------------------------------------------
   # 1 Choose a folders or files locally within your home directory with shinyFiles package
   output$project_dir = renderPrint({
 
      # root directory for file selection
      volumes = c('User directory'=Sys.getenv("HOME"))
      #volumes = getVolumes()
      # Directory choice
      shinyDirChoose(input, 'directory', roots=volumes)

      validate (
         need(input$directory != "","No folder selected"),
         errorClass = "missing-folder"
      )
   
      #if (input$directory == ""){
       #  "Please choose"
      #} else {
      df = parseDirPath(volumes, input$directory)
      cat(df) #}
      })
      
   # File choice
   output$filepath = renderPrint({
      
      volumes = c('User directory'=Sys.getenv("HOME"))
      shinyFileChoose(input, 'shapefile', roots=volumes, filetypes=c('shp'))
   
      validate (
         need(input$shapefile != "","No shapefile selected"),
         errorClass = "missing-shapefile"
      )
   
      df = parseFilePaths(volumes, input$shapefile)
      file_path = as.character(df[,"datapath"])
      })
   
   
   #------------------------------------------------------------------------------------------------
   
   #------------------------------------------------------------------------------------------------
   # Process Alos K&C
   source(file.path("server","ALOS_tab_server.R"), local=TRUE)$value
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
