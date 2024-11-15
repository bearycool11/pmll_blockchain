#include <stdio.h>
#include <stdlib.h>

// Define the Vector Matrix Structure
typedef struct {
    int rows;
    int cols;
    int** data;
} vector_matrix_t;

// Function to Initialize a Vector Matrix
vector_matrix_t* init_vector_matrix(int rows, int cols) {
    vector_matrix_t* matrix = (vector_matrix_t*)malloc(sizeof(vector_matrix_t));
    if (!matrix) {
        perror("Memory allocation failed for vector matrix");
        exit(EXIT_FAILURE);
    }

    matrix->rows = rows;
    matrix->cols = cols;
    matrix->data = (int**)malloc(rows * sizeof(int*));
    for (int i = 0; i < rows; i++) {
        matrix->data[i] = (int*)malloc(cols * sizeof(int));
    }

    return matrix;
}

// Function to Free a Vector Matrix
void free_vector_matrix(vector_matrix_t* matrix) {
    for (int i = 0; i < matrix->rows; i++) {
        free(matrix->data[i]);
    }
    free(matrix->data);
    free(matrix);
}

// Function to Populate the Vector Matrix with Values
void populate_vector_matrix(vector_matrix_t* matrix, int* values) {
    int index = 0;
    for (int i = 0; i < matrix->rows; i++) {
        for (int j = 0; j < matrix->cols; j++) {
            matrix->data[i][j] = values[index++];
        }
    }
}

// PMLL Logic Loop Integration
void pmll_vector_matrix_process(vector_matrix_t* matrix) {
    printf("Processing the vector matrix...\n");

    // Example: Matrix Multiplication (Square Matrix)
    if (matrix->rows == matrix->cols) {
        vector_matrix_t* result = init_vector_matrix(matrix->rows, matrix->cols);

        for (int i = 0; i < matrix->rows; i++) {
            for (int j = 0; j < matrix->cols; j++) {
                result->data[i][j] = 0;
                for (int k = 0; k < matrix->cols; k++) {
                    result->data[i][j] += matrix->data[i][k] * matrix->data[k][j];
                }
            }
        }

        printf("Resultant Matrix:\n");
        for (int i = 0; i < result->rows; i++) {
            for (int j = 0; j < result->cols; j++) {
                printf("%d ", result->data[i][j]);
            }
            printf("\n");
        }

        free_vector_matrix(result);
    } else {
        printf("Non-square matrices are currently not supported for this operation.\n");
    }
}

// Main Function
int main() {
    // Example values for the matrix
    int rows = 3;
    int cols = 3;
    int values[] = {1, 2, 3, 4, 5, 6, 7, 8, 9};

    vector_matrix_t* matrix = init_vector_matrix(rows, cols);
    populate_vector_matrix(matrix, values);

    printf("Input Matrix:\n");
    for (int i = 0; i < matrix->rows; i++) {
        for (int j = 0; j < matrix->cols; j++) {
            printf("%d ", matrix->data[i][j]);
        }
        printf("\n");
    }

    pmll_vector_matrix_process(matrix);

    free_vector_matrix(matrix);
    return 0;
}
