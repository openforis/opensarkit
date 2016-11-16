#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_inv",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          #----------------------------------------------------------------------------------
          # Processing Panel Sentinel-1
          box(
             # Title                     
             title = "Processing Panel", status = "success", solidHeader= TRUE,
             tags$h4("Sentinel-1 data inventory"),
             hr(),
             tags$b("1) Project Directory:"),
             p("Note: A new folder named \"Inventory\" will be created within your Project directory. 
                This folder contains the inventory shapefile that is produced by this interface."),
             #br(),
             #div(style="display:inline-block",shinyDirButton('directory', 'Browse', 'Select a folder')),
             #div(style="display:inline-block",verbatimTextOutput("project_dir")),
             shinyDirButton('S1_inv_directory', 'Browse', 'Select a folder'),
             br(),
             br(),
             verbatimTextOutput("S1_inv_project_dir"),
             hr(),
             tags$b("2) Area of Interest"),
             p("Note: This parameter will define the spatial extent of the processing. You can either choose the borders of a country or a shapefile that bounds your area of interest."),
             # AOI choice
             radioButtons("S1_inv_AOI", "",
                          c("Country boundary" = "S1_inv_country",
                            "Shapefile (on Server/local)" = "S1_inv_shape_local",
                            "Shapefile (upload)" = "S1_inv_shape_upload")),
             
             conditionalPanel(
               "input.S1_inv_AOI == 'S1_inv_country'",
               selectInput(
                     inputId = 'S1_inv_countryname', 
                     label = '',
                     choices = dbGetQuery(
                     dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                     sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                     selected=NULL)
             ),
             
             conditionalPanel(
                    "input.S1_inv_AOI == 'S1_inv_shape_local'",
                     #div(style="display:inline-block",shinyFilesButton("shapefile","Choose file","Choose one or more files",FALSE)),
                     #div(style="display:inline-block",textOutput("filepath"))
                     shinyFilesButton("S1_inv_shapefile","Browse","Choose one shapefile",FALSE),
                     br(),
                     br(),
                     verbatimTextOutput("S1_inv_filepath")
             ),
             
             conditionalPanel(
                    "input.S1_inv_AOI == 'S1_inv_shape_upload'",
                     fileInput('S1_inv_shapefile_path', label = '',accept = c(".shp"))
             ),
             
             hr(),
             
             dateRangeInput("s1_inv_daterange",
                            "Date Range",
                             start = "2014-10-01",
                             end = Sys.Date(),
                             min = "2014-10-01",
                             max = Sys.Date(),
                             format = "yyyy-mm-dd"
                          ),
             
             hr(),
             tags$b("3) Polarisation Mode"),
             p("Note: More info on the polarisation modes of Sentinel-1 can be found in the Info Panel on the right."),
             selectInput("s1_inv_pol", "",
                       c("Dual-pol (VV+VH) " = "dual_vv",
                         "Single-pol (VV)" = "vv",
                         "Dual-pol (VV+VH) & Single-pol (VV) " = "dual_single_vv",
                         "Dual-pol (HH+HV)" = "dual_hh",
                         "Single-pol (HH)" = "hh",
                         "Dual-pol (HH+HV) & Single-pol (HH) " = "dual_single_hh")
             ),
             hr(),
             tags$b("4) Sensor Mode"),
             p("Note: More info on the sensor modes of Sentinel-1 can be found in the Info Panel on the right."),
             radioButtons("s1_inv_sensor_mode", "",
                          c("Interferometric Wide Swath (recommended) " = "iw",
                            "Extra Wide Swath" = "ew",
                            "Wave Mode" = "wv")
             ),
             hr(),
             tags$b("5) Product Level"),
             p("Note: More info on the product levels of Sentinel-1 can be found in the Info Panel on the right."),
             radioButtons("s1_inv_product_level", "",
                          c("Level-1 GRD (recommended) " = "grd",
                            "Level-1 SLC" = "slc",
                            "Level-0 RAW" = "raw")
             ),
             hr(),
             # div(style="display:inline-block",actionButton("s1_kc_process", "Start processing")),
             # div(style="display:inline-block",actionButton("s1_kc_abort", "Abort processing")),
             actionButton("s1_inv_search", "Create an OST inventory shapefile"),
             br(),
             textOutput("searchS1_inv")
          ), # close box
          #----------------------------------------------------------------------------------
          
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
             box(
               title = "Info Panel", status = "success", solidHeader= TRUE,
               
               tabBox(width = 700,
                      
                      tabPanel("General Info",
                               tags$h4("Sentinel-1 inventory "),
                               p("Sentinel-1 is a constellation of 2 C-band SAR satellites."),
                               p("By using this script you can check for data availability. In detail, the script 
                                 will create a shapefile with additonal metadata for the all scenes found. This 
                                 script can later be used for the processing"),
                               img(src = "Sentinel-1.jpg", width = "100%", height = "100%")
                               
                               ),
                      
                      tabPanel("Sensor Mode",
                               tags$h4("Sentinel-1 sensor modes"),
                               br(),
                               p("Taken from https://sentinel.esa.int/web/sentinel/missions/sentinel-1/instrument-payload"),
                               br(),
                               p("SENTINEL-1 carries a single C-band synthetic aperture radar instrument operating at a centre 
                                   frequency of 5.405 GHz. It includes a right-looking active phased array antenna providing fast
                                   scanning in elevation and azimuth, data storage capacity of 1 410 Gb and 520 Mbit/s X-band downlink
                                   capacity."),
                               br(),
                               p("The C-SAR instrument supports operation in dual polarisation (HH+HV, VV+VH) implemented through 
                                    one transmit chain (switchable to H or V) and two parallel receive chains for H and V polarisation. 
                                    Dual polarisation data is useful for land cover classification and sea-ice applications."),
                               br(),
                               p("SENTINEL-1 operates in four exclusive acquisition modes:"),
                               p(" - Stripmap (SM)"),
                               p(" - Interferometric Wide Swath (IW)"),
                               p(" - Extra-Wide swath (EW)"),
                               p(" - Wave Mode (WV)"),
                               img(src = "S1_sensor_modes.jpg", width = "100%", height = "100%")
                      ),
                      
                      tabPanel("Processing Level",
                               tags$h4("Sentinel-1 processing levels"),
                               br(),
                               p("Sentinel-1 data is provided in different product levels.")
                      ),
                      
                      tabPanel("Polarisation Modes",
                               tags$h4("Sentinel-1 polarisation modes"),
                               br(),
                               p("Sentinel-1 can acquire data in different polarizations.")
                      ),
                      
                      tabPanel("References",
                               br(),
                               "Interesting results can be found in the Kyoto and Carbon booklet provided by the Japanese Space Agnecy",br(),
                               "http://www.eorc.jaxa.jp/ALOS/en/kyoto/ref/KC-Booklet_2010_comp.pdf",
                               "References"
                      )
                  ) # close tab box
           ) # close box
        )
)