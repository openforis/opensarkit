#----------------------------------------------------------------------------------
# 1 Choose a folders or files locally within your home directory with shinyFiles package
output$kc_fnf_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  # Directory choice
  shinyDirChoose(input, 'kc_fnf_directory', roots=volumes)
  
  validate (
    need(input$kc_fnf_directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$kc_fnf_directory)
  cat(df) #}
})
#----------------------------------------------------------------------------------

#----------------------------------------------------------------------------------
# File choice
output$kc_fnf_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'kc_fnf_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$kc_fnf_shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$kc_fnf_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})
#----------------------------------------------------------------------------------


#---------------------------------------------------------------------------
# reactive values and observe events
kc_fnf_values <- reactiveValues(kc_fnf_pro = 0, kc_fnf_abort = 0, kc_fnf_log = 0)

# we create the reactive behaviour
observeEvent(input$kc_fnf_pro_btn, {
  kc_fnf_values$kc_fnf_pro = 1
  kc_fnf_values$kc_fnf_abort = 0
  kc_fnf_values$kc_fnf_log = 1
})

observeEvent(input$kc_fnf_abort_btn, {
  kc_fnf_values$kc_fnf_pro = 0
  kc_fnf_values$kc_fnf_abort = 1
})

#observeEvent(input$kc_fnf_log_btn, {
#  kc_fnf_values$kc_fnf_log = 1
#})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
kc_fnf_get_state = function() {
  
  if(!exists("kc_fnf_args"))
    return("INITIAL")
  else {
    
    # get the pid
    kc_fnf_pid_cmd=paste("-ef | grep \"sh -c ( post_ALOS_KC_FNF", kc_fnf_args, "\" | grep -v grep | awk '{print $2}'")
    kc_fnf_pid = as.integer(system2("ps", args = kc_fnf_pid_cmd, stdout = TRUE))
  }
  
  if (length(kc_fnf_pid) > 0)
    return("RUNNING")
  
  if (file.exists(kc_fnf_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# get the input arguments from the GUI
kc_fnf_get_args = function(){
  
  # check if processing directory is chosen
  if (is.null(input$kc_fnf_directory)){
    kc_fnf_dir_message=" Project directory not selected"
    kc_fnf_js_string <- 'alert("Attention");'
    kc_fnf_js_string <- sub("Attention",kc_fnf_dir_message,kc_fnf_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_fnf_js_string))
    kc_fnf_values$kc_fnf_pro = 0
    kc_fnf_values$kc_fnf_log = 0
    return("INPUT_FAIL")
  } 
  
  else if ((input$kc_fnf_AOI == "AOI_shape_local")&(is.null(input$kc_fnf_shapefile))){
    kc_fnf_dir_message=" AOI shapefile not selected"
    kc_fnf_js_string <- 'alert("Attention");'
    kc_fnf_js_string <- sub("Attention",kc_fnf_dir_message,kc_fnf_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_fnf_js_string))
    kc_fnf_values$kc_fnf_pro = 0
    kc_fnf_values$kc_fnf_log = 0
    return("INPUT_FAIL")
  }
  
  else if ((input$kc_fnf_AOI == "AOI_zip_upload")&(is.null(input$kc_fnf_zipfile_path))){
    kc_fnf_dir_message="AOI zip-archive not selected"
    kc_fnf_js_string <- 'alert("Attention");'
    kc_fnf_js_string <- sub("Attention",kc_fnf_dir_message,kc_fnf_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_fnf_js_string))
    kc_fnf_values$kc_fnf_pro = 0
    kc_fnf_values$kc_fnf_log = 0
    return("INPUT_FAIL")
  }
  
  else {
    # get project folder input
    volumes = c('User directory'=Sys.getenv("HOME"))
    kc_fnf_dir <<- parseDirPath(volumes, input$kc_fnf_directory)
    
    # get AOI (dependent on AOI type)      
    if (input$kc_fnf_AOI == "country"){
      db_file=Sys.getenv("OST_DB")
      # get iso3
      db = dbConnect(SQLite(),dbname=db_file)
      query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$kc_fnf_countryname)
      kc_fnf_aoi_set = dbGetQuery(db,query)
      dbDisconnect(db)
    }
    
    else if (input$kc_fnf_AOI == "AOI_shape_local"){
      df = parseFilePaths(volumes, input$kc_fnf_shapefile)
      kc_fnf_aoi_set = as.character(df[,"datapath"])
    } 
    
    else if (input$kc_fnf_AOI == "AOI_zip_upload"){
      df = input$kc_fnf_zipfile_path
      print(df)
      ARCHIVE = df$datapath
      print(ARCHIVE)
      OUT_ARCHIVE = paste(DIR, "/AOI", sep = "")
      print(OUT_ARCHIVE)
      dir.create(OUT_ARCHIVE)
      unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
      AOI_SHP=list.files(OUT_ARCHIVE, pattern = "*.shp")
      kc_fnf_aoi_set = paste(OUT_ARCHIVE,"/",AOI_SHP,sep = "")
    } 
    
    # get year from input
    kc_fnf_year_set = input$kc_fnf_year
    
    # handling username and password data
    UNAME = input$kc_fnf_uname
    PW = input$kc_fnf_piwo
    FILENAME = paste(".",randomStrings(1, 20), sep = "")
    HOME_DIR = Sys.getenv("HOME")
    kc_fnf_file = file.path(HOME_DIR,FILENAME)
    write(UNAME, kc_fnf_file)
    write(PW, kc_fnf_file, append = TRUE)
    rm(UNAME)
    rm(PW)
    
    # print command
    kc_fnf_args <<- paste(kc_fnf_dir, kc_fnf_aoi_set, kc_fnf_year_set, kc_fnf_file)
    
    # define exitfile path
    kc_fnf_exitfile <<- paste(kc_fnf_dir, "/.kc_fnf_exitfile", sep="")
    
    kc_fnf_tmp <<- paste(kc_fnf_dir, "/.TMP", kc_fnf_year_set, sep = "")
    
    # return updated state
    return("NOT_STARTED") 
  }
}

#---------------------------------------------------------------------------
# Processing functions
kc_fnf_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("kc_fnf_pro_btn", {
    
    kc_fnf_message="Processing started (This will take a while.)"
    js_string_kc_dow <- 'alert("Processing");'
    js_string_kc_dow <- sub("Processing",kc_fnf_message,js_string_kc_dow)
    session$sendCustomMessage(type='jsCode', list(value = js_string_kc_dow))
    
    #print(paste("( post_ALOS_KC_download", kc_fnf_args, "; echo $? >", kc_fnf_exitfile, ")"))
    system(paste("( post_ALOS_KC_FNF", kc_fnf_args, "; echo $? >", kc_fnf_exitfile, ")"), wait = FALSE, intern = FALSE)
    
    return("RUNNING")
  })
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Termination Function (what to do when script stopped)
kc_fnf_term = function() {
  
  # get the exit state of the script
  kc_fnf_status = readLines(kc_fnf_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(kc_fnf_exitfile, force = TRUE)

  # message when all downloads finished/failed
  if (kc_fnf_status == 11 ){
    kc_fnf_end_message="Your downloaded data tiles seem to be corrupted. Delete the files and re-download them."
    kc_fnf_end_js_string <- 'alert("SUCCESS");'
    kc_fnf_end_js_string <- sub("SUCCESS",kc_fnf_end_message,kc_fnf_end_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_fnf_end_js_string))  
  }
  # message when all downloads finished/failed
  else
  if ( kc_fnf_status != 0 ){
    kc_fnf_end_message="Download or processing failed. Please try again!"
    kc_fnf_js_string <- 'alert("SUCCESS");'
    kc_fnf_js_string <- sub("SUCCESS",kc_fnf_end_message,kc_fnf_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_fnf_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    kc_fnf_fin_message="Download & processing finished"
    js_string_kc_fnf_fin <- 'alert("Processing");'
    js_string_kc_fnf_fin <- sub("Processing",kc_fnf_fin_message,js_string_kc_fnf_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_kc_fnf_fin))
  }
  
  # reset button to 0 for enable re-start
  kc_fnf_values$kc_fnf_pro = 0
}  
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Processing and Abort function
output$process_KC_fnf = renderText({
  
  # trigger processing when action button clicked
  if(kc_fnf_values$kc_fnf_pro) {
    
    #run the state function
    kc_fnf_state = kc_fnf_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    print(paste("1",kc_fnf_state))
    
    if (kc_fnf_state == "INITIAL"){
      kc_fnf_values$kc_fnf_log = 0
      kc_fnf_state = kc_fnf_get_args()
      unlink(paste(kc_fnf_dir, "/.kc_fnf_progress", sep = ""))
    }
    
    if (kc_fnf_state == "NOT_STARTED"){
      kc_fnf_state = kc_fnf_start()
      Sys.sleep(2)
      kc_fnf_values$kc_fnf_log = 1
    }
    
    if (kc_fnf_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (kc_fnf_state == "TERMINATED")
      kc_fnf_term()
    
    print("")
  } # close value process    
  
  if(kc_fnf_values$kc_fnf_abort) {
    
    # delete the exit file
    unlink(kc_fnf_exitfile)
    
    # cancel the
    print(paste("ost_cancel_proc \"sh -c ( post_ALOS_KC_FNF", kc_fnf_args, "\"", kc_fnf_tmp))
    system(paste("ost_cancel_proc \"sh -c ( post_ALOS_KC_FNF", kc_fnf_args, "\"", kc_fnf_tmp))
    
    kc_fnf_dir_message="User interruption"
    kc_fnf_js_string <- 'alert("Attention");'
    kc_fnf_js_string <- sub("Attention",kc_fnf_dir_message,kc_fnf_js_string)
    session$sendCustomMessage(type='jsCode', list(value = kc_fnf_js_string))
    print("")
  }
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Progress monitor function
output$kc_fnf_progress = renderText({
  
  if(kc_fnf_values$kc_fnf_log) {
    
    kc_fnf_progress_file=file.path(kc_fnf_dir, "/.kc_fnf_progress")
    
    if(file.exists(kc_fnf_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", kc_fnf_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(kc_fnf_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------