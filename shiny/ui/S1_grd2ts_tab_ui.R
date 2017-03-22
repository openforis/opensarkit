#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_grd2rtc-ts",
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
            tags$h4("Sentinel-1 GRD to RTC time-series & timescan processor"),
            hr(),
            tags$b("DATA directory:"),
            br(),
            shinyDirButton("s1_g2ts_inputdir","Select S1 DATA folder in your project directory","Select S1 DATA folder in your project directory",FALSE),
            br(),
            br(),
            verbatimTextOutput("s1_g2ts_inputfolder"),
            hr(),
            tags$b("Area of Interest"),
            p("Note: This parameter will apply only to the timeseries and timescan products."),
            # AOI choice
            radioButtons("S1_g2ts_AOI", "",
                         c("Country boundary" = "S1_g2ts_country",
                           "Shapefile (local/ on server)" = "S1_g2ts_shape_local",
                           "Shapefile (upload a zipped archive)" = "S1_g2ts_shape_upload")),
            
            conditionalPanel(
              "input.S1_g2ts_AOI == 'S1_g2ts_country'",
              selectInput(
                inputId = 'S1_g2ts_countryname', 
                label = '',
                choices = dbGetQuery(
                  dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                  sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                selected=NULL)
            ),
            
            conditionalPanel(
              "input.S1_g2ts_AOI == 'S1_g2ts_shape_local'",
              shinyFilesButton("S1_g2ts_shapefile","Browse","Choose one shapefile",FALSE),
              br(),
              br(),
              verbatimTextOutput("S1_g2ts_filepath")
            ),
            
            conditionalPanel(
              "input.S1_g2ts_AOI == 'S1_g2ts_shape_upload'",
              fileInput('S1_g2ts_shapefile_path', label = '',accept = c(".shp"))
            ),
            
            hr(),
            radioButtons("s1_g2ts_res", "Choose the output resolution:",
                         c("Medium Resolution (30m, recommended)" = "med_res",
                           "Full resolution (10m)" = "full_res")),
            hr(),
            tags$b("Choose the output datatype for the timeseries/timescan products."), 
            p("Note: Those values represent the amount of space reserved for one pixel per band. "),
            radioButtons("s1_g2ts_dtype", "",
                         c("Unsigned Integer (8 bit)" = "8_bit",
                           "Unsigned Integer (16 bit, recommended)" = "16_bit",
                           "Floating Point (32 bit)" = "32_bit")),
            hr(),
            withBusyIndicatorUI(
              actionButton("s1_g2ts_process", "Start processing")
            ),
            br(),
            br(),
            #"Output:",
            textOutput("processS1_G2TS")
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
                            tags$b("Figure 2: Left: High-resolution optical imagery taken from Google Earth over an area in Congo. 
                                    Right: RGB composite using the  "),
                            p("")
                            ),
                   
                   tabPanel("Processing chain",
                            tags$h4("The Sentinel-1 GRD to RTC time-series processor"),
                            br(),
                            p(""),
                            img(src = "S1_GRD_ts_grd2rtc.png", width = "100%", height = "100%"),
                            tags$b("Figure 1: First part of the processing chain. This workflow is applied to every SAR acquisition."),
                            br(),
                            br(),
                            img(src = "S1_GRD_ts_grd2rtc_mt.png", width = "100%", height = "100%"),
                            tags$b("Figure 2: Second part of the processing chain. This workflow creates the time-series imagery and multi-temporal stats."),
                            p(""),
                            br()
                            ),
                   
                   tabPanel("References",
                            br(),
                            tags$b("References")
                   )
                            ) # close tab box
                   ) # close box
          
        ) # close fluid row
) # close tabit
