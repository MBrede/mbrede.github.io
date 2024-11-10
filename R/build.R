# An optional custom script to run before Hugo builds your site.
# You can delete it if you do not need it.
library(tidyverse)

build_iframe <- function(link = '',
                         height = "500",
                         width = '90%') {
  cat(
    glue::glue(
      '<iframe width="{width}" height="{height}" name="iframe" src="{link}"></iframe>'
    )
  )
  cat(glue::glue('Sollte die Darstellung nicht richtig funktionieren, kann das Skript/die App auch [hier]({link}) gefunden werden.'))
}

if(!exists('run_script')){
  orcid = "0000-0001-7134-0553"
  
  pubs <-
    jsonlite::read_json(
      glue::glue(
        'https://api.crossref.org/works?filter=orcid:{orcid}&mailto=contact@max-bre.de'
      )
    )
  
  pubs <- pubs$message$items %>%
    map_dfr(
      ~ tibble(
        title = first(.$title),
        authors = map_chr(.$author, ~ paste(.$given, .$family)) %>%
          str_replace('Max Brede', 'admin') %>%
          str_c(collapse = '\n- '),
        date = str_c(unlist(.$published), collapse = '-'),
        file_name = str_to_lower(str_c(
          unlist(.$published)[1],
          first(.$author)$family,
          paste0(unlist(str_split(title, ' '))[1:3], collapse = ''),
          sep = '_'
        )),
        doi = .$DOI,
        publication_types = case_when(.$type == "journal-article" ~ "2",
                                      T ~ "1"),
        publication = first(.$`container-title`),
        publication_short = first(.$`short-container-title`),
        abstract = .$abstract
      )
    ) %>% 
    mutate(across(everything(), ~str_remove_all(replace_na(., ''), '<.[^>]+>')))
  
  existing <- list.files('content/publication/')
  proto <- read_file('R/proto_article.md')
  
  for(i in seq_len(nrow(pubs))){
    if(!(str_c(pubs$file_name[i], '.md') %in% existing)){
      out <- glue::glue(proto)
      write_file(out, str_c('content/publication/',pubs$file_name[i], '.md'))
    }
  }
}
