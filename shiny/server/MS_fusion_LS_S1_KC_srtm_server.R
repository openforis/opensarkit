#---------------------------------------------------------------------------
# Functions for Original File choice

# Choose a Lsat file
output$ms2_lsat_file = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'ms2_lsat_file', roots=volumes, filetypes=c('vrt','tif'))
  
  validate (
    need(input$ms2_lsat_file != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$ms2_lsat_file)
  ms2_lsat_file_path = as.character(df[,"datapath"])
  cat(ms2_lsat_file_path)
})

# Choose a S1 zstack
output$ms2_s1_file = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'ms2_s1_file', roots=volumes, filetypes=c('vrt','tif'))
  
  validate (
    need(input$ms2_s1_file != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$ms2_s1_file)
  ms2_s1_file_path = as.character(df[,"datapath"])
  cat(ms2_s1_file_path)
})

# Choose a ALOS stack file
output$ms2_alos_file = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'ms2_alos_file', roots=volumes, filetypes=c('vrt','tif'))
  
  validate (
    need(input$ms2_alos_file != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$ms2_alos_file)
  ms2_alos_file_path = as.character(df[,"datapath"])
  cat(ms2_alos_file_path)
})

# Choose a SRTM stack file
output$ms2_srtm_file = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'ms2_srtm_file', roots=volumes, filetypes=c('vrt','tif'))
  
  validate (
    need(input$ms2_srtm_file != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$ms2_srtm_file)
  ms2_srtm_file_path = as.character(df[,"datapath"])
  cat(ms2_srtm_file_path)
})

# output folder 
output$ms_ls_s1_kc_srtm_outdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 'ms_ls_s1_kc_srtm_outdir', roots=volumes)
  
  validate (
    need(input$ms_ls_s1_kc_srtm_outdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$ms_ls_s1_kc_srtm_outdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# reactive values and observe events
# we create some values for reactive behaviour
ms_ls_s1_kc_srtm_values <- reactiveValues(ms_ls_s1_kc_srtm_pro = 0, ms_ls_s1_kc_srtm_abort = 0, ms_ls_s1_kc_srtm_log = 0)

# we create the reactive behaviour
observeEvent(input$ms_ls_s1_kc_srtm_pro_btn, {
  ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_pro = 1
  ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_abort = 0
  ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log = 1
})

observeEvent(input$ms_ls_s1_kc_srtm_abort_btn, {
  ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_pro = 0
  ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_abort = 1
})

#observeEvent(input$ms_ls_s1_kc_srtm_log_btn, {
#  ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log = 1
#})
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
ms_ls_s1_kc_srtm_get_state = function() {
  
  if(!exists("ms_ls_s1_kc_srtm_args"))
    return("INITIAL")
  else {
    # get the pid
    ms_ls_s1_kc_srtm_pid_cmd=paste("-ef | grep \"sh -c ( ost_multi_sensor_ls_s1_kc_srtm", ms_ls_s1_kc_srtm_args, "\" | grep -v grep | awk '{print $2}'")
    
    ms_ls_s1_kc_srtm_pid = as.integer(system2("ps", args = ms_ls_s1_kc_srtm_pid_cmd, stdout = TRUE))
  }
  
  if (length(ms_ls_s1_kc_srtm_pid) > 0)
    return("RUNNING")
  
  if (file.exists(ms_ls_s1_kc_srtm_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# get the input arguments from the GUI
ms_ls_s1_kc_srtm_get_args = function(){
  
  # empty input file message
    if(is.null(input$ms2_lsat_file)){
      ms2_lsat_file_message=" No Landsat stack has been selected"
      ms_lsat_js_string <- 'alert("Attention");'
      ms_lsat_js_string <- sub("Attention",ms2_lsat_file_message, ms_lsat_js_string)
      session$sendCustomMessage(type='jsCode', list(value =  ms_lsat_js_string))
      ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_pro = 0
      ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log = 0
      return("INPUT_FAIL")
    } 
    
  # empty s1 message
  else if(is.null(input$ms2_s1_file)){
    ms2_s1_file_message=" No Sentinel-1 stack has been selected"
    ms_s1_js_string <- 'alert("Attention");'
    ms_s1_js_string <- sub("Attention",ms2_s1_file_message, ms_s1_js_string)
    session$sendCustomMessage(type='jsCode', list(value =  ms_s1_js_string))
    ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_pro = 0
    ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log = 0
    return("INPUT_FAIL")
  }
   
  # empty kc message
  else if(is.null(input$ms2_alos_file)){
    ms_kc_file_message=" No ALOS K&C stack has been selected"
    ms_kc_js_string <- 'alert("Attention");'
    ms_kc_js_string <- sub("Attention",ms_kc_file_message, ms_kc_js_string)
    session$sendCustomMessage(type='jsCode', list(value =  ms_kc_js_string))
    ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_pro = 0
    ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log = 0
    return("INPUT_FAIL")
  } 
   
  # empty srtm message
  else if(is.null(input$ms2_srtm_file)){
    ms_srtm_file_message=" No SRTM stack has been selected"
    ms_srtm_js_string <- 'alert("Attention");'
    ms_srtm_js_string <- sub("Attention",ms_srtm_file_message, ms_srtm_js_string)
    session$sendCustomMessage(type='jsCode', list(value =  ms_srtm_js_string))
    ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_pro = 0
    ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log = 0
    return("INPUT_FAIL")
  }
  
  # empty output directy message
  else if(is.null(input$ms_ls_s1_kc_srtm_outdir)){
    ms_ls_kc_s1_dir_message=" No output folder selected"
    ms_ls_kc_s1_js_string <- 'alert("Attention");'
    ms_ls_kc_s1_js_string <- sub("Attention",ms_ls_kc_s1_dir_message,ms_ls_kc_s1_js_string)
    session$sendCustomMessage(type='jsCode', list(value = ms_ls_kc_s1_js_string))
    ms_ls_kc_s1_values$ms_ls_kc_s1_pro = 0
    ms_ls_kc_s1_values$ms_ls_kc_s1_log = 0
    return("INPUT_FAIL")
  }
  
  # processing
  else {
  
    volumes = c('User directory'=Sys.getenv("HOME"))
    
    ms_lsat_df = parseFilePaths(volumes, input$ms2_lsat_file)
    ms_lsat_infile = as.character(ms_lsat_df[,"datapath"])
    
    ms_ls_s1_kc_srtm_lsatind = input$ms_ls_s1_kc_srtm_lsatind
    
    ms_s1_df = parseFilePaths(volumes, input$ms2_s1_file)
    ms_s1_infile = as.character(ms_s1_df[,"datapath"])
    
    ms_kc_df = parseFilePaths(volumes, input$ms2_alos_file)
    ms_kc_infile = as.character(ms_kc_df[,"datapath"])
    
    ms_srtm_df = parseFilePaths(volumes, input$ms2_srtm_file)
    ms_srtm_infile = as.character(ms_srtm_df[,"datapath"])
    
    ms_ls_s1_kc_srtm_dir <<- parseDirPath(volumes, input$ms_ls_s1_kc_srtm_outdir)      
    #ms_ls_s1_kc_srtm_outfile = paste(ms_ls_s1_kc_srtm_dir,"/ms_sensor_stack.vrt",sep="")
    ms_ls_s1_kc_srtm_args<<- paste(ms_lsat_infile, ms_s1_infile, ms_kc_infile, ms_srtm_infile, ms_ls_s1_kc_srtm_dir, ms_ls_s1_kc_srtm_lsatind )
  
    # create a exitfile path and export as global variable
    ms_ls_s1_kc_srtm_exitfile <<- paste(ms_ls_s1_kc_srtm_dir, "/.exitfile", sep="")
    
    ms_ls_s1_kc_srtm_tmp <<- paste(ms_ls_s1_kc_srtm_dir, "/.TMP")
    
    # return new state
    return("NOT_STARTED")
    
  }
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# start function that triggers the processing 
ms_ls_s1_kc_srtm_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("ms_ls_s1_kc_srtm_pro_btn", {
    
    ms_ls_s1_kc_srtm_message="Processing started (This can take a moment)"
    js_string_ms_ls_s1_kc <- 'alert("Processing");'
    js_string_ms_ls_s1_kc <- sub("Processing",ms_ls_s1_kc_srtm_message,js_string_ms_ls_s1_kc)
    session$sendCustomMessage(type='jsCode', list(value = js_string_ms_ls_s1_kc))
      
    # run processing
    print(paste("( ost_multi_sensor_ls_s1_kc_srtm", ms_ls_s1_kc_srtm_args, "; echo $? >", ms_ls_s1_kc_srtm_exitfile, ")"))
    system(paste("( ost_multi_sensor_ls_s1_kc_srtm", ms_ls_s1_kc_srtm_args, "; echo $? >", ms_ls_s1_kc_srtm_exitfile, ")"), wait = FALSE, intern=FALSE)
    return("RUNNING")     
  })
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Termination Function (what to do when script stopped)
ms_ls_s1_kc_srtm_term = function() {
  
  # get the exit state of the script
  ms_ls_s1_kc_srtm_status = readLines(ms_ls_s1_kc_srtm_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(ms_ls_s1_kc_srtm_exitfile, force = TRUE)
  
  # message when all downloads finished/failed
  if ( ms_ls_s1_kc_srtm_status != 0 ){
    ms_ls_s1_kc_srtm_end_message="Processing failed. Check the Progress Monitor."
    ms_ls_s1_kc_srtm_js_string <- 'alert("SUCCESS");'
    ms_ls_s1_kc_srtm_js_string <- sub("SUCCESS",ms_ls_s1_kc_srtm_end_message,ms_ls_s1_kc_srtm_js_string)
    session$sendCustomMessage(type='jsCode', list(value = ms_ls_s1_kc_srtm_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    ms_ls_s1_kc_srtm_fin_message="Processing finished"
    js_string_ms_ls_s1_kc_srtm_fin <- 'alert("Processing");'
    js_string_ms_ls_s1_kc_srtm_fin <- sub("Processing",ms_ls_s1_kc_srtm_fin_message,js_string_ms_ls_s1_kc_srtm_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_ms_ls_s1_kc_srtm_fin))
  }
  
  # reset button to 0 for enable re-start
  ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_pro = 0
}  
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# main function triggering processing and controlling state
output$processMS_ls_s1_kc_srtm = renderText({
  
  # trigger processing when action button clicked
  if(ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_pro) {
    
    #run the state function
    ms_ls_s1_kc_srtm_state = ms_ls_s1_kc_srtm_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    print(paste("state1",ms_ls_s1_kc_srtm_state))
    
    if (ms_ls_s1_kc_srtm_state == "INITIAL"){
      ms_ls_s1_kc_srtm_state = ms_ls_s1_kc_srtm_get_args()
      unlink(paste(ms_ls_s1_kc_srtm_dir, "/.ms_ls_s1_kc_srtm_progress"))
      ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log = 0
    }
    
    if (ms_ls_s1_kc_srtm_state == "NOT_STARTED"){
      ms_ls_s1_kc_srtm_state = ms_ls_s1_kc_srtm_start()
      print(paste("state3",ms_ls_s1_kc_srtm_state))
      Sys.sleep(2)
      ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log = 1
    }
    
    if (ms_ls_s1_kc_srtm_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (ms_ls_s1_kc_srtm_state == "TERMINATED")
      ms_ls_s1_kc_srtm_term()
    
    print("")
  } # close value process    
  
  if(ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_abort) {
    
    # delete the exit file
    unlink(ms_ls_s1_kc_srtm_exitfile)
    
    # check which temp folder
    if (dir.exists(paste(ms_ls_s1_kc_srtm_dir, "/.TMP")))
      ms_ls_s1_kc_srtm_tmp = paste(ms_ls_s1_kc_srtm_dir, "/.TMP")
    
    if (!dir.exists(paste(ms_ls_s1_kc_srtm_dir, "/.TMP")))
      ms_ls_s1_kc_srtm_tmp = "/ram/SAR_TMP"
    
    system(paste("ost_cancel_proc \"sh -c ( ost_multi_sensor_ls_s1_kc_srtm", ms_ls_s1_kc_srtm_args, "\"", ms_ls_s1_kc_srtm_tmp))
    
    ms_ls_s1_kc_srtm_dir_message="User interruption"
    ms_ls_s1_kc_srtm_js_string <- 'alert("Attention");'
    ms_ls_s1_kc_srtm_js_string <- sub("Attention",ms_ls_s1_kc_srtm_dir_message,ms_ls_s1_kc_srtm_js_string)
    session$sendCustomMessage(type='jsCode', list(value = ms_ls_s1_kc_srtm_js_string))
    print("")
  }
  
}) # close render function

#---------------------------------------------------------------------------  
# Progress monitor function
output$ms_ls_s1_kc_srtm_progress = renderText({
  
  if(ms_ls_s1_kc_srtm_values$ms_ls_s1_kc_srtm_log) {
    
    ms_ls_s1_kc_srtm_progress_file=file.path(ms_ls_s1_kc_srtm_dir, "/.ms_ls_s1_kc_srtm_progress")
    
    if(file.exists(ms_ls_s1_kc_srtm_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", ms_ls_s1_kc_srtm_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(ms_ls_s1_kc_srtm_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------
