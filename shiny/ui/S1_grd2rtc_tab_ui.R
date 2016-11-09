

"Please type in your NASA Earthdata username/password. If you are not in possess of a user account: ",
a(href = "https://urs.earthdata.nasa.gov/", "Click Here!"),

textInput(inputId = "uname",
          label = "Username", 
          value = "Type in your username" 
),

passwordInput(inputId = "piwo",
              label = "Password",
              value = "Type in your password"
),
hr()#,