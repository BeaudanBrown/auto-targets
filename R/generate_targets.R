#' Generate targets from R/auto directory
#'
#' Scans the `R/auto/` directory for function and constant definitions,
#' then generates corresponding `tar_target()` calls and writes them to
#' a file.
#'
#' @param path Project root path (default: current directory)
#' @param write Whether to write the output file (default: TRUE)
#' @param output_path Output file path relative to project root
#'   (default: "targets/_targets_generated.R")
#' @param auto_dir Directory to scan for auto-generated targets relative to
#'   project root (default: "R/auto")
#'
#' @return Invisibly returns a character vector of the generated tar_target()
#'   call strings
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Generate targets and write to file
#' generate_targets()
#'
#' # Generate without writing (dry run)
#' targets <- generate_targets(write = FALSE)
#' cat(targets, sep = "\n")
#' }
generate_targets <- function(
  path = ".",
  write = TRUE,
  output_path = "targets/_targets_generated.R",
  auto_dir = "R/auto"
) {
  path <- fs::path_abs(path)
  auto_path <- fs::path(path, auto_dir)
  output_full <- fs::path(path, output_path)

  # Scan directory for definitions
  result <- scan_auto_dir(auto_path)

  # Generate target lines
  target_lines <- character()

  # Functions first
  for (name in names(result$functions)) {
    formals <- result$functions[[name]]
    target_lines <- c(target_lines, make_function_target(name, formals))
  }

  # Then constants
  for (name in result$constants) {
    target_lines <- c(target_lines, make_constant_target(name))
  }

  if (write) {
    write_targets_file(target_lines, output_full, source_dir = auto_dir)
  }

  invisible(target_lines)
}

#' Regenerate and return auto-generated targets
#'
#' This function is designed to be called from `_targets.R`. It regenerates
#' the targets file and then sources it to return the list of targets.
#'
#' @param path Project root path (default: current directory)
#' @param output_path Output file path relative to project root
#'   (default: "targets/_targets_generated.R")
#' @param auto_dir Directory to scan for auto-generated targets relative to
#'   project root (default: "R/auto")
#'
#' @return A list of `tar_target()` objects ready to be included in the
#'   pipeline
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # In _targets.R:
#' library(targets)
#' library(autotargets)
#'
#' auto_targets <- use_auto_targets()
#'
#' c(auto_targets, list(
#'   # additional manual targets here
#' ))
#' }
use_auto_targets <- function(
  path = ".",
  output_path = "targets/_targets_generated.R",
  auto_dir = "R/auto"
) {
  path <- fs::path_abs(path)
  output_full <- fs::path(path, output_path)
  auto_path <- fs::path(path, auto_dir)

  # First, source all files in R/auto so functions are available
  r_files <- fs::dir_ls(auto_path, regexp = "\\.[rR]$", recurse = FALSE)
  for (file in r_files) {
    source(file, local = FALSE)
  }

  # Regenerate the targets file
  generate_targets(
    path = path,
    write = TRUE,
    output_path = output_path,
    auto_dir = auto_dir
  )

  # Source and return the generated targets
  if (fs::file_exists(output_full)) {
    source(output_full, local = TRUE)$value
  } else {
    cli::cli_warn("No targets generated")
    list()
  }
}
