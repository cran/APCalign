% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/load_taxonomic_resources.R
\name{load_taxonomic_resources}
\alias{load_taxonomic_resources}
\title{Load taxonomic reference lists, APC & APNI}
\usage{
load_taxonomic_resources(
  stable_or_current_data = "stable",
  version = default_version(),
  quiet = FALSE
)
}
\arguments{
\item{stable_or_current_data}{Type of dataset to access.
The default is "stable", which loads the dataset from a github archived file.
If set to "current", the dataset will be loaded from a URL which is the
cutting edge version, but this may change at any time without notice.}

\item{version}{The version number of the dataset to use.
Defaults to the default version.}

\item{quiet}{A logical indicating whether to print status of loading to screen.
Defaults to FALSE.}
}
\value{
The taxonomic resources data loaded into the global environment.
}
\description{
This function loads two taxonomic datasets for Australia's vascular plants,
the APC and APNI, into the global environment. It creates several data frames
by filtering and selecting data from the loaded lists.
}
\details{
\itemize{
\item It accesses taxonomic data from a dataset using the provided version number
or the default version.
\item The output is several dataframes that include subsets of the APC/APNI based
on taxon rank and taxonomic status.
}
}
\examples{
\donttest{
load_taxonomic_resources(stable_or_current_data="stable", 
version="2024-10-11")}

}
