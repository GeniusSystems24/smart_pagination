# Error Images Setup Guide

Complete guide for adding awesome error illustrations to your pagination error screens.

## 🎨 Quick Start

### Option 1: Use Free Illustrations (Recommended)

Visit **unDraw** - the easiest and best free illustration resource:

1. **Go to**: https://undraw.co/illustrations
2. **Search** for error-related terms
3. **Customize** the primary color (e.g., `#FF6B6B` for errors)
4. **Download** as SVG
5. **Convert** to PNG (400x400px) or use SVG directly
6. **Save** to `example/assets/images/errors/`

### Option 2: Run the Download Script

```bash
cd example/assets/images/errors
./download_images.sh
```

Choose option 1 for placeholders or option 2 for manual instructions.

## 📋 Required Images

Download and save these images to `example/assets/images/errors/`:

| Filename | Purpose | Recommended Search Terms | Colors |
|----------|---------|-------------------------|--------|
| `error_general.png` | General errors | "error", "void", "warning" | Red (#FF6B6B) |
| `error_network.png` | Network errors | "connection", "wifi", "offline" | Orange (#FFA726) |
| `error_404.png` | Not found errors | "not found", "search", "lost" | Grey (#78909C) |
| `error_500.png` | Server errors | "server down", "maintenance", "broken" | Red (#E74C3C) |
| `error_timeout.png` | Timeout errors | "waiting", "loading", "time" | Amber (#FFA726) |
| `error_auth.png` | Auth errors | "secure", "login", "lock" | Orange (#FF9800) |
| `error_offline.png` | Offline mode | "offline", "no connection", "cloud" | Grey (#607D8B) |
| `error_empty.png` | Empty states | "empty", "void", "inbox" | Grey (#78909C) |
| `retry_icon.png` | Retry actions | "refresh", "retry", "reload" | Blue (#42A5F5) |
| `recovery_icon.png` | Recovery | "restore", "backup", "recovery" | Green (#66BB6A) |
| `error_loading.png` | Load more errors | "loading", "waiting" | Orange (#FF9800) |
| `error_custom.png` | Custom errors | "customize", "settings" | Purple (#9C27B0) |

## 🌟 Best Free Resources

### 1. unDraw (⭐ Highly Recommended)
- **URL**: https://undraw.co/illustrations
- **License**: Free for commercial use, no attribution required
- **Format**: SVG (easily convertible to PNG)
- **Customization**: Change colors directly on website
- **Quality**: High-quality, modern illustrations
- **Perfect for**: All error types

**Quick Links**:
- Error illustrations: https://undraw.co/search?q=error
- 404 illustrations: https://undraw.co/search?q=not-found
- Offline illustrations: https://undraw.co/search?q=offline
- Empty states: https://undraw.co/search?q=empty

### 2. Storyset by Freepik
- **URL**: https://storyset.com/
- **License**: Free with attribution (or paid license)
- **Format**: SVG, PNG, customizable
- **Styles**: Rafiki, Amico, Bro, Pana, Cuate
- **Quality**: Professional, colorful
- **Perfect for**: Polished, commercial look

### 3. DrawKit
- **URL**: https://www.drawkit.com/
- **License**: Free for personal & commercial use
- **Format**: SVG
- **Styles**: Various illustration packs
- **Quality**: Clean, minimal designs
- **Perfect for**: Simple, elegant errors

### 4. Illustrations.co
- **URL**: https://illlustrations.co/
- **License**: Free (check current terms)
- **Format**: PNG, SVG
- **Styles**: Open-source illustration kit
- **Quality**: Modern, consistent
- **Perfect for**: Cohesive design system

### 5. Humaaans
- **URL**: https://www.humaaans.com/
- **License**: Free for commercial use
- **Format**: SVG, PNG
- **Styles**: Mix-and-match people
- **Quality**: Unique, customizable
- **Perfect for**: Human-centered errors

## 🔧 Using the ErrorImages Helper

The `ErrorImages` helper class provides easy access to all error images with automatic fallback to icons:

```dart
import 'package:smart_pagination_example/utils/error_images.dart';

// In your error widget
ErrorImages.network(
  width: 200,
  height: 200,
  fallbackColor: Colors.orange,
)

// Or use the builder for custom paths
ErrorImages.buildImage(
  imagePath: 'assets/images/errors/custom_error.png',
  fallbackIcon: Icons.error_outline,
  fallbackColor: Colors.red,
  width: 250,
  height: 250,
)
```

### Available Helper Methods

```dart
ErrorImages.general()       // General error image
ErrorImages.network()       // Network error image
ErrorImages.notFound()      // 404 error image
ErrorImages.serverError()   // 500 error image
ErrorImages.timeout()       // Timeout error image
ErrorImages.auth()          // Authentication error image
ErrorImages.offline()       // Offline mode image
ErrorImages.empty()         // Empty state image
ErrorImages.retry()         // Retry icon image
ErrorImages.recovery()      // Recovery icon image
ErrorImages.loadingError()  // Load more error image
ErrorImages.custom()        // Custom error image
```

## 📐 Image Specifications

### Recommended Sizes
- **Primary error screens**: 400x400px
- **Compact/inline errors**: 200x200px
- **Icons**: 64x64px

### File Formats
- **SVG**: Recommended for scalability
- **PNG**: For compatibility, use PNG-24 with transparency
- **WebP**: For smaller file sizes (requires configuration)

### Optimization
- **Target file size**: <100KB per image
- **Use PNG-8** for simple illustrations
- **Compress** before committing

**Tools**:
```bash
# PNG optimization
pngquant --quality=65-80 *.png --ext .png --force

# SVG to PNG conversion
inkscape -w 400 -h 400 input.svg -o output.png
```

## 🎨 Color Palette

Match your illustrations to these error colors:

```dart
// Error colors used in the app
final errorColors = {
  'error': Color(0xFFFF6B6B),     // Red
  'warning': Color(0xFFFFA726),   // Orange
  'info': Color(0xFF42A5F5),      // Blue
  'success': Color(0xFF66BB6A),   // Green
  'neutral': Color(0xFF78909C),   // Grey
};
```

When customizing illustrations on unDraw:
- Use `#FF6B6B` for error/danger illustrations
- Use `#FFA726` for warning illustrations
- Use `#42A5F5` for info illustrations
- Use `#66BB6A` for success illustrations

## 📝 Step-by-Step: Adding Images from unDraw

1. **Visit unDraw**
   ```
   https://undraw.co/illustrations
   ```

2. **Search for "error"**
   - Browse through results
   - Find an illustration that matches your need

3. **Customize Color**
   - Click the color picker (top right)
   - Enter `#FF6B6B` (or your theme color)
   - Preview the updated illustration

4. **Download SVG**
   - Click "Download" button
   - Save as SVG format

5. **Convert to PNG** (if needed)
   - Use online converter: https://cloudconvert.com/svg-to-png
   - Or command line:
     ```bash
     inkscape -w 400 -h 400 undraw_void.svg -o error_general.png
     ```

6. **Rename and Move**
   ```bash
   mv undraw_void.png example/assets/images/errors/error_general.png
   ```

7. **Verify in App**
   ```bash
   cd example
   flutter pub get
   flutter run
   ```

## 🚀 Quick Setup (5 minutes)

### For Development/Testing

Use this quick script to create colored placeholders:

```bash
cd example/assets/images/errors

# Create simple placeholders using ImageMagick
convert -size 400x400 xc:#FF6B6B -gravity center -pointsize 48 -fill white -annotate +0+0 "Error" error_general.png
convert -size 400x400 xc:#FFA726 -gravity center -pointsize 48 -fill white -annotate +0+0 "Network" error_network.png
convert -size 400x400 xc:#78909C -gravity center -pointsize 72 -fill white -annotate +0+0 "404" error_404.png
convert -size 400x400 xc:#E74C3C -gravity center -pointsize 72 -fill white -annotate +0+0 "500" error_500.png
convert -size 400x400 xc:#FFA726 -gravity center -pointsize 48 -fill white -annotate +0+0 "Timeout" error_timeout.png
convert -size 400x400 xc:#FF9800 -gravity center -pointsize 48 -fill white -annotate +0+0 "Auth" error_auth.png
convert -size 400x400 xc:#607D8B -gravity center -pointsize 48 -fill white -annotate +0+0 "Offline" error_offline.png
convert -size 400x400 xc:#78909C -gravity center -pointsize 48 -fill white -annotate +0+0 "Empty" error_empty.png
convert -size 300x300 xc:#42A5F5 -gravity center -pointsize 48 -fill white -annotate +0+0 "Retry" retry_icon.png
convert -size 300x300 xc:#66BB6A -gravity center -pointsize 36 -fill white -annotate +0+0 "Recover" recovery_icon.png
convert -size 400x400 xc:#FF9800 -gravity center -pointsize 40 -fill white -annotate +0+0 "Loading..." error_loading.png
convert -size 400x400 xc:#9C27B0 -gravity center -pointsize 48 -fill white -annotate +0+0 "Custom" error_custom.png
```

*Requires ImageMagick: `brew install imagemagick` (Mac) or `apt-get install imagemagick` (Linux)*

### For Production

Download quality illustrations from unDraw (10-15 minutes for all images).

## ✅ Verification

After adding images, verify they work:

1. **Run pub get**:
   ```bash
   cd example
   flutter pub get
   ```

2. **Restart app** (hot reload won't reload new assets):
   ```bash
   flutter run
   ```

3. **Navigate to error screens**:
   - Open Error Handling Examples section
   - Check each error screen
   - Verify images load correctly
   - If images don't show, icons should display as fallback

4. **Check file sizes**:
   ```bash
   cd example/assets/images/errors
   ls -lh *.png
   ```
   Each file should be <100KB ideally.

## 🐛 Troubleshooting

### Images Not Showing?

1. **Check pubspec.yaml**:
   ```yaml
   flutter:
     assets:
       - assets/images/errors/
   ```

2. **Run flutter pub get**:
   ```bash
   flutter pub get
   ```

3. **Restart app** (not just hot reload):
   ```bash
   flutter run
   ```

4. **Verify image paths**:
   ```bash
   ls example/assets/images/errors/
   ```

5. **Check file names** match exactly (case-sensitive).

### Images Look Pixelated?

- Use higher resolution (800x800px or 2x/3x sizes)
- Use SVG instead of PNG
- Use `flutter_svg` package for SVG support

### Build Size Too Large?

- Optimize PNGs with `pngquant`
- Use WebP format
- Remove unused images
- Consider using remote images for non-critical errors

## 📦 Complete Example

Here's a complete error widget using images:

```dart
import 'package:flutter/material.dart';
import '../utils/error_images.dart';

class BeautifulErrorWidget extends StatelessWidget {
  final Exception error;
  final VoidCallback onRetry;

  const BeautifulErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Beautiful error illustration
            ErrorImages.network(
              width: 250,
              height: 250,
            ),

            const SizedBox(height: 32),

            // Error message
            Text(
              'Connection Lost',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 32),

            // Retry button with icon
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🎯 Next Steps

1. ✅ Download error illustrations from unDraw
2. ✅ Save them to `example/assets/images/errors/`
3. ✅ Run `flutter pub get`
4. ✅ Restart your app
5. ✅ Navigate to error screens to see beautiful illustrations!

## 📚 Additional Resources

- **unDraw**: https://undraw.co
- **Storyset**: https://storyset.com
- **DrawKit**: https://www.drawkit.com
- **Illustrations.co**: https://illlustrations.co
- **Humaaans**: https://www.humaaans.com
- **SVG to PNG Converter**: https://cloudconvert.com/svg-to-png
- **PNG Optimizer**: https://tinypng.com

---

**Happy illustrating! 🎨**
