library(httr)
library(jsonlite)

# 1. Define the Tableau dashboard URL
tableau_url <- "https://public.tableau.com/views/SeattlePublicUtilitiesMSWTonnageQuarterlyReport/HomePage"

# 2. Get the Tableau session bootstrap data
# Use curl to simulate a browser request
res <- httr::GET(
  tableau_url,
  httr::add_headers(
    `User-Agent` = "Mozilla/5.0"
  )
)

# 3. Extract the embedded JSON data (this only works if it's client-side rendered)
content_html <- content(res, "text")
bootstrap_info <- sub(".*bootstrapSession\":\"([^\"]+)\".*", "\\1", content_html)

# 4. View what we got (likely a session token)
cat("Bootstrap session:", bootstrap_info, "\n")
