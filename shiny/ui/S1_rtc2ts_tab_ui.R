#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_rtc2ts",
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
                   
            tabPanel("Processor",
            tags$h4("Sentinel-1 RTC to time-series & timescan processor"),
            span(textOutput("RAMwarning_rtc2ts"), style='color:red'),
            hr(),
            tags$b("Short description:"),
            p("This interface allows the fully-automated generation of time-series and timescan products. It expects the folder structure 
               created by the data download tab and that all data has been already processed by the GRD to RTC processor, using the time-series preparation option.
               If more than one track is present within the data folder, the procedure will generate 
               the final product for each track separately. The output can be subsequently mosaicked by using the routine in the time-series mosaics submenu. "),
            hr(),
            tags$b("Processing directory:"),
            p("The path should point to the", tags$b(" DATA directory "), 
              "created by routine of the data download submenu, within your project folder, i.e. \"/path/to/project/DATA\""),
            shinyDirButton("s1_rtc2ts_inputdir","Browse","Browse",FALSE),
            br(),
            br(),
            verbatimTextOutput("s1_rtc2ts_inputdir"),
            hr(),
            tags$b("Select the desired multi-temporal product:"), 
            p("The time-series processor creates a co-registered, multi-temporal speckle-filtered stack of of all available overlapping scenes per track and polarisation, 
               Allclipped to the same extent. Timescan data aggregates the time-series data by calculating basic 
               descriptive statistics for each polarization in the temporal domain."),
            radioButtons("s1_rtc2ts_mode", "",
                         c("Time-series & Timescan" = "1",
                           "Time-series only" = "2",
                           "Timescan only" = "3"),
                           "1"),hr(),
            
            #---------------------------------------------------------------------------
            # Datatype selction
            tags$b("Choose the output datatype for the timeseries/timescan products."), 
            p("Those values represent the amount of space reserved for one pixel per band."),
            radioButtons("s1_rtc2ts_dtype", "",
                         c("16 bit unsigned integer (recommended)" = "1",
                           "8 bit unsigned integer" = "2",
                           "32 bit floating point" = "3"),
                           "1"),hr(),
            #---------------------------------------------------------------------------
            
            #---------------------------------------------------------------------------
            # trigger and abort buttons
            div(style="display: inline-block;vertical-align:top; width: 135px;",withBusyIndicatorUI(
              actionButton("s1_rtc2ts_pro_btn", "Start processing"))),
            div(style="display: inline-block;vertical-align:top; width: 125px;", withBusyIndicatorUI(
              actionButton("s1_rtc2ts_abort_btn", "Abort processing")
            )),
            #"Output:",
            textOutput("processS1_RTC2TS")
            ),
            #---------------------------------------------------------------------------
            
            # tab panel for cleaning up files
            tabPanel("Clean up files",
                     # Title
                     tags$h4("Clean up intermediate products"),
                     tags$b("DATA directory:"),br(),br(),
                     shinyDirButton("S1_ts_cleanupdir","Select S1 DATA folder in your project directory","Select S1 DATA folder in your project directory",FALSE),br(),br(),
                     verbatimTextOutput("S1_ts_cleanupdir"),hr(),
                     
                     tags$b("Clean up raw files"),
                     p("This button deletes all the raw Sentinel-1 zip files downloaded in the first place by the",tags$i(" Data Download "), " tab."),
                     withBusyIndicatorUI(
                       actionButton("s1_ts_clean_raw", "Delete files")
                     ),
                     #"Output:",
                     textOutput("cleanS1RAW"),hr(),
                     tags$b("Clean up RTC/LS files"),
                     p("This button deletes all the single, radiometrically terrain corrected products 
                        as well as the single layover/shadow maps generated during the GRD to RTC processing.",tags$i(" Data Download "), " tab."),
                     withBusyIndicatorUI(
                       actionButton("s1_ts_clean_rtc", "Delete files")
                     ),
                     #"Output:",
                     textOutput("cleanS1RTC"),br(),hr(),
                     
                     tags$b("Delete Time-series data"),
                     p("This button deletes the Time-series folder for each track within the project directory."),
                     withBusyIndicatorUI(
                       actionButton("s1_ts_clean_timeseries", "Delete files")
                     ),
                     #"Output:",
                     textOutput("cleanS1TS"),hr(),
                     
                     
                     tags$b("Delete Timescan data"),
                     p("This button deletes the Timescan products for each track within the project directory."),
                     withBusyIndicatorUI(
                       actionButton("s1_ts_clean_timescan", "Delete files")
                     ),
                     #"Output:",
                     textOutput("cleanS1TScan"),hr()
                     )
            )
          ), #close box
          
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
          box(
            title = "Info Panel", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   
                   tabPanel("Processing Monitor",
                            tags$h4("Monitor the progress of a running process"),hr(),
                            verbatimTextOutput("s1_rtc2ts_progress")
                   ),
                            
                   tabPanel("General Info",
                            tags$h4("Processing chain"),
                            hr(),
                            p("The ", tags$b("RTC to time-series/timescan processor"), " (Figure 1) applies the necessary preprocessing steps for preparing multi-temporal stacks of Sentinel-1 RTC products
                               generated by the ", tags$b("GRD to RTC processor."), " Those stacks are ready-to-use for time-series analysis, or the subsequent generation of timescan products."),
                            p("The user has the choice to select ", tags$b("different data types"), " of the resulting stack. While loosing radiometric resolution, the necessary disk space is reduced by a factor of 2 
                               for 16 bit unsigned integer, and by a factor of 4 for 8 bit unsigned integer products. A good trade-off between disk space and radiometric accuracy is usually 
                               the 16 bit option, since it still holds a sensitivity of about 0.00045 dB. The conversion to 8 bit channels, instead, results in a histogram binning of 0,11 dB."),
                            p("The ", tags$b("output"), " is written to a newly created folder named \"Timeseries\" within the track folder created by the data download routine. Inside this folder each scene can be found, 
                               sorted by a starting number. The actual stack can be opened by using the correspondend \"Virtual Raster Table\" (VRT) file (i.e. timeseries.VV.vrt). 
                               This is a simple xml text file that refers to the actual single layers of the stack. Band numbering of the stack refers to the numbers set as a prefix for each acquisition 
                               and are sorted by the acquisition date."),
                            p("The routine will automatically detect if the ", tags$b("input imagery"), " has been acquired in ", tags$b("dual-polarised mode."), " Only if all imagery has been acquired in dual-polarised mode, the processing 
                               routine will create the time-series stack for the VH polarisation (i.e. timeseries.VH.vrt)."),
                            p("For an easy", tags$b(" assessment of the quality,"), " thumbnail images and an animated gif file are created as well. This helps to identify images where the backscatter is
                               affected by heavy rainfall events or other disturbing factors. "),
                            img(src = "S1_RTC2TS/TimeseriesWorkflow.jpg", width = "100%", height = "100%"),
                            tags$b("Figure 1: Preprocessing chain of the RTC to time-series processor for Sentinel-1 RTC data prepared by the RTC to GRD processor. 
                                    Note that the generation of the VH-polarised time-series only applies if all imagery has been acquired in the dual-polarised mode."),
                            br(),
                            br(),
                            p("Using", tags$b(" multi-temporal SAR data"), " features some", tags$b("advantages"), " over single image use. First of all, the use of multiple imagery
                               over one area allows for more", tags$b(" effective reduction of Speckle noise."), "The combination of adaptive spatial filters and temporal statistics can 
                               significantly improve the quality of all single scenes within the multi-temporal stack (Figure 2)."),
                            img(src = "MT_speckle.png", width = "100%", height = "100%"),
                            tags$b("Figure 1: Sentinel-1 VV-polarized image taken at 01.09.2016 over a partly forested area in Congo. 
                                    Left: Image filtered only in the spatail domain using the Refined Lee Speckle Filter.
                                    Right: Image filtered in the spatial and temporal domain as part of a multi-temporal stack of 10 images."),
                            br(),
                            br(),
                            p("Another advantage of multi-temporal data is that ", tags$b("temporal dynamics"), " of the earth's surface are captured. Thus the succession of different 
                               biogeophysical processes can potentially be tracked by various types of time-series analysis."),
                            p("The temporal variation of the signal can also give information on the ", tags$b("type of land cover."), " Feeding a classifier with a stack of single imagery 
                               acquired at different dates may however result in long processing times, and the data storage demand is increased as well. This is especially true for Sentinel-1,
                               where the 6-24 days repeat cycle quickly leads to a massive accumulation of data. The ", tags$b("Timescan"), " approach overcomes this issue 
                               by aggregating the temporal information for each polarisation channel separately. For every pixel of the time-series stack, 
                               a basic set of descriptive statistics are calculated in time: "),
                               p("  - Average backscatter in time "),
                               p("  - Maximum backscatter in time "),
                               p("  - Minimum backscatter in time "),
                               p("  - Standard deviation in time "),
                               p("  - Coefficient of Variation (CoV) in time"),
                             p("For example, the", tags$b(" average backscatter"), " in time further reduces Speckle noise. The  ", tags$b("minimum backscatter,"), " instead, may reduce
                                the influence of soil moisture, given that the dry period is covered within the time-series stack. 
                                The ", tags$b("standard deviation"), " allows differentiating between land cover classes that have rather stable backscatter over time (e.g. urban, forests, water) from 
                                surfaces with varying backscatter behaviour (e.g. agricultural fields, wetlands).
                                The ", tags$b("coefficient of variation,"), " which depicts the ratio of the standard deviation divided by the mean, represent the relative variation 
                                of the backscatter. In this way, classes with a small standard deviation, but different levels of mean backscatter values (e.g. water and urban) become 
                                distinguishable."),
                             p("By applying this approach to both polarisations, a total of 10 channels is available. Figure 3 depicts an exemplary colour composition. A set of 
                                10 dual-polarised Sentinel-1 IW images, acquired 
                                between the 15th of July 2016 and the 31st of October 2016, have been used. Similar to the time-series stack, all bands are actually stored
                                singularly, but an additional VRT-file is present to load the whole stack into your favorite GIS environment, or to use it for subsequent data fusion or
                                classification tasks."),
                            img(src = "MT_ts.png", width = "100%", height = "100%"),
                            tags$b("Figure 2: Left: High-resolution optical imagery taken from Google Earth over an area in Congo. 
                                    Right: Timescan RGB composite using a band combination of VH-maximum (red), VV-minimum (green) and VV-CoV (blue).   ")
                            ),
                   
                   
                   tabPanel("Detailed Description",
                            tags$h4("Description of the single processing steps"),
                            hr(),
                            tags$b("1.) Image stacking"),
                            p("The image stacking takes all available RTC scenes per track and collocates the spatially overlapping products.
                               Collocating the products implies that the pixel values of some products (the slave imageries) are resampled into the geographical
                               raster of a master image, which is usually refers to the earliest date. Resampling of the slave imagery is then achieved by bilinear interpolation."),
                            hr(),
                            tags$b("2.) Multi-temporal Lee-Sigma Speckle Filter"),
                            p("SAR images have inherent salt and pepper like texturing called speckles which degrade the quality of the image and make interpretation of features more difficult. 
                               The speckles are caused by random constructive and destructive interference of the de-phased but coherent return waves scattered by the elementary scatters 
                               within each resolution cell. Multi-temporal filtering is one of the commonly used speckle noise reduction techniques."),
                            p("The SNAP toolbox provides a modified approach, firstly proposed by Quegan et al 2000. The Lee-Sigma Filter is applied in the spatial domain and information 
                               from the temporal domain are applied as stated in the original approach. The filter uses a window size of 7x7, a target window size of 3x3, 
                               and a sigma of 0.9."),
                            hr(),
                            tags$b("3.) Linear power to decibal scale"),
                            p("The received power of the backscattering is usually measured in linear power. Depending on the surface, the measurement can vary across a wide range. 
                               In order to derive a more balanced output, logarithmic scaling in decibel (dB) is applied."),
                            hr(),
                            tags$b("4.) Clip to minimum common extent"),
                            p("In order to assure that every pixel contains the same amount of temporal measurements, the time-series stack is clipped to the minimum common extent of the
                               whole set of imagery."),
                            hr(),
                            tags$b("5.) Scaling to integer value (optional)"),
                            p("In order to reduce disk space, values of each polarization are linearly stretched between -25 and 5 dB. This partially reduces the radiometric resolution.
                               "),
                            hr(),
                            tags$b("6.) Mask out Layover/Shadow areas"),
                            p("The layover/shadow masks are combined for all images, assuring that at no point in time an area affected by layover/shadow is present. Respective data points
                               exhibit 0 as no data value."),
                            hr(),
                            tags$b("7.) Time-series - output"),
                            p("The time-series processor generates a single file per date, track and polarisation in GeoTiff format, which can be found in a newly created \"Timeseries\" folder.
                               A prefix number is added, which reflects the cronical order of the acquisition. In order to open the whole time-series stack, a VRT file is present 
                               for each polarisation (e.g. timeseries.VV.vrt). "),
                            p("Inside the \"Timeseries\" folder a file named \"time_animation.gif\" allows for a quick quality assessment of the data. The file is generated using the Thumbnail files. 
                               Those are located within the same folder, produced at 20% of the original image size."),
                            hr(),
                            tags$b("8.) Timescan calculation and output"),
                            p("The timescan approach aggregates the time-series data by calculating basic descriptive statistics in the temporal domain. "),
                            hr()
                            ),
                   tabPanel("Demo",
                            br(),
                            tags$h4("Demo I: Create a time-series stack"),
                            br(),
                            p("Within this demo a time-series stack will be created. The accompanying slides contain a step-by-step guide and deepen the understanding of the user 
                              handling and interpreting multi-temporal SAR data sets."),
                            #p("Here you can download a directory that contains Sentinel-1 imagery acquired over a small area in the south of Taman Nasional Sebangau area in South Kalimantan, Indonesia. 
                            #  This data will be placed in your home folder. In order to process, choose", tags$b("/home/username/S1_timeseries_demo/Demo_Jena/DATA"), "as the project directory. 
                            #  The resultant time-series data can be found in", tags$b("/home/username/S1_timeseries_demo/Demo_Jena/DATA/044A/Timeseries"), "and",
                            #  tags$b("/home/username/S1_timeseries_demo/Demo_Jena/DATA/044A/MT_metrics",".")),
                            #withBusyIndicatorUI(
                            #  actionButton("S1_ts_testdata_download", "Download")
                            #),
                            #br(),
                            #textOutput("download_Demo_Jena"),
                            hr(),
                            tags$h4("Demo II: Create a timescan composite"),
                            br(),
                            p("Within this demo a timescan composite will be created. The accompanying slides contain a step-by-step guide and deepen the understanding of the user 
                              handling and interpreting timescan composites. A special focus is given for land cover applications."),
                            tags$b("In preparation"),
                            hr(),
                            tags$h4("Demo III: Multi-temporal data and Deforestation"),
                            br(),
                            p("Within this demo we will focus on the signatures of deforestation in time-series and timescan data. The accompanying slides contain a step-by-step guide and deepen the understanding of the user 
                              handling and interpreting timescan composites. "),
                            #p("Further examples can be found here using ESA SAR data of the last 25 years. https://earth.esa.int/web/earth-watching/20-years-of-sar/-/asset_publisher/084v29WO4EeJ/content/global-deforestation-2012?redirect=https%3A%2F%2Fearth.esa.int%2Fweb%2Fearth-watching%2F20-years-of-sar%3Fp_p_id%3D101_INSTANCE_084v29WO4EeJ%26p_p_lifecycle%3D0%26p_p_state%3Dnormal%26p_p_mode%3Dview%26p_p_col_id%3Dcolumn-1%26p_p_col_pos%3D1%26p_p_col_count%3D2")
                            tags$b("In preparation"),
                            hr(),
                            tags$h4("Demo IV: Reprocessing of data due image artifacts caused by heavy rainfall. "),
                            br(),
                            p("While SAR is capable of seeing through clouds, heavy rainfall events during the time of data acquisition can lead to unwanted artifacts within the imagery due to 
                               attenuation of the transmitted radiation. In such a case it is necessary to sort out the affected imagery and re-run the RTC to time-series and timescan processor. 
                               The accompanying slides contain a step-by-step guide and help the user identify unwanted image artifacts caused by heavy rainfall."),
                            tags$b("In preparation")
                   ),
                   tabPanel("References",
                            br(),
                            tags$b("References"),
                            tags$b("Scientific Articles"),
                            p("Quegan et al. (2000): Multitemporal ERS SAR Analysis Applied to Forest Mapping. in: IEEE Transactions on Geoscience and Remote Sensing. 38. 2.")
                   )
                   
                            ) # close tab box
                   ) # close box
          
        ) # close fluid row
) # close tabit
