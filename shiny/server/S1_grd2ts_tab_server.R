#---------------------------------------------------------------------------
# Folder processing
output$s1_g2ts_inputfolder = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2ts_inputdir', roots=volumes)
  
  validate (
    need(input$s1_g2ts_inputdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2ts_inputdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

# Choose a local file
output$S1_g2ts_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'S1_g2ts_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$S1_g2ts_shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$S1_g2ts_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})


#---------------------------------------------------------------------------
# Processing functions
print_s1_g2ts = eventReactive(input$s1_g2ts_process, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_g2ts_process", {
    
    if(is.null(input$s1_g2ts_inputdir)){
    stop("No project folder chosen")
    }
  
    else if ((input$S1_g2ts_AOI == "S1_inv_shape_local")&(is.null(input$S1_inv_shapefile))){
      stop("Select a shapefile")
    }
    
    else if ((input$S1_g2ts_AOI == "S1_inv_shape_upload")&(is.null(input$S1_inv_shapefile_path))){
      stop("Select a Zipfile that contains an AOI shapefile")
    }
    
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      OUTDIR = parseDirPath(volumes, input$s1_g2ts_inputdir)
    
      # get AOI (dependent on AOI type)      
      if (input$S1_g2ts_AOI == "S1_g2ts_country"){
        db_file=Sys.getenv("OST_DB")
        # get iso3
        db = dbConnect(SQLite(),dbname=db_file)
        query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$S1_g2ts_countryname)
        AOI = dbGetQuery(db,query)
        dbDisconnect(db)
      } 
      
      else if (input$S1_g2ts_AOI == "S1_g2ts_shape_local"){
        df = parseFilePaths(volumes, input$S1_g2ts_shapefile)
        AOI = as.character(df[,"datapath"])
      }
      
      if (input$s1_g2ts_res == "med_res"){
        MODE = "MED_RES" 
      } 
    
      else if (input$s1_g2ts_res == "full_res"){
        MODE = "HI_RES" 
      }
    
      if (input$s1_g2ts_dtype == "8_bit"){
        DTYPE = "1" 
      } 
      
      else if (input$s1_g2ts_dtype == "16_bit"){
        DTYPE = "2" 
      }
      
      else if (input$s1_g2ts_dtype == "32_bit"){
        DTYPE = "3" 
      }
      
      s1_g2ts_message="Processing started (This will take a while.)"
      js_string_s1_g2ts <- 'alert("Processing");'
      js_string_s1_g2ts <- sub("Processing",s1_g2ts_message,js_string_s1_g2ts)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2ts))

      ARG_PROC=paste(OUTDIR, AOI, MODE, "1", DTYPE)
      print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
      system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
    
      s1_g2ts_fin_message="Processing finished"
      js_string_s1_g2ts_fin <- 'alert("Processing");'
      js_string_s1_g2ts_fin <- sub("Processing",s1_g2ts_fin_message,js_string_s1_g2ts_fin)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2ts_fin))
    } 
  })
})

output$processS1_G2TS = renderText({
  print_s1_g2ts()
})