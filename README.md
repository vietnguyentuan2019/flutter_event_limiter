# Flutter Event Limiter 🛡️

[![pub package](https://img.shields.io/pub/v/flutter_event_limiter.svg)](https://pub.dev/packages/flutter_event_limiter)
[![Pub Points](https://img.shields.io/pub/points/flutter_event_limiter)](https://pub.dev/packages/flutter_event_limiter/score)
[![Tests](https://img.shields.io/badge/tests-128%20passing-brightgreen.svg)](https://github.com/vietnguyentuan2019/flutter_event_limiter)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Production-ready throttle and debounce for Flutter apps.**

Stop wrestling with `Timer` boilerplate, race conditions, and setState crashes. Handle button spam, search debouncing, and async operations with **3 lines of code** instead of 15+.

---

## ⚡ Quick Start

### Problem: Manual Throttling (15+ lines, error-prone)

```dart
Timer? _timer;
bool _loading = false;

void onSearch(String text) {
  _timer?.cancel();
  _timer = Timer(Duration(milliseconds: 300), () async {
    setState(() => _loading = true);
    try {
      final result = await api.search(text);
      if (!mounted) return; // Easy to forget!
      setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  });
}

@override
void dispose() {
  _timer?.cancel(); // Easy to forget!
  super.dispose();
}
```

### Solution: flutter_event_limiter (3 lines, safe)

```dart
AsyncDebouncedTextController(
  onChanged: (text) async => await api.search(text),
  onSuccess: (result) => setState(() => _result = result),
  onLoadingChanged: (loading) => setState(() => _loading = loading),
)
```

**Result:** 80% less code. Auto-dispose. Auto mounted checks. Auto loading state.

---

## ✨ Why This Library?

**Built for production use:**
- ✅ **160/160 pub points** - Perfect score, actively maintained
- ✅ **128 comprehensive tests** - Edge cases covered, battle-tested
- ✅ **Zero dependencies** - No bloat, no conflicts

**Saves development time:**
- ✅ **3 lines vs 15+** - Eliminates boilerplate
- ✅ **Auto-safety** - No setState crashes, no memory leaks
- ✅ **Works with any widget** - Material, Cupertino, custom widgets

**Unique features:**
- ✅ **Built-in loading state** - No manual `bool isLoading = false` needed
- ✅ **Race condition prevention** - Auto-cancels stale API calls
- ✅ **Universal builders** - Not locked into specific widgets

[See detailed comparison with alternatives →](docs/comparison.md)

---

## 🚀 Common Use Cases

### 1. Prevent Button Double-Clicks

```dart
ThrottledInkWell(
  onTap: () => submitOrder(), // Only executes once per 500ms
  child: Text("Submit Order"),
)
```

[See E-Commerce example →](docs/examples/e-commerce.md)

### 2. Smart Search Bar

```dart
AsyncDebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) async => await api.search(text),
  onSuccess: (products) => setState(() => _products = products),
  onLoadingChanged: (isLoading) => setState(() => _loading = isLoading),
)
```

[See Search example →](docs/examples/search.md)

### 3. Form Submission with Loading UI

```dart
AsyncThrottledCallbackBuilder(
  onPressed: () async => await uploadFile(),
  builder: (context, callback, isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : callback,
      child: isLoading ? CircularProgressIndicator() : Text("Upload"),
    );
  },
)
```

[See Form example →](docs/examples/form-submission.md)

### 4. Advanced Concurrency Control (NEW in v1.2.0)

Control how multiple async operations are handled with 4 powerful modes:

```dart
// Chat App: Queue messages and send in order
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.enqueue,
  onPressed: () async => await api.sendMessage(text),
  builder: (context, callback, isLoading, pendingCount) {
    return ElevatedButton(
      onPressed: callback,
      child: Text(pendingCount > 0 ? 'Sending ($pendingCount)...' : 'Send'),
    );
  },
)

// Search: Cancel old queries, only run latest
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.replace,
  onPressed: () async => await api.search(query),
  builder: (context, callback, isLoading, _) {
    return SearchBar(
      onChanged: (q) { query = q; callback?.call(); },
      trailing: isLoading ? CircularProgressIndicator() : null,
    );
  },
)

// Auto-save: Save current + latest only
ConcurrentAsyncThrottledBuilder(
  mode: ConcurrencyMode.keepLatest,
  onPressed: () async => await api.saveDraft(content),
  builder: (context, callback, isLoading, _) {
    return TextField(
      onChanged: (text) { content = text; callback?.call(); },
      decoration: InputDecoration(
        suffixIcon: isLoading ? CircularProgressIndicator() : Icon(Icons.check),
      ),
    );
  },
)
```

**4 Concurrency Modes:**
- 🔴 **Drop** (default): Ignore new calls while busy - perfect for preventing double-clicks
- 📤 **Enqueue**: Queue all calls and execute sequentially - perfect for chat apps
- 🔄 **Replace**: Cancel current and start new - perfect for search queries
- 💾 **Keep Latest**: Execute current + latest only - perfect for auto-save

[See interactive demo →](example/concurrency_demo.dart)

---

## 🎨 Universal Builder Pattern

**The power of flexibility:** Works with **any** Flutter widget.

```dart
ThrottledBuilder(
  duration: Duration(seconds: 1),
  builder: (context, throttle) {
    return FloatingActionButton(
      onPressed: throttle(() => saveData()),
      child: Icon(Icons.save),
    );
  },
)
```

**Use with:**
- ✅ Material Design (`ElevatedButton`, `FloatingActionButton`, `InkWell`)
- ✅ Cupertino (`CupertinoButton`, `CupertinoTextField`)
- ✅ Custom widgets from any package
- ✅ Third-party UI libraries

Unlike other libraries that lock you into specific widgets, flutter_event_limiter **adapts to your UI framework**.

---

## 📊 Throttle vs Debounce: Which One?

### Throttle (Anti-Spam)

Fires **immediately**, then blocks for duration.

```
User clicks: ▼     ▼   ▼▼▼       ▼
Executes:    ✓     X   X X       ✓
             |<-500ms->|         |<-500ms->|
```

**Use for:** Button clicks, refresh actions, preventing spam

### Debounce (Wait for Pause)

Waits for **pause** in events, then fires.

```
User types:  a  b  c  d ... (pause) ... e  f  g
Executes:                   ✓                   ✓
             |<--300ms wait-->|     |<--300ms wait-->|
```

**Use for:** Search input, auto-save, slider changes

### AsyncDebouncer (Debounce + Auto-Cancel)

Waits for pause **and** cancels previous async operations.

```
User types:  a    b    c  (API starts) ... d
API calls:   X    X    ▼ (running...)   X (cancelled)
Result used:                            ✓ (only 'd')
```

**Use for:** Search APIs, autocomplete, async validation

[Learn more about timing strategies →](docs/guides/throttle-vs-debounce.md)

---

## 📚 Complete Widget Reference

### Throttling (Anti-Spam Buttons)

| Widget | Use Case |
|--------|----------|
| `ThrottledInkWell` | Material buttons with ripple |
| `ThrottledBuilder` | **Universal** - Any widget |
| `AsyncThrottledCallbackBuilder` | Async with auto loading state |
| `Throttler` | Direct class (advanced) |

### Debouncing (Search, Auto-save)

| Widget | Use Case |
|--------|----------|
| `DebouncedTextController` | Basic text input |
| `AsyncDebouncedTextController` | Search API with loading |
| `DebouncedBuilder` | **Universal** - Any widget |
| `Debouncer` | Direct class (advanced) |

### High-Frequency Events

| Widget | Use Case |
|--------|----------|
| `HighFrequencyThrottler` | Scroll, mouse, resize (60fps) |

[View full API documentation →](https://pub.dev/documentation/flutter_event_limiter)

---

## 🛠 Installation

```bash
flutter pub add flutter_event_limiter
```

Or add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_event_limiter: ^1.1.2
```

Then import:

```dart
import 'package:flutter_event_limiter/flutter_event_limiter.dart';
```

---

## 📖 Documentation

### Getting Started
- [Quick Start Guide](docs/getting-started.md)
- [Throttle vs Debounce Explained](docs/guides/throttle-vs-debounce.md)
- [FAQ](docs/faq.md) - Common questions answered

### Examples
- [E-Commerce: Prevent Double Checkout](docs/examples/e-commerce.md)
- [Search with Race Condition Prevention](docs/examples/search.md)
- [Form Submission with Loading State](docs/examples/form-submission.md)
- [Chat App: Prevent Message Spam](docs/examples/chat-app.md)

### Migration Guides
- [From easy_debounce](docs/migration/from-easy-debounce.md) - Stop managing IDs manually
- [From flutter_smart_debouncer](docs/migration/from-flutter-smart-debouncer.md) - Unlock from fixed widgets
- [From rxdart](docs/migration/from-rxdart.md) - Simpler API for UI events

### Advanced
- [Detailed Comparison with Alternatives](docs/comparison.md)
- [Roadmap](ROADMAP.md) - Upcoming features
- [API Reference](https://pub.dev/documentation/flutter_event_limiter)

---

## 🎯 Features

**Core Capabilities:**
- ⏱️ **Throttle** - Execute immediately, block duplicates
- ⏳ **Debounce** - Wait for pause, then execute
- 🔄 **Async Support** - Built-in for async operations
- 🏃 **High Frequency** - Optimized for scroll/mouse events (60fps)
- 🎭 **Combo** - ThrottleDebouncer (leading + trailing)

**Safety & Reliability:**
- 🛡️ **Auto Dispose** - Zero memory leaks
- ✅ **Auto Mounted Checks** - No setState crashes
- 🏁 **Race Condition Prevention** - Auto-cancel stale calls
- 📦 **Batch Execution** - Group multiple operations

**Developer Experience:**
- 🎨 **Universal Builders** - Works with any widget
- 📊 **Built-in Loading State** - No manual flags
- 🐛 **Debug Mode** - Log throttle/debounce events
- 📈 **Performance Metrics** - Track execution time
- ⚙️ **Conditional Execution** - Enable/disable dynamically

---

## 🧪 Testing

Works seamlessly with Flutter's test framework:

```dart
testWidgets('throttle blocks rapid clicks', (tester) async {
  int clickCount = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: ThrottledInkWell(
        duration: Duration(milliseconds: 500),
        onTap: () => clickCount++,
        child: Text('Tap'),
      ),
    ),
  );

  await tester.tap(find.text('Tap'));
  expect(clickCount, 1);

  await tester.tap(find.text('Tap')); // Blocked
  expect(clickCount, 1);

  await tester.pumpAndSettle(Duration(milliseconds: 500));
  await tester.tap(find.text('Tap')); // Works again
  expect(clickCount, 2);
});
```

[See more testing examples in FAQ →](docs/faq.md#testing)

---

## 🔧 Advanced Features (v1.1.0+)

### Debug Mode

```dart
Throttler(
  debugMode: true,
  name: 'submit-button',
  onMetrics: (duration, executed) {
    print('Throttle took: $duration, executed: $executed');
  },
)
```

### Conditional Throttling

```dart
ThrottledBuilder(
  enabled: !isVipUser, // VIP users skip throttle
  builder: (context, throttle) => ElevatedButton(...),
)
```

### Custom Duration per Call

```dart
final throttler = Throttler();

throttler.callWithDuration(
  () => criticalAction(),
  duration: Duration(seconds: 2), // Override default
);
```

### Manual Reset

```dart
final throttler = Throttler();
throttler.call(() => action());
throttler.reset(); // Clear throttle state
throttler.call(() => action()); // Executes immediately
```

[See all advanced features →](docs/guides/advanced-features.md)

---

## 💡 Integration with State Management

Works with **all** state management solutions:

**GetX:**
```dart
ThrottledInkWell(
  onTap: () => Get.find<MyController>().submit(),
  child: Text("Submit"),
)
```

**Riverpod:**
```dart
AsyncDebouncedTextController(
  onChanged: (text) async {
    return await ref.read(searchProvider.notifier).search(text);
  },
  onSuccess: (results) {
    // Update state
  },
)
```

**Bloc:**
```dart
ThrottledBuilder(
  builder: (context, throttle) {
    return ElevatedButton(
      onPressed: throttle(() => context.read<MyBloc>().add(SubmitEvent())),
      child: Text("Submit"),
    );
  },
)
```

**Provider:**
```dart
ThrottledInkWell(
  onTap: () => context.read<CounterProvider>().increment(),
  child: Text("Increment"),
)
```

[See more state management examples →](docs/faq.md#state-management)

---

## ⚡ Performance

Near-zero overhead:

| Metric | Performance |
|--------|------------|
| Throttle/Debounce | ~0.01ms per call |
| High-Frequency Throttler | ~0.001ms (100x faster) |
| Memory | ~40 bytes per controller |

**Benchmarked:** Handles 1000+ concurrent operations without frame drops.

[See performance benchmarks →](docs/guides/performance.md)

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

---

## 📮 Support

- 💬 **Questions:** [FAQ](docs/faq.md) · [GitHub Discussions](https://github.com/vietnguyentuan2019/flutter_event_limiter/discussions)
- 🐛 **Bugs:** [GitHub Issues](https://github.com/vietnguyentuan2019/flutter_event_limiter/issues)
- ⭐ **Like it?** Star this repo!

---

<p align="center">Made with ❤️ for the Flutter community</p>
