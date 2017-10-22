#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "ms_biomass",
        fluidRow( # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          
          # for busy indicator 
          useShinyjs(),
          tags$style(appCSS),
          
          #----------------------------------------------------------------------------------
          # Processing Panel Sentinel-1
          box(
            
            # Title                     
            title = "Processing Panel", status = "success", solidHeader= TRUE,
            tags$h4("Biomass mapping"),
            hr(),
            tags$b("Short description"),
            p("This module will create a biomass map based on a Multi-Sensor Stack created by OST and a shapefile containing the biomass values of a field inventory."),
            hr(),
            
            #------------------------------------------------------------------------------
            tags$b("Multi-Sensor Stack"),
            p("This path should point to a multi-sensor stack created by OST"),
            shinyDirButton("bm_ms_dir","Browse","Browse",FALSE),br(),br(),
            verbatimTextOutput("bm_ms_dir"),hr(),
            #------------------------------------------------------------------------------
            
            #------------------------------------------------------------------------------
            tags$b("Field Inventory Shapefile"),
            p("This path should point to the shapefile containing the biomass values (Note: for themoment only polygon shapefiles are accepted)"),
            shinyFilesButton("bm_fi_file","Browse","Browse",FALSE),br(),br(),
            verbatimTextOutput("bm_fi_file"),hr(),
            #------------------------------------------------------------------------------
            
            #------------------------------------------------------------------------------
            tags$b("Biomass column of the Field Inventory Shapefile"),
            p("This text field expects the column name of the biomass value within the attribute table of the Field Inventory Shapefile"),
            textInput("bm_fi_field", label ="", value = "Enter the column name ..."),hr(),
            #------------------------------------------------------------------------------
            
            #------------------------------------------------------------------------------
            tags$b("Output directory:"),
            p("Select a folder where the output data files will be written to:"),
            shinyDirButton("bm_outdir","Browse","Browse",FALSE),br(),br(),
            verbatimTextOutput("bm_outdir"),hr(),
            #------------------------------------------------------------------------------
            
            #-----------------------------------------------------------------------------------------------------------------------------------
            # Trigger / Abort
            div(style="display: inline-block;vertical-align:top; width: 135px;",withBusyIndicatorUI(
              actionButton("bm_pro_btn", "Start processing"))),
            div(style="display: inline-block;vertical-align:top; width: 125px;", withBusyIndicatorUI(
              actionButton("bm_abort_btn", "Abort processing")
            )),
            #"Output:",
            textOutput("processMS_biomass")
            
            ), # close box
          #-----------------------------------------------------------------------------------------------------------------------------------
          #   #----------------------------------------------------------------------------------
          #   # Info Panel
          box(
            title = "Info Panel", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   tabPanel("Progress Monitor",
                            tags$h4("Monitor the progress of a running process"),hr(),
                            verbatimTextOutput("bm_progress"))
            )
          ) # close box
      ) # close fluid row
) # close tabit
