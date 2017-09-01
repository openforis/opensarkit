tabItem(tabName = "SARimage",
        fluidRow(
          box(
            # Title                     
            title = "SAR image interpretation", status = "success", solidHeader= TRUE,
            tabBox(width = 1400,
                   
                   tabPanel("ALOS L-Band data",
                            tags$h4("Note"),
                            p("This material is taken from the", a(href = "http://www.gfoi.org/wp-content/uploads/2016/10/PALSAR-Interpretation-Guide-v1.1.pdf", target = "_blank", 
                              "Interpretation Guide for ALOS / ALOS-2 PALSAR global 25m mosaic data"),"(Rosenqvist 2016)."),
                            p("Below follow examples of how some typical land cover types found in the Kenyan
                               landscape appear in L-band SAR data, or more specifically, in ALOS PALSAR/ALOS-2
                               PALSAR-2 mosaic data at HH and HV polarisations."),
                            p("The backscatter values shown below the images have however been measured in the 
                               original (16 bits) images – averaged over >1000 pixels to reduce the influence of 
                               speckle – and should hus indicate “true” estimates of the backscatter. The backscatter 
                               standard deviation is given in brackets when applicable."),
                            p("Also an RGB colour composite image is shown for reference, although it is important to 
                               keep in mind that there are neither any standardised rules on how represent microwave 
                               data visually, nor how to compose a 3-channel colour image from only two input channels.
                               Yet, the [HH, HV, HH/HV] combination used here for [R, G, B] is frequently utilised by 
                               remote sensing users."),
                            hr(),
                            tags$h4("Examples from Kenya"),
                            img(src = "ALOS_KC/Forest.png", width = "100%", height = "100%"),
                            tags$b("Figure: HH: -7.7 (1.0) dB; HV: -12.4 (0.9) dB"),
                            p("Dense homogeneous forest (Mount Kenya National Park) results in high and uniform backscatter 
                               at both polarisations. HV backscatter is closely correlated with forest structure and above-ground 
                               biomass, with HV reaching higher σ^0 values than for any other land cover. The darker patch in the 
                               upper right corner indicates a deforested area."),
                            hr(),
                            img(src = "ALOS_KC/SparseForest.png", width = "100%", height = "100%"),
                            tags$b("Figure: HH: -10.5 (N/A) dB; HV: -17.0 (N/A) dB"),
                            p("The high-altitude forest on Mount Kenya shown above, displays medium-high HH and HV backscatter. 
                               The drop in backscatter for this lower/sparser forest type, compared to that for the denser lower
                               altitude forest in the previous example, is directly related to parameters such as tree height, structure 
                               and stem density, and illustrates the strong relationship between L-band backscatter 
                               and forest above-ground biomass."),
                            hr(),
                            img(src = "ALOS_KC/Agriculture.png", width = "100%", height = "100%"),
                            tags$b("Figure: HH: -8.2 (1.9) dB; HV: -17.5 (2.1) dB"),
                            p("Mixed agriculture area (Kirinyaga county). The low vegetation typical for agricultural crops is 
                               largely transparent at the L-band wavelength, signified by low HV backscatter. The higher backscatter 
                               observed in the HH channel is not caused by the crop vegetation, but by direct scattering on ploughed 
                               fields and rough open soil."),
                            p("Agricultural areas typically have a purple appearance in the RGB composite. The agricultural landscape 
                               can also be identified by geometrical patterns and textural features in the image, such as fields, 
                               roads and waterways. Small patches of trees appear green due to higher HV backscatter."),
                            hr(),
                            img(src = "ALOS_KC/Rice.png", width = "100%", height = "100%"),
                            tags$b("Figure: HH: -9.6 (N/A) dB; HV: -21.1 (N/A) dB"),
                            p("Irrigated rice is the only agricultural crop which is clearly visible in L-band SAR data. 
                               Reflections between the vertical rice plants and the water surface of the flooded fields 
                               can result in a strong HH backscatter, which increases throughout the vegetation season 
                               from planting to harvest. While it needs to be confirmed, it is likely that the bright 
                               areas in visible in the image above over Wanguru, Kirinyaga county, are rice paddies."),
                            hr(),
                            img(src = "ALOS_KC/Bare.png", width = "100%", height = "100%"),
                            tags$b("Figure: HH: -27.7 (5.3) dB; HV: -35.8 (3.0) dB"),
                            p("North Horr, Marsabit county. Arid landscapes with vast expanses of sand or grass result 
                               in extremely low HH backscatter, as the smooth surfaces in these type of dry savannah 
                               environments produce no return. The HV backscatter is also extremely low, and close to 
                               the noise floor of the radar. The slightly brighter patches visible in the HV image are 
                               caused by low riparian vegetation along the river channels, and by scattered bushes and scrubs."),
                            hr(),
                            img(src = "ALOS_KC/Rocky.png", width = "100%", height = "100%"),
                            tags$b("Figure: HH: -8.9 (1.1) dB; HV: -21.7 (1.6) dB"),
                            p("Kenya-Ethiopia border, Marsabit county. Arid landscape with rock outcrops and exposed bedrock. 
                               In contrast to the smooth surfaces in the previous example, a rocky terrain results in strong 
                               surface reflections and high HH backscatter. Whether the moderate HV returns are caused by the 
                               uneven rock surfaces and/or low vegetation needs to be confirmed."),
                            hr(),
                            img(src = "ALOS_KC/Water.png", width = "100%", height = "100%"),
                            tags$b("Figure: HH: -18.7 (1.1) dB; HV: -35.8 (1.3) dB"),
                            p("Open water surfaces appear pitch black in HV imagery and result in backscatter levels close to 
                               the sensor noise floor. In the HH channel, a smooth water surface similarly results in no scattering 
                               back to the sensor. Waves on the water however, which may be present on Lake Turkana in the image
                               above, can result in a slight HH backscatter increase. Water appears (appropriately) blue in the RGB composite.")
                   ),
                   
                   tabPanel("Sentinel-1 DualPol C-band data",
                            tags$b("Under construction")
                   )
            )
        )
        ) # close box
) # close tabItem