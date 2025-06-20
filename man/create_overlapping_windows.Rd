% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_production.R
\name{create_overlapping_windows}
\alias{create_overlapping_windows}
\title{create_overlapping_windows}
\usage{
create_overlapping_windows(r, target_tiles, buffer_dist)
}
\arguments{
\item{target_tiles}{amount of "tiles"/"windows/"chunks" in which to ideally break the raster into.}

\item{buffer_dist}{buffer distance to use for each tile}

\item{A}{SpatRast element read in using terra::rast(raster_name.tif)}
}
\value{
a list in which each element is representing a window, and provides a sub
list of the buffered extent, and the un-buffered extent of that tile
}
\description{
For a raster provided, split into n windows and their buffer of n meters (to maintain distance calculation relevant).
}
\keyword{internal}
