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
            tags$b("1) Output directory"),
            p("Note: A new folder named \"DATA\" will be created within the chosen Output directory. 
               Within this folder the downloaded data files will be stored and further sorted by satellite track and acquistion date."),
            #div(style="display:inline-block",shinyDirButton('directory', 'Browse', 'Select a folder')),
            #div(style="display:inline-block",verbatimTextOutput("project_dir")),
            shinyDirButton('S1_dow_directory', 'Browse', 'Select a folder'),
            br(),
            br(),
            verbatimTextOutput("S1_dow_project_dir"),
            hr(),
            tags$b("2) OST S1 inventory file"),
            p("Note: This browse should point to an OST inventory file created under the data inventory tab."),
            br(),
            shinyFilesButton("S1_dow_shapefile","Choose file","Choose one or more files",FALSE),
            br(),
            br(),
            verbatimTextOutput("S1_dow_filepath"),
            hr(),
            tags$b("3) Provide your NASA Earthdata username/password."), 
            p("If you are not in possess of a user account you can create one ",a(href = "https://urs.earthdata.nasa.gov/", "here"),"."),
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
            # div(style="display:inline-block",actionButton("s1_kc_process", "Start processing")),
            # div(style="display:inline-block",actionButton("s1_kc_abort", "Abort processing")),
            actionButton("S1_download", "Start downloading"),
            br(),
            # "Command Line Syntax:",
            textOutput("S1_down")
          ) # close box
        )
)