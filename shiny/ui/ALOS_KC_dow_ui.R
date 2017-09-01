#-----------------------------------------------------------------------------
# ALOS K&C Tab
tabItem(tabName = "alos_kc_dow",
        fluidRow(
           # Include the line below in ui.R so you can send messages
           tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
           
           # for busy indicator 
           useShinyjs(),
           tags$style(appCSS),
           #----------------------------------------------------------------------------------
           # Processing Panel ALOS K&C
           box(
              
              # Title                     
              title = "Processing Panel", status = "success", solidHeader= TRUE,
              tags$h4("ALOS Kyoto & Carbon mosaic download"),
              hr(),
              
              tags$b("Short description"),
              p("ALOS K&C yearly backscatter data is distributed by JAXA in 5x5 degree tiles that are stored on a regular ftp-server. In order to ease the access,  
                 data tiles will be automatically filtered based on the extents of the Area of Interest (AOI) as well as the selected year for the subsequent download."),
              hr(),
              tags$b("Project directory"),
              p("The hereby selected directory defines the greater project folder, where the downloaded data tiles will be stored within the newly created directory called \"ZIP\"."),
              shinyDirButton('kc_dow_directory', 'Browse', 'Select a folder'),
              br(),br(),
              verbatimTextOutput("kc_dow_project_dir"),
              hr(),
              
              tags$b("Area of Interest"),br(),
              p("This parameter will define the spatial extent of the data inventory. You can either choose the borders 
                of a country or a shapefile that bounds your area of interest. If you are working from remote, 
                you can transfer a zipped archive containing a shapefile and its associated files 
                from your local machine to the server by selecting the third option."),
              radioButtons("KC_dow_AOI", "",
                           c("Country" = "country",
                             "Shapefile (on Server/local)" = "AOI_shape_local",
                             "Shapefile (upload zipped archive)" = "AOI_zip_upload")),
              
              conditionalPanel(
                 "input.KC_dow_AOI == 'country'",
                 selectInput(
                    inputId = 'kc_dow_countryname', 
                    label= '', 
                    choices = dbGetQuery(
                       dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                       sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                    selected=NULL)
              ),
              
              conditionalPanel(
                 "input.KC_dow_AOI == 'AOI_shape_local'",
                 shinyFilesButton("kc_dow_shapefile","Browse","Choose a shapefile",FALSE),
                 br(),
                 br(),
                 verbatimTextOutput("kc_dow_filepath")
              ),
              
              conditionalPanel(
                 "input.KC_dow_AOI == 'AOI_zip_upload'",
                 fileInput('kc_dow_zipfile_path', label = 'Browse',accept = c(".zip"))
              ),
              hr(),
              
              tags$b("Year"),
              p("ALOS K&C mosaics are produced for an entire single year. Therefore no control is given on the actual acquisition date. 
                 Note that the processing routine will produce a shapefile that contains the acquisition dates of the used imagery."),
              selectInput("kc_dow_year","",c(
                 "1996" = "1996",
                 "2007" = "2007",
                 "2008" = "2008",
                 "2009" = "2009",
                 "2010" = "2010",
                 "2015" = "2015",
                 "2016" = "2016")),                   
              hr(),
              
              tags$b("Provide your ALOS K&C username and password."),
              p("If you are not in possess of a user account you can create one ",
                 a(href = "http://www.eorc.jaxa.jp/ALOS/en/palsar_fnf/registration.htm", "here",".")),
              textInput(inputId = "kc_dow_uname",
                        label = "Username", 
                        value = "Type in your username" 
              ),
              passwordInput(inputId = "kc_dow_piwo",
                            label = "Password",
                            value = "Type in your password"),
              hr(),
              
              div(style="display: inline-block;vertical-align:top; width: 135px;",withBusyIndicatorUI(
                actionButton("kc_dow_pro_btn", "Start download"))),
              div(style="display: inline-block;vertical-align:top; width: 125px;", withBusyIndicatorUI(
                actionButton("kc_dow_abort_btn", "Abort download")
              )),
              #"Output:",
              textOutput("download_KC")
           ), # close box
           #----------------------------------------------------------------------------------
           
           
           #----------------------------------------------------------------------------------
           # Info Panel
           box(
              title = "Info Panel", status = "success", solidHeader= TRUE,
              
              tabBox(width = 700,
                     
                     tabPanel("General Info",
                              tags$h4("Monitoring the progress of the download"),
                              hr(),
                              verbatimTextOutput("kc_dow_progress")
                     ),
                     tabPanel("General Info",
                              tags$h4("ALOS Kyoto & Carbon SAR backscatter data"),
                              hr(),
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
                              p("Global 25m resolution PALSAR-2/PALSAR mosaic and forest/non-forest map
                                 are free and open datasets generated by applying JAXAs sophisticated processing
                                 and analysis method/technique to a lot of images obtained with Japanese L-band
                                 Synthetic Aperture Radars (PALSAR and PALSAR-2) on Advanced Land Observing 
                                 Satellite (ALOS) and Advanced Land Observing Satellite-2 (ALOS-2)."),
                              img(src = "shimada_alos_global.png", width = "100%", height = "100%"),
                              tags$b("Figure 1: 2007 - 2010 global mosaics of ALOS Kyoto & Carbon initiative (Shimada et al. 2014)")
                     ),
                     
                     tabPanel("References",
                              tags$h4("References"),
                              hr(),
                              tags$b("Information Material"),
                              p("JAXA (2010): Global Environmental Monitoring by ALOS PALSAR. Science Results from the ALOS Kyoto & Carbon Initiative.",
                                a(href = "http://www.eorc.jaxa.jp/ALOS/en/kyoto/ref/KC-Booklet_2010_comp.pdf", "Link"),"."),
                              p("Global 25m Resolution PALSAR-2/PALSAR Mosaic and Forest/Non-Forest Map (FNF). Dataset Description",
                                a(href = "http://www.eorc.jaxa.jp/ALOS/en/palsar_fnf/DatasetDescription_PALSAR2_Mosaic_FNF_revC.pdf", "Link"),"."),
                              tags$b("Web sites"),
                              p(a(href = "http://www.eorc.jaxa.jp/ALOS/en/kyoto/kyoto_index.htm", target = "_blank", "ALOS Kyoto & Carbon official website")),
                              tags$b("Scientific Articles"),
                              p("Special Issue on ALOS PALSAR in Remote Sensing of Environment (2014, Open Access):",a(href = "http://www.sciencedirect.com/science/journal/00344257/155", target = "_blank", "Link"),"."), 
                              p("Mitchard, E.T.A. et al. (2012): Mapping tropical forest biomass with radar and spaceborne LiDAR in Lope National Park, 
                                 Gabon: overcoming problems of high biomass and persistent cloud. in: Biogeosciences. 9. 179-191.",
                                a(href = "http://www.biogeosciences.net/9/179/2012/bg-9-179-2012.pdf", target = "_blank", "Link"),"."),
                              p("Reiche, J. et al. (2015): Fusing Landsat and SAR time-series to detect deforestation in the tropics.
                                 in: Remote Sensing of Environment, 156, 276-293.",
                                a(href = "https://www.researchgate.net/publication/267339835_Fusing_Landsat_and_SAR_time_series_to_detect_deforestation_in_the_tropics",target = "_blank", "Link"),"."),                       
                              p("Saatchi, S. (2011): Introducing the Radar Forest Degradation Index (RFDI) from L-band Polarimetric data. 
                                 in: Proceedings of the IEEE IGARRS 2011, Vancouver, Canada.", a(href = "http://igarss11.org/papers/ViewPapers_MS.asp?PaperNum=3877", target = "_blank", "Link"),"."),
                              p("Shimada et al. (2014): New global forest/non-forest maps from ALOS PALSAR data (2007–2010). 
                                 in: Remote Sensing of Environment, 155, 13-31.", 
                                a(href = "http://ac.els-cdn.com/S0034425714001527/1-s2.0-S0034425714001527-main.pdf?_tid=d9c35274-acb6-11e6-b070-00000aacb360&acdnat=1479381382_15a3e412b87bf3ad00eb6833137fbf15", target = "_blank", "Link"),"."),
                              p("Tange, O. (2011): GNU Parallel - The Command-Line Power Tool, ;login: The USENIX Magazine, February 2011:42-47.")
                     ),
                     
                     tabPanel("Legal Notices",
                              tags$h4("Legal notice"),
                              hr(),
                              p("- JAXA retains ownership of the dataset. JAXA cannot guarantee any problem caused by or possibly caused by using the datasets."),
                              p("- Anyone wishing to publish any results using the datasets should clearly acknowledge the ownership of the data in the publication."),
                              p("- Note that the datasets are provided free of charge, but are available for research and educational purposes only. It is prohibited to use the datasets for commercial, 
                                 profit-making purposes without JAXA's consent. If users wish to use the datasets for such purposes, please make contact to JAXA.")
                     )
              ) # close tab box
           ) # close box
           #----------------------------------------------------------------------------------
        ) # close fluidRow
) # close tabItem
