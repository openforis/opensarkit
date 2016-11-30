#-----------------------------------------------------------------------------
# About OST tab
tabItem(tabName = "about",
        "Welcome to the Open Foris SAR Toolkit",
        fluidRow(
        ) # close box
) # close tabItem


#-----------------------------------------------------------------------------
# ALOS K&C Tab
tabItem(tabName = "alos_kc",
        fluidRow(
           # Include the line below in ui.R so you can send messages
           tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
           
           #----------------------------------------------------------------------------------
           # Processing Panel ALOS K&C
           box(
              
              # Title                     
              title = "Processing Panel", status = "success", solidHeader= TRUE,
              tags$h4("ALOS mosaics preparation (JAXA's Kyoto & Carbon initiative)"),
              hr(),
              tags$b("1) Project directory"),br(),
              p("Note: Within this directory the processing chain will store all data (i.e. downloaded archives, processed mosaics and auxiliary information.)"),
              #div(style="display:inline-block",shinyDirButton('directory', 'Browse', 'Select a folder')),
              #div(style="display:inline-block",verbatimTextOutput("project_dir")),
              shinyDirButton('directory', 'Browse', 'Select a folder'),
              br(),
              br(),
              verbatimTextOutput("KC_project_dir"),
              hr(),
              tags$b("2) Area of Interest"),br(),
              p("Note: This parameter will define the spatial extent of the processing. 
                 You can either choose the borders of a country or a shapefile that bounds your area of interest."),
              # AOI choice
              radioButtons("ALOS_AOI", "",
                           c("Country" = "country",
                             "Shapefile (on Server/local)" = "AOI_shape_local",
                             "Shapefile (upload)" = "AOI_shape_upload")),
              
              conditionalPanel(
                 "input.ALOS_AOI == 'country'",
                 selectInput(
                    inputId = 'countryname', 
                    label= '', 
                    choices = dbGetQuery(
                       dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                       sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                    selected=NULL)
              ),
              
              conditionalPanel(
                 "input.ALOS_AOI == 'AOI_shape_local'",
                 #div(style="display:inline-block",shinyFilesButton("shapefile","Choose file","Choose one or more files",FALSE)),
                 #div(style="display:inline-block",textOutput("filepath"))
                 shinyFilesButton("shapefile","Choose file","Choose one or more files",FALSE),
                 br(),
                 br(),
                 verbatimTextOutput("KC_filepath")
              ),
              
              conditionalPanel(
                 "input.ALOS_AOI == 'AOI_shape_upload'",
                 fileInput('shapefile_path', label = '',accept = c(".shp"))
              ),
              
              hr(),
              
              selectInput("year","3) Year",c(
                 "2007" = "2007",
                 "2008" = "2008",
                 "2009" = "2009",
                 "2010" = "2010",
                 "2015" = "2015")),                   
              hr(),
              radioButtons("ALOS_KC_speckle", "4) Additional speckle filtering",
                           c("Yes (recommended)" = "Yes",
                             "No" = "No")),
              
              hr(),
              
              tags$b("5) Provide your ALOS K&C username and password."),
              p("If you are not in possess of a user account you can create one ",
                 a(href = "http://www.eorc.jaxa.jp/ALOS/en/palsar_fnf/registration.htm", "here",".")),
              
              textInput(inputId = "uname",
                        label = "Username", 
                        value = "Type in your username" 
              ),
              
              passwordInput(inputId = "piwo",
                            label = "Password",
                            value = "Type in your password"),
              hr(),
              #div(style="display:inline-block",actionButton("alos_kc_process", "Start processing")),
              #div(style="display:inline-block",actionButton("alos_kc_abort", "Abort processing")),
              actionButton("alos_kc_process", "Start processing"),
              br(),
              br(),
              "Command Line Syntax:",
              verbatimTextOutput("processALOS")
           ), # close box
           #----------------------------------------------------------------------------------
           
           
           #----------------------------------------------------------------------------------
           # Info Panel
           box(
              title = "Info Panel", status = "success", solidHeader= TRUE,
              
              tabBox(width = 700,
                     
                     tabPanel("General Info",
                              tags$h4("ALOS Kyoto & Carbon initiative"),
                              p("The global 25m resolution PALSAR/PALSAR-2 mosaic is a seamless global SAR
                                 image created by mosaicking SAR images of backscattering coefficient measured
                                 by PALSAR/PALSAR-2, where all the path within 10x10 degrees in latitude and
                                 longitude are path processed and mosaicked for the sake of processing efficiency.
                                 Correction of geometric distortion specific to SAR (ortho-rectification) and 
                                 topographic effects on image intensity (slope correction) are applied to make forest
                                 classification easy. The size of one pixel is approximately 25 meter by 25 meter.
                                 The temporal interval of the mosaic is generally 1 year."),
                              p("JAXA distributes the data in 5 by 5 degree tiles. This includes not only the 
                                 backscatter data, but also additional information such as acquistion date, the local incidence angle, 
                                 and a forest/non-forest classification. The processing chain will automatically download the tiles
                                 that correspond to the selected Area of Interest, mosaic them and crop the data to a buffered extent 
                                 of the area. If chosen, an additional speckle filter (Refined Lee) is applied for the backscatter data."),
                              img(src = "shimada_alos_global.png", width = "100%", height = "100%"),
                              tags$b("Figure 1: 2007 - 2010 global mosaics of ALOS Kyoto & Carbon initiative (Shimada et al. 2014)"),br(),
                              p("Global 25m resolution PALSAR-2/PALSAR mosaic and forest/non-forest map
                                 are free and open datasets generated by applying JAXAs sophisticated processing
                                 and analysis method/technique to a lot of images obtained with Japanese L-band
                                 Synthetic Aperture Radars (PALSAR and PALSAR-2) on Advanced Land Observing 
                                 Satellite (ALOS) and Advanced Land Observing Satellite-2 (ALOS-2)."),
                              p("The global forest/non-forest map (FNF) is generated by classifying the SAR image
                                 (backscattering coefficient) in the global 25m resolution PALSAR-2/PALSAR
                                 mosaic so that strong and low backscatter pixels are assigned as forest (colored in
                                 green) and non-forest (colored in yellow), respectively. Here, the forest is defined
                                 as the natural forest with the area larger than 0.5ha and forest cover over 90%, as
                                 same to the FAO definition. Since the radar backscatter from the forest depends
                                 on the region (climate zone), the classification of 2 Forest/Non-forest is conducted
                                 by using the region dependent threshold of backscatter. The classification accu-
                                 racy is checked by using in-situ photos and high-resolution optical satellite images."),
                              img(src = "shimada_fnf_global.png", width = "100%", height = "100%"),
                              tags$b("Figure 2: 2007 - 2010 global forest/non-forest maps of the ALOS Kyoto & Carbon initiative (Shimada et al. 2014)"),br()
                              ),
                     
                     tabPanel("Processing",
                              tags$h4("Processing workflow"),
                              p("The actual workflow of the ALOS Palsar Kyoto & Carbon mosaic processing chain consists 
                                 of 2 main parts, one for the data download, and one for the subsequent processing. The
                                 only input which needs to be given is either a polygon shapefile, bounding the
                                 area of interest, or a country name, for which the script will automatically extract the boundary.
                                 In addition the year for which the data should be retrieved and processed should be provided."),
                              p("The processing includes various steps. Downloaded archives are first extracted. In a next step 
                                 the auxiliary data files (Acquisition Date, Local Incidence Angle) as well as the forest/non-forest\
                                 map are mosaicked and cropped to the extent of the Area of Interest."),
                              p("The preparation of the backscatter tiles includes the optional speckle filter as well as the calculation of the
                                 backscatter ratio (HH pol/ HV pol) and the Radar Forest Degradation Index (RFDI, Saatchi et al. 2011). 
                                 The former is usually for a proper RGB visualization, although it is useful for multi-temporal analysis, 
                                 since environmental effects are somewhat cancelled out (Reiche et al. 2015).
                                 The RFDI depicts a normalized ratio similar to the NDVI from optical data. It is designed to assess the 
                                 strength of the double bounce scattering term by combining the power of the HH and HV polarisations. The HH polarisation
                                 is sensitive to both volume and double bounce scattering, whereas the HV polarisation is predominantly sensitive to 
                                 volume scattering. As a result it improves the differentation of different vegetation classes (Mitchard et al. 2012)"),
                              p("The output of the processing chain is stored within the selected project directory. This contains a ZIP folder where 
                                 the downloaded archives are saved to during the download process. Another folder named after the respective year is
                                 created and contains subfolders for the auxiliary data (AUX), the forest/non-forest map (FNF) and the backscatter mosaics (MOS).
                                 The latter contains the actual data files for further classification tasks. Both polarizations, the HH/HV backscatter ratio and the RFDI 
                                 layer can be found here. An additional Virtual Raster file (RGB_YEAR.vrt) can be loaded into a GIS for RGB visualization purposes.")
                              ),
                     
                     tabPanel("References",
                              tags$h4("References"),
                              tags$b("Information Material"),
                              p("JAXA (2010): Global Environmental Monitoring by ALOS PALSAR. Science Results from the ALOS Kyoto & Carbon Initiative.",
                              a(href = "http://www.eorc.jaxa.jp/ALOS/en/kyoto/ref/KC-Booklet_2010_comp.pdf", "Link to PDF")),
                              tags$b("Web sites"),
                              p(a(href = "http://www.eorc.jaxa.jp/ALOS/en/kyoto/kyoto_index.htm", "ALOS Kyoto & Carbon official website")),
                              tags$b("Scientific Articles"),
                              p("Special Issue on ALOS PALSAR in Remote Sensing of Environment (2014, Open Access):",a(href = "http://www.sciencedirect.com/science/journal/00344257/155", "Click here")), 
                              p("Mitchard, E.T.A. et al. (2012): Mapping tropical forest biomass with radar and spaceborne LiDAR in Lope National Park, 
                                 Gabon: overcoming problems of high biomass and persistent cloud. in: Biogeosciences. 9. 179-191.",
                                 a(href = "http://www.biogeosciences.net/9/179/2012/bg-9-179-2012.pdf", "Link.")),
                              p("Reiche, J. et al. (2015): Fusing Landsat and SAR time-series to detect deforestation in the tropics.
                                 in: Remote Sensing of Environment, 156, 276-293.",
                                 a(href = "https://www.researchgate.net/publication/267339835_Fusing_Landsat_and_SAR_time_series_to_detect_deforestation_in_the_tropics","Link.")),                       
                              p("Saatchi, S. (2011): Introducing the Radar Forest Degradation Index (RFDI) from L-band Polarimetric data. 
                                 in: Proceedings of the IEEE IGARRS 2011, Vancouver, Canada.", a(href = "http://igarss11.org/papers/ViewPapers_MS.asp?PaperNum=3877","Link.")),
                              p("Shimada et al. (2014): New global forest/non-forest maps from ALOS PALSAR data (2007–2010). 
                                 in: Remote Sensing of Environment, 155, 13-31.", 
                                 a(href = "http://ac.els-cdn.com/S0034425714001527/1-s2.0-S0034425714001527-main.pdf?_tid=d9c35274-acb6-11e6-b070-00000aacb360&acdnat=1479381382_15a3e412b87bf3ad00eb6833137fbf15", "Link.")),
                              p("Tange, O. (2011): GNU Parallel - The Command-Line Power Tool, ;login: The USENIX Magazine, February 2011:42-47.")
                     )
              ) # close tab box
           ) # close box
           #----------------------------------------------------------------------------------
) # close fluidRow
) # close tabItem