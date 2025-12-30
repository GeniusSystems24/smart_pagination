part of '../../pagination.dart';

/// A search box widget that connects to a SmartPaginationCubit for searching.
///
/// This widget provides a text field that triggers search operations on the
/// connected cubit when the user types.
///
/// Example:
/// ```dart
/// SmartSearchBox<Product>(
///   controller: searchController,
///   decoration: InputDecoration(
///     hintText: 'Search products...',
///     prefixIcon: Icon(Icons.search),
///   ),
/// )
/// ```
class SmartSearchBox<T> extends StatelessWidget {
  const SmartSearchBox({
    super.key,
    required this.controller,
    this.decoration,
    this.style,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.search,
    this.keyboardType = TextInputType.text,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.showClearButton = true,
    this.clearButtonBuilder,
    this.prefixIcon,
    this.suffixIcon,
    this.contentPadding,
    this.filled,
    this.fillColor,
    this.borderRadius,
    this.border,
    this.focusedBorder,
    this.enabledBorder,
    this.validator,
    this.inputFormatters,
    this.autovalidateMode,
    this.onChanged,
    this.maxLength,
    this.maxLengthEnforcement,
    this.buildCounter,
  });

  /// The search controller managing this search box.
  final SmartSearchController<T> controller;

  /// Decoration for the text field.
  final InputDecoration? decoration;

  /// Text style for the search input.
  final TextStyle? style;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// The action button on the keyboard.
  final TextInputAction textInputAction;

  /// The type of keyboard to display.
  final TextInputType keyboardType;

  /// Called when the user submits the search (e.g., presses Enter).
  final ValueChanged<String>? onSubmitted;

  /// Called when the text field is tapped.
  final VoidCallback? onTap;

  /// Whether the text field is enabled.
  final bool enabled;

  /// Whether the text field is read-only.
  final bool readOnly;

  /// Whether to show a clear button when there's text.
  final bool showClearButton;

  /// Custom builder for the clear button.
  final Widget Function(VoidCallback onClear)? clearButtonBuilder;

  /// Icon to show at the start of the text field.
  final Widget? prefixIcon;

  /// Icon to show at the end of the text field (before clear button).
  final Widget? suffixIcon;

  /// Padding for the content inside the text field.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether to fill the text field background.
  final bool? filled;

  /// Background fill color.
  final Color? fillColor;

  /// Border radius for the text field.
  final BorderRadius? borderRadius;

  /// Default border.
  final InputBorder? border;

  /// Border when focused.
  final InputBorder? focusedBorder;

  /// Border when enabled but not focused.
  final InputBorder? enabledBorder;

  /// Validator function for form validation.
  ///
  /// Returns an error string if validation fails, null otherwise.
  final String? Function(String?)? validator;

  /// Input formatters to restrict or format input.
  ///
  /// Example:
  /// ```dart
  /// inputFormatters: [
  ///   FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
  ///   LengthLimitingTextInputFormatter(50),
  /// ]
  /// ```
  final List<TextInputFormatter>? inputFormatters;

  /// When to validate the input.
  final AutovalidateMode? autovalidateMode;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Maximum length of the input.
  final int? maxLength;

  /// How to enforce the max length.
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Custom counter builder for showing character count.
  final InputCounterWidgetBuilder? buildCounter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Focus(
          skipTraversal: true,
          onKeyEvent: (node, event) {
            // Handle keyboard navigation and prevent propagation if handled
            if (controller.handleKeyEvent(event)) {
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: validator != null
              ? TextFormField(
                  controller: controller.textController,
                  focusNode: controller.focusNode,
                  decoration: _buildDecoration(context),
                  style: style,
                  textCapitalization: textCapitalization,
                  textInputAction: textInputAction,
                  keyboardType: keyboardType,
                  autofocus: controller.config.autoFocus,
                  enabled: enabled,
                  readOnly: readOnly,
                  validator: validator,
                  autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
                  inputFormatters: inputFormatters,
                  maxLength: maxLength,
                  maxLengthEnforcement: maxLengthEnforcement,
                  buildCounter: buildCounter,
                  onChanged: (value) {
                    onChanged?.call(value);
                  },
                  onFieldSubmitted: (value) {
                    controller.searchNow();
                    onSubmitted?.call(value);
                  },
                  onTap: () {
                    controller.showOverlay();
                    onTap?.call();
                  },
                )
              : TextField(
                  controller: controller.textController,
                  focusNode: controller.focusNode,
                  decoration: _buildDecoration(context),
                  style: style,
                  textCapitalization: textCapitalization,
                  textInputAction: textInputAction,
                  keyboardType: keyboardType,
                  autofocus: controller.config.autoFocus,
                  enabled: enabled,
                  readOnly: readOnly,
                  inputFormatters: inputFormatters,
                  maxLength: maxLength,
                  maxLengthEnforcement: maxLengthEnforcement,
                  buildCounter: buildCounter,
                  onChanged: (value) {
                    onChanged?.call(value);
                  },
                  onSubmitted: (value) {
                    controller.searchNow();
                    onSubmitted?.call(value);
                  },
                  onTap: () {
                    controller.showOverlay();
                    onTap?.call();
                  },
                ),
        );
      },
    );
  }

  InputDecoration _buildDecoration(BuildContext context) {
    final searchTheme = SmartSearchTheme.of(context);
    final effectiveBorderRadius =
        borderRadius ?? searchTheme.searchBoxBorderRadius ?? BorderRadius.circular(12);

    final defaultBorder = OutlineInputBorder(
      borderRadius: effectiveBorderRadius,
      borderSide: BorderSide(
        color: searchTheme.searchBoxBorderColor ?? Colors.grey[300]!,
      ),
    );

    final focusedDefaultBorder = OutlineInputBorder(
      borderRadius: effectiveBorderRadius,
      borderSide: BorderSide(
        color: searchTheme.searchBoxFocusedBorderColor ?? Theme.of(context).primaryColor,
        width: 2,
      ),
    );

    final baseDecoration = decoration ??
        InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: searchTheme.searchBoxHintColor),
          filled: filled ?? true,
          fillColor: fillColor ?? searchTheme.searchBoxBackgroundColor,
          contentPadding: contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: border ?? defaultBorder,
          focusedBorder: focusedBorder ?? focusedDefaultBorder,
          enabledBorder: enabledBorder ?? defaultBorder,
        );

    // Build suffix icons
    final List<Widget> suffixWidgets = [];

    if (suffixIcon != null) {
      suffixWidgets.add(suffixIcon!);
    }

    if (showClearButton && controller.hasText) {
      if (clearButtonBuilder != null) {
        suffixWidgets.add(clearButtonBuilder!(controller.clearSearch));
      } else {
        suffixWidgets.add(
          IconButton(
            icon: Icon(
              Icons.clear,
              size: 20,
              color: searchTheme.searchBoxIconColor,
            ),
            onPressed: controller.clearSearch,
            splashRadius: 20,
          ),
        );
      }
    }

    Widget? suffixIconWidget;
    if (suffixWidgets.isNotEmpty) {
      if (suffixWidgets.length == 1) {
        suffixIconWidget = suffixWidgets.first;
      } else {
        suffixIconWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: suffixWidgets,
        );
      }
    }

    return baseDecoration.copyWith(
      prefixIcon: prefixIcon ??
          baseDecoration.prefixIcon ??
          Icon(Icons.search, color: searchTheme.searchBoxIconColor),
      suffixIcon: suffixIconWidget,
    );
  }
}
