# autotargets

Automatically generate `targets` pipelines from R functions using convention over configuration.

## Overview

`autotargets` scans your R files and automatically creates `tar_target()` definitions based on function arguments. Write your analysis functions, and the package wires up the dependencies for you.

**Key principle:** A function `f(x, y)` becomes `tar_target(f, f(x, y))` automatically.

## Installation

### From GitHub (Nix)

Add to your `flake.nix`:

```nix
autotargets = pkgs.rPackages.buildRPackage {
  name = "autotargets";
  src = pkgs.fetchFromGitHub {
    owner = "your-username";
    repo = "auto-targets";
    rev = "main";
    sha256 = "...";  # Run nix flake update to get hash
  };
  propagatedBuildInputs = with pkgs.rPackages; [
    targets
    cli
    fs
  ];
};
```

### From GitHub (R)

```r
remotes::install_github("your-username/auto-targets")
```

### From Local Source

```r
install.packages("path/to/auto-targets", repos = NULL, type = "source")
```

## Quick Start

### 1. Initialize Project Structure

```r
library(autotargets)
init_project()
```

This creates:
```
project/
├── _targets.R
├── R/
│   ├── auto/       # Functions scanned for targets
│   ├── helpers/    # Helper functions (not targets)
│   └── manual/     # Manual target definitions
└── targets/        # Generated files go here
```

### 2. Write Functions in R/auto/

Create `R/auto/analysis.R`:

```r
# Constants become targets too
params <- list(
  threshold = 0.05,
  n_iter = 1000
)

# This becomes: tar_target(data, data())
data <- function() {
  read.csv("input.csv")
}

# This becomes: tar_target(clean, clean(data))
clean <- function(data) {
  na.omit(data)
}

# This becomes: tar_target(model, model(clean, params))
model <- function(clean, params) {
  lm(y ~ x, data = clean)
}
```

### 3. Use Simple _targets.R

```r
library(targets)
library(autotargets)

use_auto_targets()
```

### 4. Run Pipeline

```r
targets::tar_make()
```

That's it! The package automatically:
- Maps function arguments to dependencies
- Creates `tar_target()` calls
- Handles the dependency graph

## Core Functions

### `init_project(path = ".")`

Initialize project structure with directories and template files.

**Arguments:**
- `path`: Project root directory
- `overwrite`: Whether to overwrite existing files

### `generate_targets(path = ".", write = TRUE, output_path = "targets/_targets_generated.R")`

Scan `R/auto/` and generate target definitions.

**Arguments:**
- `path`: Project root directory
- `write`: Whether to write output file
- `output_path`: Where to write generated targets
- `auto_dir`: Directory to scan (default: "R/auto")

**Returns:** List of target expressions (invisibly)

### `use_auto_targets(path = ".")`

Regenerate and source auto targets. Use this in `_targets.R`.

**Arguments:**
- `path`: Project root directory
- `output_path`: Where to write generated targets
- `auto_dir`: Directory to scan

**Returns:** List of `tar_target()` objects

### `load_obj(name)` / `load_objs(names)`

Load target(s) into global environment for interactive debugging.

**Arguments:**
- `name`: Target name (character or unquoted symbol)
- `names`: Vector of target names
- `envir`: Environment to load into (default: global)
- `store`: Path to targets store (optional)

**Examples:**

```r
# Load single target
load_obj(model)
load_obj("model")  # Equivalent

# Load multiple targets
load_objs(c("data", "clean", "model"))

# Now available in your environment
summary(model)
```

## Directory Structure

### R/auto/
Functions and constants here are automatically converted to targets.

**Conventions:**
- One function/constant per top-level assignment
- Function arguments must match existing target/constant names
- Files are sourced in alphabetical order

### R/helpers/
Helper functions that should NOT become targets. These are sourced before auto-generation.

Example: utility functions, custom operators, plotting themes.

### R/manual/
Manual `tar_target()` definitions for complex cases that can't be auto-generated.

Each file should return a list of targets:

```r
# R/manual/special.R
list(
  tar_target(
    complex_target,
    {
      # Multi-step process
      step1 <- process_data()
      step2 <- transform(step1)
      finalize(step2)
    }
  ),
  tar_target_raw(
    "dynamic_target",
    quote(some_function()),
    deps = c("other", "deps")
  )
)
```

## Complete _targets.R Template

```r
library(targets)
library(autotargets)

# Source helper functions (not turned into targets)
helper_files <- list.files("R/helpers", pattern = "\\.[rR]$", full.names = TRUE)
for (f in helper_files) {
  source(f, local = FALSE)
}

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
```

## How It Works

### Parsing

The package uses base R's `parse()` and `getParseData()` to identify:

1. **Function definitions:** `name <- function(args) body`
2. **Constants:** `name <- value` (any non-function assignment)

### Target Generation

**Functions** → `tar_target(name, name(arg1, arg2, ...))`

```r
# Input
clean <- function(data, params) {
  filter(data, value > params$threshold)
}

# Generated
tar_target(clean, clean(data, params))
```

**Constants** → `tar_target(name, name)`

```r
# Input
params <- list(threshold = 0.05)

# Generated
tar_target(params, params)
```

### Dependency Resolution

Dependencies are automatically inferred from function arguments:
- `f(x, y)` depends on targets `x` and `y`
- `targets` handles the execution order
- No manual dependency specification needed

## Edge Cases

| Case | Behavior |
|------|----------|
| No arguments: `f <- function() {}` | `tar_target(f, f())` |
| Default values: `f <- function(x = 1)` | Uses arg name: `tar_target(f, f(x))` |
| Duplicate definitions | Warning issued, last definition wins |
| `=` vs `<-` assignment | Both supported |
| Nested functions | Only top-level parsed |

## Example Workflow

```r
# 1. Initialize
library(autotargets)
init_project()

# 2. Write functions in R/auto/data.R
raw_data <- function() {
  read.csv("input.csv")
}

processed <- function(raw_data) {
  transform(raw_data)
}

# 3. Write _targets.R
library(targets)
library(autotargets)
use_auto_targets()

# 4. Run pipeline
targets::tar_make()

# 5. Load results for debugging
load_obj(processed)
head(processed)

# 6. Visualize pipeline
targets::tar_visnetwork()
```

## Generated Output

The file `targets/_targets_generated.R` is created:

```r
# AUTOGENERATED by autotargets - DO NOT EDIT BY HAND
# Generated: 2025-01-15 10:30:00
# Source: R/auto/

list(
  tar_target(raw_data, raw_data()),
  tar_target(processed, processed(raw_data))
)
```

This file is committed to version control for transparency.

## Development

### Running Tests

```r
devtools::test()
```

### Building Documentation

```r
devtools::document()
```

### Checking Package

```r
devtools::check()
```

## Design Philosophy

**Convention over configuration:** Minimal boilerplate, maximum automation.

**Transparency:** Generated code is visible and committed to version control.

**Simplicity:** Base R parsing, no complex dependencies.

**Flexibility:** Manual targets available for complex cases.

## Limitations

- Only top-level assignments are parsed
- Function arguments must match existing target names exactly
- No support for dynamic/branching targets (use manual targets)
- No built-in file watching (future feature)

## License

MIT

## Related Projects

- [targets](https://docs.ropensci.org/targets/) - The underlying pipeline toolkit
- [tarchetypes](https://docs.ropensci.org/tarchetypes/) - Target archetypes for common patterns
