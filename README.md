# Readme for rippR: GPT-Assisted PDF Data Extraction by Taylor Rundell

## Introduction
- `rippR` is an R script designed to automate the extraction of specific data points from a collection of PDF files. It uses the OpenAI GPT API to extract numerical data from sentences of PDFs.

## Key Features
- **PDF Loading and Text Extraction**: Scans a specified folder for PDFs and reads their text content.
- **Topic Filtering and Preprocessing**: Filters PDF pages based on user-defined topics and prepares the content using text mining techniques.
- **GPT API Query**: Sends the processed text to OpenAI's GPT API for numerical data extraction.

## How to Use
1. **API Key Setup**
   - Uncomment and insert your OpenAI API key in the line `Sys.setenv(OPENAI_API_KEY = 'your-api-key')`.
2. **Topic Definition**
   - Modify the `topics_of_interest` variable to include your topics. This is the initial filter to ensure that you only query relevant pages.
3. **Query Specification**
   - Modify the `message` variable to specify your query of relevant pages - eg, respond with the dollar value of the lease specified
4. **Run the Script**
   - Execute the script. The extracted data will be stored in a data frame called `answers_df`.
