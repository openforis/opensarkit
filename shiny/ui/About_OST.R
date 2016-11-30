tabItem(tabName = "about",
        
        fillRow(
           box(
              title = "About OST", status = "success", solidHeader= TRUE,
              
              tabBox(width = 1400,
                     
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
                     
                     tabPanel("Outline",
                              br(),
                              tags$h4("1  - Getting started"),
                              p("1.1 - ", actionLink("link_to_tabpanel_sartheory", " SAR theory")),
                              p("1.2 - ", actionLink("link_to_tabpanel_sarmissions", "SAR missions")),
                              p("1.3 - ", actionLink("link_to_tabpanel_sarimage", "SAR image interpretation")),
                              p("1.4 - ", actionLink("link_to_tabpanel_sarrefs", "Reference Material")),
                              tags$h4("2  - ALOS Functionality"),
                              p("2.1 - ", actionLink("link_to_tabpanel_alos_kc", "ALOS Kyoto & Carbon Mosaics")),
                              p("2.2 - ", actionLink("link_to_tabpanel_alos_inv", "ALOS-1 inventory (ASF server)")),
                              #p("2.3", actionLink("link_to_tabpanel_alos_dow", "ALOS-1 download (ASF server)")),
                              p("2.4 - ", actionLink("link_to_tabpanel_alos_grd2rtc", "ALOS-1 GRD to RTC processor")),
                              tags$h4("3  - Sentinel-1 Functionality"),
                              p("3.1 - ", actionLink("link_to_tabpanel_s1_inv", "Sentinel-1 inventory (ASF server)")),
                              p("3.2 - ", actionLink("link_to_tabpanel_s1_dow", "Sentinel-1 download (ASF server)")),
                              p("3.3 - ", actionLink("link_to_tabpanel_s1_grd2rtc", "Sentinel-1 GRD to RTC processor")),
                              p("3.4 - ", actionLink("link_to_tabpanel_s1_grd2ts", "Sentinel-1 GRD to RTC time-series processor"))
                     ),
                     
                     tabPanel("References",
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