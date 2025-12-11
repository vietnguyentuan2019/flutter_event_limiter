# Advanced Features

This page documents advanced features introduced in v1.1.0 and later versions.

## v1.1.0 Features

### 1. Debug Mode

Enable detailed logging for troubleshooting throttle/debounce behavior.

```dart
Throttler(
  debugMode: true,
  name: 'submit-button',
  duration: Duration(milliseconds: 500),
)

// Output when throttled:
// [submit-button] Throttled call at 2025-01-15T10:30:45.123
// [submit-button] Call blocked (throttled) at 2025-01-15T10:30:45.323
```

**Use cases:**
- Debugging timing issues
- Understanding when callbacks execute
- Identifying blocked calls

---

### 2. Performance Metrics

Track execution time and status for analytics or optimization.

```dart
Throttler(
  onMetrics: (duration, executed) {
    print('Execution took: ${duration.inMilliseconds}ms');
    print('Was executed: $executed');

    // Send to analytics
    Analytics.logEvent('throttle_performance', {
      'duration_ms': duration.inMilliseconds,
      'executed': executed,
    });
  },
)
```

---

### 3. Conditional Execution

Enable/disable throttling dynamically without changing widget tree.

```dart
Throttler(
  enabled: !isVipUser, // VIP users bypass throttle
  duration: Duration(milliseconds: 500),
)

// OR

ThrottledBuilder(
  enabled: shouldThrottle, // Toggle at runtime
  builder: (context, throttle) {
    return ElevatedButton(
      onPressed: throttle(() => action()),
      child: Text("Submit"),
    );
  },
)
```

**Use cases:**
- Skip throttling for premium users
- Disable throttling in development mode
- A/B testing different throttle behaviors

---

### 4. Custom Duration per Call

Override default duration for specific calls.

```dart
final throttler = Throttler(
  duration: Duration(milliseconds: 500), // Default
);

// Normal action - uses default 500ms
throttler.call(() => normalAction());

// Critical action - custom 2 second throttle
throttler.callWithDuration(
  () => criticalAction(),
  duration: Duration(seconds: 2),
);
```

---

### 5. Reset on Error

Automatically reset throttle state when callback throws an error.

```dart
AsyncThrottler(
  resetOnError: true, // Reset if error occurs
  maxDuration: Duration(seconds: 30),
)

// If callback throws:
// 1. Error is rethrown
// 2. Throttle state is reset
// 3. Next call can execute immediately
```

**Use cases:**
- Prevent users from being locked out after errors
- Allow retry after failed API calls
- Better error recovery UX

---

### 6. Batch Execution

Group multiple operations into batches.

```dart
final batchThrottler = BatchThrottler(
  duration: Duration(seconds: 1),
  onBatch: (items) {
    print('Processing ${items.length} items');
    sendBatchToServer(items);
  },
);

// Add items individually
batchThrottler.add(event1);
batchThrottler.add(event2);
batchThrottler.add(event3);

// After 1 second: processes all 3 items as one batch
```

**Use cases:**
- Analytics event batching
- Log aggregation
- Bulk API operations

---

### 7. Manual Control

Direct control over throttle/debounce state.

**Reset:**
```dart
final throttler = Throttler();

throttler.call(() => action1());
// Currently throttled...

throttler.reset(); // Clear throttle state

throttler.call(() => action2()); // Executes immediately
```

**Check State:**
```dart
final throttler = Throttler();

if (throttler.isThrottled) {
  print('Currently blocked');
  showSnackBar('Please wait before trying again');
} else {
  print('Ready to execute');
}
```

**Flush Debouncer:**
```dart
final debouncer = Debouncer();

debouncer.call(() => action());
// Timer running...

debouncer.flush(); // Execute immediately, cancel timer
```

---

## Future Features (Roadmap)

### v1.2.0 (Planned): Concurrency Mode

Different execution strategies for async operations:

```dart
// Enqueue mode - execute sequentially
ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.enqueue,
  maxDuration: Duration(seconds: 30),
)

// Replace mode - cancel old, start new
ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.replace,
)

// Keep latest - execute latest after current finishes
ConcurrentAsyncThrottler(
  mode: ConcurrencyMode.keepLatest,
)
```

[See full roadmap →](../../ROADMAP.md)

---

### v1.3.0 (Planned): Retry Logic

Automatic retry with exponential backoff:

```dart
AsyncThrottler(
  retryConfig: RetryConfig(
    maxAttempts: 3,
    delayFactor: Duration(milliseconds: 500),
    retryIf: (e) => e is NetworkException,
  ),
)
```

[See full roadmap →](../../ROADMAP.md)

---

### v1.3.1 (Planned): Stream Extensions

Throttle/debounce for Dart streams:

```dart
streamController.stream
  .throttle(Duration(milliseconds: 500))
  .listen((event) => print(event));

streamController.stream
  .debounce(Duration(milliseconds: 300))
  .listen((event) => print(event));
```

[See full roadmap →](../../ROADMAP.md)

---

### v1.4.0 (Planned): Visual Debugger

Real-time overlay showing throttle/debounce events:

```dart
EventLimiterDebugOverlay(
  enabled: kDebugMode,
  child: MyApp(),
)

// Shows on screen:
// [Search API] 🟡 Debouncing (200ms left)
// [Submit Btn] 🔴 Throttled (Blocked 3 clicks)
// [Load Data]  🟢 Executing...
```

[See full roadmap →](../../ROADMAP.md)

---

## Best Practices

### 1. Use Named Controllers for Debugging

```dart
// ❌ Hard to debug
final throttler = Throttler(debugMode: true);

// ✅ Easy to identify in logs
final submitThrottler = Throttler(
  debugMode: true,
  name: 'submit-button',
);
```

### 2. Combine Features

```dart
Throttler(
  debugMode: kDebugMode,          // Debug only in dev
  enabled: !isVipUser,             // Conditional
  onMetrics: sendToAnalytics,      // Track performance
  name: 'checkout-button',         // Identify in logs
)
```

### 3. Use Reset Wisely

```dart
// ✅ Good: Reset after successful operation
try {
  await throttler.call(() => submitOrder());
  throttler.reset(); // Allow immediate next action
} catch (e) {
  // Don't reset on error - prevent spam retries
}

// ❌ Bad: Reset without reason (defeats purpose)
throttler.call(() => action());
throttler.reset(); // Why use throttler at all?
```

---

## Related Documentation

- [Throttle vs Debounce](./throttle-vs-debounce.md)
- [FAQ](../faq.md)
- [Performance Guide](./performance.md)
- [Roadmap](../../ROADMAP.md)

---

## Examples

See real-world usage in:
- [E-Commerce Example](../examples/e-commerce.md)
- [Search Example](../examples/search.md)
- [Form Submission Example](../examples/form-submission.md)
- [Chat App Example](../examples/chat-app.md)
