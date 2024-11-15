#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include "vector_Matrix.h" // Include the vector_Matrix header

#define CLIENT_ID "Ov23li5l71lKLE8kYTIc"
#define CLIENT_SECRET "7b4626c63b6b939b9b14680b32ab01ec231cf2e2"
#define REPO_OWNER "bearycool11"
#define REPO_NAME "pmll"
#define API_URL "127.0.0.1" // Ensure localhost resolves properly
#define API_PORT 8080
#define CROSS_TALK_URL "127.0.0.1"
#define CROSS_TALK_PORT 8081
#define IO_SOCKET_URL "127.0.0.1"
#define IO_SOCKET_PORT 8082
#define LOGIC_LOOP_URL "127.0.0.1"
#define LOGIC_LOOP_PORT 8083
#define PML_LOGIC_LOOP_URL "127.0.0.1"
#define PML_LOGIC_LOOP_PORT 8084

// Function to create a new socket
int create_socket() {
    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("Failed to create socket");
        exit(EXIT_FAILURE);
    }
    return sockfd;
}

// Function to set up the server address
void set_up_server_address(struct sockaddr_in* server_addr, const char* url, int port) {
    memset(server_addr, 0, sizeof(*server_addr));
    server_addr->sin_family = AF_INET;
    server_addr->sin_port = htons(port);
    if (inet_pton(AF_INET, url, &server_addr->sin_addr) <= 0) {
        fprintf(stderr, "Invalid address: %s\n", url);
        exit(EXIT_FAILURE);
    }
}

// Function to connect to a server
void connect_to_server(int sockfd, struct sockaddr_in* server_addr) {
    if (connect(sockfd, (struct sockaddr*)server_addr, sizeof(*server_addr)) < 0) {
        perror("Failed to connect to server");
        close(sockfd);
        exit(EXIT_FAILURE);
    }
}

// Function to perform vector matrix operations
void handle_vector_matrix_operations() {
    int rows = 3, cols = 3;
    int values[] = {1, 2, 3, 4, 5, 6, 7, 8, 9};

    // Initialize and populate the vector matrix
    vector_matrix_t* matrix = init_vector_matrix(rows, cols);
    if (!matrix) {
        fprintf(stderr, "Failed to initialize vector matrix\n");
        exit(EXIT_FAILURE);
    }

    if (populate_vector_matrix(matrix, values) != 0) {
        fprintf(stderr, "Failed to populate vector matrix\n");
        free_vector_matrix(matrix);
        exit(EXIT_FAILURE);
    }

    printf("Input Matrix:\n");
    for (int i = 0; i < matrix->rows; i++) {
        for (int j = 0; j < matrix->cols; j++) {
            printf("%d ", matrix->data[i][j]);
        }
        printf("\n");
    }

    // Perform polynomial-time operations using the vector matrix logic
    if (pmll_vector_matrix_process(matrix) != 0) {
        fprintf(stderr, "Vector matrix processing failed\n");
        free_vector_matrix(matrix);
        exit(EXIT_FAILURE);
    }

    // Clean up
    free_vector_matrix(matrix);
}

// Function to make a GET request
void make_get_request(const char* url) {
    CURL* curl = curl_easy_init();
    if (!curl) {
        fprintf(stderr, "Failed to initialize cURL\n");
        exit(EXIT_FAILURE);
    }

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        fprintf(stderr, "cURL GET request failed: %s\n", curl_easy_strerror(res));
    }

    curl_easy_cleanup(curl);
}

// Function to make a POST request
void make_post_request(const char* url, const char* data) {
    CURL* curl = curl_easy_init();
    if (!curl) {
        fprintf(stderr, "Failed to initialize cURL\n");
        exit(EXIT_FAILURE);
    }

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);

    CURLcode res = curl_easy_perform(curl);
    if (res != CURLE_OK) {
        fprintf(stderr, "cURL POST request failed: %s\n", curl_easy_strerror(res));
    }

    curl_easy_cleanup(curl);
}

int main() {
    int api_sockfd, cross_talk_sockfd, io_socket_sockfd, logic_loop_sockfd, pml_logic_loop_sockfd;
    struct sockaddr_in api_server_addr, cross_talk_server_addr, io_socket_server_addr, logic_loop_server_addr, pml_logic_loop_server_addr;

    // Perform vector matrix operations
    printf("Performing vector matrix operations...\n");
    handle_vector_matrix_operations();

    // Create and connect to API server
    api_sockfd = create_socket();
    set_up_server_address(&api_server_addr, API_URL, API_PORT);
    connect_to_server(api_sockfd, &api_server_addr);

    // Create and connect to Cross-Talk server
    cross_talk_sockfd = create_socket();
    set_up_server_address(&cross_talk_server_addr, CROSS_TALK_URL, CROSS_TALK_PORT);
    connect_to_server(cross_talk_sockfd, &cross_talk_server_addr);

    // Create and connect to IO Socket server
    io_socket_sockfd = create_socket();
    set_up_server_address(&io_socket_server_addr, IO_SOCKET_URL, IO_SOCKET_PORT);
    connect_to_server(io_socket_sockfd, &io_socket_server_addr);

    // Create and connect to Logic Loop server
    logic_loop_sockfd = create_socket();
    set_up_server_address(&logic_loop_server_addr, LOGIC_LOOP_URL, LOGIC_LOOP_PORT);
    connect_to_server(logic_loop_sockfd, &logic_loop_server_addr);

    // Create and connect to PML Logic Loop server
    pml_logic_loop_sockfd = create_socket();
    set_up_server_address(&pml_logic_loop_server_addr, PML_LOGIC_LOOP_URL, PML_LOGIC_LOOP_PORT);
    connect_to_server(pml_logic_loop_sockfd, &pml_logic_loop_server_addr);

    // Make a GET request to retrieve repository information
    printf("Making a GET request to the GitHub API...\n");
    const char* get_url = "https://api.github.com/repos/bearycool11/pmll";
    make_get_request(get_url);

    // Make a POST request to create a new issue
    printf("Making a POST request to create a new issue...\n");
    const char* post_data = "{\"title\":\"New issue\",\"body\":\"This is a new issue\"}";
    const char* post_url = "https://api.github.com/repos/bearycool11/pmll/issues";
    make_post_request(post_url, post_data);

    // Send a request to the API server
    const char* request = "GET /api/endpoint HTTP/1.1\r\nHost: localhost:8080\r\n\r\n";
    if (send(api_sockfd, request, strlen(request), 0) < 0) {
        perror("Failed to send request to API server");
    }

    // Receive a response from the API server
    char response[1024];
    if (recv(api_sockfd, response, sizeof(response), 0) < 0) {
        perror("Failed to receive response from API server");
    } else {
        printf("API Server Response:\n%s\n", response);
    }

    // Close all sockets
    close(api_sockfd);
    close(cross_talk_sockfd);
    close(io_socket_sockfd);
    close(logic_loop_sockfd);
    close(pml_logic_loop_sockfd);

    return 0;
}

    close(logic_loop_sockfd);
    close(pml_logic_loop_sockfd);

    return 0;
}

