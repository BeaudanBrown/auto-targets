#' Initialize autotargets project structure
#'
#' Creates the directory structure and template files needed for an
#' autotargets project.
#'
#' @param path Project root path (default: current directory)
#' @param overwrite Whether to overwrite existing files (default: FALSE)
#'
#' @return Invisibly returns the project path
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize in current directory
#' init_project()
#'
#' # Initialize in a new directory
#' init_project("my_project")
#' }
init_project <- function(path = ".", overwrite = FALSE) {
  path <- fs::path_abs(path)

  # Create directories
  dirs <- c(
    "R/auto",
    "R/helpers",
    "R/manual",
    "targets"
  )

  for (dir in dirs) {
    dir_path <- fs::path(path, dir)
    if (!fs::dir_exists(dir_path)) {
      fs::dir_create(dir_path, recurse = TRUE)
      cli::cli_alert_success("Created {.file {dir}}")
    } else {
      cli::cli_alert_info("Directory already exists: {.file {dir}}")
    }
  }

  # Create _targets.R from template
  targets_file <- fs::path(path, "_targets.R")
  if (!fs::file_exists(targets_file) || overwrite) {
    writeLines(targets_r_template(), targets_file)
    cli::cli_alert_success("Created {.file _targets.R}")
  } else {
    cli::cli_alert_info("File already exists: {.file _targets.R}")
  }

  # Create example file in R/auto
  example_file <- fs::path(path, "R/auto/example.R")
  if (!fs::file_exists(example_file) || overwrite) {
    writeLines(example_auto_template(), example_file)
    cli::cli_alert_success("Created {.file R/auto/example.R}")
  } else {
    cli::cli_alert_info("File already exists: {.file R/auto/example.R}")
  }
  # Create placeholder in R/helpers
  helpers_file <- fs::path(path, "R/helpers/.gitkeep")
  if (!fs::file_exists(helpers_file)) {
    fs::file_create(helpers_file)
  }

  # Create placeholder in R/manual
  manual_file <- fs::path(path, "R/manual/.gitkeep")
  if (!fs::file_exists(manual_file)) {
    fs::file_create(manual_file)
  }

  cli::cli_alert_success("autotargets project initialized at {.file {path}}")
  cli::cli_alert_info("Next steps:")
  cli::cli_bullets(c(
    " " = "Add functions to {.file R/auto/}",
    " " = "Run {.code targets::tar_make()} to execute the pipeline"
  ))

  invisible(path)
}

#' Template for _targets.R
#' @keywords internal
targets_r_template <- function() {
  c(
    "library(targets)",
    "library(autotargets)",
    "",
    "# Source helper functions (not turned into targets)",
    "helper_files <- list.files(\"R/helpers\", pattern = \"\\\\.[rR]$\", full.names = TRUE)",
    "for (f in helper_files) source(f, local = FALSE)",
    "",
    "# Auto-generate targets from R/auto/",
    "auto_targets <- use_auto_targets()",
    "",
    "# Source manual target definitions",
    "manual_files <- list.files(\"R/manual\", pattern = \"\\\\.[rR]$\", full.names = TRUE)",
    "manual_targets <- lapply(manual_files, function(f) {",
    "  source(f, local = TRUE)$value",
    "})",
    "manual_targets <- unlist(manual_targets, recursive = FALSE)",
    "",
    "# Combine all targets",
    "c(auto_targets, manual_targets)"
  )
}

#' Template for example R/auto file
#' @keywords internal
example_auto_template <- function() {
  c(
    "# Example autotargets file",
    "# Functions and constants defined here become targets automatically",
    "",
    "# This constant becomes: tar_target(greeting, greeting)",
    "greeting <- \"Hello, autotargets!\"",
    "",
    "# This function becomes: tar_target(make_message, make_message(greeting))",
    "make_message <- function(greeting) {",
    "  paste(greeting, \"The pipeline is working.\")",
    "}",
    "",
    "# This function becomes: tar_target(print_message, print_message(make_message))",
    "print_message <- function(make_message) {",
    "  message(make_message)",
    "  make_message",
    "}"
  )
}
