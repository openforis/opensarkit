#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_grd2gtc",
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
            tags$h4("Sentinel-1 GRD to GTC processor"),
            span(textOutput("s1_g2g_RAMwarning"), style='color:red'),
                      #if (detectCores(FALSE, TRUE) < 8){
            # tags$b("You have not enough cpu's to do processing ")},
            hr(),
            tags$b("Short description:"),
            p("This interface allows processing Sentinel-1 GRD scenes to higher level GTC products. Either single files or multiple scenes can be processed. For the latter, 
               preparation as well as execution of subsequent time-series can be optionally selected. For details on the applied processing steps check the info panel on the right."),
            hr(),
            
            tags$b("Input type:"),
            p("This option lets you choose if only a single file, or multiple scenes should be processed in batch mode. For the latter, the path should point to the", tags$b(" DATA directory "), 
              "created by routine of the data download submenu, within your project folder, i.e. \"/path/to/project/DATA\""),
            radioButtons("s1_g2g_input_type", "",
                         c("Original File" = "s1_g2g_file",
                           "Folder (batch processing)" = "s1_g2g_folder")),
            
            conditionalPanel(
              "input.s1_g2g_input_type == 's1_g2g_file'",
              tags$b("Select a Sentinel-1 zip file:"),br(),br(),
              shinyFilesButton("s1_g2g_zip","Browse","Browse",FALSE),br(),br(),
              verbatimTextOutput("s1_g2g_zip"),hr(),
              tags$b("Output directory:"),
              p("Select a folder where the output data files will be written to:"),
              shinyDirButton("s1_g2g_outdir","Browse","Browse",FALSE),br(),br(),
              verbatimTextOutput("s1_g2g_outdir"),hr(),
              
              #-----------------------------------------------------------------------------------------------------------------------------------  
              tags$b("Select the output resolution:"),
              p("This parameter defines the output resolution of your products in meter. Note that for SAR data a 
               higher resolution is not always favorable since it is more affected by Speckle noise. 
               In addition, a 10 m product will occupy 9 times more disk space and processing takes considerably longer."),
              radioButtons("s1_g2g_res_file", "",
                           c("Medium Resolution (30m, recommended)" = "med_res",
                             "Full resolution (10m)" = "full_res"),
                             selected = "med_res")
             ),
             #-----------------------------------------------------------------------------------------------------------------------------------
             
             #-----------------------------------------------------------------------------------------------------------------------------------
             # Batch processing options
             conditionalPanel(
              "input.s1_g2g_input_type == 's1_g2g_folder'",
              tags$b("Project directory:"),
              p("The path should point to the", tags$b(" DATA directory "), 
                "created by routine of the data download submenu, within your project folder, i.e. \"/path/to/project/DATA\""),
              shinyDirButton("s1_g2g_inputdir","Browse","Browse",FALSE),br(),br(),
              verbatimTextOutput("s1_g2g_inputdir"),hr(),
              
                  #-----------------------------------------------------------------------------------------------------------------------------------
                  # Resolution choice
                  tags$b("Select the output resolution:"),
                  p("This parameter defines the output resolution of your products in meter. Note that for SAR data a 
                     higher resolution is not always favorable since it is more affected by Speckle noise. 
                     In addition a 10 m product will occupy 9 times more disk space and processing takes considerably longer."),
                  radioButtons("s1_g2g_res_folder", "",
                           c("Medium Resolution (30m)" = "med_res",
                             "Full resolution (10m)" = "full_res"),
                              selected = "med_res"),hr(),
                  tags$b("Select the product generation mode:"),
                  p("The standard RTC generation should only be selected, if single imagery is of particular interest. Elsewise, when acquistions from the same satellite track, but different dates
                     overlap, use the time-series preparation mode and apply the subsequent RTC to time-series processor."),
                  radioButtons("s1_g2g_mode", "",
                           c("Standard RTC generation" = "0",
                             "Timeseries preparation" = "1"),
                             "0"),hr(),
                  #-----------------------------------------------------------------------------------------------------------------------------------
              
                  #-----------------------------------------------------------------------------------------------------------------------------------
                  # Datatype choice
                  conditionalPanel(
                    "input.s1_g2g_mode == 1",
                  tags$b("Apply the Time-series/Timescan processing?"),
                  p("This option provides the possibility to concatenate the GRD to RTC processor with the RTC to time-series processor. The selected datatype applies 
                     only for the multi-temporal products (i.e. time-series/timescan). For more details on the RTC to time-series processor go to the respective submenu on the left."),
                  radioButtons("s1_g2g_ts", "",
                        c("No" = "0",
                        "Yes (16 bit unsigned integer, recommended)" = "1",
                        "Yes (8 bit unsigned integer)" = "2",
                        "Yes (32 bit floating point )" = "3"),
                        "1")
                  )),hr(),
                  #-----------------------------------------------------------------------------------------------------------------------------------
            #-----------------------------------------------------------------------------------------------------------------------------------
            
            
            #-----------------------------------------------------------------------------------------------------------------------------------
            # Trigger / Abort
            div(style="display: inline-block;vertical-align:top; width: 135px;",withBusyIndicatorUI(
              actionButton("s1_g2g_pro_btn", "Start processing"))),
            div(style="display: inline-block;vertical-align:top; width: 125px;", withBusyIndicatorUI(
              actionButton("s1_g2g_abort_btn", "Abort processing")
            )),
            #"Output:",
            textOutput("processS1_G2G")
            ), #close box
            #-----------------------------------------------------------------------------------------------------------------------------------
          
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
          box(
            title = "Info Panel", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   tabPanel("Progress Monitor",
                            tags$h4("Monitor the progress of a running process"),hr(),
                            verbatimTextOutput("s1_g2g_progress")
                   ),
                   tabPanel("General Info",
                            tags$h4("Processing Chain"),hr(),
                            p("The", tags$b("GRD to GTC processor")," applies the necessary preprocessing for preparing either single, analysis-ready-data products 
                               suitable for land and sea applications, or multiple scenes for the subsequent generation of time-series. It expects Level-1 GRD Sentinel-1 data as distributed
                               by the ESA ground segment and transforms the image(s) to Level-2 geometrically terrain-corrected (GTC) product(s)."),
                            p(tags$b("Compatibility"), " is limited to the standard image modes for Sentinel-1 over land, i.e. the Interferometric Wide Swath mode (IW) in either single-polarised VV, 
                               or dual-polarised VV & VH polarisation. Other image modes are not yet supported."),
                            p("There is the possibility to preprocess a ",tags$b("single file"), " as well as batch process ",tags$b("multiple scenes"), ". For the latter,
                               the folder structure created by the Data download routine is required."),
                            p("Compared to optical data, ",tags$b("resolution"), " is more of an arbitrary concept for SAR data and can be handled flexible. On the cost of resolution, 
                               Speckle-Noise is reduced by the so-called multi-looking operation. Therefore it is recommended to rather process the data at 30 m medium resolution, if
                               10 m full resolution is not an absolute priority. Also note that for the full resolution product, the required disk space increases by a factor of 9 
                               and processing takes considerably more time."),
                            p("For single files the", tags$b("Standard GRD to GTC processor")," (Figure 1) applies automatically. Note that the underlying processing routine 
                               automatically detects, if the input image had been acquired in single- or in dual-polarised polarisation mode. As a result, the output product is either 
                               a single-band greyscale image (for single-polarised scenes) or a 3-band RGB image that contains the VV (Red) and VH polarisation (Green) channels, 
                               as well as the VV/VH ratio (Blue)."),
                            img(src = "S1_GRD2GTC/GRD2GTC_single.jpg", width = "100%", height = "100%"),
                            tags$b("Figure 1: Preprocessing chain of the Standard GRD to GTC processor for single-polarised (A) and dual-polarised (B) Sentinel-1 data. 
                                    Note that according to the input product, the routine will automatically adapt to single- or dual polarised mode."),
                            br(),
                            br(),
                            p("Batch processing, instead, can be performed in 2 ways. The", tags$b("Standard GRD to GTC processor")," will produce the same output as for single files. 
                               If the area of interest is covered by more than one image frame for the same acquisition date, both frames will be automatically
                               assembled to a single, seamless swath product."),
                            p("If the", tags$b("generation of time-series"), " is envisaged, the ", tags$b("time-series preperation mode")," needs to be chosen. 
                               The processing routine is slightly different (Figure 2), mainly because Speckle-Filtering will be applied subsequently on the time-series stack, 
                               taking advantage of spatio-temporal statistics (i.e. multi-temporal Speckle-Filtering)."),
                            p("The actual generation of ", tags$b("time-series and timescan"), " products can be already included in the processing. Here it is also possible to choose between 
                               different output data types. The idea is to reduce the storage demand, however, on the cost of radiometric accuracy. 16 bit unsigned integer is usually 
                               a good trade-off between the two. "),
                            p("For more details on the time-series and timescan product generation, see the info panel in the Time-series/Timescan processor."),
                            img(src = "S1_GRD2GTC/GRD2GTC_tsprep.jpg", width = "100%", height = "100%"),
                            tags$b("Figure 2: Preprocessing chain of the Timeseries preparation GRD to RTC processor for single-polarised (A) and dual-polarised (B) Sentinel-1 data. 
                                    Note that according to the input product, the routine will automatically adapt to single- or dual polarised mode.")
                          ),
                   
                   tabPanel("Detailed Description",
                            tags$h4("Description of the single processing steps"),
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
                            tags$b("3. Swath Assembly (optional)"),
                            p("Sentinel-1 acquires all data in one single take for a maximum of 25 minutes per orbit. However, for easier data distribution, 
                               the acquired swaths are divided into single slices (or frames). If the processor detects more than one acquisition per swath for the same date, those products
                               will be automatically assembled to a single product. Note that this step only applies to the batch processing mode."),
                            hr(),
                            tags$b("4. GRD Border Noise Removal"),
                            p("The Sentinel-1 (S-1) Instrument Processing Facility (IPF) is responsible for generating the complete family of Level-1 
                               and Level-2 operation products. The processing of the RAW data into L1 products features number of processing 
                               steps leading to artefacts at the image borders. These processing steps are mainly the azimuth and /range compression and 
                               the sampling start time changes handling that is necessary to compensate for the change of earth curvature. 
                               The latter is generating a number of leading and trailing “no-value” samples that depends on the data-take length 
                               that can be of several minutes. The former creates radiometric artefacts complicating the detection of the “no-value” samples. 
                               These “no-value” pixels are not null but contain very low values which complicates the masking based on thresholding. 
                               This operator implements an algorithm allowing masking the \"no-value\" samples efficiently with thresholding method."),
                            hr(),
                            tags$b("5. Calibration to beta nought"),
                            p("The objective of SAR calibration is to provide imagery in which the pixel values can be directly related to the radar backscatter of the scene. 
                               Though uncalibrated SAR imagery is sufficient for qualitative use, calibrated SAR images are essential to quantitative use of SAR data.
                               Typical SAR data processing, which produces level 1 images, does not include radiometric corrections and significant radiometric bias remains.
                               Therefore, it is necessary to apply the radiometric correction to SAR images so that the pixel values of the SAR images truly represent the 
                               radar backscatter of the reflecting surface. The radiometric correction is also necessary for the comparison of SAR images acquired with 
                               different sensors, or acquired from the same sensor but at different times, in different modes, or processed by different processors."),
                            p("In order to prepare the data for the subsequent terrain flattening, the SAR data has to be calibrated to the radar brightness (beta nought)."),
                            hr(),
                            tags$b("6. Lee-Sigma Speckle filtering (applies only for Standard GRD to RTC processor)"),
                            p("SAR images have inherent salt and pepper like texturing called speckles which degrade the quality of the image and make interpretation
                               of features more difficult. Speckles are caused by random constructive and destructive interference of the de-phased but coherent return
                               waves scattered by the elementary scatters within each resolution cell. Speckle noise reduction can be applied either by spatial 
                               filtering or multilook processing."),
                            p("For the Standard GRD to RTC processor, the adaptive spatial Lee-Sigma filter is automatically applied by using a window size of 7x7, a target window size of 3x3, 
                               and a sigma of 0.9. For the time-series processing chain this step will be skipped, since a more advanced spatio-temporal filtering will be applied after RTC generation."),
                            hr(),
                            tags$b("7. SAR-simulation/Layover-shadow mask"),
                            p("In a first step, the operator generates a simulated SAR image using a DEM, the Geocoding and orbit state vectors from a given SAR image, and 
                                mathematical modeling of SAR imaging geometry. The simulated SAR image will have the same dimension and resolution as the original SAR image."),
                            p("Based on the geomtrical information of the acquisition and the DEM, layover and shadow areas are detected and subsequently masked out."),
                            hr(),
                            tags$b("8. Multi-loooking (only applies for 30 m product output)"),
                            p("Generally, a SAR original image appears speckled with inherent speckle noise. To reduce this inherent speckled appearance, 
                               several images are incoherently combined as if they corresponded to different looks of the same scene. This processing is generally 
                               known as multilook processing. As a result the multilooked image improves the image interpretability. Additionally, multilook 
                               processing can be used to produce an application product with nominal image pixel size."),
                            p("This operator implements the space-domain multilook method by averaging a single look image with a small sliding window. Rane and Azimuth Looks 
                               are set to 3 in order to derive a 30 m resolution product."),
                            hr(),
                            tags$b("9. Geocoding/Range Doppler Terrain Correction"),
                            p("Due to topographical variations of a scene and the tilt of the satellite sensor, distances can be distorted in the SAR images. 
                               Image data not directly at the sensor’s Nadir location will have some distortion. 
                               Terrain corrections are intended to compensate for these distortions so that the geometric representation of the image will
                               be as close as possible to the real world."),
                            p("As part of this procedure, the image will be geocoded so that every pixel is attributed with a unique geolocation."),
                            hr(),
                            tags$b("10. Linear power to decibel-scale"),
                            p("The received power of the backscattering is usually measured in linear power. Depending on the surface, the measurement can vary across a wide range. 
                               In order to derive a more balanced output, logarithmic scaling in decibel (dB) is applied."),
                            hr(),
                            tags$b("11. VV/VH ratio (only applies to dual-polarised scenes)"),
                            p("Dual polarised images can e represented in RGB by adding a ratio channel of the VV and VH band. This ratio is also advantageous for time-series analysis, 
                               since it is less sensitive to environmental conditions."),
                            hr(),
                            tags$b("12. Output generation"),
                            p("The Standard GRD to RTC processor outputs the data in GeoTiff format. Single-polarised products are 1-band greyscale images and dual-polarised products
                               contain 3-bands (VV, VH, VV/VH) and can be visualised as RGB. This processor will automatically apply the Layover/Shadow mask, that is also retained as 
                               output file. For quick visualisation, an additional KMZ file with reduced resolution is created."),
                            p("The time-series preparation mode, instead, creates the data in the BEAM-DIMAP format. This format contains all the necessary acquisition metadata
                               that is necessary for later time-series production. A Layover/Shadow mask is created, but not applied (will be applied during time-series stack generation).
                               Therefore the data can be opened in the SNAP toolbox.")
                   ),
                   tabPanel("Demo",
                            br(),
                            tags$h4("Demo I: Processing of one single-polarised scene"),
                            p("Within this demo a single-polarised scene over the wider area of the city of Santa Cruz della Sierra, Bolivia will be processed with the 
                               Standard GRD to RTC processor. The accompanying slides contain a step-by-step guide and familiarise the user with basic concepts of SAR 
                               image processing and SAR image interpretation."),
                            tags$b("In preparation"),
                            hr(),
                            tags$h4("Demo II: Processing of one dual-polarised scene"),
                            p("Within this demo a dual-polarised scene over the wider area of the city of Santa Cruz della Sierra, Bolivia will be processed with the 
                               Standard GRD to RTC processor. The accompanying slides contain a step-by-step guide and familiarise the user with the RGB representation 
                               of dual-polarised SAR imagery and highlight the advantages of using dual-polarised data."),
                            tags$b("In preparation"),
                            hr(),
                            tags$h4("Demo III: Batch-processing of three dual-polarised scenes with the Standard GRD to RTC processor."),
                            p("This demo applies the batch processing of the Standard GRD to RTC processor. Three dual-polarised scenes
                               over the wider area of the city of Santa Cruz della Sierra, Bolivia will be processed. The accompanying slides 
                               contain a step-by-step guide and familiarise the user with the temporal behaviour of SAR backscatter."),
                            tags$b("In preparation"),
                            hr(),
                            tags$h4("Demo IV: Processing of three dual-polarised scenes for multi-temporal analysis."),
                            p("Within this demo three dual-polarised scenes over the wider area of the city of Santa Cruz della Sierra, Bolivia will be processed with the time-series 
                               preparation processor. The processing involves the generation of a time-series stack as well as timescan data. The accompanying slides 
                               contain a step-by-step guide and familiarise the user with the advantages of using multi-temporal SAR imagery."),
                            tags$b("In preparation")
                   ),
                   tabPanel("References",     
                            tags$b("Scientific Articles"),
                            p("Small, D. (2011): Flattening Gamma: Radiometric Terrain Correction for SAR imagery. in: 
                            IEEE Transaction on Geoscience and Remote Sensing, Vol. 48, No. 8, ")
                    )
                            
                   
            )
          )
            
        ) # close fluid row
) # close tabitem
            
            
          