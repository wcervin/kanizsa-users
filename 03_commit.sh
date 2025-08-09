#!/bin/bash

# Commit Script for Kanizsa Photo Categorizer
# This script stages and commits changes with proper version information
# Usage: ./03_commit.sh [commit_message]
#   commit_message: optional commit message (will be auto-generated if not provided)

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

print_status "Kanizsa Photo Categorizer - Commit Script"
print_status "========================================="

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

# Get current version and version type from temporary files
CURRENT_VERSION=""
VERSION_TYPE_DESC=""

if [[ -f "$SCRIPT_DIR/.new_version" ]]; then
    CURRENT_VERSION=$(cat "$SCRIPT_DIR/.new_version")
    print_status "Using version from .new_version file: $CURRENT_VERSION"
else
    CURRENT_VERSION=$(cat "$SCRIPT_DIR/VERSION")
    print_status "Using current version from VERSION file: $CURRENT_VERSION"
fi

if [[ -f "$SCRIPT_DIR/.version_type" ]]; then
    VERSION_TYPE_DESC=$(cat "$SCRIPT_DIR/.version_type")
    print_status "Version type: $VERSION_TYPE_DESC"
fi

# Get commit message from command line argument
COMMIT_MESSAGE="${1:-}"

# Auto-generate commit message if not provided
if [[ -z "$COMMIT_MESSAGE" ]]; then
    # Generate a default commit message based on version type
    case $VERSION_TYPE_DESC in
        "revision")
            COMMIT_MESSAGE="fix: version bump (revision)"
            ;;
        "minor")
            COMMIT_MESSAGE="feat: version bump (minor)"
            ;;
        "major")
            COMMIT_MESSAGE="BREAKING: version bump (major)"
            ;;
        "custom")
            COMMIT_MESSAGE="feat: version bump (custom)"
            ;;
        *)
            COMMIT_MESSAGE="chore: version bump"
            ;;
    esac
    print_status "Using auto-generated commit message: $COMMIT_MESSAGE"
fi

# Check git status
print_status "Checking git status..."
if ! git status --porcelain | grep -q .; then
    print_warning "No changes to commit! Working directory is clean."
    exit 0
fi

# Show what will be committed
print_status "Changes to be committed:"
git status --porcelain | while read -r line; do
    status="${line:0:2}"
    file="${line:3}"
    case $status in
        "M ") print_status "  Modified: $file" ;;
        "A ") print_status "  Added: $file" ;;
        "D ") print_status "  Deleted: $file" ;;
        "R ") print_status "  Renamed: $file" ;;
        "C ") print_status "  Copied: $file" ;;
        "U ") print_status "  Unmerged: $file" ;;
        *) print_status "  $status $file" ;;
    esac
done

# Stage all changes
print_status "Staging all changes..."
if git add .; then
    print_success "✓ All changes staged successfully"
else
    print_error "✗ Failed to stage changes!"
    exit 1
fi

# Verify what's staged
print_status "Staged changes:"
git diff --cached --name-only | while read -r file; do
    print_status "  - $file"
done

# Commit the changes
print_status "Committing changes with message: '$COMMIT_MESSAGE'"
if git commit -m "$COMMIT_MESSAGE"; then
    print_success "✓ Changes committed successfully!"
    
    # Get the commit hash and store it for the next script
    COMMIT_HASH=$(git rev-parse HEAD)
    echo "$COMMIT_HASH" > "$SCRIPT_DIR/.last_commit_hash"
    echo "$COMMIT_MESSAGE" > "$SCRIPT_DIR/.last_commit_message"
    
    print_status "Commit hash: $COMMIT_HASH"
    print_status "Commit message: $COMMIT_MESSAGE"
else
    print_error "✗ Failed to commit changes!"
    exit 1
fi

# Show the commit details
print_status "Commit details:"
git log --oneline -1

print_success "Commit script completed successfully!"
