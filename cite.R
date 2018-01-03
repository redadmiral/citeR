#!/usr/bin/env Rscript

#Creates Biblatex-Citation from URL, DOI and ISBN
###################### IMPORT LIBRARIES#################################

library(readr)
library(stringr)
library(rcrossref) #library for dois
library(digest)
library(base64enc) #hashing the amazon api
suppressMessages(library(RCurl))

###################### DEFINE FUNCTIONS #################################

remove_tags <- function(string) {
    string <- gsub(pattern = '<meta name=".*?" content="', "", x = string)
    string <- gsub(pattern = '"\\W{0,10}/{0,1}>', "", x = string)
}

#create the api-request for amazon
createRequest <- function(isbn, accesskey, secretkey, associateTag) {

  pb.txt <- Sys.time()
  pb.date <- as.POSIXct(pb.txt, tz = Sys.timezone)
  timestamp <- strtrim(format(pb.date, tz = "GMT", usetz = TRUE, "%Y-%m-%dT%H:%M:%S.000Z"), 24)
  timestamp <- gsub("\\:", "%3A", timestamp)

  getSuffix <- "GET\nwebservices.amazon.com\n/onca/xml\n"
  requestSuffix <- "http://webservices.amazon.com/onca/xml?"

  canonicalString <- paste("AWSAccessKeyId=",
                           accesskey,
                           "&AssociateTag=",
                           associateTag,
                           "&IdType=ISBN&ItemId=",
                           isbn,
                           "&Operation=ItemLookup&ResponseGroup=ItemAttributes&SearchIndex=All&Service=AWSECommerceService&Timestamp=",
                           timestamp,
                           sep = "")

  signature <- base64encode(hmac(key = secretkey,
                                 object = paste(getSuffix, canonicalString, sep = ""),
                                 algo = "sha256",
                                 raw = TRUE))

  signature <- gsub("\\+", "%2B", signature)
  signature <- gsub("\\=", "%3D", signature)

  request <- paste(requestSuffix,
                   canonicalString,
                   "&Signature=",
                   signature,
                   sep = "")
  return(request)
}


################## READ CITATION REFERENCE FROM BASH #############################

cite_me <- commandArgs(trailingOnly=TRUE)

if (substr(cite_me, start = 1, stop = 2) == "10") {
############################# CITATION FROM DOI #################################

  cat(cr_cn(dois = cite_me, format = "bibtex"))

} else if (substr(cite_me, start = 1, stop = 2) == "97") {
############################# CITATION FROM ISBN #################################

  #Login Parameter for Amazon AWS, Access & Secret Key from Affiliate Program
  isbn <- cite_me

  credentials <- read.table("credentials.txt")
  accesskey <- as.character(credentials[[1]][1])
  secretkey <- as.character(credentials[[1]][2])
  associateTag <- as.character(credentials[[1]][3])

  isbn <- gsub("-", "", isbn)
  isbn <- gsub(" ", "", isbn)

  request <- createRequest(isbn, accesskey, secretkey, associateTag)

  xml <- getURL(request)

  author <- gsub("<.*?>", "", str_match(xml, "<Author>.*?<\\/Author>"))
  title <- gsub("<.*?>", "", str_match(xml, "<Title>.*?<\\/Title>"))
  publisher <- gsub("<.*?>", "", str_match(xml, "<Publisher>.*?<\\/Publisher>"))
  year <- str_match(gsub("<.*?>", "", str_match(xml, "<ReleaseDate>.*?<\\/ReleaseDate>")), "\\d{4}")
  shortname <- paste(trimws(tolower(str_match(author, "\\s\\S+$"))), year, sep = "")

  cat(paste('@book{', shortname,
            ',\n   author = {', author,
            '},\n   year = {', year,
            '},\n   publisher = {', publisher,
            '},\n   title = {', title, '}\n}\n',
            sep = ""))
} else {
##################### CITATION FROM URL ################################

article <- getURL(cite_me)
#download.file(article, "article.html", quiet = TRUE)
#article <- read_file("article.html")
#file.remove("article.html")

publish_date <- as.character(str_match(article, pattern = '<meta name="last-modified" content=".*?>'))
if (is.na(publish_date)) {
  publish_date <- "o.J."
} else {
  publish_date <- as.character(str_match(publish_date, pattern = "\\d{4}-\\d{2}-\\d{2}"))
}

author <- as.character(str_match(article, pattern = '<meta name="author" content=".*?>'))
author <- remove_tags(author)
if (is.na(author)) {
    author <- gsub(pattern = "((http[s]?:\\/\\/|)www\\.|)", "", cite_me)
    author <- gsub(pattern = "\\/.*", "", author)
    shortname <- paste(as.character(str_match(author, pattern = "\\w+")),
                       as.character(str_match(publish_date, pattern = "\\d{4}")),
                       sep = "")
} else {
  shortname <- paste(as.character(str_match(author, pattern = " \\w+")),
                     as.character(str_match(publish_date, pattern = "\\d{4}")),
                     sep = "")
}

access_date <- Sys.Date()

title <- as.character(str_match(article, pattern = '<title>.*?</title>'))
title <- gsub(pattern = "</{0,1}title>", replacement = "", x = title )
title <- gsub(pattern = "&nbsp;", replacement = " ", x = title)

shortname <- paste(as.character(str_match(author, pattern = "\\w+")),
                   as.character(str_match(publish_date, pattern = "\\d{4}")),
                   sep = "")
shortname <- tolower(gsub(pattern = " ",replacement = "", x = shortname))

cat(paste('@online{', shortname, ',\n   author={',
          author, '},\n   date = {',
          publish_date, '},\n   urldate = {',
          access_date, '},\n   url = {',
          cite_me, '},\n   title = {',
          title, '}\n}\n',
          sep = ""))
}
