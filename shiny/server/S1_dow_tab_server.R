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

#------------------------------------------------------------------------------------------------
# main function calling the CL script
print_S1_dow = eventReactive(input$S1_download, {
  
  # invoke the busy indicator
  withBusyIndicatorServer("S1_download", {
  
    # get the root folder (i.e. home)
    volumes = c('User directory'=Sys.getenv("HOME"))
  
    # check if processing directory is chosen
    if (is.null(input$S1_dow_directory)){
      stop("Choose an output folder")
    } 
  
    else if ((input$S1_DOWNFILE == "S1_AOI_shape_local")&(is.null(input$S1_dow_shapefile))){
      stop("No inventory shapefile chosen")
    } 
  
    else if ((input$S1_DOWNFILE == "S1_AOI_zip_upload")&(is.null(input$S1_zipfile_path))){
      stop("No zip archive chosen")
    }
  
    else {
    
      # get project folder input
      volumes = c('User directory'=Sys.getenv("HOME"))
      DIR = parseDirPath(volumes, input$S1_dow_directory)
      
      # get inventory shapefile
      if (input$S1_DOWNFILE == "S1_AOI_shape_local"){
        df = parseFilePaths(volumes, input$S1_dow_shapefile)
        INV_FILE = as.character(df[,"datapath"])
      }
      else if (input$S1_DOWNFILE == "S1_AOI_zip_upload"){
        df = input$S1_zipfile_path
        ARCHIVE = df$datapath
        OUT_ARCHIVE = paste(DIR, "/Inventory_upload", sep = "")
        dir.create(OUT_ARCHIVE)
        unzip(ARCHIVE, junkpaths = TRUE, exdir = OUT_ARCHIVE)
        OST_inv=list.files(OUT_ARCHIVE, pattern = "*.shp")
        INV_FILE = paste(OUT_ARCHIVE,"/",OST_inv,sep = "")
      }
      
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
    
      # message for starting downloading
      s1_dow_start_message="Started downloading (this can take some time)"
      s1_dow_js_string <- 'alert("Attention");'
      s1_dow_js_string <- sub("Attention",s1_dow_start_message,s1_dow_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
      
      # construct OST CL command
      ARG_DOWN=paste(DIR, INV_FILE, FILE)
      print(paste("ost_S1_ASF_download",ARG_DOWN),intern=FALSE)
      system(paste("ost_S1_ASF_download",ARG_DOWN),intern=FALSE)
      
      # delete the wget conf
      unlink(FILE, force = TRUE)
      
      # message when all downloads finished
      s1_dow_end_message="Finished downloading"
      s1_dow_js_string <- 'alert("SUCCESS");'
      s1_dow_js_string <- sub("SUCCESS",s1_dow_end_message,s1_dow_js_string)
      session$sendCustomMessage(type='jsCode', list(value = s1_dow_js_string))
    
    }
  })
})   
#------------------------------------------------------------------------------------------------

output$S1_down = renderText({
  print_S1_dow()
})