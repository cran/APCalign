#' Load taxonomic resources from either stable or current versions of APC and APNI
#'
#' Loads taxonomic resources into the global environment. This function accesses taxonomic data from a dataset using the provided version number or the default version. The loaded data contains two lists: APC and APNI, which contain taxonomic information about plant species in Australia. The function creates several tibbles by filtering and selecting data from the loaded lists.
#'
#' @param stable_or_current_data Type of dataset to access. The default is "stable", which loads the
#'   dataset from a github archived file. If set to "current", the dataset will be loaded from
#'   a URL which is the cutting edge version, but this may change at any time without notice.
#' @param version The version number of the dataset to use. Defaults to the default version.
#'
#' @param reload A logical indicating whether to reload the dataset from the data source. Defaults to FALSE.
#'
#' @return The taxonomic resources data loaded into the global environment.
#' @export
#'
#' @examples
#' \donttest{load_taxonomic_resources(stable_or_current_data="stable",version="0.0.2.9000")}
#'
#' @importFrom dplyr filter select mutate distinct arrange
#' @importFrom crayon red

load_taxonomic_resources <-
  function(stable_or_current_data = "stable",
           version = default_version(),
           reload = FALSE) {
    message("Loading resources...", appendLF = FALSE)
    on.exit(message("...done"))
    
    taxonomic_resources <- dataset_access_function(
      version = version,
      path = tools::R_user_dir("APCalign"),
      type = stable_or_current_data
    )
      
    if(is.null(taxonomic_resources)) {
      return(NULL)
    }
    
    # Give list names
    names(taxonomic_resources) <- c("APC", "APNI")
    
    ## todo :review this, why zzz
    ### Note: Use `zzzz zzzz` because the fuzzy matching algorithm can't handles NA's
    zzz <- "zzzz zzzz"
    
    taxonomic_resources$APC <- taxonomic_resources$APC %>%
      rename(
        taxon_ID = .data$taxonID,
        taxon_rank = .data$taxonRank,
        name_type = .data$nameType,
        taxonomic_status = .data$taxonomicStatus,
        pro_parte = .data$proParte,
        scientific_name = .data$scientificName,
        scientific_name_ID = .data$scientificNameID,
        accepted_name_usage_ID = .data$acceptedNameUsageID,
        accepted_name_usage = .data$acceptedNameUsage,
        canonical_name = .data$canonicalName,
        scientific_name_authorship = .data$scientificNameAuthorship,
        taxon_rank_sort_order = .data$taxonRankSortOrder,
        taxon_remarks = .data$taxonRemarks,
        taxon_distribution = .data$taxonDistribution,
        higher_classification = .data$higherClassification,
        nomenclatural_code = .data$nomenclaturalCode,
        dataset_name = .data$datasetName
      ) %>%
      mutate(
        genus = extract_genus(canonical_name),
        taxon_rank = stringr::str_to_lower(taxon_rank),
        taxon_rank = stringr::str_replace(taxon_rank, "regnum", "kingdom"),
        taxon_rank = stringr::str_replace(taxon_rank, "classis", "class"),
        taxon_rank = stringr::str_replace(taxon_rank, "ordo", "order"),
        taxon_rank = stringr::str_replace(taxon_rank, "familia", "family"),
        taxon_rank = stringr::str_replace(taxon_rank, "varietas", "variety"),
        taxon_rank = stringr::str_replace(taxon_rank, "forma", "form"),
        taxon_rank = stringr::str_replace(taxon_rank, "sectio", "section")
      )
    
    taxonomic_resources$APNI <- taxonomic_resources$APNI %>%
      rename(
        name_type = .data$nameType,
        taxonomic_status = .data$taxonomicStatus,
        taxon_rank = .data$taxonRank,
        scientific_name = .data$scientificName,
        scientific_name_ID = .data$scientificNameID,
        canonical_name = .data$canonicalName,
        scientific_name_authorship = .data$scientificNameAuthorship,
        taxon_rank_sort_order = .data$taxonRankSortOrder,
        nomenclatural_code = .data$nomenclaturalCode,
        dataset_name = .data$datasetName,
        name_element = .data$nameElement
      )  %>%
      mutate(
        genus = extract_genus(canonical_name),
        taxon_rank = stringr::str_to_lower(taxon_rank),
        taxon_rank = stringr::str_replace(taxon_rank, "regnum", "kingdom"),
        taxon_rank = stringr::str_replace(taxon_rank, "classis", "class"),
        taxon_rank = stringr::str_replace(taxon_rank, "ordo", "order"),
        taxon_rank = stringr::str_replace(taxon_rank, "familia", "family"),
        taxon_rank = stringr::str_replace(taxon_rank, "varietas", "variety"),
        taxon_rank = stringr::str_replace(taxon_rank, "forma", "form"),
        taxon_rank = stringr::str_replace(taxon_rank, "sectio", "section")
      )
    
    APC_tmp <-
      taxonomic_resources$APC %>%
      dplyr::arrange(taxonomic_status) %>%
      dplyr::filter(taxon_rank %in% c("subspecies", "species", "form", "variety")) %>%
      dplyr::filter(!stringr::str_detect(canonical_name, "[:space:]sp\\.$")) %>%
      dplyr::select(
        canonical_name,
        scientific_name,
        taxonomic_status,
        taxon_ID,
        scientific_name_ID,
        accepted_name_usage_ID,
        name_type,
        taxon_rank,
        genus
      ) %>%
      dplyr::mutate(
        # strip_names removes punctuation and filler words associated with infraspecific taxa (subsp, var, f, ser)
        stripped_canonical = strip_names(canonical_name),
        ## strip_names2 removes punctuation, filler words associated with infraspecific taxa (subsp, var, f, ser), and filler words associated with species name cases (x, sp)
        ## strip_names2 is essential for the matches involving 2 or 3 words, since you want those words to not count filler words
        stripped_canonical2 = strip_names_2(canonical_name),
        stripped_scientific = strip_names(scientific_name),
        binomial = ifelse(
          taxon_rank == "species",
          stringr::word(stripped_canonical2, start = 1, end = 2),
          zzz
        ),
        binomial = ifelse(is.na(binomial), zzz, binomial),
        binomial = base::replace(binomial, duplicated(binomial), zzz),
        genus = extract_genus(stripped_canonical),
        trinomial = stringr::word(stripped_canonical2, start = 1, end = 3),
        trinomial = ifelse(is.na(trinomial), zzz, trinomial),
        trinomial = base::replace(trinomial, duplicated(trinomial), zzz),
      ) %>%
      dplyr::distinct()
    
    taxonomic_resources[["APC list (accepted)"]] <-
      APC_tmp %>%
      dplyr::filter(taxonomic_status == "accepted") %>%
      dplyr::mutate(taxonomic_dataset = "APC")
    
    taxonomic_resources[["APC list (known names)"]] <-
      APC_tmp %>%
      dplyr::filter(taxonomic_status != "accepted") %>%
      dplyr::mutate(taxonomic_dataset = "APC")
    
    # Repeated from above - bionomial, tronomials etc
    taxonomic_resources[["APNI names"]] <-
      taxonomic_resources$APNI %>%
      dplyr::filter(name_element != "sp.") %>%
      dplyr::filter(!canonical_name %in% APC_tmp$canonical_name) %>%
      dplyr::select(canonical_name,
                    scientific_name,
                    scientific_name_ID,
                    name_type,
                    taxon_rank) %>%
      dplyr::filter(taxon_rank %in% c("series", "subspecies", "species", "form", "variety")) %>%
      dplyr::mutate(
        taxonomic_status = "unplaced for APC",
        stripped_canonical = strip_names(canonical_name),
        stripped_canonical2 = strip_names_2(canonical_name),
        stripped_scientific = strip_names(scientific_name),
        binomial = ifelse(
          taxon_rank == "species",
          stringr::word(stripped_canonical2, start = 1, end = 2),
          "zzzz zzzz"
        ),
        binomial = ifelse(is.na(binomial), "zzzz zzzz", binomial),
        trinomial = stringr::word(stripped_canonical2, start = 1, end = 3),
        trinomial = ifelse(is.na(trinomial), "zzzz zzzz", trinomial),
        trinomial = base::replace(trinomial, duplicated(trinomial), "zzzz zzzz"),
        genus = extract_genus(stripped_canonical),
        taxonomic_dataset = "APNI"
      ) %>%
      dplyr::distinct() %>%
      dplyr::arrange(canonical_name)
    
    taxonomic_resources[["genera_accepted"]] <-
      taxonomic_resources$APC %>%
      dplyr::select(
        canonical_name,
        accepted_name_usage,
        accepted_name_usage_ID,
        scientific_name,
        taxonomic_status,
        taxon_ID,
        scientific_name_ID,
        name_type,
        taxon_rank,
        genus
      ) %>%
      dplyr::filter(taxon_rank %in% c("genus"), taxonomic_status == "accepted") %>%
      dplyr::mutate(taxonomic_dataset = "APC")
    
    taxonomic_resources[["genera_known"]] <-
      taxonomic_resources$APC %>%
      dplyr::select(
        canonical_name,
        accepted_name_usage,
        accepted_name_usage_ID,
        scientific_name,
        taxonomic_status,
        taxon_ID,
        scientific_name_ID,
        name_type,
        taxon_rank,
        genus
      ) %>%
      dplyr::filter(taxon_rank %in% c("genus")) %>%
      dplyr::filter(!canonical_name %in% taxonomic_resources$genera_accepted$canonical_name) %>%
      dplyr::mutate(taxonomic_dataset = "APC") %>%
      dplyr::distinct(canonical_name, .keep_all = TRUE)
    
    taxonomic_resources[["genera_APNI"]] <-
      taxonomic_resources$APNI %>%
      dplyr::select(
        canonical_name,
        scientific_name,
        taxonomic_status,
        scientific_name_ID,
        name_type,
        taxon_rank,
        genus
      ) %>%
      dplyr::filter(taxon_rank %in% c("genus")) %>%
      dplyr::filter(!canonical_name %in% taxonomic_resources$APC$canonical_name) %>%
      dplyr::mutate(taxonomic_dataset = "APNI") %>%
      dplyr::distinct(canonical_name, .keep_all = TRUE)
    
    taxonomic_resources[["genera_all"]] <-
      dplyr::bind_rows(
        taxonomic_resources$genera_accepted,
        taxonomic_resources$genera_known,
        taxonomic_resources$genera_APNI
      ) %>%
      dplyr::mutate(
        cleaned_name = stringr::word(accepted_name_usage, 1),
        cleaned_name = ifelse(is.na(cleaned_name), canonical_name, cleaned_name)
      ) %>%
      dplyr::distinct(cleaned_name, canonical_name, scientific_name, .keep_all = TRUE)
    
    taxonomic_resources[["family_accepted"]] <-
      taxonomic_resources$APC %>%
      dplyr::filter(taxon_rank %in% c("family"), taxonomic_status == "accepted")
    
    return(taxonomic_resources)
  }

##' Access Australian Plant Census Dataset
##'
##' This function provides access to the Australian Plant Census dataset containing information
##' about various species. The dataset can be loaded from a github for a stable file or from a URL for the most cutting-edge, but not stable version.
##'
##' @param version Version number. The default is NULL, which will load the most recent
##'   version of the dataset on your computer or the most recent version known
##'   to the package if you have never downloaded the data before. With
##'   `plant_lookup_del`, specifying `version=NULL` will delete \emph{all} data sets.
##' @param path Path to store the data at. If not given, `datastorr` will use `rappdirs`
##'   to find the best place to put persistent application data on your system. You can
##'   delete the persistent data at any time by running `mydata_del(NULL)` (or
##'   `mydata_del(NULL, path)` if you use a different path).
##' @param type Type of dataset to access. The default is "stable", which loads the
##'   dataset from a github archived file. If set to "current", the dataset will be loaded from
##'   a URL which is the cutting edge version, but this may change at any time without notice.
##'
##' @examples
##'
##'
##' # Load the a stable version of the dataset
##' dataset_access_function(version="0.0.2.9000",type = "stable")
##'
##' @noRd
dataset_access_function <-
  function(version = default_version(),
           path = tools::R_user_dir("APCalign"),
           type = "stable") {
    
    # Check if there is internet connection
    ## Dummy variable to allow testing of network
    network <- as.logical(Sys.getenv("NETWORK_UP", unset = TRUE)) 
    
    
    if (!curl::has_internet() | !network) { # Simulate if network is down
      message("No internet connection, please retry with stable connection (dataset_access_function)")
      return(invisible(NULL))
    } 
    
    # Download from Github Release
    if (type == "stable") {
      return(dataset_get(version, path))
    }
    
    # Download from NSL
    if (type == "current") {
      tryCatch({
        APC <- readr::read_csv(
          "https://biodiversity.org.au/nsl/services/export/taxonCsv",
          n_max = 110000,
          col_types =
            readr::cols(
              .default = readr::col_character(),
              proParte = readr::col_logical(),
              taxonRankSortOrder = readr::col_double(),
              created = readr::col_datetime(format = ""),
              modified = readr::col_datetime(format = "")
            )
        )
        
        APNI <-
          readr::read_csv(
            "https://biodiversity.org.au/nsl/services/export/namesCsv",
            n_max = 140000,
            col_types =
              readr::cols(
                .default = readr::col_character(),
                autonym = readr::col_logical(),
                hybrid = readr::col_logical(),
                cultivar = readr::col_logical(),
                formula = readr::col_logical(),
                scientific = readr::col_logical(),
                nomInval = readr::col_logical(),
                nomIlleg = readr::col_logical(),
                namePublishedInYear = readr::col_double(),
                taxonRankSortOrder = readr::col_double(),
                created = readr::col_datetime(format = ""),
                modified = readr::col_datetime(format = "")
              )
          )

        on.exit(
          close( "https://biodiversity.org.au/nsl/services/export/taxonCsv"),
          close( "https://biodiversity.org.au/nsl/services/export/namesCsv")
                )
      }, error = function(e) rlang::abort("Taxonomic resources not currently available, try again later")
      )
    }
    
    # Put lists together
    current_list <- list(APC, APNI)
    names(current_list) <- c("APC", "APNI")
    return(current_list)
  }

#' Get the default version for stable data
#'
#' This function returns the default version for stable data, which is used when no
#' version is specified.
#'
#' @return A character string representing the default version for stable data.
#'
#'
#' @noRd

default_version <- function() {
  # Check if there is internet connection
  ## Dummy variable to allow testing of network
  network <- as.logical(Sys.getenv("NETWORK_UP", unset = TRUE)) 
  
  if (!curl::has_internet() | !network) { # Simulate if network is down
    message("No internet connection, please retry with stable connection (default_version)")
    return(invisible(NULL))
  } else {
    
    # Get all the releases
    url <-
      paste0(
        "https://api.github.com/repos/",
        "traitecoevo",
        "/",
        "APCalign",
        "/releases"
      )
    
    response <- httr::GET(url)
  
  if(httr::http_error(response)){
    message("API currently down, try again later")
  } 
  release_data <- httr::content(response, "text") |> jsonlite::fromJSON()
  
  # Pull out versions
  versions <- unique(release_data$tag_name)
  
  # Exclude Taxonomy: first upload
  dplyr::first(versions)
  }
}

#' @noRd
dataset_get <- function(version = default_version(),
                        path = tools::R_user_dir("APCalign")) {
  
  # Check if there is internet connection
  ## Dummy variable to allow testing of network
  network <- as.logical(Sys.getenv("NETWORK_UP", unset = TRUE)) 
  
  if (!curl::has_internet() | !network) { # Simulate if network is down
    message("No internet connection, please retry with stable connection (dataset_get)")
    return(invisible(NULL))
  } else{
  
  #APC
  apc.url <-
    paste0(
      "https://github.com/traitecoevo/APCalign/releases/download/",
      version,
      "/apc.parquet"
    )
  
  # APNI
  apni.url <-
    paste0(
      "https://github.com/traitecoevo/APCalign/releases/download/",
      version,
      "/apni.parquet"
    )
  
  
  download_and_read_parquet <- function(url, path_to_file) {
    tryCatch({
      utils::download.file(url, path_to_file, mode = "wb")
      message("File downloaded successfully.")
      return(arrow::read_parquet(path_to_file))
    }, error = function(e) {
      message(
        "Internet or server may be down; error in downloading or reading the file: ",
        e$message
      )
      return(NULL)
    })
  }
  
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
  
  path_to_apc <- file.path(path, paste0("apc", version, ".parquet"))
  path_to_apni <- file.path(path, paste0("apni", version, ".parquet"))
  
  APC <- if (!file.exists(path_to_apc)) {
    download_and_read_parquet(apc.url, path_to_apc)
  } else {
    arrow::read_parquet(path_to_apc)
  }
  
  APNI <- if (!file.exists(path_to_apni)) {
    download_and_read_parquet(apni.url, path_to_apni)
  } else {
    arrow::read_parquet(path_to_apni)
  }

  #combine
  current_list <- list(APC, APNI)
  names(current_list) <- c("APC", "APNI")
  return(current_list)
  
  }
}
