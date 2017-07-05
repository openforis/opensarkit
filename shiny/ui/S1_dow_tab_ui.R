#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_dow",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          #----------------------------------------------------------------------------------
          # Processing Panel Sentinel-1
          box(
            
            #-----------------------------------------------------------------------------------------------------------------------------------
            # Title                     
            title = "Processing Panel", status = "success", solidHeader= TRUE,
            tags$h4("Sentinel-1 data download"),hr(),
            tags$b("Short description:"),
            p("This interface allows to download all scenes contained by the OST inventory shapefile 
               created during the Sentinel-1 data inventory. Note that during the download the scenes 
               will already be placed in a folder structure defined by satellite track and acquisition date. 
               Thus, no sortation prior to the bulk processing steps is necessary."),hr(),
            #-----------------------------------------------------------------------------------------------------------------------------------
            
            
            #-----------------------------------------------------------------------------------------------------------------------------------
            # Project Directory
            tags$b("Project directory"),
            p("A new folder named \"DATA\" will be created within your project directory, containing 
               all the acquisitions sorted by satellite track and acquisition date."),
            shinyDirButton('s1_dow_directory', 'Browse', 'Select a folder'),br(),br(),
            verbatimTextOutput("s1_dow_project_dir"),hr(),
            #-----------------------------------------------------------------------------------------------------------------------------------
            
            
            #-----------------------------------------------------------------------------------------------------------------------------------
            # OST inventory shapefile selection
            tags$b("OST S1 inventory file"),
            p("This file should point to an OST inventory file created under the data inventory tab. It can either be 
               an OST inventory shapefile located on the same computer, or uploaded with its associated file as a zip archive."),
            
            # selction for local shapefile or zip archive for upload 
            radioButtons("s1_dow_file_options", "",
                         c("OST Inventory Shapefile (local)" = "s1_dow_shape",
                           "OST Inventory Shapefile (upload zipped archive)" = "s1_dow_zip")),
            
            # if local shapefile is selected
            conditionalPanel(
              "input.s1_dow_file_options == 's1_dow_shape'",br(),
            shinyFilesButton("s1_dow_shapefile","Choose file","Choose one or more files",FALSE),br(),br(),
            verbatimTextOutput("s1_dow_shape_path")
            ),
            
            # if zip archive for upload is selected
            conditionalPanel(
              "input.s1_dow_file_options == 's1_dow_zip'",
              fileInput('s1_dow_zipfile', label = 'Browse',accept = c(".zip"))
            ),hr(),
            #-----------------------------------------------------------------------------------------------------------------------------------
            
            
            #-----------------------------------------------------------------------------------------------------------------------------------
            # Username/Password
            tags$b("Provide your NASA Earthdata username/password."), 
            p("If you are not in possess of a NASA Earthdata user account you can create one ",a(href = "https://urs.earthdata.nasa.gov/",target="_blank", "here"),"."),
            br(),
            textInput(inputId = "s1_asf_uname",
                label = "Username", 
                value = "Type in your username" 
            ),

            passwordInput(inputId = "s1_asf_piwo",
                label = "Password",
                value = "Type in your password"
            ),
            hr(),
            #-----------------------------------------------------------------------------------------------------------------------------------
            
            
            #-----------------------------------------------------------------------------------------------------------------------------------
            # Trigger / Abort
            div(style="display: inline-block;vertical-align:top; width: 150px;", withBusyIndicatorUI(
                     actionButton("s1_dow_pro_btn", "Start downloading")
            )),
            div(style="display: inline-block;vertical-align:top; width: 150px;", withBusyIndicatorUI(
                     actionButton("s1_dow_abort_btn", "Abort downloading")
            )),
            #-----------------------------------------------------------------------------------------------------------------------------------
            
            # Output from commands
            textOutput("s1_dow")
            
          ), # close box
          
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
          box(
            title = "Info Panel", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   
                   tabPanel("Progress Monitor",
                            tags$h4("Monitor the progress of active downloads"),hr(),
                            #actionButton("s1_dow_log_btn", "Start"),hr(),
                            verbatimTextOutput("s1_dow_progress")
                   )
            )
                
          )
    )
)