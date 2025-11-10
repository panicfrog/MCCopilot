#!/bin/bash

# Xcode Build Script for React Web Module
# This script is automatically called during Xcode build process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[Build Script]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[Build Script]${NC} $1 ✅"
}

print_warning() {
    echo -e "${YELLOW}[Build Script]${NC} $1 ⚠️"
}

print_error() {
    echo -e "${RED}[Build Script]${NC} $1 ❌"
}

# Check if we're in a build environment
if [ -z "$SRCROOT" ]; then
    print_error "This script should be run from Xcode build environment"
    print_status "Usage: ./scripts/build-web.sh (from Xcode Run Script phase)"
    exit 1
fi

# Get the Web project directory
WEB_PROJECT_DIR="$SRCROOT/Web"

if [ ! -d "$WEB_PROJECT_DIR" ]; then
    print_error "Web project directory not found: $WEB_PROJECT_DIR"
    exit 1
fi

print_status "Building React Web module..."
print_status "Web project directory: $WEB_PROJECT_DIR"
print_status "Target directory: $SRCROOT/MCCopilot/Web"

# Change to Web project directory
cd "$WEB_PROJECT_DIR"

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Please install Node.js to build the web module."
    exit 1
fi

# Check if npm is available
if ! command -v npm &> /dev/null; then
    print_error "npm not found. Please install npm to build the web module."
    exit 1
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    print_status "Installing Node.js dependencies..."
    npm install
    if [ $? -eq 0 ]; then
        print_success "Dependencies installed successfully"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
fi

# Determine build mode
if [ "$CONFIGURATION" = "Debug" ]; then
    BUILD_MODE="dev"
    print_status "Building in Development mode"
else
    BUILD_MODE="production"
    print_status "Building in Production mode"
fi

# Build the web module
if [ "$BUILD_MODE" = "dev" ]; then
    print_status "Running: npm run build:ios:dev"
    npm run build:ios:dev
else
    print_status "Running: npm run build:ios"
    npm run build:ios
fi

# Check if build was successful
if [ $? -eq 0 ]; then
    print_success "Web module built successfully"

    # Verify the output files exist
    if [ -f "$SRCROOT/MCCopilot/Web/index.html" ]; then
        print_success "index.html found in target directory"
    else
        print_error "index.html not found in target directory"
        exit 1
    fi

    if [ -d "$SRCROOT/MCCopilot/Web/assets" ]; then
        print_success "assets directory found in target directory"
    else
        print_error "assets directory not found in target directory"
        exit 1
    fi

    print_success "React Web module integration completed successfully!"
else
    print_error "Failed to build web module"
    exit 1
fi