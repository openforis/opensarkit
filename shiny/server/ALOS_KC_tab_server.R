# 1 Choose a folders or files locally within your home directory with shinyFiles package
output$KC_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  # Directory choice
  shinyDirChoose(input, 'directory', roots=volumes)
  
  validate (
    need(input$directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$directory)
  cat(df) #}
})

# File choice
output$KC_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})


print_alos = eventReactive(input$alos_kc_process, {
   volumes = c('User directory'=Sys.getenv("HOME"))
   
   # check if processing directory is chosen
   if (is.null(input$directory)){
      empty_dir_message="No project folder chosen"
      js_string <- 'alert("SOMETHING");'
      js_string <- sub("SOMETHING",empty_dir_message,js_strign)
      session$sendCustomMessage(type='jsCode', list(value = js_string))
   } else if (input$ALOS_AOI == "AOI_shape_local"){
         
         # if local shapefile is clicked, check if it actually chosen
         if(is.null(input$shapefile)){
            empty_shp_message="No shapefile chosen"
            js_string <- 'alert("SOMETHING");'
            js_string <- sub("SOMETHING",empty_shp_message,js_string)
            session$sendCustomMessage(type='jsCode', list(value = js_string))
         } else {
           dummy="dummy"
         }
     
   } else if (input$ALOS_AOI == "AOI_zip_upload"){
     
     # if local shapefile is clicked, check if it actually chosen
     if(is.null(input$zipfile_path)){
       empty_shp_message="No zip-archive chosen"
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
         DIR = parseDirPath(volumes, input$directory)
        
         # get AOI (dependent on AOI type)      
         if (input$ALOS_AOI == "country"){
            
            db_file=Sys.getenv("OST_DB")
            # get iso3
            db = dbConnect(SQLite(),dbname=db_file)
            query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$countryname)
            AOI = dbGetQuery(db,query)
            dbDisconnect(db)
         } else if (input$ALOS_AOI == "AOI_shape_local"){
            df = parseFilePaths(volumes, input$shapefile)
            AOI = as.character(df[,"datapath"])
         } else if (input$ALOS_AOI == "AOI_zip_upload"){
           
            df = input$zipfile_path
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
         YEAR = input$year
   
         # get speckle filter modus
         if (input$ALOS_KC_speckle == "Yes"){
            SPECKLE = "1" } else {
            SPECKLE = "0" }
   
         # handling username and password data
         UNAME = input$uname
         PW = input$piwo
         FILENAME = paste(".",randomStrings(1, 20), sep = "")
         HOME_DIR = Sys.getenv("HOME")
         FILE = file.path(HOME_DIR,FILENAME)
         write(UNAME, FILE)
         write(PW, FILE, append = TRUE)
         rm(UNAME)
         rm(PW)

         kc_start_message="Started processing (this will take a few hours)"
         kc_start_js_string <- 'alert("Attention");'
         kc_start_js_string <- sub("Attention",kc_start_message,kc_start_js_string)
         session$sendCustomMessage(type='jsCode', list(value = kc_start_js_string))
         # print command
         ARG_DOWN= paste(DIR, AOI, YEAR, SPECKLE, FILE, "")
         print(paste("poft-sar-ALOS-KC-full", ARG_DOWN))
         system(paste("poft-sar-ALOS-KC-full", ARG_DOWN), intern=TRUE)
         kc_end_message="Finished processing"
         kc_end_js_string <- 'alert("SUCCESS");'
         kc_end_js_string <- sub("SUCCESS",kc_end_message,kc_end_js_string)
         session$sendCustomMessage(type='jsCode', list(value = kc_end_js_string))
      }
})

output$processALOS = renderText({
   print_alos()
})


