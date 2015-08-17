library(tm)

options(stringsAsFactors = FALSE)
unigram <- read.csv("uniGram1.txt", sep = "\t")
bigram <- read.csv("biGram1.txt", sep = "\t")
trigram <- read.csv("triGram1.txt", sep = "\t")
fourgram <- read.csv("fourGram1.txt", sep = "\t")

## ngram search function
## return the most probable words
predictWord <- function(string, ngram, n) {
        patt <- paste0("^", string, " ")
        index <- grep(patt, ngram$words)
        if (length(index) == 0) return (NULL)
        else {
                tmp <- sapply(ngram[index[1:3], 1], function(x) strsplit(x, " ")[[1]][n])
                return(unname(tmp))
        }
}

## next word prediction function
## predict the next word based on the input condition
predictNext <- function(inputString) {
        if (inputString == "" | inputString == " " | is.null(inputString)) 
                return (c("","",""))
        
        inputString <- removePunctuation(inputString)
        inputString <- tolower(inputString)
        inputVec <- strsplit(inputString, " ")[[1]]
        inputLength <- length(inputVec)
        nextWord <- NULL
        
        # predict with fourgram
        if (inputLength >= 3) {
                string <- paste(inputVec[(inputLength - 2) : inputLength], collapse = " ")
                nextWord <- predictWord(string, fourgram, 4)
        }
        
        # predict with trigram
        if (inputLength == 2 | is.null(nextWord)) {
                string <- paste(inputVec[(inputLength - 1) : inputLength], collapse = " ")
                nextWord <- predictWord(string, trigram, 3)
        }
        # predict with bigram
        if (inputLength == 1 | is.null(nextWord)) {
                string <- inputVec[inputLength]
                nextWord <- predictWord(string, bigram, 2)
        }
        # OK... can't find anything... just return unigram
        if (is.null(nextWord)) nextWord <- unigram$words[1:3]
        
        return(nextWord)
}
