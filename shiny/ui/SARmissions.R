tabItem(tabName = "SARmissions",
        fluidRow(
          box(
            title = "Theoretical Aspects of SAR remote sensing", status = "success", solidHeader= TRUE,
            
            tabBox(width=1400,
                   tabPanel("Sentinel-1",
                            tags$h4("The Sentinel-1 mission"),
                            tags$i("Note that the content is adapted from"), 
                            a(href = "https://sentinel.esa.int/web/sentinel/missions/sentinel-1", "ESA's Sentinel-1 webpage."),
                            hr(),
                            p("The SENTINEL-1 mission is the European Radar Observatory for the Copernicus joint initiative 
                               of the European Commission (EC) and the European Space Agency (ESA). Copernicus, previously 
                               known as GMES, is a European initiative for the implementation of information services dealing
                               with environment and security. It is based on observation data received from Earth Observation 
                               satellites and ground-based information."),
                            p("The SENTINEL-1 mission includes C-band imaging operating in four exclusive imaging modes with 
                               different resolution (down to 5 m) and coverage (up to 400 km). It provides dual polarisation 
                               capability, very short revisit times and rapid product delivery. For each observation, 
                               precise measurements of spacecraft position and attitude are available."),
                            p("Synthetic Aperture Radar (SAR) has the advantage of operating at wavelengths not impeded 
                               by cloud cover or a lack of illumination and can acquire data over a site during day or night 
                               time under all weather conditions. SENTINEL-1, with its C-SAR instrument, can offer reliable, 
                               repeated wide area monitoring."),
                            p("The mission is composed of a constellation of two satellites, SENTINEL-1A and SENTINEL-1B, 
                               sharing the same orbital plane."),
                            p("SENTINEL-1 is designed to work in a pre-programmed, conflict-free operation mode, imaging all 
                               global landmasses, coastal zones and shipping routes at high resolution and covering the global
                               ocean with vignettes. This ensures the reliability of service required by operational services 
                               and a consistent long term data archive built for applications based on long time series."),
                            tags$b("Instrument"),
                            img(src = "Sentinel-1.jpg", width = "100%", height = "100%"),
                            tags$b("Figure 1: Artisitic representation of Sentinel-1 in orbit. (image courtesy:ESA)")
                   ),
         
                   tabPanel("ALOS-1 PALSAR",
                            tags$h4("The ALOS-1 mission")

                  ),
            

                   tabPanel("ALOS-2 PALSAR",
                            tags$h4("The ALOS-2 mission")
                            
                   )
            )
        ) # close box
) # close tabItem
)