# 1 Choose a folders or files locally within your home directory with shinyFiles package
output$kc_pro_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  # Directory choice
  shinyDirChoose(input, 'kc_pro_directory', roots=volumes)
  
  validate (
    need(input$kc_pro_directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$kc_pro_directory)
  cat(df) #}
})

# File choice
output$kc_pro_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'kc_pro_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$kc_pro_shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$kc_pro_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})

# main function triggering the OST CL command
print_kc_pro = eventReactive(input$kc_process, {
   
   # wrapper for busy indicator
   withBusyIndicatorServer("kc_process", {
   # set root directory to home
   # volumes = c('User directory'=Sys.getenv("HOME"))
   
      # check if processing directory is chosen
      if (is.null(input$kc_pro_directory)){
        stop("Choose a project folder")
      } 
   
      else if ((input$KC_pro_AOI == "AOI_shape_local")&(is.null(input$kc_pro_shapefile))){
        stop("Select a shapefile")
      }
   
      else if ((input$KC_pro_AOI == "AOI_zip_upload")&(is.null(input$kc_pro_zipfile_path))){
        stop("Select a Zipfile that contains an AOI shapefile")
      }
   
      else {
        # get project folder input
        volumes = c('User directory'=Sys.getenv("HOME"))
        DIR = parseDirPath(volumes, input$kc_pro_directory)
        
        # get AOI (dependent on AOI type)      
        if (input$KC_pro_AOI == "country"){
          db_file=Sys.getenv("OST_DB")
          # get iso3
          db = dbConnect(SQLite(),dbname=db_file)
          query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$kc_pro_countryname)
          AOI = dbGetQuery(db,query)
          dbDisconnect(db)
        }
        
        else if (input$KC_pro_AOI == "AOI_shape_local"){
          df = parseFilePaths(volumes, input$kc_pro_shapefile)
          AOI = as.character(df[,"datapath"])
        } 
        
        else if (input$KC_pro_AOI == "AOI_zip_upload"){
          df = input$kc_pro_zipfile_path
          print(df)
          ARCHIVE = df$datapath
          print(ARCHIVE)
          OUT_ARCHIVE = paste(DIR, "/AOI", sep = "")
          print(OUT_ARCHIVE)
          dir.create(OUT_ARCHIVE)
          unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
          AOI_SHP=list.files(OUT_ARCHIVE, pattern = "*.shp")
          AOI = paste(OUT_ARCHIVE,"/",AOI_SHP,sep = "")
        } 
   
         # get year from input
        YEAR = input$kc_pro_year
   
        # get speckle filter modus
        if (input$kc_pro_speckle == "Yes"){
          SPECKLE = "1" 
        } 
        
        else {
          SPECKLE = "0" 
        }
   
        kc_pro_start_message="Started processing (this will take a few hours)"
        kc_pro_start_js_string <- 'alert("Attention");'
        kc_pro_start_js_string <- sub("Attention",kc_pro_start_message,kc_pro_start_js_string)
        session$sendCustomMessage(type='jsCode', list(value = kc_pro_start_js_string))
        
        # print command
        ARG_PRO= paste(DIR, AOI, YEAR, SPECKLE, "")
        print(paste("post_ALOS_KC_process", ARG_PRO))
        status = system(paste("post_ALOS_KC_process", ARG_PRO), wait=TRUE)
        
        if (status == 11 ){
          kc_pro_end_message="Your downloaded data tiles seem to be corrupted. Delete the files and re-download them."
          kc_pro_end_js_string <- 'alert("SUCCESS");'
          kc_pro_end_js_string <- sub("SUCCESS",kc_pro_end_message,kc_pro_end_js_string)
          session$sendCustomMessage(type='jsCode', list(value = kc_pro_end_js_string))  
        }
        
        else if (status == 111 ){
          kc_pro_end_message="Something went terribly wrong, and your final output files have not been created. Most likely you ran into storage issues (i.e. no space left on device)."
          kc_pro_end_js_string <- 'alert("SUCCESS");'
          kc_pro_end_js_string <- sub("SUCCESS",kc_pro_end_message,kc_pro_end_js_string)
          session$sendCustomMessage(type='jsCode', list(value = kc_pro_end_js_string))  
        }
        else if ( status == 0 ){
          kc_pro_end_message="Finished processing"
          kc_pro_end_js_string <- 'alert("SUCCESS");'
          kc_pro_end_js_string <- sub("SUCCESS",kc_pro_end_message,kc_pro_end_js_string)
          session$sendCustomMessage(type='jsCode', list(value = kc_pro_end_js_string))
        }
      }
   })
})

output$process_KC = renderText({
   print_kc_pro()
})


