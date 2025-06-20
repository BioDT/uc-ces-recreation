% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_production.R
\name{one_hot_all}
\alias{one_hot_all}
\title{One Hot All}
\usage{
one_hot_all(indir, outdir)
}
\arguments{
\item{indir}{Path to directory containing the input rasters.}

\item{outdir}{Path to directory in which to write the ouput rasters.}
}
\description{
Apply \link{one_hot_layer} to all rasters in a directory.
The file names must be consistent with the features as defined in the
configuration file.
\itemize{
\item \strong{Preceded by:} \link{reproject_all}
\item \strong{Precedes:} \link{stack_all}
}
}
\seealso{
\link{one_hot_layer}
}
\keyword{internal}
