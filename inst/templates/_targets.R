library(targets)
library(autotargets)

# Source helper functions (not turned into targets)
helper_files <- list.files("R/helpers", pattern = "\\.[rR]$", full.names = TRUE)
for (f in helper_files) source(f, local = FALSE)

# Auto-generate targets from R/auto/
auto_targets <- use_auto_targets()

# Source manual target definitions
manual_files <- list.files("R/manual", pattern = "\\.[rR]$", full.names = TRUE)
manual_targets <- lapply(manual_files, function(f) {
  source(f, local = TRUE)$value
})
manual_targets <- unlist(manual_targets, recursive = FALSE)

# Combine all targets
c(auto_targets, manual_targets)
