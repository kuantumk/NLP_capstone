library(shiny)

shinyUI(fluidPage(
        titlePanel("Coursera Capstone NLP Project"),
        
        sidebarLayout(
                sidebarPanel(
                        textInput("text", label = h3("Type your text below:"), value = (""))
                ), #sidebarPanel
                
                mainPanel(
                        h5("The top 3 most probable next words are:"),
                        verbatimTextOutput("view")
                )
        ) #sidebarLayout
        
        ) #fluidPage
)