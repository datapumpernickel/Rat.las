
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Rat.las

<!-- badges: start -->
<!-- badges: end -->

The goal of Rat.las is to easily load into your project the data of the
atlas of economic complexity.

## Installation

You can install the development version of Rat.las like so:

``` r
devtools::install_github("datapumpernickel/Rat.las")
```

## Authentication

The data comes from the Harvard Dataverse. You need an API key.

See here for more info:
<https://guides.dataverse.org/en/latest/user/account.html>

Once you have an API key, set it in your R-Environment file like so:

``` r
usethis::edit_r_environ()
```

It must have the variable name: `DATAVERSE_KEY`. The function will then
automatically look for it and load it. Alternatively, you can set it
manually.

## Download Atlas of Economic Complexity Data

This is a basic example which shows you how to solve a common problem:

``` r
dir <- file.path("01_raw_data/aec")
dir.create(dir, showWarnings = F)


download_dataverse_atlas(digits = 6, years = 2010:2021,dir = dir)
```

Read the data into R:

``` r
full_data <- read_dataverse_atlas(digits = 6, 
                                  years = 2010:2021, 
                                  dir = dir, 
                                  workers = 12)
```
