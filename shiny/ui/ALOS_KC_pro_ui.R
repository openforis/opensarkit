#-----------------------------------------------------------------------------
# ALOS K&C Tab
tabItem(tabName = "alos_kc_pro",
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
              tags$h4("ALOS K&C mosaic preparation"),
              if ( nchar(Sys.getenv('SEPAL')) > 0){
                span(p("Warning! Make sure you have enough free space. During the processing, a lot of intermediate files have to be created,
                        which, dependent on your AOI, may take up a considerable amount of disk space. For country wide processing make sure to have at least 100 GB of free disk space available. 
                        For countries of the size of the Democratic Republic of Congo, Ethiopia or Bolivia, even 200 GB and more might be necessary."), style='color:red')
              },
              hr(),
              
              #----------------------------------------------------------------------------------
              # directory choice
              tags$b("Project directory"),
              p("The hereby selected directory defines the greater project folder. It should refer to the same folder which was
                 chosen for the download of the data tiles."),
              shinyDirButton('kc_pro_directory', 'Browse', 'Select a folder'),
              br(),br(),
              verbatimTextOutput("kc_pro_project_dir"),hr(),
              #----------------------------------------------------------------------------------
              
              #----------------------------------------------------------------------------------
              # aoi choice
              tags$b("Area of Interest"),
              p("This parameter will define the spatial extent of the processing routine. All final products will be clipped by this file. 
                 In order to assure successful processing use the same file as for the earlier download routine. "),
              # AOI choice
              radioButtons("kc_pro_AOI", "",
                           c("Country" = "country",
                             "Shapefile (on Server/local)" = "AOI_shape_local",
                             "Shapefile (upload zipped archive)" = "AOI_zip_upload")),
              
              conditionalPanel(
                "input.kc_pro_AOI == 'country'",
                selectInput(
                  inputId = 'kc_pro_countryname', 
                  label= '', 
                  choices = dbGetQuery(
                    dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                    sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                  selected=NULL)
              ),
              
              conditionalPanel(
                "input.kc_pro_AOI == 'AOI_shape_local'",
                #div(style="display:inline-block",shinyFilesButton("shapefile","Choose file","Choose one or more files",FALSE)),
                #div(style="display:inline-block",textOutput("filepath"))
                shinyFilesButton("kc_pro_shapefile","Browse","Select a shapefile",FALSE),
                br(),
                br(),
                verbatimTextOutput("kc_pro_filepath")
              ),
              
              conditionalPanel(
                "input.KC_pro_AOI == 'AOI_zip_upload'",
                fileInput('kc_pro_zipfile_path', label = 'Browse',accept = c(".zip"))
              ),hr(),
              #----------------------------------------------------------------------------------
              
              #----------------------------------------------------------------------------------
              # Year choice
              tags$b("Year"),
              p("Select the year for which the downloaded data should be processed. Make sure to have downloaded the corresponding tiles first."),
              selectInput("kc_pro_year","",c(
                "1996" = "1996",
                "2007" = "2007",
                "2008" = "2008",
                "2009" = "2009",
                "2010" = "2010",
                "2015" = "2015",
                "2016" = "2016")),                   
              hr(),
              #----------------------------------------------------------------------------------
              
              #----------------------------------------------------------------------------------
              # Speckle filter
              tags$b("Speckle-Filtering"),
              p("As all SAR imagery, also the ALOS K&C mosaics are affected by Speckle noise. In order to reduce this Speckle noise, 
                 a filtering procedure can be optionally be applied."),
              radioButtons("kc_pro_speckle", "",
                           c("Yes (recommended)" = "Yes",
                             "No" = "No")),hr(),
              #----------------------------------------------------------------------------------
              
              #----------------------------------------------------------------------------------
              # action buttons
              div(style="display: inline-block;vertical-align:top; width: 135px;",withBusyIndicatorUI(
                actionButton("kc_pro_pro_btn", "Start download"))),
              div(style="display: inline-block;vertical-align:top; width: 125px;", withBusyIndicatorUI(
                actionButton("kc_pro_abort_btn", "Abort download")
              )),
              #"Output:",
              textOutput("process_KC")
              #----------------------------------------------------------------------------------
              
            ), # close box
           
           
           
           #----------------------------------------------------------------------------------
           # Info Panel
           box(
             title = "Info Panel", status = "success", solidHeader= TRUE,
             
             tabBox(width = 700,
                    
                    tabPanel("Progress Monitor",
                             tags$h4("Monitoring the progress of ongoing processing"),hr(),
                             verbatimTextOutput("kc_pro_progress")
                    ),
                    tabPanel("Workflow",
                             tags$h4("Detailed description of the processing workflow in OST"),
                             hr(),
                             p("The actual workflow of the ALOS Palsar Kyoto & Carbon mosaic processing chain consists 
                                 of 2 main parts, one for the data download, and one for the subsequent processing. The
                                 only input which needs to be given is either a polygon shapefile, bounding the
                                 area of interest, or a country name, for which the script will automatically extract the boundary.
                                 In addition the year for which the data should be retrieved and processed should be provided."),
                             p("The processing includes various steps. Downloaded archives are first extracted. In a next step 
                                 the auxiliary data files (Acquisition Date, Local Incidence Angle) as well as the forest/non-forest\
                                 map are mosaicked and cropped to the extent of the Area of Interest."),
                             p("The preparation of the backscatter tiles includes the optional speckle filter (Refined Lee) as well as the calculation of the
                                 backscatter ratio (HH pol/ HV pol) and the Radar Forest Degradation Index (RFDI, Saatchi et al. 2011). 
                                 The former is generally used for a proper RGB visualization (i.e. R: HH, G: HV, B: HH/HV ratio), 
                                 although it is useful for multi-temporal analysis, 
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