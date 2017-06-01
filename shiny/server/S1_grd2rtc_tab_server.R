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
# Processing functions
print_s1_g2r = eventReactive(input$s1_g2r_process, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("s1_g2r_process", {
  
    # original file choice
    if (input$s1_g2r_input_type == "file"){

      # empty input file message
      if(is.null(input$s1_g2r_zip)){
        stop("Choose a Sentinel-1 zip file")
      } 
    
      # empty output directy message
      else if(is.null(input$s1_g2r_outdir)){
        stop("Choose an output folder")
      }
  
      # processing
      else {
    
        volumes = c('User directory'=Sys.getenv("HOME"))
        df = parseFilePaths(volumes, input$s1_g2r_zip)
        INFILE = as.character(df[,"datapath"])
        OUTDIR = parseDirPath(volumes, input$s1_g2r_outdir)
    
        if (input$s1_g2r_res_file == "med_res"){
          RESOLUTION = "MED_RES" 
        } 
    
        else if (input$s1_g2r_res_file == "full_res"){
          RESOLUTION = "HI_RES" 
        }
    
        s1_g2r_message="Processing started (This will take a while.)"
        js_string_s1_g2r <- 'alert("Processing");'
        js_string_s1_g2r <- sub("Processing",s1_g2r_message,js_string_s1_g2r)
        session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
      
        ARG_PROC=paste(INFILE, OUTDIR, RESOLUTION)
        print(paste("ost_S1_grd2rtc", ARG_PROC))
        system(paste("ost_S1_grd2rtc", ARG_PROC))
      
        s1_g2r_fin_message="Processing finished"
        js_string_s1_g2r_fin <- 'alert("Processing");'
        js_string_s1_g2r_fin <- sub("Processing",s1_g2r_fin_message,js_string_s1_g2r_fin)
        session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r_fin))
      } 
    
    } 
    
    else if (input$s1_g2r_input_type == "folder"){

      if (is.null(input$s1_g2r_inputdir)){
        stop("Choose a folder")
      }
  
      else {
        volumes = c('User directory'=Sys.getenv("HOME"))
        PROCDIR = parseDirPath(volumes, input$s1_g2r_inputdir)
    
        if (input$s1_g2r_res_folder == "med_res"){
          RESOLUTION = "MED_RES" 
        } 
    
        else if (input$s1_g2r_res_folder == "full_res"){
          RESOLUTION = "HI_RES" 
        }
    
        if (input$s1_g2r_mode == "0"){
          MODE = "0" 
          TS_PROC = "0"
        } 
        
        else if (input$s1_g2r_mode == "1"){
          MODE = "1"
          TS_PROC = input$s1_g2r_ts 
        }
        
        s1_g2r_message="Processing started (This can take a considerable amount of time, dependent on the number of images to be processed)"
        js_string_s1_g2r <- 'alert("Processing");'
        js_string_s1_g2r <- sub("Processing",s1_g2r_message,js_string_s1_g2r)
        session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
        
        ARG_PROC=paste(PROCDIR, RESOLUTION, MODE, TS_PROC)
        print(paste("ost_S1_grd2rtc_bulk", ARG_PROC))
        system(paste("ost_S1_grd2rtc_bulk", ARG_PROC),intern=TRUE)
    
        s1_g2r_fin_message="Processing finished"
        js_string_s1_g2r_fin <- 'alert("Processing");'
        js_string_s1_g2r_fin <- sub("Processing",s1_g2r_fin_message,js_string_s1_g2r_fin)
        session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r_fin))
      } 
  
    } 
    
  })
})

output$processS1_G2R = renderText({
  print_s1_g2r()
})


print_s1_g2ts_test = eventReactive(input$S1_ts_testdata_download, {
  
  # wrapper for busy indicator
  withBusyIndicatorServer("S1_ts_testdata_download", {

    dir.create("~/S1_timeseries_demo/")
    system2("wget","-O ~/S1_timeseries_demo/Demo_Jena.zip https://www.dropbox.com/s/edll1u6wrw8dcil/Demo_Jena.zip?dl=0")
    unzip("~/S1_timeseries_demo/Demo_Jena.zip", exdir = "~/S1_timeseries_demo/")
    file.remove("~/S1_timeseries_demo/Demo_Jena.zip")
    print("Done!")
    
  })
})

output$download_Demo_Jena = renderText({
  print_s1_g2ts_test()
})