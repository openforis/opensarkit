#---------------------------------------------------------------------------
# Folder processing
output$s1_g2ts_inputfolder = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2ts_inputdir', roots=volumes)
  
  validate (
    need(input$s1_g2ts_inputdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2ts_inputdir)
  cat(df) #}
})
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
# Inventory file
output$s1_g2ts_shp_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 's1_g2ts_shp', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$s1_g2ts_shp != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  df = parseFilePaths(volumes, input$s1_g2ts_shp)
  s1_g2ts_shp_file_path = as.character(df[,"datapath"])
  cat(s1_g2ts_shp_file_path)
})

# output folder 
output$s1_g2ts_outfolder = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2ts_outdir', roots=volumes)
  
  validate (
    need(input$s1_g2ts_outdir != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2ts_outdir)
  cat(df) #}
})

#---------------------------------------------------------------------------
# Processing functions
print_s1_g2ts = eventReactive(input$s1_g2ts_process, {
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  
if (input$s1_g2ts_input_type == "folder"){

  if(is.null(input$s1_g2ts_inputdir)){
    s1_g2t_dir_empty_dir_message="No output folder chosen"
    s1_g2t_dir_js_string <- 'alert("SOMETHING");'
    s1_g2t_dir_js_string <- sub("SOMETHING",s1_g2t_dir_empty_dir_message, s1_g2t_dir_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_dir_js_string))
  }
  
  else {
    volumes = c('User directory'=Sys.getenv("HOME"))
    OUTDIR = parseDirPath(volumes, input$s1_g2ts_inputdir)
    
    if (input$s1_g2ts_res == "med_res"){
      MODE = "MED_RES" 
    } 
    else if (input$s1_inv_pol == "full_res"){
      MODE = "HI_RES" 
    }
    
    ARG_PROC=paste(OUTDIR, MODE, "1")
    print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
    system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
  } 
  
} else if (input$s1_g2ts_input_type == "inventory"){
  
  if(is.null(input$s1_g2ts_shp)){
    s1_g2t_file_empty_shp_message="No S1 inputfile chosen"
    s1_g2t_file_js_string <- 'alert("SOMETHING");'
    s1_g2t_file_js_string <- sub("SOMETHING",s1_g2t_file_empty_shp_message,s1_g2t_file_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_file_js_string))
  } 
  
  else if(is.null(input$s1_g2ts_outdir)){
    s1_g2t_shp_empty_dir_message="No output folder chosen"
    s1_g2t_shp_js_string <- 'alert("SOMETHING");'
    s1_g2t_shp_js_string <- sub("SOMETHING",s1_g2t_shp_empty_dir_message, s1_g2t_shp_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_shp_js_string))
  }
  
  else {
    
    # download
    df = parseFilePaths(volumes, input$s1_g2ts_shp)
    INFILE = as.character(df[,"datapath"])
    
    volumes = c('User directory'=Sys.getenv("HOME"))
    OUTDIR = parseDirPath(volumes, input$s1_g2ts_outdir)
    
    # handling username and password data
    UNAME = paste("http_user=",input$s1_asf_uname2, sep = "")
    PW = paste("http_password=",input$s1_asf_piwo2,sep="")
    HOME_DIR = Sys.getenv("HOME")
    FILE = file.path(HOME_DIR,"wget.conf")
    write(UNAME, FILE)
    write(PW, FILE, append = TRUE)
    rm(UNAME)
    rm(PW)
    system("echo $USER", intern=FALSE)
    system(paste("chmod 600",FILE), intern=TRUE)
    
    ARG_DOWN=paste(OUTDIR, INFILE, FILE)
    print(paste("oft-sar-S1-ASF-download", ARG_DOWN))
    system(paste("oft-sar-S1-ASF-download", ARG_DOWN),intern=TRUE)
    
    # processing
    if (input$s1_g2ts_res == "med_res"){
      MODE = "MED_RES" 
    } 
    else if (input$s1_inv_pol == "full_res"){
      MODE = "HI_RES" 
    }
    
    OUTDIR_DATA = paste(OUTDIR,"/DATA",sep="")
    ARG_PROC=paste(OUTDIR_DATA, MODE, "1")
    print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
    system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
  } 
}
})


output$processS1_G2TS = renderText({
  print_s1_g2ts()
})