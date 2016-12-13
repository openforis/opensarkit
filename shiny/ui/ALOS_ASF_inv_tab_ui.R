#-----------------------------------------------------------------------------
# ALOS K&C Tab
tabItem(tabName = "alos_inv",
        fluidRow(
          # Include the line below in ui.R so you can send messages
          tags$head(tags$script(HTML('Shiny.addCustomMessageHandler("jsCode",function(message) {eval(message.value);});'))),
          
          #----------------------------------------------------------------------------------
          # Inventory Panel ALOS Inventory
          box(
            # Title                     
            title = "Processing Panel", status = "success", solidHeader= TRUE,
            tags$h4("ALOS data inventory (ASF server)"),
            hr(),
            tags$b("Under construction"),br())
        )
)