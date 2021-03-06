# Milestone Report for Coursera Data Science Specialization NLP Capstone Project

### Background
In this capstone we will be applying data science in the area of natural language processing. We'll build a model that predicts the next word one would most likely need during texting. This projects uses the files named LOCALE.blogs.txt where LOCALE is the each of the four locales en_US, de_DE, ru_RU and fi_FI. The data is from a corpus called HC Corpora (www.corpora.heliohost.org). See the readme file at http://www.corpora.heliohost.org/aboutcorpus.html for details on the corpora available. The files have been language filtered but may still contain some foreign text. Concretely, we'll be using the en_US locale files from three different sources: blogs, news and twitters.

### Data Pre-processing
In order to process the large amount of text data, we'll be using the following packages in R: 
1) `tm` and `qdapRegex` for data loading and pre-processing
2) `RWeka` for tokenization
We'll also need `ggplot2` and `wordcloud` to visualize our findings on our n-gram tokenizations.


```r
## load requied packages
libs <- c("tm", "ggplot2", "RWeka", "wordcloud", "dplyr", "qdapRegex", "RColorBrewer", "grid", "gridExtra")
suppressMessages(lapply(libs, library, character.only = TRUE))
```


```r
## load and sample data 
en_US.corpus <- Corpus(DirSource("en_US", encoding = "UTF-8"), readerControl = list(reader = readPlain, language = "en", load = TRUE))
```

After loading the corpus, we can perform some basic size count and line count:

en_US.blogs.txt: 248.5 Mb, 899288 lines

en_US.news.txt: 249.6 Mb, 1010242 lines

en_US.twitter.txt: 301.4 Mb, 2360148 lines

For efficient and fast prototype model building, one only needs a portion of these large a mount of data. In this case, we would be sampling the original corpus and take out `1 %` as the training data. The training data set will be written to a separate file for later convenient processing.  


```r
# only take 1% of the data for fast model building
set.seed(2)
sampleCorpus <- function(corpus.element) {
        textVector <- corpus.element$content
        n <- length(textVector)
        inTrain <- sample(1:n, n*0.01)
        return(inTrain)
}
text.name <- gsub("^en_US.|.txt$", "", names(en_US.corpus)) 
lapply(seq_along(en_US.corpus), function(i) {
        inTrain <- sampleCorpus(en_US.corpus[[i]])
        text.train <- en_US.corpus[[i]]$content[inTrain]
        text.test <- en_US.corpus[[i]]$content[-inTrain]
        # sampled data stored in train folder
        write.table(text.train, paste0("./train/train.", text.name[i], ".txt"), sep = "\n", row.names = FALSE, col.names = FALSE, quote = FALSE)
        # unused data stored in test folder
        write.table(text.test, paste0("./test/test.", text.name[i], ".txt"), sep = "\n", row.names = FALSE, col.names = FALSE, quote = FALSE)
})
rm(en_US.corpus)
```

### Training Corpus Loading and Cleaning
After we sampled the training corpus, we'll load it and perform corpus cleaning before we tokenize it. We'll need to clean the following things: 1) punctuation, 2) white space, 3) profane words, 4) urls, emoticons and hash tags. The information gain on these symbols are fairly small and will not contribute to build our model. One important note: we will NOT remove stop words since we're not mining the meaning of these data but to predict what the next word a text typer will need most.


```r
# load training data from ./train directory
corpus.train <- Corpus(DirSource("train", encoding = "UTF-8"), readerControl = list(reader = readPlain, language = "en", load = TRUE))
## clean data
cleanCorpus <- function(corpus) {
        # profane word list from http://www.cs.cmu.edu/~biglou/resources/bad-words.txt
        bad_words <- readLines("bad-words.txt")
        tm_map(corpus, removePunctuation) %>%
        tm_map(stripWhitespace) %>%
        tm_map(tolower) %>%
        tm_map(rm_url) %>%
        tm_map(rm_emoticon) %>%
        tm_map(rm_hash) %>%
        tm_map(PlainTextDocument) %>%
        tm_map(removeWords, bad_words)
}
corpus.train <- cleanCorpus(corpus.train)
```

### Tokenization, Term Document Matrix and N-grams
After cleaning, the corpus is ready for tokenization. We'll be using `RWeka::NGramTokenizer` for this task. for computer performance issue, only uni-gram, bi-gram and tri-gram term document matrices will be generated.


```r
## construct n-gram term doc matrix and perform word counting
options(mc.cores = 1) # to make NGramTokenizer work with parallel::mclapply
# Tokenization on corpus
uniGram <- function(x) NGramTokenizer(x, Weka_control(min = 1, max = 1))
biGram <- function(x) NGramTokenizer(x, Weka_control(min = 2, max = 2))
triGram <- function(x) NGramTokenizer(x, Weka_control(min = 3, max = 3))
# generate term doc matrix
unigram.tdm <- TermDocumentMatrix(corpus.train, control = list(tokenize = uniGram))
bigram.tdm <- TermDocumentMatrix(corpus.train, control = list(tokenize = biGram))
trigram.tdm <- TermDocumentMatrix(corpus.train, control = list(tokenize = triGram))
# n-gram frequency count and sort, return top count in a data frame
ngramFreq <- function(tdm) {
        tmp <- removeSparseTerms(tdm, 0.5) %>% as.matrix %>% rowSums %>% sort(decreasing = TRUE)
        tmp <- data.frame(words = factor(attr(tmp, "names"), level = attr(tmp, "names")), count = tmp, row.names = NULL)
        head(tmp, 10)
}
ngram.words.freq <- lapply(list(unigram.tdm, bigram.tdm, trigram.tdm), ngramFreq)
```


### Statistics of the N-grams
In the previous step, we get our top 10 list of the uni-gram, bi-gram and tri-gram terms. Let's take a look at them and find out what they are. For aesthetic reason, we'll also plot a wordcloud to demonstrate them.


```r
# generate bar plot of 1-, 2- and 3- grams.
fill.color <- c("black", "salmon", "seagreen")
bar.plot <- lapply(seq_along(ngram.words.freq), function(i) ggplot(data = ngram.words.freq[[i]], aes(x = words, y = count)) + geom_bar(stat = "identity", fill = fill.color[i]) + labs(x = "", title = paste0(i, "-gram")) + theme(axis.text.x = element_text(size = 10, angle = 90, hjust = 1, vjust = 0.5)))
grid.arrange(bar.plot[[1]], bar.plot[[2]], bar.plot[[3]], ncol = 3)
```

![](milesone_files/figure-html/unnamed-chunk-6-1.png) 

```r
#generate wordcloud for 1-, 2- and 3- grams
par(mfrow = c(1, 3))
par(mar = c(0.5, 0.5, 0.5, 0.5))
nullvalue <- lapply(ngram.words.freq, function(x) wordcloud(x$words, x$count, scale = c(5, 0.3), max.words= 50, random.order = FALSE, rot.per = 0.3, use.r.layout = FALSE, colors = brewer.pal(8, "Set2")))
```

![](milesone_files/figure-html/unnamed-chunk-6-2.png) 

### Summary
From the bar plots and wordcloud plots of the top 20 uni-gram, bi-gram and tri-gram list, we notice stop words are actually taking the lead. In general, they don't provide too much information about what people are writing/twitting. But they are the words that people do type the most and it would be convenient to build a prediction model to save people's typing time with these findings.

### What's Next?
The next step is to look for a good prediction model built on our n-gram term document matrices and optimize the efficiency on next word prediction.
