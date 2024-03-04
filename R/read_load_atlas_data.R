#' Download Dataset from Dataverse
#'
#' Downloads datasets from Dataverse according to specified digit level and years,
#' and saves them to a specified directory. It checks the validity of `digits` and
#' `years` parameters before proceeding with the download. Requires an environment
#' variable `DATAVERSE_KEY` for API access.
#'
#' @param digits An integer indicating the level of digit classification of the dataset (2, 4, or 6).
#' @param years A vector of integers indicating the years of interest (between 1995 and 2021).
#' @param dir A character string specifying the directory path where datasets should be saved.
#' @return Invisible NULL. The function is called for its side effect: downloading and saving datasets.
#' @export
download_dataverse_atlas <- function(digits, years, dir) {
  label <- NULL
  checkmate::assert_choice(digits, choices = c(2, 4, 6))
  checkmate::assert_subset(years, choices = c(1995:2021))
  datasets <-
    httr2::request("https://dataverse.harvard.edu/api/datasets/3425423/versions/:latest/files") |>
    httr2::req_headers("X-Dataverse-key" = Sys.getenv("DATAVERSE_KEY")) |>
    httr2::req_perform() |>
    httr2::resp_body_json(simplifyVector = TRUE) |>
    purrr::pluck("data") |>
    tidyr::unnest(cols = "dataFile", names_repair = "unique") |>
    dplyr::filter(
      stringr::str_detect(label, stringr::str_c(digits, "digit")) &
        stringr::str_detect(label, "partner") &
        stringr::str_detect(label, "dta") &
        stringr::str_detect(label, stringr::str_c(years, collapse = "|"))
    )

  for (i in cli::cli_progress_along(datasets$id)) {
    file <- file.path(dir, stringr::str_c(datasets$label[i]))
    if (!file.exists(file)) {
      resp <-
        httr2::request(
          glue::glue(
            "https://dataverse.harvard.edu/api/access/datafile/{datasets$id[i]}"
          )
        ) |>
        httr2::req_headers("X-Dataverse-key" = Sys.getenv("DATAVERSE_KEY")) |>
        httr2::req_perform() |>
        httr2::resp_body_raw() |>
        base::writeBin(file)
    }
  }
}

#' Read Dataset Files from Directory
#'
#' Reads .dta files matching specified digit level and years from a directory into a single data frame.
#' It performs an error check to ensure there are files matching the query before attempting to read them.
#'
#' @param digits An integer indicating the level of digit classification of the dataset (2, 4, or 6).
#' @param years A vector of integers indicating the years of interest.
#' @param dir A character string specifying the directory path where datasets are located.
#' @param workers An integer specifying the number of workers to use for parallel processing (default is 10).
#' @return A data frame containing combined data from all matched .dta files.
#' @export
read_dataverse_atlas <- function(digits, years, dir, workers = 10) {
  files <- list.files(dir, full.names = TRUE)

  file_set <-
    files[stringr::str_detect(files, stringr::str_c(digits, "digit")) &
            stringr::str_detect(files, "partner") &
            stringr::str_detect(files, "dta") &
            stringr::str_detect(files, stringr::str_c(years, collapse = "|"))]

  if (length(file_set) < 1) {
    rlang::abort("There are no files matching your query.")
  }

  future::plan("multisession", workers = workers)

  result <-
    furrr::future_map_dfr(file_set,
                          haven::read_dta,
                          .progress = TRUE)

  return(result)
}
