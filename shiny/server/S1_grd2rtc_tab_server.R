#---------------------------------------------------------------------------
# Functions for Original File choice

# Choose a S1 zip file
output$s1_g2r_zip = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 's1_g2r_zip', roots=volumes, filetypes=c('zip','dim'))
  
  validate (
    need(input$s1_g2r_zip != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$s1_g2r_zip)
  s1_g2r_zip_file_path = as.character(df[,"datapath"])
  cat(s1_g2r_zip_file_path)
})

# output folder 
output$s1_g2r_outdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2r_outdir', roots=volumes)
  
  validate (
    need(input$s1_g2r_outdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2r_outdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Warning messages
memtotal = as.numeric(system("awk '/MemTotal/ {print $2}' /proc/meminfo",intern=TRUE))
if (memtotal < 15000000) {
  if ( nchar(Sys.getenv('SEPAL')) > 0){
    output$RAMwarning <- renderText({"WARNING: You do NOT have enough RAM on your machine for running this processing. Please go to the Terminal,
                                      manually start an instance with at least 16 GB of RAM and restart the SAR toolkit in the processing menu. "})
  } else {
    output$RAMwarning <- renderText({"WARNING: You do NOT have enough RAM on your machine for running this processing. Make sure your PC has at least 16 GB of RAM."})
  }
} else {
  output$RAMwarning <- renderText({""})
}
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Folder processing
output$s1_g2r_inputdir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2r_inputdir', roots=volumes)
  
  validate (
    need(input$s1_g2r_inputdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2r_inputdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# reactive values and observe events
# we create some values for reactive behaviour
s1_g2r_values <- reactiveValues(s1_g2r_pro = 0, s1_g2r_abort = 0, s1_g2r_log = 0)

# we create the reactive behaviour
observeEvent(input$s1_g2r_pro_btn, {
  s1_g2r_values$s1_g2r_pro = 1
  s1_g2r_values$s1_g2r_abort = 0
  s1_g2r_values$s1_g2r_log = 1
})

observeEvent(input$s1_g2r_abort_btn, {
  s1_g2r_values$s1_g2r_pro = 0
  s1_g2r_values$s1_g2r_abort = 1
})

#observeEvent(input$s1_g2r_log_btn, {
#  s1_g2r_values$s1_g2r_log = 1
#})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# a function that returns the currrent state based on pid and exit file
s1_g2r_get_state = function() {
  
  if(!exists("s1_g2r_args"))
    return("INITIAL")
  else {
    # get the pid
    if (input$s1_g2r_input_type == "s1_g2r_file")
      s1_g2r_pid_cmd=paste("-ef | grep \"sh -c ( ost_S1_grd2rtc", s1_g2r_args, "\" | grep -v grep | awk '{print $2}'")
  
    if (input$s1_g2r_input_type == "s1_g2r_folder")
      s1_g2r_pid_cmd=paste("-ef | grep \"sh -c ( ost_S1_grd2rtc_bulk", s1_g2r_args, "\" | grep -v grep | awk '{print $2}'")
  
    s1_g2r_pid = as.integer(system2("ps", args = s1_g2r_pid_cmd, stdout = TRUE))
  }

  if (length(s1_g2r_pid) > 0)
    return("RUNNING")
  
  if (file.exists(s1_g2r_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# get the input arguments from the GUI
s1_g2r_get_args = function(){
  
  # original file choice
  if (input$s1_g2r_input_type == "s1_g2r_file"){
    
    # empty input file message
    if(is.null(input$s1_g2r_zip)){
      s1_g2r_dir_message=" No Sentinel-1 product selected"
      s1_g2r_js_string <- 'alert("Attention");'
      s1_g2r_js_string <- sub("Attention",s1_g2r_dir_message,s1_g2r_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_g2r_js_string))
      s1_g2r_values$s1_g2r_pro = 0
      s1_g2r_values$s1_g2r_log = 0
      return("INPUT_FAIL")
    } 
    
    # empty output directy message
    else if(is.null(input$s1_g2r_outdir)){
      s1_g2r_dir_message=" No output folder selected"
      s1_g2r_js_string <- 'alert("Attention");'
      s1_g2r_js_string <- sub("Attention",s1_g2r_dir_message,s1_g2r_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_g2r_js_string))
      s1_g2r_values$s1_g2r_pro = 0
      s1_g2r_values$s1_g2r_log = 0
      return("INPUT_FAIL")
    }
    
    # processing
    else {
      
      volumes = c('User directory'=Sys.getenv("HOME"))
      s1_g2r_df = parseFilePaths(volumes, input$s1_g2r_zip)
      s1_g2r_infile = as.character(s1_g2r_df[,"datapath"])
      s1_g2r_outdir = parseDirPath(volumes, input$s1_g2r_outdir)
      
      if (input$s1_g2r_res_file == "med_res"){
        s1_g2r_resolution = "MED_RES" 
      } 
      
      else if (input$s1_g2r_res_file == "full_res"){
        s1_g2r_resolution = "HI_RES" 
      }
  
      # single file arguments     
      s1_g2r_args <<- paste(s1_g2r_infile, s1_g2r_outdir, s1_g2r_resolution)
      
      # get the dir of the outfile
      s1_g2r_dir <<- dirname(s1_g2r_infile)
      
      # create a exitfile path and export as global variable
      s1_g2r_exitfile <<- paste(s1_g2r_dir, "/.exitfile", sep="")
      
      s1_g2r_tmp <<- paste(s1_g2r_dir, "/TMP")
      
      # return new state
      return("NOT_STARTED")
    } 
    
  } 
  
  else if (input$s1_g2r_input_type == "s1_g2r_folder"){
    
    if (is.null(input$s1_g2r_inputdir)){
      s1_g2r_dir_message=" No project directory selected"
      s1_g2r_js_string <- 'alert("Attention");'
      s1_g2r_js_string <- sub("Attention",s1_g2r_dir_message,s1_g2r_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_g2r_js_string))
      s1_g2r_values$s1_g2r_pro = 0
      s1_g2r_values$s1_g2r_log = 0
      return("INPUT_FAIL")
      
    }
    
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      s1_g2r_dir <<- parseDirPath(volumes, input$s1_g2r_inputdir)
      
      if (input$s1_g2r_res_folder == "med_res"){
        s1_g2r_resolution = "MED_RES" 
      } 
      
      else if (input$s1_g2r_res_folder == "full_res"){
        s1_g2r_resolution = "HI_RES" 
      }
      
      if (input$s1_g2r_mode == "0"){
        MODE = "0" 
        TS_PROC = "0"
      } 
      
      else if (input$s1_g2r_mode == "1"){
        MODE = "1"
        TS_PROC = input$s1_g2r_ts 
      }
 
      # decide to apply LS map based on number of tracks
      if (length(Sys.glob(file.path(s1_g2r_dir, "[0-9]*"))) > 1){
        s1_g2r_ls = "0"  
      }
      else {
        s1_g2r_ls = "1"
      }
      
      # set arguments as global variable
      s1_g2r_args <<- paste(s1_g2r_dir, s1_g2r_resolution, MODE, TS_PROC, s1_g2r_ls)     
      
      # create a exitfile path and export as global variable
      s1_g2r_exitfile <<- paste(s1_g2r_dir, "/.exitfile", sep="")
      
      # return new state
      return("NOT_STARTED")
    }
  }
}

#---------------------------------------------------------------------------
# start function that triggers the processing 
s1_g2r_start = function() {
    
    # wrapper for busy indicator
    withBusyIndicatorServer("s1_g2r_pro_btn", {
      
      if (input$s1_g2r_input_type == "s1_g2r_file"){
        s1_g2r_message="Processing started (This can take a moment)"
        js_string_s1_g2r <- 'alert("Processing");'
        js_string_s1_g2r <- sub("Processing",s1_g2r_message,js_string_s1_g2r)
        session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
        
        # run processing
        system(paste("( ost_S1_grd2rtc", s1_g2r_args, "; echo $? >", s1_g2r_exitfile, ")"), wait = FALSE, intern=FALSE)
        
        return("RUNNING")
      }
      
      if (input$s1_g2r_input_type == "s1_g2r_folder"){
        s1_g2r_message="Processing started (This can take a considerable amount of time, dependent on the number of images to be processed)"
        js_string_s1_g2r <- 'alert("Processing");'
        js_string_s1_g2r <- sub("Processing",s1_g2r_message,js_string_s1_g2r)
        session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
  
        # run processing
        system(paste("( ost_S1_grd2rtc_bulk", s1_g2r_args ,"; echo $? >", s1_g2r_exitfile, ")"), wait = FALSE, intern=FALSE)
        
        return("RUNNING")
      }
    })
}

#---------------------------------------------------------------------------
# Termination Function (what to do when script stopped)
s1_g2r_term = function() {
  
  # get the exit state of the script
  s1_g2r_status = readLines(s1_g2r_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(s1_g2r_exitfile, force = TRUE)
  
  # message when all downloads finished/failed
  if ( s1_g2r_status != 0 ){
    s1_g2r_end_message="Processing failed. Check the Progress Monitor."
    s1_g2r_js_string <- 'alert("SUCCESS");'
    s1_g2r_js_string <- sub("SUCCESS",s1_g2r_end_message,s1_g2r_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2r_js_string))
  }
  
  else {
    # Pop-up message for having finished data inventory
    s1_g2r_fin_message="Processing finished"
    js_string_s1_g2r_fin <- 'alert("Processing");'
    js_string_s1_g2r_fin <- sub("Processing",s1_g2r_fin_message,js_string_s1_g2r_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r_fin))
  }
 
   # reset button to 0 for enable re-start
  s1_g2r_values$s1_g2r_pro = 0
}  
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# main function triggering processing and controlling state
output$processS1_G2R = renderText({
  
  # trigger processing when action button clicked
  if(s1_g2r_values$s1_g2r_pro) {
    
    #run the state function
    s1_g2r_state = s1_g2r_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
    
    if (s1_g2r_state == "INITIAL"){
      s1_g2r_state = s1_g2r_get_args()
      unlink(paste(s1_g2r_dir, "/.s1_g2r_progress"))
      s1_g2r_values$s1_g2r_log = 0
      }
    
    if (s1_g2r_state == "NOT_STARTED"){
      s1_g2r_state = s1_g2r_start()
      Sys.sleep(2)
      s1_g2r_values$s1_g2r_log = 1
    }
    
    if (s1_g2r_state == "RUNNING")
      invalidateLater(2000, session = getDefaultReactiveDomain())
    
    if (s1_g2r_state == "TERMINATED")
      s1_g2r_term()
    
    print("")
  } # close value process    
  
  if(s1_g2r_values$s1_g2r_abort) {
    
    # delete the exit file
    unlink(s1_g2r_exitfile)
    
    # check whihc temp folder
    if (dir.exists(paste(s1_g2r_dir, "/TMP")))
      s1_g2r_tmp = paste(s1_g2r_dir, "/TMP")
    
    if (!dir.exists(paste(s1_g2r_dir, "/TMP")))
      s1_g2r_tmp = "/ram/SAR_TMP"
    
    print(s1_g2r_tmp)
    if (input$s1_g2r_input_type == "s1_g2r_file")
      system(paste("ost_cancel_proc \"sh -c ( ost_S1_grd2rtc", s1_g2r_args, "\"", s1_g2r_tmp))

    if (input$s1_g2r_input_type == "s1_g2r_folder")
      system(paste("ost_cancel_proc \"sh -c ( ost_S1_grd2rtc_bulk", s1_g2r_args, "\"", s1_g2r_tmp))
    
    s1_g2r_dir_message="User interruption"
    s1_g2r_js_string <- 'alert("Attention");'
    s1_g2r_js_string <- sub("Attention",s1_g2r_dir_message,s1_g2r_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2r_js_string))
    print("")
  }
  
}) # close render function

#---------------------------------------------------------------------------
# Progress monitor function
output$s1_g2r_progress = renderText({
  
  if(s1_g2r_values$s1_g2r_log) {
    
    s1_g2r_progress_file=file.path(s1_g2r_dir, "/.s1_g2r_progress")
    
    if(file.exists(s1_g2r_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", s1_g2r_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(s1_g2r_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running")
    }
  }  
})
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# Demo section
print_s1_g2r_l1a = eventReactive(input$S1_g2r_l1a, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("S1_g2r_l1a", {

    dir.create("~/OST_demos/S1/Lecture_1a/Inventory", recursive = TRUE)
    system2("wget","-O ~/OST_demos/S1/Lecture_1a/Inventory/s1_ssv_example.zip https://www.dropbox.com/s/iszfnjgrzze6uzd/s1_ssv_example.zip?dl=0")
    unzip("~/OST_demos/S1/Lecture_1a/Inventory/s1_ssv_example.zip", exdir = "~/OST_demos/S1/Lecture_1a/Inventory/")
    file.remove("~/OST_demos/S1/Lecture_1a/Inventory/s1_ssv_example.zip")
    print("Done!")
    
  })
})

output$download_s1_L1A = renderText({
  print_s1_g2r_l1a()
})
#---------------------------------------------------------------------------
