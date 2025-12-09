#' Parse an R file and extract function/constant definitions
#'
#' Scans an R file for top-level function definitions and constant assignments.
#' Returns information about each definition including name and formal arguments.
#'
#' @param path Path to an R file
#' @return A list with two elements:
#'   - `functions`: Named list where names are function names and values are
#'     lists of formal arguments
#'   - `constants`: Character vector of constant names
#' @keywords internal
parse_r_file <- function(path) {
  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.file {path}}")
  }

  exprs <- tryCatch(
    parse(path, keep.source = TRUE),
    error = function(e) {
      cli::cli_warn("Failed to parse {.file {path}}: {e$message}")
      return(NULL)
    }
  )

  if (is.null(exprs)) {
    return(list(functions = list(), constants = character()))
  }

  functions <- list()
  constants <- character()

  for (expr in exprs) {
    if (is_function_def(expr)) {
      name <- get_assignment_name(expr)
      formals <- get_function_formals(expr)
      functions[[name]] <- formals
    } else if (is_constant_def(expr)) {
      name <- get_assignment_name(expr)
      constants <- c(constants, name)
    }
  }

  list(functions = functions, constants = constants)
}

#' Scan a directory for R files and parse all of them
#'
#' @param dir Directory path to scan
#' @param recursive Whether to scan subdirectories
#' @return A list with two elements:
#'   - `functions`: Named list of all functions found
#'   - `constants`: Character vector of all constant names
#' @keywords internal
scan_auto_dir <- function(dir, recursive = FALSE) {
  if (!fs::dir_exists(dir)) {
    cli::cli_warn("Directory not found: {.file {dir}}")
    return(list(functions = list(), constants = character()))
  }

  r_files <- fs::dir_ls(dir, regexp = "\\.[rR]$", recurse = recursive)

  if (length(r_files) == 0) {
    cli::cli_alert_info("No R files found in {.file {dir}}")
    return(list(functions = list(), constants = character()))
  }

  all_functions <- list()
  all_constants <- character()
  seen_names <- character()

  for (file in r_files) {
    result <- parse_r_file(file)

    # Check for duplicate function names
    for (name in names(result$functions)) {
      if (name %in% seen_names) {
        cli::cli_warn(
          "Duplicate definition of {.val {name}} in {.file {file}}; using latest"
        )
      }
      seen_names <- c(seen_names, name)
      all_functions[[name]] <- result$functions[[name]]
    }

    # Check for duplicate constant names
    for (name in result$constants) {
      if (name %in% seen_names) {
        cli::cli_warn(
          "Duplicate definition of {.val {name}} in {.file {file}}; using latest"
        )
      }
      seen_names <- c(seen_names, name)
    }
    all_constants <- unique(c(all_constants, result$constants))
  }

  # Remove constants that are also function names (function takes precedence)
  all_constants <- setdiff(all_constants, names(all_functions))

  list(functions = all_functions, constants = all_constants)
}
