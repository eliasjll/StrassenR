# 2x2 test
A2 <- matrix(c(1, 2, 3, 4), nrow = 2, byrow = TRUE)
B2 <- matrix(c(5, 6, 7, 8), nrow = 2, byrow = TRUE)

# 4x4 test
A4 <- matrix(runif(16), nrow = 4)
B4 <- matrix(runif(16), nrow = 4)


# --- Test 2x2 ---
# R's built-in
C_builtin_2 <- A2 %*% B2

# Your naive function
C_naive_2 <- naive_multiply(A2, B2)

# Your Strassen function
C_strassen_2 <- strassen_r(A2, B2)

# Check if they are (all) "close"
print("2x2 Test Results:")
print(C_builtin_2)
print(C_naive_2)
print(C_strassen_2)
all.equal(C_builtin_2, C_naive_2)
all.equal(C_builtin_2, C_strassen_2)


# --- Test 4x4 ---
C_builtin_4 <- A4 %*% B4
C_naive_4 <- naive_multiply(A4, B4)
C_strassen_4 <- strassen_r(A4, B4)

print("4x4 Test Results:")
all.equal(C_builtin_4, C_naive_4)
all.equal(C_builtin_4, C_strassen_4)