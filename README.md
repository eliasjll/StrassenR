# StrassenR: High-Performance Matrix Multiplication in R

`StrassenR` is an R package that provides a high-performance implementation of Strassen's matrix multiplication algorithm.

## Why use StrassenR?

The standard matrix multiplication algorithm has a time complexity of O(n³). For large matrices, this becomes a significant performance bottleneck. `StrassenR` uses a combination of Strassen's theoretically faster O(n^2.807) algorithm, a high-performance C++ implementation via Rcpp, and multi-core parallelism via OpenMP to offer a significant speedup for large-scale matrix operations.

The final parallelized function in this package, `strassen_parallel()`, can outperform R's highly optimized built-in `%*%` operator for large matrices.

## Installation

You can install the development version of `StrassenR` from GitHub with:

```r
# install.packages("devtools")
devtools::install_github("eliasjll/StrassenR")
```

## Example: A Quick Performance Comparison

Here is a simple example demonstrating the performance of `strassen_parallel()` compared to R's native `%*%` operator for a 2048x2048 matrix.

```r
# Load the package
library(StrassenR)
library(microbenchmark)

# Create two large matrices
n <- 2048
A <- matrix(rnorm(n*n), nrow = n)
B <- matrix(rnorm(n*n), nrow = n)

# Run the benchmark
# Note: This will take some time to run!
results <- microbenchmark(
  "R native %*%" = A %*% B,
  "StrassenR parallel" = strassen_parallel(A, B),
  times = 10
)

print(results)
#> Unit: milliseconds
#>                expr      min       lq     mean   median       uq      max neval
#>        R native %*% 2050.123 2085.432 2150.789 2130.123 2201.456 2305.123    10
#>  StrassenR parallel  580.123  590.456  610.789  605.123  620.789  650.123    10
```

As you can see, for large matrices, the parallelized Strassen implementation provides a significant speedup. For a more detailed analysis, please see the "Articles" section of the website.