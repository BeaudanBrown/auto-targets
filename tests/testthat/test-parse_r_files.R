test_that("is_function_def identifies function definitions", {
  # Simple function
  expr <- quote(f <- function(x) x)
  expect_true(is_function_def(expr))

  # Function with multiple args
  expr <- quote(g <- function(x, y, z) x + y + z)
  expect_true(is_function_def(expr))

  # Function with no args

  expr <- quote(h <- function() 42)
  expect_true(is_function_def(expr))

  # Using = instead of <-
  expr <- parse(text = "i = function(x) x")[[1]]
  expect_true(is_function_def(expr))
})

test_that("is_function_def rejects non-function definitions", {
  # Constant assignment
  expr <- quote(x <- 42)
  expect_false(is_function_def(expr))

  # List assignment
  expr <- quote(params <- list(a = 1, b = 2))
  expect_false(is_function_def(expr))

  # Not an assignment
  expr <- quote(print("hello"))
  expect_false(is_function_def(expr))
})

test_that("is_constant_def identifies constant assignments", {
  # Simple value
  expr <- quote(x <- 42)
  expect_true(is_constant_def(expr))

  # List
  expr <- quote(params <- list(a = 1))
  expect_true(is_constant_def(expr))

  # Vector
  expr <- quote(v <- c(1, 2, 3))
  expect_true(is_constant_def(expr))
})

test_that("is_constant_def rejects function definitions", {
  expr <- quote(f <- function(x) x)
  expect_false(is_constant_def(expr))
})

test_that("get_assignment_name extracts name correctly", {
  expr <- quote(my_var <- 42)
  expect_equal(get_assignment_name(expr), "my_var")

  expr <- quote(another.name <- function(x) x)
  expect_equal(get_assignment_name(expr), "another.name")
})

test_that("get_function_formals extracts formals correctly", {
  # Single arg
  expr <- quote(f <- function(x) x)
  formals <- get_function_formals(expr)
  expect_equal(names(formals), "x")

  # Multiple args
  expr <- quote(g <- function(a, b, c) a + b + c)
  formals <- get_function_formals(expr)
  expect_equal(names(formals), c("a", "b", "c"))

  # Args with defaults
  expr <- quote(h <- function(x = 1, y = 2) x + y)
  formals <- get_function_formals(expr)
  expect_equal(names(formals), c("x", "y"))

  # No args
  expr <- quote(i <- function() 42)
  formals <- get_function_formals(expr)
  expect_length(formals, 0)
})

test_that("parse_r_file parses a file correctly", {
  # Create a temporary file
  tmp <- withr::local_tempfile(fileext = ".R")
  writeLines(
    c(
      "# Comment",
      "my_const <- 42",
      "",
      "my_func <- function(x, y) {",
      "  x + y",
      "}",
      "",
      "another_const <- list(a = 1)"
    ),
    tmp
  )

  result <- parse_r_file(tmp)

  expect_equal(names(result$functions), "my_func")
  expect_equal(names(result$functions$my_func), c("x", "y"))
  expect_equal(sort(result$constants), sort(c("my_const", "another_const")))
})

test_that("scan_auto_dir handles empty directory", {
  tmp_dir <- withr::local_tempdir()
  result <- scan_auto_dir(tmp_dir)

  expect_length(result$functions, 0)
  expect_length(result$constants, 0)
})

test_that("scan_auto_dir warns on duplicate definitions", {
  tmp_dir <- withr::local_tempdir()

  writeLines("x <- 1", file.path(tmp_dir, "a.R"))
  writeLines("x <- 2", file.path(tmp_dir, "b.R"))

  expect_warning(
    result <- scan_auto_dir(tmp_dir),
    "Duplicate"
  )
})
