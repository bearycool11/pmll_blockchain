#!/bin/bash
# File: Orchestrate.sh
# Description: Integrates consent collection, health checks, payload distribution, and binary deployment.

# Determine the directory of this script (Dynamically resolve the script location)
SCRIPT_DIR="${SCRIPT_DIR:-$(dirname "$0")}"

# Ensure the directory where Orchestrate.sh is located exists
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "ERROR: The directory for Orchestrate.sh does not exist! Exiting."
    exit 1
fi

# Define paths dynamically based on SCRIPT_DIR

LOG_DIR="$SCRIPT_DIR/logs"
BUILD_LOG="$LOG_DIR/build.log"
ORCHESTRA_LOG="$LOG_DIR/orchestra.log"
CONSENT_LOG_FILE="$LOG_DIR/consent_responses.log"
CONSENT_SCRIPT="$SCRIPT_DIR/Consent_request.sh"  # Ensure uppercase 'C' is correctly referenced
BINARIES_DIR="$SCRIPT_DIR/binaries"
PORT_BASE=8080

# Components to orchestrate
COMPONENTS=("VECTOR_MATRIX" "MEMORY_SILO" "IO_SOCKET" "PML_LOGIC_LOOP" "UNIFIED_VOICE" "CROSS_TALK" "PERSISTENCE")

# URL/IP configuration for silos
SILO_DOMAIN="silo"
START_SILO=1
END_SILO=144000
RETRY_COUNT=3

# Payload message
PAYLOAD_MESSAGE=$(cat <<EOF
{
  "subject": "Deployment Notification",
  "body": "We are deploying the latest binaries to your silo. Please prepare to receive updates."
}
EOF
)

# Ensure directories exist before using them
mkdir -p "$LOG_DIR" "$BINARIES_DIR"  # Ensure log and binary directories exist

# Log rotation if log file exceeds 10MB
MAX_LOG_SIZE=10485760  # 10 MB
LOG_FILE_SIZE=$(stat -c %s "$ORCHESTRA_LOG")

if [ $LOG_FILE_SIZE -gt $MAX_LOG_SIZE ]; then
    mv "$ORCHESTRA_LOG" "$ORCHESTRA_LOG.old"
    touch "$ORCHESTRA_LOG"  # Create a new log file
    log "Log file rotated."
fi

# Logging utility with a digital ones and zeros pattern
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ORCHESTRA_LOG"
    echo "01001001 01100100 01100101 01101110 01110100 01101001 01100101" >> "$ORCHESTRA_LOG"  # Visual binary signature
}

# Initialize counters
SUCCESS_PAYLOAD=0
FAILED_PAYLOAD=0
SUCCESS_BINARY=0
FAILED_BINARY=0
FAILED_HEALTH=0

# Health check with retry logic
health_check() {
    local silo=$1
    local retries=3
    local delay=5  # seconds
    local attempt=1
    while [ $attempt -le $retries ]; do
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://silo$silo.$SILO_DOMAIN/health")
        if [ "$RESPONSE" == "200" ]; then
            return 0
        fi
        log "Health check failed for silo$silo.$SILO_DOMAIN (Attempt $attempt/$retries)"
        sleep $delay
        attempt=$((attempt + 1))
    done
    log "ERROR: Health check failed for silo$silo.$SILO_DOMAIN after $retries attempts."
    FAILED_HEALTH=$((FAILED_HEALTH + 1))
    return 1
}

# Step 1: Execute Consent_request.sh
log "Starting consent request process..."
bash "$CONSENT_SCRIPT"
if [ $? -ne 0 ]; then
    log "ERROR: Consent_request.sh failed. Exiting."
    exit 1
fi

# Verify consent results
if [ ! -f "$CONSENT_LOG_FILE" ]; then
    log "ERROR: Consent log not found. Exiting."
    exit 1
fi
SUCCESS_COUNT=$(grep -c "SUCCESS" "$CONSENT_LOG_FILE")
FAILURE_COUNT=$(grep -c "ERROR" "$CONSENT_LOG_FILE")
log "Consent process completed. Success: $SUCCESS_COUNT, Failures: $FAILURE_COUNT"

# Step 2: Compile dependencies
log "Compiling dependencies..."
make clean all &>> "$BUILD_LOG"
if [ $? -ne 0 ]; then
    log "ERROR: Compilation failed. Check $BUILD_LOG for details."
    exit 1
fi
log "Compilation completed successfully."

# Validate compiled components
log "Validating compiled components..."
for component in "${COMPONENTS[@]}"; do
    if [ ! -f "$BINARIES_DIR/$component" ]; then
        log "ERROR: Missing executable for $component in $BINARIES_DIR. Skipping deployment for this component."
        continue  # Skip this component and proceed with others
    fi
done
log "All components validated and prepared for distribution."

# Function to send payload message with digital theme
send_payload() {
    local silo=$1
    local attempt=1

    while [ $attempt -le $RETRY_COUNT ]; do
        RESPONSE=$(curl -s -X POST "https://silo$silo.$SILO_DOMAIN/payload" \
            -H "Content-Type: application/json" \
            --data "$PAYLOAD_MESSAGE")

        if [ $? -eq 0 ] && [[ "$RESPONSE" == *"ACKNOWLEDGED"* ]]; then
            SUCCESS_PAYLOAD=$((SUCCESS_PAYLOAD + 1))
            echo "Payload sent to silo$silo.$SILO_DOMAIN"
            echo "01100011 01100101 01100100 01101001 01110100 01100101 01101100 01100101"  # Binary signature for success
            return 0
        fi

        attempt=$((attempt + 1))
        sleep 2
    done

    FAILED_PAYLOAD=$((FAILED_PAYLOAD + 1))
    echo "01101001 01110011 00100000 01100110 01100001 01101100 01100101 01100100"  # Binary for "is failed"
    return 1
}

# Function to deploy binaries with digital signature
deploy_binaries() {
    local silo=$1
    local binary=$2
    local attempt=1

    while [ $attempt -le $RETRY_COUNT ]; do
        RESPONSE=$(curl -s -X POST "https://silo$silo.$SILO_DOMAIN/binary" \
            -H "Content-Type: application/octet-stream" \
            --data-binary "@$BINARIES_DIR/$binary")

        if [ $? -eq 0 ]; then
            SUCCESS_BINARY=$((SUCCESS_BINARY + 1))
            echo "Binary deployed to silo$silo.$SILO_DOMAIN"
            echo "01101110 01101001 01100101 01100100 00100000 01100010 01101001 01101110 01100001 01110010 01111001"  # Binary for "needed binary"
            return 0
        fi

        attempt=$((attempt + 1))
        sleep 2
    done

    FAILED_BINARY=$((FAILED_BINARY + 1))
    echo "01000110 01100001 01101001 01101100 01100101 01100100"  # Binary for "Failed"
    return 1
}

# Step 3: Notify silos with payload
log "Performing health checks and sending payload notifications to silos..."
for silo in $(seq $START_SILO $END_SILO); do
    if health_check "$silo"; then
        send_payload "$silo" &
    else
        echo "Skipping silo$silo.$SILO_DOMAIN due to failed health check."
    fi
done
wait
log "Payload notifications complete."

# Step 4: Deploy binaries to silos
log "Deploying binaries to silos..."
for binary in "${COMPONENTS[@]}"; do
    for silo in $(seq $START_SILO $END_SILO); do
        if health_check "$silo"; then
            deploy_binaries "$silo" "$binary" &
        else
            echo "Skipping silo$silo.$SILO_DOMAIN due to failed health check."
        fi
    done
done
wait
log "Binary distribution complete."

# Summary
echo -e "\nSummary of Operations:"
echo "Payload Notifications - Success: $SUCCESS_PAYLOAD, Failed: $FAILED_PAYLOAD"
echo "Binary Deployments - Success: $SUCCESS_BINARY, Failed: $FAILED_BINARY"
echo "Health Checks - Failed: $FAILED_HEALTH"
log "Deployment process completed."

