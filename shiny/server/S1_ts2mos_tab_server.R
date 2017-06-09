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

#---------------------------------------------------------------------------
# Processing functions
print_s1_ts2mos = eventReactive(input$s1_ts2mos_process, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_ts2mos_process", {
    
    if(is.null(input$s1_ts2mos_inputdir)){
      stop("No project folder chosen")
    }
    
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      PROC_DIR = parseDirPath(volumes, input$s1_ts2mos_inputdir)
      #MODE = input$s1_ts2mos_mode
      
      
      s1_ts2mos_message="Processing started (This will take a while.)"
      js_string_s1_ts2mos <- 'alert("Processing");'
      js_string_s1_ts2mos <- sub("Processing",s1_ts2mos_message,js_string_s1_ts2mos)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_ts2mos))
      
      #ARG_PROC=paste(PROC_DIR, MODE)
      ARG_PROC=paste(PROC_DIR, "1")
      print(paste("ost_S1_ts2mosaic", ARG_PROC))
      system(paste("ost_S1_ts2mosaic", ARG_PROC),intern=TRUE)
      
      s1_ts2mos_fin_message="Processing finished"
      js_string_s1_ts2mos_fin <- 'alert("Processing");'
      js_string_s1_ts2mos_fin <- sub("Processing",s1_ts2mos_fin_message,js_string_s1_ts2mos_fin)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_ts2mos_fin))
    } 
  })
})

output$processS1_ts2mos = renderText({
  print_s1_ts2mos()
})
