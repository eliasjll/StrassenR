# This script benchmarks the hybrid Strassen algorithm across a range of 
# threshold values to find the optimal setting for a given matrix size.

# --- 1. Setup ---
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("microbenchmark")) install.packages("microbenchmark")
if (!require("dplyr")) install.packages("dplyr")
if (!require("devtools")) install.packages("devtools")

library(ggplot2)
library(microbenchmark)
library(dplyr)
library(devtools)

# --- 2. Load Package and Define Parameters ---
# Load the StrassenR package functions
load_all()

# Define the parameters for the benchmark
MATRIX_SIZE <- 1024
THRESHOLDS <- 2^(4:8) # Test thresholds 16, 32, 64, 128, 256

# --- 3. Benchmarking ---
# Create a list to store benchmark results
results_list <- list()

cat(paste("Starting hybrid algorithm benchmark for a", MATRIX_SIZE, "x", MATRIX_SIZE, "matrix.\n"))

# Create the matrices once to ensure fair comparison
mat_a <- matrix(rnorm(MATRIX_SIZE * MATRIX_SIZE), nrow = MATRIX_SIZE)
mat_b <- matrix(rnorm(MATRIX_SIZE * MATRIX_SIZE), nrow = MATRIX_SIZE)

for (thresh in THRESHOLDS) {
  cat(paste("Benchmarking threshold:", thresh, "\n"))
  
  # Run the benchmark for the current threshold
  mb_result <- microbenchmark(
    strassen_hybrid(mat_a, mat_b, thresh),
    times = 10
  )
  
  # Store the median time in milliseconds
  results_list[[as.character(thresh)]] <- data.frame(
    threshold = thresh,
    median_ms = median(mb_result$time) / 1e6 # Convert ns to ms
  )
}

# Combine all results into a single data frame
benchmark_results <- do.call(rbind, results_list)

print("Benchmark Results (median time in ms):")
print(benchmark_results)

# --- 4. Find Optimal Threshold ---
optimal_point <- benchmark_results %>%
  filter(median_ms == min(median_ms))

cat("\nOptimal Threshold Found:\n")
print(optimal_point)

# --- 5. Plotting ---
threshold_plot <- ggplot(benchmark_results, aes(x = threshold, y = median_ms)) +
  geom_line(color = "blue", linewidth = 1.2) +
  geom_point(color = "blue", size = 4, alpha = 0.8) +
  
  # Highlight the optimal point
  geom_point(data = optimal_point, aes(x = threshold, y = median_ms), color = "red", size = 6) +
  geom_vline(xintercept = optimal_point$threshold, linetype = "dashed", color = "red") +
  annotate("text", 
           x = optimal_point$threshold, 
           y = optimal_point$median_ms + (0.1 * optimal_point$median_ms), # Position text above the point
           label = paste("Optimal:", optimal_point$threshold),
           color = "red",
           hjust = 0.5) +
  
  # Labels and Theming
  labs(
    title = "Hybrid Algorithm Performance vs. Crossover Threshold",
    subtitle = paste("For a fixed matrix size of", MATRIX_SIZE, "x", MATRIX_SIZE),
    x = "Crossover Threshold (Switch to Naive Algorithm at this size)",
    y = "Median Execution Time (ms)"
  ) +
  theme_minimal(base_size = 14)

# Save the plot
ggsave("threshold_tuning.png", plot = threshold_plot, width = 12, height = 8, dpi = 300)

cat("\nThreshold tuning plot saved to threshold_tuning.png\n")
