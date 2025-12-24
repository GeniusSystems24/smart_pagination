# Error Illustration Images

This directory contains error illustration images used in the error handling example screens.

## Image Requirements

### Recommended Sources (All Free & Commercial Use)

#### 1. **unDraw** (https://undraw.co/illustrations)
- **License**: Open source, free for commercial use
- **Format**: SVG (easily convert to PNG)
- **Recommended Images**:
  - `error.svg` - General error (search "void" or "error")
  - `404.svg` - Page not found (search "not found" or "lost")
  - `500.svg` - Server error (search "server down" or "maintenance")
  - `no_connection.svg` - Network error (search "connection" or "offline")
  - `timeout.svg` - Timeout error (search "wait" or "loading")
  - `auth_error.svg` - Authentication (search "secure" or "login")
  - `empty.svg` - Empty state (search "empty" or "void")

#### 2. **Storyset** (https://storyset.com/)
- **License**: Free with attribution (or pay for no attribution)
- **Format**: SVG, PNG, customizable colors
- **Categories**: Curated error illustrations
- **Recommended Collections**:
  - Rafiki style - Modern, friendly illustrations
  - Amico style - Flat, colorful designs
  - Bro style - Simple, clean illustrations

#### 3. **DrawKit** (https://www.drawkit.com/)
- **License**: Free for personal & commercial use
- **Format**: SVG
- **Recommended Packs**:
  - Classic Kit
  - Error illustrations pack

#### 4. **Humaaans** (https://www.humaaans.com/)
- **License**: Free for commercial & personal use
- **Format**: SVG, PNG
- **Style**: Mix-and-match people illustrations

#### 5. **Illustrations.co** (https://illlustrations.co/)
- **License**: Free for personal use
- **Format**: PNG, SVG
- **Style**: Open source illustration kit

## Image Specifications

### Recommended Sizes
- **Primary Images**: 400x400px (for main error screens)
- **Inline Images**: 200x200px (for compact errors)
- **Icons**: 64x64px (for minimal errors)

### File Naming Convention
```
error_[type]_[variant].png

Examples:
- error_general.png
- error_network.png
- error_404.png
- error_500.png
- error_timeout.png
- error_auth.png
- error_offline.png
- error_empty.png
- retry_icon.png
- recovery_icon.png
```

## Quick Setup Guide

### Option 1: Download from unDraw (Recommended)

1. Visit https://undraw.co/illustrations
2. Search for error-related terms
3. Customize the primary color to match your theme
4. Download as SVG
5. Convert to PNG if needed using:
   - Online: https://cloudconvert.com/svg-to-png
   - CLI: `inkscape -w 400 -h 400 input.svg -o output.png`

### Option 2: Use Placeholders (Development)

For development, you can use placeholder images from:
- https://placehold.co/400x400/orange/white?text=Error
- https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=404

### Option 3: Generate AI Images

Use AI tools to generate custom error illustrations:
- DALL-E 3
- Midjourney
- Stable Diffusion

**Prompt template:**
"Minimalist flat illustration of [error type], friendly character, pastel colors, white background, simple geometric shapes, modern design"

## Image Mapping

| Screen | Primary Image | Fallback Icon |
|--------|--------------|---------------|
| Basic Error | `error_general.png` | Icons.error_outline |
| Network Errors | `error_network.png` | Icons.wifi_off |
| Retry Patterns | `retry_icon.png` | Icons.autorenew |
| Custom Widgets | `error_custom.png` | Icons.widgets |
| Error Recovery | `recovery_icon.png` | Icons.restore |
| Graceful Degradation | `error_offline.png` | Icons.cloud_off |
| Load More Errors | `error_loading.png` | Icons.expand_more |

## Color Palette Recommendations

Match your error images to these colors:

- **Error/Danger**: #FF6B6B, #E74C3C
- **Warning**: #FFA726, #FF9800
- **Info**: #42A5F5, #2196F3
- **Success**: #66BB6A, #4CAF50
- **Neutral**: #78909C, #607D8B

## Implementation Example

```dart
// In your error widget
Image.asset(
  'assets/images/errors/error_network.png',
  width: 200,
  height: 200,
  errorBuilder: (context, error, stackTrace) {
    // Fallback to icon if image not found
    return Icon(
      Icons.wifi_off,
      size: 64,
      color: Colors.orange,
    );
  },
)
```

## License Information

All recommended sources provide images that are:
- ✅ Free for commercial use
- ✅ No attribution required (except Storyset)
- ✅ Can be modified
- ✅ Can be redistributed

Always verify the current license terms before using.

## Quick Download Commands

### Using curl (if images are hosted)
```bash
# Example download script
cd example/assets/images/errors

# Download error illustrations (update URLs as needed)
curl -o error_general.png "https://your-source/error_general.png"
curl -o error_network.png "https://your-source/error_network.png"
curl -o error_404.png "https://your-source/error_404.png"
```

## Testing Images

After adding images, verify they load correctly:

```bash
cd example
flutter run
```

Navigate to error screens and verify images display properly.

## Optimization

Before committing images:

1. **Optimize PNGs**:
   ```bash
   # Using pngquant
   pngquant --quality=65-80 *.png --ext .png --force

   # Using ImageOptim (Mac)
   # Drag and drop images to ImageOptim app
   ```

2. **Keep file sizes small**:
   - Target: <100KB per image
   - Use PNG-8 for simple illustrations
   - Use WebP for better compression (requires pubspec configuration)

## Troubleshooting

### Images not showing?
1. Check pubspec.yaml has assets declared
2. Run `flutter pub get`
3. Restart app (hot reload may not work for assets)
4. Verify image path is correct

### Images look pixelated?
1. Use higher resolution source (2x or 3x)
2. Use SVG instead of PNG
3. Use vector_graphics package for SVG support

## Contributing

To add new error images:
1. Follow naming convention
2. Optimize file size
3. Add entry to this README
4. Update pubspec.yaml if needed
