#-----------------------------------------------------------------------------
# S1 Mosaic Tab
tabItem(tabName = "s1_ts2mos",
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
            tags$h4("Sentinel-1 mosaicking of time-series & timescan swaths"),
            hr(),
            tags$b("Short description"),
            p("If your Area of interest is covered by more than one track, this routine will automatically mosaic the time-series and/or timescan products created in the earlier processing step."),
            hr(),
            tags$b("Processing directory:"),
            p("The path should point to the", tags$b(" DATA directory "), 
              "created by routine of the data download submenu, within your project folder, i.e. \"/path/to/project/DATA\""),
            shinyDirButton("s1_ts2mos_inputdir","Browse","Browse",FALSE),
            br(),
            br(),
            verbatimTextOutput("s1_ts2mos_inputdir"),
            # hr(),
            # tags$b("Mosaicking type"),
            # p(""),
            # radioButtons("s1_ts2mos_type", "",
            #              c("Full scene statistic (recommended)" = "1",
            #                "Overlap statistics" = "2")),
            hr(),
            withBusyIndicatorUI(
              actionButton("s1_ts2mos_process", "Processing")
            ),
            br(),
            br(),
            #"Output:",
            textOutput("processS1_ts2mos")
          ) #close box
        )
)