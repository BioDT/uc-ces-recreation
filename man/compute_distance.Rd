% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_production.R
\name{compute_distance}
\alias{compute_distance}
\title{Compute Distance}
\usage{
compute_distance(infile, outfile)
}
\arguments{
\item{infile}{Path to file containing the input raster.}

\item{outfile}{Path that the output raster will be written to.}
}
\description{
Computes the distance to the nearest non-\code{NA} value in a raster using
haversine distance, writing straight to \code{outfile}. This is a thin wrapper
around \link[terra:distance]{terra::distance}.
}
\keyword{internal}
