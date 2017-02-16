#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_inv",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          
          # for busy indicator 
          useShinyjs(),
          tags$style(appCSS),
          
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
                            "Shapefile (local/ on server)" = "S1_inv_shape_local",
                            "Shapefile (upload a zipped archive)" = "S1_inv_shape_upload")),
             
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
                            "3) Date Range",
                             start = "2014-10-01",
                             end = Sys.Date(),
                             min = "2014-10-01",
                             max = Sys.Date(),
                             format = "yyyy-mm-dd"
                          ),
             
             hr(),
             tags$b("4) Polarisation Mode"),
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
             tags$b("5) Sensor Mode"),
             p("Note: More info on the sensor modes of Sentinel-1 can be found in the Info Panel on the right."),
             radioButtons("s1_inv_sensor_mode", "",
                          c("Interferometric Wide Swath (recommended) " = "iw",
                            "Extra Wide Swath" = "ew",
                            "Wave Mode" = "wv")
             ),
             hr(),
             tags$b("6) Product Level"),
             p("Note: More info on the product levels of Sentinel-1 can be found in the Info Panel on the right."),
             radioButtons("s1_inv_product_level", "",
                          c("Level-1 GRD (recommended) " = "grd",
                            "Level-1 SLC" = "slc",
                            "Level-0 RAW" = "raw")
             ),
             hr(),
             # div(style="display:inline-block",actionButton("s1_kc_process", "Start processing")),
             # div(style="display:inline-block",actionButton("s1_kc_abort", "Abort processing")),
             withBusyIndicatorUI(
                  actionButton("s1_inv_search", "Create an OST inventory shapefile")
             ),
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
                               tags$h4("Sentinel-1 data inventory "),
                               hr(),
                               p("By using the processing panel on the left, it is possible to easily search for data from the Sentinel-1 constellation for a certain area, 
                                  defined by country borders or a self-provided shapefile delimiting the area of interest. Based on this selection, as well as the 
                                  other criteria, an", tags$b("OST inventory shapefile"), "is created. This shapefile shows the footprints of the 
                                  matching scenes and contains further metadata in its attribute table. Thus, the selection of scenes can be further refined
                                  manually. Ultimately, this shapefile is needed for the subsequent", actionLink("link_to_tabpanel_s1_dow", "Data Download"), 
                                  "or as input to the bulk processing routines for the", actionLink("link_to_tabpanel_s1_grd2rtc", "GRD to RTC processor"), "
                                   as well as the", actionLink("link_to_tabpanel_s1_grd2ts", "GRD to RTC time-series processor"),"."),
                               p("Specifications of the acquisition mode can be modified as well. The default values are recommended. 
                                  For more information see the other tabs within this Info Panel."),
                               p(tags$b("Note I:"), "For subsequent processing tasks not all imaging modes are supported. At the moment OST only supports processing of
                                            data acquired over land (i.e. IW sensor mode, VV or VV/VH polarisation) at Level-1 GRD product level. 
                                            Data inventory and download is however possible for all kind of Sentinel-1 data."),
                               p(tags$b("Note II:"), "Dependent on the envisaged analysis, a refinement of the inventory shapefile is", tags$b("highly recommended"),"
                                                      before downloading and processing of data."),
                               p(tags$b("Firstly"),", the search will use a rectangular area bounding the maximum extent of the given 
                                  AOI. Therefore some scenes might not overlap with the actual AOI and should be sorted out. In some rare cases, scenes appear
                                   more than once. Those can be identified by the Start and Stop time within the attrivute table of the OST inventory shapefile"),
                               p(tags$b("Secondly"),", a proper data selection is",tags$b("most important"), "for time-series processing (i.e. GRD to RTC time-series processor) 
                                  and needs additional consideration of the:"),
                               p(tags$b("- minimum extent:"), "The GRD to RTC time-series processor will crop the final time-series and multi-temporal metrics stack
                                  to the smallest common area covered by all acquistions. In other words, if there is one acquisition that only covers a 
                                  part of the AOI, the extent of all output products will hold the respective extent of this particular acquisition. Since ideally 
                                  the whole AOI should be covered, those acquisitions should be sorted out."),
                               p(tags$b("- quality of mosaicking:"), "If the AOI is covered by more than one track, the quality of subsequent mosaicking depends on
                                     the homogeneity of the data selection. All tracks should therefore have the same amount of acquisitions, 
                                     acquired as closely as possible. Thus, effects due to different environmental conditions are reduced and the radiometry of 
                                     the output products are similar.")
                      ),
                             
                      tabPanel("Observation Scenario",
                               tags$h4("Sentinel-1's general acquisition plan"),
                               hr(),
                               p("SENTINEL-1 provides regular global coverage of C-Band SAR data. 
                                  Since the launch of the SENTINEL-1A unit in April 2014, daily data delivery has been increased constantly. 
                                  With the availability of the data from the SENTINEL-1B unit and the integration into the",
                                  a(href = "https://en.wikipedia.org/wiki/European_Data_Relay_System", "European Data Relay System (EDRS)"),
                                  ", constant image acqusition is in place since October 2016."),
                               p("Detailed information on the acquisition strategy can be found", 
                                 a(href = "https://sentinel.esa.int/web/sentinel/missions/sentinel-1/observation-scenario", target = "_blank", "here"), "."),
                               img(src = "Sentinel-1-revisit-frequency.jpg", width = "100%", height = "100%"),
                               tags$b("Figure 1: Revisit and coverage frequency of the SENTINEL-1 constellation as from October 2016 (image courtesy:ESA)."),
                               br(),
                               img(src = "Sentinel-1-mode-polarisation-observation-geometry.jpg", width = "100%", height = "100%"),
                               tags$b("Figure 2: Imaging modes of the SENTINEL-1 constellation as from Ocotber 2016 (image courtesy:ESA).")
                      ),
                      tabPanel("Sensor Mode",
                               tags$h4("Sentinel-1 sensor modes"),
                               tags$i("Note that the content is adapted from"), 
                               a(href = "https://sentinel.esa.int/web/sentinel/missions/sentinel-1", target = "_blank", "ESA's Sentinel-1 webpage."),
                               hr(),
                               p("SENTINEL-1 operates in four exclusive acquisition modes:"),
                               p(tags$b(" - Interferometric Wide Swath (IW):"), " IW is SENTINEL-1's primary operational mode over land masses 
                                     and should be the first choice if regular temporal coverage is needed. Data is acquired in three swaths using the Terrain Observation 
                                     with Progressive Scanning SAR (TOPSAR) imaging technique. In IW mode, bursts are synchronised from pass 
                                     to pass to ensure the alignment of interferometric pairs. "),                               
                               p(tags$b(" - Stripmap (SM):"), " A standard SAR stripmap imaging mode where the ground swath is illuminated with a continuous 
                                     sequence of pulses, while the antenna beam is pointing to a fixed azimuth and elevation angle."),
                               p(tags$b(" - Extra-Wide swath (EW):"), " Data is acquired in five swaths using the TOPSAR imaging technique. 
                                     EW mode provides very large swath coverage at the expense of spatial resolution."),
                               p(tags$b(" - Wave Mode (WV):"), " Data is acquired in small stripmap scenes called vignettes, situated at regular intervals of 100 km 
                                     along track. The vignettes are acquired by alternating, acquiring one vignette at a near range incidence angle 
                                    while the next vignette is acquired at a far range incidence angle. WV is SENTINEL-1's operational mode over open ocean."),
                               img(src = "S1_sensor_modes.jpg", width = "100%", height = "100%"),
                               tags$b("Figure 1: Representation of the different imaging modes by Sentinel-1. (image courtesy:ESA)")
                      ),
                      
                      tabPanel("Processing Level",
                               tags$h4("Sentinel-1 processing levels"),
                               tags$i("Note that the content is adapted from"), 
                               a(href = "https://sentinel.esa.int/web/sentinel/missions/sentinel-1", target = "_blank", "ESA's Sentinel-1 webpage."),
                               hr(),
                               p("SENTINEL-1 data products acquired in SM, IW and EW mode are operationally distributed at three levels of processing."),
                               p(" - Level-0 (Raw)"),
                               p(" - Level-1 (SLC or GRD)"),
                               p(" - Level 2 (Ocean)"),
                               br(),
                               p(tags$b("Note:"), "While it is possible to search and download for SENTINEL-1 data of every product level, OST provides 
                                  only processors for GRD products at the moment."),
                               hr(),
                               img(src = "Sentinel-1_product_types.jpg", width = "100%", height = "100%"),
                               tags$b("Figure 1: Product types for the different sensor modes of Sentinel-1 (image courtesy: ESA)"),
                               br(),
                               br(),
                               p(tags$b("Level-0:"), "The SAR Level-0 products consist of the sequence of Flexible Dynamic Block Adaptive Quantization 
                                 (FDBAQ) compressed unfocused SAR raw data. For the data to be usable, it will need to be decompressed 
                                 and processed using focusing software."),
                               br(),
                               p(tags$b("Level-1: "), "Level-1 data are the generally available products intended for most data users. 
                                  Level-1 products are produced as Single Look Complex (SLC) and Ground Range Detected (GRD)."),
                               p(tags$b("Single Look Complex (SLC)")," products consist of focused SAR data geo-referenced using 
                                  orbit and attitude data from the satellite and provided in zero-Doppler slant-range geometry. 
                                  The products include a single look in each dimension using the full TX signal bandwidth 
                                  and consist of complex samples preserving the phase information."),
                               p(tags$b("Ground Range Detected (GRD)")," products consist of focused SAR data that has been detected,
                                  multi-looked and projected to ground range using an Earth ellipsoid model. Phase information is lost.
                                  The resulting product has approximately square resolution pixels and square pixel spacing with
                                  reduced speckle at the cost of reduced geometric resolution."),
                               p(tags$b("Level-2: "),"OCN products include components for Ocean Swell spectra (OSW) providing continuity with ERS and 
                                  ASAR WV and two new components: Ocean Wind Fields (OWI) and Surface Radial Velocities (RVL).")
                      ),
                      
                      tabPanel("Polarisation Modes",
                               tags$h4("Sentinel-1 polarisation modes"),
                               br(),
                               p("The C-SAR instrument of Sentinel-1 supports operation in dual polarisation (HH+HV, VV+VH) implemented through 
                                  one transmit chain (switchable to H or V) and two parallel receive chains for H and V polarisation. 
                                  Dual polarisation data is useful for land cover classification and sea-ice applications.")
                      ),
                      
                      tabPanel("References",
                               br(),
                               tags$h4("References"),
                               tags$b("Information Material"),
                               p("ESA (2016): Sentinel-1. Radar Vision for Copernicus", a (href = "http://esamultimedia.esa.int/multimedia/publications/sentinel-1/", target = "_blank", "Link"),"."),
                               tags$b("Websites"),
                               
                               tags$b("Scientific Articles"),
              
                               p("Torres et al. (2012): ")
                               
                      ),
                      tabPanel("Legal Notices",
                               br(),
                               tags$h4("Legal notices regarding the access of Sentinel-1 data."),
                               p("Generally speaking, the use of Coperincus Sentinel data (including Sentinel-1) is open and free. However, any public
                                  communication material shall include a notice on the use and/or modification of the data.
                                 The full text on the use of Copernicus Sentinel Data and Service Information can be found",
                                 a(href = "https://sentinels.copernicus.eu/documents/247904/690755/Sentinel_Data_Legal_Notice", target = "_blank", "here." )
                               
                      )
                  ) # close tab box
           ) # close box
        )
)
)