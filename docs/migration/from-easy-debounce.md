# Migration Guide: From easy_debounce

## Why Migrate?

`flutter_event_limiter` provides automatic lifecycle management, eliminating the need for manual ID management and disposal that `easy_debounce` requires.

## Key Improvements

- **No manual ID management** - No need to create and track string IDs
- **Auto-dispose** - Controllers automatically clean up, preventing memory leaks
- **Built-in loading state** - Integrated loading state tracking
- **Auto mounted checks** - Prevents setState crashes after widget disposal
- **Race condition prevention** - Automatically cancels old API calls

## Migration Examples

### Example 1: Search Debouncing

**Before** (easy_debounce):
```dart
import 'package:easy_debounce/easy_debounce.dart';

void onSearch(String text) {
  EasyDebounce.debounce(
    'search-tag', // Manual ID management
    Duration(milliseconds: 300),
    () async {
      final result = await api.search(text);
      if (!mounted) return; // Must remember this check
      setState(() => _results = result);
    },
  );
}

@override
void dispose() {
  EasyDebounce.cancel('search-tag'); // Must remember to cancel
  super.dispose();
}
```

**After** (flutter_event_limiter):
```dart
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

AsyncDebouncedTextController(
  duration: Duration(milliseconds: 300),
  onChanged: (text) async => await api.search(text),
  onSuccess: (results) => setState(() => _results = results),
)
// Auto-dispose, auto mounted check, no ID management needed
```

**Lines of code:** 15+ → 3 lines (80% reduction)

### Example 2: Button Throttling

**Before** (easy_debounce):
```dart
void onButtonPressed() {
  EasyDebounce.debounce(
    'submit-button',
    Duration(milliseconds: 500),
    () {
      submitForm();
    },
  );
}

@override
void dispose() {
  EasyDebounce.cancel('submit-button');
  super.dispose();
}
```

**After** (flutter_event_limiter):
```dart
ThrottledInkWell(
  duration: Duration(milliseconds: 500),
  onTap: () => submitForm(),
  child: Text("Submit"),
)
```

## Common Patterns

### Pattern 1: Multiple Debouncers in One Widget

**Before:**
```dart
void dispose() {
  EasyDebounce.cancel('search');
  EasyDebounce.cancel('filter');
  EasyDebounce.cancel('sort');
  super.dispose();
}
```

**After:**
```dart
// Each controller auto-disposes, no manual cleanup needed
final searchController = AsyncDebouncedTextController(...);
final filterController = DebouncedTextController(...);
final sortController = Debouncer(...);

@override
void dispose() {
  // Controllers automatically dispose
  super.dispose();
}
```

### Pattern 2: Loading State Management

**Before:**
```dart
bool _isLoading = false;

void onSearch(String text) {
  EasyDebounce.debounce('search', duration, () async {
    setState(() => _isLoading = true);
    try {
      final result = await api.search(text);
      if (!mounted) return;
      setState(() {
        _results = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  });
}
```

**After:**
```dart
AsyncDebouncedTextController(
  onChanged: (text) async => await api.search(text),
  onSuccess: (results) => setState(() => _results = results),
  onLoadingChanged: (loading) => setState(() => _isLoading = loading),
  onError: (error, stack) => showError(error),
)
// Loading state and error handling built-in
```

## Migration Checklist

- [ ] Remove `easy_debounce` from `pubspec.yaml`
- [ ] Add `flutter_event_limiter` to dependencies
- [ ] Replace `EasyDebounce.debounce()` calls with appropriate widgets or controllers
- [ ] Remove manual `EasyDebounce.cancel()` calls from `dispose()` methods
- [ ] Remove manual `mounted` checks (handled automatically by CallbackBuilder widgets)
- [ ] Update tests to use flutter_event_limiter's testing approach
- [ ] Remove manual loading state boolean flags where applicable

## Need Help?

- See [Getting Started Guide](../getting-started.md) for basics
- Check [FAQ](../faq.md) for common questions
- Open an issue on [GitHub](https://github.com/vietnguyentuan2019/flutter_event_limiter/issues) for migration support
