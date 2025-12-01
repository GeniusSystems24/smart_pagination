# Screenshots Guide

This directory contains screenshots for all example screens in the package.

## Directory Structure

```
screenshots/
├── basic/           # Basic pagination examples
├── streams/         # Stream-based examples
├── advanced/        # Advanced features examples
└── errors/          # Error handling examples
```

## Screenshot Naming Convention

Use descriptive names matching the example screen names:

### Basic Examples (5 screenshots)

- `01_basic_listview.png` - Basic ListView pagination
- `02_gridview.png` - GridView pagination
- `03_retry_mechanism.png` - Automatic retry demo
- `04_filter_search.png` - Filter and search
- `05_pull_to_refresh.png` - Pull to refresh

### Stream Examples (3 screenshots)

- `06_single_stream.png` - Single stream real-time updates
- `07_multi_stream.png` - Multiple streams switching
- `08_merged_streams.png` - Merged streams

### Advanced Examples (13 screenshots)

- `09_cursor_pagination.png` - Cursor-based pagination
- `10_horizontal_scroll.png` - Horizontal scrolling list
- `11_page_view.png` - PageView pagination
- `12_staggered_grid.png` - StaggeredGridView
- `13_custom_states.png` - Custom loading/empty/error states
- `14_scroll_control.png` - Programmatic scrolling
- `15_before_build_hook.png` - beforeBuild hook
- `16_has_reached_end.png` - Reached end detection
- `17_custom_view_builder.png` - Custom view builder
- `18_reorderable_list.png` - Drag and drop reordering
- `19_state_separation.png` - State separation
- `20_smart_preloading.png` - Smart preloading
- `21_custom_error_handling.png` - Custom error handling

### Error Handling Examples (7 screenshots)

- `22_basic_error.png` - Basic error handling
- `23_network_errors.png` - Network error types
- `24_retry_patterns.png` - Retry patterns (manual, auto, exponential)
- `25_custom_error_widgets.png` - All 6 error widget styles
- `26_error_recovery.png` - Error recovery strategies
- `27_graceful_degradation.png` - Graceful degradation
- `28_load_more_errors.png` - Load more error handling

## Capturing Screenshots

### Using Flutter DevTools

1. Run the example app:

   ```bash
   cd example
   flutter run
   ```

2. Navigate to the screen you want to capture

3. Take screenshot using:
   - **Android Studio**: Tools → Layout Inspector → Export Image
   - **VS Code**: Flutter DevTools → Screenshot
   - **Device**: Use device screenshot feature

### Using Command Line (Automated)

```bash
# Install screenshot tool
flutter pub global activate screenshots

# Configure and capture
flutter pub global run screenshots:main
```

### Recommended Settings

- **Resolution**: 1080x2400 (phone) or 1200x2560 (tablet)
- **Format**: PNG with transparency
- **Device Frame**: Include device frame for better presentation
- **Light/Dark Mode**: Capture in light mode for consistency
- **Quality**: High quality, no compression

## Image Optimization

After capturing, optimize images:

```bash
# Install ImageMagick
sudo apt-get install imagemagick  # Linux
brew install imagemagick          # macOS

# Resize and optimize
for file in screenshots/**/*.png; do
  convert "$file" -resize 1080x2400 -quality 85 "$file"
done
```

## Adding to README

Screenshots are automatically referenced in the main README.md using relative paths:

```markdown
![Basic ListView](screenshots/basic/01_basic_listview.png)
```

## Git LFS (Optional)

For large screenshot files, consider using Git LFS:

```bash
git lfs install
git lfs track "screenshots/**/*.png"
git add .gitattributes
```

## Screenshot Checklist

- [ ] All 28 example screens captured
- [ ] Images optimized (< 500KB each)
- [ ] Consistent device frame used
- [ ] Light mode for all screenshots
- [ ] No sensitive data visible
- [ ] Clear, readable text
- [ ] Representative of actual functionality

## Placeholder Images

Until real screenshots are available, we use placeholder images in the README. Replace these with actual screenshots when ready.

## Contributing Screenshots

When contributing screenshots:

1. Follow naming convention
2. Optimize image size
3. Use consistent device/theme
4. Update this README if adding new categories
5. Include in PR description which screenshots were updated
