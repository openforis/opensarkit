tabItem(tabName = "about",
        
        fillRow(
           box(
              title = "About OST", status = "success", solidHeader= TRUE,
              
              tabBox(width = 700,
                     
                     tabPanel("Welcome",
                              br(),
                              tags$h4("Welcome to the Open Foris SAR Toolkit!"),
                              p("The Open Foris SAR toolkit (OST) provides easy-to-use and standardized workflows to transform raw
                                 and low-level radar imagery, as provided by different space agencies, into higher level remote sensing 
                                 products. Processing of Radar Remote Sensing imagery is complex and differs considerably from its optical counterpart. 
                                 On the other hand, lots of the required steps can be automized. OST intends to achieve a high level of automization 
                                 and therefore minimizes the required knowledge necessary for the product generation. The generated output 
                                 can be considered as pre-processed imagery ready to use for subsequent value adding such as image classification, 
                                 as it is the case for pre-processed optical imagery (e.g. surface reflectance products)."),
                              p("In addition, OST contains education and information material in order to provide beginners with a basic understanding
                                 of the technology and the meaningfulness of the different imagery. References to websites, information material 
                                 and scientific articles allow the user to gain a more profound knowledge about SAR satellites, SAR products 
                                 and different application scenarios."),
                              p("OST bases on free and open source software components. The actual SAR processing is done by the
                                 Sentinel Application Platform (SNAP) provided free of charge by the European Space Agency (ESA). Basic geospatial operations
                                 are accomplished by using the Geospatial Data Abstraction Library (GDAL). The graphical user interface is constructed by 
                                 the R shiny package."),
                              p("The development is funded under the UN-FAO SEPAL project and aims to contribute to the activities of the UN programme for 
                                 Reduction of Emissions from Deforestation and Degradation (UN-REDD)."),
                              br(),
                              br(),
                              img(src="sepal-logo-EN-white.jpg", height = 100, width = 210),
                              img(src="UNREDD_LOGO_COLOUR.jpg",  height = 80,  width = 100),
                              img(src="Open-foris-Logo160.jpg",  height = 70,  width = 70),
                              br()
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
                              ""
                     ),
                     
                     tabPanel("Disclaimer",
                              
                              tags$h4("Disclaimer"),
                              p("FAO declines all responsibility for errors or deficiencies in the database or software 
                                 or in the documentation accompanying it, for program maintenance and upgrading as well as 
                                 for any damage that may arise from them. FAO also declines any responsibility for updating 
                                 the data and assumes no responsibility for errors and omissions in the data provided. Users are, 
                                 however, kindly asked to report any errors or deficiencies in this product to FAO. "),
                              br(),
                              br(),
                              img(src="sepal-logo-EN-white.jpg", height = 100, width = 210),
                              img(src="UNREDD_LOGO_COLOUR.jpg",  height = 80,  width = 100),
                              img(src="Open-foris-Logo160.jpg",  height = 70,  width = 70),
                              br()
                     )
              ) # close tab box
           ) # close box
        ) # close fillRow
) # close tabItem