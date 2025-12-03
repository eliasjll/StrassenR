#include <Rcpp.h>
#include <vector>
#include <algorithm>
#include <omp.h>

// --- Native C++ Core ---
// This entire section is pure C++ and has no knowledge of R or Rcpp.
// This is the key to making the parallel code thread-safe.
// We use std::vector<double> to represent matrices in row-major order.

// Forward declaration for the native recursive function
void native_strassen_recursive(const std::vector<double>& A, const std::vector<double>& B, std::vector<double>& C, int n, int threshold, bool parallelize);

// Native Naive Multiplication
void native_naive_multiply(const std::vector<double>& A, const std::vector<double>& B, std::vector<double>& C, int n) {
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            double sum = 0.0;
            for (int k = 0; k < n; ++k) {
                sum += A[i * n + k] * B[k * n + j];
            }
            C[i * n + j] = sum;
        }
    }
}

// Native Matrix Addition/Subtraction
void native_matrix_op(const std::vector<double>& A, const std::vector<double>& B, std::vector<double>& C, int n, bool add) {
    for (int i = 0; i < n * n; ++i) {
        C[i] = add ? (A[i] + B[i]) : (A[i] - B[i]);
    }
}

// Native Strassen's Algorithm
void native_strassen_recursive(const std::vector<double>& A, const std::vector<double>& B, std::vector<double>& C, int n, int threshold, bool parallelize) {
    if (n <= threshold) {
        native_naive_multiply(A, B, C, n);
        return;
    }

    int mid = n / 2;
    int new_size = mid * mid;

    std::vector<double> A11(new_size), A12(new_size), A21(new_size), A22(new_size);
    std::vector<double> B11(new_size), B12(new_size), B21(new_size), B22(new_size);

    for (int i = 0; i < mid; ++i) {
        for (int j = 0; j < mid; ++j) {
            A11[i * mid + j] = A[i * n + j];
            A12[i * mid + j] = A[i * n + j + mid];
            A21[i * mid + j] = A[(i + mid) * n + j];
            A22[i * mid + j] = A[(i + mid) * n + j + mid];

            B11[i * mid + j] = B[i * n + j];
            B12[i * mid + j] = B[i * n + j + mid];
            B21[i * mid + j] = B[(i + mid) * n + j];
            B22[i * mid + j] = B[(i + mid) * n + j + mid];
        }
    }

    std::vector<double> M1(new_size), M2(new_size), M3(new_size), M4(new_size), M5(new_size), M6(new_size), M7(new_size);

    if (parallelize) {
        std::vector<double> S1(new_size), S2(new_size), S3(new_size), S4(new_size), S5(new_size), S6(new_size), S7(new_size), S8(new_size), S9(new_size), S10(new_size);
        native_matrix_op(A11, A22, S1, mid, true);
        native_matrix_op(B11, B22, S2, mid, true);
        native_matrix_op(A21, A22, S3, mid, true);
        native_matrix_op(B12, B22, S4, mid, false);
        native_matrix_op(B21, B11, S5, mid, false);
        native_matrix_op(A11, A12, S6, mid, true);
        native_matrix_op(A21, A11, S7, mid, false);
        native_matrix_op(B11, B12, S8, mid, true);
        native_matrix_op(A12, A22, S9, mid, false);
        native_matrix_op(B21, B22, S10, mid, true);

        #pragma omp parallel
        {
            #pragma omp single
            {
                #pragma omp task
                native_strassen_recursive(S1, S2, M1, mid, threshold, false);
                #pragma omp task
                native_strassen_recursive(S3, B11, M2, mid, threshold, false);
                #pragma omp task
                native_strassen_recursive(A11, S4, M3, mid, threshold, false);
                #pragma omp task
                native_strassen_recursive(A22, S5, M4, mid, threshold, false);
                #pragma omp task
                native_strassen_recursive(S6, B22, M5, mid, threshold, false);
                #pragma omp task
                native_strassen_recursive(S7, S8, M6, mid, threshold, false);
                #pragma omp task
                native_strassen_recursive(S9, S10, M7, mid, threshold, false);
            }
        }
    } else {
        std::vector<double> S1(new_size), S2(new_size);
        native_matrix_op(A11, A22, S1, mid, true);
        native_matrix_op(B11, B22, S2, mid, true);
        native_strassen_recursive(S1, S2, M1, mid, threshold, false);

        native_matrix_op(A21, A22, S1, mid, true);
        native_strassen_recursive(S1, B11, M2, mid, threshold, false);

        native_matrix_op(B12, B22, S1, mid, false);
        native_strassen_recursive(A11, S1, M3, mid, threshold, false);

        native_matrix_op(B21, B11, S1, mid, false);
        native_strassen_recursive(A22, S1, M4, mid, threshold, false);

        native_matrix_op(A11, A12, S1, mid, true);
        native_strassen_recursive(S1, B22, M5, mid, threshold, false);

        native_matrix_op(A21, A11, S1, mid, false);
        native_matrix_op(B11, B12, S2, mid, true);
        native_strassen_recursive(S1, S2, M6, mid, threshold, false);

        native_matrix_op(A12, A22, S1, mid, false);
        native_matrix_op(B21, B22, S2, mid, true);
        native_strassen_recursive(S1, S2, M7, mid, threshold, false);
    }

    std::vector<double> C11(new_size), C12(new_size), C21(new_size), C22(new_size);
    native_matrix_op(M1, M4, C11, mid, true);
    native_matrix_op(C11, M5, C11, mid, false);
    native_matrix_op(C11, M7, C11, mid, true);

    native_matrix_op(M3, M5, C12, mid, true);

    native_matrix_op(M2, M4, C21, mid, true);

    native_matrix_op(M1, M3, C22, mid, true);

    native_matrix_op(C22, M2, C22, mid, false);
    native_matrix_op(C22, M6, C22, mid, true);

    for (int i = 0; i < mid; ++i) {
        for (int j = 0; j < mid; ++j) {
            C[i * n + j] = C11[i * mid + j];
            C[i * n + j + mid] = C12[i * mid + j];
            C[(i + mid) * n + j] = C21[i * mid + j];
            C[(i + mid) * n + j + mid] = C22[i * mid + j];
        }
    }
}

// --- Rcpp Wrapper Functions ---
// These are the bridges between R and the native C++ code.

// Helper to find the next power of 2
int next_power_of_2(int n) {
  if (n > 0 && (n & (n - 1)) == 0) return n;
  int p = 1;
  while (p < n) p <<= 1;
  return p;
}

// Generic internal wrapper to reduce code duplication
Rcpp::NumericMatrix strassen_internal_wrapper(Rcpp::NumericMatrix A, Rcpp::NumericMatrix B, int threshold, bool parallelize) {
    int n_orig = A.nrow();
    int p_orig = A.ncol();
    int m_orig = B.ncol();

    if (p_orig != B.nrow()) {
        Rcpp::stop("Incompatible matrix dimensions.");
    }

    int max_dim = std::max({n_orig, p_orig, m_orig});
    int padded_size = next_power_of_2(max_dim);

    std::vector<double> A_pad(padded_size * padded_size, 0.0);
    std::vector<double> B_pad(padded_size * padded_size, 0.0);

    for (int i = 0; i < n_orig; ++i) {
        for (int j = 0; j < p_orig; ++j) {
            A_pad[i * padded_size + j] = A(i, j);
        }
    }
    for (int i = 0; i < p_orig; ++i) {
        for (int j = 0; j < m_orig; ++j) {
            B_pad[i * padded_size + j] = B(i, j);
        }
    }

    std::vector<double> C_pad(padded_size * padded_size);
    native_strassen_recursive(A_pad, B_pad, C_pad, padded_size, threshold, parallelize);

    Rcpp::NumericMatrix C(n_orig, m_orig);
    for (int i = 0; i < n_orig; ++i) {
        for (int j = 0; j < m_orig; ++j) {
            C(i, j) = C_pad[i * padded_size + j];
        }
    }

    return C;
}

//' Parallel Strassen's Matrix Multiplication
//'
//' Computes the matrix product of two matrices using a parallelized, hybrid
//' version of Strassen's algorithm. This is the fastest implementation in the
//' package for large matrices. It uses a threshold to switch to a naive
//' algorithm for smaller sub-problems and OpenMP to parallelize the recursive calls.
//'
//' @param A A numeric matrix.
//' @param B A numeric matrix.
//' @param threshold The matrix size at which the algorithm switches from Strassen's
//'   recursion to a naive multiplication. Defaults to 64.
//' @return The matrix product of A and B.
//' @export
// [[Rcpp::export]]
Rcpp::NumericMatrix strassen_parallel(Rcpp::NumericMatrix A, Rcpp::NumericMatrix B, int threshold = 64) {
    return strassen_internal_wrapper(A, B, threshold, true);
}

//' Hybrid Strassen's Matrix Multiplication (Sequential)
//'
//' Computes the matrix product of two matrices using a sequential, hybrid
//' version of Strassen's algorithm. It uses a threshold to switch to a naive
//' algorithm for smaller sub-problems but does not use parallel processing.
//'
//' @param A A numeric matrix.
//' @param B A numeric matrix.
//' @param threshold The matrix size at which the algorithm switches from Strassen's
//'   recursion to a naive multiplication. Defaults to 64.
//' @return The matrix product of A and B.
//' @export
// [[Rcpp::export]]
Rcpp::NumericMatrix strassen_hybrid(Rcpp::NumericMatrix A, Rcpp::NumericMatrix B, int threshold = 64) {
    return strassen_internal_wrapper(A, B, threshold, false);
}

//' Pure Strassen's Matrix Multiplication (Recursive)
//'
//' Computes the matrix product of two matrices using the classic, pure
//' recursive Strassen's algorithm. This function is provided for educational
//' and benchmarking purposes to demonstrate the high overhead of recursion
//' without a hybrid strategy. It recurses down to a 1x1 matrix.
//'
//' @param A A numeric matrix.
//' @param B A numeric matrix.
//' @return The matrix product of A and B.
//' @export
// [[Rcpp::export]]
Rcpp::NumericMatrix strassen_pure_recursive(Rcpp::NumericMatrix A, Rcpp::NumericMatrix B) {
    return strassen_internal_wrapper(A, B, 1, false);
}

//' Naive Matrix Multiplication (C++)
//'
//' Computes the matrix product of two matrices using a simple, three-loop
//' naive algorithm in C++. This function is provided for educational and
//' benchmarking purposes.
//'
//' @param A A numeric matrix.
//' @param B A numeric matrix.
//' @return The matrix product of A and B.
//' @export
// [[Rcpp::export]]
Rcpp::NumericMatrix naive_rcpp_multiply(Rcpp::NumericMatrix A, Rcpp::NumericMatrix B) {
    int n = A.nrow();
    int m = B.ncol();
    if (A.ncol() != B.nrow()) {
        Rcpp::stop("Incompatible matrix dimensions.");
    }
    Rcpp::NumericMatrix C(n, m);
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < m; ++j) {
            double sum = 0.0;
            for (int k = 0; k < A.ncol(); ++k) {
                sum += A(i, k) * B(k, j);
            }
            C(i, j) = sum;
        }
    }
    return C;
}