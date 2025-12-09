# Example autotargets file
# Functions and constants defined here become targets automatically

# This constant becomes: tar_target(greeting, greeting)
greeting <- "Hello, autotargets!"

# This function becomes: tar_target(make_message, make_message(greeting))
make_message <- function(greeting) {
  paste(greeting, "The pipeline is working.")
}

# This function becomes: tar_target(print_message, print_message(make_message))
print_message <- function(make_message) {
  message(make_message)
  make_message
}
