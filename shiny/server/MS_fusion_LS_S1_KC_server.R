#---------------------------------------------------------------------------
# Functions for Original File choice

# Choose a Lsat file
output$ms1_lsat_file = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'ms1_lsat_file', roots=volumes, filetypes=c('vrt','tif'))
  
  validate (
    need(input$ms1_lsat_file != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$ms1_lsat_file)
  ms1_lsat_file_path = as.character(df[,"datapath"])
  cat(ms1_lsat_file_path)
})

# Choose a S1 zstack
output$ms1_s1_file = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'ms1_s1_file', roots=volumes, filetypes=c('vrt','tif'))
  
  validate (
    need(input$ms1_s1_file != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$ms1_s1_file)
  ms1_s1_file_path = as.character(df[,"datapath"])
  cat(ms1_s1_file_path)
})

# Choose a ALOS stack file
output$ms1_alos_file = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'ms1_alos_file', roots=volumes, filetypes=c('vrt','tif'))
  
  validate (
    need(input$ms1_alos_file != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$ms1_alos_file)
  ms1_alos_file_path = as.character(df[,"datapath"])
  cat(ms1_alos_file_path)
})

# output folder 
output$ms_ls_s1_kc_outdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 'ms_ls_s1_kc_outdir', roots=volumes)
  
  validate (
    need(input$ms_ls_s1_kc_outdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$ms_ls_s1_kc_outdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# reactive values and observe events
# we create some values for reactive behaviour
ms_ls_s1_kc_values <- reactiveValues(ms_ls_s1_kc_pro = 0, ms_ls_s1_kc_abort = 0, ms_ls_s1_kc_log = 0)

# we create the reactive behaviour
observeEvent(input$ms_ls_s1_kc_pro_btn, {
  ms_ls_s1_kc_values$ms_ls_s1_kc_pro = 1
  ms_ls_s1_kc_values$ms_ls_s1_kc_abort = 0
  ms_ls_s1_kc_values$ms_ls_s1_kc_log = 1
})

observeEvent(input$ms_ls_s1_kc_abort_btn, {
  ms_ls_s1_kc_values$ms_ls_s1_kc_pro = 0
  ms_ls_s1_kc_values$ms_ls_s1_kc_abort = 1
})

#observeEvent(input$ms_ls_s1_kc_log_btn, {
#  ms_ls_s1_kc_values$ms_ls_s1_kc_log = 1
#})
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
ms_ls_s1_kc_get_state = function() {
  
  if(!exists("ms_ls_s1_kc_args"))
    return("INITIAL")
  else {
    # get the pid
    ms_ls_s1_kc_pid_cmd=paste("-ef | grep \"sh -c ( ost_multi_sensor_ls_s1_kc", ms_ls_s1_kc_args, "\" | grep -v grep | awk '{print $2}'")
    
    ms_ls_s1_kc_pid = as.integer(system2("ps", args = ms_ls_s1_kc_pid_cmd, stdout = TRUE))
  }
  
  if (length(ms_ls_s1_kc_pid) > 0)
    return("RUNNING")
  
  if (file.exists(ms_ls_s1_kc_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# get the input arguments from the GUI
ms_ls_s1_kc_get_args = function(){
  
  # empty input file message
    if(is.null(input$ms1_lsat_file)){
      ms1_lsat_file_message=" No Landsat stack has been selected"
      ms_lsat_js_string <- 'alert("Attention");'
      ms_lsat_js_string <- sub("Attention",ms1_lsat_file_message, ms_lsat_js_string)
      session$sendCustomMessage(type='jsCode', list(value =  ms_lsat_js_string))
      ms_ls_s1_kc_values$ms_ls_s1_kc_pro = 0
      ms_ls_s1_kc_values$ms_ls_s1_kc_log = 0
      return("INPUT_FAIL")
    } 
    
  # empty s1 message
  else if(is.null(input$ms1_s1_file)){
    ms1_s1_file_message=" No Sentinel-1 stack has been selected"
    ms_s1_js_string <- 'alert("Attention");'
    ms_s1_js_string <- sub("Attention",ms1_s1_file_message, ms_s1_js_string)
    session$sendCustomMessage(type='jsCode', list(value =  ms_s1_js_string))
    ms_ls_s1_kc_values$ms_ls_s1_kc_pro = 0
    ms_ls_s1_kc_values$ms_ls_s1_kc_log = 0
    return("INPUT_FAIL")
  }
   
  # empty kc message
  else if(is.null(input$ms1_alos_file)){
    ms_kc_file_message=" No ALOS K&C stack has been selected"
    ms_kc_js_string <- 'alert("Attention");'
    ms_kc_js_string <- sub("Attention",ms_kc_file_message, ms_kc_js_string)
    session$sendCustomMessage(type='jsCode', list(value =  ms_kc_js_string))
    ms_ls_s1_kc_values$ms_ls_s1_kc_pro = 0
    ms_ls_s1_kc_values$ms_ls_s1_kc_log = 0
    return("INPUT_FAIL")
  } 
   
  # empty output directy message
  else if(is.null(input$ms_ls_s1_kc_outdir)){
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
    
    ms_lsat_df = parseFilePaths(volumes, input$ms1_lsat_file)
    ms_lsat_infile = as.character(ms_lsat_df[,"datapath"])
    
    ms_ls_s1_kc_lsatind = input$ms_ls_s1_kc_lsatind  
    
    ms_s1_df = parseFilePaths(volumes, input$ms1_s1_file)
    ms_s1_infile = as.character(ms_s1_df[,"datapath"])
    
    ms_kc_df = parseFilePaths(volumes, input$ms1_alos_file)
    ms_kc_infile = as.character(ms_kc_df[,"datapath"])
    
    ms_ls_s1_kc_dir <<- parseDirPath(volumes, input$ms_ls_s1_kc_outdir)      
    #ms_ls_s1_kc_outfile = paste(ms_ls_s1_kc_dir,"/ms_sensor_stack.vrt",sep="")
    ms_ls_s1_kc_args<<- paste(ms_lsat_infile, ms_s1_infile, ms_kc_infile, ms_ls_s1_kc_dir )
  
    # create a exitfile path and export as global variable
    ms_ls_s1_kc_exitfile <<- paste(ms_ls_s1_kc_dir, "/.exitfile", sep="")
    
    ms_ls_s1_kc_tmp <<- paste(ms_ls_s1_kc_dir, "/.TMP")
    
    # return new state
    return("NOT_STARTED")
    
  }
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# start function that triggers the processing 
ms_ls_s1_kc_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("ms_ls_s1_kc_pro_btn", {
    
    ms_ls_s1_kc_message="Processing started (This can take a moment)"
    js_string_ms_ls_s1_kc <- 'alert("Processing");'
    js_string_ms_ls_s1_kc <- sub("Processing",ms_ls_s1_kc_message,js_string_ms_ls_s1_kc)
    session$sendCustomMessage(type='jsCode', list(value = js_string_ms_ls_s1_kc))
      
    # run processing
    print(paste("( ost_multi_sensor_ls_s1_kc", ms_ls_s1_kc_args, "; echo $? >", ms_ls_s1_kc_exitfile, ")"))
    system(paste("( ost_multi_sensor_ls_s1_kc", ms_ls_s1_kc_args, "; echo $? >", ms_ls_s1_kc_exitfile, ")"), wait = FALSE, intern=FALSE)
    return("RUNNING")     
  })
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Termination Function (what to do when script stopped)
ms_ls_s1_kc_term = function() {
  
  # get the exit state of the script
  ms_ls_s1_kc_status = readLines(ms_ls_s1_kc_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(ms_ls_s1_kc_exitfile, force = TRUE)
  
  # message when all downloads finished/failed
  if ( ms_ls_s1_kc_status != 0 ){
    ms_ls_s1_kc_end_message="Processing failed. Check the Progress Monitor."
    ms_ls_s1_kc_js_string <- 'alert("SUCCESS");'
    ms_ls_s1_kc_js_string <- sub("SUCCESS",ms_ls_s1_kc_end_message,ms_ls_s1_kc_js_string)
    session$sendCustomMessage(type='jsCode', list(value = ms_ls_s1_kc_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    ms_ls_s1_kc_fin_message="Processing finished"
    js_string_ms_ls_s1_kc_fin <- 'alert("Processing");'
    js_string_ms_ls_s1_kc_fin <- sub("Processing",ms_ls_s1_kc_fin_message,js_string_ms_ls_s1_kc_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_ms_ls_s1_kc_fin))
  }
  
  # reset button to 0 for enable re-start
  ms_ls_s1_kc_values$ms_ls_s1_kc_pro = 0
}  
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# main function triggering processing and controlling state
output$processMS_ls_s1_kc = renderText({
  
  # trigger processing when action button clicked
  if(ms_ls_s1_kc_values$ms_ls_s1_kc_pro) {
    
    #run the state function
    ms_ls_s1_kc_state = ms_ls_s1_kc_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    print(paste("state1",ms_ls_s1_kc_state))
    
    if (ms_ls_s1_kc_state == "INITIAL"){
      ms_ls_s1_kc_state = ms_ls_s1_kc_get_args()
      unlink(paste(ms_ls_s1_kc_dir, "/.ms_ls_s1_kc_progress"))
      ms_ls_s1_kc_values$ms_ls_s1_kc_log = 0
    }
    
    if (ms_ls_s1_kc_state == "NOT_STARTED"){
      ms_ls_s1_kc_state = ms_ls_s1_kc_start()
      print(paste("state3",ms_ls_s1_kc_state))
      Sys.sleep(2)
      ms_ls_s1_kc_values$ms_ls_s1_kc_log = 1
    }
    
    if (ms_ls_s1_kc_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (ms_ls_s1_kc_state == "TERMINATED")
      ms_ls_s1_kc_term()
    
    print("")
  } # close value process    
  
  if(ms_ls_s1_kc_values$ms_ls_s1_kc_abort) {
    
    # delete the exit file
    unlink(ms_ls_s1_kc_exitfile)
    
    # check whihc temp folder
    if (dir.exists(paste(ms_ls_s1_kc_dir, "/.TMP")))
      ms_ls_s1_kc_tmp = paste(ms_ls_s1_kc_dir, "/.TMP")
    
    if (!dir.exists(paste(ms_ls_s1_kc_dir, "/.TMP")))
      ms_ls_s1_kc_tmp = "/ram/SAR_TMP"
    
    system(paste("ost_cancel_proc \"sh -c ( ost_multi_sensor_ls_s1_kc", ms_ls_s1_kc_args, "\"", ms_ls_s1_kc_tmp))
    
    ms_ls_s1_kc_dir_message="User interruption"
    ms_ls_s1_kc_js_string <- 'alert("Attention");'
    ms_ls_s1_kc_js_string <- sub("Attention",ms_ls_s1_kc_dir_message,ms_ls_s1_kc_js_string)
    session$sendCustomMessage(type='jsCode', list(value = ms_ls_s1_kc_js_string))
    print("")
  }
  
}) # close render function

#---------------------------------------------------------------------------  
# Progress monitor function
output$ms_ls_s1_kc_progress = renderText({
  
  if(ms_ls_s1_kc_values$ms_ls_s1_kc_log) {
    
    ms_ls_s1_kc_progress_file=file.path(ms_ls_s1_kc_dir, "/.ms_ls_s1_kc_progress")
    
    if(file.exists(ms_ls_s1_kc_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", ms_ls_s1_kc_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(ms_ls_s1_kc_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------
