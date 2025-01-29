/// Flutter Event Limiter - Stop spam clicks, fix race conditions, prevent memory leaks.
///
/// **Features:**
/// - Throttling: Prevent double-clicks with `ThrottledInkWell`, `Throttler`
/// - Debouncing: Auto-cancel search APIs with `AsyncDebouncedTextController`, `AsyncDebouncer`
/// - Universal Builders: Work with ANY widget using `ThrottledBuilder`, `DebouncedBuilder`
/// - Safe setState: Auto-checks `mounted` in async operations
/// - Memory safe: All dispose() paths covered
///
/// **Quick Start:**
///
/// ```dart
/// // 1. Prevent double-clicks
/// ThrottledInkWell(
///   onTap: () => submitOrder(),
///   child: Text('Submit'),
/// )
///
/// // 2. Search API with auto-cancel
/// AsyncDebouncedTextController(
///   onChanged: (text) async => await api.search(text),
///   onSuccess: (results) => setState(() => _results = results),
///   onLoadingChanged: (loading) => setState(() => _loading = loading),
/// )
///
/// // 3. Universal throttle (works with ANY widget)
/// ThrottledBuilder(
///   builder: (context, throttle) {
///     return FloatingActionButton(
///       onPressed: throttle(() => saveData()),
///       child: Icon(Icons.save),
///     );
///   },
/// )
/// ```
///
/// See individual class documentation for detailed usage.
library flutter_event_limiter;

// Core controllers (advanced usage)
export 'src/callback_controller.dart';

// Widgets and builders (recommended usage)
export 'src/callback_widgets.dart';
