test_that("load_obj errors when target doesn't exist", {
  tmp_dir <- withr::local_tempdir()

  # Initialize a targets project
  withr::local_dir(tmp_dir)

  expect_error(
    load_obj("nonexistent"),
    "not found"
  )
})

# Integration tests for load_obj require a built targets pipeline,
# which is more appropriate for integration testing rather than unit testing.
# The basic error handling is tested above.
