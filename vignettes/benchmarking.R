# This script is for benchmarking the Strassen matrix multiplication implementations.

# --- 1. Setup ---

# Install packages if not already installed
if (!require("microbenchmark")) {
  install.packages("microbenchmark")
}
if (!require("ggplot2")) {
  install.packages("ggplot2")
}
if (!require("dplyr")) {
  install.packages("dplyr")
}
library(microbenchmark)
library(ggplot2)
library(dplyr)

# Load the C++ functions
# This will compile and load all functions in strassen_rcpp.cpp
# The ~/.R/Makevars file will ensure it is compiled with OpenMP
Rcpp::sourceCpp("src/strassen_rcpp.cpp")


# --- 2. Benchmarking Configuration ---

# Define the matrix sizes (powers of 2) you want to test
matrix_sizes <- c(32, 64, 128, 256, 512, 1024, 2048)

# We will use the optimal threshold of 64 found in the previous step
optimal_threshold <- 64

# Create a list to store the results
all_results <- list()


# --- 3. Running the Benchmarks ---

cat("Starting final performance benchmarks...\n")

for (size in matrix_sizes) {
  cat(paste("\n--- Benchmarking for matrix size:", size, "x", size, "---\n"))

  # Create random matrices for testing
  A <- matrix(rnorm(size * size), nrow = size, ncol = size)
  B <- matrix(rnorm(size * size), nrow = size, ncol = size)

  # Run the benchmark for the current matrix size
  benchmark_results <- microbenchmark(
    "Naive_R" = A %*% B,
    "Naive_C++" = naive_rcpp_multiply(A, B),
    "Pure_Strassen" = strassen_pure_recursive(A, B),
    "Hybrid_C++" = strassen_hybrid(A, B, threshold = optimal_threshold),
    "Parallel_C++" = strassen_parallel(A, B, threshold = optimal_threshold),
    times = 10L,
    unit = "ms"
  )

  # Store and print the results for this size
  all_results[[as.character(size)]] <- benchmark_results
  print(benchmark_results)
}

cat("\n--- All benchmarks complete. ---\n")


# --- 4. Process and Plot Results ---

cat("Generating plot...\n")

# Combine all benchmark results into a single data frame
results_df <- do.call(rbind, lapply(names(all_results), function(size) {
  data.frame(
    size = as.integer(size),
    expr = all_results[[size]]$expr,
    time = all_results[[size]]$time
  )
}))

# Calculate the mean time for each expression and size
summary_df <- results_df %>%
  group_by(size, expr) %>%
  summarise(mean_time = mean(time / 1e6)) # Convert nanoseconds to milliseconds

# Create the plot
performance_plot <- ggplot(summary_df, aes(x = size, y = mean_time, color = expr, group = expr)) +
  geom_line() +
  geom_point() +
  scale_y_log10(breaks = 10^seq(-3, 4), labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  scale_x_continuous(breaks = matrix_sizes) +
  labs(
    title = "Performance Comparison of Matrix Multiplication Algorithms",
    subtitle = "Execution time in milliseconds (log scale)",
    x = "Matrix Size (n x n)",
    y = "Mean Execution Time (ms)",
    color = "Algorithm"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

# Save the plot
ggsave("performance_comparison.png", plot = performance_plot, width = 10, height = 6)

cat("Plot saved to performance_comparison.png\n")

