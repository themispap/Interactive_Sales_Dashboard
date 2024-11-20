library(shiny)
library(DT)
library(dplyr)

ui <- fluidPage(
  titlePanel("Interactive Sales Dashboard"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Upload Sales Data (CSV)", accept = c(".csv")),
      uiOutput("region_filter"),
      dateRangeInput("date_filter", "Select Date Range:", start = Sys.Date() - 30, end = Sys.Date()),
      actionButton("update", "Update Dashboard")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Table", DTOutput("data_table")),
        tabPanel("Summary", verbatimTextOutput("summary")),
        tabPanel("Visualization", plotOutput("sales_plot"))
      )
    )
  )
)

server <- function(input, output, session) {
  sales_data <- reactiveVal()
  
  observeEvent(input$file, {
    req(input$file)
    data <- read.csv(input$file$datapath)
    sales_data(data)
  })
  
  output$region_filter <- renderUI({
    req(sales_data())
    selectInput("region", "Select Region:", choices = unique(sales_data()$Region), multiple = TRUE)
  })
  
  filtered_data <- reactive({
    req(sales_data())
    data <- sales_data()
    if (!is.null(input$region)) {
      data <- data[data$Region %in% input$region, ]
    }
    if (!is.null(input$date_filter)) {
      data <- data[data$Date >= as.Date(input$date_filter[1]) &
                     data$Date <= as.Date(input$date_filter[2]), ]
    }
    data
  })
  
  output$data_table <- renderDT({
    req(filtered_data())
    datatable(filtered_data())
  })
  
  output$summary <- renderPrint({
    req(filtered_data())
    data <- filtered_data()
    data.frame(
      Total_Sales = sum(data$Sales, na.rm = TRUE),
      Average_Sales = mean(data$Sales, na.rm = TRUE),
      Total_Transactions = nrow(data)
    )
  })
  
  output$sales_plot <- renderPlot({
    req(filtered_data())
    data <- filtered_data()
    ggplot(data, aes(x = Date, y = Sales, color = Region)) +
      geom_line() +
      theme_minimal() +
      labs(title = "Sales Trends", x = "Date", y = "Sales")
  })
}

shinyApp(ui, server)
