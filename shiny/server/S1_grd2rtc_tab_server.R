#---------------------------------------------------------------------------
# Functions for Original File choice

# Choose a S1 zip file
output$s1_g2r_zip_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 's1_g2r_zip', roots=volumes, filetypes=c('zip'))
  
  validate (
    need(input$s1_g2r_zip != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$s1_g2r_zip)
  s1_g2r_zip_file_path = as.character(df[,"datapath"])
  cat(s1_g2r_zip_file_path)
})

# output folder 
output$s1_g2r_outfolder = renderPrint({
  
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
# Folder processing
output$s1_g2r_inputfolder = renderPrint({
  
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
# Inventory file
output$s1_g2r_shp_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 's1_g2r_shp', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$s1_g2r_shp != "","No file selected"),
    errorClass = "missing-shapefile"
  )
  df = parseFilePaths(volumes, input$s1_g2r_shp)
  s1_g2r_shp_file_path = as.character(df[,"datapath"])
  cat(s1_g2r_shp_file_path)
})

# output folder 
output$s1_g2r_outfolder2 = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2r_outdir2', roots=volumes)
  
  validate (
    need(input$s1_g2r_outdir2 != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2r_outdir2)
  cat(df) #}
})

#---------------------------------------------------------------------------
# Zip file
# output folder 
output$s1_g2r_outfolder3 = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 's1_g2r_outdir3', roots=volumes)
  
  validate (
    need(input$s1_g2r_outdir3 != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$s1_g2r_outdir3)
  cat(df) #}
})
#---------------------------------------------------------------------------


#---------------------------------------------------------------------------
# Processing functions
print_s1_g2r = eventReactive(input$s1_g2r_process, {
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  
# original file choice
if (input$s1_g2r_input_type == "file"){

  # empty input file message
  if(is.null(input$s1_g2r_zip)){
    s1_g2t_zip_empty_file_message="No S1 inputfile chosen"
    s1_g2t_zip_js_string <- 'alert("SOMETHING");'
    s1_g2t_zip_js_string <- sub("SOMETHING",s1_g2t_zip_empty_file_message,s1_g2t_zip_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_zip_js_string))
  } 
  # empty output directy message
  else if(is.null(input$s1_g2r_outdir)){
    s1_g2t_file_empty_dir_message="No output folder chosen"
    s1_g2t_file_js_string <- 'alert("SOMETHING");'
    s1_g2t_file_js_string <- sub("SOMETHING",s1_g2t_file_empty_dir_message, s1_g2t_file_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_file_js_string))
  }
  
  # processing
  else {
    df = parseFilePaths(volumes, input$s1_g2r_zip)
    INFILE = as.character(df[,"datapath"])
    
    volumes = c('User directory'=Sys.getenv("HOME"))
    OUTDIR = parseDirPath(volumes, input$s1_g2r_outdir)
    
    if (input$s1_g2r_res == "med_res"){
      MODE = "MED_RES" 
    } 
    else if (input$s1_inv_pol == "full_res"){
      MODE = "HI_RES" 
    }
    
    ARG_PROC=paste(INFILE, OUTDIR, MODE)
    print(paste("oft-sar-S1-GRD-single-preprocess", ARG_PROC))
    
    s1_g2r_message="Processing started (This will take a while.)"
    js_string_s1_g2r <- 'alert("Processing");'
    js_string_s1_g2r <- sub("Processing",s1_g2r_message,js_string_s1_g2r)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
    system(paste("oft-sar-S1-GRD-single-preprocess", ARG_PROC))
    s1_g2r_fin_message="Processing finished"
    js_string_s1_g2r_fin <- 'alert("Processing");'
    js_string_s1_g2r_fin <- sub("Processing",s1_g2r_fin_message,js_string_s1_g2r_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r_fin))
  } 
    
} else if (input$s1_g2r_input_type == "folder"){

  if(is.null(input$s1_g2r_inputdir)){
    s1_g2t_dir_empty_dir_message="No output folder chosen"
    s1_g2t_dir_js_string <- 'alert("SOMETHING");'
    s1_g2t_dir_js_string <- sub("SOMETHING",s1_g2t_dir_empty_dir_message, s1_g2t_dir_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_dir_js_string))
  }
  
  else {
    volumes = c('User directory'=Sys.getenv("HOME"))
    OUTDIR = parseDirPath(volumes, input$s1_g2r_inputdir)
    
    if (input$s1_g2r_res == "med_res"){
      MODE = "MED_RES" 
    } 
    else if (input$s1_inv_pol == "full_res"){
      MODE = "HI_RES" 
    }
    
    ARG_PROC=paste(OUTDIR, MODE, "0","> ~/log_processing")
    print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
    
    s1_g2r_message="Processing started (This can take a considerable amount of time, dependent on the number of images to be processed)"
    js_string_s1_g2r <- 'alert("Processing");'
    js_string_s1_g2r <- sub("Processing",s1_g2r_message,js_string_s1_g2r)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
    system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
    s1_g2r_fin_message="Processing finished"
    js_string_s1_g2r_fin <- 'alert("Processing");'
    js_string_s1_g2r_fin <- sub("Processing",s1_g2r_fin_message,js_string_s1_g2r_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r_fin))
  } 
  
} else if (input$s1_g2r_input_type == "inventory"){
  
  if(is.null(input$s1_g2r_shp)){
    s1_g2t_file_empty_shp_message="No S1 inputfile chosen"
    s1_g2t_file_js_string <- 'alert("SOMETHING");'
    s1_g2t_file_js_string <- sub("SOMETHING",s1_g2t_file_empty_shp_message,s1_g2t_file_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_file_js_string))
  } 
  
  else if(is.null(input$s1_g2r_outdir2)){
    s1_g2t_shp_empty_dir_message="No output folder chosen"
    s1_g2t_shp_js_string <- 'alert("SOMETHING");'
    s1_g2t_shp_js_string <- sub("SOMETHING",s1_g2t_shp_empty_dir_message, s1_g2t_shp_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_shp_js_string))
  }

  else {
    
    # download
    df = parseFilePaths(volumes, input$s1_g2r_shp)
    INFILE = as.character(df[,"datapath"])
    
    volumes = c('User directory'=Sys.getenv("HOME"))
    OUTDIR = parseDirPath(volumes, input$s1_g2r_outdir2)
    
    # handling username and password data
    UNAME = paste("http_user=",input$s1_asf_uname3, sep = "")
    PW = paste("http_password=",input$s1_asf_piwo3,sep="")
    HOME_DIR = Sys.getenv("HOME")
    FILE = file.path(HOME_DIR,"wget.conf")
    write(UNAME, FILE)
    write(PW, FILE, append = TRUE)
    rm(UNAME)
    rm(PW)
    system(paste("chmod 600",FILE), intern=TRUE)
    
    s1_g2r_message="Download of scenes started (This can take some time.)"
    js_string_s1_g2r <- 'alert("Download");'
    js_string_s1_g2r <- sub("Download",s1_g2r_message,js_string_s1_g2r)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
    ARG_DOWN=paste(OUTDIR, INFILE, FILE)
    print(paste("oft-sar-S1-ASF-download", ARG_DOWN))
    system(paste("oft-sar-S1-ASF-download", ARG_DOWN),intern=TRUE)
    unlink(FILE)
    # processing
    if (input$s1_g2r_res == "med_res"){
      MODE = "MED_RES" 
    } 
    else if (input$s1_inv_pol == "full_res"){
      MODE = "HI_RES" 
    }
    s1_g2r_message2="Download finished. Start to process the imagery. Stay patient!"
    js_string_s1_g2r2 <- 'alert("Processing");'
    js_string_s1_g2r2 <- sub("Processing",s1_g2r_message2,js_string_s1_g2r2)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r2))
    OUTDIR_DATA = paste(OUTDIR,"/DATA",sep="")
    ARG_PROC=paste(OUTDIR_DATA, MODE, "0")
    print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
    system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
    s1_g2r_fin_message="Processing finished"
    js_string_s1_g2r_fin <- 'alert("Processing");'
    js_string_s1_g2r_fin <- sub("Processing",s1_g2r_fin_message,js_string_s1_g2r_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r_fin))
  } 
} else if (input$s1_g2r_input_type == "zipfile"){
  
  if(is.null(input$S1_grd2rtc_zipfile_path)){
    s1_g2t_file_empty_shp_message="No zip archive chosen"
    s1_g2t_file_js_string <- 'alert("SOMETHING");'
    s1_g2t_file_js_string <- sub("SOMETHING",s1_g2t_file_empty_shp_message,s1_g2t_file_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_file_js_string))
  } 
  
  else if(is.null(input$s1_g2r_outdir3)){
    s1_g2t_shp_empty_dir_message="No output folder chosen"
    s1_g2t_shp_js_string <- 'alert("SOMETHING");'
    s1_g2t_shp_js_string <- sub("SOMETHING",s1_g2t_shp_empty_dir_message, s1_g2t_shp_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_g2t_shp_js_string))
  }
  
  else {
    
    volumes = c('User directory'=Sys.getenv("HOME"))
    OUTDIR = parseDirPath(volumes, input$s1_g2r_outdir3)
    
    df = input$S1_grd2rtc_zipfile_path
    ARCHIVE = df$datapath
    OUT_ARCHIVE = paste(OUTDIR, "/Inventory_upload", sep = "")
    dir.create(OUT_ARCHIVE)
    unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
    OST_inv=list.files(OUT_ARCHIVE, pattern = "*.shp")
    INFILE = paste(OUT_ARCHIVE,"/",OST_inv,sep = "")
    
    # handling username and password data
    UNAME = paste("http_user=",input$s1_asf_uname4, sep = "")
    PW = paste("http_password=",input$s1_asf_piwo4,sep="")
    HOME_DIR = Sys.getenv("HOME")
    FILE = file.path(HOME_DIR,"wget.conf")
    print(FILE)
    write(UNAME, FILE)
    write(PW, FILE, append = TRUE)
    rm(UNAME)
    rm(PW)
    system("echo $USER", intern=FALSE)
    system(paste("chmod 600",FILE), intern=TRUE)
    
    s1_g2r_message="Download of scenes started (This can take some time.)"
    js_string_s1_g2r <- 'alert("Download");'
    js_string_s1_g2r <- sub("Download",s1_g2r_message,js_string_s1_g2r)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r))
    ARG_DOWN=paste(OUTDIR, INFILE, FILE)
    print(paste("oft-sar-S1-ASF-download", ARG_DOWN))
    system(paste("oft-sar-S1-ASF-download", ARG_DOWN),intern=TRUE)
    #unlink(FILE)
    # processing
    if (input$s1_g2r_res == "med_res"){
      MODE = "MED_RES" 
    } 
    else if (input$s1_inv_pol == "full_res"){
      MODE = "HI_RES" 
    }
    s1_g2r_message2="Download finished. Start to process the imagery. Stay patient!"
    js_string_s1_g2r2 <- 'alert("Processing");'
    js_string_s1_g2r2 <- sub("Processing",s1_g2r_message2,js_string_s1_g2r2)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r2))
    OUTDIR_DATA = paste(OUTDIR,"/DATA",sep="")
    ARG_PROC=paste(OUTDIR_DATA, MODE, "0")
    print(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC))
    system(paste("oft-sar-S1-GRD-MT-bulk-preprocess", ARG_PROC),intern=TRUE)
    s1_g2r_fin_message="Processing finished"
    js_string_s1_g2r_fin <- 'alert("Processing");'
    js_string_s1_g2r_fin <- sub("Processing",s1_g2r_fin_message,js_string_s1_g2r_fin)
    session$sendCustomMessage(type='jsCode', list(value = js_string_s1_g2r_fin))
    
  }
}

})


output$processS1_G2R = renderText({
  print_s1_g2r()
})