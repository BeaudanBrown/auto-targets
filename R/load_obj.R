#' Load a target into the global environment for debugging
#'
#' Convenience function to quickly load a target's value into the global
#' environment for interactive debugging and exploration.
#'
#' @param name Target name. Can be a character string or unquoted symbol.
#' @param envir Environment to load into (default: global environment)
#' @param store Path to the targets store (default: NULL uses targets default)
#'
#' @return Invisibly returns the loaded value
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Load by name (character)
#' load_obj("my_target")
#'
#' # Load by symbol (unquoted)
#' load_obj(my_target)
#'
#' # The target value is now available in your environment
#' print(my_target)
#' }
load_obj <- function(name, envir = globalenv(), store = NULL) {
  # Handle both quoted and unquoted names
  name_expr <- substitute(name)
  if (is.symbol(name_expr)) {
    name <- as.character(name_expr)
  } else if (is.character(name)) {
    # Already a character, use as-is
  } else {
    cli::cli_abort("{.arg name} must be a character string or symbol")
  }

  # Check if target exists
  if (!is.null(store)) {
    exists <- targets::tar_exist_objects(name, store = store)
  } else {
    exists <- targets::tar_exist_objects(name)
  }

  if (!exists) {
    cli::cli_abort(c(
      "Target {.val {name}} not found in store",
      "i" = "Run {.code targets::tar_make()} first to build targets"
    ))
  }

  # Load the target
  if (!is.null(store)) {
    value <- targets::tar_read_raw(name, store = store)
  } else {
    value <- targets::tar_read_raw(name)
  }

  # Assign to environment
  assign(name, value, envir = envir)

  cli::cli_alert_success("Loaded {.val {name}} into environment")

  invisible(value)
}

#' Load multiple targets into the global environment
#'
#' @param names Character vector of target names to load
#' @param envir Environment to load into (default: global environment)
#' @param store Path to the targets store (default: NULL uses targets default)
#'
#' @return Invisibly returns a named list of the loaded values
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Load multiple targets
#' load_objs(c("data", "model", "results"))
#' }
load_objs <- function(names, envir = globalenv(), store = NULL) {
  values <- list()
  for (name in names) {
    values[[name]] <- load_obj(name, envir = envir, store = store)
  }
  invisible(values)
}
