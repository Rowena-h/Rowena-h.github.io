setwd("D:/Documents/GitHub/Rowena-h.github.io/")

library(scholar)
library(tidyverse)
library(glue)
library(rcrossref)
library(usethis)
library(listviewer)

# escape some special chars, german umlauts, ...
char2html <- function(x){
  dictionary <- data.frame(
    symbol = c("ä", "á", "ö", "ü", "Ä", "Ö", "Ü", "ß", "Z"),
    html = c("&auml;", "&aacute;", "&ouml;", "&uuml;","&Auml;",
             "&Ouml;", "&Uuml;", "&szlig;", "&#381;"))
  for(i in 1:dim(dictionary)[1]){
    x <- gsub(dictionary$symbol[i], dictionary$html[i], x)
  }
  x
}

# my google scholar user id from my profile url
scholar.id <- "5ibFtocAAAAJ"

# pull from google
html_1 <- get_publications(scholar.id)

html_1$doi <- NA

for (i in 1:length(html_1$title)) {
  
  cr.df <- cr_works(query=html_1$title[i])$data
  
  cr.df$title <- gsub("<i>|</i>|\n", "", cr.df$title)
  
  idx <- na.omit(match(str_to_lower(html_1$title[i]), str_to_lower(cr.df$title)))
  
  if (length(idx) == 1) {
    
    html_1$doi[i] <- cr.df$doi[idx]
    
  }
  
}

# convert to htlm table - the ugly way ;)
html_2 <- html_1 %>%
  as_tibble %>% arrange(desc(year)) %>%
  mutate(
    author=str_replace_all(author, "([A-Z]) ([A-Z]) ", "\\1\\2 "),
    author=str_replace_all(author, ", \\.\\.\\.", " et al."),
    author=str_replace_all(author, "R Hill", "<b>R Hill</b>")
  ) %>% split(.$year) %>%
  map(function(x){
    x <- x %>%
      glue_data('<tr>
      <td width="10%">
      <a href="https://plu.mx/plum/a/?doi={doi}" data-popup="right" data-size="large" class="plumx-plum-print-popup" data-site="plum" data-hide-when-empty="true">{title}</a>
      </td>
      <td width="10%">
      <div data-badge-popover="right" data-badge-type="donut" data-doi="{doi}" data-hide-no-mentions="true" class="altmetric-embed"></div>
      </td>
      <td width="70%">{author} ({year}) <a href="https://scholar.google.com/scholar?oi=bibs&cluster={cid}&btnI=1&hl=en">{title}</a>, {journal} {number}
      </td>
      <td width="10%">{cites}</td>
      </tr>') %>%
      str_replace_all("(, )+</p>", "</p>") %>%
      char2html()
    x <- c('<table class="publication-table" border="10px solid blue" cellspacing="0" cellpadding="6" rules="", frame="">
    <tbody>
    <tr>
    <th></th>
    <th></th>
    <th></th>
    <th>Google scholar citations</th>
    </tr>',
    x,
    '</tbody>
    </table>')
    return(x);
  }) %>% rev

html_3 <- map2(names(html_2) %>% paste0("<h3>", ., "</h3>"), html_2, c) %>% unlist

html_4 <- c(
  paste0('<body>
  <script type="text/javascript" src="//cdn.plu.mx/widget-popup.js"></script>
  <script type="text/javascript" src="https://d1bxh8uas1mnw7.cloudfront.net/assets/embed.js"></script>
  <p style="text-align: right; margin-top: 10px;">
  <small>Last updated ', format(Sys.Date(), format="%B %d, %Y"), ' automatically from <a href="https://scholar.google.com/citations?hl=en&user=5ibFtocAAAAJ">Google Scholar</a> &ndash; adapted from <a href="https://thackl.github.io/automatically-update-publications-with-R-scholar">this script</a>
  </small>
  </p>'),
  html_3,
  '</body>')

# write the html list to a file
writeLines(html_4, "publications.html")
