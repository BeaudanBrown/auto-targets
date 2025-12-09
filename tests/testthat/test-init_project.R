test_that("init_project creates directory structure", {
  tmp_dir <- withr::local_tempdir()

  init_project(tmp_dir)

  expect_true(dir.exists(file.path(tmp_dir, "R", "auto")))
  expect_true(dir.exists(file.path(tmp_dir, "R", "helpers")))
  expect_true(dir.exists(file.path(tmp_dir, "R", "manual")))
  expect_true(dir.exists(file.path(tmp_dir, "targets")))
})

test_that("init_project creates _targets.R", {
  tmp_dir <- withr::local_tempdir()

  init_project(tmp_dir)

  targets_file <- file.path(tmp_dir, "_targets.R")
  expect_true(file.exists(targets_file))

  content <- readLines(targets_file)
  expect_true(any(grepl("library\\(targets\\)", content)))
  expect_true(any(grepl("library\\(autotargets\\)", content)))
  expect_true(any(grepl("use_auto_targets", content)))
})

test_that("init_project creates example file", {
  tmp_dir <- withr::local_tempdir()

  init_project(tmp_dir)

  example_file <- file.path(tmp_dir, "R", "auto", "example.R")
  expect_true(file.exists(example_file))

  content <- readLines(example_file)
  expect_true(any(grepl("greeting", content)))
  expect_true(any(grepl("function", content)))
})

test_that("init_project does not overwrite by default", {
  tmp_dir <- withr::local_tempdir()

  # First init
  init_project(tmp_dir)

  # Modify a file
  targets_file <- file.path(tmp_dir, "_targets.R")
  writeLines("# Modified", targets_file)

  # Second init should not overwrite
  init_project(tmp_dir)

  content <- readLines(targets_file)
  expect_equal(content, "# Modified")
})

test_that("init_project overwrites when requested", {
  tmp_dir <- withr::local_tempdir()

  # First init
  init_project(tmp_dir)

  # Modify a file
  targets_file <- file.path(tmp_dir, "_targets.R")
  writeLines("# Modified", targets_file)

  # Second init with overwrite
  init_project(tmp_dir, overwrite = TRUE)

  content <- readLines(targets_file)
  expect_true(any(grepl("library\\(targets\\)", content)))
})
