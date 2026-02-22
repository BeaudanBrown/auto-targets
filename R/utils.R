#' Check if expression is a function definition
#'
#' @param expr An R expression
#' @return Logical indicating if expression is a function definition
#' @keywords internal
is_function_def <- function(expr) {
  if (!is.call(expr)) {
    return(FALSE)
  }
  op <- as.character(expr[[1]])
  if (!(op %in% c("<-", "="))) {
    return(FALSE)
  }
  if (length(expr) < 3) {
    return(FALSE)
  }
  is.call(expr[[3]]) && identical(expr[[3]][[1]], as.name("function"))
}

#' Check if expression is a constant (non-function assignment)
#'
#' @param expr An R expression
#' @return Logical indicating if expression is a constant assignment
#' @keywords internal
is_constant_def <- function(expr) {
  if (!is.call(expr)) {
    return(FALSE)
  }
  op <- as.character(expr[[1]])
  if (!(op %in% c("<-", "="))) {
    return(FALSE)
  }
  if (length(expr) < 3) {
    return(FALSE)
  }
  # It's a constant if it's an assignment but NOT a function definition
  !is_function_def(expr)
}

#' Check if a name indicates a file target
#'
#' File targets are identified by the `_file` suffix convention.
#' Variables named like `raw_data_file` will be treated as file targets.
#'
#' @param name Variable name
#' @return Logical indicating if this should be a file target
#' @keywords internal
is_file_target <- function(name) {
  grepl("_file$", name)
}

#' Get the name from an assignment expression
#'
#' @param expr An assignment expression
#' @return Character string with the assigned name
#' @keywords internal
get_assignment_name <- function(expr) {
  as.character(expr[[2]])
}

#' Get formals from a function definition expression
#'
#' @param expr A function definition expression
#' @return List of formal arguments (or NULL if not a function)
#' @keywords internal
get_function_formals <- function(expr) {
  if (!is_function_def(expr)) {
    return(NULL)
  }
  func_expr <- expr[[3]]
  # func_expr is function(args) body
  # formals are in func_expr[[2]]
  as.list(func_expr[[2]])
}

#' Get source code for an expression from parse data
#'
#' @param expr An expression
#' @param parse_data Parse data from getParseData()
#' @param expr_index Index of the expression in the parse tree
#' @return Character string with the source code
#' @keywords internal
get_expression_source <- function(expr, parse_data, expr_index) {
  # Try to get source from parse data
  if (!is.null(parse_data) && nrow(parse_data) > 0) {
    # Find the top-level expression by looking for parent == 0
    top_level <- parse_data[parse_data$parent == 0, ]
    if (nrow(top_level) >= expr_index) {
      row <- top_level[expr_index, ]
      source_lines <- seq(row$line1, row$line2)
      # We need the original file content - fall back to deparse
    }
  }
  # Fall back to deparsing the expression
  paste(deparse(expr), collapse = "\n")
}

#' Generate tar_target call string for a function
#'
#' Creates a single target that embeds the function source directly.
#' This ensures that when the function body changes, the command changes
#' and targets properly invalidates the target.
#'
#' @param name Function name
#' @param formals List of formal arguments
#' @param source Source code of the function (as string)
#' @return Character string with tar_target() call
#' @keywords internal
make_function_target <- function(name, formals, source) {
  arg_names <- names(formals)

  # Escape the source for embedding in string
  source_escaped <- gsub('\\', '\\\\', source, fixed = TRUE)
  source_escaped <- gsub('"', '\\"', source_escaped, fixed = TRUE)
  source_escaped <- gsub("\n", "\\n", source_escaped, fixed = TRUE)
  source_escaped <- gsub("\r", "\\r", source_escaped, fixed = TRUE)
  source_escaped <- gsub("\t", "\\t", source_escaped, fixed = TRUE)

  # Build the argument call
  if (is.null(arg_names) || length(arg_names) == 0) {
    call_str <- ".fn()"
  } else {
    call_str <- paste0(".fn(", paste(arg_names, collapse = ", "), ")")
  }

  # Check if this is a file target (name ends with _file)
  if (is_file_target(name)) {
    paste0(
      '  tar_target(', name, ', {\n',
      '    .fn <- eval(parse(text = "', source_escaped, '"))\n',
      '    ', call_str, '\n',
      '  }, format = "file")'
    )
  } else {
    paste0(
      '  tar_target(', name, ', {\n',
      '    .fn <- eval(parse(text = "', source_escaped, '"))\n',
      '    ', call_str, '\n',
      '  })'
    )
  }
}

#' Generate tar_target call string for a constant
#'
#' Uses `get()` to fetch the constant from globalenv() to avoid
#' name conflicts where the constant name matches the target name.
#'
#' @param name Constant name
#' @return Character string with tar_target() call
#' @keywords internal
make_constant_target <- function(name) {
  paste0('  tar_target(', name, ', get("', name, '", envir = globalenv()))')
}

#' Generate tar_target call string for a file target
#'
#' File targets use `format = "file"` to track the file itself
#' rather than the string value of the path.
#'
#' Uses `get()` to fetch the constant from globalenv() to avoid
#' name conflicts where the constant name matches the target name.
#'
#' @param name File target name
#' @return Character string with tar_target() call
#' @keywords internal
make_file_target <- function(name) {
  paste0('  tar_target(', name, ', get("', name, '", envir = globalenv()), format = "file")')
}

#' Write generated targets file with header
#'
#' @param target_lines Character vector of tar_target() call strings
#' @param path Output file path
#' @param source_dir Source directory that was scanned
#' @keywords internal
write_targets_file <- function(target_lines, path, source_dir = "R/auto/") {
  header <- c(
    "# AUTOGENERATED by autotargets - DO NOT EDIT BY HAND",
    paste0("# Generated: ", Sys.time()),
    paste0("# Source: ", source_dir),
    "",
    "list(",
    ""
  )

  footer <- c(
    ")"
  )

  # Add commas between targets
  if (length(target_lines) > 0) {
    target_lines[-length(target_lines)] <- paste0(
      target_lines[-length(target_lines)],
      ","
    )
  }

  content <- c(header, target_lines, footer)

  # Ensure directory exists
  fs::dir_create(fs::path_dir(path))

  writeLines(content, path)
  cli::cli_alert_success(
    "Generated {length(target_lines)} target(s) in {.file {path}}"
  )

  invisible(path)
}
