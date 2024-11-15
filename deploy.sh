#!/bin/bash

# Define Silos and Deployment Details
SILOS=("silo1.example.com" "silo2.example.com" "silo3.example.com" ... "silo300.example.com")
INSTALL_DIR="/opt/pmll"
DEPLOY_DIR="path/to/binaries"

# Function to Deploy to a Single Silo
deploy_to_silo() {
    local silo=$1
    echo "Deploying to $silo..."
    
    # Ensure the installation directory exists on the remote silo
    ssh $silo "mkdir -p $INSTALL_DIR" || { echo "Failed to create directory on $silo"; return 1; }
    
    # Copy binaries to the remote silo
    scp $DEPLOY_DIR/* $silo:$INSTALL_DIR/ || { echo "Failed to copy to $silo"; return 1; }
    
    # Start services on the remote silo
    ssh $silo "cd $INSTALL_DIR && nohup ./silo_manager &> silo_manager.log & nohup ./api &> api.log & nohup ./logic_loop &> logic_loop.log &" || { echo "Failed to start services on $silo"; return 1; }
    
    echo "Deployment successful on $silo"
}

# Deploy to All Silos
for silo in "${SILOS[@]}"; do
    deploy_to_silo $silo &
