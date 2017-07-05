# 1 Choose a local folder 
output$s1_dow_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_dow_directory', roots=volumes)
  
  validate (
    need(input$s1_dow_directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_dow_directory)
  cat(df) #}
})

# Choose a local file
output$s1_dow_shape_path = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 's1_dow_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$s1_dow_shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$s1_dow_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})

#------------------------------------------------------------------------------------------------
# main function calling the CL script

# we create some values for reactive behaviour
s1_dow_values <- reactiveValues(s1_dow_pro = 0, s1_dow_abort = 0, s1_dow_log = 0)

# we create the reactive behaviour
observeEvent(input$s1_dow_pro_btn, {
  s1_dow_values$s1_dow_pro = 1
  s1_dow_values$s1_dow_abort = 0
  s1_dow_values$s1_dow_log = 1
})

observeEvent(input$s1_dow_abort_btn, {
  s1_dow_values$s1_dow_pro = 0
  s1_dow_values$s1_dow_abort = 1
})

#observeEvent(input$s1_dow_log_btn, {
#  s1_dow_values$s1_dow_log = 1
#})

# a function that returns the currrent state based on pid and exit file
s1_dow_get_state = function() {
  
  if(!exists("s1_dow_args"))
    return("INITIAL")
  else {
    # get the pid
    s1_dow_pid_cmd=paste("-ef | grep \"sh -c ( ost_S1_ASF_download", s1_dow_args, "\" | grep -v grep | awk '{print $2}'")
    s1_dow_pid = as.integer(system2("ps", args = s1_dow_pid_cmd, stdout = TRUE))
    #print(pid)
  }
  if (length(s1_dow_pid) > 0)
    return("RUNNING")
  
  if (file.exists(s1_dow_exitfile))
    return("TERMINATED")
  
  return("INITIAL")
} 

s1_dow_get_args = function() {
  
  # check if processing directory is chosen
  if (is.null(input$s1_dow_directory)){
    s1_dow_dir_message="Project directory not set"
    s1_dow_js_string <- 'alert("Attention");'
    s1_dow_js_string <- sub("Attention",s1_dow_dir_message,s1_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
    s1_dow_values$s1_dow_pro = 0
    s1_dow_values$s1_dow_log = 0
    return("INPUT_FAIL")
  } 
  
  else 
    if ((input$s1_dow_file_options == "s1_dow_shape")&(is.null(input$s1_dow_shapefile))){
      s1_dow_dir_message="No OST inventory shapefile selected."
      s1_dow_js_string <- 'alert("Attention");'
      s1_dow_js_string <- sub("Attention",s1_dow_dir_message,s1_dow_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
      s1_dow_values$s1_dow_pro = 0
      s1_dow_values$s1_dow_log = 0
      return("INPUT_FAIL")
    } 
  
  else
    if ((input$s1_dow_file_options == "s1_dow_zip")&(is.null(input$s1_dow_zipfile))){
      s1_dow_dir_message="No zip-archive selected."
      s1_dow_js_string <- 'alert("Attention");'
      s1_dow_js_string <- sub("Attention",s1_dow_dir_message,s1_dow_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
      s1_dow_values$s1_dow_pro = 0
      s1_dow_values$s1_dow_log = 0
      return("INPUT_FAIL")
    }
  
  else {
    # get project folder input
    volumes = c('User directory'=Sys.getenv("HOME"))
    s1_dow_dir <<- parseDirPath(volumes, input$s1_dow_directory)
    
    # get inventory shapefile
    if (input$s1_dow_file_options == "s1_dow_shape"){
      df = parseFilePaths(volumes, input$s1_dow_shapefile)
      s1_dow_inv_file = as.character(df[,"datapath"])
    }
    
    else 
      if (input$s1_dow_file_options == "s1_dow_zip"){
        df = input$s1_dow_zipfile
        ARCHIVE = df$datapath
        OUT_ARCHIVE = paste(s1_dow_dir, "/Inventory_upload", sep = "")
        dir.create(OUT_ARCHIVE)
        unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
        OST_inv=list.files(OUT_ARCHIVE, pattern = "*.shp")
        s1_dow_inv_file = paste(OUT_ARCHIVE,"/",OST_inv,sep = "")
      }
    
    # handling username and password data
    #get uname & pw
    UNAME = paste("http_user=",input$s1_asf_uname, sep = "")
    PW = paste("http_password=",input$s1_asf_piwo,sep="")
    
    # create a wget file and fill with relevant content
    dir.create(paste(s1_dow_dir,"/.TMP/", sep = ""))
    s1_dow_wget <<- file.path(s1_dow_dir,".TMP/wget.conf")
    write(UNAME, s1_dow_wget)
    write(PW, s1_dow_wget, append = TRUE)
    
    # remove variables and change access rights
    rm(UNAME)
    rm(PW)
    system(paste("chmod 600", s1_dow_wget), intern=TRUE)
    
    # get the arguments for file execution, proper cancellation etc. and export as global variable (<<-)
    s1_dow_args <<- paste(s1_dow_dir, s1_dow_inv_file, s1_dow_wget)
    
    # set the name of an exit file for checking success of processing and export as global variable
    s1_dow_exitfile <<- paste(s1_dow_dir, "/.s1_dow_exitfile", sep="")
    
    return("NOT_STARTED")
  }
}

# start fucntion that runs the processing 
s1_dow_start = function() {
  
  # invoke the busy indicator
  withBusyIndicatorServer("S1_download", {
    
    # message for starting the download
    s1_dow_start_message="Started downloading (this can take some time)"
    s1_dow_js_string <- 'alert("Attention");'
    s1_dow_js_string <- sub("Attention",s1_dow_start_message,s1_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
    
    # run OST command
    #print(paste("( ost_S1_ASF_download", s1_dow_args, "; echo $? >", s1_dow_exitfile,")"))
    system(paste("( ost_S1_ASF_download", s1_dow_args, "; echo $? >", s1_dow_exitfile, ")"), wait = FALSE, intern = FALSE)
    return("RUNNING")
  
    }) # close busy indicator
} # close start function

# when processing is script is finished we want to check if everything went fine
s1_dow_term = function() {
  # get the exit state of the script
  s1_dow_status = readLines(s1_dow_exitfile)
  
  # we want to remove the exit file for the next run
  unlink(s1_dow_exitfile, force = TRUE)
  unlink(s1_dow_wget , force = TRUE)
  
  # message when all downloads finished/failed
  if ( s1_dow_status == 2 ){
    s1_dow_end_message="Username/Password Authentication Failed."
    s1_dow_js_string <- 'alert("SUCCESS");'
    s1_dow_js_string <- sub("SUCCESS",s1_dow_end_message,s1_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
  }
  
  else
    if ( s1_dow_status == 3 ){
      s1_dow_end_message="Having problems with downloading. Try again!"
      s1_dow_js_string <- 'alert("SUCCESS");'
      s1_dow_js_string <- sub("SUCCESS",s1_dow_end_message,s1_dow_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
    }
  
  else {
    s1_dow_end_message="Succesfully finished downloading."
    s1_dow_js_string <- 'alert("SUCCESS");'
    s1_dow_js_string <- sub("SUCCESS",s1_dow_end_message,s1_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
    
  }
  # reset downoading button for next download
  s1_dow_values$s1_dow_pro = 0
}

# we tell what the reactive behaviour should do
output$s1_dow = renderText({

    # trigger processing when action button clicked
    if(s1_dow_values$s1_dow_pro) {
      
      # run the state function
      s1_dow_state = s1_dow_get_state() # Can be NOT_STARTED, RUNNING, TERMINATED
      
      if (s1_dow_state == "INITIAL"){
        s1_dow_state = s1_dow_get_args()
        unlink(paste(s1_dow_dir, "/.s1_dow_progress"))
        s1_dow_values$s1_dow_log = 0
      }
      
      if (s1_dow_state == "NOT_STARTED"){
        s1_dow_state = s1_dow_start()
        Sys.sleep(2)
        s1_dow_values$s1_dow_log = 1
      }
      
      if (s1_dow_state == "RUNNING")
        invalidateLater(2000, session = getDefaultReactiveDomain())
        
      if (s1_dow_state == "TERMINATED")
        s1_dow_term()
    
      print("")
    } # close value process    
  
  if(s1_dow_values$s1_dow_abort) {
      
    unlink(s1_dow_exitfile)
    unlink(s1_dow_wget)
    
    print(paste("ost_cancel_proc \"sh -c ( ost_S1_ASF_download", s1_dow_args, "\"", paste(s1_dow_dir, "/.TMP", sep = "")))
    system(paste("ost_cancel_proc \"sh -c ( ost_S1_ASF_download", s1_dow_args, "\"", paste(s1_dow_dir, "/.TMP", sep = "")))
    s1_dow_dir_message="User interruption"
    s1_dow_js_string <- 'alert("Attention");'
    s1_dow_js_string <- sub("Attention",s1_dow_dir_message,s1_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
    print("")
    }
})  # close render text function 
#------------------------------------------------------------------------------------------------

output$s1_dow_progress = renderText({

  if(s1_dow_values$s1_dow_log) {
  
    s1_dow_progress_file=file.path(s1_dow_dir, "/.s1_dow_progress")
    #????????????????????????????????????
    # use tail for maximum of 2000 lines 
    #????????????????????????????????????
    
    if(file.exists(s1_dow_progress_file)){
      NLI = as.integer(system2("wc", args = c("-l", s1_dow_progress_file," | awk '{print $1}'"), stdout = TRUE))
      NLI = NLI + 1 
      invalidateLater(2000)
      paste(readLines(s1_dow_progress_file, n = NLI, warn = FALSE), collapse = "\n")
    }
    else{
      print("No process seems to be running. Make sure you selected the correct Project Directory in the processing panel. ")
    }
  }  
})