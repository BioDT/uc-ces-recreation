% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{make_safe_string}
\alias{make_safe_string}
\title{Make Safe String}
\usage{
make_safe_string(string)
}
\arguments{
\item{string}{The input string.}
}
\value{
The 'safe' string.
}
\description{
Convert an arbitrary string into a 'safe' one that can be used in
file names and data.frame column names. This involves replacing
spaces with underscores and removing any characters that are not
alpha-numeric.
}
\keyword{internal}
