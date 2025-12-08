// util/callback_controller.dart
//
// ⚠️ PREFER WRAPPER WIDGETS (callback_extension.dart)
//
// Wrappers (99% cases): ThrottledInkWell, AsyncThrottledCallback, DebouncedTextController
// Direct classes (advanced): Throttler, Debouncer, AsyncThrottler

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Base class for time-controlled callbacks (Throttler, Debouncer, ThrottleDebouncer).
abstract class CallbackController {
  final Duration duration;
  final bool debugMode;
  final String? name;
  Timer? _timer;

  CallbackController({
    required this.duration,
    this.debugMode = false,
    this.name,
  });

  /// Subclasses implement: Throttler (immediate), Debouncer (delayed), etc.
  void call(VoidCallback callback);

  /// Wraps callback for widget builders: `throttler.wrap(() => handleTap(index, item))`
  VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) return null;
    return () => call(callback);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();

  bool get isPending => _timer?.isActive ?? false;

  @protected
  set timer(Timer? value) {
    _timer?.cancel();
    _timer = value;
  }

  @protected
  Timer? get timer => _timer;

  /// Helper method for debug logging
  @protected
  void debugLog(String message) {
    if (debugMode) {
      final prefix = name != null ? '[$name] ' : '';
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('$prefix$message at $timestamp');
    }
  }
}

/// Prevents spam clicks by blocking calls for [duration] after first execution.
///
/// **Behavior:** First call executes immediately, subsequent calls blocked for 500ms.
///
/// **NEW in v1.1.0:**
/// - Debug mode: `Throttler(debugMode: true, name: 'submit-button')`
/// - Performance metrics: `onMetrics` callback tracks execution time
/// - Conditional throttling: `enabled` parameter to bypass throttle
/// - Reset on error: `resetOnError: true` auto-resets on exceptions
///
/// **Recommended:** Use `ThrottledInkWell` or `ThrottledTapWidget` instead.
/// **Direct usage:** Only if you need advanced InkWell features (onLongPress, mouseCursor, etc.)
///
/// ```dart
/// // Wrapper (recommended):
/// ThrottledInkWell(onTap: () => submit(), child: MyButton())
///
/// // Direct (advanced):
/// class _State extends State {
///   final _throttler = Throttler(
///     debugMode: true,
///     name: 'submit-button',
///     onMetrics: (duration, executed) {
///       print('Throttle took: $duration, executed: $executed');
///     },
///   );
///   void dispose() { _throttler.dispose(); super.dispose(); }
///   Widget build(context) => InkWell(
///     onTap: _throttler.wrap(() => submit()),
///     onLongPress: () => showMenu(),  // Advanced feature
///   );
/// }
/// ```
class Throttler extends CallbackController {
  static const Duration defaultDuration = Duration(milliseconds: 500);
  bool _isThrottled = false;
  final bool enabled;
  final bool resetOnError;
  final void Function(Duration executionTime, bool executed)? onMetrics;

  Throttler({
    super.duration = defaultDuration,
    super.debugMode = false,
    super.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
  });

  @override
  void call(VoidCallback callback) {
    _throttleWithDuration(callback, duration);
  }

  /// Execute with custom duration for this specific call
  void callWithDuration(VoidCallback callback, Duration customDuration) {
    _throttleWithDuration(callback, customDuration);
  }

  void _throttleWithDuration(VoidCallback callback, Duration effectiveDuration) {
    final startTime = DateTime.now();

    // Skip throttle if disabled
    if (!enabled) {
      debugLog('Throttle bypassed (disabled)');
      _executeCallback(callback, startTime, executed: true);
      return;
    }

    if (_isThrottled) {
      debugLog('Throttle blocked');
      onMetrics?.call(Duration.zero, false);
      return;
    }

    debugLog('Throttle executed');
    _executeCallback(callback, startTime, executed: true);
    _isThrottled = true;
    timer = Timer(effectiveDuration, () {
      _isThrottled = false;
      debugLog('Throttle cooldown ended');
    });
  }

  void _executeCallback(VoidCallback callback, DateTime startTime,
      {required bool executed}) {
    try {
      callback();
      final executionTime = DateTime.now().difference(startTime);
      onMetrics?.call(executionTime, executed);
    } catch (e) {
      if (resetOnError) {
        debugLog('Error occurred, resetting throttle state');
        reset();
      }
      rethrow;
    }
  }

  void reset() {
    cancel();
    _isThrottled = false;
    debugLog('Throttle reset');
  }

  bool get isThrottled => _isThrottled;

  @override
  void dispose() {
    super.dispose();
    _isThrottled = false;
  }
}

/// Delays execution until user stops calling for [duration] (default 300ms).
///
/// **Behavior:** Resets timer on each call, executes only after pause.
///
/// **NEW in v1.1.0:**
/// - Debug mode: `Debouncer(debugMode: true, name: 'search-input')`
/// - Performance metrics: `onMetrics` callback tracks timing
/// - Conditional debouncing: `enabled` parameter to bypass debounce
/// - Reset on error: `resetOnError: true` auto-resets on exceptions
///
/// **Recommended:** Use `DebouncedTextController` for search input.
/// **Direct usage:** For custom debounce logic beyond text input.
///
/// ```dart
/// // Wrapper (recommended):
/// class _State extends State {
///   final _controller = DebouncedTextController(
///     onChanged: (text) => searchApi(text),
///   );
///   void dispose() { _controller.dispose(); super.dispose(); }
///   Widget build(context) => TextField(controller: _controller.textController);
/// }
///
/// // Direct (advanced with new features):
/// class _State extends State {
///   final _debouncer = Debouncer(
///     debugMode: true,
///     name: 'search',
///     onMetrics: (duration, cancelled) {
///       print('Debounce took: $duration, cancelled: $cancelled');
///     },
///   );
///   void dispose() { _debouncer.dispose(); super.dispose(); }
///   Widget build(context) => TextField(
///     onChanged: (text) => _debouncer(() => searchApi(text)),
///   );
/// }
/// ```
class Debouncer extends CallbackController {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  final bool enabled;
  final bool resetOnError;
  final void Function(Duration waitTime, bool cancelled)? onMetrics;
  DateTime? _lastCallTime;

  Debouncer({
    super.duration = defaultDuration,
    super.debugMode = false,
    super.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
  });

  @override
  void call(VoidCallback callback) {
    _debounceWithDuration(callback, duration);
  }

  /// Execute with custom duration for this specific call
  void callWithDuration(VoidCallback callback, Duration customDuration) {
    _debounceWithDuration(callback, customDuration);
  }

  void _debounceWithDuration(VoidCallback callback, Duration effectiveDuration) {
    final callTime = DateTime.now();

    // Skip debounce if disabled
    if (!enabled) {
      debugLog('Debounce bypassed (disabled)');
      _executeCallback(callback, callTime, cancelled: false);
      return;
    }

    // Cancel previous timer (if any)
    if (_lastCallTime != null) {
      final waitTime = callTime.difference(_lastCallTime!);
      debugLog('Debounce cancelled (new call after ${waitTime.inMilliseconds}ms)');
      onMetrics?.call(waitTime, true);
    }

    _lastCallTime = callTime;
    timer?.cancel();
    timer = Timer(effectiveDuration, () {
      final totalWaitTime = DateTime.now().difference(callTime);
      debugLog('Debounce executed after ${totalWaitTime.inMilliseconds}ms');
      _executeCallback(callback, callTime, cancelled: false);
    });
  }

  void _executeCallback(VoidCallback callback, DateTime callTime, {required bool cancelled}) {
    if (cancelled) return;

    try {
      callback();
      final totalTime = DateTime.now().difference(callTime);
      onMetrics?.call(totalTime, false);
    } catch (e) {
      if (resetOnError) {
        debugLog('Error occurred, cancelling pending debounce');
        cancel();
        _lastCallTime = null;
      }
      // Don't rethrow - errors in debounced callbacks are swallowed
      // This is consistent with how Timer callbacks work
      debugLog('Debounce callback error (swallowed): $e');
    }
  }

  /// Force immediate execution (e.g., form submit without waiting for debounce).
  void flush(VoidCallback callback) {
    cancel();
    _lastCallTime = null;
    debugLog('Debounce flushed (immediate execution)');
    callback();
    onMetrics?.call(Duration.zero, false);
  }
}

/// Combines leading (immediate) + trailing (after pause) execution.
///
/// **Rare use case.** Most apps should use Throttler, Debouncer, or AsyncThrottler instead.
///
/// **Behavior:** Execute immediately (leading), then again after pause (trailing).
///
/// ```dart
/// final limiter = ThrottleDebouncer();
/// onScroll: () => limiter(() => updatePosition())  // Fires on start + end
/// ```
class ThrottleDebouncer extends CallbackController {
  static const Duration defaultDuration = Duration(milliseconds: 500);

  bool _isThrottled = false;
  VoidCallback? _pendingCallback;

  ThrottleDebouncer({super.duration = defaultDuration});

  @override
  void call(VoidCallback callback) {
    if (!_isThrottled) {
      // First call - execute immediately (leading edge)
      callback();
      _isThrottled = true;
      _startThrottleWindow();
    } else {
      // Within throttle window - save for trailing edge
      _pendingCallback = callback;
    }
  }

  // Async recursion (safe): Each call runs in new event loop, no stack buildup.
  // Self-terminating: Stops when _pendingCallback == null.
  void _startThrottleWindow() {
    timer = Timer(duration, () {
      if (_pendingCallback != null) {
        final callback = _pendingCallback!;
        _pendingCallback = null;
        callback();
        _startThrottleWindow(); // New timer, not stack recursion
      } else {
        _isThrottled = false;
      }
    });
  }

  void reset() {
    cancel();
    _isThrottled = false;
    _pendingCallback = null;
  }

  @override
  void dispose() {
    super.dispose();
    _isThrottled = false;
    _pendingCallback = null;
  }
}

/// Debounce with auto-cancel for async operations (search API, autocomplete).
///
/// **Behavior:** Waits 300ms before execution, cancels previous pending calls.
/// **Difference from Debouncer:** Handles async operations and cancels old results.
/// **Difference from AsyncThrottler:** Debounces (delays), while AsyncThrottler locks immediately.
///
/// **NEW in v1.1.0:**
/// - Debug mode: `AsyncDebouncer(debugMode: true, name: 'search-api')`
/// - Performance metrics: `onMetrics` callback tracks async execution time
/// - Conditional debouncing: `enabled` parameter to bypass debounce
/// - Reset on error: `resetOnError: true` auto-resets on exceptions
///
/// **Use cases:**
/// - Search API: User types "abc" → only last call executes
/// - Autocomplete: Cancels stale API responses
/// - Real-time validation: Debounce + async server check
///
/// **⚠️ CRITICAL IMPLEMENTATION NOTES:**
///
/// 1. **Mounted Check is REQUIRED:**
///    While AsyncDebouncer handles data integrity (cancels old results), it does NOT
///    know about the Widget's lifecycle. You MUST check `mounted` before calling
///    setState() or using BuildContext after await.
///
///    ```dart
///    _debouncer.run(() async {
///      final data = await api.fetch();
///      if (!mounted) return null;  // ✅ YOU MUST CHECK THIS
///      setState(() => _data = data);
///      return data;
///    });
///    ```
///
/// 2. **Disposal is REQUIRED:**
///    Always call dispose() in your State's dispose() method to prevent memory leaks.
///
///    ```dart
///    @override
///    void dispose() {
///      _debouncer.dispose();  // ✅ REQUIRED
///      super.dispose();
///    }
///    ```
///
/// 3. **How Cancellation Works:**
///    - Uses ID-based tracking (no external dependencies)
///    - Old API calls may still complete, but results are ignored
///    - HTTP requests will timeout naturally (via dio timeout config)
///    - **IMPORTANT:** `run()` returns `Future<T?>`. If cancelled, it returns `null`.
///      Always check for null if you need to handle cancellation:
///      ```dart
///      final result = await _debouncer.run(() async => await api.search(text));
///      if (result == null) return;  // Cancelled by newer call
///      // Process result...
///      ```
///
/// **Example:**
/// ```dart
/// class _State extends State {
///   final _debouncer = AsyncDebouncer(
///     debugMode: true,
///     name: 'search',
///     onMetrics: (duration, cancelled) {
///       print('API call took: $duration, cancelled: $cancelled');
///     },
///   );
///
///   @override
///   void dispose() {
///     _debouncer.dispose();  // ✅ Clean up
///     super.dispose();
///   }
///
///   @override
///   Widget build(context) => TextField(
///     onChanged: (text) {
///       _debouncer.run(() async {
///         final results = await searchApi(text);
///         if (!mounted) return results;  // ✅ Check before setState
///         setState(() => _searchResults = results);
///         return results;
///       });
///     },
///   );
/// }
/// ```
class AsyncDebouncer {
  static const Duration defaultDuration = Duration(milliseconds: 300);

  final Duration duration;
  final bool debugMode;
  final String? name;
  final bool enabled;
  final bool resetOnError;
  final void Function(Duration executionTime, bool cancelled)? onMetrics;

  Timer? _timer;
  int _latestCallId =
      0; // Track latest call via ID (no external dependencies needed)
  Completer<dynamic>?
      _pendingCompleter; // Track active completer to prevent hanging futures

  AsyncDebouncer({
    this.duration = defaultDuration,
    this.debugMode = false,
    this.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
  });

  /// Executes async action after debounce delay, auto-cancels previous calls.
  ///
  /// Returns `Future<T?>` where null means the call was cancelled by a newer call.
  Future<T?> run<T>(Future<T> Function() action) async {
    final startTime = DateTime.now();

    // Skip debounce if disabled
    if (!enabled) {
      _debugLog('AsyncDebounce bypassed (disabled)');
      try {
        final result = await action();
        final executionTime = DateTime.now().difference(startTime);
        onMetrics?.call(executionTime, false);
        return result;
      } catch (e) {
        if (resetOnError) {
          _debugLog('Error occurred, state reset');
        }
        rethrow;
      }
    }

    // Cancel old timer
    _timer?.cancel();

    // ✅ FIX: Complete old completer to prevent hanging futures
    // If we don't do this, the old Future will hang forever waiting for completion
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      _pendingCompleter!.complete(null); // Signal cancellation to old caller
      _debugLog('AsyncDebounce cancelled previous call');
      final cancelTime = DateTime.now().difference(startTime);
      onMetrics?.call(cancelTime, true);
    }

    final currentCallId = ++_latestCallId; // Increment ID for this call
    final completer = Completer<T?>();
    _pendingCompleter = completer; // Track new completer

    _timer = Timer(duration, () async {
      try {
        // Check if this is still the latest call
        if (currentCallId != _latestCallId) {
          if (!completer.isCompleted) {
            completer.complete(null); // Cancelled by newer call
            _debugLog('AsyncDebounce cancelled during wait');
          }
          return;
        }

        _debugLog('AsyncDebounce executing async action');
        try {
          final result = await action();
          // Double-check after await (another call might have started)
          if (currentCallId == _latestCallId && !completer.isCompleted) {
            final executionTime = DateTime.now().difference(startTime);
            _debugLog(
                'AsyncDebounce completed in ${executionTime.inMilliseconds}ms');
            onMetrics?.call(executionTime, false);
            completer.complete(result);
          } else if (!completer.isCompleted) {
            _debugLog('AsyncDebounce cancelled after execution');
            completer.complete(null); // Cancelled during execution
          }
        } catch (e, stackTrace) {
          _debugLog('AsyncDebounce error: $e');
          if (resetOnError) {
            _debugLog('Resetting AsyncDebouncer state due to error');
            cancel();
          }
          // Capture stack trace for better debugging
          if (!completer.isCompleted) {
            completer.completeError(e, stackTrace);
          }
        }
      } catch (e, stackTrace) {
        // Catch any errors in the outer scope (e.g., during ID check)
        // Capture stack trace for better debugging
        if (!completer.isCompleted) {
          completer.completeError(e, stackTrace);
        }
      } finally {
        // Clear reference when done to help GC
        if (_pendingCompleter == completer) {
          _pendingCompleter = null;
        }
      }
    });

    return completer.future;
  }

  /// Helper method for debug logging
  void _debugLog(String message) {
    if (debugMode) {
      final prefix = name != null ? '[$name] ' : '';
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('$prefix$message at $timestamp');
    }
  }

  /// Cancels all pending and in-flight operations.
  void cancel() {
    _timer?.cancel();
    _timer = null;

    // ✅ FIX: Complete pending completer to prevent hanging futures
    if (_pendingCompleter != null && !_pendingCompleter!.isCompleted) {
      _pendingCompleter!.complete(null);
      _pendingCompleter = null;
    }

    _latestCallId++; // Invalidate all pending calls
  }

  void dispose() {
    cancel();
  }

  bool get isPending => _timer?.isActive ?? false;
}

/// Throttle for high-frequency events (scroll, resize) using DateTime check.
///
/// **Behavior:** Executes immediately if enough time passed, otherwise ignores.
/// **Difference from Throttler:** Uses DateTime.now() instead of Timer (less overhead).
///
/// **Use cases:**
/// - Scroll listener: Update sticky header every 16ms (~60fps)
/// - Window resize: Recalculate layout every 32ms
/// - Mouse move: Track position every 50ms
///
/// **Why DateTime.now() instead of Timer:**
/// - High frequency (16-32ms): Timer overhead becomes significant
/// - No timer cleanup needed: Simpler, more efficient
/// - More accurate: Timer can drift, DateTime is precise
///
/// ```dart
/// // Scroll listener example:
/// class _State extends State {
///   final _throttler = HighFrequencyThrottler(
///     duration: Duration(milliseconds: 16),  // ~60fps
///   );
///   void dispose() { _throttler.dispose(); super.dispose(); }
///
///   Widget build(context) => NotificationListener<ScrollNotification>(
///     onNotification: (notification) {
///       _throttler.call(() {
///         // Update sticky header position
///         setState(() => _headerOffset = notification.metrics.pixels);
///       });
///       return false;
///     },
///     child: ListView(...),
///   );
/// }
/// ```
class HighFrequencyThrottler {
  static const Duration defaultDuration = Duration(milliseconds: 16); // ~60fps

  final Duration duration;
  DateTime? _lastExecutionTime;

  HighFrequencyThrottler({this.duration = defaultDuration});

  void call(VoidCallback callback) {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= duration) {
      callback();
      _lastExecutionTime = now;
    }
  }

  VoidCallback? wrap(VoidCallback? callback) {
    if (callback == null) return null;
    return () => call(callback);
  }

  void reset() {
    _lastExecutionTime = null;
  }

  void dispose() {
    _lastExecutionTime = null;
  }

  bool get isThrottled {
    if (_lastExecutionTime == null) return false;
    return DateTime.now().difference(_lastExecutionTime!) < duration;
  }
}

/// Prevents duplicate async operations by locking until Future completes.
///
/// **Behavior:** Locks during async execution, auto-unlocks after 15s timeout.
/// **Difference from Throttler:** Process-based (waits for completion) vs time-based (fixed 500ms).
/// **Difference from AsyncDebouncer:** Locks immediately, while AsyncDebouncer delays execution.
///
/// **NEW in v1.1.0:**
/// - Debug mode: `AsyncThrottler(debugMode: true, name: 'form-submit')`
/// - Performance metrics: `onMetrics` callback tracks async execution time
/// - Conditional throttling: `enabled` parameter to bypass throttle
/// - Reset on error: `resetOnError: true` auto-resets on exceptions
///
/// **Use cases:**
/// - Form submission: Prevent double-submit
/// - File upload: Lock during upload
/// - Payment: Prevent duplicate charges
///
/// **Recommended:** Use `AsyncThrottledCallback` wrapper.
/// **Direct usage:** If you need to check `isLocked` state or reuse across multiple widgets.
///
/// **⚠️ CRITICAL:** If using BuildContext after await, check `mounted` first!
///
/// ```dart
/// // Wrapper (recommended):
/// AsyncThrottledCallback(
///   onPressed: () async {
///     await api.submit();
///     if (!mounted) return;  // ✅ Check before using context!
///     Navigator.pop(context);
///   },
///   builder: (ctx, cb) => ElevatedButton(onPressed: cb),
/// )
///
/// // Direct (advanced with new features):
/// class _State extends State {
///   final _throttler = AsyncThrottler(
///     debugMode: true,
///     name: 'submit',
///     onMetrics: (duration, executed) {
///       print('Submit took: $duration, executed: $executed');
///     },
///   );
///   void dispose() { _throttler.dispose(); super.dispose(); }
///   Widget build(context) => ElevatedButton(
///     onPressed: _throttler.wrap(() async => await api.submit()),
///   );
/// }
///
/// // Custom timeout:
/// AsyncThrottler(maxDuration: Duration(seconds: 60))  // For file upload
/// ```
class AsyncThrottler {
  final Duration? maxDuration; // Default 15s for APIs, 60s+ for file uploads
  final bool debugMode;
  final String? name;
  final bool enabled;
  final bool resetOnError;
  final void Function(Duration executionTime, bool executed)? onMetrics;

  bool _isLocked = false;
  Timer? _timeoutTimer;

  AsyncThrottler({
    this.maxDuration = const Duration(seconds: 15),
    this.debugMode = false,
    this.name,
    this.enabled = true,
    this.resetOnError = false,
    this.onMetrics,
  });

  Future<void> call(Future<void> Function() callback) async {
    final startTime = DateTime.now();

    // Skip throttle if disabled
    if (!enabled) {
      _debugLog('AsyncThrottle bypassed (disabled)');
      try {
        await callback();
        final executionTime = DateTime.now().difference(startTime);
        onMetrics?.call(executionTime, true);
      } catch (e) {
        if (resetOnError) {
          _debugLog('Error occurred, resetting lock state');
        }
        rethrow;
      }
      return;
    }

    if (_isLocked) {
      _debugLog('AsyncThrottle blocked (locked)');
      onMetrics?.call(Duration.zero, false);
      return;
    }

    _isLocked = true;
    _debugLog('AsyncThrottle locked');

    if (maxDuration != null) {
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(maxDuration!, () {
        _debugLog('AsyncThrottle timeout reached, auto-unlocking');
        _timeoutTimer = null;
        _isLocked = false;
      });
    }

    try {
      await callback();
      final executionTime = DateTime.now().difference(startTime);
      _debugLog('AsyncThrottle completed in ${executionTime.inMilliseconds}ms');
      onMetrics?.call(executionTime, true);
    } catch (e) {
      _debugLog('AsyncThrottle error: $e');
      if (resetOnError) {
        _debugLog('Resetting AsyncThrottler state due to error');
        reset();
      }
      rethrow;
    } finally {
      // Only unlock if timeout hasn't already unlocked
      if (_timeoutTimer != null) {
        _timeoutTimer!.cancel();
        _timeoutTimer = null;
        _isLocked = false;
        _debugLog('AsyncThrottle unlocked');
      }
    }
  }

  /// Helper method for debug logging
  void _debugLog(String message) {
    if (debugMode) {
      final prefix = name != null ? '[$name] ' : '';
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('$prefix$message at $timestamp');
    }
  }

  VoidCallback? wrap(Future<void> Function()? callback) {
    if (callback == null) return null;
    return () => call(callback);
  }

  bool get isLocked => _isLocked;

  void reset() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isLocked = false;
    _debugLog('AsyncThrottle reset');
  }

  void dispose() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isLocked = false;
  }
}

/// Batch execution utility for throttling/debouncing multiple actions as one.
///
/// **NEW in v1.1.0:** Collects multiple throttled calls and executes them as a single batch.
///
/// **Use cases:**
/// - Analytics tracking: Batch multiple tracking events
/// - API calls: Combine multiple small requests into one
/// - State updates: Batch multiple setState calls
///
/// **Example:**
/// ```dart
/// final batchThrottler = BatchThrottler(
///   duration: Duration(milliseconds: 500),
///   onBatchExecute: (actions) {
///     // Execute all actions as one batch
///     for (final action in actions) {
///       action();
///     }
///   },
///   debugMode: true,
///   name: 'analytics-batch',
/// );
///
/// // Multiple rapid calls
/// batchThrottler.add(() => trackEvent('click1'));
/// batchThrottler.add(() => trackEvent('click2'));
/// batchThrottler.add(() => trackEvent('click3'));
/// // After 500ms, all 3 events execute as one batch
/// ```
class BatchThrottler {
  final Duration duration;
  final void Function(List<VoidCallback> actions) onBatchExecute;
  final bool debugMode;
  final String? name;

  Timer? _timer;
  final List<VoidCallback> _pendingActions = [];

  BatchThrottler({
    required this.duration,
    required this.onBatchExecute,
    this.debugMode = false,
    this.name,
  });

  /// Add an action to the batch
  void add(VoidCallback action) {
    _pendingActions.add(action);
    _debugLog('Action added to batch (${_pendingActions.length} total)');

    // Reset timer
    _timer?.cancel();
    _timer = Timer(duration, _executeBatch);
  }

  void _executeBatch() {
    if (_pendingActions.isEmpty) return;

    _debugLog('Executing batch of ${_pendingActions.length} actions');
    final actionsToExecute = List<VoidCallback>.from(_pendingActions);
    _pendingActions.clear();

    try {
      onBatchExecute(actionsToExecute);
    } catch (e) {
      _debugLog('Batch execution error: $e');
      rethrow;
    }
  }

  /// Force immediate batch execution
  void flush() {
    _timer?.cancel();
    _timer = null;
    _executeBatch();
  }

  /// Clear pending actions without executing
  void clear() {
    _debugLog('Clearing ${_pendingActions.length} pending actions');
    _timer?.cancel();
    _timer = null;
    _pendingActions.clear();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pendingActions.clear();
  }

  int get pendingCount => _pendingActions.length;

  /// Helper method for debug logging
  void _debugLog(String message) {
    if (debugMode) {
      final prefix = name != null ? '[$name] ' : '';
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('$prefix$message at $timestamp');
    }
  }
}
