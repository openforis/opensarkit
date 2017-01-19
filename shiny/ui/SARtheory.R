tabItem(tabName = "SARtheory",

        fluidRow(
           box(
            title = "Theoretical Aspects of SAR remote sensing", status = "success", solidHeader= TRUE,
            
            tabBox(width=1400,
                   tabPanel("SAR system",
                       br(),
                       tags$h4(""),
                       p("A ", tags$b("Synthetic Aperture Radar"), " (SAR) system is an", tags$b("active"), "imaging radar mounted on a flying platform such as 
                          an aeroplane or a satellite. It consists of a set of aligned real antennas that", tags$b("transmit electromagnetic
                          pulses"), " and", tags$b("receive the backscattered energy"), "from the illuminated area, similar to a flash camera. 
                          As shown in Figure, a typical imaging radar consists of a transmitter, switch, antenna, receiver and 
                          data recorder. Such systems are also known as", tags$b(" monostatic"), "radars, since transmitter and receiver share 
                          the same antenna. If those two elements are separated, the radar is denoted as", tags$b(" bistatic"),". 
                          The transmission of the pulses is synchronized to the speed of the platform and is known as the", 
                          tags$b(" pulse repetition frequency"), ". This assures the continuous coverage in the flight direction."),
                          img(src = "SARtheory/monostatic_rar.png", width = "100%", height = "100%"),
                          tags$b(" Figure 1: Block diagram of a typical radar system (adapted from: Chan & Koo 2008)"),
                          br(),
                          br(),
                          p("The electromagnetic waves are", tags$b("polarized"), "which means that they are either send out in a horizontal 
                             (H) or vertical (V) direction. For", tags$b("single-polarized systems"), "the polarization of the received wave 
                             corresponds to the one during transmission. Instead, ", tags$b("full-polarimetric systems"), "send out and receive
                             pulses in horizontal and vertical directions. Consequently, four imaging bands are recorded. 
                             The", tags$b("co-polarized channels"),"represent the bands of corresponding outgoing and incoming wave 
                             polarization, i.e. HH and VV. The", tags$b("cross-polarized bands"), "contain the information on the opposing 
                             state between transmission and reception (VH, HV).", tags$b("Dual-polarized systems"), "contain two of the
                             possible combinations, whereas at least one channel is co-polarized. Based on the", tags$b("reciprocity theorem"),
                             ", the cross-polarised channels contain the same information  (Lee & Pottier, 2009).
                          ")
                      ),
              
                   tabPanel("Terminology",
                            br(),
                            tags$h4("")
                   ),
                   tabPanel("SAR principle",
                            br(),
                            tags$h4("Introduction"),
                            p("Synthetic Aperture Radar is not an instrument, but rather refers to a signal processing technique
                               that allows for high resolution imaging from distance by using microwave radiation. For a 
                               basic understanding",a(href = "https://www.youtube.com/watch?v=g-YICKbcC-A", target = "_blank", "click here"),".")
                   )
            )
          ),
          
          box(
            title = "Resolution in Range", status = "success", solidHeader= TRUE,
            
            tabBox(
                   tabPanel("History",
                            br(),
                            tags$h4("")
                   )
            )
          )
        )
        
) # close tabItem