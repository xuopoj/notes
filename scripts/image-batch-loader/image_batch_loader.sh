#!/bin/bash

# Docker Image Batch Loader and Registry Pusher
# Loads Docker tar/tar.gz files and pushes them to a private registry

set -uo pipefail

# Configuration
REGISTRY_URL=""
ORGANIZATION=""
DELETE_AFTER_PROCESS="false"
MOVE_TO_DIRECTORY=""
LOG_FILE="docker_batch_loader_$(date +%Y%m%d_%H%M%S)_$$.log"
SUCCESS_COUNT=0
FAILED_COUNT=0
FAILED_FILES=()
SCRIPT_PID=$$

# Arrays to track detailed results per file
FAILED_FILES=()
FAILED_REASONS=()
DELETED_COUNT=0
MOVED_COUNT=0

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Display output to console
    echo "${timestamp} [${level}] [PID:$$] ${message}"
    # Write to log file
    echo "${timestamp} [${level}] [PID:$$] ${message}" >> "$LOG_FILE"
}

# Error handling
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Parse command line arguments
parse_arguments() {
    # Set default values
    DIRECTORY="."
    PATTERN="*.tar*"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --registry)
                REGISTRY_URL="$2"
                shift 2
                ;;
            --organization)
                ORGANIZATION="$2"
                shift 2
                ;;
            --delete)
                DELETE_AFTER_PROCESS="true"
                shift
                ;;
            --move-to)
                MOVE_TO_DIRECTORY="$2"
                shift 2
                ;;
            --directory|-d)
                DIRECTORY="$2"
                shift 2
                ;;
            --pattern|-p)
                PATTERN="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            -*)
                error_exit "Unknown option: $1"
                ;;
            *)
                error_exit "Unexpected argument: $1. Use --help for usage information."
                ;;
        esac
    done
}

# Check if required tools are available
check_dependencies() {
    log "INFO" "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        error_exit "Docker is not installed or not in PATH"
    fi
}

# Validate configuration
validate_config() {
    log "INFO" "Validating configuration..."
    
    if [[ -z "$REGISTRY_URL" ]]; then
        error_exit "REGISTRY_URL is required"
    fi
    
    if [[ -z "$ORGANIZATION" ]]; then
        error_exit "ORGANIZATION variable is required"
    fi
    
    # Remove trailing slash from registry URL
    REGISTRY_URL="${REGISTRY_URL%/}"
    
    # Validate move directory if specified
    if [[ -n "$MOVE_TO_DIRECTORY" ]]; then
        if [[ ! -d "$MOVE_TO_DIRECTORY" ]]; then
            log "INFO" "Creating move directory: $MOVE_TO_DIRECTORY"
            if ! mkdir -p "$MOVE_TO_DIRECTORY"; then
                error_exit "Failed to create move directory: $MOVE_TO_DIRECTORY"
            fi
        fi
        if [[ ! -w "$MOVE_TO_DIRECTORY" ]]; then
            error_exit "Move directory is not writable: $MOVE_TO_DIRECTORY"
        fi
    fi
    
    if [[ -n "$MOVE_TO_DIRECTORY" ]]; then
        log "INFO" "Move to directory: $MOVE_TO_DIRECTORY"
    fi
}



# Load and tag Docker image
load_and_tag_image() {
    local tar_file="$1"
    local filename=$(basename "$tar_file")
    local failure_reason=""
    local final_tag=""
    
    log "INFO" "Processing: $filename"
    
    # Validate tar file first
    if ! tar -tf "$tar_file" >/dev/null 2>&1; then
        failure_reason="Invalid or corrupted tar file"
        log "ERROR" "$failure_reason: $filename"
        FAILED_FILES+=("$filename")
        FAILED_REASONS+=("$failure_reason")
        return 1
    fi
    
    # Load the image and capture the output
    log "INFO" "Loading image from $filename..."
    local load_output
    if ! load_output=$(docker load -i "$tar_file" 2>&1); then
        echo "$load_output" >> "$LOG_FILE"
        failure_reason="Failed to load image - Invalid Docker image or corrupted tar"
        log "ERROR" "$failure_reason: $filename"
        FAILED_FILES+=("$filename")
        FAILED_REASONS+=("$failure_reason")
        return 1
    fi
    echo "$load_output" >> "$LOG_FILE"
    
    # Extract image information from docker load output
    local image_id=""
    local original_tag=""
    
    # Extract image ID
    if echo "$load_output" | grep -q "Loaded image ID:"; then
        image_id=$(echo "$load_output" | grep "Loaded image ID:" | sed 's/.*Loaded image ID: //' | head -1)
    elif echo "$load_output" | grep -q "Loaded image:"; then
        # For newer Docker versions that show "Loaded image:"
        image_id=$(echo "$load_output" | grep "Loaded image:" | sed 's/.*Loaded image: //' | head -1)
    fi
    
    # Extract original tag if present in the output
    if echo "$load_output" | grep -q "Loaded image:"; then
        # Look for repository:tag pattern in the output
        original_tag=$(echo "$load_output" | grep "Loaded image:" | sed 's/.*Loaded image: //' | grep -o '[^:]*:[^[:space:]]*' | head -1)
    fi
    
    if [[ -z "$image_id" ]]; then
        failure_reason="Could not determine loaded image ID"
        log "ERROR" "$failure_reason: $filename"
        log "ERROR" "Docker load output: $load_output"
        FAILED_FILES+=("$filename")
        FAILED_REASONS+=("$failure_reason")
        return 1
    fi
    
    log "INFO" "Loaded image ID: $image_id"
    
    # Create new tag for registry
    local new_tag
    if [[ -n "$original_tag" ]]; then
        # Use original repository name, replace registry with organization
        local repo_name=$(echo "$original_tag" | cut -d':' -f1 | sed 's|.*/||')
        local tag_name=$(echo "$original_tag" | cut -d':' -f2)
        new_tag="${REGISTRY_URL}/${ORGANIZATION}/${repo_name}:${tag_name}"
    else
        # Generate tag from filename with organization
        local base_name=$(basename "$tar_file" .tar.gz)
        base_name=$(basename "$base_name" .tar)
        new_tag="${REGISTRY_URL}/${ORGANIZATION}/${base_name}:latest"
    fi
    
    # Tag the image
    log "INFO" "Tagging image as: $new_tag"
    local tag_output
    if ! tag_output=$(docker tag "$image_id" "$new_tag" 2>&1); then
        echo "$tag_output" >> "$LOG_FILE"
        log "ERROR" "Failed to tag image: $new_tag"
        return 1
    fi
    echo "$tag_output" >> "$LOG_FILE"
    log "INFO" "Successfully tagged image"
    
    # Push to registry
    log "INFO" "Pushing to registry..."
    local push_output
    if ! push_output=$(docker push "$new_tag" 2>&1); then
        echo "$push_output" >> "$LOG_FILE"
        log "ERROR" "Failed to push $new_tag - Registry may be unreachable or authentication expired"
        return 1
    fi
    echo "$push_output" >> "$LOG_FILE"
    log "INFO" "Successfully pushed $new_tag"
    
    # Move or delete tar file if requested
    if [[ "$DELETE_AFTER_PROCESS" == "true" ]]; then
        log "INFO" "Deleting tar file: $filename"
        if rm "$tar_file"; then
            log "INFO" "Successfully deleted: $filename"
            ((DELETED_COUNT++))
        else
            log "WARN" "Failed to delete: $filename"
        fi
    elif [[ -n "$MOVE_TO_DIRECTORY" ]]; then
        log "INFO" "Moving tar file to: $MOVE_TO_DIRECTORY/$filename"
        if mv "$tar_file" "$MOVE_TO_DIRECTORY/"; then
            log "INFO" "Successfully moved: $filename"
            ((MOVED_COUNT++))
        else
            log "WARN" "Failed to move: $filename"
        fi
    fi
    
    echo "$new_tag"
    return 0
}

# Process all tar files in directory
process_files() {
    local directory="${1:-.}"
    local file_pattern="${2:-*.tar*}"
    
    # Find all tar files
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$directory" -maxdepth 1 -name "$file_pattern" -type f -print0 2>/dev/null)
    
    if [[ ${#files[@]} -eq 0 ]]; then
        log "WARN" "No tar files found matching pattern: $file_pattern"
        return 0
    fi
    
    log "INFO" "Found ${#files[@]} files to process"
    
    # Process each file
    for file in "${files[@]}"; do
        log "INFO" "Processing file $((SUCCESS_COUNT + FAILED_COUNT + 1)) of ${#files[@]}: $(basename "$file")"
        
        if load_and_tag_image "$file"; then
            ((SUCCESS_COUNT++))
            log "INFO" "✓ Successfully processed: $(basename "$file")"
        else
            ((FAILED_COUNT++))
            FAILED_FILES+=("$file")
            log "ERROR" "✗ Failed to process: $(basename "$file") - Continuing with next file..."
        fi
        echo "---" >> "$LOG_FILE"
    done
}

# Cleanup function
cleanup() {
    log "INFO" "Cleaning up..."
}

# Print summary
print_summary() {
    echo "" >> "$LOG_FILE"
    log "INFO" "=== SUMMARY ==="
    log "INFO" "Successfully processed: $SUCCESS_COUNT files"
    log "INFO" "Failed: $FAILED_COUNT files"
    log "INFO" "Total files: $((SUCCESS_COUNT + FAILED_COUNT))"
    if [[ "$DELETE_AFTER_PROCESS" == "true" ]]; then
        log "INFO" "Files deleted: $DELETED_COUNT"
    elif [[ -n "$MOVE_TO_DIRECTORY" ]]; then
        log "INFO" "Files moved: $MOVED_COUNT"
    fi
    
    if [[ $FAILED_COUNT -gt 0 ]]; then
        log "INFO" "Failed files:"
        for i in "${!FAILED_FILES[@]}"; do
            log "INFO" "  - ${FAILED_FILES[$i]}: ${FAILED_REASONS[$i]}"
        done
        log "INFO" "Common failure reasons:"
        log "INFO" "  - Invalid or corrupted tar files"
        log "INFO" "  - Registry authentication expired"
        log "INFO" "  - Network connectivity issues"
        log "INFO" "  - Registry storage full or unavailable"
    fi
    
    log "INFO" "Log file: $LOG_FILE"
}

# Main function
main() {
    # Check for help first before any logging
    for arg in "$@"; do
        if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
            show_usage
            exit 0
        fi
    done
    
    # Parse command line arguments
    parse_arguments "$@"
    
    log "INFO" "=== Docker Batch Loader Started ==="
    log "INFO" "Registry: $REGISTRY_URL"
    log "INFO" "Organization: $ORGANIZATION"
    log "INFO" "Directory: $DIRECTORY"
    log "INFO" "Pattern: $PATTERN"
    log "INFO" "Delete after process: $DELETE_AFTER_PROCESS"
    if [[ -n "$MOVE_TO_DIRECTORY" ]]; then
        log "INFO" "Move to directory: $MOVE_TO_DIRECTORY"
    fi
    
    # Set up cleanup trap
    trap cleanup EXIT
    
    # Validate and setup
    check_dependencies
    validate_config
    
    # Process files
    process_files "$DIRECTORY" "$PATTERN"
    
    # Print summary
    print_summary
    
    # Exit with appropriate code based on results
    if [[ $FAILED_COUNT -gt 0 && $SUCCESS_COUNT -eq 0 ]]; then
        log "ERROR" "All files failed to process"
        exit 1
    elif [[ $FAILED_COUNT -gt 0 ]]; then
        log "WARN" "Some files failed, but processing completed"
        exit 2
    else
        log "INFO" "All files processed successfully"
        exit 0
    fi
}

# Show usage
show_usage() {
cat << EOF
Usage: $0 [OPTIONS]

Load Docker tar/tar.gz files and push them to a registry.

Required Options:
  --registry URL           Registry URL (required)
  --organization NAME      Organization/namespace (required)

Optional Options:
  --delete                Delete tar files after successful processing
  --move-to DIR           Move tar files to directory after successful processing
  --directory, -d DIR     Directory containing tar files (default: current directory)
  --pattern, -p PATTERN   File pattern to match (default: *.tar*)
  --help, -h              Show this help message

Examples:
  $0 --registry myregistry.com --organization myorg
  $0 --registry myregistry.com --organization myorg --directory /path/to/images
  $0 --registry myregistry.com --organization myorg --pattern "*.tar.gz"
  $0 --registry myregistry.com --organization myorg --delete --directory /path/to/images
  $0 --registry myregistry.com --organization myorg --move-to /processed --directory /path/to/images
  $0 --registry myregistry.com --organization myorg -d /path/to/images -p "*.tar*" --move-to /processed

Background Execution:
  nohup $0 --registry myregistry.com --organization myorg --directory /path/to/images > batch_loader.log 2>&1 &
  nohup $0 --registry myregistry.com --organization myorg --delete --directory /path/to/images > /dev/null 2>&1 &

EOF
}

# Run main function
main "$@"
