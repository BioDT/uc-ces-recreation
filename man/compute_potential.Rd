% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/recreation.R
\name{compute_potential}
\alias{compute_potential}
\title{Compute Recreational Potential}
\usage{
compute_potential(persona, bbox, data_dir = NULL)
}
\arguments{
\item{persona}{A named vector containing the persona scores.}

\item{bbox}{An optional bounding box for cropping.}

\item{data_dir}{Path to the directory containing the rasters.}
}
\value{
A \code{SpatRaster} with five layers: the four components and the Recreational
Potential. All five layers are normalised to the unit interval [0, 1].
}
\description{
Compute all four components and aggregate into the Recreational Potential value.
}
\details{
The Recreational Potential value, \eqn{\hat{P}(x, y)}, is given by a normalised sum over
the four normalised components. That is,

\deqn{ P(x, y) = \sum_{i=1}^{4}  \hat{p}_i(x, y) }

where the hat denotes values that have been rescaled to the unit interval
using a data-dependent shift-and-rescale

\deqn{ \hat{v}(x, y) = \frac{v(x, y) - \min_{x,y}(v)}{\max_{x,y}(v) - \min_{x,y}(v)} }
}
\examples{
library(biodt.recreation)

persona <- get_example_persona()
bbox <- get_example_bbox()
data_dir <- get_example_data_dir()

# Compute all layers
layers <- compute_potential(persona, bbox, data_dir)

# Get the full RP layer only
rp <- layers[["Recreational_Potential"]]
}
\seealso{
\link{compute_component} used to compute each component.
\link{rescale_to_unit_interval} performs the normalisation.
}
