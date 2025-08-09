#!/bin/bash

# Push Script for Kanizsa Photo Categorizer
# This script pushes committed changes to the remote repository
# Usage: ./04_push.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status "Kanizsa Photo Categorizer - Push Script"
print_status "======================================="

# Check if we're in the correct repository
if [[ ! -f "$SCRIPT_DIR/VERSION" ]]; then
    print_error "VERSION file not found! Make sure you're in the kanizsa-photo-categorizer repository."
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository! Please run this script from a git repository."
    exit 1
fi

# Get current version and commit information
CURRENT_VERSION=""
COMMIT_HASH=""
COMMIT_MESSAGE=""

if [[ -f "$SCRIPT_DIR/.new_version" ]]; then
    CURRENT_VERSION=$(cat "$SCRIPT_DIR/.new_version")
    print_status "Using version from .new_version file: $CURRENT_VERSION"
else
    CURRENT_VERSION=$(cat "$SCRIPT_DIR/VERSION")
    print_status "Using current version from VERSION file: $CURRENT_VERSION"
fi

if [[ -f "$SCRIPT_DIR/.last_commit_hash" ]]; then
    COMMIT_HASH=$(cat "$SCRIPT_DIR/.last_commit_hash")
    print_status "Last commit hash: $COMMIT_HASH"
fi

if [[ -f "$SCRIPT_DIR/.last_commit_message" ]]; then
    COMMIT_MESSAGE=$(cat "$SCRIPT_DIR/.last_commit_message")
    print_status "Last commit message: $COMMIT_MESSAGE"
fi

# Check if there are commits to push
print_status "Checking for commits to push..."
# Get the current branch's upstream
CURRENT_BRANCH=$(git branch --show-current)
UPSTREAM_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "origin/$CURRENT_BRANCH")

LOCAL_COMMITS=$(git log --oneline "$UPSTREAM_BRANCH"..HEAD 2>/dev/null || echo "")

if [[ -z "$LOCAL_COMMITS" ]]; then
    print_warning "No new commits to push!"
    print_status "Current branch is up to date with remote."
    exit 0
fi

print_status "Commits to push:"
echo "$LOCAL_COMMITS" | while read -r commit; do
    if [[ -n "$commit" ]]; then
        print_status "  - $commit"
    fi
done

# Check remote status
print_status "Checking remote status..."
if ! git remote -v | grep -q origin; then
    print_error "No 'origin' remote found!"
    print_status "Available remotes:"
    git remote -v
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
print_status "Current branch: $CURRENT_BRANCH"

# Check if we're on a valid branch
if [[ "$CURRENT_BRANCH" == "HEAD" ]]; then
    print_error "Not on a valid branch! Please checkout a branch before pushing."
    exit 1
fi

# Push to remote
print_status "Pushing to remote repository..."
if git push origin "$CURRENT_BRANCH"; then
    print_success "✓ Successfully pushed to remote!"
    
    # Verify the push
    print_status "Verifying push..."
    sleep 2  # Give the remote a moment to update
    
    # Check if the commit is now on the remote
    if git fetch origin >/dev/null 2>&1; then
        if git log --oneline origin/"$CURRENT_BRANCH" | head -1 | grep -q "$(echo "$LOCAL_COMMITS" | head -1 | cut -d' ' -f1)"; then
            print_success "✓ Push verification successful!"
        else
            print_warning "⚠ Push verification inconclusive - commit may still be propagating"
        fi
    else
        print_warning "⚠ Could not verify push - network issues or remote unavailable"
    fi
else
    print_error "✗ Failed to push to remote!"
    print_status "This could be due to:"
    echo "  - Network connectivity issues"
    echo "  - Authentication problems"
    echo "  - Remote repository access issues"
    echo "  - Merge conflicts that need to be resolved"
    exit 1
fi

# Show final status
print_status "Final repository status:"
git status --porcelain

# Clean up temporary files
print_status "Cleaning up temporary files..."
rm -f "$SCRIPT_DIR/.new_version" "$SCRIPT_DIR/.version_type" "$SCRIPT_DIR/.last_commit_hash" "$SCRIPT_DIR/.last_commit_message"

print_success "Push script completed successfully!"
print_status "Repository: kanizsa-photo-categorizer"
print_status "Version: $CURRENT_VERSION"
print_status "Branch: $CURRENT_BRANCH"
if [[ -n "$COMMIT_MESSAGE" ]]; then
    print_status "Last commit: $COMMIT_MESSAGE"
fi
