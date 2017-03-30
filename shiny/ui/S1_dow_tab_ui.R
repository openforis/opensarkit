#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_dow",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          #----------------------------------------------------------------------------------
          # Processing Panel Sentinel-1
          box(
            # Title                     
            title = "Processing Panel", status = "success", solidHeader= TRUE,
            tags$h4("Sentinel-1 data download"),
            hr(),
            tags$b("Short description:"),
            p("This interface allows to download all scenes contained by the OST inventory shapefile 
               created during the Sentinel-1 data inventory. Note that during the download the scenes 
               will already be placed in a folder structure defined by satellite track and acquisition date. 
               Thus, no sortation prior to the bulk processing steps is necessary."),
            hr(),
            tags$b("Project directory"),
            p("A new folder named \"DATA\" will be created within your project directory, containing 
               all the acquisitions sorted by satellite track and acquisition date."),
            shinyDirButton('S1_dow_directory', 'Browse', 'Select a folder'),
            br(),
            br(),
            verbatimTextOutput("S1_dow_project_dir"),
            hr(),
            tags$b("OST S1 inventory file"),
            p("This file should point to an OST inventory file created under the data inventory tab. It can either be 
               an OST inventory shapefile located on the same computer, or uploaded with its associated file as a zip archive."),
            radioButtons("S1_DOWNFILE", "",
                         c("OST Inventory Shapefile (local)" = "S1_AOI_shape_local",
                           "OST Inventory Shapefile (upload zipped archive)" = "S1_AOI_zip_upload")),
            
            conditionalPanel(
              "input.S1_DOWNFILE == 'S1_AOI_shape_local'",
            
            br(),
            shinyFilesButton("S1_dow_shapefile","Choose file","Choose one or more files",FALSE),
            br(),
            br(),
            verbatimTextOutput("S1_dow_filepath")
            ),
            
            conditionalPanel(
              "input.S1_DOWNFILE == 'S1_AOI_zip_upload'",
              fileInput('S1_zipfile_path', label = 'Browse',accept = c(".zip"))
            ),
            hr(),
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
            withBusyIndicatorUI(
             actionButton("S1_download", "Start downloading")
            ),
            br(),
            textOutput("S1_down")
          ) # close box
        )
)