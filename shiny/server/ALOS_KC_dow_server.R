#---------------------------------------------------------------------------
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
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
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
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# reactive values and observe events
kc_dow_values <- reactiveValues(kc_dow_pro = 0, kc_dow_abort = 0, kc_dow_log = 0)

# we create the reactive behaviour
observeEvent(input$kc_dow_pro_btn, {
  kc_dow_values$kc_dow_pro = 1
  kc_dow_values$kc_dow_abort = 0
  kc_dow_values$kc_dow_log = 1
})

observeEvent(input$kc_dow_abort_btn, {
  kc_dow_values$kc_dow_pro = 0
  kc_dow_values$kc_dow_abort = 1
})

#observeEvent(input$kc_dow_log_btn, {
#  kc_dow_values$kc_dow_log = 1
#})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
kc_dow_get_state = function() {
  
  if(!exists("kc_dow_args"))
    return("INITIAL")
  else {
    
    # get the pid
    kc_dow_pid_cmd=paste("-ef | grep \"sh -c ( post_ALOS_KC_download", kc_dow_args, "\" | grep -v grep | awk '{print $2}'")
    kc_dow_pid = as.integer(system2("ps", args = kc_dow_pid_cmd, stdout = TRUE))
  }
  
  if (length(kc_dow_pid) > 0)
    return("RUNNING")
  
  if (file.exists(kc_dow_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# get the input arguments from the GUI
kc_dow_get_args = function(){
  
  # check if processing directory is chosen
  if (is.null(input$kc_dow_directory)){
    kc_dow_dir_message=" Project directory not selected"
    kc_dow_js_string <- 'alert("Attention");'
    kc_dow_js_string <- sub("Attention",kc_dow_dir_message,kc_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_dow_js_string))
    kc_dow_values$kc_dow_pro = 0
    kc_dow_values$kc_dow_log = 0
    return("INPUT_FAIL")
  } 
  
  else if ((input$KC_dow_AOI == "AOI_shape_local")&(is.null(input$kc_dow_shapefile))){
    kc_dow_dir_message=" AOI shapefile not selected"
    kc_dow_js_string <- 'alert("Attention");'
    kc_dow_js_string <- sub("Attention",kc_dow_dir_message,kc_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_dow_js_string))
    kc_dow_values$kc_dow_pro = 0
    kc_dow_values$kc_dow_log = 0
    return("INPUT_FAIL")
  }
  
  else if ((input$KC_dow_AOI == "AOI_zip_upload")&(is.null(input$kc_dow_zipfile_path))){
    kc_dow_dir_message=" AOI zip archive not selected"
    kc_dow_js_string <- 'alert("Attention");'
    kc_dow_js_string <- sub("Attention",kc_dow_dir_message,kc_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_dow_js_string))
    kc_dow_values$kc_dow_pro = 0
    kc_dow_values$kc_dow_log = 0
    return("INPUT_FAIL")
  }
  
  else {
    # get project folder input
    volumes = c('User directory'=Sys.getenv("HOME"))
    kc_dow_dir <<- parseDirPath(volumes, input$kc_dow_directory)
    
    # get AOI (dependent on AOI type)      
    if (input$KC_dow_AOI == "country"){
      db_file=Sys.getenv("OST_DB")
      # get iso3
      db = dbConnect(SQLite(),dbname=db_file)
      query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$kc_dow_countryname)
      kc_dow_aoi = dbGetQuery(db,query)
      dbDisconnect(db)
    }
    
    else if (input$KC_dow_AOI == "AOI_shape_local"){
      df = parseFilePaths(volumes, input$kc_dow_shapefile)
      kc_dow_aoi = as.character(df[,"datapath"])
    } 
    
    else if (input$KC_dow_AOI == "AOI_zip_upload"){
      df = input$kc_dow_zipfile_path
      print(df)
      ARCHIVE = df$datapath
      print(ARCHIVE)
      OUT_ARCHIVE = paste(kc_dow_dir, "/AOI", sep = "")
      print(OUT_ARCHIVE)
      dir.create(OUT_ARCHIVE)
      unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
      AOI_SHP=list.files(OUT_ARCHIVE, pattern = "*.shp")
      kc_dow_aoi = paste(OUT_ARCHIVE,"/",AOI_SHP,sep = "")
    } 
    
    # get year from input
    kc_dow_year = input$kc_dow_year
    
    # handling username and password data
    UNAME = input$kc_dow_uname
    PW = input$kc_dow_piwo
    kc_dow_filename = paste(".",randomStrings(1, 20), sep = "")
    kc_dow_home = Sys.getenv("HOME")
    kc_dow_file = file.path(kc_dow_home, kc_dow_filename)
    write(UNAME, kc_dow_file)
    write(PW, kc_dow_file, append = TRUE)
    rm(UNAME)
    rm(PW)
    
    # get the arguments
    kc_dow_args <<- paste(kc_dow_dir, kc_dow_aoi, kc_dow_year, kc_dow_file)
    
    # define exitfile path
    kc_dow_exitfile <<- paste(kc_dow_dir, "/.kc_dow_exitfile", sep="")
    
    kc_dow_tmp <<- paste(kc_dow_dir, "/.TMP", kc_dow_year, sep = "")
    # return updated state
    return("NOT_STARTED")
  }
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Processing functions
kc_dow_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("kc_dow_pro_btn", {
    
    kc_dow_message="Processing started (This will take a while.)"
    js_string_kc_dow <- 'alert("Processing");'
    js_string_kc_dow <- sub("Processing",kc_dow_message,js_string_kc_dow)
    session$sendCustomMessage(type='jsCode', list(value = js_string_kc_dow))
    
    #print(paste("( post_ALOS_KC_download", kc_dow_args, "; echo $? >", kc_dow_exitfile, ")"))
    system(paste("( post_ALOS_KC_download", kc_dow_args, "; echo $? >", kc_dow_exitfile, ")"), wait = FALSE, intern = FALSE)
    
    return("RUNNING")
  })
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Termination Function (what to do when script stopped)
kc_dow_term = function() {
  
  # get the exit state of the script
  kc_dow_status = readLines(kc_dow_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(kc_dow_exitfile, force = TRUE)
  
  # message when all downloads finished/failed
  if ( kc_dow_status != 0 ){
    kc_dow_end_message="Download failed. Please try again!"
    kc_dow_js_string <- 'alert("SUCCESS");'
    kc_dow_js_string <- sub("SUCCESS",kc_dow_end_message,kc_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_dow_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    kc_dow_fin_message="Download finished"
    js_string_kc_dow_fin <- 'alert("Processing");'
    js_string_kc_dow_fin <- sub("Processing",kc_dow_fin_message,js_string_kc_dow_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_kc_dow_fin))
  }
  
  # reset button to 0 for enable re-start
  kc_dow_values$kc_dow_pro = 0
}  
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Processing and Abort function
output$download_KC = renderText({
  
  # trigger processing when action button clicked
  if(kc_dow_values$kc_dow_pro) {
    
    #run the state function
    kc_dow_state = kc_dow_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    print(paste("1",kc_dow_state))
    
    if (kc_dow_state == "INITIAL"){
      kc_dow_values$kc_dow_log = 0
      kc_dow_state = kc_dow_get_args()
      unlink(paste(kc_dow_dir, "/.kc_dow_progress", sep = ""))
    }
    
    if (kc_dow_state == "NOT_STARTED"){
      kc_dow_state = kc_dow_start()
      Sys.sleep(2)
      kc_dow_values$kc_dow_log = 1
    }
    
    if (kc_dow_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (kc_dow_state == "TERMINATED")
      kc_dow_term()
    
    print("")
  } # close value process    
  
  if(kc_dow_values$kc_dow_abort) {
    
    # delete the exit file
    unlink(kc_dow_exitfile)
    
    # cancel the
    print(paste("ost_cancel_proc \"sh -c ( post_ALOS_KC_download", kc_dow_args, "\"", kc_dow_tmp))
    system(paste("ost_cancel_proc \"sh -c ( post_ALOS_KC_download", kc_dow_args, "\"", kc_dow_tmp))
    
    kc_dow_dir_message="User interruption"
    kc_dow_js_string <- 'alert("Attention");'
    kc_dow_js_string <- sub("Attention",kc_dow_dir_message,kc_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_dow_js_string))
    print("")
  }
  
  
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Progress monitor function
output$kc_dow_progress = renderText({
  
  if(kc_dow_values$kc_dow_log) {
    
    kc_dow_progress_file=file.path(kc_dow_dir, "/.kc_dow_progress")
    
    if(file.exists(kc_dow_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", kc_dow_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(kc_dow_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------

