#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_grd2rtc",
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
            tags$h4("Sentinel-1 GRD to RTC processor"),
            hr(),
            # AOI choice
            radioButtons("s1_g2r_input_type", "Input type:",
                         c("Original File" = "file",
                           "Folder (batch processing)" = "folder",
                           "OST inventory shapefile (local/on server)" = "inventory",
                           "OST inventory shapefile (upload zipped archive)" = "zipfile")),
            
            conditionalPanel(
              "input.s1_g2r_input_type == 'file'",
              shinyFilesButton("s1_g2r_zip","Choose a Sentinel-1 zip file","Choose a Sentinel-1 zip file",FALSE),
              br(),
              br(),
              verbatimTextOutput("s1_g2r_zip_filepath"),
              hr(),
              tags$b("Output directory:"),
              br(),
              br(),
              shinyDirButton("s1_g2r_outdir","Browse","Choose a directory",FALSE),
              br(),
              br(),
              verbatimTextOutput("s1_g2r_outfolder"),
              hr(),
              radioButtons("s1_g2r_res", "Choose the output resolution:",
                           c("Medium Resolution (30m)" = "med_res",
                             "Full resolution (10m)" = "full_res")
              )
             ),
            
            conditionalPanel(
              "input.s1_g2r_input_type == 'folder'",
              
              shinyDirButton("s1_g2r_inputdir","Choose S1 DATA folder in your project directory","Choose the DATA folder inside your project directory",FALSE),
              br(),
              br(),
              verbatimTextOutput("s1_g2r_inputfolder"),
              hr(),
              radioButtons("s1_g2r_res", "Choose the output resolution:",
                           c("Medium Resolution (30m)" = "med_res",
                             "Full resolution (10m)" = "full_res")
              )
            ),
            
            conditionalPanel(
              "input.s1_g2r_input_type == 'inventory'",
              
              shinyFilesButton("s1_g2r_shp","Choose S1 DATA file","Choose one or more files",FALSE),
              br(),
              br(),
              verbatimTextOutput("s1_g2r_shp_filepath"),
              hr(),
              tags$b("Output directory"),
              br(),
              shinyDirButton("s1_g2r_outdir2","Browse","Choose a directory",FALSE),
              br(),
              br(),
              verbatimTextOutput("s1_g2r_outfolder2"),
              hr(),
              radioButtons("s1_g2r_res", "Choose the output resolution:",
                           c("Medium Resolution (30m)" = "med_res",
                             "Full resolution (10m)" = "full_res")
              ),
              hr(),
              "NASA Earthdata username/password. If you are not in possess of a user account: ",
              a(href = "https://urs.earthdata.nasa.gov/", target="_blank","Click Here!"),
              
              textInput(inputId = "s1_asf_uname3",
                        label = "Username", 
                        value = "Type in your username" 
              ),
              
              passwordInput(inputId = "s1_asf_piwo3",
                            label = "Password",
                            value = "Type in your password"
              )
              ),
              
              conditionalPanel(
                "input.s1_g2r_input_type == 'zipfile'",
                fileInput('S1_grd2rtc_zipfile_path', label = 'Browse',accept = c(".zip")),
                hr(),
                tags$b("Output directory"),
                br(),
                shinyDirButton("s1_g2r_outdir3","Browse","Choose a directory",FALSE),
                br(),
                br(),
                verbatimTextOutput("s1_g2r_outfolder3"),
                hr(),
                radioButtons("s1_g2r_res", "Choose the output resolution:",
                             c("Medium Resolution (30m)" = "med_res",
                               "Full resolution (10m)" = "full_res")
                ),
                hr(),
                "NASA Earthdata username/password. If you are not in possess of a user account: ",
                a(href = "https://urs.earthdata.nasa.gov/", target="_blank","Click Here!"),
                
                textInput(inputId = "s1_asf_uname4",
                          label = "Username", 
                          value = "Type in your username" 
                ),
                
                passwordInput(inputId = "s1_asf_piwo4",
                              label = "Password",
                              value = "Type in your password"
                )
              ),
            
            hr(),
            withBusyIndicatorUI(
              actionButton("s1_g2r_process", "Start processing")
            ),
            br(),
            #"Output:",
            textOutput("processS1_G2R")
            ), #close box
          
          
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
          box(
            title = "Info Panel", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   tabPanel("General Info",      
                            hr(),
                            p("Sentinel-1 Ground Range Detected (GRD) products are operationally generated by the 
                               Payload Data Ground Segment (PDGS) of ESA. From all available products, those images have undergone the most preprocessing 
                               steps, including azimuth and range compression (i.e. SAR focusing), slant to ground range during which the phase information 
                               is lost. Therefore advanced interferometric and polarimetric data analysis are not possible. 
                               On the other hand, the products exhibit only 1/7th of the size of an Single-Look Complex (SLC) image 
                               and further processign time is considerably reduced."),
                            p("This processor autmatically applies the missing steps to generate Radiometrically-Terrain-Corrected (RTC) Products that 
                               are suited for land cover classification. ")
                   ),
                   
                   tabPanel("Processing",
                            tags$h4("Processing Chain"),
                            hr(),
                            tags$b("1. Apply Orbit File"),
                            p("Precise orbit state vectors are necessary for geolocation and radiometric correction. The orbit state vectors provided 
                               in the metadata of a SAR product are generally 
                               not accurate and can be refined with the precise orbit files which are available days-to-weeks 
                               after the generation of the product."),
                            p("The orbit file provides accurate satellite position and velocity information. 
                               Based on this information, the orbit state vectors in the abstract metadata of the product are updated."),
                            p("For Sentinel-1, Restituted orbit files and Preceise orbit files may be applied. Precise orbits are produced 
                               a few weeks after acquisition. Orbit files are automatically downloaded."),
                            hr(),
                            tags$b("2. Thermal noise removal"),
                            p("Level-1 products provide a noise LUT for each measurement data set. The values in the de-noise LUT, provided in linear power,
                               can be used to derive calibrated noise profiles matching the calibrated GRD data."),
                            hr(),
                            tags$b("3. GRD Border Noise Removal"),
                            p("The Sentinel-1 (S-1) Instrument Processing Facility (IPF) is responsible for generating the complete family of Level-1 
                               and Level-2 operation products. The processing of the RAW data into L1 products features number of processing 
                               steps leading to artefacts at the image borders. These processing steps are mainly the azimuth and /range compression and 
                               the sampling start time changes handling that is necessary to compensate for the change of earth curvature. 
                               The latter is generating a number of leading and trailing “no-value” samples that depends on the data-take length 
                               that can be of several minutes. The former creates radiometric artefacts complicating the detection of the “no-value” samples. 
                               These “no-value” pixels are not null but contain very low values which complicates the masking based on thresholding. 
                               This operator implements an algorithm allowing masking the \"no-value\" samples efficiently with thresholding method."),
                            hr(),
                            tags$b("4. Terrain Flattening"),
                            p("When land cover classification is applied to terrain that is not flat, inaccurate classification result is produced. 
                               This is because that terrain variations. affect not only the position of a target on the Earth's surface, but also the 
                               brightness of the radar return. Without treatment, the radiometric biases caused by terrain variations are introduced 
                               into the coherency and covariance mstrices. It is often seen that the classification result mimic the radiometry rathen 
                               than the actual land cover. This operator removes the radiometric variability associated with topography using the 
                               terrain flattening method proposed by Small [1] while leaving the radiometric variability associated with land cover.")
                   ),
                   
                   tabPanel("References",      
                            p("Small, D. (2011): Flattening Gamma: Radiometric Terrain Correction for SAR imagery. in: 
                            IEEE Transaction on Geoscience and Remote Sensing, Vol. 48, No. 8, ")
                    )
                            
                   
            )
          )
            
        ) # close fluid row
) # close tabitem
            
            
          