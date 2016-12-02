# 1 Choose a local folder 
output$S1_inv_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 'S1_inv_directory', roots=volumes)
  
  validate (
    need(input$S1_inv_directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$S1_inv_directory)
  cat(df) #}
})

# Choose a local file
output$S1_inv_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'S1_inv_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
  need(input$S1_inv_shapefile != "","No shapefile selected"),
  errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$S1_inv_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})


print_s1_inv = eventReactive(input$s1_inv_search, {
  volumes = c('User directory'=Sys.getenv("HOME"))
  
  # check if processing directory is chosen
  if (is.null(input$S1_inv_directory)){
    empty_dir_message="No project folder chosen"
    js_string <- 'alert("SOMETHING");'
    js_string <- sub("SOMETHING",empty_dir_message,js_string)
    session$sendCustomMessage(type='jsCode', list(value = js_string))
  } else if (input$S1_inv_AOI == "AOI_shape_local"){
    
    # if local shapefile is clicked, check if it actually chosen
    if(is.null(input$S1_inv_shapefile)){
      empty_shp_message="No shapefile chosen"
      js_string <- 'alert("SOMETHING");'
      js_string <- sub("SOMETHING",empty_shp_message,js_string)
      session$sendCustomMessage(type='jsCode', list(value = js_string))
    } else {
      dummy="dummy"
    }
  } else {
    dummy="dummy"
  }   
  
  if (dummy == "dummy"){
    
    # get project folder input
    volumes = c('User directory'=Sys.getenv("HOME"))
    DIR = parseDirPath(volumes, input$S1_inv_directory)
    
    # get AOI (dependent on AOI type)      
    if (input$S1_inv_AOI == "S1_inv_country"){
      
      db_file=Sys.getenv("OST_DB")
      # get iso3
      db = dbConnect(SQLite(),dbname=db_file)
      query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$S1_inv_countryname)
      AOI = dbGetQuery(db,query)
      dbDisconnect(db)
    } else if (input$S1_inv_AOI == "S1_inv_shape_local"){
      df = parseFilePaths(volumes, input$S1_inv_shapefile)
      AOI = as.character(df[,"datapath"])
    } else if (input$S1_inv_AOI == "S1_inv_shape_upload"){
      AOI = input$S1_inv_shapefile_path
    } 
    
    # get year from input
    print(input$s1_inv_daterange)
    STARTDATE = input$s1_inv_daterange[1]
    ENDDATE = input$s1_inv_daterange[2]
    
    # # choice of the sensor polarisation
    if (input$s1_inv_pol == "dual_vv"){
                POLAR = "2" 
    } 
    else if (input$s1_inv_pol == "vv"){
                POLAR = "3" 
    }
    else if (input$s1_inv_pol == "dual_single_vv"){
      POLAR = "1" 
    }
    else if (input$s1_inv_pol == "dual_hh"){
      POLAR = "5" 
    }
    else if (input$s1_inv_pol == "hh"){
      POLAR = "6" 
    }
    else if (input$s1_inv_pol == "dual_single_hh"){
      POLAR = "4" 
    }
    
    # choice of the sensor mode
    if (input$s1_inv_sensor_mode == "iw"){
      SMODE = "IW" 
    }
    else if (input$s1_inv_sensor_mode == "ew"){
      SMODE = "EW" 
    } 
    else if (input$s1_inv_sensor_mode == "wv"){
      SMODE = "WV" 
    } 
    
    # choice of the product level
    if (input$s1_inv_product_level == "grd"){
      PLEVEL = "GRD" 
    }
    else if (input$s1_inv_product_level == "slc"){
      PLEVEL = "SLC" 
    } 
    else if (input$s1_inv_product_level == "raw"){
      PLEVEL = "RAW" 
    } 
    
    
    s1_search_message="Searching for data"
    js_string_s1_search <- 'alert("Inventory");'
    js_string_s1_search <- sub("Inventory",s1_search_message,js_string_s1_search)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_search))
    print("searching...")
    print(STARTDATE)
    print(ENDDATE)
    # call OST command line and create inventory shapefile
    ARG_DOWN = paste(DIR, AOI, STARTDATE, ENDDATE, SMODE, PLEVEL, POLAR, "0")
    print(ARG_DOWN)
    system(paste("oft-sar-S1-ASF-inventory", ARG_DOWN), intern=FALSE)
    print(paste("oft-sar-S1-ASF-inventory", ARG_DOWN), intern=FALSE)
    
    s1_found_message="Found data"
    js_string_s1_found <- 'alert("Finished");'
    js_string_s1_found <- sub("Finished",s1_found_message,js_string_s1_found)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_found))
    
  }
})

output$searchS1_inv = renderText({
  print_s1_inv()
})



