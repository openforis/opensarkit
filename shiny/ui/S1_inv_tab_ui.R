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
             
    
             tabBox(width = 700,
                    tabPanel("Automatic data inventory",
                      tags$h4("Automated Sentinel-1 data inventory"),hr(),
                      tags$b("Short description:"),
                      p("While the observation scenario of Sentinel-1 foresees systematic acquisitions worldwide, repeat and revisit will still vary across adjacent acquisition swaths.     
                         The large-scale processing routines of OST however do rely on homogeneous acquisitions across the given Area of Interest (AOI), 
                         i.e. the same amount of acquisitions across the entire AOI. This routine will therefore look for all available data in the first place,
                         and subsequently do a refinement of the available acquisitions in order to be compliant with the processing logic, guaranteeing 
                         the highest possible quality of the final output data. Note that the area should coincide with
                         the observation scenario of Sentinel-1 (see Info Panel), which for most places is geared to national boundaries. The refinement will 
                         possibly fail for larger areas. In this case a full search and a subsequent manual refinement is necessary. Respective instructions 
                         are given in the Info Panel on the right."),hr(), 
                      #-----------------------------------------------------------------------------------------------------------
                      
                      #-----------------------------------------------------------------------------------------------------------
                      # Project Directory
                      tags$b(" Project Directory:"),br(),
                      p("A new folder named \"Inventory\" will be created within the selected project directory. 
                        This folder will contain the OST inventory shapefiles, sorted by orbit direction and polarization mode. See the Info Panel for 
                        more details on the naming conventions."),
                      shinyDirButton('s1_ainv_directory', 'Browse', 'Select a folder'),br(),br(),
                      verbatimTextOutput("s1_ainv_project_dir"),hr(),             
                      #-----------------------------------------------------------------------------------------------------------
                      
                      #-----------------------------------------------------------------------------------------------------------
                      tags$b("Area of Interest"),
                      p("This parameter will define the spatial extent of the data inventory. You can either choose the borders 
                        of a country or a shapefile that bounds your area of interest. If you are working from remote, 
                        you can transfer a zipped archive containing a shapefile and its associated files 
                        from your local machine to the server by selecting the third option."),
               # AOI choice
               radioButtons("s1_ainv_AOI", "",
                            c("Country boundary" = "s1_ainv_country",
                              "Shapefile (local/ on server)" = "s1_ainv_shape_local",
                              "Shapefile (upload a zipped archive)" = "s1_ainv_shape_upload")),
               
               conditionalPanel(
                 "input.s1_ainv_AOI == 's1_ainv_country'",
                 selectInput(
                       inputId = 's1_ainv_countryname', 
                       label = '',
                       choices = dbGetQuery(
                       dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                       sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                       selected=NULL)
               ),
               
               conditionalPanel(
                      "input.s1_ainv_AOI == 's1_ainv_shape_local'",
                       #div(style="display:inline-block",shinyFilesButton("shapefile","Choose file","Choose one or more files",FALSE)),
                       #div(style="display:inline-block",textOutput("filepath"))
                       shinyFilesButton("s1_ainv_shapefile","Browse","Choose one shapefile",FALSE),
                       br(),
                       br(),
                       verbatimTextOutput("s1_ainv_filepath")
               ),
               
               conditionalPanel(
                      "input.s1_ainv_AOI == 's1_ainv_shape_upload'",
                       fileInput('s1_ainv_shapefile_path', label = '',accept = c(".zip"))
               ),hr(),
               
               #-----------------------------------------------------------------------------------------------------------
               tags$b("Date Range"),
               p("Select a period of time for which data inventory will be applied."),
               dateRangeInput("s1_ainv_daterange",
                              "",
                               start = "2014-10-01",
                               end = Sys.Date(),
                               min = "2014-10-01",
                               max = Sys.Date(),
                               format = "yyyy-mm-dd"
                            ),hr(),
               #-----------------------------------------------------------------------------------------------------------------------------------
               
               #-----------------------------------------------------------------------------------------------------------------------------------
               # Trigger / Abort
               div(style="display: inline-block;vertical-align:top; width: 235px;", withBusyIndicatorUI(
                 actionButton("s1_ainv_pro_btn", "Create an OST inventory shapefile")
               )),
               div(style="display: inline-block;vertical-align:top; width: 150px;", withBusyIndicatorUI(
                 actionButton("s1_ainv_abort_btn", "Abort the inventory")
               )),
               textOutput("s1_ainv")
              #      )
             ),
               #-----------------------------------------------------------------------------------------------------------
               
             tabPanel("Full Selection",
               tags$h4("Sentinel-1 data inventory"),hr(),
               tags$b("Short description:"),
               p("This interface allows to create a shapefile that contains all available Sentinel-1 scenes according to the parameters set below.
                 A careful refinement of the selection for the subsequent timeseries/timescan product generation is strongly encouraged."),hr(),
               #-----------------------------------------------------------------------------------------------------------
               
               #-----------------------------------------------------------------------------------------------------------
               # Project Directory
               tags$b(" Project Directory:"),br(),
               p("A new folder named \"Inventory\" will be created within the selected project directory. 
                  This folder contains the OST inventory shapefile that is produced by this interface."),
               shinyDirButton('s1_inv_directory', 'Browse', 'Select a folder'),br(),br(),
               verbatimTextOutput("s1_inv_project_dir"),hr(),
               #-----------------------------------------------------------------------------------------------------------
               
               #-----------------------------------------------------------------------------------------------------------
               tags$b("Area of Interest"),
               p("This parameter will define the spatial extent of the data inventory. You can either choose the borders 
                  of a country or a shapefile that bounds your area of interest. If you are working from remote, 
                  you can transfer a zipped archive containing a shapefile and its associated files 
                  from your local machine to the server by selecting the third option."),
               # AOI choice
               radioButtons("s1_inv_AOI", "",
                            c("Country boundary" = "s1_inv_country",
                              "Shapefile (local/ on server)" = "s1_inv_shape_local",
                              "Shapefile (upload a zipped archive)" = "s1_inv_shape_upload")),
               
               conditionalPanel(
                 "input.s1_inv_AOI == 's1_inv_country'",
                 selectInput(
                       inputId = 's1_inv_countryname', 
                       label = '',
                       choices = dbGetQuery(
                       dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                       sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                       selected=NULL)
               ),
               
               conditionalPanel(
                      "input.s1_inv_AOI == 's1_inv_shape_local'",
                       #div(style="display:inline-block",shinyFilesButton("shapefile","Choose file","Choose one or more files",FALSE)),
                       #div(style="display:inline-block",textOutput("filepath"))
                       shinyFilesButton("s1_inv_shapefile","Browse","Choose one shapefile",FALSE),
                       br(),
                       br(),
                       verbatimTextOutput("s1_inv_filepath")
               ),
               
               conditionalPanel(
                      "input.s1_inv_AOI == 's1_inv_shape_upload'",
                       fileInput('s1_inv_shapefile_path', label = '',accept = c(".zip"))
               ),hr(),
               
               #-----------------------------------------------------------------------------------------------------------
               tags$b("Date Range"),
               p("Select a period of time for which data inventory will be applied."),
               dateRangeInput("s1_inv_daterange",
                              "",
                               start = "2014-10-01",
                               end = Sys.Date(),
                               min = "2014-10-01",
                               max = Sys.Date(),
                               format = "yyyy-mm-dd"
                            ),hr(),
               
               #-----------------------------------------------------------------------------------------------------------
               tags$b("Polarisation Mode"),
               p("Note that for subsequent processing tasks only the VV co- and VH cross-polarisations are supported
                  by OST for now. More info on the polarisation modes of Sentinel-1 can be found in the Info Panel on the right."),
               selectInput("s1_inv_pol", "",
                         c("Dual-pol (VV+VH) " = "dual_vv",
                           "Single-pol (VV)" = "vv",
                           "Dual-pol (VV+VH) & Single-pol (VV) " = "dual_single_vv",
                           "Dual-pol (HH+HV)" = "dual_hh",
                           "Single-pol (HH)" = "hh",
                           "Dual-pol (HH+HV) & Single-pol (HH) " = "dual_single_hh")
               ),hr(),
               #-----------------------------------------------------------------------------------------------------------
               
               #-----------------------------------------------------------------------------------------------------------
               tags$b("Sensor Mode"),
               p(" Note that for subsequent processing tasks only the standard Interferometric Wide Swath is 
                   supported by OST for now. More info on the sensor modes of Sentinel-1 can be found in the 
                   Info Panel on the right. "),
               radioButtons("s1_inv_sensor_mode", "",
                            c("Interferometric Wide Swath (recommended) " = "iw",
                              "Extra Wide Swath" = "ew",
                              "Wave Mode" = "wv")
               ),hr(),
               #-----------------------------------------------------------------------------------------------------------
               
               #-----------------------------------------------------------------------------------------------------------
               tags$b("Product Level"),
               p("Note that for subsequent processing tasks only the GRD products are supported by OST for now.
                  More info on the product levels of Sentinel-1 can be found in the Info Panel on the right."),
               radioButtons("s1_inv_product_level", "",
                            c("Level-1 GRD (recommended) " = "grd",
                              "Level-1 SLC" = "slc",
                              "Level-0 RAW" = "raw")
               ),hr(),
               #-----------------------------------------------------------------------------------------------------------
               
               #-----------------------------------------------------------------------------------------------------------------------------------
               # Trigger / Abort
               div(style="display: inline-block;vertical-align:top; width: 235px;", withBusyIndicatorUI(
                 actionButton("s1_inv_pro_btn", "Create an OST inventory shapefile")
               )),
               div(style="display: inline-block;vertical-align:top; width: 150px;", withBusyIndicatorUI(
                 actionButton("s1_inv_abort_btn", "Abort the inventory")
               )),
               textOutput("s1_inv")
             )
             )
             
             #-----------------------------------------------------------------------------------------------------------------------------------
             
          ), # close box
          #----------------------------------------------------------------------------------
          
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
             box(
               title = "Info Panel", status = "success", solidHeader= TRUE,
               
               tabBox(width = 700,
                      
                      tabPanel("Progress Monitor",
                               tags$h4("Monitoring the progress of active inventory"),hr(),
                               #actionButton("s1_inv_log_btn", "Start"),hr(),
                               verbatimTextOutput("s1_inv_progress")
                      ),
                      tabPanel("General Info",
                               
                               
                               tags$h4("Sentinel-1 data inventory "),
                               hr(),
                               p("OST separates the search for data from the actual download. Two routines are available to the user, the ", tags$b("Automatic Data Inventory"), " and 
                                  the ", tags$b("Full Selection."), "Both routines will create a folder named ", tags$b("Inventory"), " within the selected project folder, where all
                                  outputs will be placed."),
                               p("The ", tags$b("Automatic Data Inventory"), " tab will look for all GRD data products available for the given AOI within the selected time-period
                                  in VV only (i.e. single-polarized) and VV + VH polarisation (i.e. dual-polarized).
                                  An automated refinement takes place that sorts out scenes that do not meet the criteria to be included in the time-series/timescan processing.  
                                  Available imagery will be stored in separate shapefiles according to the orbit direction and polarisation mode. Additionally, the user can see 
                                  the number of available number of acquisitions placed at the beginning of each file. E.g., the file ", tags$b("23.asc.single-pol.shp"), " is read as: 
                                  23 wall-to-wall mosaics for the entire AOI, acquired in single-polarised mode and ascending orbit direction."),
                               p("A maximum of 4 combinations is available, i.e. ascending + single-pol, ascending + dual-pol, descending + single-pol and descending dual-pol. 
                                  The selection for further download and processing should comply with the highest number of available wall-to-wall mosaics.
                                  However, since dual-pol data includes additional information from the VH cross-polarised channel, it mihgt be favorable to select 
                                  the dual-pol file, even if the number of mosaics is lower."),
                               p("In order to give sense to the envisaged analysis based on timescans, a ", tags$b("minimum"), " of 5 wall-to-wall mosaics, distributed over 
                                  different seasons, should be available. This should assure that the temporal dynamics of all present land cover classes is well captured. More 
                                  suited datasets contain 10 and more wall-to-wall mosaics. As a result, an OST inventory shapefile, containing 12 mosaics acquired in single-pol mode 
                                  is likely to give more information than an OST inventory shapefile containing just 5 mosaics in dual-pol mode. "),
                               p("The ", tags$b("Full Selection."), ", instead, returns the full set of available imagery and allows also for more advanced search criteria.
                                  It is possible to easily search for all kinds of data from the Sentinel-1 constellation for a certain area, 
                                  defined by country borders or a self-provided shapefile delimiting the AOI. Based on this selection, as well as the 
                                  other criteria, an", tags$b("OST inventory shapefile"), "is created. This shapefile shows the footprints of the 
                                  matching scenes and contains further metadata in its attribute table. Thus, the selection of scenes can be further refined
                                  manually. Ultimately, this shapefile can then be used for the subsequent", actionLink("link_to_tabpanel_s1_dow", "Data Download"),"."),
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
                                 ", constant image acqusition is in place since May 2017."),
                               p("Detailed information on the acquisition strategy can be found", 
                                 a(href = "https://sentinel.esa.int/web/sentinel/missions/sentinel-1/observation-scenario", target = "_blank", "here"), "."),
                               br(),
                               tags$h3("Observation scenarion as of 05/2017"),
                               br(),
                               img(src = "Sentinel-1-revisit-coverage-052017.jpg", width = "100%", height = "100%"),
                               tags$b("Figure 1: Revisit and coverage frequency of the SENTINEL-1 constellation as from May 2017 (image courtesy:ESA)."),
                               br(),
                               img(src = "Sentinel-1-mode-polarisation-pass-052017.jpg", width = "100%", height = "100%"),
                               tags$b("Figure 2: Imaging modes of the SENTINEL-1 constellation as from May 2017 (image courtesy:ESA)."),
                               hr(),
                               tags$h4("Observation scenarion as of 10/2016"),
                               br(),
                               img(src = "Sentinel-1-revisit-frequency.jpg", width = "100%", height = "100%"),
                               tags$b("Figure 3: Revisit and coverage frequency of the SENTINEL-1 constellation as from October 2016 (image courtesy:ESA)."),
                               br(),
                               img(src = "Sentinel-1-mode-polarisation-observation-geometry.jpg", width = "100%", height = "100%"),
                               tags$b("Figure 4: Imaging modes of the SENTINEL-1 constellation as from October 2016 (image courtesy:ESA).")                      ),
                      tabPanel("Sensor Mode",
                               tags$h3("Sentinel-1 sensor modes"),
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
                               p("ESA (2016): Sentinel-1. Radar Vision for Copernicus", 
                                 a (href = "http://esamultimedia.esa.int/multimedia/publications/sentinel-1/", target = "_blank", "Link"),"."),
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