# 1 Choose a folders or files locally within your home directory with shinyFiles package
output$kc_dow_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  # Directory choice
  shinyDirChoose(input, 'kc_dow_directory', roots=volumes)
  
  validate (
    need(input$kc_dow_directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$kc_dow_directory)
  cat(df) #}
})

# File choice
output$kc_dow_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'kc_dow_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$kc_dow_shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$kc_dow_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})

# main function triggering the OST CL command
print_kc_dow = eventReactive(input$kc_download, {
   
   # wrapper for busy indicator
   withBusyIndicatorServer("kc_download", {
   # set root directory to home
   # volumes = c('User directory'=Sys.getenv("HOME"))
   
      # check if processing directory is chosen
      if (is.null(input$kc_dow_directory)){
        stop("Select a project folder")
      } 
   
      else if ((input$KC_dow_AOI == "AOI_shape_local")&(is.null(input$kc_dow_shapefile))){
        stop("Select a shapefile")
      }
   
      else if ((input$KC_dow_AOI == "AOI_zip_upload")&(is.null(input$kc_dow_zipfile_path))){
        stop("Select a Zipfile that contains an AOI shapefile")
      }
   
      else {
        # get project folder input
        volumes = c('User directory'=Sys.getenv("HOME"))
        DIR = parseDirPath(volumes, input$kc_dow_directory)
        
        # get AOI (dependent on AOI type)      
        if (input$KC_dow_AOI == "country"){
          db_file=Sys.getenv("OST_DB")
          # get iso3
          db = dbConnect(SQLite(),dbname=db_file)
          query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$kc_dow_countryname)
          AOI = dbGetQuery(db,query)
          dbDisconnect(db)
        }
        
        else if (input$KC_dow_AOI == "AOI_shape_local"){
          df = parseFilePaths(volumes, input$kc_dow_shapefile)
          AOI = as.character(df[,"datapath"])
        } 
        
        else if (input$KC_dow_AOI == "AOI_zip_upload"){
          df = input$kc_dow_zipfile_path
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
        YEAR = input$kc_dow_year
   
        # handling username and password data
        UNAME = input$kc_dow_uname
        PW = input$kc_dow_piwo
        FILENAME = paste(".",randomStrings(1, 20), sep = "")
        HOME_DIR = Sys.getenv("HOME")
        FILE = file.path(HOME_DIR,FILENAME)
        write(UNAME, FILE)
        write(PW, FILE, append = TRUE)
        rm(UNAME)
        rm(PW)

        kc_dow_start_message="Downloading data tiles (this will take about 2 hours)"
        kc_dow_start_js_string <- 'alert("Attention");'
        kc_dow_start_js_string <- sub("Attention",kc_dow_start_message,kc_dow_start_js_string)
        session$sendCustomMessage(type='jsCode', list(value = kc_dow_start_js_string))
        
        # print command
        ARG_DOWN= paste(DIR, AOI, YEAR, FILE)
        print(paste("post_ALOS_KC_download", ARG_DOWN))
        system(paste("post_ALOS_KC_download", ARG_DOWN), intern=TRUE)
        
        kc_dow_end_message="Download finished."
        kc_dow_end_js_string <- 'alert("SUCCESS");'
        kc_dow_end_js_string <- sub("SUCCESS",kc_dow_end_message,kc_dow_end_js_string)
        session$sendCustomMessage(type='jsCode', list(value = kc_dow_end_js_string))
   }
   })
})

output$download_KC = renderText({
   print_kc_dow()
})


