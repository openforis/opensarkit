print_alos = eventReactive(input$alos_kc_process, {
   volumes = c('User directory'=Sys.getenv("HOME"))
   
   # check if processing directory is chosen
   if (is.null(input$directory)){
      empty_dir_message="No project folder chosen"
      js_string <- 'alert("SOMETHING");'
      js_string <- sub("SOMETHING",empty_dir_message,js_string)
      session$sendCustomMessage(type='jsCode', list(value = js_string))
      } else if (input$ALOS_AOI == "AOI_shape_local"){
         
         # if local shapefile is clicked, check if it actually chosen
         if(is.null(input$shapefile)){
            empty_shp_message="No shapefile chosen"
            js_string <- 'alert("SOMETHING");'
            js_string <- sub("SOMETHING",empty_shp_message,js_string)
            session$sendCustomMessage(type='jsCode', list(value = js_string))
         }
      } else {
         
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
         } else if (input$ALOS_AOI == "AOI_shape_upload"){
            AOI = input$shapefile_path
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
   
         # print command
         ARG_DOWN= paste(DIR, AOI, YEAR, SPECKLE, FILE)
         system(paste("poft-sar-ALOS-KC-full", ARG_DOWN), intern=TRUE)
         ARGS_FIN=paste("-c \"poft-sar-ALOS-KC-full\"", ARG_DOWN)
         #system2("bash", ARGS_FIN, wait = TRUE)
         #system2("poft-sar-ALOS-KC-full", ARG_DOWN, stdout=TRUE)
      }
})

output$processALOS = renderText({
   print_alos()
})


