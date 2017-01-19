tabItem(tabName = "SARhistory",
        
        fluidRow(
          box(
            title = "From the discovery of radio waves to Synthetic Aperture Radar - A brief historical sketch", status = "success", solidHeader= TRUE,
            
            tabBox(width=1400,
                   tabPanel("The beginning",
                            br(),
                            tags$h4("The discovery of radio waves"),
                            p("James Clerk Maxwell first predicted the existence of radio waves in 1867 and formulated the
                              general behaviour of electromagnetic waves within the mathematical framework of Maxwell’s
                              equations. It was 20 years later when Heinrich Hertz experimentally demonstrated the reality
                              of radio waves and in the 1890’s Guglielmo Marconi built the first practical radio transmitters
                              and receivers for communication purposes."),
                            img(src = "SARtheory/radiowaves.png", width = "100%", height = "100%"),
                            tags$b("Figure 1: The spectrum of electromagnetic waves and the indicative transmittance 
                                   of the atmosphere from space to earth (adapted from: Richards 2009)"),
                            br(),
                            br(),
                            p("In 1904 Christian Hülsmeyer discovered the ability to detect remote metallic objects even
                              in the presence of fog by using long-wave electromagnetic radiation. His so-called Telemobiloskop
                              is seen as the precursor of modern radar systems. The principle consisted of transmitting 
                              continuous energy and recording the backscattered echoes by using a simple dipole antenna. 
                              In the course of the following years, different scientists around the globe conducted similar
                              research related to object detection. In 1935, Sir Robert Alexander Watson-Watt took the principle 
                              one step further by developing the first pulsed radar. Instead of continuously transmitting 
                              electromagnetic energy, his aperture transmitted short pulses. As a result, the distance between
                              the sensor and an object reflecting the electromagnetic pulse could be determined by precisely
                              measuring the runtime that elapses between transmission and reception of the backscattered wave."
                            )
                    ),
                    tabPanel("WW II",
                            tags$h4("Advances during World War II "),
                            p("As it was the case for many technological advances of that time, radar experienced its
                              breakthrough due to the military armament during the Second World War. One of the major
                              advancements was the use of shorter wavelengths in the microwave portion of the 
                              electromagnetic spectrum. This provided a number of advantages including finer resolution, a tighter
                              beam, and greater immunity to noise from other long-wave radiation sources. One relict of
                              this time is the nomenclature of the different wavelength bands represented by specific code
                              letters shown in Table 1. While at the beginning resolution was not a major restriction, new
                              application domains evolving in the 1950s had to fulfil higher user requirements. One of them
                              was the utilization of radar for military reconnaissance purposes which led to the consequent
                              development of imaging radars. The use of microwaves offered the possibility to observe an
                              area independent of weather and daylight conditions due to the physical properties of the
                              microwaves and the active character of the system."),
                            img(src = "SARtheory/radarbands.png", width = "100%", height = "100%"),
                            tags$b("Table 1: Nomenclature of selected frequency bands, and the corresponding frequency and 
                                    wavelength ranges (adapted from: Moreira et al. 2013)")
                            )
            )
          )
        )
)
          