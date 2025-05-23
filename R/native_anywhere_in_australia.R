#' @title Native anywhere in Australia
#' 
#' @description
#' This function checks which species from a list is thought to be native anywhere in 
#' Australia according to the APC. 
#'
#' @details 
#' Important caveats: 
#' -  This function will not detect within-Australia introductions, 
#' e.g. if a species is from Western Australia and is invasive on the east coast.
#' -  Very recent invasions are unlikely to be documented yet in APC. 
#' -  Ideally check spelling and taxonomy updates first via 
#' \link{create_taxonomic_update_lookup}.
#' -  For the complete matrix of species by states that also represents 
#' within-Australia invasions, use \link{create_species_state_origin_matrix}.  
#'
#' @family diversity methods
#' @param species A character string typically representing the binomial for the species.  
#' @param resources An optional list of taxonomic resources to use for the lookup.
#'        If not provided, the function will load default taxonomic resources using the
#'        `load_taxonomic_resources()` function.
#' @return A tibble with two columns: `species`, which is the same as the unique values of
#'  the input `species`, and `native_anywhere_in_aus`, a vector indicating whether each
#'  species is native anywhere in Australia, introduced by humans from elsewhere, or
#'  unknown with respect to the APC resource.
#' @export
#' @examples
#' \donttest{native_anywhere_in_australia(c("Eucalyptus globulus","Pinus radiata","Banksis notaspecies"))}

native_anywhere_in_australia <- function(species, resources = load_taxonomic_resources()) {
  
  # Create lookup tables  
  full_lookup <- create_species_state_origin_matrix(resources = resources)
  
  if(is.null(resources)){
    message("Not finding taxonomic resources; check internet connection?")
    return(NULL)
  }
  
  if (any(!species %in% full_lookup$species)) {
    warning("At least one input not found in APC; make sure inputs are at the species level and consider using `create_taxonomic_update_lookup` first.")
  }
  
  # Filter for native species
  full_lookup$native_anywhere <-
    apply(full_lookup, 1, function(x)
      any(grepl("native", x)))
  native_only<-dplyr::filter(full_lookup,native_anywhere)
  
  # Check membership
  natives <- species %in% native_only$species
  fulllist <- species %in% full_lookup$species
  
  # Create output tibble
  result <- dplyr::tibble(
    species = species,
    native_anywhere_in_aus = dplyr::case_when(
      natives & fulllist ~ "native",
      fulllist ~ "introduced",
      TRUE ~ "unknown"
    )
  )
  
  return(result)
}

