#-----------------------------------------------------------------------------
# ALOS GRD 2 RTC Tab
tabItem(tabName = "alos_pro",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          
          #----------------------------------------------------------------------------------
          # Inventory Panel ALOS Inventory
          box(
            # Title                     
            title = "Processing Panel", status = "success", solidHeader= TRUE,
            tags$h4("ALOS GRD to RTC processor"),
            hr(),
            tags$b("Under construction"),br())
        )
)