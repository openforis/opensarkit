#-----------------------------------------------------------------------------
# SRTM Tab
tabItem(tabName = "srtm_dow",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          
          # for busy indicator 
          useShinyjs(),
          tags$style(appCSS),
          #----------------------------------------------------------------------------------
          
          #----------------------------------------------------------------------------------
          # Download Panel SRTM
          box(
            # Title                     
            title = "SRTM Download and Preparation", status = "success", solidHeader= TRUE,
            tags$h4("SRTM download and preparation"),
            hr(),
            
            tags$b("Short description"),
            p("The Shuttle Radar Topography Mission (SRTM) dataset contains topographical information in the form of a Digital Surface Model (DSM). 
               With this interface it is possible to download the tiles corresponding to the selected AOI and prepare them for subsequent integration into a multi-sensor stack 
               for classification prposes. In addition, it is possible to create topographic indices such as slope and aspect."),
            hr(),
            tags$b("Output directory"),
            p("The final products will be stored in the hereby selected directory."),
            shinyDirButton('srtm_dow_directory', 'Browse', 'Select a folder'),
            br(),br(),
            verbatimTextOutput("srtm_dow_project_dir"),
            hr(),
            
            tags$b("Area of Interest"),br(),
            p("This parameter will define the spatial extent of the data inventory. You can either choose the borders 
                of a country or a shapefile that bounds your area of interest. If you are working from remote, 
                you can transfer a zipped archive containing a shapefile and its associated files 
                from your local machine to the server by selecting the third option."),
            radioButtons("srtm_dow_AOI", "",
                         c("Country" = "country",
                           "Shapefile (on Server/local)" = "SRTM_AOI_shape_local",
                           "Shapefile (upload zipped archive)" = "SRTM_AOI_zip_upload")),
            
            conditionalPanel(
              "input.srtm_dow_AOI == 'country'",
              selectInput(
                inputId = 'srtm_dow_countryname', 
                label= '', 
                choices = dbGetQuery(
                  dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                  sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                selected=NULL)
            ),
            
            conditionalPanel(
              "input.srtm_dow_AOI == 'SRTM_AOI_shape_local'",
              shinyFilesButton("srtm_dow_shapefile","Browse","Choose a shapefile",FALSE),
              br(),
              br(),
              verbatimTextOutput("srtm_dow_filepath")
            ),
            
            conditionalPanel(
              "input.srtm_dow_AOI == 'SRTM_AOI_zip_upload'",
              fileInput('srtm_dow_zipfile_path', label = 'Browse',accept = c(".zip"))
            ),
            hr(),
            
            #----------------------------------------------------------------------------------
            # Topographic Indices
            tags$b("Topographic indices"),
            p("Additional calculation of topographic indices"),
            radioButtons("srtm_dow_ind", "",
                         c("Slope, Aspect (recommended)" = "1",
                           "No" = "0")),hr(),
            #----------------------------------------------------------------------------------
            
            #----------------------------------------------------------------------------------
            # Datatype conversion
            tags$b("Data type conversion"),
            p("This allows to convert the data to less storage intense 16 bit format."),
            radioButtons("srtm_dow_type", "",
                         c("Yes (recommended)" = "1",
                           "No" = "0")),hr(),
            #----------------------------------------------------------------------------------
            
            #----------------------------------------------------------------------------------
            # action buttons
            div(style="display: inline-block;vertical-align:top; width: 135px;",withBusyIndicatorUI(
              actionButton("srtm_dow_pro_btn", "Start processing"))),
            div(style="display: inline-block;vertical-align:top; width: 125px;", withBusyIndicatorUI(
              actionButton("srtm_dow_abort_btn", "Abort processing")
            )),
            #"Output:",
            textOutput("process_SRTM")
            #----------------------------------------------------------------------------------
            
          ),
          #----------------------------------------------------------------------------------
          # Info Panel
          box(
            title = "Info Panel", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   
                   tabPanel("Progress Monitor",
                            tags$h4("Monitoring the progress of ongoing processing"),hr(),
                            verbatimTextOutput("srtm_dow_progress")
                   )
            )
          )# close box
          
        ) # close fluid row
) # close tabit
