library(shiny)
library(bslib)
library(plotly)
library(dplyr)
library(readr)
library(lubridate)

# ---------------- DATA ----------------
csv_path <- file.path("..", "data", "raw", "ncr_ride_bookings.csv")
uber <- read_csv(csv_path, show_col_types = FALSE)

# Standardise column names: spaces -> underscores
names(uber) <- gsub(" ", "_", names(uber))

uber$Date <- as.Date(uber$Date)

# Coalesce cancellation reasons into a single column
uber$Issue_Reason <- dplyr::coalesce(
  uber$Reason_for_cancelling_by_Customer,
  uber$Driver_Cancellation_Reason,
  uber$Incomplete_Rides_Reason,
  ""
)

uber <- uber |>
  mutate(
    Driver_Ratings = as.numeric(Driver_Ratings),
    Booking_Value = as.numeric(Booking_Value)
  )

# ---------------- HELPER ----------------
human_format <- function(num) {
  num <- as.numeric(num)
  if (abs(num) >= 1e9) {
    sprintf("%dB", round(num / 1e9))
  } else if (abs(num) >= 1e6) {
    sprintf("%dM", round(num / 1e6))
  } else if (abs(num) >= 1e3) {
    sprintf("%dK", round(num / 1e3))
  } else {
    sprintf("%d", round(num))
  }
}

set2_colors <- RColorBrewer::brewer.pal(8, "Set2")

# ---------------- UI ----------------
kpi_card <- function(icon_class, label, output_id) {
  card(
    div(
      div(
        tags$i(class = paste(icon_class, "kpi-icon")),
        div(label),
        class = "kpi-row"
      ),
      div(textOutput(output_id), class = "kpi-value")
    ),
    class = "kpi-card"
  )
}

ui <- page_fluid(
  tags$link(
    rel = "stylesheet",
    href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"
  ),
  
  tags$style(HTML("
    html, body {
      height: 100vh; width: 100vw;
      margin: 0; padding: 0;
      overflow: hidden !important;
      background: #f8f9fb;
    }
    .kpi-card {
      border-radius: 10px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.08);
      padding: 6px;
      text-align: center;
      background: white;
    }
    .kpi-row {
      display: flex; justify-content: center; align-items: center;
      gap: 4px; font-size: 12px; font-weight: 600;
    }
    .kpi-icon  { font-size: 16px; }
    .kpi-value { font-size: 18px; font-weight: 700; }
    .card {
      border-radius: 10px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.08);
      background: white; padding: 0; margin: 0; overflow: hidden;
    }
    .card-header { font-size: 12px; font-weight: 600; padding: 4px 6px; }
    * { box-sizing: border-box; }
  ")),
  
  div(
    "Uber Data Visualization Dashboard",
    style = "font-size:16px;font-weight:800;text-align:center;padding:2px 0;"
  ),
  layout_sidebar(
    
    sidebar = sidebar(
      width = 230,
      
      sliderInput(
        "slider", "Date range",
        min   = min(uber$Date),
        max   = max(uber$Date),
        value = c(min(uber$Date), max(uber$Date))
      ),
      actionButton("action_button", "Reset Filters")
    ),
    
    # Main content: two columns
    layout_columns(
      col_widths = c(12),
      # ---- RIGHT COLUMN ----
      div(
        card(
          card_header("Revenue Distribution by Vehicle Type"),
          plotlyOutput("pie_chart", height = "185px"),
          style = "height:235px;margin-bottom:4px;padding:0;"
        ),
        card(
          card_header("Total Booking Value Over Time"),
          plotlyOutput("line_chart", height = "115px"),
          style = "height:165px;margin-bottom:4px;padding:0;"
        ),
        card(
          card_header("Avg Driver Rating by Vehicle Type"),
          plotlyOutput("rating_bar", height = "135px"),
          style = "height:185px;margin-bottom:4px;padding:0;"
        )
      )
    )
  )
)

# ---------------- SERVER ----------------
server <- function(input, output, session) {
  
  # ---- Reactive: filtered data (date) ----
  filtered_data <- reactive({
    df <- uber |>
      filter(Date >= input$slider[1], Date <= input$slider[2])
    df
  })
  
  # ---- Reset filters ----
  observeEvent(input$action_button, {
    updateSliderInput(session,    "slider",       value = c(min(uber$Date), max(uber$Date)))
  })
  
  # ---------------- KPI VALUES ----------------
  output$total_bookings <- renderText({
    human_format(nrow(filtered_data()))
  })
  
  output$total_revenue <- renderText({
    human_format(sum(filtered_data()$Booking_Value, na.rm = TRUE))
  })
  
  output$canceled_bookings <- renderText({
    df <- filtered_data()
    count <- sum(df$Cancelled_Rides_by_Driver   == 1, na.rm = TRUE) +
      sum(df$Cancelled_Rides_by_Customer == 1, na.rm = TRUE)
    human_format(count)
  })
  
  # ---------------- CHARTS ----------------
  output$rating_bar <- renderPlotly({
    avg <- filtered_data() |>
      group_by(Vehicle_Type) |>
      summarise(Driver_Ratings = mean(Driver_Ratings, na.rm = TRUE), .groups = "drop")
    
    min_val <- min(avg$Driver_Ratings)
    max_val <- max(avg$Driver_Ratings)
    padding <- (max_val - min_val) * 0.05
    
    plot_ly(
      avg,
      x     = ~Vehicle_Type,
      y     = ~Driver_Ratings,
      type  = "bar",
      color = ~Vehicle_Type,
      colors = set2_colors,
      text  = ~sprintf("%.4f", Driver_Ratings),
      textposition = "outside"
    ) |>
      layout(
        showlegend   = FALSE,
        plot_bgcolor = "white",
        paper_bgcolor = "white",
        margin = list(l = 5, r = 5, t = 5, b = 5),
        xaxis  = list(title = ""),
        yaxis  = list(title = "Avg Rating",
                      range = c(min_val - padding, max_val + padding))
      )
  })
  
  output$line_chart <- renderPlotly({
    df_agg <- filtered_data() |>
      group_by(Date) |>
      summarise(Booking_Value = sum(Booking_Value, na.rm = TRUE), .groups = "drop")
    
    plot_ly(df_agg, x = ~Date, y = ~Booking_Value, type = "scatter", mode = "lines") |>
      layout(
        plot_bgcolor  = "white",
        paper_bgcolor = "white",
        margin = list(l = 5, r = 5, t = 5, b = 5)
      )
  })
  
  output$pie_chart <- renderPlotly({
    revenue <- filtered_data() |>
      group_by(Vehicle_Type) |>
      summarise(Booking_Value = sum(Booking_Value, na.rm = TRUE), .groups = "drop")
    
    plot_ly(
      revenue,
      labels = ~Vehicle_Type,
      values = ~Booking_Value,
      type   = "pie",
      textinfo = "percent+label",
      textposition = "inside",
      marker = list(colors = set2_colors)
    ) |>
      layout(
        showlegend    = FALSE,
        margin        = list(l = 0, r = 0, t = 0, b = 0),
        paper_bgcolor = "white"
      )
  })
}

# ---------------- APP ----------------
shinyApp(ui, server)