library(scholar)
library(tidyverse)
library(glue)
library(rcrossref)
library(usethis)
library(listviewer)

#Function to convert special characters for HTML
char2html <- function(x){
  dictionary <- data.frame(
    symbol=c("ä", "á", "ö", "ü", "Ä", "Ö", "Ü", "ß", "Ž"),
    html=c("&auml;", "&aacute;", "&ouml;", "&uuml;","&Auml;",
           "&Ouml;", "&Uuml;", "&szlig;", "&#381;"))
  for(i in 1:dim(dictionary)[1]){
    x <- gsub(dictionary$symbol[i], dictionary$html[i], x)
  }
  x
}

#Google Scholar ID
scholar.id <- "5ibFtocAAAAJ"

#Pull publications from Google Scholar
html_1 <- get_publications(scholar.id)

#Add DOI
html_1$doi <- NA

for (i in 1:length(html_1$title)) {
  
  cr.df <- cr_works(query=html_1$title[i])$data
  
  cr.df$title <- gsub("<i>|</i>|\n", "", cr.df$title)
  
  idx <- na.omit(match(str_to_lower(html_1$title[i]), str_to_lower(cr.df$title)))
  
  if (length(idx) == 1) {
    
    html_1$doi[i] <- cr.df$doi[idx]
    
  }
  
}

#Format as HTML table with metric badges
html_2 <- html_1 %>%
  as_tibble %>%
  arrange(desc(year)) %>%
  mutate(author=str_replace_all(author, "([A-Z]) ([A-Z]) ", "\\1\\2 "),
         author=str_replace_all(author, ", \\.\\.\\.", " et al."),
         author=str_replace_all(author, "R Hill", "<b>R Hill</b>"),
         title=str_replace(title,
                           "Using collections to explore the evolution of plant associated lifestyles in the Ascomycota",
                           "Using collections to explore the evolution of plant associated lifestyles in the <i>Ascomycota</i> <b>(PhD thesis)</b>")) %>% 
  split(.$year) %>%
  map(function(x){
    x <- x %>%
      glue_data('
      <tr>
      <td width="10%">
      <a href="https://plu.mx/plum/a/?doi={doi}" data-popup="right" data-size="large" class="plumx-plum-print-popup" data-site="plum" data-hide-when-empty="true" target="_blank"></a>
      </td>
      <td width="10%">
      <div data-badge-popover="right" data-badge-type="donut" data-doi="{doi}" data-hide-no-mentions="true" class="altmetric-embed"></div>
      </td>
      <td width="70%">{author} ({year}) <a href="https://scholar.google.com/scholar?oi=bibs&cluster={cid}&btnI=1&hl=en" target="_blank">{title}</a>. <i>{journal}</i> {number}
      </td>
      <td style="width:10%; text-align: center">{cites}</td>
      </tr>') %>%
      str_replace_all("(, )+</p>", "</p>") %>%
      char2html()
    return(x);
  }) %>% 
  rev

#Add table rows for year groupings
html_3 <- map2(names(html_2) %>%
                 paste0('<tr><td width="10%"><h3>', ., '</h3></td><td width="10%"></td><td width="10%"></td><td width="10%"></td></tr>'), html_2, c) %>%
  unlist

#Add page preamble and table wrapping
html_4 <- c(
  paste0('<body>
  <script type="text/javascript" src="//cdn.plu.mx/widget-popup.js"></script>
  <script type="text/javascript" src="https://d1bxh8uas1mnw7.cloudfront.net/assets/embed.js"></script>
  <p style="margin-top: 10px">
  <small>Last updated ', format(Sys.Date(), format="%B %d, %Y"), ' automatically from <a href="https://scholar.google.com/citations?hl=en&user=5ibFtocAAAAJ" target="_blank">Google Scholar</a> &ndash; adapted from <a href="https://thackl.github.io/automatically-update-publications-with-R-scholar" target="_blank">this script</a></small>
  </p>
  <table>
  <tbody>
  <tr>
  <th></th>
  <th></th>
  <th></th>
  <th style="text-align: center"><small>Citations</small></th>
  </tr>'),
  html_3,
  '</tbody>
  </table>
  </body>')

#Remove nonexistent metric badges
html_4 <- sub('<div data-badge-popover="right" data-badge-type="donut" data-doi="NA" data-hide-no-mentions="true" class="altmetric-embed"></div>', '', html_4)
html_4 <- sub('<a href="https://plu.mx/plum/a/?doi=NA" data-popup="right" data-size="large" class="plumx-plum-print-popup" data-site="plum" data-hide-when-empty="true" target="_blank"></a>', '', html_4)


#Write to file
writeLines(html_4, file("publications.html", encoding="UTF-8"))
