#!/bin/bash

# Error Images Download Script
# This script helps you download error illustration images from various free sources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "======================================"
echo "  Error Images Download Helper"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to download image from URL
download_image() {
    local url=$1
    local filename=$2

    if [ -f "$filename" ]; then
        print_warning "File $filename already exists, skipping..."
        return 0
    fi

    print_info "Downloading $filename..."
    if curl -L -o "$filename" "$url" 2>/dev/null; then
        print_success "Downloaded $filename"
        return 0
    else
        print_error "Failed to download $filename"
        return 1
    fi
}

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    print_error "curl is not installed. Please install curl first."
    exit 1
fi

echo "This script will help you download error illustrations."
echo ""
echo "📦 Recommended Sources:"
echo "  1. unDraw (https://undraw.co)"
echo "  2. Storyset (https://storyset.com)"
echo "  3. DrawKit (https://drawkit.com)"
echo ""
echo "Choose an option:"
echo "  1) Download placeholder images (for testing)"
echo "  2) Show manual download instructions"
echo "  3) Generate placeholder SVGs"
echo "  4) Exit"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        print_info "Downloading placeholder images..."
        echo ""

        # Download placeholder images using placehold.co
        download_image "https://placehold.co/400x400/FF6B6B/FFFFFF/png?text=Error" "error_general.png"
        download_image "https://placehold.co/400x400/FFA726/FFFFFF/png?text=No+Network" "error_network.png"
        download_image "https://placehold.co/400x400/78909C/FFFFFF/png?text=404" "error_404.png"
        download_image "https://placehold.co/400x400/E74C3C/FFFFFF/png?text=500" "error_500.png"
        download_image "https://placehold.co/400x400/FFA726/FFFFFF/png?text=Timeout" "error_timeout.png"
        download_image "https://placehold.co/400x400/FF9800/FFFFFF/png?text=Auth" "error_auth.png"
        download_image "https://placehold.co/400x400/78909C/FFFFFF/png?text=Offline" "error_offline.png"
        download_image "https://placehold.co/400x400/607D8B/FFFFFF/png?text=Empty" "error_empty.png"
        download_image "https://placehold.co/300x300/42A5F5/FFFFFF/png?text=Retry" "retry_icon.png"
        download_image "https://placehold.co/300x300/66BB6A/FFFFFF/png?text=Recover" "recovery_icon.png"
        download_image "https://placehold.co/400x400/FF9800/FFFFFF/png?text=Loading..." "error_loading.png"
        download_image "https://placehold.co/400x400/9C27B0/FFFFFF/png?text=Custom" "error_custom.png"

        echo ""
        print_success "Placeholder images downloaded successfully!"
        print_warning "These are temporary placeholders. Replace with proper illustrations."
        ;;

    2)
        echo ""
        print_info "Manual Download Instructions"
        echo "======================================"
        echo ""
        echo "🎨 Option 1: unDraw (Recommended)"
        echo "  1. Visit: https://undraw.co/illustrations"
        echo "  2. Search for: 'error', 'void', 'not found', 'offline', etc."
        echo "  3. Customize the primary color to match your theme"
        echo "  4. Download as SVG"
        echo "  5. Convert to PNG (400x400px) if needed"
        echo "  6. Save to this directory with proper names"
        echo ""
        echo "📸 Option 2: Storyset"
        echo "  1. Visit: https://storyset.com/"
        echo "  2. Search for error-related illustrations"
        echo "  3. Customize colors and download"
        echo "  4. Choose PNG format (400x400px)"
        echo "  5. Save to this directory"
        echo ""
        echo "🎭 Option 3: DrawKit"
        echo "  1. Visit: https://www.drawkit.com/"
        echo "  2. Browse free packs"
        echo "  3. Download relevant illustrations"
        echo "  4. Extract and rename files"
        echo "  5. Move to this directory"
        echo ""
        echo "Required files:"
        echo "  - error_general.png    (General error illustration)"
        echo "  - error_network.png    (No connection/WiFi off)"
        echo "  - error_404.png        (Page not found)"
        echo "  - error_500.png        (Server error)"
        echo "  - error_timeout.png    (Request timeout)"
        echo "  - error_auth.png       (Authentication required)"
        echo "  - error_offline.png    (Offline mode)"
        echo "  - error_empty.png      (Empty state)"
        echo "  - retry_icon.png       (Retry action)"
        echo "  - recovery_icon.png    (Recovery/restore)"
        echo "  - error_loading.png    (Load more error)"
        echo "  - error_custom.png     (Custom error)"
        echo ""
        ;;

    3)
        print_info "Generating simple SVG placeholders..."
        echo ""

        # Create simple SVG placeholders
        cat > error_general.svg << 'EOF'
<svg width="400" height="400" xmlns="http://www.w3.org/2000/svg">
  <rect width="400" height="400" fill="#FFF5F5"/>
  <circle cx="200" cy="180" r="60" fill="#FF6B6B"/>
  <text x="200" y="300" font-family="Arial" font-size="24" fill="#333" text-anchor="middle">Error!</text>
</svg>
EOF

        print_success "Created error_general.svg"

        print_info "To convert SVG to PNG, use:"
        echo "  - Online: https://cloudconvert.com/svg-to-png"
        echo "  - CLI: inkscape -w 400 -h 400 error_general.svg -o error_general.png"
        ;;

    4)
        print_info "Exiting..."
        exit 0
        ;;

    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "======================================"
print_info "Next steps:"
echo "  1. Replace placeholders with quality illustrations"
echo "  2. Run 'flutter pub get' in the example directory"
echo "  3. Restart your Flutter app to see the images"
echo "======================================"
echo ""
