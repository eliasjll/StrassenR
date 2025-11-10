#install.packages("devtools")
#install.packages("usethis")
library("devtools")
library("Rcpp")
library("usethis")
#usethis::use_description()
#usethis::use_package("Rcpp")
#usethis::use_rcpp("strassen_utils")

# Naive O(n^3) matrix multiplication method
naive_multiply <- function(A, B) {
  # Check for compatible dimensions
  if (ncol(A) != nrow(B)) {
    stop("Incompatible matrix dimensions: ncol(A) must equal nrow(B).")
  }
  
  # Get dimensions
  n <- nrow(A)
  m <- ncol(B)
  p <- ncol(A)
  
  # Initialize the result matrix with zeros
  C <- matrix(0, nrow = n, ncol = m)
  
  # Perform the triple-loop multiplication
  for (i in 1:n) {
    for (j in 1:m) {
      # Calculate the dot product for C[i, j]
      sum <- 0
      for (k in 1:p) {
        sum <- sum + A[i, k] * B[k, j]
      }
      C[i, j] <- sum
    }
  }
  
  return(C)
}

# Strassen's Matrix Multiplication (Pure R)
strassen_r <- function(A, B) {
  
  n <- nrow(A)
  
  # --- Base Case ---
  # If the matrix is 1x1, just do simple multiplication.
  if (n == 1) {
    # We still return a 1x1 matrix, not a scalar
    return(matrix(A[1, 1] * B[1, 1])) 
  }
  
  # --- Recursive Step ---
  
  # Find the midpoint
  mid <- n / 2
  
  # 1. Partition matrices A and B
  # Added 'drop = FALSE' to every subset to preserve dimensions
  A11 <- A[1:mid, 1:mid, drop = FALSE]
  A12 <- A[1:mid, (mid + 1):n, drop = FALSE]
  A21 <- A[(mid + 1):n, 1:mid, drop = FALSE]
  A22 <- A[(mid + 1):n, (mid + 1):n, drop = FALSE]
  
  B11 <- B[1:mid, 1:mid, drop = FALSE]
  B12 <- B[1:mid, (mid + 1):n, drop = FALSE]
  B21 <- B[(mid + 1):n, 1:mid, drop = FALSE]
  B22 <- B[(mid + 1):n, (mid + 1):n, drop = FALSE]
  
  # 2. Calculate the 7 products (M1-M7) recursively
  M1 <- strassen_r(A11 + A22, B11 + B22)
  M2 <- strassen_r(A21 + A22, B11)
  M3 <- strassen_r(A11, B12 - B22)
  M4 <- strassen_r(A22, B21 - B11)
  M5 <- strassen_r(A11 + A12, B22)
  M6 <- strassen_r(A21 - A11, B11 + B12)
  M7 <- strassen_r(A12 - A22, B21 + B22)
  
  # 3. Calculate result sub-matrices (C11, C12, C21, C22)
  C11 <- M1 + M4 - M5 + M7
  C12 <- M3 + M5
  C21 <- M2 + M4
  C22 <- M1 - M2 + M3 + M6
  
  # 4. Combine sub-matrices into the final result matrix C
  C_top <- cbind(C11, C12)
  C_bottom <- cbind(C21, C22)
  C <- rbind(C_top, C_bottom)
  
  return(C)
}