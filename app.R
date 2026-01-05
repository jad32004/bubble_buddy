library(shiny)
library(DBI)
library(RSQLite)
library(DT)
library(shinyjs)
library(plotly)

# Initialize SQLite database
init_db <- function() {
  # Connect to the SQLite database
  conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
  
  # Create the laundry_orders table if it doesn't exist
  dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS laundry_orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_name TEXT NOT NULL,
      phone_number TEXT NOT NULL,
      loads INTEGER NOT NULL,
      service_type TEXT NOT NULL,
      pickup_date TEXT NOT NULL,
      status TEXT DEFAULT 'Pending',
      is_archived INTEGER DEFAULT 0,
      created_at TEXT,
      updated_at TEXT
    )
  ")
  
  # Close the database connection
  dbDisconnect(conn)
}

init_db()

# UI with Bubbles Laundry Design
ui <- fluidPage(
  useShinyjs(),  
  tags$head(
    tags$link(href = "https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap", rel = "stylesheet")
  ),
    tags$style(HTML("
      * {
        font-family: 'Nunito', sans-serif;
      }
      
      body {
        background: linear-gradient(135deg, #ffeef8 0%, #e8f4ff 50%, #fff0f5 100%);
        min-height: 100vh;
        margin: 0;
        padding: 0;
      }
      
      @keyframes float {
        0%, 100% { transform: translateY(0px); }
        50% { transform: translateY(-10px); }
      }
      
      @keyframes bubble {
        0% { transform: scale(1); opacity: 0.7; }
        50% { transform: scale(1.1); opacity: 1; }
        100% { transform: scale(1); opacity: 0.7; }
      }
      
      .bubble-bg {
        position: fixed;
        border-radius: 50%;
        background: radial-gradient(circle at 30% 30%, rgba(255, 255, 255, 0.9) 0%, rgba(200, 230, 255, 0.5) 50%, rgba(244, 114, 182, 0.3) 100%);
        box-shadow: 
          inset -10px -10px 20px rgba(255, 255, 255, 0.8),
          inset 10px 10px 20px rgba(200, 230, 255, 0.4),
          0 10px 30px rgba(244, 114, 182, 0.2);
        z-index: 0;  /* IMPORTANT: Keep at 0 */
        pointer-events: none;
      }
      
      .bubble-1 { 
        width: 120px; 
        height: 120px; 
        top: 10%; 
        left: 5%; 
        animation: bubble 4s ease-in-out infinite; 
      }
      
      .bubble-2 { 
        width: 80px; 
        height: 80px; 
        top: 20%; 
        right: 10%; 
        animation: bubble 5s ease-in-out 0.5s infinite; 
      }
      
      .bubble-3 { 
        width: 150px; 
        height: 150px; 
        bottom: 15%; 
        left: 10%; 
        animation: bubble 6s ease-in-out 1s infinite; 
      }
            
      .bubble-4 { 
        width: 90px; 
        height: 90px; 
        bottom: 25%; 
        right: 15%; 
        animation: bubble 5s ease-in-out 1.5s infinite; 
      }
      
      .bubble-5 {
        width: 100px;
        height: 100px;
        top: 50%;
        left: 50%;
        animation: bubble 5.5s ease-in-out 2s infinite;
      }
      
      .bubble-6 {
        width: 70px;
        height: 70px;
        top: 70%;
        right: 30%;
        animation: bubble 4.5s ease-in-out 2.5s infinite;
      }
      @keyframes bubble {
        0%, 100% { 
          transform: scale(1) translateY(0px); 
          opacity: 0.6; 
        }
        50% { 
          transform: scale(1.15) translateY(-20px); 
          opacity: 0.9; 
        }
      }
      
      .navbar {
        background: rgba(255, 255, 255, 0.8);
        backdrop-filter: blur(10px);
        box-shadow: 0 2px 10px rgba(255, 182, 217, 0.2);
        padding: 16px 32px;
        position: sticky;
        top: 0;
        z-index: 100;  /* Higher than bubbles */
      }
      
      .nav-content {
        max-width: 1200px;
        margin: 0 auto;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }
      
      .nav-brand {
        display: flex;
        align-items: center;
        gap: 12px;
      }
      
      .nav-title {
        color: #f472b6;
        font-weight: 800;
        font-size: 24px;
        margin: 0;
      }
      
      .nav-buttons {
        display: flex;
        gap: 12px;
      }
      
      .nav-btn {
        padding: 10px 20px;
        border: none;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.3s ease;
        font-size: 14px;
      }
      
      .nav-btn.active {
        background: #fce7f3;
        color: #f472b6;
      }
      
      .nav-btn.inactive {
        background: transparent;
        color: #a855f7;
      }
      
      .nav-btn.inactive:hover {
        background: #f3e8ff;
      }
      
      .nav-btn.logout {
        background: transparent;
        color: #9ca3af;
      }
      
      .nav-btn.logout:hover {
        background: #f3f4f6;
      }
      
      .content-wrapper {
        position: relative;
        z-index: 1;  /* Higher than bubbles */
        max-width: 1200px;
        margin: 0 auto;
        padding: 32px;
      }
      
      .glass-card {
        background: rgba(255, 255, 255, 0.8);
        backdrop-filter: blur(10px);
        border-radius: 24px;
        box-shadow: 0 8px 32px rgba(255, 182, 217, 0.2);
        padding: 24px;
        margin-bottom: 20px;
        position: relative;
        z-index: 1;  /* Ensure cards are above bubbles */
      }
      
      /* Stat Cards - Target by parent column position */
      .row .col-sm-3:nth-child(1) .stat-card {
        background: linear-gradient(135deg, #fce7f3 0%, #ffffff 100%) !important;
        box-shadow: 0 4px 12px rgba(236, 72, 153, 0.15) !important;
      }
      
      .row .col-sm-3:nth-child(2) .stat-card {
        background: linear-gradient(135deg, #fef3c7 0%, #ffffff 100%) !important;
        box-shadow: 0 4px 12px rgba(217, 119, 6, 0.15) !important;
      }
      
      .row .col-sm-3:nth-child(3) .stat-card {
        background: linear-gradient(135deg, #dbeafe 0%, #ffffff 100%) !important;
        box-shadow: 0 4px 12px rgba(37, 99, 235, 0.15) !important;
      }
      
      .row .col-sm-3:nth-child(4) .stat-card {
        background: linear-gradient(135deg, #d1fae5 0%, #ffffff 100%) !important;
        box-shadow: 0 4px 12px rgba(5, 150, 105, 0.15) !important;
      }
      
      /* Base stat card styles */
      .stat-card {
        background: white !important;
        border-radius: 12px !important;
        border: 1px solid rgba(0, 0, 0, 0.05) !important;
        transition: all 0.3s ease !important;
      }
      
      .stat-card:hover {
        transform: translateY(-4px) !important;
        box-shadow: 0 8px 20px rgba(244, 114, 182, 0.25) !important;
      }
            
      .visual-analytics,
      .analytics-card {
        background: white;
        border-radius: 12px;
        padding: 20px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06);
        margin-bottom: 24px;
      }
  
      .orders-table-container {
        background: white;
        border-radius: 12px;
        padding: 20px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06);
        margin-bottom: 24px;
      }
      
      .recent-activity,
      .activity-card {
        background: white;
        border-radius: 12px;
        padding: 20px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06);
        margin-bottom: 24px;
      }
      .btn-bubble {
        background: linear-gradient(135deg, #f472b6 0%, #a78bfa 100%);
        border: none;
        border-radius: 16px;
        color: white;
        font-weight: 700;
        padding: 12px 24px;
        box-shadow: 0 4px 15px rgba(244, 114, 182, 0.3);
        transition: all 0.3s ease;
      }
      
      .btn-bubble:hover {
        transform: scale(1.05);
        box-shadow: 0 6px 25px rgba(244, 114, 182, 0.4);
      }
      
      .status-pending { 
        background: #fef3c7; 
        color: #92400e;
        padding: 6px 12px;
        border-radius: 12px;
        font-weight: 700;
        font-size: 12px;
      }
      
      .status-washing { 
        background: #dbeafe; 
        color: #1e40af;
        padding: 6px 12px;
        border-radius: 12px;
        font-weight: 700;
        font-size: 12px;
      }
      
      .status-folding { 
        background: #e9d5ff; 
        color: #6b21a8;
        padding: 6px 12px;
        border-radius: 12px;
        font-weight: 700;
        font-size: 12px;
      }
      
      .status-ready { 
        background: #d1fae5; 
        color: #065f46;
        padding: 6px 12px;
        border-radius: 12px;
        font-weight: 700;
        font-size: 12px;
      }
      
      .status-picked { 
        background: #f3f4f6; 
        color: #4b5563;
        padding: 6px 12px;
        border-radius: 12px;
        font-weight: 700;
        font-size: 12px;
      }
      
      .form-control {
        border: 2px solid #fcd5e5 !important;
        border-radius: 16px !important;
        padding: 12px 16px !important;
        font-size: 14px !important;
      }
      
      .form-control:focus {
        border-color: #f472b6 !important;
        box-shadow: 0 0 0 3px rgba(244, 114, 182, 0.1) !important;
      }
      
      .dataTables_wrapper {
        background: transparent !important;
      }
      
      table.dataTable {
        border-collapse: separate !important;
        border-spacing: 0 8px !important;
        background: transparent !important;
      }
      
      table.dataTable thead th {
        background: linear-gradient(135deg, #fce7f3 0%, #e9d5ff 100%) !important;
        color: #a855f7 !important;
        font-weight: 800 !important;
        border: none !important;
        padding: 16px !important;
        font-size: 13px !important;
      }
      
      table.dataTable tbody tr {
        background: rgba(255, 255, 255, 0.9) !important;
        border-radius: 12px !important;
        transition: all 0.2s ease !important;
      }
      
      table.dataTable tbody tr:hover {
        background: rgba(252, 231, 243, 0.5) !important;
        transform: scale(1.01);
      }
      
      table.dataTable tbody td {
        border: none !important;
        padding: 16px !important;
        vertical-align: middle !important;
      }
      
      .title-text {
        color: #a855f7;
        font-weight: 800;
        font-size: 28px;
        margin-bottom: 8px;
      }
      
      .subtitle-text {
        color: #c084fc;
        font-weight: 600;
        font-size: 14px;
      }
      
      .info-banner {
        background: linear-gradient(135deg, #e7f3ff 0%, #fce7f3 100%);
        padding: 16px;
        border-radius: 16px;
        margin-bottom: 20px;
        border: 2px solid #f9a8d4;
      }
      
      .quick-actions {
        background: white;
        border-radius: 12px;
        padding: 20px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06);
        margin-bottom: 24px;
      }
      
      .quick-action-btn {
        padding: 20px;
        background: linear-gradient(135deg, #fce7f3 0%, #fcd5e5 100%);
        border: none;
        border-radius: 20px;
        transition: all 0.3s ease;
        cursor: pointer;
        text-align: center;
      }
      
      .quick-action-btn:hover {
        transform: scale(1.05);
        box-shadow: 0 8px 20px rgba(244, 114, 182, 0.3);
      }
      
      .activity-item {
        display: flex;
        align-items: center;
        gap: 16px;
        padding: 16px;
        background: #fce7f3;
        border-radius: 16px;
        margin-bottom: 12px;
      }
      
      /* Modal Styles */
      .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.5);
        backdrop-filter: blur(4px);
        z-index: 1000;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 20px;
      }
      
      .modal-content {
        background: white;
        border-radius: 24px;
        max-width: 600px;
        width: 100%;
        max-height: 90vh;
        overflow-y: auto;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        animation: modalSlideIn 0.3s ease;
        position: relative;
        z-index: 1001;
        margin: auto;  /* ADD THIS LINE */
      }
      
      @keyframes modalSlideIn {
        from {
          opacity: 0;
          transform: translateY(-20px);
        }
        to {
          opacity: 1;
          transform: translateY(0);
        }
      }
      
      .modal-header {
        padding: 24px 32px;
        border-bottom: 2px solid #fce7f3;
      }
      
      .modal-body {
        padding: 32px;
      }
      
      .modal-footer {
        padding: 24px 32px;
        border-top: 2px solid #fce7f3;
        display: flex;
        gap: 12px;
        justify-content: flex-end;
      }
      
      .form-group {
        margin-bottom: 20px;
      }
      
      .form-label {
        display: block;
        font-weight: 700;
        color: #a855f7;
        margin-bottom: 8px;
        font-size: 14px;
      }
      
      .btn-cancel {
        background: #f3f4f6;
        color: #6b7280;
        border: none;
        border-radius: 12px;
        padding: 12px 24px;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.3s ease;
      }
      
      .btn-cancel:hover {
        background: #e5e7eb;
      }
      
      .btn-submit {
        background: linear-gradient(135deg, #f472b6 0%, #a78bfa 100%);
        color: white;
        border: none;
        border-radius: 12px;
        padding: 12px 24px;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.3s ease;
      }
      
      .btn-submit:hover {
        transform: scale(1.05);
        box-shadow: 0 6px 20px rgba(244, 114, 182, 0.4);
      }
      .row {
      margin-bottom: 20px;
      }
      background: transparent;
      }
    
      /* Stat Cards - Individual Pastel Gradients */
      .stat-card:nth-child(1) {
        background: linear-gradient(135deg, rgba(252, 231, 243, 0.9) 0%, rgba(255, 255, 255, 0.95) 100%) !important;
      }
      
      .stat-card:nth-child(2) {
        background: linear-gradient(135deg, rgba(254, 243, 199, 0.9) 0%, rgba(255, 255, 255, 0.95) 100%) !important;
      }
      
      .stat-card:nth-child(3) {
        background: linear-gradient(135deg, rgba(219, 234, 254, 0.9) 0%, rgba(255, 255, 255, 0.95) 100%) !important;
      }
      
      .stat-card:nth-child(4) {
        background: linear-gradient(135deg, rgba(209, 250, 229, 0.9) 0%, rgba(255, 255, 255, 0.95) 100%) !important;
      }
      
      /* Quick Actions - Enhanced Gradient */
      .quick-actions {
        background: linear-gradient(135deg, rgba(255, 255, 255, 0.95) 0%, rgba(252, 231, 243, 0.6) 100%) !important;
      }
      
      /* Visual Analytics Cards - White with Shadow */
      .visual-analytics,
      .analytics-card {
        background: rgba(255, 255, 255, 0.95) !important;
      }
      
      /* Recent Activity - Purple Tint */
      .recent-activity,
      .activity-card {
        background: linear-gradient(135deg, rgba(255, 255, 255, 0.95) 0%, rgba(233, 213, 255, 0.5) 100%) !important;
      }
      
      /* Orders Table Container - White */
      .orders-table-container {
        background: rgba(255, 255, 255, 0.95) !important;
      }
      
      /* Glass Card Enhancement */
      .glass-card {
        background: rgba(255, 255, 255, 0.85) !important;
        backdrop-filter: blur(12px) !important;
      }
      
      /* Status Badge - Iron (missing from original) */
      .status-iron { 
        background: #fed7aa !important;
        color: #9a3412 !important;
        padding: 6px 12px;
        border-radius: 12px;
        font-weight: 700;
        font-size: 12px;
      }
    /* Login Page Styles */
    #login-page {
      min-height: 100vh;
      width: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 24px;
      position: relative;
      overflow: hidden;
    }
    
    .float-animation {
      animation: float 3s ease-in-out infinite;
    }
    
    @keyframes float {
      0%   { transform: translateY(0px); }
      50%  { transform: translateY(-5px); } 
      100% { transform: translateY(0px); }
    }
    
    .bubble-animation {
      animation: bubble 4s ease-in-out infinite;
    }
  ")),
  

  tags$nav(id = "main-navbar", class = "navbar",
           div(class = "nav-content",
               div(class = "nav-brand",
                   tags$img(
                     src = "glinda_heart.png",
                     height = "80px",
                     style = "border-radius: 12px; margin-right: 8px;"
                   ),
                   h1(class = "nav-title", "Bubble Buddy\n")
               ),
               div(class = "nav-buttons",
                   actionButton("nav_dashboard", "🏠 Dashboard", class = "nav-btn"),
                   actionButton("nav_orders", "📋 Orders", class = "nav-btn"),
                   actionButton("nav_reports", "📊 Reports", class = "nav-btn"),
                   actionButton("nav_archived", "📦 Archived", class = "nav-btn"),
                   actionButton("nav_logout", "👋 Logout", class = "nav-btn logout")
               )
           )
  ),
  
  # Main content
  div(class = "content-wrapper",
      
      # Dashboard Page
      uiOutput("dashboard_page"),
      
      # Orders Page
      uiOutput("orders_page"),
      
      # Reports Page
      uiOutput("reports_page"),
      
      #Login
      uiOutput("login_ui"),
      
      # Main App (hidden until logged in)
      uiOutput("main_app_ui")
  )
  )

# Server
server <- function(input, output, session) {
  useShinyjs()
  
  # Checks login state
  logged_in <- reactiveVal(FALSE)
  
  # Login UI
  output$login_ui <- renderUI({
    req(!logged_in())
    
    tags$div(
      id = "login-page",
      style = "position: fixed; top: 0; left: 0; min-height: 100vh; width: 100%; display: flex; align-items: center; justify-content: center; padding: 24px; background: linear-gradient(135deg, #ffeef8 0%, #e8f4ff 50%, #fff0f5 100%); z-index: 9999;",
      
      # Bubbles
      tags$div(class = "bubble-bg bubble-animation", 
               style = "width: 80px; height: 80px; top: 10%; left: 5%; animation-delay: 0s; position: fixed;"),
      tags$div(class = "bubble-bg bubble-animation", 
               style = "width: 50px; height: 50px; top: 20%; right: 10%; animation-delay: 0.5s; position: fixed;"),
      tags$div(class = "bubble-bg bubble-animation", 
               style = "width: 100px; height: 100px; bottom: 15%; left: 10%; animation-delay: 1s; position: fixed;"),
      tags$div(class = "bubble-bg bubble-animation", 
               style = "width: 60px; height: 60px; bottom: 25%; right: 15%; animation-delay: 1.5s; position: fixed;"),
      
      # Login Card
      tags$div(
        style = "background: rgba(255, 255, 255, 0.8); backdrop-filter: blur(10px); border-radius: 1.5rem; box-shadow: 0 20px 25px rgba(0,0,0,0.1); padding: 2rem; width: 100%; max-width: 28rem; position: relative; z-index: 10;",
        
        # Header
        tags$div(
          style = "text-align: center; margin-bottom: 2rem; position: relative;",
          tags$div(
            class = "float-animation",
            style = "display: inline-block; margin-bottom: 1rem;",
            tags$div(
              class = "float-animation",
              style = "display: inline-block; margin-bottom: 1rem;",
              tags$img(src = "glinda_bubble.png", width = "80px", height = "80px")
            )
          ),
          tags$h1("🫧 Bubble Buddy 🫧", 
                  style = "font-size: 1.875rem; font-weight: 800; color: #f472b6; margin-bottom: 0.5rem;"),
          tags$p("Your buddy, just around the corner", 
                 style = "color: #c084fc; font-weight: 600;")
        ),
        # Login Form
        tags$div(
          style = "display: flex; flex-direction: column; gap: 1.25rem;",
          
          # Username
          tags$div(
            tags$label("Username", 
                       style = "display: block; font-size: 0.875rem; font-weight: 700; color: #a855f7; margin-bottom: 0.5rem;"),
            textInput("login_username", NULL, 
                      value = "",
                      placeholder = "Enter your username",
                      width = "100%")
          ),
          
          # Password
          tags$div(
            tags$label("Password", 
                       style = "display: block; font-size: 0.875rem; font-weight: 700; color: #a855f7; margin-bottom: 0.5rem;"),
            passwordInput("login_password", NULL,
                          value = "",
                          placeholder = "Enter your password",
                          width = "100%")
          ),
          
          # Login Button
          actionButton("login_btn", "Let's Go! 🌸",
                       style = "width: 100%; padding: 0.75rem 1.5rem; background: linear-gradient(to right, #f472b6, #a78bfa); color: white; font-weight: 700; border-radius: 1rem; border: none; cursor: pointer;")
        ),
        
      )
    )
  })
  
  # Handle login button click
  observeEvent(input$login_btn, {
    username <- input$login_username
    password <- input$login_password
    
    # validation
    if(username == "admin" && password == "admin123") {
      logged_in(TRUE)
      showNotification("✨ Welcome to Bubbles Laundry!", type = "message", duration = 3)
    } else if(nzchar(username) && nzchar(password)) {
      showNotification("❌ Invalid username or password", type = "error", duration = 3)
    } else {
      showNotification("⚠️ Please enter both username and password", type = "warning")
    }
  }, ignoreInit = TRUE)
  
  # Show/hide navbar based on login state
  observe({
    if(logged_in()) {
      runjs("document.getElementById('main-navbar').style.display = 'block';")
    } else {
      runjs("document.getElementById('main-navbar').style.display = 'none';")
    }
  })
  
  # Main App UI (shown after login)
  output$main_app_ui <- renderUI({
    req(logged_in())
    
    tagList(
      # Decorative bubbles
      tags$div(class = "bubble-bg bubble-1"),
      tags$div(class = "bubble-bg bubble-2"),
      tags$div(class = "bubble-bg bubble-3"),
      tags$div(class = "bubble-bg bubble-4"),
      tags$div(class = "bubble-bg bubble-5"),
      tags$div(class = "bubble-bg bubble-6"),
      
      
      # ONE uiOutput
      tags$div(class = "content-wrapper",
               uiOutput("current_page_content")  
      )
    )
  })
  
  observeEvent(input$logout, {
    logged_in(FALSE)
    showNotification("👋 Logged out successfully", type = "message")
  })
  
  
  # Reactive values
  current_page <- reactiveVal("dashboard")
  refresh_trigger <- reactiveVal(0)
  
  get_orders <- reactive({
    refresh_trigger()
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    orders <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE is_archived = 0 ORDER BY created_at DESC")
    dbDisconnect(conn)
    
    if(isTRUE(input$show_overstaying_only)) {
      orders <- orders[sapply(1:nrow(orders), function(i) {
        is_overstaying(orders$status[i], orders$updated_at[i])
      }), ]
    }
    orders
  })
  
  # Dashboard content as a reactive
  get_dashboard_content <- reactive({
    orders <- get_orders()
    
    tagList(
      # Enhanced greeting with image
      div(style = "display: flex; align-items: center; gap: 20px; margin-bottom: 32px; background: linear-gradient(135deg, rgba(252, 231, 243, 0.4) 0%, rgba(233, 213, 255, 0.4) 100%); padding: 24px; border-radius: 20px; border: 2px solid rgba(244, 114, 182, 0.2);",
          tags$img(src = "labubu_greet.png", height = "100px", style = "border-radius: 20px; box-shadow: 0 8px 20px rgba(244, 114, 182, 0.3);"),
          div(
            h2("Welcome back, Bubble Bud! 🫧️", class = "title-text", style = "margin: 0; font-size: 32px;"),
            p("Here's what's happening with your laundry today", class = "subtitle-text", style = "margin: 8px 0 0 0; font-size: 16px;")
          )
      ),     
      
      # Statistics Cards
      fluidRow(
        column(3,
               div(class = "stat-card",
                   style = "padding: 16px; min-height: auto;",
                   div(style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;",
                       tags$span("🧺", style = "font-size: 28px;"),
                       tags$span("Today", style = "background: #fce7f3; color: #ec4899; padding: 3px 10px; border-radius: 10px; font-weight: 700; font-size: 10px;")
                   ),
                   h2(nrow(orders), style = "color: #374151; font-weight: 800; margin: 0; font-size: 32px; line-height: 1;"),
                   p("Total Orders", style = "color: #c084fc; font-weight: 600; margin: 6px 0 0 0; font-size: 13px;")
               )
        ),
        column(3,
               div(class = "stat-card",
                   style = "padding: 16px; min-height: auto;",
                   div(style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;",
                       tags$span("🕐", style = "font-size: 28px;"),
                       tags$span("Pending", style = "background: #fef3c7; color: #d97706; padding: 3px 10px; border-radius: 10px; font-weight: 700; font-size: 10px;")
                   ),
                   h2(sum(orders$status == "Pending"), style = "color: #374151; font-weight: 800; margin: 0; font-size: 32px; line-height: 1;"),
                   p("Pending", style = "color: #c084fc; font-weight: 600; margin: 6px 0 0 0; font-size: 13px;")
               )
        ),
        column(3,
               div(class = "stat-card",
                   style = "padding: 16px; min-height: auto;",
                   div(style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;",
                       tags$span("🫧", style = "font-size: 28px;"),
                       tags$span("Washing", style = "background: #dbeafe; color: #2563eb; padding: 3px 10px; border-radius: 10px; font-weight: 700; font-size: 10px;")
                   ),
                   h2(sum(orders$status == "Washing"), style = "color: #374151; font-weight: 800; margin: 0; font-size: 32px; line-height: 1;"),
                   p("Washing", style = "color: #c084fc; font-weight: 600; margin: 6px 0 0 0; font-size: 13px;")
               )
        ),
        column(3,
               div(class = "stat-card",
                   style = "padding: 16px; min-height: auto;",
                   div(style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;",
                       tags$span("✨", style = "font-size: 28px;"),
                       tags$span("Done", style = "background: #d1fae5; color: #059669; padding: 3px 10px; border-radius: 10px; font-weight: 700; font-size: 10px;")
                   ),
                   h2(sum(orders$status %in% c("Ready for Pickup", "Picked Up")), style = "color: #374151; font-weight: 800; margin: 0; font-size: 32px; line-height: 1;"),
                   p("Ready/Picked Up", style = "color: #c084fc; font-weight: 600; margin: 6px 0 0 0; font-size: 13px;")
               )
        )
      ),      
      
      # Quick Actions
      div(class = "glass-card", style = "background: linear-gradient(135deg, rgba(255, 255, 255, 0.9) 0%, rgba(252, 231, 243, 0.5) 100%);",
          h3("Quick Actions 🚀", style = "color: #a855f7; font-weight: 800; margin-bottom: 24px; font-size: 20px;"),
          fluidRow(
            column(4,
                   actionButton("quick_new_order", "", class = "quick-action-btn", 
                                style = "width: 100%; height: 140px; background: linear-gradient(135deg, #fce7f3 0%, #f9a8d4 100%); border: 2px solid rgba(244, 114, 182, 0.3); box-shadow: 0 4px 15px rgba(244, 114, 182, 0.2);",
                                tags$div(style = "display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%;",
                                         tags$span("➕", style = "font-size: 48px; display: block; margin-bottom: 12px; filter: drop-shadow(0 2px 4px rgba(244, 114, 182, 0.3));"),
                                         tags$span("New Order", style = "color: #f472b6; font-weight: 800; font-size: 16px;")
                                )
                   )
            ),
            column(4,
                   actionButton("quick_view_orders", "", class = "quick-action-btn", 
                                style = "width: 100%; height: 140px; background: linear-gradient(135deg, #e9d5ff 0%, #c4b5fd 100%); border: 2px solid rgba(167, 139, 250, 0.3); box-shadow: 0 4px 15px rgba(167, 139, 250, 0.2);",
                                tags$div(style = "display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%;",
                                         tags$span("📋", style = "font-size: 48px; display: block; margin-bottom: 12px; filter: drop-shadow(0 2px 4px rgba(167, 139, 250, 0.3));"),
                                         tags$span("View Orders", style = "color: #a78bfa; font-weight: 800; font-size: 16px;")
                                )
                   )
            ),
            column(4,
                   actionButton("quick_view_reports", "", class = "quick-action-btn", 
                                style = "width: 100%; height: 140px; background: linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%); border: 2px solid rgba(16, 185, 129, 0.3); box-shadow: 0 4px 15px rgba(16, 185, 129, 0.2);",
                                tags$div(style = "display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100%;",
                                         tags$span("📊", style = "font-size: 48px; display: block; margin-bottom: 12px; filter: drop-shadow(0 2px 4px rgba(16, 185, 129, 0.3));"),
                                         tags$span("Reports", style = "color: #10b981; font-weight: 800; font-size: 16px;")
                                )
                   )
            )
          )
      ),
      
      # Visual Analytics
      fluidRow(
        column(6,
               div(class = "glass-card",
                   h3("Order Status Distribution 📊", style = "color: #a855f7; font-weight: 800; margin-bottom: 16px;"),
                   plotlyOutput("status_donut_chart", height = "300px")
               )
        ),
        column(6,
               div(class = "glass-card",
                   h3("Service Type Breakdown 🧺", style = "color: #a855f7; font-weight: 800; margin-bottom: 16px;"),
                   plotlyOutput("service_bar_chart", height = "300px")
               )
        )
      ),
      
      # Recent Activity
      div(class = "glass-card", style = "background: linear-gradient(135deg, rgba(255, 255, 255, 0.9) 0%, rgba(233, 213, 255, 0.5) 100%);",
          h3("Recent Activity 💫", style = "color: #a855f7; font-weight: 800; margin-bottom: 24px; font-size: 20px;"),
          if(nrow(orders) > 0) {
            recent <- head(orders, 5)
            lapply(1:nrow(recent), function(i) {
              status <- as.character(recent$status[i])
              
              # Emoji
              emoji <- switch(status,
                              "Pending" = "🧺",
                              "Washing" = "🫧",
                              "Folding" = "🌀",
                              "Iron" = "🔥",
                              "Ready for Pickup" = "✨",
                              "Picked Up" = "✅",
                              "🧺")
              
              # Get background color with fallback
              bg_color <- switch(status,
                                 "Pending" = "linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)",
                                 "Washing" = "linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%)",
                                 "Folding" = "linear-gradient(135deg, #e9d5ff 0%, #d8b4fe 100%)",
                                 "Iron" = "linear-gradient(135deg, #fed7aa 0%, #fdba74 100%)",
                                 "Ready for Pickup" = "linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%)",
                                 "Picked Up" = "linear-gradient(135deg, #e0e7ff 0%, #c7d2fe 100%)",
                                 "linear-gradient(135deg, #fce7f3 0%, #fbcfe8 100%)")
              
              tags$div(class = "activity-item", 
                       style = paste0("background: ", bg_color, "; border: 2px solid rgba(244, 114, 182, 0.2); transition: all 0.3s ease; cursor: pointer;"),
                       onmouseover = "this.style.transform='translateX(10px) scale(1.02)'; this.style.boxShadow='0 8px 24px rgba(244, 114, 182, 0.3)';",
                       onmouseout = "this.style.transform='translateX(0) scale(1)'; this.style.boxShadow='none';",
                       tags$span(emoji, style = "font-size: 32px; filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.1));"),
                       tags$div(style = "flex: 1;",
                                tags$p(paste("Order #", recent$id[i], "•", recent$customer_name[i]), 
                                       style = "font-weight: 800; color: #374151; margin: 0; font-size: 15px;"),
                                tags$p(paste(recent$service_type[i], "• Just now"), 
                                       style = "font-size: 13px; color: #a855f7; margin: 4px 0 0 0; font-weight: 600;")
                       ),
                       tags$span(status, 
                                 class = paste0("status-", tolower(gsub(" ", "-", gsub(" for Pickup", "", status)))))
              )
            })
          } else {
            tags$p("No activity yet. Add your first order! 🌸", 
                   style = "color: #c084fc; text-align: center; font-size: 16px; padding: 40px; font-weight: 600;")
          }
      )
    )
  })
      
  # Orders content as a reactive
  get_orders_content <- reactive({
    tagList(
      # Orders Page Header - Enhanced Style
      div(style = "display: flex; align-items: center; gap: 20px; margin-bottom: 32px; background: linear-gradient(135deg, rgba(252, 231, 243, 0.4) 0%, rgba(233, 213, 255, 0.4) 100%); padding: 24px; border-radius: 20px; border: 2px solid rgba(244, 114, 182, 0.2);",
          tags$span("📋", style = "font-size: 60px;"),
          div(style = "flex: 1;",
              h2("Orders Management", class = "title-text", style = "margin: 0; font-size: 32px;"),
              p("Manage and track all your laundry orders", class = "subtitle-text", style = "margin: 8px 0 0 0; font-size: 16px;")
          ),
          # Action buttons on the right side of header
          div(style = "display: flex; flex-direction: column; align-items: flex-end; gap: 8px;",
              div(
                checkboxInput("show_overstaying_only", "⏰ Show Overstaying Only", value = FALSE)
              ),
              div(style = "display: flex; gap: 8px;",
                  actionButton("refresh_orders", "🔄 Refresh", 
                               style = "background: #e9d5ff; color: #7c3aed; border: none; border-radius: 12px; padding: 10px 20px; font-weight: 700;"),
                  actionButton("show_add_modal", "➕ New Order", class = "btn-bubble")
              )
          )
      ),
      
      # Orders Table
      div(class = "glass-card", style = "background: rgba(255, 255, 255, 0.95);",
          DTOutput("orders_table")
      )
    )
  })      
  
  # Reports content as a reactive
  get_reports_content <- reactive({
    orders <- get_orders()
    
    tagList(
      # Page Header
      div(style = "display: flex; align-items: center; gap: 20px; margin-bottom: 32px; background: linear-gradient(135deg, rgba(252, 231, 243, 0.4) 0%, rgba(233, 213, 255, 0.4) 100%); padding: 24px; border-radius: 20px; border: 2px solid rgba(244, 114, 182, 0.2);",
          tags$span("📊", style = "font-size: 60px;"),
          div(
            h2("Business Reports & Analytics", class = "title-text", style = "margin: 0; font-size: 32px;"),
            p("Insights and metrics for your laundry business", class = "subtitle-text", style = "margin: 8px 0 0 0; font-size: 16px;")
          )
      ),
      
      # Top Metric Cards
      fluidRow(
        column(6,
               div(class = "glass-card", 
                   style = "background: linear-gradient(135deg, rgba(219, 234, 254, 0.8) 0%, rgba(191, 219, 254, 0.6) 100%); border: 2px solid rgba(59, 130, 246, 0.3); min-height: 140px; display: flex; flex-direction: column; justify-content: center;",
                   div(style = "text-align: center;",
                       tags$span("📦", style = "font-size: 48px; display: block; margin-bottom: 12px; filter: drop-shadow(0 4px 8px rgba(59, 130, 246, 0.3));"),
                       h4(style = "color: #2563eb; margin: 0; font-size: 14px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;", "Picked Up Total"),
                       h2(style = "color: #1e40af; margin: 12px 0 0 0; font-weight: 800; font-size: 48px; line-height: 1;", 
                          sum(orders$status == "Picked Up"))
                   )
               )
        ),
        column(6,
               div(class = "glass-card", 
                   style = "background: linear-gradient(135deg, rgba(233, 213, 255, 0.8) 0%, rgba(216, 180, 254, 0.6) 100%); border: 2px solid rgba(168, 85, 247, 0.3); min-height: 140px; display: flex; flex-direction: column; justify-content: center;",
                   div(style = "text-align: center;",
                       tags$span("🧺", style = "font-size: 48px; display: block; margin-bottom: 12px; filter: drop-shadow(0 4px 8px rgba(168, 85, 247, 0.3));"),
                       h4(style = "color: #7c3aed; margin: 0; font-size: 14px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;", "Total Active Orders"),
                       h2(style = "color: #6b21a8; margin: 12px 0 0 0; font-weight: 800; font-size: 48px; line-height: 1;", 
                          nrow(orders))
                   )
               )
        )
      ),
      
      # Charts Row 1: Status Distribution & Service Breakdown
      fluidRow(
        column(6,
               div(class = "glass-card", style = "background: rgba(255, 255, 255, 0.95);",
                   h3("Order Status Distribution 📊", style = "color: #a855f7; font-weight: 800; margin-bottom: 16px; font-size: 18px;"),
                   plotlyOutput("status_donut_chart", height = "300px")
               )
        ),
        column(6,
               div(class = "glass-card", style = "background: rgba(255, 255, 255, 0.95);",
                   h3("Service Type Breakdown 🧺", style = "color: #a855f7; font-weight: 800; margin-bottom: 16px; font-size: 18px;"),
                   plotlyOutput("service_bar_chart", height = "300px")
               )
        )
      ),
      
      # Charts Row 2: Picked Up & Overstaying
      fluidRow(
        column(6,
               div(class = "glass-card", style = "background: rgba(255, 255, 255, 0.95);",
                   h3("Orders Picked Up (Last 7 Days) 📦", style = "color: #a855f7; font-weight: 800; margin-bottom: 16px; font-size: 18px;"),
                   plotlyOutput("picked_up_chart", height = "300px")
               )
        ),
        column(6,
               div(class = "glass-card", style = "background: rgba(255, 255, 255, 0.95);",
                   h3("Overstaying Orders ⏰", style = "color: #a855f7; font-weight: 800; margin-bottom: 16px; font-size: 18px;"),
                   plotlyOutput("overstaying_chart", height = "300px")
               )
        )
      )
    )
  })

  # Archived content as a reactive
  get_archived_content <- reactive({
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    archived <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE is_archived = 1 ORDER BY updated_at DESC")
    dbDisconnect(conn)
    
    tagList(
      # Page Header
      div(style = "display: flex; align-items: center; gap: 20px; margin-bottom: 32px; background: linear-gradient(135deg, rgba(252, 231, 243, 0.4) 0%, rgba(233, 213, 255, 0.4) 100%); padding: 24px; border-radius: 20px; border: 2px solid rgba(244, 114, 182, 0.2);",
          tags$span("📦", style = "font-size: 60px;"),
          div(
            h2("Archived Orders", class = "title-text", style = "margin: 0; font-size: 32px;"),
            p("View and manage your archived orders", class = "subtitle-text", style = "margin: 8px 0 0 0; font-size: 16px;")
          )
      ),
      
      # Archived Orders Table or Empty State
      if(nrow(archived) > 0) {
        div(class = "glass-card", style = "background: rgba(255, 255, 255, 0.95);",
            DTOutput("archived_orders_table")
        )
      } else {
        div(class = "glass-card", 
            style = "background: linear-gradient(135deg, #fce7f3 0%, #e9d5ff 100%); padding: 60px 20px; text-align: center;",
            tags$span("📦", style = "font-size: 80px; display: block; margin-bottom: 16px; opacity: 0.5;"),
            tags$p(style = "font-size: 18px; font-weight: 700; color: #a855f7; margin: 0;", 
                   "No archived orders yet"),
            tags$p(style = "font-size: 14px; color: #c084fc; margin-top: 8px;", 
                   "Archived orders will appear here")
        )
      }
    )
  })
  
  # Single page content renderer
  output$current_page_content <- renderUI({
    page <- current_page()
    
    if(page == "dashboard") {
      get_dashboard_content()
    } else if(page == "orders") {
      get_orders_content()
    } else if(page == "reports") {
      get_reports_content()
    } else if(page == "archived") {  
      get_archived_content()
    }
  })
  
  # Navigation handlers
  observeEvent(input$nav_dashboard, {
    current_page("dashboard")
    
    # Update button styles
    runjs("
      $('.nav-btn').removeClass('active').addClass('inactive');
      $('#nav_dashboard').removeClass('inactive').addClass('active');
    ")
  })
  
  observeEvent(input$nav_orders, {
    current_page("orders")
    
    # Update button styles
    runjs("
      $('.nav-btn').removeClass('active').addClass('inactive');
      $('#nav_orders').removeClass('inactive').addClass('active');
    ")
  })
  
  observeEvent(input$nav_reports, {
    current_page("reports")
    
    # Update button styles
    runjs("
    $('.nav-btn').removeClass('active').addClass('inactive');
    $('#nav_reports').removeClass('inactive').addClass('active');
  ")
  })
  
  observeEvent(input$nav_archived, {
    current_page("archived")
  })
  
  
  observeEvent(input$nav_logout, {
    showModal(modalDialog(
      title = "👋 Logout",
      "Are you sure you want to logout?",
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_logout", "Logout", class = "btn btn-danger")
      )
    ))
  })
  
  observeEvent(input$confirm_logout, {
    logged_in(FALSE)
    removeModal()
    # current_page("dashboard")
    showNotification("👋 Logged out successfully!", type = "message")
  })
  
  observe({
    page <- current_page()
    
    if(page == "dashboard") {
      updateActionButton(session, "nav_dashboard", label = "🏠 Dashboard")
      updateActionButton(session, "nav_orders", label = "📋 Orders")
      updateActionButton(session, "nav_reports", label = "📊 Reports")
    }
  })
  
  # Auto-progress every 15 seconds, progress after 2 minutes
  autoProgress <- reactiveTimer(15000)
  
  observeEvent(autoProgress(), {
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    orders <- dbGetQuery(conn, "
    SELECT id, status, service_type, updated_at, 
           (julianday('now', 'localtime') - julianday(updated_at)) * 24 * 60 as minutes_elapsed
    FROM laundry_orders 
    WHERE status IN ('Pending', 'Washing', 'Folding', 'Iron')
  ")
    
    rows_affected <- 0
    
    if(nrow(orders) > 0) {
      current_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      
      for(i in 1:nrow(orders)) {
        if(!is.na(orders$minutes_elapsed[i]) && orders$minutes_elapsed[i] >= 2) {
          service <- orders$service_type[i]
          current_status <- orders$status[i]
          
          # Determine next status based on service type
          new_status <- NULL
          
          if(service == "Wash & Fold") {
            new_status <- switch(current_status,
                                 "Pending" = "Washing",
                                 "Washing" = "Folding",
                                 "Folding" = "Ready for Pickup",
                                 NULL)
          } else if(service == "Wash & Iron") {
            new_status <- switch(current_status,
                                 "Pending" = "Washing",
                                 "Washing" = "Iron",
                                 "Iron" = "Ready for Pickup",
                                 NULL)
          }
          
          if(!is.null(new_status)) {
            dbExecute(conn, "UPDATE laundry_orders SET status = ?, updated_at = ? WHERE id = ?",
                      params = list(new_status, current_time, orders$id[i]))
            rows_affected <- rows_affected + 1
          }
        }
      }
    }
    
    dbDisconnect(conn)
    
    if(rows_affected > 0) {
      refresh_trigger(refresh_trigger() + 1)
    }
  })
  # CREATE - From modal
  observeEvent(input$submit_order, {
    req(input$modal_customer_name, input$modal_phone_number, input$modal_loads, input$modal_pickup_date)
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    tryCatch({
      current_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      pickup_date <- as.character(input$modal_pickup_date)
      
      dbExecute(conn, "
      INSERT INTO laundry_orders (customer_name, phone_number, loads, service_type, pickup_date, status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 'Pending', ?, ?)
    ", params = list(input$modal_customer_name, input$modal_phone_number, input$modal_loads, 
                     input$modal_service_type, pickup_date, current_time, current_time))
      
      showNotification("🎉 Order added successfully!", type = "message", duration = 3)
      
      # Close modal properly using removeModal()
      removeModal()
      
      # Clear form inputs
      updateTextInput(session, "modal_customer_name", value = "")
      updateTextInput(session, "modal_phone_number", value = "")
      updateNumericInput(session, "modal_loads", value = 1)
      updateDateInput(session, "modal_pickup_date", value = Sys.Date() + 3)
      updateTextAreaInput(session, "modal_notes", value = "")
      
      refresh_trigger(refresh_trigger() + 1)
    }, error = function(e) {
      showNotification(paste("❌ Error:", e$message), type = "error")
    })
    
    dbDisconnect(conn)
  })  
  # Close modal handlers
  observeEvent(input$cancel_modal, {
    runjs("$('#show_add_modal').click();")
  })
  
  observeEvent(input$close_modal, {
    runjs("$('#show_add_modal').click();")
  })
  
  # READ
  
  get_archived_orders <- reactive({
    refresh_trigger()
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    orders <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE is_archived = 1 ORDER BY updated_at DESC")
    dbDisconnect(conn)
    
    orders
  })
  
  # Helper function to check if order is overstaying
  is_overstaying <- function(status, updated_at, threshold_days = 3) {
    if(status != "Ready for Pickup") return(FALSE)
    
    days_waiting <- as.numeric(difftime(Sys.Date(), as.Date(updated_at), units = "days"))
    return(days_waiting > threshold_days)
  }
  
  # Orders Page
  output$overstaying_count <- renderText({
    orders <- get_orders()
    count <- sum(sapply(1:nrow(orders), function(i) {
      is_overstaying(orders$status[i], orders$updated_at[i])
    }))
    as.character(count)
  })
  
  
  # Reports page charts (same data as dashboard)
  
  # Picked Up Orders Chart (Reports page only)
  output$picked_up_chart <- renderPlotly({
    refresh_trigger()
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    picked_up_data <- dbGetQuery(conn, "
    SELECT DATE(updated_at) as date, COUNT(*) as count 
    FROM laundry_orders 
    WHERE status = 'Picked Up'
    AND is_archived = 0
    AND DATE(updated_at) >= DATE('now', '-7 days')
    GROUP BY DATE(updated_at)
    ORDER BY date
  ")
    
    dbDisconnect(conn)
    
    if(nrow(picked_up_data) > 0) {
      plot_ly(picked_up_data, 
              x = ~date, 
              y = ~count, 
              type = 'bar',
              marker = list(
                color = '#d8b4fe',  # UPDATED: pastel purple
                line = list(color = '#a78bfa', width = 2)
              )) %>%
        layout(
          xaxis = list(title = "Date", tickfont = list(color = '#a855f7')),
          yaxis = list(title = "Orders Picked Up", tickfont = list(color = '#a855f7')),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)'
        )
    } else {
      plot_ly() %>%
        layout(
          annotations = list(
            text = "No picked up orders in the last 7 days",
            showarrow = FALSE,
            font = list(size = 14, color = '#c084fc')
          ),
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)'
        )
    }
  })  
  # Overstaying Orders Chart (Reports page only)
  output$overstaying_chart <- renderPlotly({
    refresh_trigger()
    orders <- get_orders()
    
    if(nrow(orders) > 0) {
      ready_orders <- orders[orders$status == "Ready for Pickup", ]
      
      if(nrow(ready_orders) > 0) {
        # Calculate days waiting for each order
        ready_orders$days_waiting <- as.numeric(difftime(Sys.Date(), as.Date(ready_orders$updated_at), units = "days"))
        
        # Categorize
        ready_orders$category <- cut(ready_orders$days_waiting,
                                     breaks = c(-Inf, 3, 7, Inf),
                                     labels = c("0-3 days", "4-7 days", "7+ days"),
                                     right = TRUE)
        
        # Count by category
        overstaying_data <- as.data.frame(table(ready_orders$category))
        names(overstaying_data) <- c("category", "count")
        overstaying_data <- overstaying_data[overstaying_data$count > 0, ]
        
        # Assign colors based on category
        color_map <- c("0-3 days" = "#a7f3d0", "4-7 days" = "#fde68a", "7+ days" = "#fecaca")
        chart_colors <- color_map[as.character(overstaying_data$category)]
        
        plot_ly(overstaying_data, 
                labels = ~category, 
                values = ~count, 
                type = 'pie',
                textinfo = 'label+value+percent',  # Show count + percentage
                textfont = list(size = 12, color = '#374151'),
                marker = list(colors = chart_colors,
                              line = list(color = '#ffffff', width = 2))) %>%
          layout(
            title = list(
              text = paste0("Total Ready: ", nrow(ready_orders)),
              font = list(size = 14, color = '#a855f7')
            ),
            showlegend = TRUE,
            plot_bgcolor = 'rgba(0,0,0,0)',
            paper_bgcolor = 'rgba(0,0,0,0)',
            font = list(family = 'Nunito', color = '#a855f7')
          )
      } else {
        plot_ly() %>%
          layout(
            annotations = list(
              text = "No orders ready for pickup",
              showarrow = FALSE,
              font = list(size = 14, color = '#c084fc')
            ),
            xaxis = list(visible = FALSE),
            yaxis = list(visible = FALSE),
            plot_bgcolor = 'rgba(0,0,0,0)',
            paper_bgcolor = 'rgba(0,0,0,0)'
          )
      }
    } else {
      plot_ly() %>%
        layout(
          annotations = list(
            text = "No data available",
            showarrow = FALSE,
            font = list(size = 14, color = '#c084fc')
          ),
          xaxis = list(visible = FALSE),
          yaxis = list(visible = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)',
          paper_bgcolor = 'rgba(0,0,0,0)'
        )
    }
  })  
  
  # Metric cards with enhanced styling
  fluidRow(
    column(6,
           div(class = "glass-card", 
               style = "background: linear-gradient(135deg, rgba(219, 234, 254, 0.8) 0%, rgba(191, 219, 254, 0.6) 100%); border: 2px solid rgba(59, 130, 246, 0.3); min-height: 140px; display: flex; flex-direction: column; justify-content: center;",
               div(style = "text-align: center;",
                   tags$span("📦", style = "font-size: 48px; display: block; margin-bottom: 12px; filter: drop-shadow(0 4px 8px rgba(59, 130, 246, 0.3));"),
                   h4(style = "color: #2563eb; margin: 0; font-size: 14px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;", "Picked Up Today"),
                   h2(style = "color: #1e40af; margin: 12px 0 0 0; font-weight: 800; font-size: 48px; line-height: 1;", textOutput("picked_up_today"))
               )
           )
    ),
    column(6,
           div(class = "glass-card", 
               style = "background: linear-gradient(135deg, rgba(233, 213, 255, 0.8) 0%, rgba(216, 180, 254, 0.6) 100%); border: 2px solid rgba(168, 85, 247, 0.3); min-height: 140px; display: flex; flex-direction: column; justify-content: center;",
               div(style = "text-align: center;",
                   tags$span("🧺", style = "font-size: 48px; display: block; margin-bottom: 12px; filter: drop-shadow(0 4px 8px rgba(168, 85, 247, 0.3));"),
                   h4(style = "color: #7c3aed; margin: 0; font-size: 14px; font-weight: 600; text-transform: uppercase; letter-spacing: 1px;", "Total Active Orders"),
                   h2(style = "color: #6b21a8; margin: 12px 0 0 0; font-weight: 800; font-size: 48px; line-height: 1;", textOutput("total_orders"))
               )
           )
    ),
  )

  
  # Completed orders today
  output$completed_today <- renderText({
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    count <- dbGetQuery(conn, "
    SELECT COUNT(*) as count 
    FROM laundry_orders 
    WHERE status = 'Picked Up' 
    AND DATE(updated_at) = DATE('now')
    AND is_archived = 0
  ")
    
    dbDisconnect(conn)
    as.character(count$count)
  })
  
  # Picked up today
  output$picked_up_today <- renderText({
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    count <- dbGetQuery(conn, "
    SELECT COUNT(*) as count 
    FROM laundry_orders 
    WHERE status = 'Picked Up'
    AND is_archived = 0
  ")
    
    dbDisconnect(conn)
    as.character(count$count)
  })  
  
  # Total active orders
  output$total_orders <- renderText({
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    count <- dbGetQuery(conn, "
    SELECT COUNT(*) as count 
    FROM laundry_orders 
    WHERE is_archived = 0
  ")
    
    dbDisconnect(conn)
    as.character(count$count)
  })
  
  # Status bar chart
  output$status_donut_chart <- renderPlotly({
    refresh_trigger()
    orders <- get_orders()
    
    if (nrow(orders) > 0) {
      status_counts <- table(orders$status)
      
      # Define colors for each status
      status_colors <- c(
        "Pending" = "#fef3c7",
        "Washing" = "#dbeafe",
        "Folding" = "#e9d5ff",
        "Iron" = "#fed7aa",
        "Ready for Pickup" = "#d1fae5",
        "Picked Up" = "#e0e7ff"
      )
      
      # Map colors to match the order of statuses in the data
      chart_colors <- status_colors[names(status_counts)]
      
      plot_ly(
        labels = names(status_counts),
        values = as.numeric(status_counts),
        type = "pie",
        hole = 0.6,
        marker = list(
          colors = chart_colors,
          line = list(color = "#ffffff", width = 2)
        ),
        textinfo = "none",  
        hovertemplate = "%{label}<br>%{percent}<extra></extra>"
      ) %>%
        layout(
          showlegend = TRUE,   
          paper_bgcolor = "rgba(0,0,0,0)",
          plot_bgcolor = "rgba(0,0,0,0)",
          font = list(family = "Nunito", color = "#a855f7")
        )
      
    } else {
      plot_ly() %>%
        layout(
          annotations = list(
            text = "No data yet",
            showarrow = FALSE,
            font = list(size = 16, color = "#c084fc")
          )
        )
    }
  })
  
  observeEvent(input$show_add_modal, {
    showModal(modalDialog(
      title = div(style = "color: #f472b6; font-weight: 800; font-size: 24px;",
                  "➕ Add New Order"),
      div(
        p("Fill out the form below to create a new laundry order", 
          style = "color: #c084fc; font-weight: 600; margin: 0 0 20px 0; font-size: 14px;"),
        
        div(class = "form-group",
            tags$label(class = "form-label", "Customer Name"),
            textInput("modal_customer_name", NULL, placeholder = "Enter customer name...", width = "100%")
        ),
        div(class = "form-group",
            tags$label(class = "form-label", "Phone Number"),
            textInput("modal_phone_number", NULL, placeholder = "Enter phone number...", width = "100%")
        ),
        fluidRow(
          column(6,
                 div(class = "form-group",
                     tags$label(class = "form-label", "Number of Loads"),
                     numericInput("modal_loads", NULL, value = 1, min = 1, width = "100%")
                 )
          ),
          column(6,
                 div(class = "form-group",
                     tags$label(class = "form-label", "Service Type"),
                     selectInput("modal_service_type", NULL,
                                 choices = c("Wash & Fold", "Wash & Iron"),
                                 width = "100%")
                 )
          )
        ),
        div(class = "form-group",
            tags$label(class = "form-label", "Pickup Date (Optional)"),
            dateInput("modal_pickup_date", NULL, value = Sys.Date() + 3, 
                      min = Sys.Date(), width = "100%")
        ),
        div(class = "form-group",
            tags$label(class = "form-label", "Special Instructions (Optional)"),
            textAreaInput("modal_notes", NULL, 
                          placeholder = "Any special instructions or notes...", 
                          rows = 3, width = "100%")
        )
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("submit_order", "Add Order 🎉", class = "btn btn-primary")
      ),
      size = "l",
      easyClose = TRUE
    ))
  })  
  # adding order triggered by quick action button
  observeEvent(input$quick_new_order, {
    showModal(modalDialog(
      title = div(style = "color: #f472b6; font-weight: 800; font-size: 24px;",
                  "➕ Add New Order"),
      div(
        p("Fill out the form below to create a new laundry order", 
          style = "color: #c084fc; font-weight: 600; margin: 0 0 20px 0; font-size: 14px;"),
        
        div(class = "form-group",
            tags$label(class = "form-label", "Customer Name"),
            textInput("modal_customer_name", NULL, placeholder = "Enter customer name...", width = "100%")
        ),
        div(class = "form-group",
            tags$label(class = "form-label", "Phone Number"),
            textInput("modal_phone_number", NULL, placeholder = "Enter phone number...", width = "100%")
        ),
        fluidRow(
          column(6,
                 div(class = "form-group",
                     tags$label(class = "form-label", "Number of Loads"),
                     numericInput("modal_loads", NULL, value = 1, min = 1, width = "100%")
                 )
          ),
          column(6,
                 div(class = "form-group",
                     tags$label(class = "form-label", "Service Type"),
                     selectInput("modal_service_type", NULL,
                                 choices = c("Wash & Fold", "Wash & Iron"),
                                 width = "100%")
                 )
          )
        ),
        div(class = "form-group",
            tags$label(class = "form-label", "Pickup Date (Optional)"),
            dateInput("modal_pickup_date", NULL, value = Sys.Date() + 3, 
                      min = Sys.Date(), width = "100%")
        ),
        div(class = "form-group",
            tags$label(class = "form-label", "Special Instructions (Optional)"),
            textAreaInput("modal_notes", NULL, 
                          placeholder = "Any special instructions or notes...", 
                          rows = 3, width = "100%")
        )
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("submit_order", "Add Order 🎉", class = "btn btn-primary")
      ),
      size = "l",
      easyClose = TRUE
    ))
  })
  
  observeEvent(input$quick_view_orders, {
    current_page("orders")
    runjs("
      $('.nav-btn').removeClass('active').addClass('inactive');
      $('#nav_orders').removeClass('inactive').addClass('active');
    ")
  })
  
  observeEvent(input$quick_view_reports, {
    current_page("reports")
    runjs("
    $('.nav-btn').removeClass('active').addClass('inactive');
    $('#nav_reports').removeClass('inactive').addClass('active');
  ")
  })
  
  observeEvent(input$archive_order, {
    req(input$archive_order)  
    
    order_id <- input$archive_order
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    # Update the order to set is_archived = 1
    dbExecute(conn, 
              "UPDATE laundry_orders SET is_archived = 1, updated_at = ? WHERE id = ?",
              params = list(Sys.time(), order_id)
    )
    
    dbDisconnect(conn)
    
    refresh_trigger(refresh_trigger() + 1)
    
    showNotification("Order archived successfully!", type = "message")
  })
  
  
  # Render Archived Orders Table
  output$archived_orders_table <- renderDT({
    current_page()
    refresh_trigger()
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    archived <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE is_archived = 1 ORDER BY updated_at DESC")
    dbDisconnect(conn)
    
    if(nrow(archived) > 0) {
      archived$Status_Display <- sapply(archived$status, function(s) {
        class_name <- tolower(gsub(" ", "-", gsub(" for Pickup", "", s)))
        paste0('<span class="status-', class_name, '">', 
               switch(s,
                      "Pending" = "🕐 Pending",
                      "Washing" = "🫧 Washing",
                      "Folding" = "🌀 Folding",
                      "Ready for Pickup" = "✨ Ready",
                      "Picked Up" = "✅ Picked Up",
                      s),
               '</span>')
      })
      
      archived$Actions <- sapply(1:nrow(archived), function(i) {
        id <- archived$id[i]
        
        restore_btn <- sprintf(
          '<button onclick="Shiny.setInputValue(\'restore_order\', %d, {priority: \'event\'})" style="background: #d1fae5; color: #059669; border: none; padding: 8px 12px; border-radius: 10px; font-weight: 700; font-size: 12px; cursor: pointer; margin-right: 5px;">🔄 Restore</button>',
          id
        )
        
        delete_btn <- sprintf(
          '<button onclick="Shiny.setInputValue(\'delete_archived_order\', %d, {priority: \'event\'})" style="background: #fee2e2; color: #dc2626; border: none; padding: 8px 12px; border-radius: 10px; font-weight: 700; font-size: 12px; cursor: pointer;">🗑️ Delete</button>',
          id
        )
        
        paste0(restore_btn, delete_btn)
      })
      
      display_archived <- archived[, c("id", "customer_name", "phone_number", "service_type", "Status_Display", "updated_at", "Actions")]
      colnames(display_archived) <- c("ID", "Customer", "Phone", "Service", "Status", "Archived Date", "Actions")
      
      datatable(display_archived,
                escape = FALSE,
                options = list(
                  pageLength = 10,
                  dom = 'tip',
                  ordering = TRUE
                ),
                rownames = FALSE)
    }
  })
  
  # Restore Order
  observeEvent(input$restore_order, {
    req(input$restore_order)
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    dbExecute(conn, 
              "UPDATE laundry_orders SET is_archived = 0, updated_at = ? WHERE id = ?",
              params = list(Sys.time(), input$restore_order))
    dbDisconnect(conn)
    
    refresh_trigger(refresh_trigger() + 1)
    showNotification("✅ Order restored successfully!", type = "message")
  })
  
  # Delete Archived Order Permanently
  observeEvent(input$delete_archived_order, {
    req(input$delete_archived_order)
    
    showModal(modalDialog(
      title = "⚠️ Confirm Deletion",
      div(style = "padding: 20px; text-align: center;",
          tags$p(style = "font-size: 16px; color: #dc2626; font-weight: 700;",
                 "Are you sure you want to permanently delete this order?"),
          tags$p(style = "font-size: 14px; color: #6b7280;",
                 "This action cannot be undone!")
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete_archived", "Delete Permanently", 
                     style = "background: #dc2626; color: white; border: none; padding: 10px 20px; border-radius: 10px; font-weight: 700; cursor: pointer;")
      ),
      easyClose = FALSE
    ))
  })
  
  # Confirm Delete Archived Order
  observeEvent(input$confirm_delete_archived, {
    req(input$delete_archived_order)
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    dbExecute(conn, "DELETE FROM laundry_orders WHERE id = ?", 
              params = list(input$delete_archived_order))
    dbDisconnect(conn)
    
    refresh_trigger(refresh_trigger() + 1)
    removeModal()
    showNotification("🗑️ Order permanently deleted", type = "warning")
  })
  
  # Restore Order
  observeEvent(input$restore_order, {
    req(input$restore_order)
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    dbExecute(conn, 
              "UPDATE laundry_orders SET is_archived = 0, updated_at = ? WHERE id = ?",
              params = list(Sys.time(), input$restore_order))
    dbDisconnect(conn)
    
    refresh_trigger(refresh_trigger() + 1)
    showNotification("✅ Order restored successfully!", type = "message")
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    archived <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE is_archived = 1")
    dbDisconnect(conn)
    
    if(nrow(archived) == 0) {
      removeModal()
    }
  })
  
  # Delete Archived Order Permanently
  observeEvent(input$delete_archived_order, {
    req(input$delete_archived_order)
    
    showModal(modalDialog(
      title = "⚠️ Confirm Deletion",
      div(style = "padding: 20px; text-align: center;",
          tags$p(style = "font-size: 16px; color: #dc2626; font-weight: 700;",
                 "Are you sure you want to permanently delete this order?"),
          tags$p(style = "font-size: 14px; color: #6b7280;",
                 "This action cannot be undone!")
      ),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_delete_archived", "Delete Permanently", 
                     style = "background: #dc2626; color: white; border: none; padding: 10px 20px; border-radius: 10px; font-weight: 700; cursor: pointer;")
      ),
      easyClose = FALSE
    ))
  })
  
  # Confirm Delete Archived Order
  observeEvent(input$confirm_delete_archived, {
    req(input$delete_archived_order)
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    dbExecute(conn, "DELETE FROM laundry_orders WHERE id = ?", 
              params = list(input$delete_archived_order))
    dbDisconnect(conn)
    
    refresh_trigger(refresh_trigger() + 1)
    removeModal()
    showNotification("🗑️ Order permanently deleted", type = "warning")
    
    # Check if there are more archived orders
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    archived <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE is_archived = 1")
    dbDisconnect(conn)
    
    # If no more archived orders, close the archived modal too
    if(nrow(archived) == 0) {
      Sys.sleep(0.5)  
      removeModal()
    }
  })
  
  # Display orders table
  output$orders_table <- renderDT({
    orders <- get_orders()
    
    if(nrow(orders) > 0) {
      orders$Status_Display <- sapply(orders$status, function(s) {
        class_name <- tolower(gsub(" ", "-", gsub(" for Pickup", "", s)))
        paste0('<span class="status-', class_name, '">', 
               switch(s,
                      "Pending" = "🕐 Pending",
                      "Washing" = "🫧 Washing",
                      "Folding" = "🌀 Folding",
                      "Iron" = "🔥 Ironing",
                      "Ready for Pickup" = "✨ Ready",
                      "Picked Up" = "✅ Picked Up",
                      s),
               '</span>')
      })
      
      # Add action buttons with overstay badge
      orders$Actions <- sapply(1:nrow(orders), function(i) {
        id <- orders$id[i]
        status <- orders$status[i]
        updated_at <- orders$updated_at[i]
        
        # Check if overstaying
        overstay_badge <- ""
        
        # View/Edit button 
        view_btn <- sprintf(
          '<button onclick="Shiny.setInputValue(\'view_order\', %d, {priority: \'event\'})" style="background: #dbeafe; color: #1e40af; border: none; padding: 8px 12px; border-radius: 10px; font-weight: 700; font-size: 12px; cursor: pointer; margin-right: 5px;">View</button>',
          id
        )
        
        # Pick Up button - only show when status = "Ready for Pickup"
        if(status == "Ready for Pickup") {
          pickup_btn <- sprintf(
            '<button onclick="Shiny.setInputValue(\'pickup_order\', %d, {priority: \'event\'})" style="background: #d1fae5; color: #059669; border: none; padding: 8px 12px; border-radius: 10px; font-weight: 700; font-size: 12px; cursor: pointer; margin-right: 5px;">Pick Up</button>',
            id
          )
        } else {
          pickup_btn <- ""
        }
        
        # Delete button
        if(status == "Pending") {
          delete_btn <- sprintf(
            '<button onclick="Shiny.setInputValue(\'delete_order\', %d, {priority: \'event\'})" style="background: #fee2e2; color: #dc2626; border: none; padding: 8px 12px; border-radius: 10px; font-weight: 700; font-size: 12px; cursor: pointer;">Delete</button>',
            id
          )
        } else {
          delete_btn <- sprintf(
            '<button onclick="Shiny.setInputValue(\'delete_order\', %d, {priority: \'event\'})" style="background: #f3f4f6; color: #9ca3af; border: none; padding: 8px 12px; border-radius: 10px; font-weight: 700; font-size: 12px; cursor: pointer;">Delete</button>',
            id
          )
        }
        
        # Archive button - only show when status = "Picked Up"
        if(status == "Picked Up") {
          archive_btn <- sprintf(
            '<button onclick="Shiny.setInputValue(\'archive_order\', %d, {priority: \'event\'})" style="background: #fef3c7; color: #92400e; border: none; padding: 8px 12px; border-radius: 10px; font-weight: 700; font-size: 12px; cursor: pointer; margin-right: 5px;">Archive</button>',
            id
          )
        } else {
          archive_btn <- ""
        }
        
        paste0(overstay_badge, view_btn, pickup_btn, archive_btn, delete_btn)
      })
      
      display_orders <- orders[, c("id", "customer_name", "phone_number", "loads", 
                                   "service_type", "pickup_date", "Status_Display", "created_at", "Actions")]
      colnames(display_orders) <- c("ID", "Customer", "Phone", "Loads", "Service", "Pickup Date", "Status", "Created", "Actions")
      
      datatable(display_orders,
                escape = FALSE,
                options = list(
                  pageLength = 10,
                  dom = 'tip',
                  ordering = TRUE,
                  columnDefs = list(
                    list(className = 'dt-center', targets = c(0, 3, 5, 7)),
                    list(width = '120px', targets = 6) 
                  )
                ),
                rownames = FALSE)
    } else {
      datatable(data.frame(Message = "No orders yet. Add your first order above! 🌸"), 
                options = list(dom = 't'), rownames = FALSE)
    }
  })
  
  # UPDATE: Pick up
  observeEvent(input$pickup_order, {
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    # Get both status and pickup_date
    order <- dbGetQuery(conn, "SELECT status, pickup_date FROM laundry_orders WHERE id = ?", 
                        params = list(input$pickup_order))
    
    dbDisconnect(conn)
    
    if(nrow(order) > 0 && order$status[1] == "Ready for Pickup") {
      pickup_date <- as.Date(order$pickup_date[1])
      today_date <- Sys.Date()
      
      showModal(modalDialog(
        title = "✅ Confirm Pickup",
        div(
          p(strong(paste0("Order #", input$pickup_order))),
          p(paste0("Scheduled pickup date: ", format(pickup_date, "%B %d, %Y"))),
          p(paste0("Today's date: ", format(today_date, "%B %d, %Y"))),
          tags$br(),
          p("Continue with pickup?")
        ),
        footer = tagList(
          modalButton("Cancel"),
          actionButton("confirm_pickup", "Mark as Picked Up", class = "btn btn-success")
        )
      ))
    } else {
      showNotification("⚠️ Order must be 'Ready for Pickup' first!", type = "warning")
    }
  })
  
  # Execute Pickup (update status to Picked Up)
  observeEvent(input$confirm_pickup, {
    req(input$confirm_pickup)
    
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    tryCatch({
      order <- dbGetQuery(conn, "SELECT status FROM laundry_orders WHERE id = ?", 
                          params = list(input$pickup_order))
      
      if(nrow(order) > 0 && order$status[1] == "Ready for Pickup") {
        current_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
        dbExecute(conn, "UPDATE laundry_orders SET status = 'Picked Up', updated_at = ? WHERE id = ?",
                  params = list(current_time, input$pickup_order))
        
        dbDisconnect(conn)
        removeModal()
        
        showNotification("✅ Order marked as Picked Up!", type = "message", duration = 3)
        
        invalidateLater(100)
        isolate({
          refresh_trigger(refresh_trigger() + 1)
        })
        
      } else {
        dbDisconnect(conn)
        removeModal()
        showNotification("⚠️ Order status has changed. Cannot mark as picked up.", type = "warning")
      }
      
    }, error = function(e) {
      if(exists("conn") && dbIsValid(conn)) {
        dbDisconnect(conn)
      }
      showNotification(paste("Error:", e$message), type = "error")
      removeModal()
    })
  }, ignoreInit = TRUE, ignoreNULL = TRUE)
  
  # DELETE
  observeEvent(input$delete_order, {
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    # Get order status fore deleting
    order <- dbGetQuery(conn, "SELECT status FROM laundry_orders WHERE id = ?", 
                        params = list(input$delete_order))
    
    dbDisconnect(conn)
    
    if(nrow(order) > 0) {
      status <- order$status[1]
      
      if(status == "Pending"  || status == "Picked Up" ) {
        # Allow deletion
        showModal(modalDialog(
          title = "🗑️ Confirm Deletion",
          paste("Are you sure you want to delete order #", input$delete_order, "?"),
          p(style = "color: #6b7280; margin-top: 10px;", 
            if(status == "Pending") "This order hasn't started processing yet." 
            else "This order has been picked up and can be safely removed from the system."),
          footer = tagList(
            modalButton("Cancel"),
            actionButton("confirm_delete", "Delete", class = "btn btn-danger")
          )
        ))
      } else {
        showModal(modalDialog(
          title = "⚠️ Cannot Delete Order",
          div(style = "padding: 10px;",
              p(strong("This order cannot be deleted.")),
              p(paste0("Current status: ", status)),
              p("Orders can only be deleted when they are 'Pending' or 'Picked Up'."),
              p(style = "color: #6b7280; font-size: 14px; margin-top: 10px;",
                "Orders in progress (Washing, Folding, Ready for Pickup) cannot be deleted.")),
          footer = modalButton("OK"),
          easyClose = TRUE
        ))
      }
    }
  })
  
  # Execute Deletion (only called when status was Pending)
  observeEvent(input$confirm_delete, {
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    order <- dbGetQuery(conn, "SELECT status FROM laundry_orders WHERE id = ?", 
                        params = list(input$delete_order))
    
    if(nrow(order) > 0 && (order$status[1] == "Pending" || order$status[1] == "Picked Up")) {
      dbExecute(conn, "DELETE FROM laundry_orders WHERE id = ?", 
                params = list(input$delete_order))
      showNotification("✅ Order deleted successfully!", type = "message")
      refresh_trigger(refresh_trigger() + 1)
    } else {
      showNotification("⚠️ Order cannot be deleted (status changed)", type = "warning")
    }
    
    dbDisconnect(conn)
    removeModal()
  })
  
  # View/Edit Order Modal
  observeEvent(input$view_order, {
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    order <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE id = ?", 
                        params = list(input$view_order))
    
    dbDisconnect(conn)
    
    if(nrow(order) > 0) {
      status <- order$status[1]
      
      showModal(modalDialog(
        title = paste("👁️ View Order #", order$id),
        div(style = "background: #f9fafb; padding: 20px; border-radius: 8px;",
            div(style = "margin-bottom: 12px;",
                strong("Customer:"), " ", order$customer_name),
            div(style = "margin-bottom: 12px;",
                strong("Phone:"), " ", order$phone_number),
            div(style = "margin-bottom: 12px;",
                strong("Loads:"), " ", order$loads),
            div(style = "margin-bottom: 12px;",
                strong("Service Type:"), " ", order$service_type),
            div(style = "margin-bottom: 12px;",
                strong("Pickup Date:"), " ", 
                tryCatch({
                  if(grepl("^\\d{4}-\\d{2}-\\d{2}", order$pickup_date)) {
                    format(as.Date(order$pickup_date), "%B %d, %Y")
                  } else {
                    format(as.Date(as.numeric(order$pickup_date), origin = "1970-01-01"), "%B %d, %Y")
                  }
                }, error = function(e) {
                  order$pickup_date
                })
            ),
            div(style = "margin-bottom: 12px;",
                strong("Status:"), " ", 
                span(style = paste0("padding: 4px 12px; border-radius: 12px; font-weight: 600; ",
                                    "background: ", if(status == "Pending") "#fef3c7" else if(status == "Washing") "#dbeafe" else if(status == "Folding") "#e0e7ff" else if(status == "Ready for Pickup") "#d1fae5" else "#d1fae5", "; ",
                                    "color: ", if(status == "Pending") "#92400e" else if(status == "Washing") "#1e40af" else if(status == "Folding") "#4338ca" else if(status == "Ready for Pickup") "#059669" else "#059669"),
                     status)),
            div(style = "margin-top: 12px;",
                strong("Instructions:"), br(),
                em(style = "color: #6b7280;", if(is.na(order$instructions) || order$instructions == "") "No instructions" else order$instructions))
        ),
        footer = tagList(
          modalButton("Close"),
          if(status != "Picked Up") {
            actionButton("open_edit_modal", "Edit", class = "btn btn-primary", 
                         icon = icon("pencil"))
          }
        ),
        easyClose = TRUE,
        size = "m"
      ))
      }
  })
  
  # Open Edit Modal from View Modal
  observeEvent(input$open_edit_modal, {
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    order <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE id = ?", 
                        params = list(input$view_order))
    
    dbDisconnect(conn)
    
    if(nrow(order) > 0) {
      status <- order$status[1]
      
      if(status == "Pending") {
        # All fields editable
        showModal(modalDialog(
          title = paste("✏️ Edit Order #", order$id),
          textInput("edit_customer_name", "Customer Name", value = order$customer_name),
          textInput("edit_phone_number", "Phone Number", value = order$phone_number),
          numericInput("edit_loads", "Loads", value = order$loads, min = 1),
          selectInput("edit_service_type", "Service Type", 
                      choices = c("Wash & Fold", "Wash & Iron"),
                      selected = order$service_type),
          dateInput("edit_pickup_date", "Pickup Date", value = order$pickup_date),
          textAreaInput("edit_instructions", "Instructions", 
              value = if(is.na(order$instructions) || order$instructions == "NA") "" else order$instructions, 
              rows = 3, placeholder = "Add any special instructions..."),
          footer = tagList(
            actionButton("back_to_view", "← Back", class = "btn btn-secondary"),
            actionButton("save_edit", "Save Changes", class = "btn btn-primary")
          ),
          easyClose = FALSE,
          size = "m"
        ))
      } else {
        # Only pickup_date editable, others are locked but clickable
        showModal(modalDialog(
          title = paste("✏️ Edit Order #", order$id),
          div(style = "background: #fef3c7; padding: 12px; border-radius: 8px; margin-bottom: 15px; color: #92400e;",
              icon("lock"), " Order in progress. Only pickup date can be changed."),
          tags$div(
            onclick = "Shiny.setInputValue('locked_field_click', Math.random(), {priority: 'event'})",
            style = "cursor: not-allowed; opacity: 0.6;",
            textInput("edit_customer_name_locked", "Customer Name", value = order$customer_name),
            tags$script("$('#edit_customer_name_locked').prop('disabled', true);")
          ),
          tags$div(
            onclick = "Shiny.setInputValue('locked_field_click', Math.random(), {priority: 'event'})",
            style = "cursor: not-allowed; opacity: 0.6;",
            textInput("edit_phone_number_locked", "Phone Number", value = order$phone_number),
            tags$script("$('#edit_phone_number_locked').prop('disabled', true);")
          ),
          tags$div(
            onclick = "Shiny.setInputValue('locked_field_click', Math.random(), {priority: 'event'})",
            style = "cursor: not-allowed; opacity: 0.6;",
            numericInput("edit_loads_locked", "Loads", value = order$loads, min = 1),
            tags$script("$('#edit_loads_locked').prop('disabled', true);")
          ),
          tags$div(
            onclick = "Shiny.setInputValue('locked_field_click', Math.random(), {priority: 'event'})",
            style = "cursor: not-allowed; opacity: 0.6;",
            selectInput("edit_service_type_locked", "Service Type", 
                        choices = c("Wash & Fold", "Wash & Iron"),
                        selected = order$service_type),
            tags$script("$('#edit_service_type_locked').prop('disabled', true);")
          ),
          dateInput("edit_pickup_date", "Pickup Date", value = order$pickup_date),
          tags$div(
            onclick = "Shiny.setInputValue('locked_field_click', Math.random(), {priority: 'event'})",
            style = "cursor: not-allowed; opacity: 0.6;",
            textAreaInput("edit_instructions_locked", "Instructions", 
              value = if(is.na(order$instructions) || order$instructions == "NA") "" else order$instructions, 
              rows = 3),
            tags$script("$('#edit_instructions_locked').prop('disabled', true);")
          ),
          footer = tagList(
            actionButton("back_to_view", "← Back", class = "btn btn-secondary"),
            actionButton("save_edit", "Save Changes", class = "btn btn-primary")
          ),
          easyClose = FALSE,
          size = "m"
        ))
      }
    }
  })
  
  # Show popup when locked field is clicked
  observeEvent(input$locked_field_click, {
    showNotification(
      "🔒 This field is locked because the order is already in progress. Only the pickup date can be changed.",
      type = "warning",
      duration = 4
    )
  })
  
  # Back button - return to View modal
  observeEvent(input$back_to_view, {
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    order <- dbGetQuery(conn, "SELECT * FROM laundry_orders WHERE id = ?", 
                        params = list(input$view_order))
    
    dbDisconnect(conn)
    
    if(nrow(order) > 0) {
      status <- order$status[1]
      
      showModal(modalDialog(
        title = paste("👁️ View Order #", order$id),
        div(style = "background: #f9fafb; padding: 20px; border-radius: 8px;",
            div(style = "margin-bottom: 12px;",
                strong("Customer:"), " ", order$customer_name),
            div(style = "margin-bottom: 12px;",
                strong("Phone:"), " ", order$phone_number),
            div(style = "margin-bottom: 12px;",
                strong("Loads:"), " ", order$loads),
            div(style = "margin-bottom: 12px;",
                strong("Service Type:"), " ", order$service_type),
            div(style = "margin-bottom: 12px;",
                strong("Pickup Date:"), " ", order$pickup_date),
            div(style = "margin-bottom: 12px;",
                strong("Status:"), " ", 
                span(style = paste0("padding: 4px 12px; border-radius: 12px; font-weight: 600; ",
                                    "background: ", if(status == "Pending") "#fef3c7" else if(status == "Washing") "#dbeafe" else if(status == "Folding") "#e0e7ff" else if(status == "Ready for Pickup") "#d1fae5" else "#d1fae5", "; ",
                                    "color: ", if(status == "Pending") "#92400e" else if(status == "Washing") "#1e40af" else if(status == "Folding") "#4338ca" else if(status == "Ready for Pickup") "#059669" else "#059669"),
                     status)),
            div(style = "margin-top: 12px;",
                strong("Instructions:"), br(),
                em(style = "color: #6b7280;", if(is.na(order$instructions) || order$instructions == "" || order$instructions == "NA") "No instructions" else order$instructions))
        ),
        footer = tagList(
          modalButton("Close"),
          actionButton("open_edit_modal", "Edit", class = "btn btn-primary", 
                       icon = icon("pencil"))
        ),
        easyClose = TRUE,
        size = "m"
      ))
    }
  })

  # Save Edit Changes
  observeEvent(input$save_edit, {
    conn <- dbConnect(SQLite(), "bubblebuddy.sqlite")
    
    order <- dbGetQuery(conn, "SELECT status FROM laundry_orders WHERE id = ?", 
                        params = list(input$view_order))
    
    if(nrow(order) > 0) {
      status <- order$status[1]
      current_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      
      if(status == "Pending") {
        dbExecute(conn, 
                  "UPDATE laundry_orders SET customer_name = ?, phone_number = ?, loads = ?, service_type = ?, pickup_date = ?, instructions = ?, updated_at = ? WHERE id = ?",
                  params = list(
                    input$edit_customer_name,
                    input$edit_phone_number,
                    input$edit_loads,
                    input$edit_service_type,
                    as.character(input$edit_pickup_date),
                    input$edit_instructions,
                    current_time,
                    input$view_order
                  ))
        showNotification("✅ Order updated successfully!", type = "message")
      } else {
        dbExecute(conn, 
                  "UPDATE laundry_orders SET pickup_date = ?, updated_at = ? WHERE id = ?",
                  params = list(
                    as.character(input$edit_pickup_date),
                    current_time,
                    input$view_order
                  ))
        showNotification("✅ Pickup date updated!", type = "message")
      }
      
      refresh_trigger(refresh_trigger() + 1)
      removeModal()
    }
    
    dbDisconnect(conn)
  })
  
  # Refresh button
  observeEvent(input$refresh_orders, {
    refresh_trigger(refresh_trigger() + 1)
    showNotification("🔄 Refreshed!", type = "message")
  })
  
  
  # Bar Chart for Service Types
  output$service_bar_chart <- renderPlotly({
    refresh_trigger()
    orders <- get_orders()
    
    if(nrow(orders) > 0) {
      service_counts <- table(orders$service_type)
      
      plot_ly(x = names(service_counts), 
              y = as.vector(service_counts),
              type = 'bar',
              marker = list(color = c('#f472b6', '#a78bfa', '#10b981', '#fbbf24'),
                            line = list(color = '#ffffff', width = 2))) %>%
        layout(
          xaxis = list(title = "", tickfont = list(size = 11, color = '#a855f7', family = 'Nunito')),
          yaxis = list(title = "Orders", tickfont = list(size = 11, color = '#a855f7', family = 'Nunito')),
          margin = list(l = 40, r = 20, t = 20, b = 60),
          paper_bgcolor = 'rgba(0,0,0,0)',
          plot_bgcolor = 'rgba(0,0,0,0)',
          font = list(family = 'Nunito', color = '#a855f7', size = 12, weight = 700)
        )
    } else {
      plot_ly() %>% 
        layout(annotations = list(text = "No data yet", 
                                  showarrow = FALSE,
                                  font = list(size = 16, color = '#c084fc')))
    }
  })
  
}

shinyApp(ui = ui, server = server)
