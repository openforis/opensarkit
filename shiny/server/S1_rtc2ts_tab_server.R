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
# Processing functions
print_s1_rtc2ts = eventReactive(input$s1_rtc2ts_process, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_rtc2ts_process", {
    
    if(is.null(input$s1_rtc2ts_inputdir)){
    stop("No project folder chosen")
    }
  
    else {
      volumes = c('User directory'=Sys.getenv("HOME"))
      PROC_DIR = parseDirPath(volumes, input$s1_rtc2ts_inputdir)
      MODE = input$s1_rtc2ts_mode
      DTYPE = input$s1_rtc2ts_dtype
      
      s1_rtc2ts_message="Processing started (This will take a while.)"
      js_string_s1_rtc2ts <- 'alert("Processing");'
      js_string_s1_rtc2ts <- sub("Processing",s1_rtc2ts_message,js_string_s1_rtc2ts)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_rtc2ts))

      ARG_PROC=paste(PROC_DIR, DTYPE, MODE)
      print(paste("ost_S1_rtc2ts", ARG_PROC))
      system(paste("ost_S1_rtc2ts", ARG_PROC),intern=TRUE)
    
      s1_rtc2ts_fin_message="Processing finished"
      js_string_s1_rtc2ts_fin <- 'alert("Processing");'
      js_string_s1_rtc2ts_fin <- sub("Processing",s1_rtc2ts_fin_message,js_string_s1_rtc2ts_fin)
      session$sendCustomMessage(type='jsCode', list(value = js_string_s1_rtc2ts_fin))
    } 
  })
})

output$processS1_RTC2TS = renderText({
  print_s1_rtc2ts()
  print(print_s1_rtc2ts())
  })

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
