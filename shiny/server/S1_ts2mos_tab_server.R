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
