# Use the official R Shiny image
FROM rocker/shiny:latest

# Install system dependencies needed for SQLite
RUN apt-get update && apt-get install -y \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install required R packages
RUN R -e "install.packages(c(
    'shiny', 
    'DBI', 
    'RSQLite', 
    'DT', 
    'dplyr', 
    'base64enc', 
    'shinyFeedback', 
    'shinyjs', 
    'plotly'
), repos='https://cloud.r-project.org')"

# Copy all app files into the container
COPY . /srv/shiny-server/
WORKDIR /srv/shiny-server/

# Expose Shiny port
EXPOSE 3838

# Run the app
CMD ["R", "-e", "shiny::runApp('.', host='0.0.0.0', port=3838)"]
