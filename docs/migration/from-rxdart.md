# Migration Guide: From rxdart

## When to Use Each Library

### Use `rxdart` when:
- Building complex reactive state management across multiple screens
- Need advanced stream operators (`combineLatest`, `switchMap`, `withLatestFrom`, etc.)
- Implementing reactive architecture patterns (BLoC, Redux Observable)
- Working with multiple coordinated data streams
- Need powerful stream transformations beyond throttle/debounce

### Use `flutter_event_limiter` when:
- Handling simple UI events (button clicks, text input, scroll)
- Need quick throttle/debounce without stream complexity
- Want zero boilerplate for common cases
- Prefer widget-based approach over stream-based
- Don't want to learn reactive programming concepts

## Why Migrate for UI Events?

For simple UI throttling/debouncing, `flutter_event_limiter` offers:

- **80% less boilerplate** - 3 lines vs 15+ lines for common cases
- **No stream knowledge required** - Direct callbacks, no Stream/Subject/Subscription
- **Auto cleanup** - No need to close streams or cancel subscriptions
- **Built-in loading state** - Integrated UI state management
- **Auto mounted checks** - Prevents setState crashes
- **Flutter-first design** - Optimized for Flutter widgets, not generic Dart streams

## Migration Examples

### Example 1: Search Debouncing

**Before** (rxdart):
```dart
import 'package:rxdart/rxdart.dart';

class _SearchPageState extends State<SearchPage> {
  final _searchController = BehaviorSubject<String>();
  StreamSubscription? _subscription;
  List<Product> _results = [];

  @override
  void initState() {
    super.initState();
    _subscription = _searchController.stream
        .debounceTime(Duration(milliseconds: 300))
        .distinct()
        .listen((text) async {
          final result = await api.search(text);
          if (!mounted) return; // Must remember this check
          setState(() => _results = result);
        });
  }

  @override
  void dispose() {
    _subscription?.cancel(); // Must remember to cancel
    _searchController.close(); // Must remember to close
    super.dispose();
  }

  Widget build(BuildContext context) {
    return TextField(
      onChanged: (text) => _searchController.add(text),
      decoration: InputDecoration(hintText: "Search"),
    );
  }
}
```

**After** (flutter_event_limiter):
```dart
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

class _SearchPageState extends State<SearchPage> {
  List<Product> _results = [];

  Widget build(BuildContext context) {
    return AsyncDebouncedTextController(
      duration: Duration(milliseconds: 300),
      onChanged: (text) async => await api.search(text),
      onSuccess: (results) => setState(() => _results = results),
      builder: (controller) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Search"),
        );
      },
    );
  }
  // No dispose needed - auto cleanup
}
```

**Lines of code:** 30+ → 10 lines (67% reduction)

### Example 2: Button Throttling

**Before** (rxdart):
```dart
final _buttonController = PublishSubject<void>();
StreamSubscription? _subscription;

@override
void initState() {
  super.initState();
  _subscription = _buttonController.stream
      .throttleTime(Duration(milliseconds: 500))
      .listen((_) => submitForm());
}

@override
void dispose() {
  _subscription?.cancel();
  _buttonController.close();
  super.dispose();
}

Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () => _buttonController.add(null),
    child: Text("Submit"),
  );
}
```

**After** (flutter_event_limiter):
```dart
Widget build(BuildContext context) {
  return ThrottledInkWell(
    duration: Duration(milliseconds: 500),
    onTap: () => submitForm(),
    child: Text("Submit"),
  );
}
// No initState, no dispose, no subscriptions
```

**Lines of code:** 20+ → 5 lines (75% reduction)

### Example 3: Multiple Input Streams

**Before** (rxdart):
```dart
final _nameController = BehaviorSubject<String>();
final _emailController = BehaviorSubject<String>();
final _phoneController = BehaviorSubject<String>();
StreamSubscription? _nameSub;
StreamSubscription? _emailSub;
StreamSubscription? _phoneSub;

@override
void initState() {
  super.initState();
  _nameSub = _nameController.stream
      .debounceTime(Duration(milliseconds: 300))
      .listen((name) => validateName(name));
  _emailSub = _emailController.stream
      .debounceTime(Duration(milliseconds: 300))
      .listen((email) => validateEmail(email));
  _phoneSub = _phoneController.stream
      .debounceTime(Duration(milliseconds: 300))
      .listen((phone) => validatePhone(phone));
}

@override
void dispose() {
  _nameSub?.cancel();
  _emailSub?.cancel();
  _phoneSub?.cancel();
  _nameController.close();
  _emailController.close();
  _phoneController.close();
  super.dispose();
}
```

**After** (flutter_event_limiter):
```dart
Widget build(BuildContext context) {
  return Column(
    children: [
      DebouncedTextController(
        onChanged: (name) => validateName(name),
        builder: (controller) => TextField(controller: controller),
      ),
      DebouncedTextController(
        onChanged: (email) => validateEmail(email),
        builder: (controller) => TextField(controller: controller),
      ),
      DebouncedTextController(
        onChanged: (phone) => validatePhone(phone),
        builder: (controller) => TextField(controller: controller),
      ),
    ],
  );
}
// No subscriptions, no manual cleanup
```

## When to Keep Using rxdart

### Scenario 1: Combining Multiple Streams

```dart
// Complex reactive pattern - use rxdart
final stream = Rx.combineLatest3(
  userStream,
  settingsStream,
  preferencesStream,
  (user, settings, prefs) => ViewModel(user, settings, prefs),
).debounceTime(Duration(milliseconds: 300));
```

### Scenario 2: Advanced Stream Transformations

```dart
// Complex stream pipeline - use rxdart
userSearchStream
  .debounceTime(Duration(milliseconds: 300))
  .distinct()
  .switchMap((query) => api.search(query))
  .onErrorReturn([])
  .startWith([]);
```

### Scenario 3: Reactive State Management

```dart
// BLoC pattern with rxdart - keep using it
class SearchBloc {
  final _searchController = BehaviorSubject<String>();
  final _resultsController = BehaviorSubject<List<Product>>();

  Stream<List<Product>> get results => _resultsController.stream;

  SearchBloc() {
    _searchController.stream
        .debounceTime(Duration(milliseconds: 300))
        .switchMap((query) => api.search(query))
        .listen(_resultsController.add);
  }
}
```

## Hybrid Approach

You can use both libraries together:

```dart
// Use rxdart for complex state management
class AppBloc {
  final _stateStream = BehaviorSubject<AppState>();
  // Complex reactive logic with rxdart
}

// Use flutter_event_limiter for simple UI throttling
Widget build(BuildContext context) {
  return ThrottledInkWell(
    onTap: () => context.read<AppBloc>().add(SubmitEvent()),
    child: Text("Submit"),
  );
}
```

## Decision Matrix

| Use Case | Recommended Library |
|----------|-------------------|
| Button click throttling | flutter_event_limiter |
| Text field debouncing | flutter_event_limiter |
| Form submission throttling | flutter_event_limiter |
| Simple API call debouncing | flutter_event_limiter |
| Combining multiple streams | rxdart |
| Complex stream transformations | rxdart |
| BLoC/Redux Observable pattern | rxdart |
| State management | rxdart |
| Multi-screen reactive state | rxdart |

## Migration Checklist

- [ ] Identify which use cases are simple UI events (migrate to flutter_event_limiter)
- [ ] Keep rxdart for complex reactive patterns
- [ ] Add `flutter_event_limiter` to dependencies (rxdart can stay if needed)
- [ ] Replace simple stream debouncing with `DebouncedTextController`
- [ ] Replace button stream throttling with `ThrottledInkWell` or `ThrottledBuilder`
- [ ] Remove unnecessary BehaviorSubject/PublishSubject for UI events
- [ ] Remove manual subscription management for UI events
- [ ] Keep rxdart for state management and complex reactive patterns

## Benefits Summary

| Aspect | rxdart (UI events) | flutter_event_limiter |
|--------|-------------------|----------------------|
| Lines of code | 15-30 lines | 3-10 lines |
| Stream knowledge required | Yes | No |
| Manual cleanup required | Yes | No |
| Built-in loading state | No | Yes |
| Auto mounted checks | No | Yes |
| Learning curve | Steep | Gentle |
| Best for | Complex streams | Simple UI events |

## Need Help?

- See [Getting Started Guide](../getting-started.md) for basics
- Check [FAQ](../faq.md) for common questions
- Browse [Examples](../../example/) for real-world usage
- Open an issue on [GitHub](https://github.com/vietnguyentuan2019/flutter_event_limiter/issues) for migration support

## Resources

- [rxdart documentation](https://pub.dev/packages/rxdart) - For complex reactive patterns
- [flutter_event_limiter documentation](https://pub.dev/packages/flutter_event_limiter) - For simple UI events
- Both libraries can coexist in the same project!
