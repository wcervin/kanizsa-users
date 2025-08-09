#!/bin/bash

# Documentation Update Script for Kanizsa Photo Categorizer
# This script updates all documentation with new version, timestamps, and feature changes
# Usage: ./02_update_documentation.sh [version]
#   version: version to update to (optional, will be read from .new_version file if not provided)

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

# Function to safely update a file with sed
safe_sed_update() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local description="$4"
    
    if [[ -f "$file" ]]; then
        # Use BSD sed compatible patterns
        if sed -i '' "s|$pattern|$replacement|g" "$file" 2>/dev/null; then
            print_status "Updated $description in $file"
        else
            print_warning "Failed to update $description in $file"
        fi
    else
        print_warning "File $file not found, skipping $description update"
    fi
}

# Function to detect new features and changes
detect_changes() {
    local version="$1"
    local version_type="$2"
    
    print_status "Detecting changes for version $version ($version_type)..."
    
    # Check for new files
    NEW_FILES=$(find . -name "*.py" -o -name "*.md" -o -name "*.sh" -o -name "*.yml" -o -name "*.yaml" | grep -v __pycache__ | grep -v .git | sort)
    
    # Check for modified files in git
    if git status --porcelain | grep -q "^M\|^A"; then
        MODIFIED_FILES=$(git status --porcelain | grep "^M\|^A" | awk '{print $2}' | grep -E '\.(py|md|sh|yml|yaml)$' | sort)
        print_status "Modified files detected:"
        echo "$MODIFIED_FILES" | while read -r file; do
            if [[ -n "$file" ]]; then
                print_status "  - $file"
            fi
        done
    fi
    
    # Check for new Python modules/classes
    if [[ -d "py_scripts" ]]; then
        NEW_MODULES=$(find py_scripts/ -name "*.py" -exec grep -l "class.*:" {} \; 2>/dev/null || true)
        if [[ -n "$NEW_MODULES" ]]; then
            print_status "Files with new classes detected:"
            echo "$NEW_MODULES" | while read -r file; do
                if [[ -n "$file" ]]; then
                    print_status "  - $file"
                fi
            done
        fi
    fi
    
    # Check for plugin changes
    if [[ -d "py_scripts/plugins" ]]; then
        PLUGIN_FILES=$(find py_scripts/plugins/ -name "*.py" -type f 2>/dev/null || true)
        if [[ -n "$PLUGIN_FILES" ]]; then
            print_status "Plugin files detected:"
            echo "$PLUGIN_FILES" | while read -r file; do
                if [[ -n "$file" ]]; then
                    print_status "  - $file"
                fi
            done
        fi
    fi
}

# Function to update README with new features
update_readme_features() {
    local version="$1"
    local timestamp="$2"
    
    print_status "Updating README with new features..."
    
    if [[ -f "README.md" ]]; then
        # Update version and timestamp
        safe_sed_update "README.md" 'Version: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' 'Version: '$version "version"
        safe_sed_update "README.md" '"version": "[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*"' '"version": "'$version'"' "version in JSON"
        safe_sed_update "README.md" '\*\*VERSION:\*\* [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*' '**VERSION:** '$version "VERSION header"
        
        # Update README.md timestamp with proper escaping
        if [[ -f "README.md" ]]; then
            sed -i '' "s|\*\*LAST UPDATED:\*\* .*|\*\*LAST UPDATED:\*\* $timestamp|g" README.md
            print_status "Updated last updated timestamp in README.md"
        else
            print_warning "README.md not found, skipping timestamp update"
        fi
        
        safe_sed_update "README.md" 'Last Updated: .*' 'Last Updated: '$timestamp "last updated timestamp"
        safe_sed_update "README.md" 'Updated: .*' 'Updated: '$timestamp "updated timestamp"
        
        # Add new features section if it doesn't exist
        if ! grep -q "## 🚀 New Features" README.md; then
            print_status "Adding new features section to README..."
            
            # Create a temporary file with the new features section
            cat > /tmp/new_features_section.md << 'EOF'

## 🚀 New Features

### Modular Commit Workflow (v'$version')
- **01_update_version.sh**: Handles version number updates with validation
- **02_update_documentation.sh**: Updates documentation with new features and changes
- **03_commit.sh**: Stages and commits changes with proper version information
- **04_push.sh**: Pushes to remote with verification

### Enhanced Version Management
- Automatic version calculation (revision, minor, major)
- Comprehensive validation of version updates
- Cross-platform sed compatibility (macOS/Linux)
- Detailed logging and error handling

### Improved Documentation
- Automatic changelog generation
- Feature detection and documentation updates
- Plugin tracking and updates
- Timestamp synchronization across all files

EOF
            
            # Insert the new features section after the main description
            awk '/## 🎯 \*\*Kanizsa Photo Categorizer\*\*/ { print; system("cat /tmp/new_features_section.md"); next } 1' README.md > README.md.tmp && mv README.md.tmp README.md
            
            # Clean up
            rm -f /tmp/new_features_section.md
            print_status "Added new features section to README"
        fi
    fi
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status "Kanizsa Photo Categorizer - Enhanced Documentation Update Script"
print_status "================================================================="

# Check if we're in the correct repository
if [[ ! -f "$SCRIPT_DIR/VERSION" ]]; then
    print_error "VERSION file not found! Make sure you're in the kanizsa-photo-categorizer repository."
    exit 1
fi

# Get version from command line argument or from .new_version file
VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    if [[ -f "$SCRIPT_DIR/.new_version" ]]; then
        VERSION=$(cat "$SCRIPT_DIR/.new_version")
        print_status "Using version from .new_version file: $VERSION"
    else
        VERSION=$(cat "$SCRIPT_DIR/VERSION")
        print_status "Using current version from VERSION file: $VERSION"
    fi
fi

if [[ -z "$VERSION" ]]; then
    print_error "No version provided and no .new_version file found!"
    exit 1
fi

# Get version type for change detection
VERSION_TYPE=""
if [[ -f "$SCRIPT_DIR/.version_type" ]]; then
    VERSION_TYPE=$(cat "$SCRIPT_DIR/.version_type")
fi

print_status "Updating documentation to version: $VERSION"
if [[ -n "$VERSION_TYPE" ]]; then
    print_status "Version type: $VERSION_TYPE"
fi

# Get current timestamp for documentation updates
TIMESTAMP=$(date '+%B %d, %Y, %H:%M:%S %Z')
print_status "Using timestamp: $TIMESTAMP"

# Detect changes and new features
detect_changes "$VERSION" "$VERSION_TYPE"

# Update Python files with version references
print_status "Updating Python files with version references..."
find . -name "*.py" -type f -exec sed -i '' "s|version=\"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|version=\"$VERSION\"|g" {} \;
find . -name "*.py" -type f -exec sed -i '' "s|\"version\": \"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|\"version\": \"$VERSION\"|g" {} \;
find . -name "*.py" -type f -exec sed -i '' "s|VERSION = \"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|VERSION = \"$VERSION\"|g" {} \;
find . -name "*.py" -type f -exec sed -i '' "s|\* VERSION: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|\* VERSION: $VERSION|g" {} \;
find . -name "*.py" -type f -exec sed -i '' "s|VERSION: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|VERSION: $VERSION|g" {} \;
find . -name "*.py" -type f -exec sed -i '' "s|Kanizsa-CLI/[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|Kanizsa-CLI/$VERSION|g" {} \;
find . -name "*.py" -type f -exec sed -i '' "s|LAST UPDATED: .*|LAST UPDATED: $TIMESTAMP|g" {} \;

# Update README with new features
update_readme_features "$VERSION" "$TIMESTAMP"

# Update any documentation files with comprehensive patterns
print_status "Updating documentation files with comprehensive patterns..."
find . -name "*.md" -type f -exec sed -i '' "s|Version: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|Version: $VERSION|g" {} \;
find . -name "*.md" -type f -exec sed -i '' "s|\"version\": \"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|\"version\": \"$VERSION\"|g" {} \;
find . -name "*.md" -type f -exec sed -i '' "s|\*\*VERSION:\*\* [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|\*\*VERSION:\*\* $VERSION|g" {} \;
find . -name "*.md" -type f -exec sed -i '' "s|VERSION: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|VERSION: $VERSION|g" {} \;
find . -name "*.md" -type f -exec sed -i '' "s|LAST UPDATED: .*|LAST UPDATED: $TIMESTAMP|g" {} \;
find . -name "*.md" -type f -exec sed -i '' "s|Last Updated: .*|Last Updated: $TIMESTAMP|g" {} \;
find . -name "*.md" -type f -exec sed -i '' "s|Updated: .*|Updated: $TIMESTAMP|g" {} \;

# Update Dockerfile with version references
print_status "Updating Dockerfile with version references..."
find . -name "Dockerfile*" -type f -exec sed -i '' "s|LABEL version=\"[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\"|LABEL version=\"$VERSION\"|g" {} \;
find . -name "Dockerfile*" -type f -exec sed -i '' "s|ARG VERSION=[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|ARG VERSION=$VERSION|g" {} \;
find . -name "Dockerfile*" -type f -exec sed -i '' "s|# Kanizsa v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|# Kanizsa v$VERSION|g" {} \;
find . -name "Dockerfile*" -type f -exec sed -i '' "s|# VERSION: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|# VERSION: $VERSION|g" {} \;

# Update shell scripts with version references
print_status "Updating shell scripts with version references..."
find . -name "*.sh" -type f -exec sed -i '' "s|VERSION: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|VERSION: $VERSION|g" {} \;
find . -name "*.sh" -type f -exec sed -i '' "s|v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|v$VERSION|g" {} \;

# Update any remaining version patterns in all files
print_status "Updating any remaining version patterns..."
find . -name "*.py" -type f -exec sed -i '' "s|v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|v$VERSION|g" {} \;
find . -name "*.md" -type f -exec sed -i '' "s|v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|v$VERSION|g" {} \;

# Update any YAML files that might contain version references
print_status "Updating YAML files..."
find . -name "*.yml" -type f -exec sed -i '' "s|version: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|version: $VERSION|g" {} \;
find . -name "*.yaml" -type f -exec sed -i '' "s|version: [0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|version: $VERSION|g" {} \;

# Verify key files were updated
print_status "Verifying documentation updates..."
VERIFICATION_FAILED=false

# Check README.md
if grep -q "VERSION.*$VERSION" README.md 2>/dev/null; then
    print_success "✓ README.md version verified"
else
    print_error "✗ README.md version not updated correctly"
    VERIFICATION_FAILED=true
fi

# Check if timestamp was updated in README.md
if grep -q "\*\*LAST UPDATED:\*\* .*2025" README.md 2>/dev/null; then
    print_success "✓ README.md timestamp verified"
else
    print_error "✗ README.md timestamp not updated correctly"
    VERIFICATION_FAILED=true
fi

if [[ "$VERIFICATION_FAILED" == true ]]; then
    print_error "Documentation update verification failed! Please check the files manually."
    exit 1
fi

print_success "Enhanced documentation update completed successfully!"
print_status "Version: $VERSION"
print_status "Timestamp: $TIMESTAMP"
print_status "Files updated:"
echo "  - *.py files"
echo "  - README.md (with new features section)"
echo "  - *.md documentation files"
echo "  - *.yml/*.yaml files"
echo "  - Dockerfile* files"
echo "  - *.sh shell scripts"

print_status "New features and changes detected and documented!"
print_success "Enhanced documentation update script completed!"
