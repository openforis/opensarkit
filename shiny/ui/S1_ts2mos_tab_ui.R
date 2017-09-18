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
            shinyDirButton("s1_ts2m_inputdir","Browse","Browse",FALSE),
            br(),
            br(),
            verbatimTextOutput("s1_ts2m_inputdir"),hr(),
            #---------------------------------------------------------------------------
            # Layover/shadow mask selction
            tags$b("Apply the Layover/Shadow mask?"), 
            p("This option provides the possibility to set the Layover/Shadow affected areas to 0 (no data value)."),
            radioButtons("s1_ts2mos_ls", "",
                         c("Yes" = "1",
                           "No" = "0"),
                         "0"),hr(),
            #---------------------------------------------------------------------------
            
            # hr(),
            # tags$b("Mosaicking type"),
            # p(""),
            # radioButtons("s1_ts2mos_type", "",
            #              c("Full scene statistic (recommended)" = "1",
            #                "Overlap statistics" = "2")),

            
            #-----------------------------------------------------------------------------------------------------------------------------------
            # Trigger / Abort
            div(style="display: inline-block;vertical-align:top; width: 135px;", withBusyIndicatorUI(
              actionButton("s1_ts2m_pro_btn", "Start mosaicking")
            )),
            div(style="display: inline-block;vertical-align:top; width: 150px;", withBusyIndicatorUI(
              actionButton("s1_ts2m_abort_btn", "Abort mosaicking")
            )),
            textOutput("s1_ts2m")
            #-----------------------------------------------------------------------------------------------------------------------------------
            
          ), #close box
          
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
          box(
            title = "Info Panel", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   tabPanel("Progress Monitor",
                            tags$h4("Monitor the progress of a running process"),hr(),
                            verbatimTextOutput("s1_ts2m_progress")
                   ),
                   tabPanel("General Info",
                            tags$h4("Under construction"),hr()
                   ),
                   tabPanel("References",
                            tags$h4("References"),hr(),
                            tags$b("Scientific Articles"),
                            p("Cresson R. & Saint-Geours N. (2015): Natural Color Satellite Image Mosaicking Using Quadratic Programming in Decorrelated Color Space. in: IEEE JSTARS, vol. 8, issue 8.",
                              a(href = "http://hal.cirad.fr/hal-01373314/document", target = "_blank", "Link"),".")
                   )
            )
          )
        )
)
