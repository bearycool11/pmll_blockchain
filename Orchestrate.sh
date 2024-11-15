#!/bin/bash

# Configuration Variables
PROJECT_DIR="/workspaces/pmll"
INSTALL_DIR="/opt/pmll"
LOG_FILE="/var/log/pmll_orchestration.log"

# Helper function for logging
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

# Function to deploy binaries
deploy() {
    log "Deploying binaries to $INSTALL_DIR..."
    sudo mkdir -p "$INSTALL_DIR" || { log "Failed to create install directory"; exit 1; }
    make deploy || { log "Deployment failed"; exit 1; }
    log "Deployment successful."
}

# Function to start services
start_services() {
    log "Starting services..."
    make start_services || { log "Failed to start services"; exit 1; }
    log "Services started successfully."
}

# Function to stop services
stop_services() {
    log "Stopping services..."
    make stop_services || { log "Failed to stop services"; exit 1; }
    log "Services stopped successfully."
}

# Function to restart services
restart_services() {
    log "Restarting services..."
    make restart_services || { log "Failed to restart services"; exit 1; }
    log "Services restarted successfully."
}

# Function to clean the environment
clean() {
    log "Cleaning the environment..."
    make clean || { log "Failed to clean environment"; exit 1; }
    log "Clean complete."
}

# Function to build the project
build() {
    log "Building the project..."
    make all || { log "Build failed"; exit 1; }
    log "Build successful."
}

# Menu for orchestrating tasks
log "Starting orchestration script..."
PS3="Select a task: "
options=("Build All" "Deploy" "Start Services" "Stop Services" "Restart Services" "Clean" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Build All")
            build
            ;;
        "Deploy")
            deploy
            ;;
        "Start Services")
            start_services
            ;;
        "Stop Services")
            stop_services
            ;;
        "Restart Services")
            restart_services
            ;;
        "Clean")
            clean
            ;;
        "Quit")
            log "Exiting orchestration script."
            break
            ;;
        *)
            echo "Invalid option. Please select a valid task."
            ;;
    esac
done
