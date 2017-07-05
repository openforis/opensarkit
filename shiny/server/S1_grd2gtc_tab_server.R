#---------------------------------------------------------------------------
# Functions for Original File choice

# Choose a S1 zip file
output$s1_g2g_zip = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 's1_g2g_zip', roots=volumes, filetypes=c('zip','dim'))
  
  validate (
    need(input$s1_g2g_zip != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$s1_g2g_zip)
  s1_g2g_zip_file_path = as.character(df[,"datapath"])
  cat(s1_g2g_zip_file_path)
})

# output folder 
output$s1_g2g_outdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2g_outdir', roots=volumes)
  
  validate (
    need(input$s1_g2g_outdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2g_outdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Warning messages
s1_g2g_memtotal = as.numeric(system("awk '/MemTotal/ {print $2}' /proc/meminfo",intern=TRUE))
if (s1_g2g_memtotal < 15000000) {
  if ( nchar(Sys.getenv('SEPAL')) > 0){
    output$s1_g2g_RAMwarning <- renderText({"WARNING: You do NOT have enough RAM on your machine for running this processing. Please go to the Terminal,
      manually start an instance with at least 16 GB of RAM and restart the SAR toolkit in the processing menu. "})
    } else {
      output$s1_g2g_RAMwarning <- renderText({"WARNING: You do NOT have enough RAM on your machine for running this processing. Make sure your PC has at least 16 GB of RAM."})
  }
} else {
  output$s1_g2g_RAMwarning <- renderText({""})
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Folder processing
output$s1_g2g_inputdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2g_inputdir', roots=volumes)
  
  validate (
    need(input$s1_g2g_inputdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2g_inputdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# reactive values and observe events
# we create some values for reactive behaviour
s1_g2g_values <- reactiveValues(s1_g2g_pro = 0, s1_g2g_abort = 0, s1_g2g_log = 0)

# we create the reactive behaviour
observeEvent(input$s1_g2g_pro_btn, {
  s1_g2g_values$s1_g2g_pro = 1
  s1_g2g_values$s1_g2g_abort = 0
  s1_g2g_values$s1_g2g_log = 1
})

observeEvent(input$s1_g2g_abort_btn, {
  s1_g2g_values$s1_g2g_pro = 0
  s1_g2g_values$s1_g2g_abort = 1
})

#observeEvent(input$s1_g2g_log_btn, {
#  s1_g2g_values$s1_g2g_log = 1
#})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
s1_g2g_get_state = function() {
  
  if(!exists("s1_g2g_args"))
    return("INITIAL")
  else {
    # get the pid
    if (input$s1_g2g_input_type == "s1_g2g_file")
      s1_g2g_pid_cmd=paste("-ef | grep \"sh -c ( ost_S1_grd2gtc", s1_g2g_args, "\" | grep -v grep | awk '{print $2}'")
    
    if (input$s1_g2g_input_type == "s1_g2g_folder")
      s1_g2g_pid_cmd=paste("-ef | grep \"sh -c ( ost_S1_grd2gtc_bulk", s1_g2g_args, "\" | grep -v grep | awk '{print $2}'")
    
    s1_g2g_pid = as.integer(system2("ps", args = s1_g2g_pid_cmd, stdout = TRUE))
  }
  
  if (length(s1_g2g_pid) > 0)
    return("RUNNING")
  
  if (file.exists(s1_g2g_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# get the input arguments from the GUI
s1_g2g_get_args = function(){
  
  # original file choice
  if (input$s1_g2g_input_type == "s1_g2g_file"){
    
    # empty input file message
    if(is.null(input$s1_g2g_zip)){
      s1_g2g_dir_message=" No Sentinel-1 product selected"
      s1_g2g_js_string <- 'alert("Attention");'
      s1_g2g_js_string <- sub("Attention",s1_g2g_dir_message,s1_g2g_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_g2g_js_string))
      s1_g2g_values$s1_g2g_pro = 0
      s1_g2g_values$s1_g2g_log = 0
      return("INPUT_FAIL")
    } 
    
    # empty output directy message
    else if(is.null(input$s1_g2g_outdir)){
      s1_g2g_dir_message=" No output folder selected"
      s1_g2g_js_string <- 'alert("Attention");'
      s1_g2g_js_string <- sub("Attention",s1_g2g_dir_message,s1_g2g_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_g2g_js_string))
      s1_g2g_values$s1_g2g_pro = 0
      s1_g2g_values$s1_g2g_log = 0
      return("INPUT_FAIL")
    }
    
    # processing
    else {
      
      volumes = c('User directory'=Sys.getenv("HOME"))
      s1_g2g_df = parseFilePaths(volumes, input$s1_g2g_zip)
      s1_g2g_infile = as.character(s1_g2g_df[,"datapath"])
      s1_g2g_outdir = parseDirPath(volumes, input$s1_g2g_outdir)
      
      if (input$s1_g2g_res_file == "med_res"){
        s1_g2g_resolution = "MED_RES" 
      } 
      
      else if (input$s1_g2g_res_file == "full_res"){
        s1_g2g_resolution = "HI_RES" 
      }
      
      # single file arguments     
      s1_g2g_args <<- paste(s1_g2g_infile, s1_g2g_outdir, s1_g2g_resolution)
      
      # get the dir of the outfile
      s1_g2g_dir <<- dirname(s1_g2g_infile)
      
      # create a exitfile path and export as global variable
      s1_g2g_exitfile <<- paste(s1_g2g_dir, "/.exitfile", sep="")
      
      s1_g2g_tmp <<- paste(s1_g2g_dir, "/TMP")
      
      # return new state
      return("NOT_STARTED")
    } 
    
  } 
  
  else if (input$s1_g2g_input_type == "s1_g2g_folder"){
    
    if (is.null(input$s1_g2g_inputdir)){
      s1_g2g_dir_message=" No project directory selected"
      s1_g2g_js_string <- 'alert("Attention");'
      s1_g2g_js_string <- sub("Attention",s1_g2g_dir_message,s1_g2g_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_g2g_js_string))
      s1_g2g_values$s1_g2g_pro = 0
      s1_g2g_values$s1_g2g_log = 0
      return("INPUT_FAIL")
      
    }
    
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      s1_g2g_dir <<- parseDirPath(volumes, input$s1_g2g_inputdir)
      
      if (input$s1_g2g_res_folder == "med_res"){
        s1_g2g_resolution = "MED_RES" 
      } 
      
      else if (input$s1_g2g_res_folder == "full_res"){
        s1_g2g_resolution = "HI_RES" 
      }
      
      if (input$s1_g2g_mode == "0"){
        MODE = "0" 
        TS_PROC = "0"
      } 
      
      else if (input$s1_g2g_mode == "1"){
        MODE = "1"
        TS_PROC = input$s1_g2g_ts 
      }
      
      # set arguments as global variable
      s1_g2g_args <<- paste(s1_g2g_dir, s1_g2g_resolution, MODE, TS_PROC)     
      
      # create a exitfile path and export as global variable
      s1_g2g_exitfile <<- paste(s1_g2g_dir, "/.exitfile", sep="")
      
      # return new state
      return("NOT_STARTED")
    }
  }
}

#---------------------------------------------------------------------------
# start function that triggers the processing 
s1_g2g_start = function() {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_g2g_pro_btn", {
    
    if (input$s1_g2g_input_type == "s1_g2g_file"){
      s1_g2g_message="Processing started (This can take a moment)"
      js_string_s1_g2r <- 'alert("Processing");'
      js_string_s1_g2r <- sub("Processing",s1_g2g_message,js_string_s1_g2r)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
      
      # run processing
      print(paste("ost_S1_grd2gtc", s1_g2g_args))
      system(paste("( ost_S1_grd2gtc", s1_g2g_args, "; echo $? >", s1_g2g_exitfile, ")"), wait = FALSE, intern=FALSE)
      
      return("RUNNING")
    }
    
    if (input$s1_g2g_input_type == "s1_g2g_folder"){
      s1_g2g_message="Processing started (This can take a considerable amount of time, dependent on the number of images to be processed)"
      js_string_s1_g2r <- 'alert("Processing");'
      js_string_s1_g2r <- sub("Processing",s1_g2g_message,js_string_s1_g2r)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
      
      # run processing
      print(paste("ost_S1_grd2gtc_bulk", s1_g2g_args))
      system(paste("( ost_S1_grd2gtc_bulk", s1_g2g_args, "; echo $? >", s1_g2g_exitfile, ")"), wait = FALSE, intern=FALSE)
      
      return("RUNNING")
    }
  })
}

#---------------------------------------------------------------------------
# Termination Function (what to do when script stopped)
s1_g2g_term = function() {
  
  # get the exit state of the script
  s1_g2g_status = readLines(s1_g2g_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(s1_g2g_exitfile, force = TRUE)
  
  # message when all downloads finished/failed
  if ( s1_g2g_status != 0 ){
    s1_g2g_end_message="Processing failed. Check the Progress Monitor."
    s1_g2g_js_string <- 'alert("SUCCESS");'
    s1_g2g_js_string <- sub("SUCCESS",s1_g2g_end_message,s1_g2g_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2g_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    s1_g2g_fin_message="Processing finished"
    js_string_s1_g2g_fin <- 'alert("Processing");'
    js_string_s1_g2g_fin <- sub("Processing",s1_g2g_fin_message,js_string_s1_g2g_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2g_fin))
  }
  
  # reset button to 0 for enable re-start
  s1_g2g_values$s1_g2g_pro = 0
}  
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# main function triggering processing and controlling state
output$processS1_G2G = renderText({
  
  # trigger processing when action button clicked
  if(s1_g2g_values$s1_g2g_pro) {
    
    #run the state function
    s1_g2g_state = s1_g2g_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    print(paste("tmp:", Sys.getenv("TMP_DIR")))
    
    if (s1_g2g_state == "INITIAL"){
      s1_g2g_state = s1_g2g_get_args()
      unlink(paste(s1_g2g_dir, "/.s1_g2g_progress"))
      s1_g2g_values$s1_g2g_log = 0
    }
    
    if (s1_g2g_state == "NOT_STARTED"){
      s1_g2g_state = s1_g2g_start()
      Sys.sleep(2)
      s1_g2g_values$s1_g2g_log = 1
    }
    
    if (s1_g2g_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (s1_g2g_state == "TERMINATED")
      s1_g2g_term()
    
    print("")
  } # close value process    
  
  if(s1_g2g_values$s1_g2g_abort) {
    
    # delete the exit file
    unlink(s1_g2g_exitfile)
    
    # check whihc temp folder
    if (dir.exists(paste(s1_g2g_dir, "/TMP")))
        s1_g2g_tmp = paste(s1_g2g_dir, "/TMP")
    
    if (!dir.exists(paste(s1_g2g_dir, "/TMP")))
        s1_g2g_tmp = "/ram/SAR_TMP"
    
    print(s1_g2g_tmp)
    if (input$s1_g2g_input_type == "s1_g2g_file")
        system(paste("ost_cancel_proc \"sh -c ( ost_S1_grd2gtc", s1_g2g_args, "\"", s1_g2g_tmp))
    
    if (input$s1_g2g_input_type == "s1_g2g_folder")
        system(paste("ost_cancel_proc \"sh -c ( ost_S1_grd2gtc_bulk", s1_g2g_args, "\"", s1_g2g_tmp))
    
    s1_g2g_dir_message="User interruption"
    s1_g2g_js_string <- 'alert("Attention");'
    s1_g2g_js_string <- sub("Attention",s1_g2g_dir_message,s1_g2g_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2g_js_string))
    print("")
  }
  
}) # close render function

#---------------------------------------------------------------------------
# Progress monitor function
output$s1_g2g_progress = renderText({
  
  if(s1_g2g_values$s1_g2g_log) {
    
    s1_g2g_progress_file=file.path(s1_g2g_dir, "/.s1_g2g_progress")
    
    if(file.exists(s1_g2g_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", s1_g2g_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(s1_g2g_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# Demo section
# print_s1_g2ts_test = eventReactive(input$S1_ts_testdata_download, {
#   
#   # wrapper for busy indicator
#   withBusyIndicatorServer("S1_ts_testdata_download", {
#     
#     dir.create("~/S1_timeseries_demo/")
#     system2("wget","-O ~/S1_timeseries_demo/Demo_Jena.zip https://www.dropbox.com/s/edll1u6wrw8dcil/Demo_Jena.zip?dl=0")
#     unzip("~/S1_timeseries_demo/Demo_Jena.zip", exdir = "~/S1_timeseries_demo/")
#     file.remove("~/S1_timeseries_demo/Demo_Jena.zip")
#     print("Done!")
#     
#   })
# })
# 
# output$download_Demo_Jena = renderText({
#   print_s1_g2ts_test()
# })
#---------------------------------------------------------------------------