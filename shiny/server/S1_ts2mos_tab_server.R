#---------------------------------------------------------------------------
# Folder processing
output$s1_ts2mos_inputdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_ts2mos_inputdir', roots=volumes)
  
  validate (
    need(input$s1_ts2mos_inputdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_ts2mos_inputdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------
# main function calling the CL script

# we create some values for reactive behaviour
s1_ts2m_values <- reactiveValues(s1_ts2m_pro = 0, s1_ts2m_abort = 0, s1_ts2m_log = 0)

# we create the reactive behaviour
observeEvent(input$s1_ts2m_pro_btn, {
  s1_ts2m_values$s1_ts2m_pro = 1
  s1_ts2m_values$s1_ts2m_abort = 0
  s1_ts2m_values$s1_ts2m_log = 1
})

observeEvent(input$s1_ts2m_abort_btn, {
  s1_ts2m_values$s1_ts2m_pro = 0
  s1_ts2m_values$s1_ts2m_abort = 1
})

#observeEvent(input$s1_ts2m_log_btn, {
#  s1_ts2m_values$s1_ts2m_log = 1
#})

# a function that returns the currrent state based on pid and exit file
s1_ts2m_get_state = function() {
  
  if(!exists("s1_ts2m_args"))
    return("INITIAL")
  else {
    # get the pid
    s1_ts2m_pid_cmd=paste("-ef | grep \"sh -c ( ost_S1_ts2mosaic", s1_ts2m_args, "\" | grep -v grep | awk '{print $2}'")
    s1_ts2m_pid = as.integer(system2("ps", args = s1_ts2m_pid_cmd, stdout = TRUE))
  }
  
  if (length(s1_ts2m_pid) > 0)
    return("RUNNING")
  
  if (file.exists(s1_ts2m_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 



#---------------------------------------------------------------------------
# get the input arguments from the GUI
s1_ts2m_get_args = function(){
  
  if(is.null(input$s1_ts2mos_inputdir)){
    s1_ts2m_dir_message=" No project directory selected."
    s1_ts2m_js_string <- 'alert("Attention");'
    s1_ts2m_js_string <- sub("Attention",s1_ts2m_dir_message,s1_ts2m_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_ts2m_js_string))
    s1_ts2m_values$s1_ts2m_pro = 0
    s1_ts2m_values$s1_ts2m_log = 0
    return("INPUT_FAIL")
  }
  
  else {
    
    volumes = c('User directory'=Sys.getenv("HOME"))
    s1_ts2m_dir <<- parseDirPath(volumes, input$s1_ts2m_inputdir)
    #s1_ts2m_mode = input$s1_ts2mos_mode

    s1_ts2m_args <<- paste(s1_ts2m_dir, "1")
    #s1_ts2m_args <<- paste(s1_ts2m_dir, s1_ts2m_mode)
    
    # create a exitfile path and export as global variable
    s1_ts2m_exitfile <<- paste(s1_ts2m_dir, "/.s1_ts2m_exitfile", sep="")
    
    # return new state
    return("NOT_STARTED")
  }
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# start fucntion that runs the processing 
s1_ts2m_start = function() {
    
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_ts2m_search", {
      
    # Pop-up message for starting data inventory
    s1_search_message="Mosaicking started"
    js_string_s1_search <- 'alert("Inventory");'
    js_string_s1_search <- sub("Inventory",s1_search_message,js_string_s1_search)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_search))
      
    # run processing
    print(paste("ost_S1_ts2mosaic", s1_ts2m_args), intern=FALSE)
    system(paste("( ost_S1_ts2mosaic", s1_ts2m_args, "; echo $? >", s1_ts2m_exitfile, ")"), wait = FALSE, intern=FALSE)
      
    return("RUNNING")
  })  
}
#---------------------------------------------------------------------------
  
#---------------------------------------------------------------------------
# when processing is script is finished we want to check if everything went fine
s1_ts2m_term = function() {
    
  # get the exit state of the script
  s1_ts2m_status = readLines(s1_ts2m_exitfile)
    
  # we want to remove the exit file for the next run
  unlink(s1_ts2m_exitfile, force = TRUE)
    
  # message when all downloads finished/failed
  if ( s1_ts2m_status != 0 ){
    s1_ts2m_end_message="Mosaicking failed!"
    s1_ts2m_js_string <- 'alert("SUCCESS");'
    s1_ts2m_js_string <- sub("SUCCESS",s1_ts2m_end_message,s1_ts2m_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_ts2m_js_string))
  }
    
  else {
    # Pop-up message for having finished data inventory
    s1_found_message="Mosaicking finished!"
    js_string_s1_found <- 'alert("Finished");'
    js_string_s1_found <- sub("Finished",s1_found_message,js_string_s1_found)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_found))
      
  }
  # reset button to 0 for enable re-start
  s1_ts2m_values$s1_ts2m_pro = 0
}
#---------------------------------------------------------------------------
  
  
#---------------------------------------------------------------------------
# run the main processing fuction
output$s1_ts2m = renderText({
    
  # trigger processing when action button clicked
  if(s1_ts2m_values$s1_ts2m_pro) {
      
    #run the state function
    s1_ts2m_state = s1_ts2m_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
      
    if (s1_ts2m_state == "INITIAL"){
      s1_ts2m_state = s1_ts2m_get_args()
      unlink(paste(s1_ts2m_dir, "/.s1_ts2m_progress"))
      s1_ts2m_values$s1_ts2m_log = 0
    }
      
    if (s1_ts2m_state == "NOT_STARTED"){
      s1_ts2m_state = s1_ts2m_start()
      Sys.sleep(2)
      s1_ts2m_values$s1_ts2m_log = 1
    }
      
    if (s1_ts2m_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (s1_ts2m_state == "TERMINATED")
      s1_ts2m_term()
      
    print("")
  } # close value process    
  
  if(s1_ts2m_values$s1_ts2m_abort) {
    
    # delete the exit file
    unlink(s1_ts2m_exitfile)
      
    print(paste("ost_cancel_proc ost_S1_ts2mosaic", s1_ts2m_args, paste(s1_ts2m_dir, "/TMP", sep = "")))
    system(paste("ost_cancel_proc \"sh -c ( ost_S1_ts2mosaic", s1_ts2m_args, "\"", paste(s1_ts2m_dir, "/TMP", sep = "")))
    s1_ts2m_dir_message="User interruption"
    s1_ts2m_js_string <- 'alert("Attention");'
    s1_ts2m_js_string <- sub("Attention",s1_ts2m_dir_message,s1_ts2m_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_ts2m_js_string))
    print("")
  }
    
})  # close render text function 
#------------------------------------------------------------------------------------------------
  
  
#---------------------------------------------------------------------------
# progress monitor trigger
output$s1_ts2m_progress = renderText({
    
  if(s1_ts2m_values$s1_ts2m_log) {
      
    s1_ts2m_progress_file=file.path(s1_ts2m_dir, "/.s1_ts2m_progress")
      
    if(file.exists(s1_ts2m_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", s1_ts2m_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(s1_ts2m_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------