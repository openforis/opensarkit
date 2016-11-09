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
packages(mapview)
packages(raster)
packages(shinyjs)
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
      
      sidebarMenu(
      br(),
      menuItem("Getting Started", tabName = "about", icon = icon("info"),
         menuSubItem("About OST", tabName = "about", icon = icon("info")),
         menuSubItem("SAR theory", tabName = "SARtheory", icon = icon("info")),
         menuSubItem("SAR missions", tabName = "SARmissions", icon = icon("rocket")),
         menuSubItem("SAR image interpretation", tabName = "SARimage", icon = icon("eye")),
         menuSubItem("SAR references", tabName = "SARrefs", icon = icon("book"))
      ),
      hr(),
      menuItem("ALOS Functionality", tabName = "alos_funct", icon = icon("option-vertical", lib = "glyphicon"),
         menuSubItem("ALOS K&C Mosaics", tabName = "alos_kc", icon = icon("th")),
         menuSubItem("ALOS-1 ASF inventory", tabName = "alos_inv", icon = icon("search")),
         menuSubItem("ALOS-1 ASF processing", tabName = "alos_pro", icon = icon("cogs"))
      ),
      hr(),
      menuItem("Sentinel-1 Functionality", tabName = "s1_funct", icon = icon("option-vertical", lib = "glyphicon"),
         menuSubItem("S1 inventory", tabName = "s1_inv", icon = icon("search")),
         menuSubItem("S1 GRD to RTC processor", tabName = "s1_grd2rtc", icon = icon("cogs")),
         menuSubItem("S1 GRD time-series processor (GRD to RTC)", tabName = "s1_grd2rtc-ts", icon = icon("cogs"))
      ),
      hr(),
      menuItem("Data Viewer", tabName = "dataview", icon = icon("eye")),
      hr(),
      menuItem("Update", tabName = "update_ost", icon = icon("arrow-circle-o-up")),
      menuItem("Source code", icon = icon("file-code-o"),href = "https://github.com/openforis/opensarkit"),
      menuItem("Bug reports", icon = icon("bug"),href = "https://github.com/openforis/opensarkit/issues"),
      hr(),
      menuItem("Stop Server", tabName = "stop_server", icon = icon("off", lib = "glyphicon"))
          
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
      source(file.path("ui","SARtheory.R"), local=TRUE)$value,
      source(file.path("ui","SARmissions.R"), local=TRUE)$value,
      source(file.path("ui","SARimage.R"), local=TRUE)$value,
      source(file.path("ui","SARrefs.R"), local=TRUE)$value,
      #-----------------------------------------------------------------------------
      
      #-----------------------------------------------------------------------------
      # ALOS K&C Tab
      source(file.path("ui","ALOS_KC_tab_ui.R"), local=TRUE)$value,
      
      #-----------------------------------------------------------------------------
      
      #-----------------------------------------------------------------------------
      # Sentinel 1 Tab
      source(file.path("ui","S1_inv_tab_ui.R"), local=TRUE)$value,
      
      #-----------------------------------------------------------------------------
         
      #-----------------------------------------------------------------------------
      # DataViewer Tab
      tabItem(tabName = "dataview",
             fluidRow(
               #mainPanel(
               #leafletOutput("mapplot", width = "100%"),
               #mapview:::plainViewOutput("test")
               )#)
             ),
      #-----------------------------------------------------------------------------
      
      #-----------------------------------------------------------------------------
      # Stop server tab
      tabItem(tabName = "stop_server",
              fluidRow(
                 box(
                    title = "Stop the Shiny Server", status = "danger", solidHeader= TRUE,
                       "This will shutdown your shiny server and all running processes.",br(),
                       "If you have running processes, just close the browser's tab.",
                       br(),
                       br(),
                       actionButton("stop_server","Stop Server")
                    ) # close box
                 ) # close fluidRow
         ) # close tabItem
         #-----------------------------------------------------------------------------

      ) # close tabItemS
   )# close Dashboard Body
) # close Dashboard