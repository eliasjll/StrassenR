# This script projects the performance of matrix multiplication algorithms
# for large matrix sizes and plots the results, including crossover points.

# --- 1. Setup ---
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("dplyr")) install.packages("dplyr")
if (!require("scales")) install.packages("scales")

library(ggplot2)
library(dplyr)
library(scales)

# --- 2. Full Benchmark Data ---
# Contains the mean execution times (in ms) from the latest benchmarks.
benchmark_data <- data.frame(
  size = rep(c(32, 64, 128, 256, 512, 1024, 2048), each = 5),
  expr = rep(c("Naive_R", "Naive_C++", "Strassen", "Hybrid_Strassen", "Parallel"), times = 7),
  mean_ms = c(
    # N=32
    0.0104386, 0.3272866, 1.6412013, 0.0449032, 0.0655385,
    # N=64
    0.0770144, 2.4937799, 11.3856672, 0.1088632, 0.1117086,
    # N=128
    0.5715605, 19.0984847, 78.8592237, 0.6979594, 0.5916341,
    # N=256
    4.285029, 154.674587, 564.201988, 5.083725, 3.648057,
    # N=512
    33.48145, 1261.93359, 3962.33600, 35.10584, 17.31405,
    # N=1024
    272.11019, 10227.55711, 28779.20572, 271.65283, 98.47537,
    # N=2048
    2231.4327, 119661.3544, 204754.2388, 1945.6866, 595.6986
  )
)

# --- 3. Performance Modeling (Two-Model Approach) ---
# Define complexity exponents
complexity_exponents <- data.frame(
  expr = c("Naive_R", "Naive_C++", "Strassen", "Hybrid_Strassen", "Parallel"),
  complexity = c(3, 3, 2.807, 2.807, 2.807)
)

# --- 3a. Model for Crossover Calculation (using all data) ---
print("Calculating models for crossover point based on all data...")
models_for_crossover <- benchmark_data %>%
  left_join(complexity_exponents, by = "expr") %>%
  group_by(expr) %>%
  do({
    current_data <- .
    current_complexity <- unique(current_data$complexity)
    fit <- lm(log(mean_ms) ~ offset(current_complexity * log(size)), data = current_data)
    log_C <- coef(fit)[["(Intercept)"]]
    data.frame(
      complexity = current_complexity,
      constant_C = exp(log_C)
    )
  }) %>%
  ungroup()

# --- 3b. Model for Plotting (for a smooth visual transition) ---
print("Calculating models for plotting based on n=2048 data...")
cal_size <- 2048
cal_data <- benchmark_data %>% filter(size == cal_size)
models_for_plotting <- cal_data %>%
  left_join(complexity_exponents, by = "expr") %>%
  mutate(constant_C = mean_ms / (cal_size^complexity)) %>%
  select(expr, complexity, constant_C)

# --- 4. Projection (Using the plotting model) ---
# Project performance for matrix sizes beyond 2048x2048
projection_sizes_model <- 2^(12:14) # 4096, 8192, 16384

# Create a data frame with the projected times for these larger sizes
projected_df_model <- expand.grid(expr = models_for_plotting$expr, size = projection_sizes_model) %>%
  left_join(models_for_plotting, by = "expr") %>%
  mutate(projected_time_ms = constant_C * (size^complexity)) %>%
  select(expr, size, projected_time_ms)

# --- 5. Calculate Crossover Points (Using the crossover model) ---
c_hybrid_crossover <- models_for_crossover$constant_C[models_for_crossover$expr == "Hybrid_Strassen"]
k_hybrid_crossover <- models_for_crossover$complexity[models_for_crossover$expr == "Hybrid_Strassen"]
c_naive_r_crossover <- models_for_crossover$constant_C[models_for_crossover$expr == "Naive_R"]
k_naive_r_crossover <- models_for_crossover$complexity[models_for_crossover$expr == "Naive_R"]
crossover_hybrid_vs_r <- (c_naive_r_crossover / c_hybrid_crossover)^(1 / (k_hybrid_crossover - k_naive_r_crossover))

c_parallel_crossover <- models_for_crossover$constant_C[models_for_crossover$expr == "Parallel"]
k_parallel_crossover <- models_for_crossover$complexity[models_for_crossover$expr == "Parallel"]
crossover_parallel_vs_r <- (c_naive_r_crossover / c_parallel_crossover)^(1 / (k_parallel_crossover - k_naive_r_crossover))

print("Calculated Crossover Points (based on all data):")
print(paste("Hybrid_Strassen should beat Naive R at n =", round(crossover_hybrid_vs_r)))
print(paste("Parallel should beat Naive R at n =", round(crossover_parallel_vs_r)))

# --- 6. Plotting (Using the plotting model) ---
# Convert all times from milliseconds to seconds for plotting
benchmark_data$time_sec <- benchmark_data$mean_ms / 1000
projected_df_model$time_sec <- projected_df_model$projected_time_ms / 1000

# Combine actual benchmark data and projected data for plotting lines
plot_lines_df <- benchmark_data %>%
  filter(size <= 2048) %>%
  select(expr, size, time_sec) %>%
  bind_rows(projected_df_model %>% select(expr, size, time_sec))

# Data for plotting the points
plot_benchmark_df <- benchmark_data

# Custom labels for y-axis
time_labels <- function(x) {
  sapply(x, function(y) {
    if (is.na(y)) return(NA)
    if (y < 1) return(paste(round(y * 1000), "ms"))
    if (y < 60) return(paste(round(y, 1), "s"))
    if (y < 3600) return(paste(round(y / 60, 1), "min"))
    return(paste(round(y / 3600, 1), "hr"))
  })
}

# Create the plot
projection_plot <- ggplot(plot_lines_df, aes(x = size, y = time_sec, color = expr)) +
  geom_line(linewidth = 1.2, aes(linetype = "Projected")) +
  geom_point(data = plot_benchmark_df, aes(shape = "Actual"), size = 4, alpha = 0.8) +
  
  # Add vertical line and annotation for Parallel C++ crossover
  geom_vline(xintercept = crossover_parallel_vs_r, linetype = "dashed", color = "grey40") +
  annotate("text", x = crossover_parallel_vs_r * 0.9, y = 0.1,
           label = paste("Parallel > Naive R\n(n =", round(crossover_parallel_vs_r), ")"),
           hjust = 1, color = "grey20", size = 4) +
  
  # Add vertical line and annotation for Hybrid C++ crossover
  geom_vline(xintercept = crossover_hybrid_vs_r, linetype = "dashed", color = "grey40") +
  annotate("text", x = crossover_hybrid_vs_r * 0.9, y = 0.01,
           label = paste("Hybrid_Strassen > Naive R\n(n =", round(crossover_hybrid_vs_r), ")"),
           hjust = 1, color = "grey20", size = 4) +
  
  scale_x_log10(breaks = c(2^(5:11), projection_sizes_model), labels = scales::comma) +
  scale_y_log10(breaks = 10^seq(-3, 5, by = 1), labels = time_labels) +
  
  labs(
    title = "Projected vs. Actual Performance of Matrix Multiplication Algorithms",
    subtitle = "Actual data up to 2048x2048, then projections calibrated at n=2048 for visual smoothness",
    x = "Matrix Size (n x n) - Log Scale",
    y = "Execution Time - Log Scale",
    color = "Algorithm",
    shape = "Data Type",
    linetype = "Data Type"
  ) +
  scale_shape_manual(values = c("Actual" = 19)) +
  scale_linetype_manual(values = c("Projected" = 1)) +
  theme_minimal(base_size = 14) +
  theme(legend.position = "bottom", legend.box = "horizontal")

# Save the plot
ggsave("projection_plot.png", plot = projection_plot, width = 12, height = 8, dpi = 300)

cat("\nProjection plot saved to projection_plot.png\n")
