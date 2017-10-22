#----------------------------------------------
#input MS folder 
output$bm_ms_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 'bm_ms_dir', roots=volumes)
  
  validate (
    need(input$bm_ms_dir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$bm_ms_dir)
  cat(df) #}
})

# Choose a FI Shapefile zstack
output$bm_fi_file = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'bm_fi_file', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$bm_fi_file != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$bm_fi_file)
  bm_fi_file_path = as.character(df[,"datapath"])
  cat(bm_fi_file_path)
})

#output folder 
output$bm_outdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 'bm_outdir', roots=volumes)
  
  validate (
    need(input$bm_outdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$bm_outdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# reactive values and observe events
# we create some values for reactive behaviour
bm_values <- reactiveValues(bm_pro = 0, bm_abort = 0, bm_log = 0)

# we create the reactive behaviour
observeEvent(input$bm_pro_btn, {
  bm_values$bm_pro = 1
  bm_values$bm_abort = 0
  bm_values$bm_log = 1
})

observeEvent(input$bm_abort_btn, {
  bm_values$bm_pro = 0
  bm_values$bm_abort = 1
})

#observeEvent(input$bm_log_btn, {
#  bm_values$bm_log = 1
#})
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
bm_get_state = function() {
  
  if(!exists("bm_args"))
    return("INITIAL")
  else {
    # get the pid
    bm_pid_cmd=paste("-ef | grep \"sh -c ( ost_MS_biomass", bm_args, "\" | grep -v grep | awk '{print $2}'")
    
    bm_pid = as.integer(system2("ps", args = bm_pid_cmd, stdout = TRUE))
  }
  
  if (length(bm_pid) > 0)
    return("RUNNING")
  
  if (file.exists(bm_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# get the input arguments from the GUI
bm_get_args = function(){
  
  # empty input file message
  if(is.null(input$bm_ms_dir)){
    bm_file_message=" No input directory containing the multi-sensor stack given."
    bm_js_string <- 'alert("Attention");'
    bm_js_string <- sub("Attention",bm_file_message, bm_js_string)
    session$sendCustomMessage(type='jsCode', list(value =  bm_js_string))
    bm_values$bm_pro = 0
    bm_values$bm_log = 0
    return("INPUT_FAIL")
  } 
  
  # empty s1 message
  else if(is.null(input$bm_fi_file)){
    bm_fi_file_message=" No Shapefile has been selected"
    bm_fi_js_string <- 'alert("Attention");'
    bm_fi_js_string <- sub("Attention",bm_fi_file_message, bm_fi_js_string)
    session$sendCustomMessage(type='jsCode', list(value =  bm_fi_js_string))
    bm_values$bm_pro = 0
    bm_values$bm_log = 0
    return("INPUT_FAIL")
  }
  # empty output directy message
  else if(is.null(input$bm_outdir)){
    bm_dir_message=" No output folder selected"
    bm_js_string <- 'alert("Attention");'
    bm_js_string <- sub("Attention",bm_dir_message,bm_js_string)
    session$sendCustomMessage(type='jsCode', list(value = bm_js_string))
    bm_values$bm_pro = 0
    bm_values$bm_log = 0
    return("INPUT_FAIL")
  }
  
  # processing
  else {
    
    volumes = c('User directory'=Sys.getenv("HOME"))
    
    bm_ms_dir <<- parseDirPath(volumes, input$bm_ms_dir)      
    
    bm_fi_df = parseFilePaths(volumes, input$bm_fi_file)
    bm_fi_infile = as.character(bm_fi_df[,"datapath"])
    
    bm_fi_field = input$bm_fi_field
    
    bm_dir <<- parseDirPath(volumes, input$bm_outdir)      
    bm_args <<- paste(bm_ms_dir, bm_fi_infile, bm_fi_field, bm_dir )
    
    # create a exitfile path and export as global variable
    bm_exitfile <<- paste(bm_dir, "/.exitfile", sep="")
    
    bm_tmp <<- paste(bm_dir, "/.TMP")
    
    # return new state
    return("NOT_STARTED")
    
  }
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# start function that triggers the processing 
bm_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("bm_pro_btn", {
    
    bm_message="Processing started (This can take a moment)"
    js_string_bm <- 'alert("Processing");'
    js_string_bm <- sub("Processing",bm_message,js_string_bm)
    session$sendCustomMessage(type='jsCode', list(value = js_string_bm))
    
    # run processing
    print(paste("( ost_MS_biomass", bm_args, "; echo $? >", bm_exitfile, ")"))
    system(paste("( ost_MS_biomass", bm_args, "; echo $? >", bm_exitfile, ")"), wait = FALSE, intern=FALSE)
    return("RUNNING")     
  })
}
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# Termination Function (what to do when script stopped)
bm_term = function() {
  
  # get the exit state of the script
  bm_status = readLines(bm_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(bm_exitfile, force = TRUE)
  
  # message when processing finished/failed
  if ( bm_status == 2 ){
    bm_end_message="Field name is non-existent. Please re-check."
    bm_js_string <- 'alert("SUCCESS");'
    bm_js_string <- sub("SUCCESS",bm_end_message,bm_js_string)
    session$sendCustomMessage(type='jsCode', list(value = bm_js_string))
  }
  else if ( bm_status != 0 ){
    bm_end_message="Processing failed. Check the Progress Monitor."
    bm_js_string <- 'alert("SUCCESS");'
    bm_js_string <- sub("SUCCESS",bm_end_message,bm_js_string)
    session$sendCustomMessage(type='jsCode', list(value = bm_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    bm_fin_message="Processing finished"
    js_string_bm_fin <- 'alert("Processing");'
    js_string_bm_fin <- sub("Processing",bm_fin_message,js_string_bm_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_bm_fin))
  }
  
  # reset button to 0 for enable re-start
  bm_values$bm_pro = 0
}  
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# main function triggering processing and controlling state
output$processMS_biomass = renderText({
  
  # trigger processing when action button clicked
  if(bm_values$bm_pro) {
    
    #run the state function
    bm_state = bm_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    print(paste("state1",bm_state))
    
    if (bm_state == "INITIAL"){
      bm_state = bm_get_args()
      unlink(paste(bm_dir, "/.bm_progress"))
      bm_values$bm_log = 0
    }
    
    if (bm_state == "NOT_STARTED"){
      bm_state = bm_start()
      print(paste("state3",bm_state))
      Sys.sleep(2)
      bm_values$bm_log = 1
    }
    
    if (bm_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (bm_state == "TERMINATED")
      bm_term()
    
    print("")
  } # close value process    
  
  if(bm_values$bm_abort) {
    
    # delete the exit file
    unlink(bm_exitfile)
    
    # check whihc temp folder
    if (dir.exists(paste(bm_dir, "/.TMP")))
      bm_tmp = paste(bm_dir, "/.TMP")
    
    if (!dir.exists(paste(bm_dir, "/.TMP")))
      bm_tmp = "/ram/SAR_TMP"
    
    system(paste("ost_cancel_proc \"sh -c ( ost_MS_biomass", bm_args, "\"", bm_tmp))
    
    bm_dir_message="User interruption"
    bm_js_string <- 'alert("Attention");'
    bm_js_string <- sub("Attention",bm_dir_message,bm_js_string)
    session$sendCustomMessage(type='jsCode', list(value = bm_js_string))
    print("")
  }
  
}) # close render function


#---------------------------------------------------------------------------  
# Progress monitor function
output$bm_progress = renderText({
  
  if(bm_values$bm_log) {
    
    bm_progress_file=file.path(bm_dir, "/.bm_progress")
    
    if(file.exists(bm_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", bm_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(bm_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------
