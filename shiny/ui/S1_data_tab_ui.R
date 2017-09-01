#-----------------------------------------------------------------------------
# S1 Tab
tabItem(tabName = "s1_data",
        fluidRow(
          #----------------------------------------------------------------------------------
          # Processing Panel Sentinel-1
          box(
            # Title                     
            title = "Sentinel-1 - get data", status = "success", solidHeader= TRUE,
            
            tabBox(width = 700,
                   
              tags$h4("Get Sentinel-1 data"),
              hr(),
              p("The Open SAR Toolkit (OST) provides functionality to ", tags$b("effectively search and download"), " Sentinel-1 data from the",  a(href = "https://www.asf.alaska.edu/", "Alaska Satellite Facility"), "(ASF).
                 The workflow starts with a general inventory that creates a shapefile containing the most important metadata of all available imagery according to the settings of search parameters. This shapefile is 
                 referred to as an", tags$b(" OST inventory shapefile."), " It can be further edited by third party GIS software in order to refine the search results and adapt them to the actual needs. 
                 Subsequently, the OST inventory shapefile is used for the download of the data. It is important to notice that the download routine creates a
                 ", tags$b("predefined folder structure"), " that is mandatory for the bulk processing routines of OST.")
              #p(" --> ", actionLink("link_to_tabpanel_s1_inv", " Go to the Sentinel-1 data inventory")),
              #p(" --> ", actionLink("link_to_tabpanel_s1_dow", " Go to the Sentinel-1 data download "))
              
            )
          ) # close box
          
        ) # close fluid row
) # close tabit
