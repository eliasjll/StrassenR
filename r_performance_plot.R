# This script benchmarks R's native matrix multiplication (%*%) 
# for various matrix sizes and generates a performance plot.

# --- 1. Setup ---
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("microbenchmark")) install.packages("microbenchmark")
if (!require("dplyr")) install.packages("dplyr")

library(ggplot2)
library(microbenchmark)
library(dplyr)

# --- 2. Benchmarking ---
# Define the matrix sizes to test (e.g., 32x32, 64x64, ..., 2048x2048)
matrix_sizes <- 2^(5:11)

# Create a list to store benchmark results
results_list <- list()

cat("Starting benchmarks for R's native matrix multiplication (%*%) (powers of 2 up to 2048)\n")

for (n in matrix_sizes) {
  cat(paste("Benchmarking size:", n, "x", n, "\n"))
  
  # Create two random matrices of size n x n
  mat_a <- matrix(rnorm(n*n), nrow = n)
  mat_b <- matrix(rnorm(n*n), nrow = n)
  
  # Run the benchmark
  mb_result <- microbenchmark(
    mat_a %*% mat_b,
    times = 10
  )
  
  # Store the median time in milliseconds
  results_list[[as.character(n)]] <- data.frame(
    size = n,
    median_ms = median(mb_result$time) / 1e6 # Get median from raw times and convert ns to ms
  )
}

# Combine all results into a single data frame
benchmark_results <- do.call(rbind, results_list)

print("Benchmark Results (median time in ms):")
print(benchmark_results)

# --- 3. Plotting ---
# Convert time to seconds for better labeling on the plot
benchmark_results$time_sec <- benchmark_results$median_ms / 1000

# Custom labels for y-axis to show minutes/hours if needed
time_labels <- function(x) {
  sapply(x, function(y) {
    if (is.na(y)) return(NA)
    ms <- y * 1000
    if (ms < 1) return(paste(sprintf("%.2f", ms), "ms")) # Show decimals for sub-millisecond times
    if (y < 1) return(paste(round(ms), "ms"))
    if (y < 60) return(paste(round(y, 1), "s"))
    if (y < 3600) return(paste(round(y / 60, 1), "min"))
    return(paste(round(y / 3600, 1), "hr"))
  })
}

# Create the plot
r_perf_plot <- ggplot(benchmark_results, aes(x = size, y = time_sec)) +
  geom_line(color = "blue", linewidth = 1.2) +
  geom_point(color = "blue", size = 4, alpha = 0.8) +
  
  # Use linear scale for x-axis
  scale_x_continuous(breaks = matrix_sizes, labels = scales::comma) +
  scale_y_log10(labels = time_labels) +
  
  # Labels and Theming
  labs(
    title = "Performance of R's Native Matrix Multiplication (%*%)",
    subtitle = "Performance measured across various matrix sizes",
    x = "Matrix Size (n x n)",
    y = "Median Execution Time - Log Scale"
  ) +
  theme_minimal(base_size = 14)

# Save the plot
ggsave("r_performance.png", plot = r_perf_plot, width = 12, height = 8, dpi = 300)

cat("\nPerformance plot saved to r_performance.png\n")
