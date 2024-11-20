library(shiny)

ui <- fluidPage(
  titlePanel("Test App"),
  sidebarLayout(
    sidebarPanel(),
    mainPanel(h3("Hello, Shiny!"))
  )
)

server <- function(input, output, session) {}

shinyApp(ui, server)