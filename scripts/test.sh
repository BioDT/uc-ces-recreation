#!/bin/bash

# Run this from the repository root!

pre-commit run --all-files || Rscript scripts/pre-commit.R

Rscript -e 'testthat::test_local()'
