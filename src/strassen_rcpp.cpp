#include <algorithm> // For std::max
#include <Rcpp.h>
using namespace Rcpp;

// --- Matrix Arithmetic Helper Functions ---

// Helper function for matrix addition
// Now takes const references (&) for efficiency (avoids copies)
NumericMatrix matrix_add(const NumericMatrix& A, const NumericMatrix& B) {
  int n = A.nrow();
  int m = A.ncol();
  NumericMatrix C(n, m);

  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      C(i, j) = A(i, j) + B(i, j);
    }
  }
  return C;
}

// Helper function for matrix subtraction
// Now takes const references (&) for efficiency
NumericMatrix matrix_subtract(const NumericMatrix& A, const NumericMatrix& B) {
  int n = A.nrow();
  int m = A.ncol();
  NumericMatrix C(n, m);

  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      C(i, j) = A(i, j) - B(i, j);
    }
  }
  return C;
}

// --- Helper function to find the next power of 2 ---
// (Not exported to R)
int next_power_of_2(int n) {
  // If n is already a power of 2, return it
  if (n > 0 && (n & (n - 1)) == 0) {
    return n;
  }

  // Decrement n by 1 to handle cases where n is already a power of 2
  // This is a common bit-twiddling trick.
  n--;

  // Set all bits to the right of the most significant bit to 1
  n |= n >> 1;
  n |= n >> 2;
  n |= n >> 4;
  n |= n >> 8;
  n |= n >> 16; // Works for 32-bit integers

  // Increment by 1 to get the next power of 2
  n++;

  return n;
}


// --- Strassen's Algorithm (Internal) ---

// This is the internal C++ recursive function.
// It is NOT exported to R.
// It takes const references for efficiency during recursion.
NumericMatrix strassen_recursive(const NumericMatrix& A, const NumericMatrix& B) {

  int n = A.nrow();

  // --- Base Case ---
  if (n == 1) {
    NumericMatrix C(1, 1);
    C(0, 0) = A(0, 0) * B(0, 0);
    return C;
  }

  // --- Recursive Step ---

  // Find the midpoint
  int mid = n / 2;

  // 1. Partition matrices A and B
  //
  // We manually create new matrices and copy the values.
  // This avoids all 'const' and submatrix 'view' errors.
  //
  NumericMatrix A11(mid, mid); NumericMatrix A12(mid, mid);
  NumericMatrix A21(mid, mid); NumericMatrix A22(mid, mid);
  NumericMatrix B11(mid, mid); NumericMatrix B12(mid, mid);
  NumericMatrix B21(mid, mid); NumericMatrix B22(mid, mid);

  for (int i = 0; i < mid; i++) {
    for (int j = 0; j < mid; j++) {
      // Partition A
      A11(i, j) = A(i, j);
      A12(i, j) = A(i, j + mid);
      A21(i, j) = A(i + mid, j);
      A22(i, j) = A(i + mid, j + mid);

      // Partition B
      B11(i, j) = B(i, j);
      B12(i, j) = B(i, j + mid);
      B21(i, j) = B(i + mid, j);
      B22(i, j) = B(i + mid, j + mid);
    }
  }

  // 2. Calculate the 7 products (M1-M7) recursively
  // (Now calling this internal 'strassen_recursive' function)
  NumericMatrix M1 = strassen_recursive(matrix_add(A11, A22), matrix_add(B11, B22));
  NumericMatrix M2 = strassen_recursive(matrix_add(A21, A22), B11);
  NumericMatrix M3 = strassen_recursive(A11, matrix_subtract(B12, B22));
  NumericMatrix M4 = strassen_recursive(A22, matrix_subtract(B21, B11));
  NumericMatrix M5 = strassen_recursive(matrix_add(A11, A12), B22);
  NumericMatrix M6 = strassen_recursive(matrix_subtract(A21, A11), matrix_add(B11, B12));
  NumericMatrix M7 = strassen_recursive(matrix_subtract(A12, A22), matrix_add(B21, B22));

  // 3. Calculate result sub-matrices (C11, C12, C21, C22)
  NumericMatrix C11 = matrix_add(matrix_subtract(matrix_add(M1, M4), M5), M7);
  NumericMatrix C12 = matrix_add(M3, M5);
  NumericMatrix C21 = matrix_add(M2, M4);
  NumericMatrix C22 = matrix_add(matrix_subtract(matrix_add(M1, M3), M2), M6);

  // 4. Combine sub-matrices into the final result matrix C
  NumericMatrix C(n, n);
  for (int i = 0; i < mid; i++) {
    for (int j = 0; j < mid; j++) {
      C(i, j) = C11(i, j);
      C(i, j + mid) = C12(i, j);
      C(i + mid, j) = C21(i, j);
      C(i + mid, j + mid) = C22(i, j);
    }
  }

  return C;
}


// --- Rcpp Exported Wrapper ---
// This is the ONLY function R will see.
// It handles padding and trimming for arbitrary matrix sizes.
// [[Rcpp::export]]
NumericMatrix strassen_rcpp(NumericMatrix A, NumericMatrix B) {

  // 1. Get dimensions
  int n = A.nrow();
  int p = A.ncol();
  int m = B.ncol();

  // Dimension check
  if (p != B.nrow()) {
    stop("Incompatible matrix dimensions: ncol(A) must equal nrow(B).");
  }

  // 2. Find max dimension
  // We use std::max with an initializer list {n, p, m}
  int max_dim = std::max({n, p, m});

  // 3. Find next power of 2
  int k = next_power_of_2(max_dim);

  // --- Handle the trivial 1x1 base case directly ---
  // This avoids padding a 1x1 matrix up to 2x2 and back down
  if (k == 1 && n == 1 && p == 1 && m == 1) {
    NumericMatrix C(1, 1);
    C(0, 0) = A(0, 0) * B(0, 0);
    return C;
  }

  // 4. Create new k x k padded matrices (initialized to zero)
  NumericMatrix A_pad(k, k);
  NumericMatrix B_pad(k, k);

  // 5. Copy A into A_pad
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < p; j++) {
      A_pad(i, j) = A(i, j);
    }
  }

  // 6. Copy B into B_pad
  for (int i = 0; i < p; i++) {
    for (int j = 0; j < m; j++) {
      B_pad(i, j) = B(i, j);
    }
  }

  // 7. Call the recursive engine
  //
  NumericMatrix C_pad = strassen_recursive(A_pad, B_pad);

  // 8. Create the final result matrix
  NumericMatrix C(n, m);

  // 9. Copy (trim) the result from C_pad into C
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      C(i, j) = C_pad(i, j);
    }
  }

  // 10. Return the final, trimmed matrix
  return C;
}
