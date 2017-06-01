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
  cat(df) 
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

# main function for executing command
print_s1_inv = eventReactive(input$s1_inv_search, {
 
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_inv_search", {
  
    # check if necessary fields are filled
    if (is.null(input$S1_inv_directory)){
      stop("Choose a project folder")
    }
  
    else if ((input$S1_inv_AOI == "S1_inv_shape_local")&(is.null(input$S1_inv_shapefile))){
      stop("Select a shapefile")
    }

    else if ((input$S1_inv_AOI == "S1_inv_shape_upload")&(is.null(input$S1_inv_shapefile_path))){
      stop("Select a Zipfile that contains an AOI shapefile")
    }
  
    else { # run the whole thing
    
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
      } 
    
      else if (input$S1_inv_AOI == "S1_inv_shape_local"){
        df = parseFilePaths(volumes, input$S1_inv_shapefile)
        AOI = as.character(df[,"datapath"])
      }
    
      else if (input$S1_inv_AOI == "S1_inv_shape_upload"){
        df = input$S1_inv_shape_upload
        ARCHIVE = df$datapath
        OUT_ARCHIVE = paste(OUTDIR, "/Inventory_upload", sep = "")
        dir.create(OUT_ARCHIVE)
        unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
        OST_inv=list.files(OUT_ARCHIVE, pattern = "*.shp")
        AOI = paste(OUT_ARCHIVE,"/",OST_inv,sep = "")
      } 
    
      # get year from input
      print(input$s1_inv_daterange)
      STARTDATE = input$s1_inv_daterange[1]
      ENDDATE = input$s1_inv_daterange[2]
    
      # choice of the sensor polarisation
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
    
      # Pop-up message for starting data inventory
      s1_search_message="Searching for data"
      js_string_s1_search <- 'alert("Inventory");'
      js_string_s1_search <- sub("Inventory",s1_search_message,js_string_s1_search)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_search))

      # call OST command line and create inventory shapefile
      ARG_DOWN = paste(DIR, AOI, STARTDATE, ENDDATE, SMODE, PLEVEL, POLAR, "0")
      print(paste("ost_S1_ASF_inventory", ARG_DOWN), intern=FALSE)
      system(paste("ost_S1_ASF_inventory", ARG_DOWN), intern=FALSE)
    
      # Pop-up message for having finished data inventory
      s1_found_message="Found data"
      js_string_s1_found <- 'alert("Finished");'
      js_string_s1_found <- sub("Finished",s1_found_message,js_string_s1_found)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_found))
    
    }
  })
})

output$searchS1_inv = renderText({
  print_s1_inv()
})



