### rippR - Simple GPT-assisted PDF data extraction
### by Taylor Rundell

library(pdftools)
library(openai)
library(tm)

# Set your OpenAI API key here
# Sys.setenv(
#   OPENAI_API_KEY = 'AA-1234567890123456789012345678901234567890123456789'
# )


## 1 - Load in files and text

# Define the path to your folder containing PDFs
folder <- "./downloadedreports/"

# List all PDF files in the folder
pdf_files <- list.files(path = folder, pattern = "*.pdf", full.names = TRUE)

# Initialize an empty list to store the texts
pdf_texts <- list()

# Loop over each file
for(i in 1:length(pdf_files)){
  # Read the PDF file
  pdf_text <- pdf_text(pdf_files[i])
  
  # Store the text in the list
  pdf_texts[[i]] <- pdf_text
}

## 2. Filter and pre-process files


# Loop over each PDF
# Define the topics of interest in lower case - this should be a high-level filter aimed at identifying relevant pages to your query
topics_of_interest <- c("members","membership")

# Initialize an empty list to store the relevant pages
relevant_pages <- list()

# Loop over each PDF
for(i in 1:length(pdf_texts)){
  # Create a Corpus from the text
  corpus <- Corpus(VectorSource(pdf_texts[[i]]))
  
  # Preprocess the text
  corpus <- tm_map(corpus, content_transformer(tolower))
  corpus <- tm_map(corpus, removePunctuation)
  corpus <- tm_map(corpus, removeNumbers)
  corpus <- tm_map(corpus, removeWords, stopwords("english"))
  
  # Create a Document-Term Matrix
  dtm <- DocumentTermMatrix(corpus)
  
  # Find the pages that contain any of the topics of interest
  dtm_matrix <- as.matrix(dtm)
  topic_pages <- integer()
  for(topic in topics_of_interest){
    if(topic %in% colnames(dtm_matrix)){
      topic_pages <- c(topic_pages, which(dtm_matrix[,topic] > 0))
    }
  }
  relevant_pages[[i]] <- unique(topic_pages)
}

## 3. Query GPT API

## Set your own prompt with the questions you want. The most important parts of the prompt are instructing it to only respond with numeric output, and a clear NA instruction, particularly if there are similar text lines in your documents.

gpt_query <- function(document){
  # Construct the conversation messages
  messages <- list(
    list("role" = "system", "content" = "You are a number-crunching assistant. Respond only with numeric output."),
    list("role" = "user", "content" = paste("The document says: ", document)),
    list("role" = "user", "content" = "If the document does not mention the number of members of the union, please respond with 'NA'. If the document does specify the number of members in the union, reply with the number of members.")
  )
  
  # Send the conversation to the GPT-4 API
  response <- openai::create_chat_completion('gpt-3.5-turbo', messages = messages)
  
  # Print the response
  print(response$choices$message.content)
  
  # Return the model's response
  return(response$choices$message.content)
  
}

# Initialize an empty list to store the answers
answers <- list()

# Processing each relevant PDF page in the API to get an answer and storing it in an identifiable variable
for(i in 1:length(pdf_files)){
  # Print out which PDF we're working with
  print(paste("Processing PDF", i, "of", length(pdf_texts)))
  
  # Initialize an empty list to store the answers for this PDF
  answers[[i]] <- list()
  
  # Loop over each relevant page
  for(page in relevant_pages[[i]]){
    # Print out which page we're working with
    print(paste("Processing page", page, "of PDF", i))
    
    # Get the text of the page
    page_text <- pdf_texts[[i]][page]
    
    # Attempt to ask the question and store the answer, if an error occurs wait 20 seconds and retry
    answer <- tryCatch(
      {
        # Attempt to make the API request
        gpt_query(page_text)
      },
      error = function(e){
        # If an error occurs, print the message, wait 20 seconds, then retry the request
        print(paste("Encountered an error:", e$message, "Waiting 20 seconds before retrying."))
        Sys.sleep(20)
        gpt_query(page_text)
      }
    )
    
    # Store the answer
    answers[[i]][[page]] <- answer
  }
}

# Initialize a new list to store the consolidated answers, ensure it has the same length and names as pdf_files
consolidated_answers <- as.list(rep(NA, length(pdf_files)))
names(consolidated_answers) <- pdf_files

# Get a 'consolidated answer' (ie remove NAs and only list unique numerical answers)
for(i in 1:length(answers)){
  # Get the answers for this PDF
  pdf_answers <- answers[[i]]
  
  # Exclude NA or NULL responses
  pdf_answers <- pdf_answers[!is.na(pdf_answers) & !sapply(pdf_answers, is.null)]
  
  # If there's no answer after excluding NA or NULL responses, set the answer to NA
  if(length(pdf_answers) == 0){
    consolidated_answers[[i]] <- NA
  } else {
    # Use the unique function to get the unique answers
    unique_answers <- unique(pdf_answers)
    
    # If there's only one unique answer, use it; otherwise, concatenate the vector of unique answers
    if(length(unique_answers) == 1){
      consolidated_answers[[i]] <- unique_answers[[1]]
    } else {
      consolidated_answers[[i]] <- paste(unique_answers, collapse = ", ")
    }
  }
}



# Create a data frame with the file names (without extensions) and the consolidated answers
answers_df <- data.frame(
  file_name = toupper(sapply(pdf_files, function(x) tools::file_path_sans_ext(basename(x)))),
  data_extracted = unlist(consolidated_answers),
  stringsAsFactors = FALSE
)

## Now save, join to another dataset, etc... enjoy!
                       