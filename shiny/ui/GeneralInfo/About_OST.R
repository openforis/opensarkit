tabItem(tabName = "about",
        
        fillRow(
           box(
              title = "About OST", status = "success", solidHeader= TRUE,
              
              tabBox(width = 700,
                     
                     tabPanel("Welcome",
                              br(),
                              "This tool prepares ALOS K&C mosaics",br(),
                              "Interesting results can be found in the Kyoto and Carbon booklet provided by the Japanese Space Agnecy",br(),
                              "http://www.eorc.jaxa.jp/ALOS/en/kyoto/ref/KC-Booklet_2010_comp.pdf"
                     ),
                     
                     tabPanel("What is OST?",
                              br(),
                              p("Open Foris SAR Toolkit is a collection of prototype command-line utilities
                                 for highly-automated SAR related processing tasks such as data inventory and
                                 download as well as data preprocessing and some basic post-processing commands.
                                 The toolkit aims to strongly simplify the complex process of transforming raw, or
                                 low level SAR imagery into higher level products that are ready for subsequent
                                 image processing tasks in order to enable the production of value-added thematic
                                 information layers."),
                               p("The processing chains are realized in simple bash scripts that expect a minimum
                                  of given input parameters when executed. The output files are usually in
                                  the GeoTiff format and stored for every band separately. A virtual-raster file is
                                  created allowing to import the stack into GIS or RS software. The processing
                                  commands follow standardized workflows in order to provide ready-to-classify data
                                  stacks comparable to optical remote sensing data. The tools have been tested
                                  solely on Ubuntu Linux 14.04 environment for now. While it should be compatible
                                  with other with other Linux distributions (given the installation of the software
                                  dependencies) it is foreseen to provide installers for Mac OS as well as MS Win-
                                  dows in future. For the actual data processing, the scripts call the functionalities
                                  of other freely available software packages such as the Sentinel Application Plat-
                                  form (SNAP, http://step.esa.int/main/toolboxes/snap/) and geospatial
                                  FOSS software like the GDAL libraries.")
                     ),
                     
                     tabPanel("Hardware requirements",
                              br(),
                              "Not my fault"
                     ),
                     
                     tabPanel("Disclaimer",
                              br(),
                              "References"
                     )
              ) # close tab box
           ) # close box
        ) # close fillRow
) # close tabItem