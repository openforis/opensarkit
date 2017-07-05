#----------------------------------------------------------------------------------
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
#----------------------------------------------------------------------------------

#----------------------------------------------------------------------------------
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
#----------------------------------------------------------------------------------


#---------------------------------------------------------------------------
# reactive values and observe events
kc_pro_values <- reactiveValues(kc_pro_pro = 0, kc_pro_abort = 0, kc_pro_log = 0)

# we create the reactive behaviour
observeEvent(input$kc_pro_pro_btn, {
  kc_pro_values$kc_pro_pro = 1
  kc_pro_values$kc_pro_abort = 0
  kc_pro_values$kc_pro_log = 1
})

observeEvent(input$kc_pro_abort_btn, {
  kc_pro_values$kc_pro_pro = 0
  kc_pro_values$kc_pro_abort = 1
})

#observeEvent(input$kc_pro_log_btn, {
#  kc_pro_values$kc_pro_log = 1
#})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
kc_pro_get_state = function() {
  
  if(!exists("kc_pro_args"))
    return("INITIAL")
  else {
    
    # get the pid
    kc_pro_pid_cmd=paste("-ef | grep \"sh -c ( post_ALOS_KC_process", kc_pro_args, "\" | grep -v grep | awk '{print $2}'")
    kc_pro_pid = as.integer(system2("ps", args = kc_pro_pid_cmd, stdout = TRUE))
  }
  
  if (length(kc_pro_pid) > 0)
    return("RUNNING")
  
  if (file.exists(kc_pro_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# get the input arguments from the GUI
kc_pro_get_args = function(){
  
  # check if processing directory is chosen
  if (is.null(input$kc_pro_directory)){
    kc_pro_dir_message="Project directory not selected"
    kc_pro_js_string <- 'alert("Attention");'
    kc_pro_js_string <- sub("Attention",kc_pro_dir_message,kc_pro_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_pro_js_string))
    kc_pro_values$kc_pro_pro = 0
    kc_pro_values$kc_pro_log = 0
    return("INPUT_FAIL")
  } 
  
  else if ((input$kc_pro_AOI == "AOI_shape_local")&(is.null(input$kc_pro_shapefile))){
    kc_pro_dir_message="AOI shapefile not selected"
    kc_pro_js_string <- 'alert("Attention");'
    kc_pro_js_string <- sub("Attention",kc_pro_dir_message,kc_pro_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_pro_js_string))
    kc_pro_values$kc_pro_pro = 0
    kc_pro_values$kc_pro_log = 0
    return("INPUT_FAIL")
  }
  
  else if ((input$kc_pro_AOI == "AOI_zip_upload")&(is.null(input$kc_pro_zipfile_path))){
    kc_pro_dir_message="AOI zip-archive not selected"
    kc_pro_js_string <- 'alert("Attention");'
    kc_pro_js_string <- sub("Attention",kc_pro_dir_message,kc_pro_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_pro_js_string))
    kc_pro_values$kc_pro_pro = 0
    kc_pro_values$kc_pro_log = 0
    return("INPUT_FAIL")
  }
  
  else {
    # get project folder input
    volumes = c('User directory'=Sys.getenv("HOME"))
    kc_pro_dir <<- parseDirPath(volumes, input$kc_pro_directory)
    
    # get AOI (dependent on AOI type)      
    if (input$kc_pro_AOI == "country"){
      db_file=Sys.getenv("OST_DB")
      # get iso3
      db = dbConnect(SQLite(),dbname=db_file)
      query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$kc_pro_countryname)
      kc_pro_aoi_set = dbGetQuery(db,query)
      dbDisconnect(db)
    }
    
    else if (input$kc_pro_AOI == "AOI_shape_local"){
      df = parseFilePaths(volumes, input$kc_pro_shapefile)
      kc_pro_aoi_set = as.character(df[,"datapath"])
    } 
    
    else if (input$kc_pro_AOI == "AOI_zip_upload"){
      df = input$kc_pro_zipfile_path
      print(df)
      ARCHIVE = df$datapath
      print(ARCHIVE)
      OUT_ARCHIVE = paste(kc_pro_dir, "/AOI", sep = "")
      dir.create(OUT_ARCHIVE)
      unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
      AOI_SHP=list.files(OUT_ARCHIVE, pattern = "*.shp")
      kc_pro_aoi_set = paste(OUT_ARCHIVE,"/",AOI_SHP,sep = "")
    } 
    
    # get year from input
    kc_pro_year_set = input$kc_pro_year
    
    # get speckle filter modus
    if (input$kc_pro_speckle == "Yes"){
      kc_pro_spec = "1" 
    } 
    
    else {
      kc_pro_spec = "0" 
    }
    
    # print command
    kc_pro_args <<- paste(kc_pro_dir, kc_pro_aoi_set, kc_pro_year_set, kc_pro_spec)
    
    # define exitfile path
    kc_pro_exitfile <<- paste(kc_pro_dir, "/.kc_pro_exitfile", sep="")
    
    kc_pro_tmp <<- paste(kc_pro_dir, "/.TMP", kc_pro_year_set, sep = "")
    
    # return updated state
    return("NOT_STARTED")
  }
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Processing functions
kc_pro_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("kc_pro_pro_btn", {
    
    kc_pro_message="Processing started (This will take a while.)"
    js_string_kc_dow <- 'alert("Processing");'
    js_string_kc_dow <- sub("Processing",kc_pro_message,js_string_kc_dow)
    session$sendCustomMessage(type='jsCode', list(value = js_string_kc_dow))
    
    #print(paste("( post_ALOS_KC_download", kc_pro_args, "; echo $? >", kc_pro_exitfile, ")"))
    system(paste("( post_ALOS_KC_process", kc_pro_args, "; echo $? >", kc_pro_exitfile, ")"), wait = FALSE, intern = FALSE)
    
    return("RUNNING")
  })
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Termination Function (what to do when script stopped)
kc_pro_term = function() {
  
  # get the exit state of the script
  kc_pro_status = readLines(kc_pro_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(kc_pro_exitfile, force = TRUE)
  
  # message when all downloads finished/failed
  if (kc_pro_status == 11 ){
    kc_pro_end_message="Your downloaded data tiles seem to be corrupted. Delete the files and re-download them."
    kc_pro_end_js_string <- 'alert("SUCCESS");'
    kc_pro_end_js_string <- sub("SUCCESS",kc_pro_end_message,kc_pro_end_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_pro_end_js_string))  
  }
  
  else if (kc_pro_status == 111 ){
    kc_pro_end_message="Something went wrong and your final output files have not been created. Most likely you ran into storage issues (i.e. no space left on device)."
    kc_pro_end_js_string <- 'alert("SUCCESS");'
    kc_pro_end_js_string <- sub("SUCCESS",kc_pro_end_message,kc_pro_end_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_pro_end_js_string))  
  }
  else if ( kc_pro_status == 0 ){
    kc_pro_end_message="Finished processing"
    kc_pro_end_js_string <- 'alert("SUCCESS");'
    kc_pro_end_js_string <- sub("SUCCESS",kc_pro_end_message,kc_pro_end_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_pro_end_js_string))
  }
  
  # reset button to 0 for enable re-start
  kc_pro_values$kc_pro_pro = 0
  
}  
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# Processing and Abort function
output$process_KC = renderText({
  
  # trigger processing when action button clicked
  if(kc_pro_values$kc_pro_pro) {
    
    #run the state function
    kc_pro_state = kc_pro_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    print(paste("1",kc_pro_state))
    
    if (kc_pro_state == "INITIAL"){
      kc_pro_values$kc_pro_log = 0
      kc_pro_state = kc_pro_get_args()
      unlink(paste(kc_pro_dir, "/.kc_pro_progress", sep = ""))
    }
    
    if (kc_pro_state == "NOT_STARTED"){
      kc_pro_state = kc_pro_start()
      Sys.sleep(2)
      kc_pro_values$kc_pro_log = 1
    }
    
    if (kc_pro_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (kc_pro_state == "TERMINATED")
      kc_pro_term()
    
    print("")
  } # close value process    
  
  if(kc_pro_values$kc_pro_abort) {
    
    # delete the exit file
    unlink(kc_pro_exitfile)
    
    # cancel the
    print(paste("ost_cancel_proc \"sh -c ( post_ALOS_KC_process", kc_pro_args, "\"", kc_pro_tmp))
    system(paste("ost_cancel_proc \"sh -c ( post_ALOS_KC_process", kc_pro_args, "\"", kc_pro_tmp))
    
    kc_pro_dir_message="User interruption"
    kc_pro_js_string <- 'alert("Attention");'
    kc_pro_js_string <- sub("Attention",kc_pro_dir_message,kc_pro_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_pro_js_string))
    print("")
  }
  
  
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Progress monitor function
output$kc_pro_progress = renderText({
  
  if(kc_pro_values$kc_pro_log) {
    
    kc_pro_progress_file=file.path(kc_pro_dir, "/.kc_pro_progress")
    
    if(file.exists(kc_pro_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", kc_pro_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(kc_pro_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------


