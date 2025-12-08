# StrassenR Development Log

This log documents my development of the StrassenR package, with a focus on how I used GenAI to help in the process.

---

## Week 1: Oct 11 - 17 | Project Setup and Foundation

### Goals for this Week:
*   **Goal 1:** Finalize the GitHub repository setup, including `.gitignore`.
*   **Goal 2:** Confirm my R package structure and install necessary tools like `Rcpp` and `devtools`.
*   **Goal 3:** Verify my Rcpp compilation toolchain with a "Hello, World!" example.
*   **Goal 4:** Create and structure this development log.

### Weekly Summary

*   **Progress:** I got all the initial project setup goals done this week. I pushed the project to GitHub, confirmed the R package structure was correct, and installed the necessary tools.
*   **Key Learning:** To make sure my C++ compiler was working with R, I had the AI generate a simple 'Hello, World!' test, which compiled and ran perfectly. The AI was helpful for getting the specific git and R commands right, which let me get the environment set up quickly and confirm everything was working.
*   **Challenges/Blockers:** I didn't run into any significant blockers this week; the setup process was smooth.

---

## Week 2: Oct 18 - 24 | Baseline Implementation in R

### Goals for this Week:
*   **Goal 1:** Implement the naive, triple-nested loop (O(n³)) matrix multiplication function in R as a baseline.
*   **Goal 2:** Implement a pure R version of Strassen's algorithm, focusing on the recursive logic for the "perfect" case (2^n * 2^n matrices).

### Weekly Summary

*   **Progress:** I implemented the first two core functions in pure R: `naive_multiply` as a simple O(n³) baseline, and `strassen_r` for the recursive logic. I tested both against R's built-in `%*%` and confirmed they were correct for small matrices.
*   **Key Learning:** I asked the AI for help structuring the `strassen_r` function for the simplified case of power-of-two square matrices. It gave me a great starting point that laid out the main steps: partitioning the matrices, calculating the 7 products recursively, and then combining the results. This was a big help in getting the core logic down.
*   **Challenges/Blockers:** No major blockers. Focusing on the "perfect" case for the Strassen implementation made it much easier to get started without worrying about edge cases like padding.

---

## Week 3: Oct 25 - 31 | Core Rcpp Implementation

### Goals for this Week:
*   **Goal 1:** Use GenAI to translate the pure R Strassen logic into a high-performance Rcpp function.
*   **Goal 2:** Debug the C++ implementation with AI assistance to handle the "power of two" square matrix case correctly.
*   **Goal 3:** Document the AI prompts and the iterative debugging process.

### Weekly Summary

*   **Progress:** I successfully translated the R Strassen function into C++ using Rcpp. After a lot of debugging, the C++ version now compiles and runs correctly for the simple case.
*   **Key Learning:** This week was a great lesson in the differences between R and C++. The AI's first direct translation failed because it wrote C++ code as if it were R, using `+` for matrix addition and R-style `[]` subsetting. This was a good example of an AI "hallucination." The real work was in the debugging cycle: I'd get a compiler error, feed it back to the AI, and we'd work through it. This process led me to write my own C++ helper functions for matrix math and use manual loops for partitioning.
*   **Challenges/Blockers:** The main challenge was getting the first C++ version to compile. The AI's initial, incorrect assumptions about C++ syntax meant I had to guide it through the debugging process. It was a good reminder of the need for human oversight.

---

## Week 4: Nov 1 - 7 | Generalization and Progress Report

### Goals for this Week:
*   **Goal 1:** Add matrix padding and trimming logic to the Rcpp function to handle matrices of arbitrary and non-square dimensions.
*   **Goal 2:** Write comprehensive tests to ensure the generalized function is numerically accurate.
*   **Goal 3:** Write and submit the project progress report.

### Weekly Summary

*   **Progress:** I successfully generalized the C++ Strassen implementation to handle any matrix size, including non-square matrices. This involved creating a wrapper function that pads the matrices with zeros to the next power of two, runs the core recursive algorithm, and then trims the result back to the correct dimensions. I also completed and submitted my progress report.
*   **Key Learning:** This week was about making the "textbook" algorithm practical. I learned how to implement the padding/trimming logic, which is essential for making Strassen's algorithm a useful, general-purpose tool. It was a good lesson in how theoretical algorithms need extra engineering to become robust.
*   **Challenges/Blockers:** The main challenge was getting the indexing correct while copying the original matrices into the larger, padded versions and then extracting the final result. It was very easy to make off-by-one errors, and I had to write several tests to find and fix these bugs to ensure the output was numerically accurate.

---

## Week 5: Nov 10 - 16 | Hybrid Algorithm and Benchmarking

### Goals for this Week:
*   **Goal 1:** Implement a fast, baseline C++ naive multiply function (`naive_cpp_multiply`).
*   **Goal 2:** Modify the Strassen Rcpp function to use a `THRESHOLD` and switch to the naive C++ function for base cases.
*   **Goal 3:** Write a benchmarking script using the `microbenchmark` package.
*   **Goal 4:** Run benchmarks to find the optimal crossover point for the threshold.

### Weekly Summary

*   **Progress:** I successfully implemented the hybrid version of the Strassen algorithm in C++. This involved first creating a baseline `naive_cpp_multiply` function, then modifying the main Strassen function to call it for sub-problems smaller than a given `THRESHOLD`. I then wrote the `threshold_tuning_plot.R` script to benchmark the performance across different thresholds and found that **64** was the optimal crossover point for a 1024x1024 matrix.
*   **Key Learning:** This week was all about performance tuning. Using the `microbenchmark` package was essential for getting reliable timing data. The results clearly showed the U-shaped performance curve I was expecting, which validated the theory that a hybrid approach is necessary. It was satisfying to see the data prove that for small matrices, the overhead of Strassen's recursion is more costly than a simple, brute-force loop.
*   **Challenges/Blockers:** The main challenge was structuring the benchmarking script to loop through the different thresholds and capture the results cleanly. It took a few tries to get the `ggplot2` code right to automatically highlight the optimal point on the graph.

---

## Week 6: Nov 17 - 23 | Parallelization and Final Benchmarking

### Goals for this Week:
*   **Goal 1:** Create a `src/Makevars` file to enable OpenMP.
*   **Goal 2:** Add OpenMP directives to parallelize the 7 recursive calls (M1-M7).
*   **Goal 3:** Run final performance comparisons comparing all implemented algorithms.
*   **Goal 4:** Generate plots to visualize the results and identify the final crossover point.

### Weekly Summary

*   **Progress:** I parallelized the hybrid algorithm using OpenMP. This involved creating a `src/Makevars` file to add the necessary compiler flags and then adding `#pragma omp` directives to the C++ code to execute the 7 recursive calls in parallel. I then ran a final, comprehensive benchmark of all algorithms and created the `projection_plot.R` script to visualize the results and calculate the final crossover points.
*   **Key Learning:** Learning how to configure the build system for an external library like OpenMP was a major step. The `Makevars` file was critical, and it was impactful to see how a few lines of OpenMP directives could dramatically reduce the execution time by leveraging all available CPU cores. The final performance plot clearly shows the distinct performance tiers of each implementation.
*   **Challenges/Blockers:** The `Makevars` file was tricky. The configuration is different for macOS (which I use locally) and Linux (which GitHub Actions uses), and this caused several build failures during the website deployment. It took a few iterations with the AI to create a conditional `Makevars` file that worked for both environments.

---

## Week 7: Nov 24 - 30 | Website Deployment and Final Report

### Goals for this Week:
*   **Goal 1:** Set up the GitHub Pages site for the final tutorial.
*   **Goal 2:** Draft the initial sections (theory, complexity) and organize the development log.
*   **Goal 3:** Convert all GenAI logs into the final GitHub Pages tutorial, adding benchmarking results and a code walkthrough.
*   **Goal 4:** Refine the R package and write the final report document.

### Weekly Summary

*   **Progress:** I finalized the project by deploying the `pkgdown` website and writing the final report. I created the main tutorial vignette (`tutorial.Rmd`) by combining my previous logs and reports, and embedded the final benchmark plots directly into the page. After a lengthy debugging process, the website is now live and automatically updates via GitHub Actions.
*   **Key Learning:** This week was a deep dive into CI/CD (Continuous Integration/Continuous Deployment). Setting up the GitHub Actions workflow was far more complex than I anticipated. It was a practical lesson in how build environments work, the importance of installing system dependencies (like OpenMP), and how to create platform-agnostic build configurations (`Makevars` for macOS vs. Linux).
*   **Challenges/Blockers:** The main challenge was a multi-day battle with GitHub Actions. The website build failed repeatedly due to a series of cascading issues, starting with a missing OpenMP library, which then revealed a macOS-specific `Makevars` file, which then revealed a missing `devtools` dependency. Debugging this required methodically reading the build logs and fixing each issue one by one with the AI's help. It was a powerful, if frustrating, lesson in real-world deployment.

---

## Final Week: Dec 1 - 7 | Project Wrap-up and Presentation

### Goals for this Week:
*   **Goal 1:** Submit Final Report.
*   **Goal 2:** Create presentation slides outlining the motivation, GenAI process, and benchmark results.
*   **Goal 3:** Finalize and rehearse the 9-minute presentation.
*   **Goal 4:** Submit Presentation Slides.

### Weekly Summary

*   **Progress:** This week was dedicated to wrapping up the entire project. I submitted the final report, which summarized all the development, challenges, and results. I also created the presentation slides, outlining the project's motivation, the GenAI-assisted development process, and the key benchmark results. I finalized and rehearsed the 9-minute presentation multiple times to ensure smooth delivery and submitted the slides.
*   **Key Learning:** The biggest learning from this final week was the art of synthesis. Condensing weeks of complex development, debugging, and performance analysis into a concise, impactful presentation was a challenge. It forced me to distill the most important takeaways and effectively communicate the value of the GenAI workflow.
*   **Challenges/Blockers:** The main challenge was fitting all the technical details and the narrative of the GenAI process into a strict 10-minute time limit

---
