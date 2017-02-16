tabItem(tabName = "SARhistory",
        
        fluidRow(
          box(
            title = "From the discovery of radio waves to Synthetic Aperture Radar - A brief historical sketch", status = "success", solidHeader= TRUE,
            
            tabBox(width=1400,
                   tabPanel("The Beginning",
                            br(),
                            tags$h4("The discovery of radio waves"),
                            p("James Clerk Maxwell first predicted the existence of radio waves in 1867 and formulated the
                              general behaviour of electromagnetic waves within the mathematical framework of Maxwell’s
                              equations. It was 20 years later when Heinrich Hertz experimentally demonstrated the reality
                              of radio waves and in the 1890’s Guglielmo Marconi built the first practical radio transmitters
                              and receivers for communication purposes."),
                            img(src = "SARtheory/radiowaves.png", width = "100%", height = "100%"),
                            tags$b("Figure 1: The spectrum of electromagnetic waves and the indicative transmittance 
                                   of the atmosphere from space to earth (image courtesy: CNES)"),
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
                            ),
                            p("As it was the case for many technological advances of that time, radar experienced its
                              breakthrough due to the military armament during the Second World War. One of the major
                              advancements was the use of shorter wavelengths in the microwave portion of the 
                              electromagnetic spectrum. This provided a number of advantages including finer resolution, a tighter
                              beam, and greater immunity to noise from other long-wave radiation sources. One relict of
                              this time is the nomenclature of the different wavelength bands represented by specific code
                              letters shown in Table 1."),
                            img(src = "SARtheory/radarbands.png", width = "100%", height = "100%"),
                            tags$b("Table 1: Nomenclature of selected frequency bands, and the corresponding frequency and 
                                    wavelength ranges (adapted from: Moreira et al. 2013)")
                            ),
                   tabPanel("SAR invention",
                            tags$h4("The invention of SAR "),
                            p("While at the beginning resolution was not a major restriction for radar systems, new
                              application domains evolving in the 1950s had to fulfil higher user requirements. One of them
                              was the utilization of radar for military reconnaissance purposes which led to the consequent
                              development of imaging radars. The use of microwaves offered the possibility to observe an
                              area independent of weather and daylight conditions due to the physical properties of the
                              microwaves and the active character of the system. Until today this is seen as one of the major
                              advantages of the technology. For this purpose, pulsed radars were mounted in a side-looking
                              direction on an aeroplane and the reflected energy was transformed into an image. Such systems
                              were referred to as Side-looking Airborne Radar (SLAR) and operated similarly to conventional
                              radars, which later led to the denotation of Real Aperture Radar (RAR). One drawback
                              of RAR systems is the low resolution in the direction of flight limited by the antenna dimensions
                              and the distance between sensor and object. In order to overcome
                              those limitations, Carl Wiley proposed the use of a coherently operating radar in combination
                              with the Doppler beam sharpening principle in 1951. The coherent summation
                              of the antenna echoes allowed to considerably improve the resolution in the flight direction
                              independent of the range distance. This concept paved the way for modern SAR systems and
                              offered the possibility to obtain high-resolution imagery from space.")
                   ),
                   tabPanel("SAR from space",
                            tags$h4("The use of SAR from space "),
                            p("Though the principle of SAR could be theoretically described, the computational complexity 
                               hindered its technological realization. The first military airborne systems were successfully
                               used at the end of the 1950s, but it was only in 1978 when SEASAT, the first civilian SAR satellite,
                               was launched into orbit. However, the mission lasted only 106 days and it took another
                               13 years until the Earth Remote-Sensing Satellite (ERS) initiated the era of SAR remote sensing 
                               by continuously delivering SAR imagery from space. While ERS was initially
                               developed for maritime monitoring, its potential for other application fields could be demonstrated
                               quickly. One of the most striking achievements was a continuous displacement map
                               of the Landers earthquake in 1992 by applying the Differential SAR Interferometry (DInSAR)
                               technique (Massonnet et al., 1993). In the following years the satellites Japanese Earth Re-
                               sources Satellite-1 (JERS-1) and Radarsat-1 were successfully launched into orbit. JERS-1 was
                               the first operational SAR satellite with a predefined observation strategy that allowed for seasonal
                               coverage over large regions and highlighted the usefulness of L-band systems for large-scale natural
                               resource monitoring (Rosenqvist et al., 2000). In 1994, the first multi-frequency and multi-
                               polarisation SAR system was carried in the cargo bay of a space shuttle (SIR-C/X-SAR). While
                               this experimental mission was flown only over two short periods in April and October 1994,
                               it provided a wealth of data from which user requirements for future missions were deduced
                               (Schmullius & Evans, 1997).")
                   ),
                   tabPanel("The 2000's",
                            tags$h4("Operationalisation of SAR systems"),
                            p("The first spaceborne SAR purely dedicated to SAR interferometry (InSAR) was realised in
                               February 2000. The Shuttle Radar Topography Mission (SRTM) was a so-called bistatic SAR
                               system containing two antennas at X- and C-band that were mounted in the cargo bay and on a
                               60 m antenna arm of a space shuttle, respectively. The acquired interferometric data was later
                               processed to derive the most-complete and highest resolution Digital Elevation Model (DEM)
                               at that time (Farr et al., 2007)."),
                            p("Technological advancements of subsequent systems in the 2000’s were mainly characterized 
                               by the realisation of advanced acquisition concepts. The Advanced Synthetic Aperture
                               Radar (ASAR) instrument mounted on the Environmental Satellite (ENVISAT) was able to
                               acquire data in different polarization modes. In addition, electronic beam-steering of the
                               transmit/receive modules of the SAR antenna was introduced and allowed for the selection
                               of different imaging modes. Beside the standard image mode that assured data continuity
                               from the ERS satellites, a ScanSAR mode could acquire data with a maximum swath width of
                               400km, however, to the cost of resolution. The Phased-Array L-band SAR (PALSAR) on-board
                               the Advanced Land Observing Satellite (ALOS) launched in 2006 was the first instrument on a
                               satellite capable of acquiring full-polarimetric data in L-band. Polarimetric data contain additional
                               information of the structure of an imaged object which allows for better discrimination
                               between land cover classes."),
                            p("Shortly after, TerraSAR-X, Radarsat-2 and the COSMO-SkyMed satellite constellation followed. 
                               For the first time, those satellites achieved resolutions in the metre regime using the
                               StripMap acquisition principle, which is also based on electronic beam-steering. The launch of
                               TanDEM-X in 2010 further expanded the possibilities of imaging radars. The platform orbits
                               the earth together with its twin satellite TerraSAR-X in a helix-shaped flight formation. The
                               resultant bistatic SAR configuration was mainly established for the generation of a new very
                               high-resolution DEM. On top of that, the applicability of advanced methods such as Along-
                               track SAR Interferometry (AT-InSAR) or Polarimertic SAR Interferometry (PolInSAR) could be
                               experimentally demonstrated from spaceborne sensors (Ouchi, 2013)."),
                            p("While the capability to acquire imagery from different acquisition modes is interesting from
                               a technological point of view, most of the SAR users depend on consistent, repetitive measurements
                               that allow for robust time-series analysis (Ferretti et al., 2015). The mission concept
                               of the Sentinel-1 satellite constellation reflects this requirement by providing a systematic
                               data flow of standard mode imagery over land, ocean and ice covered regions (Torres et al.,
                               2012). One novelty is the Terrain Observation with Progressive Scan (TOPS) acquisition mode
                               that features both a 250 km wide swath as well as a high spatial resolution of 5 by 20 m. Due to
                               the use of the two satellite constellation operating in a 180 degree shifted orbit, the nominal
                               revisit time could be reduced to 6 days.")
                   ),
                   tabPanel("Future of SAR",
                            tags$h4("Future developments of SAR systems"),
                            p("Near future SAR missions continue to operate as constellations, since they have the advan-
                               tage of providing high-resolution imagery with a likewise high revisit frequency. Continuing
                               efforts by various space agencies will insure data continuity in the different frequency do-
                               mains by simultaneously providing an increase in available data. However, the future vision
                               of SAR engineers goes well beyond the current technological status. Digital beamforming will 
                               become a key technology for future systems and boost out the performance of current SAR
                               sensors by at least one order of magnitude. Other technological advances such as large reflector
                               antennas will allow for ultra-wide swath imaging by simultaneously providing very high
                               resolution in the metre regime (Krieger et al., 2012). As a result, a continuous spatio-temporal
                               coverage of the whole globe will become feasible. At the same time, bi- and multistatic SAR
                               configurations will enable the use of next generation image processing techniques that allow
                               to even more precisely determine geo- and biophysical parameters of the earth’s surface.")
                            ),
                   tabPanel("References",
                            tags$h4("References"),
                            p("Farr, T. et al. (2007): The Shuttle Radar Topography Mission.
                               In: Reviews of Geophysics, 45, 1–33.",
                               a(href = "http://www3.jpl.nasa.gov/srtm/SRTM_paper.pdf", target = "_blank", "Link"),"."),
                            p("Ferretti, A. et al. (2015): InSAR data for monitoring land
                               subsidence: time to think big. In: Prevention and mitigation of natural and anthropological
                               hazards due to land subsidence.",
                              a(href = "http://www.proc-iahs.net/372/331/2015/piahs-372-331-2015.pdf", target = "_blank", "Link"),"."),
                            p("Krieger, G. et al. (2012): Digital Beamforming and MIMO SAR : Review and New Concepts. in: Proceedings of EUSAR (pp. 11–14).",
                              a(href = "http://elib.dlr.de/76974/1/Kr_et_al_EUSAR2012_DBF_final.pdf", target = "_blank", "Link"),"."),
                            p("Massonnet, D. et al. (1993): The displacement field of the Landers earthquake mapped 
                               by radar interferometry. In: Nature, 364, 138–142.",
                               a(href = "https://www.researchgate.net/profile/Cesar_Carmona-Moreno/publication/243762755_The_displacement_field_of_the_Landers_earthquake_mapped_by_Radar_interferometry/links/0a85e53542104e2a44000000.pdf?origin=publication_detail&ev=pub_int_prw_xdl&msrp=aa9Oes9vkA3okgkNiIhEzhBG98349Xy80gYbU2X049txjI6JIZx5lMcW4Fky95LtmWehq3blTo50QG8MWYaLzL0XoF4tLpOsFRTfMVLNl-Q.ihZmu8nYf9zRM0_aahx9UJV4dgVVnV5HBiLma3m-gMF_9DLWBFWC7R536aFxdhvwJ5lYe03eE0jIaBEH4jLJKQ.sB03YLKHETi2oaaotxOfqjS3iELhl6MBAL7kJXl7f4A1ttgXA8xeBQlXLsM1QYjH9lrmfmBWGxg4Z_AJZsl53A", target = "_blank", "Link"),"."),
                            p("Moreira, A. et al.(2013): A tutorial on Synthetic Aperture Radar. IEEE Geoscience and Remote Sensing Magazine, 1, 6–43.",
                               a(href = "http://elib.dlr.de/82313/1/SAR-Tutorial-March-2013.pdf", target = "_blank", "Link"),"."),
                            p("Ouchi, K. (2013). Recent Trend and Advance of Synthetic Aperture Radar with Selected
                               Topics. In: Remote Sensing, 5, 716–807.",
                              a(href = "http://www.mdpi.com/2072-4292/5/2/716/pdf", target = "_blank", "Link"),"."),
                            p("Richards, J.A. (2009). Remote Sensing with Imaging Radar. Heidelberg: Springer.",
                              a(href = "http://www.springer.com/de/book/9783642020193", target = "_blank", "Link"),"."),                         
                            p("Rosenqvist, A. et al. (2000): The Global Rain Forest Mapping project — a review. International Journal of
                               Remote Sensing, 21, 1375–1387.",
                               a(href = "http://www.eorc.jaxa.jp/ALOS/kyoto/ref/IJRS_GRFM-a-review.pdf", target = "_blank", "Link"),"."),
                            p("Schmullius, C.C. & Evans, D.L. (1997). Synthetic aperture radar (SAR) frequency and
                               polarization requirements for applications in ecology , geology , hydrology , and oceanography: 
                               a tabular status quo after SIR-C / X-SAR. International Journal of Remote Sensing, 18, 2713–2722.",
                              a(href = "http://www.tandfonline.com/doi/abs/10.1080/014311697217297?journalCode=tres20", target = "_blank", "Link"),".")
                            
                   )
                   
                      )
          )
        )
)
          