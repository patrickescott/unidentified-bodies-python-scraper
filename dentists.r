# The purpose of this script is to quickly extract information from the NHS England
# site on which dentists are accepting NHS patients based on poximity to a given
# postcode. The Times did this and turned it into a story here:
# https://www.thetimes.co.uk/article/nine-out-of-ten-nhs-dental-practices-in-england-closed-to-new-routine-patients-dm0qjxqx5

# Load our packages (most of these are tidyverse packages)
library(rvest) # for scraping
library(stringr)
library(dplyr)
library(tidyr)

# Define our url here. First we make a base url, then paste a postcode onto the
# end to make a complete url
base <- "https://www.nhs.uk/service-search/find-a-dentist/results/"
url <- paste0(base, "N176AX")

# Use rvest to download the html of our url
x <- read_html(url) # this is an Rvest function

# This is the bit that requires you to do a bit of work in Chrome beforehand.
# In this case I've chosen .results__details to isolate all the information
# associated with one dentist. You can do this by nosing around in the html
# within your browser but the SelectorGadget Chrome extension makes this easier
results <- html_elements(x, ".results__details") %>% html_text()

# Our function above grabs all the html for each dentist in one blob. What we 
# want to do now is go through each of the items of this list and extract specific
# pieces of information, like the name of the dentist.
names <- html_element(results, ".results__name a") %>% html_text()

# Now we know how to isolate names, we can repeat the trick for other bits of info
# and combine this all together in one table
dentists <- data.frame(names = html_element(results, ".results__name a") %>% html_text(),
                       links = html_element(results, ".results__name a") %>% html_attr("href"),
                       headlineInfo = html_element(results, "p:nth-of-type(5)") %>% html_text(),
                       detailedInfo = html_element(results, "ul.nhsuk-u-margin-bottom-2") %>% html_text())

# This was me working out how many possible things could appear in the headlineInfo
# column extracted above
possibleHeadlines <- unique(dentists$headlineInfo)

# Here follows a long chain of data cleaning
dentistsClean <- dentists %>%
  # This first mutate function tidies up our headline info column, making it more concise
  mutate(headlineInfo = case_when(
          headlineInfo == "This dentist is:" ~ "Accepting",
          headlineInfo == "This dentist has not recently given an update on whether they're taking new NHS patients. Contact them for more information" ~ "No recent info",
          headlineInfo == "This dentist is only taking new NHS patients who have been referred" ~ "Referrals only",
          headlineInfo == "This dentist is not taking any new NHS patients at the moment" ~ "Not accepting",
          TRUE ~ headlineInfo)) %>%
  # This mutate call tidies up our detailed info column
  mutate(detailedInfo = trimws(detailedInfo) %>% 
           str_remove_all("  +") %>% 
           str_replace_all("not\r\n+", "not ") %>%
           str_remove_all("\n") %>%
           str_replace_all("\r+", "_")) %>%
  # We can then separate our tidied detailed info into the three categories in which
  # dentists might be accepting NHS patients
  separate(detailedInfo, into = c("Children", "Adults", "FreeDental"), sep = "_") %>%
  # Final bit of tidying to make these columns a bit more scannable with Yes/No
  mutate(Children = ifelse(is.na(Children), NA, ifelse(str_detect(Children, "not"), "No", "Yes")),
         Adults = ifelse(is.na(Adults), NA, ifelse(str_detect(Adults, "not"), "No", "Yes")),
         FreeDental = ifelse(is.na(FreeDental), NA, ifelse(str_detect(FreeDental, "not"), "No", "Yes")))

# Write data out to a csv
write.csv(dentistsClean, "dentists.csv", row.names = F)      
