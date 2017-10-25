# 1 Choose a local folder 
output$s1_inv_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_inv_directory', roots=volumes)
  
  validate (
    need(input$s1_inv_directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_inv_directory)
  cat(df) 
})

# Choose a local file
output$s1_inv_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 's1_inv_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
  need(input$s1_inv_shapefile != "","No shapefile selected"),
  errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$s1_inv_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})


#------------------------------------------------------------------------------------------------
# main function calling the CL script

# we create some values for reactive behaviour
s1_inv_values <- reactiveValues(s1_inv_pro = 0, s1_inv_abort = 0, s1_inv_log = 0)

# we create the reactive behaviour
observeEvent(input$s1_inv_pro_btn, {
  s1_inv_values$s1_inv_pro = 1
  s1_inv_values$s1_inv_abort = 0
  s1_inv_values$s1_inv_log = 1
})

observeEvent(input$s1_inv_abort_btn, {
  s1_inv_values$s1_inv_pro = 0
  s1_inv_values$s1_inv_abort = 1
})

#observeEvent(input$s1_inv_log_btn, {
#  s1_inv_values$s1_inv_log = 1
#})

# a function that returns the currrent state based on pid and exit file
s1_inv_get_state = function() {
  
  if(!exists("s1_inv_args"))
    return("INITIAL")
  else {
    # get the pid
    s1_inv_pid_cmd=paste("-ef | grep \"sh -c ( ost_S1_ASF_inventory", s1_inv_args, "\" | grep -v grep | awk '{print $2}'")
    s1_inv_pid = as.integer(system2("ps", args = s1_inv_pid_cmd, stdout = TRUE))
  }
  
  #pid = as.integer(system2("ps", args = "-ef | grep \"sh -c ( ost_S1_ASF_inventory\" | grep -v grep | awk '{print $2}'", stdout = TRUE))
  
  if (length(s1_inv_pid) > 0)
    return("RUNNING")
  
  if (file.exists(s1_inv_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 

#---------------------------------------------------------------------------
# get the input arguments from the GUI
s1_inv_get_args = function(){
  
  # check if necessary fields are filled
  if (is.null(input$s1_inv_directory)){
    s1_inv_dir_message=" No project directory selected."
    s1_inv_js_string <- 'alert("Attention");'
    s1_inv_js_string <- sub("Attention",s1_inv_dir_message,s1_inv_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_inv_js_string))
    s1_inv_values$s1_inv_pro = 0
    s1_inv_values$s1_inv_log = 0
    return("INPUT_FAIL")
  }
  
  else if ((input$s1_inv_AOI == "s1_inv_shape_local")&(is.null(input$s1_inv_shapefile))){
    s1_inv_dir_message=" No AOI shapefile selected."
    s1_inv_js_string <- 'alert("Attention");'
    s1_inv_js_string <- sub("Attention",s1_inv_dir_message,s1_inv_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_inv_js_string))
    s1_inv_values$s1_inv_pro = 0
    s1_inv_values$s1_inv_log = 0
    return("INPUT_FAIL")
  }
  
  else if ((input$s1_inv_AOI == "s1_inv_shape_upload")&(is.null(input$s1_inv_shapefile_path))){
    s1_inv_dir_message=" No AOI zip-archive selected."
    s1_inv_js_string <- 'alert("Attention");'
    s1_inv_js_string <- sub("Attention",s1_inv_dir_message,s1_inv_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_inv_js_string))
    s1_inv_values$s1_inv_pro = 0
    s1_inv_values$s1_inv_log = 0
    return("INPUT_FAIL")
  }
  
  else { # run the whole thing
    
    # get project folder input
    volumes = c('User directory'=Sys.getenv("HOME"))
    s1_inv_dir <<- parseDirPath(volumes, input$s1_inv_directory)
    
    # get AOI (dependent on AOI type)      
    if (input$s1_inv_AOI == "s1_inv_country"){
      db_file=Sys.getenv("OST_DB")
      # get iso3
      db = dbConnect(SQLite(),dbname=db_file)
      query = sprintf("SELECT iso3 FROM countries WHERE name='%s'", input$s1_inv_countryname)
      s1_inv_aoi = dbGetQuery(db,query)
      dbDisconnect(db)
    } 
    
    else if (input$s1_inv_AOI == "s1_inv_shape_local"){
      df = parseFilePaths(volumes, input$s1_inv_shapefile)
      s1_inv_aoi = as.character(df[,"datapath"])
    }
    
    else if (input$s1_inv_AOI == "s1_inv_shape_upload"){
      df = input$s1_inv_shapefile_path
      ARCHIVE = df$datapath
      OUT_ARCHIVE = paste(s1_inv_dir, "/AOI_upload", sep = "")
      dir.create(OUT_ARCHIVE)
      unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
      OST_inv=list.files(OUT_ARCHIVE, pattern = "*.shp")
      s1_inv_aoi = paste(OUT_ARCHIVE,"/",OST_inv,sep = "")
    } 
    
    # get year from input
    s1_inv_start = input$s1_inv_daterange[1]
    s1_inv_end = input$s1_inv_daterange[2]
    
    # choice of the sensor polarisation
    if (input$s1_inv_pol == "dual_vv"){
      s1_inv_polar = "2" 
    } 
    
    else if (input$s1_inv_pol == "vv"){
      s1_inv_polar = "3" 
    }
    
    else if (input$s1_inv_pol == "dual_single_vv"){
      s1_inv_polar = "1" 
    }
    
    else if (input$s1_inv_pol == "dual_hh"){
      s1_inv_polar = "5" 
    }
    
    else if (input$s1_inv_pol == "hh"){
      s1_inv_polar = "6" 
    }
    
    else if (input$s1_inv_pol == "dual_single_hh"){
      s1_inv_polar = "4" 
    }
    
    # choice of the sensor mode
    if (input$s1_inv_sensor_mode == "iw"){
      s1_inv_mode = "IW" 
    }
    
    else if (input$s1_inv_sensor_mode == "ew"){
      s1_inv_mode = "EW" 
    } 
    
    else if (input$s1_inv_sensor_mode == "wv"){
      s1_inv_mode = "WV" 
    } 
    
    # choice of the product level
    if (input$s1_inv_product_level == "grd"){
      s1_inv_plevel = "GRD" 
    }
    
    else if (input$s1_inv_product_level == "slc"){
      s1_inv_plevel = "SLC" 
    } 
    
    else if (input$s1_inv_product_level == "raw"){
      s1_inv_plevel = "RAW" 
    } 
    # create arguments for command execution and export as global variable
    s1_inv_args <<- paste(s1_inv_dir, s1_inv_aoi, s1_inv_start, s1_inv_end, s1_inv_mode, s1_inv_plevel, s1_inv_polar, "0")
    
    # create a exitfile path and export as global variable
    s1_inv_exitfile <<- paste(s1_inv_dir, "/.s1_inv_exitfile", sep="")
    
    # return new state
    return("NOT_STARTED")
    
  }
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# start fucntion that runs the processing 
s1_inv_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_inv_search", {
    
    # Pop-up message for starting data inventory
    s1_search_message="Looking for available data"
    js_string_s1_search <- 'alert("Inventory");'
    js_string_s1_search <- sub("Inventory",s1_search_message,js_string_s1_search)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_search))
    
    # run processing
    print(paste("ost_S1_ASF_inventory", s1_inv_args), intern=FALSE)
    #system2("/bin/bash", args = c("-c ( ost_S1_ASF_inventory", s1_inv_args, "; echo $? >", s1_inv_exitfile, ")"), wait = FALSE)
    system(paste("( ost_S1_ASF_inventory", s1_inv_args, "; echo $? >", s1_inv_exitfile, ")"), wait = FALSE, intern=FALSE)
    
    return("RUNNING")
  })  
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# when processing is script is finished we want to check if everything went fine
s1_inv_term = function() {
  
  # get the exit state of the script
  s1_inv_status = readLines(s1_inv_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(s1_inv_exitfile, force = TRUE)
  
  # message when all downloads finished/failed
  if ( s1_inv_status != 0 ){
    s1_inv_end_message="No products have been found for the given search parameters."
    s1_inv_js_string <- 'alert("SUCCESS");'
    s1_inv_js_string <- sub("SUCCESS",s1_inv_end_message,s1_inv_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_inv_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    s1_inv_cmd=paste("cat", file.path(s1_inv_dir, "/.s1_inv_progress"), "| grep Info: | awk '{print $4}'") 
    s1_inv_nr_of_prd=system(s1_inv_cmd , intern = TRUE)
    msg=paste("Search resulted", s1_inv_nr_of_prd, "products!")
    s1_found_message=msg
    js_string_s1_found <- 'alert("Finished");'
    js_string_s1_found <- sub("Finished",s1_found_message,js_string_s1_found)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_found))
    
  }
  # reset button to 0 for enable re-start
  s1_inv_values$s1_inv_pro = 0
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# run the main processing fuction
output$s1_inv = renderText({
  
  # trigger processing when action button clicked
  if(s1_inv_values$s1_inv_pro) {
    
    #run the state function
    s1_inv_state = s1_inv_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    
    if (s1_inv_state == "INITIAL"){
      s1_inv_state = s1_inv_get_args()
      unlink(paste(s1_inv_dir, "/.s1_inv_progress"))
      s1_inv_values$s1_inv_log = 0
    }
    
    if (s1_inv_state == "NOT_STARTED"){
      s1_inv_state = s1_inv_start()
      Sys.sleep(2)
      s1_inv_values$s1_inv_log = 1
    }
    
    if (s1_inv_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (s1_inv_state == "TERMINATED")
      s1_inv_term()
    
    print("")
  } # close value process    
  
  if(s1_inv_values$s1_inv_abort) {
    
    # delete the exit file
    unlink(s1_inv_exitfile)
    
    print(paste("ost_cancel_proc ost_S1_ASF_inventory", s1_inv_args, paste(s1_inv_dir, "/.TMP", sep = "")))
    system(paste("ost_cancel_proc \"sh -c ( ost_S1_ASF_inventory", s1_inv_args, "\"", paste(s1_inv_dir, "/.TMP", sep = "")))
    s1_inv_dir_message="User interruption"
    s1_inv_js_string <- 'alert("Attention");'
    s1_inv_js_string <- sub("Attention",s1_inv_dir_message,s1_inv_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_inv_js_string))
    print("")
  }
  
})  # close render text function 
#------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------
# progress monitor trigger
output$s1_inv_progress = renderText({
  
  if(s1_inv_values$s1_inv_log) {
    
    s1_inv_progress_file=file.path(s1_inv_dir, "/.s1_inv_progress")
    
    if(file.exists(s1_inv_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", s1_inv_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(s1_inv_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------