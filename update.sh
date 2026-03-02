#!/bin/bash

# Robust forecast update script with comprehensive error checking
# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Configuration
FORECAST_DIR="/Users/chrisfairless/Library/CloudStorage/OneDrive-Personal/Projects/UNU/idmc/forecast/displacement_forecast"
PAGE_DIR="/Users/chrisfairless/Library/CloudStorage/OneDrive-Personal/Projects/UNU/idmc/forecast/displacement_forecast_page"
PYTHON_BIN="/usr/local/Caskroom/miniforge/base/envs/idmc_forecast/bin/python"
LOG_FILE="${PAGE_DIR}/update.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Logging function
log() {
    echo "[${TIMESTAMP}] $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo "[${TIMESTAMP}] ERROR: $1" | tee -a "${LOG_FILE}" >&2
}

# Error trap handler
error_handler() {
    local line_num=$1
    log_error "Script failed at line ${line_num}"
    log_error "Update process aborted"
    exit 1
}

trap 'error_handler ${LINENO}' ERR

# Start update process
log "========================================="
log "Starting forecast update process"
log "========================================="

# Step 1: Validate preconditions
log "Step 1: Validating preconditions..."

if [[ ! -d "${FORECAST_DIR}" ]]; then
    log_error "Forecast directory does not exist: ${FORECAST_DIR}"
    exit 1
fi
log "✓ Forecast directory exists"

if [[ ! -d "${PAGE_DIR}" ]]; then
    log_error "Page directory does not exist: ${PAGE_DIR}"
    exit 1
fi
log "✓ Page directory exists"

if [[ ! -x "${PYTHON_BIN}" ]]; then
    log_error "Python binary not found or not executable: ${PYTHON_BIN}"
    exit 1
fi
log "✓ Python environment available"

cd "${PAGE_DIR}"

if [[ ! -d .git ]]; then
    log_error "Not a git repository: ${PAGE_DIR}"
    exit 1
fi
log "✓ Git repository detected"

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    log_error "Git repository has uncommitted changes. Please commit or stash them first."
    git status --short
    exit 1
fi
log "✓ Git repository is clean"

# Check if remote is reachable
if ! git ls-remote origin &>/dev/null; then
    log_error "Cannot reach git remote. Check network connection."
    exit 1
fi
log "✓ Git remote is reachable"

# Step 2: Generate forecasts
log "Step 2: Generating forecasts..."
cd "${FORECAST_DIR}"

if ! "${PYTHON_BIN}" process_all_forecasts.py; then
    log_error "Forecast generation failed"
    exit 1
fi
log "✓ Forecast generation completed successfully"

# Step 3: Pull latest changes from remote
log "Step 3: Pulling latest changes from git..."
cd "${PAGE_DIR}"

# Store current HEAD
OLD_HEAD=$(git rev-parse HEAD)

if ! git pull; then
    log_error "Git pull failed. There may be merge conflicts."
    exit 1
fi

NEW_HEAD=$(git rev-parse HEAD)

if [[ "${OLD_HEAD}" == "${NEW_HEAD}" ]]; then
    log "✓ Already up to date with remote"
else
    log "✓ Pulled changes from remote (${OLD_HEAD:0:7} -> ${NEW_HEAD:0:7})"
fi

# Step 4: Copy forecast outputs
log "Step 4: Copying forecast outputs..."

if ! "${PYTHON_BIN}" copy_over_outputs.py; then
    log_error "File copy operation failed"
    exit 1
fi
log "✓ File copy completed successfully"

# Step 5: Check for changes and commit
log "Step 5: Checking for changes to commit..."

# Check if there are any changes to commit
if [[ -z $(git status --porcelain) ]]; then
    log "No changes detected. Nothing to commit."
    log "========================================="
    log "Update completed (no changes)"
    log "========================================="
    exit 0
fi

# Show what changed
log "Changes detected:"
git status --short | tee -a "${LOG_FILE}"

# Stage all changes
if ! git add -A; then
    log_error "Failed to stage changes"
    exit 1
fi
log "✓ Changes staged"

# Commit changes
COMMIT_MSG="Automated update - $(date '+%Y-%m-%d %H:%M:%S')"
if ! git commit -m "${COMMIT_MSG}"; then
    log_error "Commit failed"
    exit 1
fi
COMMIT_HASH=$(git rev-parse HEAD)
log "✓ Changes committed (${COMMIT_HASH:0:7})"

# Step 6: Push to remote
log "Step 6: Pushing changes to remote..."

# Attempt push, retry once if it fails
if ! git push; then
    log "Push failed, retrying in 5 seconds..."
    sleep 5
    if ! git push; then
        log_error "Push failed after retry. Changes are committed locally but not pushed."
        log_error "You may need to manually run 'git push' from ${PAGE_DIR}"
        exit 1
    fi
fi

log "✓ Changes pushed successfully"

# Final summary
log "========================================="
log "Update completed successfully"
log "Commit: ${COMMIT_HASH:0:7}"
log "========================================="
