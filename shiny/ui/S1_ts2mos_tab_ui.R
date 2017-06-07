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
            tags$b("DATA directory:"),
            br(),
            br(),
            shinyDirButton("s1_ts2mos_inputdir","Select S1 DATA folder in your project directory","Select S1 DATA folder in your project directory",FALSE),
            br(),
            br(),
            verbatimTextOutput("s1_ts2mos_inputfolder"),
            hr(),
            tags$b("Mosaicking type"),
            p("Note: Those values represent the amount of space reserved for one pixel per band. "),
            radioButtons("s1_ts2mos_type", "",
                         c("Full scene statistic" = "non-overlap",
                           "Overlap statistics" = "overlap")),
            hr(),
            withBusyIndicatorUI(
              actionButton("s1_ts2mos_process", "Start processing")
            ),
            br(),
            br(),
            #"Output:",
            textOutput("processS1_TS2MOS")
          ) #close box
        )
)