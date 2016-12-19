#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_grd2rtc",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
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
            actionButton("s1_g2r_process", "Start processing"),
            br(),
            br(),
            "Output:",
            verbatimTextOutput("processS1_G2R")
            ) #close box
        ) # close fluid row
) # close tabitem
            
            
          