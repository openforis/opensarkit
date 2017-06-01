library(shiny)
library(shinydashboard)
library(shinyFiles)
library(RSQLite)
library(RColorBrewer)
library(shinyjs)
source("helpers.R")
server <- function(input, output, session) {
  
   #------------------------------------------------------------------------------------------------
   # Source Alos K&C
   source(file.path("server","ALOS_KC_tab_server.R"), local=TRUE)$value
   #source(file.path("server","ALOS_ASF_inv_tab_server.R"), local=TRUE)$value
   #source(file.path("server","ALOS_ASF_grd2rtc_tab_server.R"), local=TRUE)$value
   #------------------------------------------------------------------------------------------------
   
   #------------------------------------------------------------------------------------------------
   # source S1 server files
   source(file.path("server","S1_inv_tab_server.R"), local=TRUE)$value
   source(file.path("server","S1_dow_tab_server.R"), local=TRUE)$value
   source(file.path("server","S1_grd2rtc_tab_server.R"), local=TRUE)$value
   source(file.path("server","S1_rtc2ts_tab_server.R"), local=TRUE)$value
   source(file.path("server","S1_ts2mos_tab_server.R"), local=TRUE)$value
   #------------------------------------------------------------------------------------------------
   
   #------------------------------------------------------------------------------------------------
   #mapviewOptions(raster.palette = colorRampPalette(brewer.pal(9, "Greys")))
   #n=mapview(raster("/home/avollrath/Projects/UGA/DEM/DEM_SRTM3V4.1.tif"), legend = TRUE)
   #output$mapplot <- renderMapview(n)
   #------------------------------------------------------------------------------------------------
      
   #------------------------------------------------------------------------------------------------
   # end session by 
   session$onSessionEnded(stopApp)
   
   #-----------------------------------------------------------
   # Links to other tabs
   # Getting started - about
   observeEvent(input$link_to_tabpanel_about, {
     updateTabItems(session, "menus", "about")
   })

   # SAR theory
   observeEvent(input$link_to_tabpanel_sarhistory, {
     updateTabItems(session, "menus", "SARhistory")
   })
      
   # SAR theory
   observeEvent(input$link_to_tabpanel_sartheory, {
   updateTabItems(session, "menus", "SARtheory")
   })
    
   # SAR missions
   observeEvent(input$link_to_tabpanel_sarmissions, {
   updateTabItems(session, "menus", "SARmissions")
   })
    
   # SAR image interpretation
   observeEvent(input$link_to_tabpanel_sarimage, {
   updateTabItems(session, "menus", "SARimage")
   })
    
   # SAR references
   observeEvent(input$link_to_tabpanel_sarrefs, {
   updateTabItems(session, "menus", "SARrefs")
   })
    
   # ALOS K&C
   observeEvent(input$link_to_tabpanel_alos_kc, {
   updateTabItems(session, "menus", "alos_kc")
   })
   
   # ALOS ASF inventory
   observeEvent(input$link_to_tabpanel_alos_inv, {
   updateTabItems(session, "menus", "alos_inv")
   })
   
   # ALOS ASF grd2rtc
   observeEvent(input$link_to_tabpanel_alos_grd2rtc, {
   updateTabItems(session, "menus", "alos_grd2rtc")
   })
    
   # S1 inventory
   observeEvent(input$link_to_tabpanel_s1_inv, {
   updateTabItems(session, "menus", "s1_inv")
   })
   # 
   # S1 download
   observeEvent(input$link_to_tabpanel_s1_dow, {
   updateTabItems(session, "menus", "s1_dow")
   })
    
   # S1 grd2rtc
   observeEvent(input$link_to_tabpanel_s1_grd2rtc, {
   updateTabItems(session, "menus", "s1_grd2rtc")
   })
    
   # S1 grd2rtc-ts
   #observeEvent(input$link_to_tabpanel_s1_grd2ts, {
   #updateTabItems(session, "menus", "s1_grd2rtc-ts")
   #})
   
   # S1 grd2rtc-ts
   observeEvent(input$link_to_tabpanel_s1_ts2mos, {
   updateTabItems(session, "menus", "s1_ts2mos")
   })
} # EOF
