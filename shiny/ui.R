#-----------------------------------------------------------------------------------
#
#
#
#
#-----------------------------------------------------------------------------------

options(stringsAsFactors=FALSE)
#options(shiny.launch.browser=T)
#-----------------------------------------------------------------------------------
# include all the needed packages here 

packages <- function(x){
   x <- as.character(match.call()[[2]])
   if (!require(x,character.only=TRUE)){
      install.packages(pkgs=x,repos="http://cran.r-project.org")
      require(x,character.only=TRUE)
   }
}
#-----------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------
# load libraries
packages(shiny)
packages(shinydashboard)
packages(shinyFiles)
packages(RSQLite)
packages(random)
#packages(mapview)
packages(raster)
packages(shinyjs)
packages(parallel)
source("helpers.R")
#-----------------------------------------------------------------------------------


#-----------------------------------------------------------------------------------
# create UI for dashboard
ui = dashboardPage(
     skin = 'green',
   #-----------------------------------------------------------------------------------
   # title
   dashboardHeader(
      title = "Open Foris SAR Toolkit",
      #windowTitle = "Open Foris SAR Toolkit",
      titleWidth = 250
      ),
   #-----------------------------------------------------------------------------------
   
   
   #-----------------------------------------------------------------------------------
   # sidebar menu
   dashboardSidebar(
      width = 250,
      
      sidebarMenu(id = "menus",
      br(),
      menuItem("Getting Started", tabName = "info", icon = icon("info"),
         menuSubItem("About OST", tabName = "about", icon = icon("info")),
         menuSubItem("SAR history", tabName = "SARhistory", icon = icon("info")),
         menuSubItem("SAR theory", tabName = "SARtheory", icon = icon("info")),
         menuSubItem("SAR missions", tabName = "SARmissions", icon = icon("rocket")),
         menuSubItem("SAR image interpretation", tabName = "SARimage", icon = icon("eye")),
         menuSubItem("SAR references", tabName = "SARrefs", icon = icon("book"))
      ),
      hr(),
      menuItem("ALOS K&C initiative", tabName = "alos_funct", icon = icon("option-vertical", lib = "glyphicon"),
         menuSubItem("Backscatter download", tabName = "alos_kc_dow", icon = icon("download")),
         menuSubItem("Backscatter processing", tabName = "alos_kc_pro", icon = icon("th")),
         menuSubItem("FNF map download", tabName = "alos_kc_fnf", icon = icon("th")) #,
         #menuSubItem("Data inventory (ASF server)", tabName = "alos_inv", icon = icon("search")),
         #menuSubItem("GRD to RTC processor", tabName = "alos_pro", icon = icon("cogs"))
      ),
      hr(),
      menuItem("Sentinel-1", tabName = "s1_funct", icon = icon("option-vertical", lib = "glyphicon"),
         menuSubItem("Data inventory", tabName = "s1_inv", icon = icon("search")),
         menuSubItem("Data download", tabName = "s1_dow", icon = icon("download")),
         menuSubItem("GRD to RTC processor", tabName = "s1_grd2rtc", icon = icon("cogs")),
         menuSubItem("Time-series/Timescan processor ", tabName = "s1_rtc2ts", icon = icon("cogs")),
         menuSubItem("Time-series/Timescan mosaics ", tabName = "s1_ts2mos", icon = icon("map-o"))
      ),
      hr(),
      #menuItem("Data Viewer", tabName = "dataview", icon = icon("eye")),
      #hr(),
      #menuItem("Update", tabName = "update_ost", icon = icon("arrow-circle-o-up")),
      menuItem("Source code", icon = icon("file-code-o"),href = "https://github.com/openforis/opensarkit"),
      menuItem("Bug reports", icon = icon("bug"),href = "https://github.com/openforis/opensarkit/issues") #,
      #hr(),
      #menuItem("Stop Server", tabName = "stop_server", icon = icon("off", lib = "glyphicon"))
          
          ) # close sidebarMenu
      ), # close dashboardSidebar
   #-----------------------------------------------------------------------------------
   
   
   #-----------------------------------------------------------------------------------
   # main body
   dashboardBody(
     tabItems(
      
      #-----------------------------------------------------------------------------
      # About OST tab
      source(file.path("ui","About_OST.R"), local=TRUE)$value,
      source(file.path("ui","SARhistory.R"), local=TRUE)$value,
      source(file.path("ui","SARtheory.R"), local=TRUE)$value,
      source(file.path("ui","SARmissions.R"), local=TRUE)$value,
      source(file.path("ui","SARimage.R"), local=TRUE)$value,
      source(file.path("ui","SARrefs.R"), local=TRUE)$value,
      #-----------------------------------------------------------------------------
      
      #-----------------------------------------------------------------------------
      # ALOS K&C Tab
      source(file.path("ui","ALOS_KC_dow_ui.R"), local=TRUE)$value,
      source(file.path("ui","ALOS_KC_pro_ui.R"), local=TRUE)$value,
      source(file.path("ui","ALOS_KC_fnf_ui.R"), local=TRUE)$value,
      #source(file.path("ui","ALOS_ASF_inv_tab_ui.R"), local=TRUE)$value,
      #source(file.path("ui","ALOS_ASF_grd2rtc_tab_ui.R"), local=TRUE)$value,
      #-----------------------------------------------------------------------------
      
      #-----------------------------------------------------------------------------
      # Sentinel 1 Tab
      source(file.path("ui","S1_inv_tab_ui.R"), local=TRUE)$value,
      source(file.path("ui","S1_dow_tab_ui.R"), local=TRUE)$value,
      source(file.path("ui","S1_grd2rtc_tab_ui.R"), local=TRUE)$value,
      source(file.path("ui","S1_rtc2ts_tab_ui.R"), local=TRUE)$value,
      source(file.path("ui","S1_ts2mos_tab_ui.R"), local=TRUE)$value #,
      #-----------------------------------------------------------------------------
         
      #-----------------------------------------------------------------------------
      # DataViewer Tab
      #tabItem(tabName = "dataview",
      #       fluidRow(
               #mainPanel(
               #leafletOutput("mapplot", width = "100%"),
               #mapview:::plainViewOutput("test")
      #         )#)
      #      ),
      #-----------------------------------------------------------------------------
      
      #-----------------------------------------------------------------------------
      # Stop server tab
      #tabItem(tabName = "stop_server",
      #        fluidRow(
      #           box(
      #              title = "Stop the Shiny Server", status = "danger", solidHeader= TRUE,
      #                 "This will shutdown your shiny server and all running processes.",br(),
      #                 "If you have running processes, just close the browser's tab.",
      #                 br(),
      #                 br(),
      #                 actionButton("stop_server","Stop Server")
      #              ) # close box
      #           ) # close fluidRow
      #   ) # close tabItem
         #-----------------------------------------------------------------------------

      ) # close tabItemS
   )# close Dashboard Body
) # close Dashboard