#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_grd2rtc-ts",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          #----------------------------------------------------------------------------------
          # Processing Panel Sentinel-1
          box(
            # Title                     
            title = "Processing Panel", status = "success", solidHeader= TRUE,
            tags$h4("Sentinel-1 GRD to RTC time-series processor"),
            hr(),
            #tags$b("1) Input Type:"),
            # AOI choice
            radioButtons("s1_g2ts_input_type", "1) Input type",
                         c("Folder (i.e. data is already downloaded)" = "folder",
                           "OST inventory shapefile (i.e. data needs to be downloaded first)" = "inventory")),

            conditionalPanel(
              "input.s1_g2ts_input_type == 'folder'",
              
              shinyDirButton("s1_g2ts_inputdir","Choose S1 DATA folder in your project directory","Choose the DATA folder inside your project directory",FALSE),
              br(),
              br(),
              verbatimTextOutput("s1_g2ts_inputfolder")
            ),
            
            conditionalPanel(
              "input.s1_g2ts_input_type == 'inventory'",
              shinyFilesButton("s1_g2ts_shp","Choose S1 DATA file","Choose one or more files",FALSE),
              br(),
              br(),
              verbatimTextOutput("s1_g2ts_shp_filepath"),
              hr(),
              tags$b("2) Output directory"),
              p("Note: A new folder named \"DATA\" will be created within the chosen Output directory. 
               Within this folder the downloaded data files will be stored and further sorted by satellite track and acquistion date."),
              shinyDirButton("s1_g2ts_outdir","Browse","Choose the DATA folder inside your project directory",FALSE),
              br(),
              br(),
              verbatimTextOutput("s1_g2ts_outfolder"),
              hr(),
              tags$b("3) Provide your NASA Earthdata username/password."), 
              p("If you are not in possess of a user account you can create one ",a(href = "https://urs.earthdata.nasa.gov/", "here"),"."),
              textInput(inputId = "s1_asf_uname2",
                        label = "Username", 
                        value = "Type in your username" 
              ),
              
              passwordInput(inputId = "s1_asf_piwo2",
                            label = "Password",
                            value = "Type in your password"
              ),
              hr()
              
              ),
              hr(),
              conditionalPanel(
                 "input.s1_g2ts_input_type == 'folder'",
                  radioButtons("s1_g2ts_res", "2) Choose the output resolution:",
                           c("Medium Resolution (30m)" = "med_res",
                             "Full resolution (10m)" = "full_res")
               )
             ),
            
             conditionalPanel(
                "input.s1_g2ts_input_type == 'inventory'",
                radioButtons("s1_g2ts_res", "4) Choose the output resolution:",
                         c("Medium Resolution (30m)" = "med_res",
                           "Full resolution (10m)" = "full_res")
                )
             ),
             hr(),
             actionButton("s1_g2ts_process", "Start processing"),
             br(),
             br(),
             "Output:",
             verbatimTextOutput("processS1_G2TS")
            
          ), #close box
          
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
          box(
            title = "Info Panel", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   
                   tabPanel("General Info",
                            tags$h4("Sentinel-1 GRD to RTC time-series processing "),
                            p("This script will produce radiometrically terrain-corrected (RTC) products for a set of imagery. 
                               Input can be either a \"DATA\" folder created by the automatic download routine of OST, or an 
                               OST inventory shapefile, by which the data will be downloaded first and subsequent processing takes place."),
                            p("If more than one frame is present for a specific acquisition date, the processing chain 
                               will automatically assemble them to one single product. Moreover, advantage is taken by multiple images 
                               acquired over the same satellite track. That allows for the creation of more robust data layers 
                               that can be subsequently used for different classification tasks."),
                            p("In particular, the use of multi-temporal SAR products features the following advantages:"),
                            tags$b("1) Enhanced Speckle Noise Reduction:"),
                            p("The use of multiple images over one area allows to reduce Speckle not only in the spatial domain as done for single imagery. 
                               The combination of adaptive spatial filters and temporal statistics can significantly improve the quality of the single image (see Figure 1)."),
                            img(src = "MT_speckle.png", width = "100%", height = "100%"),
                            tags$b("Figure 1: Sentinel-1 VV-polarized image taken at 01.09.2016 over a partly forested area in Congo. 
                                    Left: Image filtered only in the spatail domain using the Refined Lee Speckle Filter.
                                    Right: Image filtered in the spatial and temporal domain as part of a multi-temporal stack of 10 images."),
                            br(),
                            br(),
                            tags$b("2) The creation of multi-temporal statistics."),
                            p("Having a set of images acquired over the same spot, but on different dates, allows for the calculation of metrics 
                               calculated in the temporal domain. In this way, temporal dynamics are aggregated and less storage space is needed, 
                               which also improves the performance of classifiers. The processing chain will automatically detect if single- or 
                               dual polarised data has been used. 5 different metrics are produced for each polarization:"),
                               p("  - Average backscatter in time "),
                               p("  - Maximum backscatter in time "),
                               p("  - Minimum backscatter in time "),
                               p("  - Standard deviation in time "),
                               p("  - Coefficient of variation in time"),
                               p(" Figure 2 depicts an exemplary colour composition. A set of 10 dual-polarised Sentinel-1 IW images, acquired 
                                   between the 15th of July 2016 and the 31st of October 2016, have been used. The above mentioned
                                   multi-temporal metrics were automatically produced for each polarisation."),
                            img(src = "MT_ts.png", width = "100%", height = "100%"),
                            tags$b("Figure 2: Left: High-resolution optical imagery taken from Google Earth over an area in Congo. Right:  "),
                            p("")
                            ),
                   
                   tabPanel("Processing chain",
                            tags$h4("The Sentinel-1 GRD to RTC time-series processor"),
                            br(),
                            p(""),
                            br(),
                            p(""),
                            br()
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
          
        ) # close fluid row
) # close tabitem
            
            
          