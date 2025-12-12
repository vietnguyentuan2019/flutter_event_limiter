// callback_widgets.dart
//
// USAGE: Prefer wrapper widgets (ThrottledInkWell, AsyncThrottledCallback, DebouncedTextController)
// ADVANCED: Use direct classes (Throttler, AsyncThrottler, Debouncer) only for advanced features

import 'package:flutter/material.dart';
import 'callback_controller.dart';
import 'concurrency_mode.dart';

/// QUICK START:
///
/// Button anti-spam:
///   ThrottledInkWell(onTap: () => submit(), child: MyButton())
///
/// Form submit (with loading state):
///   AsyncThrottledCallbackBuilder(
///     onPressed: () async => await api.submit(),
///     onError: (e) => showSnackbar('Error: $e'),
///     builder: (ctx, cb, isLoading) => ElevatedButton(
///       onPressed: isLoading ? null : cb,
///       child: isLoading ? CircularProgressIndicator() : Text('Submit'),
///     ),
///   )
///
/// Search API (with loading + auto-cancel):
///   ```dart
///   AsyncDebouncedCallbackBuilder<List<User>>(
///     onChanged: (text) async => await searchApi(text),
///     onSuccess: (results) => setState(() => _results = results),
///     onError: (e) => showSnackbar('Error: $e'),
///     builder: (ctx, cb, isLoading) => TextField(
///       onChanged: cb,
///       decoration: InputDecoration(
///         suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.search),
///       ),
///     ),
///   )
///   ```
///
/// Search input controller (with loading state):
///   ```dart
///   AsyncDebouncedTextController<List<User>>(
///     onChanged: (text) async => await searchApi(text),
///     onSuccess: (results) { if (mounted) setState(() => _results = results); },
///     onLoadingChanged: (isLoading) { if (mounted) setState(() => _isLoading = isLoading); },
///   )
///   ```
///
/// Available widgets:
///   Universal Builders (for ANY widget - future-proof):
///   - ThrottledBuilder (sync throttle for any widget)
///   - DebouncedBuilder (sync debounce for any widget)
///   - AsyncThrottledBuilder (async throttle for any widget)
///   - AsyncDebouncedBuilder (async debounce for any widget)
///
///   Enhanced (with loading/error state):
///   - AsyncThrottledCallbackBuilder (form submit with loading state)
///   - AsyncDebouncedCallbackBuilder (search with loading state)
///   - AsyncDebouncedTextController (controller with loading state)
///
///   Basic Wrappers:
///   - ThrottledInkWell, ThrottledTapWidget, ThrottledCallback
///   - AsyncThrottledCallback (form submit, manual mounted check)
///   - AsyncDebouncedCallback (search API, manual mounted check)
///   - DebouncedTextController, DebouncedTapWidget, DebouncedCallback
///
/// See CALLBACK_GUIDE.md for detailed documentation and comparison table.

/// Throttled callback wrapper. Used by BaseButton. Prefer ThrottledInkWell for tap events.
class ThrottledCallback extends StatefulWidget {
  final VoidCallback? onPressed;
  final Duration duration;
  final Widget Function(BuildContext context, VoidCallback? throttledCallback)
      builder;

  const ThrottledCallback({
    super.key,
    required this.onPressed,
    required this.builder,
    this.duration = Throttler.defaultDuration,
  });

  @override
  State<ThrottledCallback> createState() => _ThrottledCallbackState();
}

class _ThrottledCallbackState extends State<ThrottledCallback> {
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _throttler.wrap(widget.onPressed));
  }
}

/// Universal throttle builder that works with ANY widget.
///
/// **Problem solved:** ThrottledInkWell only supports basic InkWell params.
/// If you need advanced features (onLongPress, mouseCursor, custom widgets),
/// use ThrottledBuilder instead.
///
/// **Usage:**
/// ```dart
/// ThrottledBuilder(
///   duration: Duration(milliseconds: 500),
///   builder: (context, throttle) {
///     return InkWell(
///       onTap: throttle(() => handleTap()),
///       onLongPress: throttle(() => handleLongPress()),  // ✅ Full InkWell support!
///       onDoubleTap: throttle(() => handleDoubleTap()),
///       child: MyWidget(),
///     );
///   },
/// )
///
/// // Works with ANY widget:
/// ThrottledBuilder(
///   builder: (context, throttle) {
///     return ElevatedButton(
///       onPressed: throttle(() => submit()),
///       child: Text('Submit'),
///     );
///   },
/// )
/// ```
class ThrottledBuilder extends StatefulWidget {
  final Duration duration;
  final Widget Function(
    BuildContext context,
    VoidCallback? Function(VoidCallback? action) throttle,
  ) builder;

  const ThrottledBuilder({
    super.key,
    required this.builder,
    this.duration = Throttler.defaultDuration,
  });

  @override
  State<ThrottledBuilder> createState() => _ThrottledBuilderState();
}

class _ThrottledBuilderState extends State<ThrottledBuilder> {
  late Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
  }

  @override
  void didUpdateWidget(ThrottledBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recreate throttler if duration changes (rare but ensures correctness)
    if (oldWidget.duration != widget.duration) {
      _throttler.dispose();
      _throttler = Throttler(duration: widget.duration);
    }
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _throttler.wrap);
  }
}

/// Universal debounce builder that works with ANY widget.
///
/// **Use case:** Custom debounce logic beyond text input.
///
/// **Usage:**
/// ```dart
/// DebouncedBuilder(
///   duration: Duration(milliseconds: 300),
///   builder: (context, debounce) {
///     return Slider(
///       onChanged: (value) => debounce(() => saveValue(value)),
///     );
///   },
/// )
/// ```
class DebouncedBuilder extends StatefulWidget {
  final Duration duration;
  final Widget Function(
    BuildContext context,
    VoidCallback? Function(VoidCallback? action) debounce,
  ) builder;

  const DebouncedBuilder({
    super.key,
    required this.builder,
    this.duration = Debouncer.defaultDuration,
  });

  @override
  State<DebouncedBuilder> createState() => _DebouncedBuilderState();
}

class _DebouncedBuilderState extends State<DebouncedBuilder> {
  late Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: widget.duration);
  }

  @override
  void didUpdateWidget(DebouncedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _debouncer.dispose();
      _debouncer = Debouncer(duration: widget.duration);
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _debouncer.wrap);
  }
}

/// Universal async throttle builder that works with ANY widget.
///
/// **Use case:** Custom async operations with throttle lock.
///
/// **⚠️ CRITICAL NOTES:**
///
/// 1. **Mounted Check:** Always check `mounted` before using BuildContext after await!
///
/// 2. **Error Handling:** You MUST handle errors inside your action using try-catch.
///    Errors are NOT automatically caught by this builder. Unhandled errors will
///    become unhandled exceptions.
///
/// **Usage:**
/// ```dart
/// AsyncThrottledBuilder(
///   maxDuration: Duration(seconds: 15),
///   builder: (context, throttle) {
///     return ElevatedButton(
///       onPressed: throttle(() async {
///         try {
///           await api.submit();
///           if (!mounted) return;  // ✅ Check first!
///           Navigator.pop(context);
///         } catch (e) {
///           if (!mounted) return;
///           ScaffoldMessenger.of(context).showSnackBar(
///             SnackBar(content: Text('Error: $e')),
///           );
///         }
///       }),
///       child: Text('Submit'),
///     );
///   },
/// )
/// ```
///
/// **For automatic error handling,** use AsyncThrottledCallbackBuilder instead.
class AsyncThrottledBuilder extends StatefulWidget {
  final Duration? maxDuration;
  final Widget Function(
    BuildContext context,
    VoidCallback? Function(Future<void> Function()? action) throttle,
  ) builder;

  const AsyncThrottledBuilder({
    super.key,
    required this.builder,
    this.maxDuration,
  });

  @override
  State<AsyncThrottledBuilder> createState() => _AsyncThrottledBuilderState();
}

class _AsyncThrottledBuilderState extends State<AsyncThrottledBuilder> {
  late AsyncThrottler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = AsyncThrottler(maxDuration: widget.maxDuration);
  }

  @override
  void didUpdateWidget(AsyncThrottledBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maxDuration != widget.maxDuration) {
      _throttler.dispose();
      _throttler = AsyncThrottler(maxDuration: widget.maxDuration);
    }
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _throttler.wrap);
  }
}

/// Universal async debounce builder that works with ANY widget.
///
/// **Use case:** Custom async debounce logic with auto-cancel.
///
/// **⚠️ CRITICAL NOTES:**
///
/// 1. **Mounted Check:** Always check `mounted` before setState after await!
///
/// 2. **Error Handling:** You MUST handle errors inside your action using try-catch.
///    Errors are NOT automatically caught by this builder. Unhandled errors will
///    become unhandled exceptions.
///
/// **Usage:**
/// ```dart
/// AsyncDebouncedBuilder(
///   duration: Duration(milliseconds: 300),
///   builder: (context, debounce) {
///     return TextField(
///       onChanged: (text) => debounce(() async {
///         try {
///           final results = await searchApi(text);
///           if (!mounted) return;  // ✅ Check first!
///           setState(() => _results = results);
///         } catch (e) {
///           if (!mounted) return;
///           // Handle error (e.g., show snackbar)
///           ScaffoldMessenger.of(context).showSnackBar(
///             SnackBar(content: Text('Error: $e')),
///           );
///         }
///       }),
///     );
///   },
/// )
/// ```
///
/// **For automatic error handling,** use AsyncDebouncedCallbackBuilder instead.
class AsyncDebouncedBuilder extends StatefulWidget {
  final Duration duration;
  final Widget Function(
    BuildContext context,
    void Function(Future<void> Function() action) debounce,
  ) builder;

  const AsyncDebouncedBuilder({
    super.key,
    required this.builder,
    this.duration = AsyncDebouncer.defaultDuration,
  });

  @override
  State<AsyncDebouncedBuilder> createState() => _AsyncDebouncedBuilderState();
}

class _AsyncDebouncedBuilderState extends State<AsyncDebouncedBuilder> {
  late AsyncDebouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = AsyncDebouncer(duration: widget.duration);
  }

  @override
  void didUpdateWidget(AsyncDebouncedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _debouncer.dispose();
      _debouncer = AsyncDebouncer(duration: widget.duration);
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _wrapDebounce(Future<void> Function() action) {
    _debouncer.run(action);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _wrapDebounce);
  }
}

/// Async debounced callback wrapper with auto-cancel for search/autocomplete.
///
/// Delays execution by 300ms and cancels previous pending calls.
/// Use this for search APIs to avoid race conditions.
///
/// **⚠️ CRITICAL IMPLEMENTATION NOTES:**
///
/// 1. **Mounted Check is REQUIRED:**
///    While AsyncDebouncedCallback handles cancellation logic, it does NOT know
///    about the Widget's lifecycle. You MUST check `mounted` before calling
///    setState() or using BuildContext after await.
///
///    ```dart
///    AsyncDebouncedCallback(
///      onChanged: (text) async {
///        final results = await searchApi(text);
///        if (!mounted) return;  // ✅ YOU MUST CHECK THIS
///        setState(() => _searchResults = results);
///      },
///      builder: (ctx, cb) => TextField(onChanged: cb),
///    )
///    ```
///
/// 2. **How It Works:**
///    - User types "a" → starts 300ms timer
///    - User types "ab" → cancels previous timer, starts new 300ms timer
///    - After 300ms pause → executes API call for "ab"
///    - If "abc" is typed during API call, old result is ignored
///
/// 3. **State Management:**
///    This widget manages its own AsyncDebouncer internally and disposes it automatically.
///    You don't need to manage lifecycle manually (unlike using AsyncDebouncer directly).
///
/// **Example:**
/// ```dart
/// AsyncDebouncedCallback(
///   duration: Duration(milliseconds: 500),  // Optional, default 300ms
///   onChanged: (text) async {
///     final results = await searchApi(text);
///     if (!mounted) return;  // ✅ Always check before setState
///     setState(() => _searchResults = results);
///   },
///   builder: (ctx, cb) => TextField(
///     onChanged: cb,
///     decoration: InputDecoration(hintText: 'Search...'),
///   ),
/// )
/// ```
class AsyncDebouncedCallback extends StatefulWidget {
  final void Function(String)? onChanged;
  final Duration duration;
  final Widget Function(
      BuildContext context, void Function(String)? debouncedCallback) builder;

  const AsyncDebouncedCallback({
    super.key,
    required this.onChanged,
    required this.builder,
    this.duration = AsyncDebouncer.defaultDuration,
  });

  @override
  State<AsyncDebouncedCallback> createState() => _AsyncDebouncedCallbackState();
}

class _AsyncDebouncedCallbackState extends State<AsyncDebouncedCallback> {
  late final AsyncDebouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = AsyncDebouncer(duration: widget.duration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onChanged == null) {
      return widget.builder(context, null);
    }

    return widget.builder(context, (text) {
      _debouncer.run(() async {
        widget.onChanged!(text);
      });
    });
  }
}

/// Enhanced async debounced callback with loading state and error handling.
///
/// **Features:**
/// - Auto loading state management
/// - Built-in error handling
/// - Safe setState (auto-checks mounted)
/// - Auto-cancels old API calls
/// - Generic type support (not limited to String)
///
/// **Example:**
/// ```dart
/// AsyncDebouncedCallbackBuilder<List<User>>(
///   onChanged: (text) async {
///     return await searchApi(text);  // Return the result
///   },
///   onSuccess: (results) {
///     setState(() => _searchResults = results);
///   },
///   onError: (error) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Search failed: $error')),
///     );
///   },
///   builder: (context, callback, isLoading) => TextField(
///     onChanged: callback,
///     decoration: InputDecoration(
///       hintText: 'Search...',
///       suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.search),
///     ),
///   ),
/// )
/// ```
class AsyncDebouncedCallbackBuilder<T> extends StatefulWidget {
  /// Async callback that returns a result. Auto-cancels old calls.
  final Future<T> Function(String value)? onChanged;

  /// Called with result when onChanged completes successfully. Auto-checks mounted.
  final void Function(T result)? onSuccess;

  /// Called when onChanged throws an error.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Debounce duration (default 300ms).
  final Duration duration;

  /// Builder receives current loading state and callback.
  final Widget Function(
          BuildContext context, void Function(String)? callback, bool isLoading)
      builder;

  const AsyncDebouncedCallbackBuilder({
    super.key,
    required this.onChanged,
    required this.builder,
    this.onSuccess,
    this.onError,
    this.duration = AsyncDebouncer.defaultDuration,
  });

  @override
  State<AsyncDebouncedCallbackBuilder<T>> createState() =>
      _AsyncDebouncedCallbackBuilderState<T>();
}

class _AsyncDebouncedCallbackBuilderState<T>
    extends State<AsyncDebouncedCallbackBuilder<T>> {
  late final AsyncDebouncer _debouncer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _debouncer = AsyncDebouncer(duration: widget.duration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _handleChanged(String text) async {
    if (widget.onChanged == null) return;

    // Set loading state
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _debouncer.run(() async {
        return await widget.onChanged!(text);
      });

      // Only process result if not cancelled (result != null)
      if (result != null) {
        // Success: Turn off loading and process result
        if (mounted) {
          setState(() => _isLoading = false);
        }

        // Call onSuccess with result, auto-checks mounted
        if (mounted && widget.onSuccess != null) {
          widget.onSuccess!(result);
        }
      }
      // ✅ FIX: If result == null (cancelled), DON'T turn off loading!
      // The newer call is responsible for managing loading state.
      // Turning off loading here would cause UI flicker (loading off while new call is running).
    } catch (error, stackTrace) {
      // Safe setState - only update if still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Call error handler even if unmounted
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.onChanged == null ? null : _handleChanged,
      _isLoading,
    );
  }
}

/// Async callback wrapper. Locks until Future completes (for form submit).
///
/// ⚠️ Check `mounted` before using BuildContext after await!
///
/// Example:
/// ```dart
/// AsyncThrottledCallback(
///   onPressed: () async {
///     await api.submit();
///     if (!mounted) return;  // ✅ Check first!
///     Navigator.pop(context);
///   },
///   builder: (ctx, cb) => ElevatedButton(onPressed: cb),
/// )
/// ```
class AsyncThrottledCallback extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Duration? maxDuration;
  final Widget Function(
      BuildContext context, VoidCallback? asyncThrottledCallback) builder;

  const AsyncThrottledCallback({
    super.key,
    required this.onPressed,
    required this.builder,
    this.maxDuration,
  });

  @override
  State<AsyncThrottledCallback> createState() => _AsyncThrottledCallbackState();
}

class _AsyncThrottledCallbackState extends State<AsyncThrottledCallback> {
  late final AsyncThrottler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = AsyncThrottler(maxDuration: widget.maxDuration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _throttler.wrap(widget.onPressed));
  }
}

/// Enhanced async callback wrapper with loading state and error handling.
///
/// **Features:**
/// - Auto loading state management
/// - Built-in error handling
/// - Safe setState (auto-checks mounted)
/// - Prevents duplicate submissions
///
/// **Example:**
/// ```dart
/// AsyncThrottledCallbackBuilder(
///   onPressed: () async {
///     await api.submitForm();
///     // No need to check mounted - handled automatically!
///     Navigator.pop(context);
///   },
///   onError: (error) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text('Error: $error')),
///     );
///   },
///   builder: (context, callback, isLoading) => ElevatedButton(
///     onPressed: isLoading ? null : callback,
///     child: isLoading
///       ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
///       : Text('Submit'),
///   ),
/// )
/// ```
class AsyncThrottledCallbackBuilder extends StatefulWidget {
  /// Async callback to execute. Context operations are auto-protected with mounted check.
  final Future<void> Function()? onPressed;

  /// Called when onPressed throws an error. Runs even if widget is unmounted.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Optional callback when operation completes successfully.
  final VoidCallback? onSuccess;

  /// Max duration before auto-unlock (default 15s). Use longer for file uploads.
  final Duration? maxDuration;

  /// Builder receives current loading state.
  final Widget Function(
      BuildContext context, VoidCallback? callback, bool isLoading) builder;

  const AsyncThrottledCallbackBuilder({
    super.key,
    required this.onPressed,
    required this.builder,
    this.onError,
    this.onSuccess,
    this.maxDuration,
  });

  @override
  State<AsyncThrottledCallbackBuilder> createState() =>
      _AsyncThrottledCallbackBuilderState();
}

class _AsyncThrottledCallbackBuilderState
    extends State<AsyncThrottledCallbackBuilder> {
  late final AsyncThrottler _throttler;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _throttler = AsyncThrottler(maxDuration: widget.maxDuration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isLoading || widget.onPressed == null) return;

    setState(() => _isLoading = true);

    try {
      await _throttler.call(() async {
        await widget.onPressed!();
      });

      // Safe setState - only update if still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Call onSuccess even if unmounted (e.g., for analytics)
      widget.onSuccess?.call();
    } catch (error, stackTrace) {
      // Safe setState - only update if still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Call error handler even if unmounted
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.onPressed == null ? null : _handlePress,
      _isLoading,
    );
  }
}

/// Advanced async throttled callback builder with concurrency control.
///
/// **NEW in v1.2.0:** Adds concurrency modes for handling multiple async operations.
///
/// **Features:**
/// - **Auto loading state** - Tracks execution automatically
/// - **Concurrency modes** - drop, enqueue, replace, keepLatest
/// - **Queue size tracking** - Display pending operations count
/// - **Error handling** - onError callback with stack trace
/// - **Auto-dispose** - No manual cleanup needed
/// - **Mounted checks** - Safe setState after async operations
///
/// **Use cases:**
/// - Chat app: `enqueue` mode to send messages in order
/// - Search: `replace` mode to cancel old queries
/// - Auto-save: `keepLatest` mode to save final version after edits
/// - Payment: `drop` mode (default) to prevent duplicate charges
///
/// **Example: Chat Message Sender (Enqueue Mode)**
/// ```dart
/// ConcurrentAsyncThrottledBuilder(
///   mode: ConcurrencyMode.enqueue,
///   maxDuration: Duration(seconds: 30),
///   onPressed: () async {
///     await api.sendMessage(_messageController.text);
///     _messageController.clear();
///   },
///   onError: (error, stack) {
///     showSnackBar('Failed to send: $error');
///   },
///   builder: (context, callback, isLoading, pendingCount) {
///     return Column(
///       children: [
///         if (pendingCount > 0)
///           Text('Sending ${pendingCount} messages...'),
///         ElevatedButton(
///           onPressed: isLoading ? null : callback,
///           child: isLoading
///             ? CircularProgressIndicator()
///             : Text('Send'),
///         ),
///       ],
///     );
///   },
/// )
/// ```
///
/// **Example: Search with Replace Mode**
/// ```dart
/// ConcurrentAsyncThrottledBuilder(
///   mode: ConcurrencyMode.replace,
///   maxDuration: Duration(seconds: 10),
///   onPressed: () async {
///     final results = await api.search(_searchQuery);
///     setState(() => _results = results);
///   },
///   builder: (context, callback, isLoading, _) {
///     return SearchBar(
///       onChanged: (query) {
///         _searchQuery = query;
///         callback?.call(); // Replaces previous search
///       },
///       trailing: isLoading ? CircularProgressIndicator() : null,
///     );
///   },
/// )
/// ```
///
/// **Example: Auto-save with Keep Latest Mode**
/// ```dart
/// ConcurrentAsyncThrottledBuilder(
///   mode: ConcurrencyMode.keepLatest,
///   maxDuration: Duration(seconds: 30),
///   onPressed: () async {
///     await api.saveDraft(_draftContent);
///   },
///   onSuccess: () => showSnackBar('Draft saved'),
///   builder: (context, callback, isLoading, _) {
///     return TextField(
///       onChanged: (text) {
///         _draftContent = text;
///         callback?.call(); // Keeps latest version
///       },
///       decoration: InputDecoration(
///         suffixIcon: isLoading
///           ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
///           : Icon(Icons.check, color: Colors.green),
///       ),
///     );
///   },
/// )
/// ```
class ConcurrentAsyncThrottledBuilder extends StatefulWidget {
  /// Concurrency mode for handling multiple async operations.
  final ConcurrencyMode mode;

  /// Async callback to execute. Context operations are auto-protected with mounted check.
  final Future<void> Function()? onPressed;

  /// Called when onPressed throws an error. Runs even if widget is unmounted.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Optional callback when operation completes successfully.
  final VoidCallback? onSuccess;

  /// Max duration before auto-unlock (default 15s). Use longer for file uploads.
  final Duration? maxDuration;

  /// Enable debug logging for troubleshooting.
  final bool debugMode;

  /// Name for debug logging (e.g., 'chat-sender', 'search-api').
  final String? name;

  /// Builder receives current loading state and pending operations count.
  ///
  /// **Parameters:**
  /// - `context`: BuildContext
  /// - `callback`: VoidCallback? to trigger the async operation
  /// - `isLoading`: bool indicating if operation is currently executing
  /// - `pendingCount`: int number of pending operations (enqueue/keepLatest modes)
  final Widget Function(
    BuildContext context,
    VoidCallback? callback,
    bool isLoading,
    int pendingCount,
  ) builder;

  const ConcurrentAsyncThrottledBuilder({
    super.key,
    this.mode = ConcurrencyMode.drop,
    required this.onPressed,
    required this.builder,
    this.onError,
    this.onSuccess,
    this.maxDuration,
    this.debugMode = false,
    this.name,
  });

  @override
  State<ConcurrentAsyncThrottledBuilder> createState() =>
      _ConcurrentAsyncThrottledBuilderState();
}

class _ConcurrentAsyncThrottledBuilderState
    extends State<ConcurrentAsyncThrottledBuilder> {
  late final ConcurrentAsyncThrottler _throttler;
  bool _isLoading = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _throttler = ConcurrentAsyncThrottler(
      mode: widget.mode,
      maxDuration: widget.maxDuration,
      debugMode: widget.debugMode,
      name: widget.name,
    );
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;

    // Update loading state
    if (mounted) {
      setState(() {
        _isLoading = true;
        _pendingCount = _throttler.pendingCount;
      });
    }

    try {
      await _throttler.call(() async {
        await widget.onPressed!();
      });

      // Safe setState - only update if still mounted
      if (mounted) {
        setState(() {
          _isLoading = _throttler.isLocked;
          _pendingCount = _throttler.pendingCount;
        });
      }

      // Call onSuccess even if unmounted (e.g., for analytics)
      widget.onSuccess?.call();
    } catch (error, stackTrace) {
      // Safe setState - only update if still mounted
      if (mounted) {
        setState(() {
          _isLoading = _throttler.isLocked;
          _pendingCount = _throttler.pendingCount;
        });
      }

      // Call error handler even if unmounted
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      widget.onPressed == null ? null : _handlePress,
      _isLoading,
      _pendingCount,
    );
  }
}

/// Debounced callback wrapper. For search input use DebouncedTextController instead.
class DebouncedCallback extends StatefulWidget {
  final VoidCallback? onChanged;
  final Duration duration;
  final Widget Function(BuildContext context, VoidCallback? debouncedCallback)
      builder;

  const DebouncedCallback({
    super.key,
    required this.onChanged,
    required this.builder,
    this.duration = Debouncer.defaultDuration,
  });

  @override
  State<DebouncedCallback> createState() => _DebouncedCallbackState();
}

class _DebouncedCallbackState extends State<DebouncedCallback> {
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: widget.duration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _debouncer.wrap(widget.onChanged));
  }
}

/// Throttled tap with ripple effect (500ms window).
///
/// **Supports:** onTap, onDoubleTap, onLongPress (common gestures).
/// **For advanced features:** (mouseCursor, statesController, etc.) use ThrottledBuilder.
///
/// **Example:**
/// ```dart
/// ThrottledInkWell(
///   onTap: () => handleTap(),
///   onLongPress: () => showMenu(),  // ✅ Now supported!
///   child: MyButton(),
/// )
/// ```
class ThrottledInkWell extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final Duration duration;
  final BorderRadius? borderRadius;
  final Color? splashColor;
  final Color? highlightColor;
  final InteractiveInkFeatureFactory? splashFactory;

  const ThrottledInkWell({
    super.key,
    required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    required this.child,
    this.duration = Throttler.defaultDuration,
    this.borderRadius,
    this.splashColor,
    this.highlightColor,
    this.splashFactory,
  });

  @override
  State<ThrottledInkWell> createState() => _ThrottledInkWellState();
}

class _ThrottledInkWellState extends State<ThrottledInkWell> {
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _throttler.wrap(widget.onTap),
      onDoubleTap: _throttler.wrap(widget.onDoubleTap),
      onLongPress: _throttler.wrap(widget.onLongPress),
      borderRadius: widget.borderRadius,
      splashColor: widget.splashColor,
      highlightColor: widget.highlightColor,
      splashFactory: widget.splashFactory,
      child: widget.child,
    );
  }
}

/// Throttled tap without ripple. Use ThrottledInkWell for ripple effect.
class ThrottledTapWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Duration duration;
  final HitTestBehavior behavior;

  const ThrottledTapWidget({
    super.key,
    required this.onTap,
    required this.child,
    this.duration = Throttler.defaultDuration,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<ThrottledTapWidget> createState() => _ThrottledTapWidgetState();
}

class _ThrottledTapWidgetState extends State<ThrottledTapWidget> {
  late final Throttler _throttler;

  @override
  void initState() {
    super.initState();
    _throttler = Throttler(duration: widget.duration);
  }

  @override
  void dispose() {
    _throttler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: widget.behavior,
        onTap: _throttler.wrap(widget.onTap),
        child: widget.child);
  }
}

/// Debounced tap (waits until user stops). Rarely needed - use for auto-save.
class DebouncedTapWidget extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final Duration duration;
  final HitTestBehavior behavior;

  const DebouncedTapWidget({
    super.key,
    required this.onTap,
    required this.child,
    this.duration = Debouncer.defaultDuration,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<DebouncedTapWidget> createState() => _DebouncedTapWidgetState();
}

class _DebouncedTapWidgetState extends State<DebouncedTapWidget> {
  late final Debouncer _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = Debouncer(duration: widget.duration);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: widget.behavior,
        onTap: _debouncer.wrap(widget.onTap),
        child: widget.child);
  }
}

/// TextField controller with debounce (default 300ms). Triggers onChanged after user pauses typing.
///
/// **⚠️ CRITICAL IMPLEMENTATION NOTES:**
///
/// 1. **Disposal is REQUIRED:**
///    DebouncedTextController creates its own TextEditingController if one isn't provided.
///    You MUST call dispose() in your State's dispose() method to prevent memory leaks.
///
///    ```dart
///    class _State extends State {
///      final _controller = DebouncedTextController(
///        onChanged: (text) => searchApi(text),
///      );
///
///      @override
///      void dispose() {
///        _controller.dispose();  // ✅ REQUIRED to prevent memory leak
///        super.dispose();
///      }
///    }
///    ```
///
/// 2. **Mounted Check for Async Operations:**
///    If onChanged performs async operations, check `mounted` before setState:
///
///    ```dart
///    DebouncedTextController(
///      onChanged: (text) async {
///        final results = await searchApi(text);
///        if (!mounted) return;  // ✅ Check before setState
///        setState(() => _results = results);
///      },
///    )
///    ```
///
/// 3. **External Controller:**
///    If you pass an external controller, YOU are responsible for disposing it:
///
///    ```dart
///    final _textController = TextEditingController();
///    final _debouncedController = DebouncedTextController(
///      controller: _textController,  // External
///      onChanged: (text) => search(text),
///    );
///
///    @override
///    void dispose() {
///      _debouncedController.dispose();  // Disposes debouncer only
///      _textController.dispose();       // YOU must dispose this
///      super.dispose();
///    }
///    ```
class DebouncedTextController {
  final TextEditingController textController;
  final void Function(String value) onChanged;
  final Duration duration;
  final bool _isExternalController;

  late final Debouncer _debouncer;
  String _previousValue = '';
  bool _shouldForceNextTrigger = false; // For setText(triggerCallback: true)

  DebouncedTextController({
    required this.onChanged,
    this.duration = Debouncer.defaultDuration,
    TextEditingController? controller,
    String? initialValue,
  })  : assert(
          controller == null || initialValue == null,
          'Cannot provide both controller and initialValue.\n'
          'If using an external controller, set the initial text directly on it:\n'
          '  final controller = TextEditingController(text: "initial");\n'
          '  DebouncedTextController(controller: controller, ...)',
        ),
        textController =
            controller ?? TextEditingController(text: initialValue),
        _isExternalController = controller != null {
    _previousValue = textController.text;
    _debouncer = Debouncer(duration: duration);
    // Add listener last to avoid memory leak if constructor throws
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentValue = textController.text;
    if (_shouldForceNextTrigger || currentValue != _previousValue) {
      _shouldForceNextTrigger = false;
      _debouncer(() {
        onChanged(currentValue);
        _previousValue = currentValue;
      });
    }
  }

  String get text => textController.text;

  /// Sets text. [triggerCallback] forces onChanged even if value unchanged (for clear actions).
  void setText(String value, {bool triggerCallback = false}) {
    if (triggerCallback) {
      _shouldForceNextTrigger = true;
    }
    _previousValue = value;
    textController.text = value;
  }

  void clear({bool triggerCallback = true}) {
    setText('', triggerCallback: triggerCallback);
  }

  void cancel() {
    _debouncer.cancel();
  }

  void flush() {
    _debouncer.flush(() => onChanged(textController.text));
  }

  void dispose() {
    textController.removeListener(_onTextChanged);
    if (!_isExternalController) {
      textController.dispose();
    }
    _debouncer.dispose();
  }
}

/// Enhanced debounced text controller with loading/error state support for async operations.
///
/// Renamed from `DebouncedTextControllerWithState` for better naming consistency.
///
/// **Features:**
/// - Auto loading state management
/// - Built-in error handling
/// - Safe setState (auto-checks mounted via callbacks)
/// - Auto-cancels old API calls
/// - Generic return type support
///
/// **Example:**
/// ```dart
/// class _MyState extends State<MyWidget> {
///   late final _controller = AsyncDebouncedTextController<List<User>>(
///     onChanged: (text) async {
///       return await searchApi(text);  // Return the result
///     },
///     onSuccess: (results) {
///       if (!mounted) return;
///       setState(() => _searchResults = results);
///     },
///     onError: (error) {
///       if (!mounted) return;
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text('Error: $error')),
///       );
///     },
///     onLoadingChanged: (isLoading) {
///       if (!mounted) return;
///       setState(() => _isSearching = isLoading);
///     },
///   );
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return TextField(
///       controller: _controller.textController,
///       decoration: InputDecoration(
///         suffixIcon: _isSearching
///           ? CircularProgressIndicator()
///           : Icon(Icons.search),
///       ),
///     );
///   }
/// }
/// ```
class AsyncDebouncedTextController<T> {
  final TextEditingController textController;
  final Future<T> Function(String value) onChanged;
  final void Function(T result)? onSuccess;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final void Function(bool isLoading)? onLoadingChanged;
  final Duration duration;
  final bool _isExternalController;

  late final AsyncDebouncer _debouncer;
  String _previousValue = '';
  bool _shouldForceNextTrigger = false;
  bool _isLoading = false;

  AsyncDebouncedTextController({
    required this.onChanged,
    this.onSuccess,
    this.onError,
    this.onLoadingChanged,
    this.duration = AsyncDebouncer.defaultDuration,
    TextEditingController? controller,
    String? initialValue,
  })  : assert(
          controller == null || initialValue == null,
          'Cannot provide both controller and initialValue.\n'
          'If using an external controller, set the initial text directly on it:\n'
          '  final controller = TextEditingController(text: "initial");\n'
          '  AsyncDebouncedTextController(controller: controller, ...)',
        ),
        textController =
            controller ?? TextEditingController(text: initialValue),
        _isExternalController = controller != null {
    _previousValue = textController.text;
    _debouncer = AsyncDebouncer(duration: duration);
    // Add listener last to avoid memory leak if constructor throws
    textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentValue = textController.text;
    if (_shouldForceNextTrigger || currentValue != _previousValue) {
      _shouldForceNextTrigger = false;
      _executeAsync(currentValue);
    }
  }

  Future<void> _executeAsync(String value) async {
    // Set loading state
    _setLoadingState(true);

    try {
      final result = await _debouncer.run(() async {
        return await onChanged(value);
      });

      // Only process result if not cancelled
      if (result != null) {
        // Success: Turn off loading and process result
        _setLoadingState(false);
        onSuccess?.call(result);
        _previousValue = value;
      }
      // ✅ FIX: If result == null (cancelled), DON'T turn off loading!
      // The newer call is responsible for managing loading state.
      // Turning off loading here would cause UI flicker (loading off while new call is running).
    } catch (error, stackTrace) {
      _setLoadingState(false);
      onError?.call(error, stackTrace);
    }
  }

  void _setLoadingState(bool isLoading) {
    if (_isLoading != isLoading) {
      _isLoading = isLoading;
      onLoadingChanged?.call(isLoading);
    }
  }

  String get text => textController.text;
  bool get isLoading => _isLoading;

  /// Sets text. [triggerCallback] forces onChanged even if value unchanged.
  void setText(String value, {bool triggerCallback = false}) {
    if (triggerCallback) {
      _shouldForceNextTrigger = true;
    }
    _previousValue = value;
    textController.text = value;
  }

  void clear({bool triggerCallback = true}) {
    setText('', triggerCallback: triggerCallback);
  }

  void cancel() {
    _debouncer.cancel();
    _setLoadingState(false);
  }

  void dispose() {
    textController.removeListener(_onTextChanged);
    if (!_isExternalController) {
      textController.dispose();
    }
    _debouncer.dispose();
  }
}
