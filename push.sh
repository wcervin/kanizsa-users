#!/bin/bash

# Master Push Script for Kanizsa Photo Categorizer
# This script orchestrates the entire version update, documentation update, commit, and push workflow
# Usage: ./push.sh [version_type]
#   version_type: "revision", "minor", "major", or "custom"
#   If "custom" is specified, the current version will be used

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

print_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

print_header() {
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}  Kanizsa API Gateway - Push Workflow${NC}"
    echo -e "${CYAN}================================================${NC}"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_header

# Check if we're in the correct repository
if [[ ! -f "$SCRIPT_DIR/VERSION" ]]; then
    print_error "VERSION file not found! Make sure you're in the kanizsa-api-gateway repository."
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository! Please run this script from a git repository."
    exit 1
fi

# Parse command line arguments
VERSION_TYPE="${1:-}"

# Validate version type argument
if [[ -z "$VERSION_TYPE" ]]; then
    print_error "Version type argument is required!"
    echo ""
    print_status "Usage: $0 [version_type]"
    echo "  version_type: 'revision', 'minor', 'major', or 'custom'"
    echo ""
    print_status "Examples:"
    echo "  $0 revision    # Bump patch version (1.0.0 → 1.0.1)"
    echo "  $0 minor       # Bump minor version (1.0.0 → 1.1.0)"
    echo "  $0 major       # Bump major version (1.0.0 → 2.0.0)"
    echo "  $0 custom      # Use current version"
    echo ""
    exit 1
fi

# Validate version type
case $VERSION_TYPE in
    "revision"|"minor"|"major"|"custom")
        print_status "Version type: $VERSION_TYPE"
        ;;
    *)
        print_error "Invalid version type: $VERSION_TYPE"
        print_error "Valid types: revision, minor, major, custom"
        exit 1
        ;;
esac

# Get current version
CURRENT_VERSION=$(cat "$SCRIPT_DIR/VERSION")
print_status "Current version: $CURRENT_VERSION"

# Check if all required scripts exist
REQUIRED_SCRIPTS=("01_update_version.sh" "02_update_documentation.sh" "03_commit.sh" "04_push.sh")
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ ! -f "$SCRIPT_DIR/$script" ]]; then
        print_error "Required script not found: $script"
        exit 1
    fi
    
    if [[ ! -x "$SCRIPT_DIR/$script" ]]; then
        print_warning "Making script executable: $script"
        chmod +x "$SCRIPT_DIR/$script"
    fi
done

print_success "✓ All required scripts found and executable"

# Step 1: Version Update
print_step "Step 1: Updating version..."
print_status "Running: ./01_update_version.sh $VERSION_TYPE"

if [[ -f "$SCRIPT_DIR/01_update_version.sh" ]]; then
    if ./01_update_version.sh "$VERSION_TYPE"; then
        print_success "✓ Version update completed"
    else
        print_error "✗ Version update failed!"
        exit 1
    fi
else
    print_error "✗ 01_update_version.sh not found!"
    exit 1
fi

# Step 2: Documentation Update
print_step "Step 2: Updating documentation..."
print_status "Running: ./02_update_documentation.sh"

if [[ -f "$SCRIPT_DIR/02_update_documentation.sh" ]]; then
    if ./02_update_documentation.sh; then
        print_success "✓ Documentation update completed"
    else
        print_error "✗ Documentation update failed!"
        exit 1
    fi
else
    print_error "✗ 02_update_documentation.sh not found!"
    exit 1
fi

# Step 3: Commit
print_step "Step 3: Committing changes..."
print_status "Running: ./03_commit.sh"

if [[ -f "$SCRIPT_DIR/03_commit.sh" ]]; then
    if ./03_commit.sh; then
        print_success "✓ Commit completed"
    else
        print_error "✗ Commit failed!"
        exit 1
    fi
else
    print_error "✗ 03_commit.sh not found!"
    exit 1
fi

# Step 4: Push
print_step "Step 4: Pushing to remote..."
print_status "Running: ./04_push.sh"

if [[ -f "$SCRIPT_DIR/04_push.sh" ]]; then
    if ./04_push.sh; then
        print_success "✓ Push completed"
    else
        print_error "✗ Push failed!"
        exit 1
    fi
else
    print_error "✗ 04_push.sh not found!"
    exit 1
fi

# Final summary
print_success "================================================"
print_success "🎉 Complete workflow finished successfully!"
print_success "================================================"
print_status "Repository: kanizsa-photo-categorizer"
print_status "Version type: $VERSION_TYPE"
print_status "Current version: $CURRENT_VERSION"

# Show the final git status
print_status "Final repository status:"
git status --porcelain

print_success "All done! 🚀"

exit 0
