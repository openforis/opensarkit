#---------------------------------------------------------------------------
# 1 Choose a folders or files locally within your home directory with shinyFiles package
output$srtm_dow_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  # Directory choice
  shinyDirChoose(input, 'srtm_dow_directory', roots=volumes)
  
  validate (
    need(input$srtm_dow_directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$srtm_dow_directory)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# File choice
output$srtm_dow_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'srtm_dow_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$srtm_dow_shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$srtm_dow_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# reactive values and observe events
srtm_dow_values <- reactiveValues(srtm_dow_pro = 0, srtm_dow_abort = 0, srtm_dow_log = 0)

# we create the reactive behaviour
observeEvent(input$srtm_dow_pro_btn, {
  srtm_dow_values$srtm_dow_pro = 1
  srtm_dow_values$srtm_dow_abort = 0
  srtm_dow_values$srtm_dow_log = 1
})

observeEvent(input$srtm_dow_abort_btn, {
  srtm_dow_values$srtm_dow_pro = 0
  srtm_dow_values$srtm_dow_abort = 1
})

#observeEvent(input$srtm_dow_log_btn, {
#  srtm_dow_values$srtm_dow_log = 1
#})
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
srtm_dow_get_state = function() {
  
  if(!exists("srtm_dow_args"))
    return("INITIAL")
  else {
    
    # get the pid
    srtm_dow_pid_cmd=paste("-ef | grep \"sh -c ( ost_SRTM4_download", srtm_dow_args, "\" | grep -v grep | awk '{print $2}'")
    srtm_dow_pid = as.integer(system2("ps", args = srtm_dow_pid_cmd, stdout = TRUE))
  }
  
  if (length(srtm_dow_pid) > 0)
    return("RUNNING")
  
  if (file.exists(srtm_dow_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# get the input arguments from the GUI
srtm_dow_get_args = function(){
  
  # check if processing directory is chosen
  if (is.null(input$srtm_dow_directory)){
    srtm_dow_dir_message=" Output directory not selected"
    srtm_dow_js_string <- 'alert("Attention");'
    srtm_dow_js_string <- sub("Attention",srtm_dow_dir_message,srtm_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = srtm_dow_js_string))
    srtm_dow_values$srtm_dow_pro = 0
    srtm_dow_values$srtm_dow_log = 0
    return("INPUT_FAIL")
  } 
  
  else if ((input$srtm_dow_AOI == "SRTM_AOI_shape_local")&(is.null(input$srtm_dow_shapefile))){
    srtm_dow_dir_message=" AOI shapefile not selected"
    srtm_dow_js_string <- 'alert("Attention");'
    srtm_dow_js_string <- sub("Attention",srtm_dow_dir_message,srtm_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = srtm_dow_js_string))
    srtm_dow_values$srtm_dow_pro = 0
    srtm_dow_values$srtm_dow_log = 0
    return("INPUT_FAIL")
  }
  
  else if ((input$srtm_dow_AOI == "SRTM_AOI_zip_upload")&(is.null(input$srtm_dow_zipfile_path))){
    srtm_dow_dir_message=" AOI zip archive not selected"
    srtm_dow_js_string <- 'alert("Attention");'
    srtm_dow_js_string <- sub("Attention",srtm_dow_dir_message,srtm_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = srtm_dow_js_string))
    srtm_dow_values$srtm_dow_pro = 0
    srtm_dow_values$srtm_dow_log = 0
    return("INPUT_FAIL")
  }
  
  else {
    # get project folder input
    volumes = c('User directory'=Sys.getenv("HOME"))
    srtm_dow_dir <<- parseDirPath(volumes, input$srtm_dow_directory)
    
    # get AOI (dependent on AOI type)      
    if (input$srtm_dow_AOI == "country"){
      db_file=Sys.getenv("OST_DB")
      # get iso3
      db = dbConnect(SQLite(),dbname=db_file)
      query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$srtm_dow_countryname)
      srtm_dow_aoi = dbGetQuery(db,query)
      dbDisconnect(db)
    }
    
    else if (input$srtm_dow_AOI == "SRTM_AOI_shape_local"){
      df = parseFilePaths(volumes, input$srtm_dow_shapefile)
      srtm_dow_aoi = as.character(df[,"datapath"])
      #print(srtm_dow_aoi)
    } 
    
    else if (input$srtm_dow_AOI == "SRTM_AOI_zip_upload"){
      df = input$srtm_dow_zipfile_path
      print(df)
      ARCHIVE = df$datapath
      print(ARCHIVE)
      OUT_ARCHIVE = paste(srtm_dow_dir, "/AOI", sep = "")
      print(OUT_ARCHIVE)
      dir.create(OUT_ARCHIVE)
      unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
      AOI_SHP=list.files(OUT_ARCHIVE, pattern = "*.shp")
      srtm_dow_aoi = paste(OUT_ARCHIVE,"/",AOI_SHP,sep = "")
    } 
    
    # topograpic indices
    srtm_dow_mode = input$srtm_dow_ind
    
    # data type
    srtm_dow_type = input$srtm_dow_type
    
    # get the arguments
    srtm_dow_args <<- paste(srtm_dow_dir, srtm_dow_aoi, srtm_dow_mode, srtm_dow_type)
    
    # define exitfile path
    srtm_dow_exitfile <<- paste(srtm_dow_dir, "/.srtm_dow_exitfile", sep="")
    
    srtm_dow_tmp <<- paste(srtm_dow_dir, "/.TMP", sep = "")
    
    # return updated state
    return("NOT_STARTED")
  }
}

#---------------------------------------------------------------------------
# Processing functions
srtm_dow_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("srtm_dow_pro_btn", {
    
    srtm_dow_message="Download started (This will take a while.)"
    js_string_srtm_dow <- 'alert("Downloading");'
    js_string_srtm_dow <- sub("Downloading",srtm_dow_message,js_string_srtm_dow)
    session$sendCustomMessage(type='jsCode', list(value = js_string_srtm_dow))
    #print(paste("( ost_SRTM4_download", srtm_dow_args, "; echo $? >", srtm_dow_exitfile, ")"), wait = FALSE, intern = FALSE)
    system(paste("( ost_SRTM4_download", srtm_dow_args, "; echo $? >", srtm_dow_exitfile, ")"), wait = FALSE, intern = FALSE)
    
    return("RUNNING")
  })
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Processing and Abort function
output$process_SRTM = renderText({
  
  # trigger processing when action button clicked
  if(srtm_dow_values$srtm_dow_pro) {
    
    #run the state function
    srtm_dow_state = srtm_dow_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    
    if (srtm_dow_state == "INITIAL"){
      srtm_dow_values$srtm_dow_log = 0
      srtm_dow_state = srtm_dow_get_args()
      unlink(paste(srtm_dow_dir, "/.srtm_dow_progress", sep = ""))
    }
    
    if (srtm_dow_state == "NOT_STARTED"){
      srtm_dow_state = srtm_dow_start()
      Sys.sleep(2)
      srtm_dow_values$srtm_dow_log = 1
    }
    
    if (srtm_dow_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (srtm_dow_state == "TERMINATED")
      srtm_dow_term()
    
    print("")
  } # close value process    
  
  if(srtm_dow_values$srtm_dow_abort) {
    
    # delete the exit file
    unlink(srtm_dow_exitfile)
    
    # cancel the
    #print(paste("ost_cancel_proc \"sh -c ( ost_SRTM4_download", srtm_dow_args, "\"", srtm_dow_tmp))
    system(paste("ost_cancel_proc \"sh -c ( ost_SRTM4_download", srtm_dow_args, "\"", srtm_dow_tmp))
    
    srtm_dow_dir_message="User interruption"
    srtm_dow_js_string <- 'alert("Attention");'
    srtm_dow_js_string <- sub("Attention",srtm_dow_dir_message,srtm_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = srtm_dow_js_string))
    print("")
  }
  
  
})
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# Progress monitor function
output$srtm_dow_progress = renderText({
  
  if(srtm_dow_values$srtm_dow_log) {
    
    srtm_dow_progress_file=file.path(srtm_dow_dir, "/.srtm_dow_progress")
    
    if(file.exists(srtm_dow_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", srtm_dow_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(srtm_dow_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------

