#---------------------------------------------------------------------------
# Folder processing
output$s1_rtc2ts_inputdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_rtc2ts_inputdir', roots=volumes)
  
  validate (
    need(input$s1_rtc2ts_inputdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_rtc2ts_inputdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

# Choose a local file
output$S1_rtc2ts_shapefile = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'S1_rtc2ts_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$S1_rtc2ts_shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$S1_rtc2ts_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})

#---------------------------------------------------------------------------
# Clean up folder
output$S1_ts_cleanupdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 'S1_ts_cleanupdir', roots=volumes)
  
  validate (
    need(input$S1_ts_cleanupdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$S1_ts_cleanupdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Warning messages
memtotal = as.numeric(system("awk '/MemTotal/ {print $2}' /proc/meminfo",intern=TRUE))
if (memtotal < 15000000) {
  if ( nchar(Sys.getenv('SEPAL')) > 0){
    output$RAMwarning_rtc2ts <- renderText({"WARNING: You do NOT have enough RAM on your machine for running this processing. Please go to the Terminal,
                                      manually start an instance with at least 16 GB of RAM and restart the SAR toolkit in the processing menu. "})
  } else {
    output$RAMwarning_rtc2ts <- renderText({"WARNING: You do NOT have enough RAM on your machine for running this processing. Make sure your PC has at least 16 GB of RAM."})
  }
} else {
  output$RAMwarning_rtc2ts <- renderText({""})
}
#---------------------------------------------------------------------------



#---------------------------------------------------------------------------
# reactive values and observe events
s1_rtc2ts_values <- reactiveValues(s1_rtc2ts_pro = 0, s1_rtc2ts_abort = 0, s1_rtc2ts_log = 0)

# we create the reactive behaviour
observeEvent(input$s1_rtc2ts_pro_btn, {
  s1_rtc2ts_values$s1_rtc2ts_pro = 1
  s1_rtc2ts_values$s1_rtc2ts_abort = 0
  s1_rtc2ts_values$s1_rtc2ts_log = 1
})

observeEvent(input$s1_rtc2ts_abort_btn, {
  s1_rtc2ts_values$s1_rtc2ts_pro = 0
  s1_rtc2ts_values$s1_rtc2ts_abort = 1
})

#observeEvent(input$s1_rtc2ts_log_btn, {
#  s1_rtc2ts_values$s1_rtc2ts_log = 1
#})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
s1_rtc2ts_get_state = function() {
  
  if(!exists("s1_rtc2ts_args"))
    return("INITIAL")
  else {
    
    # get the pid
    s1_rtc2ts_pid_cmd=paste("-ef | grep \"sh -c ( ost_S1_rtc2ts", s1_rtc2ts_args, "\" | grep -v grep | awk '{print $2}'")
    s1_rtc2ts_pid = as.integer(system2("ps", args = s1_rtc2ts_pid_cmd, stdout = TRUE))
  }
  
  if (length(s1_rtc2ts_pid) > 0)
    return("RUNNING")
  
  if (file.exists(s1_rtc2ts_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# get the input arguments from the GUI
s1_rtc2ts_get_args = function(){

  if(is.null(input$s1_rtc2ts_inputdir)){
    s1_rtc2ts_dir_message=" Project directory not selected"
    s1_rtc2ts_js_string <- 'alert("Attention");'
    s1_rtc2ts_js_string <- sub("Attention",s1_rtc2ts_dir_message,s1_rtc2ts_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_rtc2ts_js_string))
    s1_rtc2ts_values$s1_rtc2ts_pro = 0
    s1_rtc2ts_values$s1_rtc2ts_log = 0
    return("INPUT_FAIL")
  }
  
  else {
    volumes = c('User directory'=Sys.getenv("HOME"))
    s1_rtc2ts_dir <<- parseDirPath(volumes, input$s1_rtc2ts_inputdir)
    s1_rtc2ts_mode = input$s1_rtc2ts_mode
    s1_rtc2ts_dtype = input$s1_rtc2ts_dtype
    s1_rtc2ts_ls = input$s1_rtc2ts_ls
    
    # processing arguments
    s1_rtc2ts_args <<- paste(s1_rtc2ts_dir, s1_rtc2ts_dtype, s1_rtc2ts_mode, s1_rtc2ts_ls)
    
    # create a exitfile path and export as global variable
    s1_rtc2ts_exitfile <<- paste(s1_rtc2ts_dir, "/.s1_rtc2ts_exitfile", sep="")
    return("NOT_STARTED")
  }
}


#---------------------------------------------------------------------------
# Processing functions
s1_rtc2ts_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_rtc2ts_pro_btn", {
    
      s1_rtc2ts_message="Processing started (This will take a while.)"
      js_string_s1_rtc2ts <- 'alert("Processing");'
      js_string_s1_rtc2ts <- sub("Processing",s1_rtc2ts_message,js_string_s1_rtc2ts)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_rtc2ts))
      
      # TRIGGER PROCESSING
      system(paste("( ost_S1_rtc2ts", s1_rtc2ts_args, "; echo $? >", s1_rtc2ts_exitfile, ")"), wait = FALSE, intern = FALSE)
      
      return("RUNNING")
  })
}
#---------------------------------------------------------------------------

# Termination Function (what to do when script stopped)
s1_rtc2ts_term = function() {
  
  # get the exit state of the script
  s1_rtc2ts_status = readLines(s1_rtc2ts_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(s1_rtc2ts_exitfile, force = TRUE)
  
  # message when all downloads finished/failed
  if ( s1_rtc2ts_status != 0 ){
    s1_rtc2ts_end_message="Processing failed. Check the Progress Monitor."
    s1_rtc2ts_js_string <- 'alert("SUCCESS");'
    s1_rtc2ts_js_string <- sub("SUCCESS",s1_rtc2ts_end_message,s1_rtc2ts_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_rtc2ts_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    s1_rtc2ts_fin_message="Processing finished"
    js_string_s1_rtc2ts_fin <- 'alert("Processing");'
    js_string_s1_rtc2ts_fin <- sub("Processing",s1_rtc2ts_fin_message,js_string_s1_rtc2ts_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_rtc2ts_fin))
  }
  
  # reset button to 0 for enable re-start
  s1_rtc2ts_values$s1_rtc2ts_pro = 0
}  
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Processing and Abort function
output$processS1_RTC2TS = renderText({
  
  # trigger processing when action button clicked
  if(s1_rtc2ts_values$s1_rtc2ts_pro) {
    
    #run the state function
    s1_rtc2ts_state = s1_rtc2ts_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    
    if (s1_rtc2ts_state == "INITIAL"){
      s1_rtc2ts_values$s1_rtc2ts_log = 0
      s1_rtc2ts_state = s1_rtc2ts_get_args()
      unlink(paste(s1_rtc2ts_dir, "/.s1_rtc2ts_progress", sep = ""))
    }
    
    if (s1_rtc2ts_state == "NOT_STARTED"){
      s1_rtc2ts_state = s1_rtc2ts_start()
      Sys.sleep(2)
      s1_rtc2ts_values$s1_rtc2ts_log = 1
    }
      
    if (s1_rtc2ts_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (s1_rtc2ts_state == "TERMINATED")
      s1_rtc2ts_term()
    
    print("")
  } # close value process    
  
  if(s1_rtc2ts_values$s1_rtc2ts_abort) {
    
    # delete the exit file
    unlink(s1_rtc2ts_exitfile)
    
    # cancel the
    system(paste("ost_cancel_proc \"sh -c ( ost_S1_rtc2ts", s1_rtc2ts_args, "\"", paste(s1_rtc2ts_dir, "/TMP", sep = "")))
    
    s1_rtc2ts_dir_message="User interruption"
    s1_rtc2ts_js_string <- 'alert("Attention");'
    s1_rtc2ts_js_string <- sub("Attention",s1_rtc2ts_dir_message,s1_rtc2ts_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_rtc2ts_js_string))
    print("")
  }
  
  
  })
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Progress monitor function
output$s1_rtc2ts_progress = renderText({
  
  if(s1_rtc2ts_values$s1_rtc2ts_log) {
    
    s1_rtc2ts_progress_file=file.path(s1_rtc2ts_dir, "/.s1_rtc2ts_progress")
    
    if(file.exists(s1_rtc2ts_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", s1_rtc2ts_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(s1_rtc2ts_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------

#---------------------------
# clean up functions

# clean up raws
print_s1_ts_cleanup_raw = eventReactive(input$s1_ts_clean_raw, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("S1_ts_cleanupdir", {
    
    if(is.null(input$S1_ts_cleanupdir)){
      stop("No project folder chosen")
    }
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      PROC_DIR = parseDirPath(volumes, input$S1_ts_cleanupdir)
      
      ARG_PROC=paste(PROC_DIR, "1")
      print(paste("ost_S1_cleanup", ARG_PROC))
      system(paste("ost_S1_cleanup", ARG_PROC),intern=TRUE)
      
      s1_ts_clean_raw_fin_message="Succesfully deleted raw files"
      js_string_s1_ts_clean_raw <- 'alert("Info");'
      js_string_s1_ts_clean_raw <- sub("Info",s1_ts_clean_raw_fin_message,js_string_s1_ts_clean_raw)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_ts_clean_raw))
    }
    
    })
})

output$cleanS1RAW = renderText({
  print_s1_ts_cleanup_raw()
})

# clean up rtc/ls
print_s1_ts_cleanup_rtc = eventReactive(input$s1_ts_clean_rtc, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("S1_ts_cleanupdir", {
    
    if(is.null(input$S1_ts_cleanupdir)){
      stop("No data folder chosen")
    }
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      PROC_DIR = parseDirPath(volumes, input$S1_ts_cleanupdir)
      
      ARG_PROC=paste(PROC_DIR, "2")
      print(paste("ost_S1_cleanup", ARG_PROC))
      system(paste("ost_S1_cleanup", ARG_PROC),intern=TRUE)
      
      s1_ts_clean_rtc_fin_message="Succesfully deleted all RTC & LS map files"
      js_string_s1_ts_clean_rtc <- 'alert("Info");'
      js_string_s1_ts_clean_rtc <- sub("Info",s1_ts_clean_rtc_fin_message,js_string_s1_ts_clean_rtc)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_ts_clean_rtc))
    }
  })
})

output$cleanS1RTC = renderText({
  print_s1_ts_cleanup_rtc()
  print("there")
  print(print_s1_ts_cleanup_rtc())
  })


# clean up timeseries
print_s1_ts_cleanup_timeseries = eventReactive(input$s1_ts_clean_timeseries, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("S1_ts_cleanupdir", {
    
    if(is.null(input$S1_ts_cleanupdir)){
      stop("No project folder chosen")
    }
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      PROC_DIR = parseDirPath(volumes, input$S1_ts_cleanupdir)
      
      ARG_PROC=paste(PROC_DIR, "4")
      print(paste("ost_S1_cleanup", ARG_PROC))
      system(paste("ost_S1_cleanup", ARG_PROC),intern=TRUE)
      
      s1_ts_clean_ts1_fin_message="Succesfully deleted all time-series data."
      js_string_s1_ts_clean_ts1 <- 'alert("Info");'
      js_string_s1_ts_clean_ts1 <- sub("Info",s1_ts_clean_ts1_fin_message,js_string_s1_ts_clean_ts1)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_ts_clean_ts1))
    }
    
  })
})

output$cleanS1TS = renderText({
  print_s1_ts_cleanup_timeseries()
})

# clean up timescan
print_s1_ts_cleanup_timescan = eventReactive(input$s1_ts_clean_timescan, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("S1_ts_cleanupdir", {
    
    if(is.null(input$S1_ts_cleanupdir)){
      stop("No project folder chosen")
    }
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      PROC_DIR = parseDirPath(volumes, input$S1_ts_cleanupdir)
      
      ARG_PROC=paste(PROC_DIR, "5")
      print(paste("ost_S1_cleanup", ARG_PROC))
      system(paste("ost_S1_cleanup", ARG_PROC),intern=TRUE)
      
      s1_ts_clean_ts2_fin_message="Succesfully deleted all timescan data."
      js_string_s1_ts_clean_ts2 <- 'alert("Info");'
      js_string_s1_ts_clean_ts2 <- sub("Info",s1_ts_clean_ts2_fin_message,js_string_s1_ts_clean_ts2)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_ts_clean_ts2))
    }
    
  })
})

output$cleanS1TScan = renderText({
  print_s1_ts_cleanup_timescan()
})
