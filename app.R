# Load necessary libraries
library(shiny)  # For building the Shiny app
library(DT)     # For rendering DataTables
library(dplyr)  # For data manipulation

# Define the UI of the app
ui <- fluidPage(
  includeCSS("www/styles.css"),  # Link the external CSS file for custom styling

  # Title panel for the app
  titlePanel("Interactive Sales Dashboard"),

  # Layout of the app with sidebar and main panel
  sidebarLayout(
    sidebarPanel(
      # File input to upload a CSV file
      fileInput("file", "Upload Sales Data (CSV)", accept = c(".csv")),
      
      # Dynamic UI for selecting regions, rendered based on the uploaded data
      uiOutput("region_filter"),
      
      # Date range input for filtering sales data by date
      dateRangeInput("date_filter", "Select Date Range:", 
                     start = Sys.Date() - 30, end = Sys.Date()),  # Default date range: last 30 days
                     
      # Action button to trigger dashboard update
      actionButton("update", "Update Dashboard")
    ),
    
    # Main panel for displaying content
    mainPanel(
      tabsetPanel(
        # Tab panel for showing the data table
        tabPanel("Table", DTOutput("data_table")),
        
        # Tab panel for showing a summary of the data
        tabPanel("Summary", verbatimTextOutput("summary")),
        
        # Tab panel for showing a sales plot (time series)
        tabPanel("Visualization", plotOutput("sales_plot"))
      )
    )
  )
)

# Define the server logic
server <- function(input, output, session) {
  
  # Create a reactive value to store the sales data
  sales_data <- reactiveVal()
  
  # Observer that triggers when a file is uploaded
  observeEvent(input$file, {
    req(input$file)  # Ensure the file input is available
    data <- read.csv(input$file$datapath)  # Read the uploaded CSV file
    sales_data(data)  # Store the data into the reactive value
  })
  
  # Render dynamic UI for selecting regions based on the uploaded data
  output$region_filter <- renderUI({
    req(sales_data())  # Ensure sales data is loaded
    selectInput("region", "Select Region:", choices = unique(sales_data()$Region), 
                multiple = TRUE)  # Create a multi-select input for regions
  })
  
  # Reactive expression to filter data based on user inputs (region and date)
  filtered_data <- reactive({
    req(sales_data())  # Ensure sales data is available
    data <- sales_data()  # Get the stored sales data
    
    # Filter by selected region(s)
    if (!is.null(input$region)) {
      data <- data[data$Region %in% input$region, ]
    }
    
    # Filter by selected date range
    if (!is.null(input$date_filter)) {
      data <- data[data$Date >= as.Date(input$date_filter[1]) &
                   data$Date <= as.Date(input$date_filter[2]), ]
    }
    
    data  # Return the filtered data
  })
  
  # Render the data table (DataTable) for the filtered data
  output$data_table <- renderDT({
    req(filtered_data())  # Ensure filtered data is available
    datatable(filtered_data())  # Display the filtered data as a DataTable
  })
  
  # Render a summary of the filtered sales data (total sales, average, and transaction count)
  output$summary <- renderPrint({
    req(filtered_data())  # Ensure filtered data is available
    data <- filtered_data()  # Get the filtered data
    
    # Create and display a summary data frame
    data.frame(
      Total_Sales = sum(data$Sales, na.rm = TRUE),  # Total sales (ignoring NAs)
      Average_Sales = mean(data$Sales, na.rm = TRUE),  # Average sales (ignoring NAs)
      Total_Transactions = nrow(data)  # Total number of transactions
    )
  })
  
  # Render a plot showing sales trends over time (line chart)
  output$sales_plot <- renderPlot({
    req(filtered_data())  # Ensure filtered data is available
    data <- filtered_data()  # Get the filtered data
    
    # Create and display a line plot of sales over time, with colors by region
    ggplot(data, aes(x = Date, y = Sales, color = Region)) +
      geom_line() +  # Line plot to show trends
      theme_minimal() +  # Minimal theme for the plot
      labs(title = "Sales Trends", x = "Date", y = "Sales")  # Add plot labels
  })
}

# Run the Shiny app
shinyApp(ui, server)
