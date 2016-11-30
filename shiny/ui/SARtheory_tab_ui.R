#-----------------------------------------------------------------------------
# SAR theory tab
tabItem(tabName = "SARtheory",
        "Theoretical Aspects of Radar Remote Sensing",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          
          #----------------------------------------------------------------------------------
          # Processing Panel ALOS K&C
          box(
            
            # Title                     
            title = "Processing Panel", status = "success", solidHeader= TRUE,
            tags$h4("ALOS mosaics preparation (JAXA's Kyoto & Carbon initiative)"),
            hr(),
            tags$b("1) Project directory"),br(),
            p("Note: Within this directory the processing chain will store all data (i.e. downloaded archives, processed mosaics and auxiliary information.)"),
            #div(style="display:inline-block",shinyDirButton('directory', 'Browse', 'Select a folder')),
            #div(style="display:inline-block",verbatimTextOutput("project_dir")),
            shinyDirButton('directory', 'Browse', 'Select a folder'),
            br(),
            br(),
            verbatimTextOutput("KC_project_dir"),
            hr(),
            tags$b("2) Area of Interest"),br(),
            p("Note: This parameter will define the spatial extent of the processing. 
              You can either choose the borders of a country or a shapefile that bounds your area of interest."),
            # AOI choice
            radioButtons("ALOS_AOI", "",
                         c("Country" = "country",
                           "Shapefile (on Server/local)" = "AOI_shape_local",
                           "Shapefile (upload)" = "AOI_shape_upload")),
            
            conditionalPanel(
              "input.ALOS_AOI == 'country'",
              selectInput(
                inputId = 'countryname', 
                label= '', 
                choices = dbGetQuery(
                  dbConnect(SQLite(),dbname=Sys.getenv("OST_DB")),
                  sprintf("SELECT name FROM %s WHERE iso3 <> -99 ORDER BY name ASC", "countries")), 
                selected=NULL)
            ),
            
            conditionalPanel(
              "input.ALOS_AOI == 'AOI_shape_local'",
              #div(style="display:inline-block",shinyFilesButton("shapefile","Choose file","Choose one or more files",FALSE)),
              #div(style="display:inline-block",textOutput("filepath"))
              shinyFilesButton("shapefile","Choose file","Choose one or more files",FALSE),
              br(),
              br(),
              verbatimTextOutput("KC_filepath")
            ),
            
            conditionalPanel(
              "input.ALOS_AOI == 'AOI_shape_upload'",
              fileInput('shapefile_path', label = '',accept = c(".shp"))
            ),
            
            hr(),
            
            selectInput("year","3) Year",c(
              "2007" = "2007",
              "2008" = "2008",
              "2009" = "2009",
              "2010" = "2010",
              "2015" = "2015")),                   
            hr(),
            radioButtons("ALOS_KC_speckle", "4) Additional speckle filtering",
                         c("Yes (recommended)" = "Yes",
                           "No" = "No")),
            
            hr(),
            
            tags$b("5) Provide your ALOS K&C username and password."),
            p("If you are not in possess of a user account you can create one ",
              a(href = "http://www.eorc.jaxa.jp/ALOS/en/palsar_fnf/registration.htm", "here",".")),
            
            textInput(inputId = "uname",
                      label = "Username", 
                      value = "Type in your username" 
            ),
            
            passwordInput(inputId = "piwo",
                          label = "Password",
                          value = "Type in your password"),
            hr(),
            #div(style="display:inline-block",actionButton("alos_kc_process", "Start processing")),
            #div(style="display:inline-block",actionButton("alos_kc_abort", "Abort processing")),
            actionButton("alos_kc_process", "Start processing"),
            br(),
            br(),
            "Command Line Syntax:",
            verbatimTextOutput("processALOS")
        ) # close box
) # close tabItem
)