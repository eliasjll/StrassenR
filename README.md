# StrassenR: A GenAI-Assisted Rcpp Tutorial
This repository contains the `StrassenR` package, which implements Strassen's matrix multiplication algorithm. It also serves as an educational tutorial on how to use Generative AI (GenAI) to build high-performance R packages using Rcpp, especially with no prior C++ experience.

## Development Log & Tutorial

### Week 1: Project Setup and Rcpp Configuration

My first goal was to set up the project and confirm Rcpp was working. As someone new to C++, I'm using Google's Gemini to guide my process.

**GenAI Prompt (to Gemini):**
> "I need to start my Biostatistics 615 final project. My 'Week 1' tasks are: finalize scope and set up GitHub, create the R package structure, install and configure Rcpp, and begin a development log. Can you give me a step-by-step plan?"

This prompt led to the initial setup of this repository, the R package structure, and the Rcpp installation.

To confirm the setup, I used the following command in my R console as suggested:

Rcpp::evalCpp("1 + 1")

It returned `[1] 2`, confirming that R can successfully compile and run C++ code. The should now be ready.



## Week 2: Pure R Implementations

This week, I implemented the two pure R functions that will serve as the foundation for the project.

1.  **`naive_multiply(A, B)`:** A simple O(n^3) triple-loop function. This will be the baseline to check for correctness and to compare against for performance.
2.  **`strassen_r(A, B)`:** A pure R implementation of Strassen's algorithm. For this version, I focused only on the "perfect" case: square matrices with dimensions 2^n times 2^n. This simplified the logic immensely, as I didn't need to worry about padding.

**GenAI Interaction:**
I used Gemini to help structure the `strassen_r` function.

**Prompt:**
> "I need to write a pure R function for Strassen's algorithm. It should be recursive. Can you give me the basic structure, assuming the input matrices A and B are always square and have dimensions that are a power of 2 (e.g., 2x2, 4x4)?"

The AI-provided code was a great starting point. It correctly identified the base case (where `n == 1`) and laid out the 4 steps:
1.  Partition matrices.
2.  Calculate the 7 M-products recursively.
3.  Calculate the 4 C-sub-matrices.
4.  Combine the C-sub-matrices using `rbind` and `cbind`.

I then tested both functions against R's built-in `%*%` operator on $2 \times 2$ and $4 \times 4$ matrices, and `all.equal()` confirmed the results were correct. Next week, I'll move this logic to Rcpp.


#Week 3: R-to-Rcpp Translation

This week, I used GenAI to translate my strassen_r function into C++ using Rcpp. This was a two-step debugging process.
GenAI Interaction (Part 1: C++ Errors): My first prompt to translate the R code gave C++ that failed to compile. R's matrix math (A+B) and splitting (A[1:mid,]) don't exist in C++.
Prompt:
"I got a compiler error: error: no matching function for call to object of type 'const NumericMatrix'... How do I fix this?"
After a few prompts, the AI helped me write C++ helper functions (matrix_add) and use manual for loops to partition the matrices. This new code compiled perfectly!

GenAI Interaction (Part 2): When I tested the compiled code, I got a new, "phantom" error: Error in .Call(...) not available. R couldn't find my compiled function, even though it built.
Prompt:
"My C++ code compiles, but I get a .Call() not available error. How can I diagnose if the problem is my code or the build system?"
This was the key. The AI suggested a "Canary Test" (a simple add_one function) which failed the same way, proving my Strassen code was innocent. We then found the "smoking gun" by checking R's build files.
The Fix: I ran readLines("NAMESPACE") and it was empty. It was missing the critical useDynLib(StrassenR) line. The AI told me to run devtools::document(), which rebuilt the NAMESPACE file correctly. After that, devtools::load_all() worked, and all my tests passed.