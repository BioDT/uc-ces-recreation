% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/recreation.R
\name{rescale_to_unit_interval}
\alias{rescale_to_unit_interval}
\title{Rescale to Unit Interval}
\usage{
rescale_to_unit_interval(raster)
}
\arguments{
\item{raster}{The \code{SpatRaster} to be transformed.}
}
\value{
A rescaled \code{SpatRaster} of the same dimensions as the input.
}
\description{
Rescale a SpatRaster to the interval [0, 1] using a data-dependent affine
(shift-and-rescale) transformation.
}
\details{
Given a \code{SpatRaster} with layers \eqn{v_i(x, y) \in \mathbb{R}}, the transformation
implemented is given by

\deqn{ \hat{v}_i(x, y) = \frac{v_i(x, y) - \min_{x,y}(v_i)}{\max_{x,y}(v_i) - \min_{x,y}(v_i)} \in [0, 1]}

I.e. every layer will be shifted and rescaled such that the layer minimum and maximum
are 0 and 1 respectively.

\code{NA} entries are silently ignored. A \emph{message} (not an error) will be raised if
the layer cannot be rescaled due to being single-valued.
}
