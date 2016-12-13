# 1 Choose a local folder 
output$S1_dow_project_dir = renderPrint({
  
  # root directory for file selection
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyDirChoose(input, 'S1_dow_directory', roots=volumes)
  
  validate (
    need(input$S1_dow_directory != "","No folder selected"),
    errorClass = "missing-folder"
  )
  
  df = parseDirPath(volumes, input$S1_dow_directory)
  cat(df) #}
})

# Choose a local file
output$S1_dow_filepath = renderPrint({
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  shinyFileChoose(input, 'S1_dow_shapefile', roots=volumes, filetypes=c('shp'))
  
  validate (
    need(input$S1_dow_shapefile != "","No shapefile selected"),
    errorClass = "missing-shapefile"
  )
  
  df = parseFilePaths(volumes, input$S1_dow_shapefile)
  file_path = as.character(df[,"datapath"])
  cat(file_path)
})


print_S1_dow = eventReactive(input$S1_download, {
  
  volumes = c('User directory'=Sys.getenv("HOME"))
  dummy=""
  # check if processing directory is chosen
  if (is.null(input$S1_dow_directory)){
    s1_dow_empty_dir_message="No download folder chosen"
    s1_dow_ed_js_string <- 'alert("SOMETHING");'
    s1_dow_ed_js_string <- sub("SOMETHING",s1_dow_empty_dir_message,s1_dow_ed_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_dow_ed_js_string))
  } else if (input$S1_DOWNFILE == "S1_AOI_shape_local"){
  
      if (is.null(input$S1_dow_shapefile)){
        s1_dow_empty_shp_message="No inventory shapefile chosen"
        s1_dow_ef_js_string <- 'alert("SOMETHING");'
        s1_dow_ef_js_string <- sub("SOMETHING",s1_dow_empty_shp_message,s1_dow_ef_js_string)
        session$sendCustomMessage(type='jsCode', list(value = s1_dow_ef_js_string))
      } else {
        dummy="dummy"
      }
    
  } else if (input$S1_DOWNFILE == "S1_AOI_zip_upload"){
  
    if (is.null(input$S1_zipfile_path)){
      s1_dow_empty_shp_message="No zip archive chosen"
      s1_dow_ef_js_string <- 'alert("SOMETHING");'
      s1_dow_ef_js_string <- sub("SOMETHING",s1_dow_empty_shp_message,s1_dow_ef_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_dow_ef_js_string))
    } else {
      dummy="dummy"
    }
  } else {
    dummy="dummy"
  }  
  
  if (dummy == "dummy"){
    
    # get project folder input
    volumes = c('User directory'=Sys.getenv("HOME"))
    DIR = parseDirPath(volumes, input$S1_dow_directory)
    
    # get inventory shapefile
    df = input$S1_zipfile_path
    ARCHIVE = df$datapath
    OUT_ARCHIVE = paste(DIR, "/Inventory_upload", sep = "")
    dir.create(OUT_ARCHIVE)
    unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
    OST_inv=list.files(OUT_ARCHIVE, pattern = "*.shp")
    INV_FILE = paste(OUT_ARCHIVE,"/",OST_inv,sep = "")
    
    # handling username and password data
    UNAME = paste("http_user=",input$s1_asf_uname, sep = "")
    PW = paste("http_password=",input$s1_asf_piwo,sep="")
    HOME_DIR = Sys.getenv("HOME")
    FILE = file.path(HOME_DIR,"wget.conf")
    write(UNAME, FILE)
    write(PW, FILE, append = TRUE)
    rm(UNAME)
    rm(PW)
    system("echo $USER", intern=FALSE)
    system(paste("chmod 600",FILE), intern=TRUE)
    
    ARG_DOWN=paste(DIR, INV_FILE, FILE)
    
    s1_dow_start_message="Started downloading (this will take a few hours)"
    s1_dow_js_string <- 'alert("Attention");'
    s1_dow_js_string <- sub("Attention",s1_dow_start_message,s1_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
    print(paste("oft-sar-S1-ASF-download",ARG_DOWN),intern=FALSE)
    system(paste("oft-sar-S1-ASF-download",ARG_DOWN),intern=FALSE)
    unlink(FILE)
    s1_dow_end_message="Finished downloading"
    s1_dow_js_string <- 'alert("SUCCESS");'
    s1_dow_js_string <- sub("SUCCESS",s1_dow_end_message,s1_dow_js_string)
    session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
    
  }
})   

output$S1_down = renderText({
  print_S1_dow()
})