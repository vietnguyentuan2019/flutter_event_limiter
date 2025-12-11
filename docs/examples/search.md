# Example: Search with Race Condition Prevention

## Problem Statement

Search functionality in apps often faces these challenges:

- **Performance:** API called on every keystroke → Network spam, server overload
- **Race conditions:** User types "flutter", but results for "flu" arrive last → Wrong results shown
- **Poor UX:** No loading indicator → User unsure if search is working
- **Memory leaks:** Forgot to cancel subscriptions → App crashes

## Solution: Async Debounced Text Controller

Use `AsyncDebouncedTextController` to wait for user to stop typing, then call API with automatic cancellation of old requests.

## Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

class ProductSearchPage extends StatefulWidget {
  @override
  _ProductSearchPageState createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage> {
  List<Product> _searchResults = [];
  bool _isSearching = false;

  Future<List<Product>> _searchProducts(String query) async {
    if (query.isEmpty) return [];
    return await ProductApi.search(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Products')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: AsyncDebouncedTextController(
              duration: Duration(milliseconds: 300), // Wait 300ms after typing stops
              onChanged: _searchProducts,
              onSuccess: (products) {
                setState(() => _searchResults = products);
              },
              onLoadingChanged: (loading) {
                setState(() => _isSearching = loading);
              },
              onError: (error, stack) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Search failed: $error')),
                );
              },
              builder: (controller) {
                return TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator())
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_searchResults.isEmpty) {
      return Center(child: Text('No results'));
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return ListTile(
          leading: Image.network(product.imageUrl, width: 50),
          title: Text(product.name),
          subtitle: Text('\$${product.price}'),
        );
      },
    );
  }
}
```

## How Race Condition Prevention Works

**Scenario: User types "flutter"**

```
Time    User Input    API Calls       Results Displayed
0ms     "f"          API "f" starts
50ms    "fl"         API "f" CANCELLED, API "fl" starts
100ms   "flu"        API "fl" CANCELLED, API "flu" starts
150ms   "flut"       API "flu" CANCELLED, API "flut" starts
200ms   "flutt"      API "flut" CANCELLED, API "flutt" starts
250ms   "flutte"     API "flutt" CANCELLED, API "flutte" starts
300ms   "flutter"    API "flutte" CANCELLED, API "flutter" starts
600ms   (300ms wait) No typing
900ms   -            API "flutter" returns → SHOW RESULTS ✅
```

**Key Points:**
- Only the LAST API call ("flutter") completes
- All intermediate calls are automatically cancelled
- Results always match the final search query

## Advanced: Autocomplete with Highlights

```dart
class AutocompleteSearch extends StatefulWidget {
  @override
  _AutocompleteSearchState createState() => _AutocompleteSearchState();
}

class _AutocompleteSearchState extends State<AutocompleteSearch> {
  List<String> _suggestions = [];
  String _currentQuery = '';

  Future<List<String>> _fetchSuggestions(String query) async {
    _currentQuery = query;
    if (query.isEmpty) return [];
    return await SuggestionApi.fetch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AsyncDebouncedTextController(
          duration: Duration(milliseconds: 200), // Faster for autocomplete
          onChanged: _fetchSuggestions,
          onSuccess: (suggestions) {
            setState(() => _suggestions = suggestions);
          },
          builder: (controller) {
            return TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type to search...',
                prefixIcon: Icon(Icons.search),
              ),
            );
          },
        ),
        // Suggestions dropdown
        if (_suggestions.isNotEmpty)
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: _buildHighlightedText(
                    suggestion,
                    _currentQuery,
                  ),
                  onTap: () {
                    // Handle suggestion selection
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) return Text(text);

    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.black),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}
```

## Comparison: Manual vs Library

### Without flutter_event_limiter (Manual):

```dart
class _SearchPageState extends State<SearchPage> {
  Timer? _debounceTimer;
  int _latestCallId = 0;
  bool _isSearching = false;
  List<Product> _results = [];

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel(); // Must remember to cancel
    _debounceTimer = Timer(Duration(milliseconds: 300), () async {
      final callId = ++_latestCallId;
      setState(() => _isSearching = true);

      try {
        final results = await api.search(query);

        // Check if this is still the latest call
        if (callId != _latestCallId) return; // Race condition check

        if (!mounted) return; // Must remember mounted check!

        setState(() {
          _results = results;
          _isSearching = false;
        });
      } catch (e) {
        if (!mounted) return; // Must remember mounted check!
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Must remember to cancel
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        suffixIcon: _isSearching ? CircularProgressIndicator() : null,
      ),
    );
  }
}
```

**Issues:** 35+ lines, manual race condition handling, easy to forget cleanup

### With flutter_event_limiter:

```dart
class _SearchPageState extends State<SearchPage> {
  List<Product> _results = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return AsyncDebouncedTextController(
      duration: Duration(milliseconds: 300),
      onChanged: (query) async => await api.search(query),
      onSuccess: (results) => setState(() => _results = results),
      onLoadingChanged: (loading) => setState(() => _isSearching = loading),
      builder: (controller) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            suffixIcon: _isSearching ? CircularProgressIndicator() : null,
          ),
        );
      },
    );
  }
}
```

**Benefits:** 12 lines, auto race condition handling, auto cleanup ✅

## Key Features

✅ **Waits for typing pause** - Calls API only after user stops typing (300ms default)
✅ **Auto-cancels old requests** - Prevents race conditions automatically
✅ **Built-in loading state** - No manual boolean flags needed
✅ **Error handling** - `onError` callback for failed API calls
✅ **Auto cleanup** - No manual timer disposal or subscription management
✅ **Auto mounted checks** - Prevents setState crashes after widget disposal

## Performance Benefits

| Metric | Without Debounce | With Debounce (300ms) |
|--------|-----------------|----------------------|
| API calls for "flutter" (8 chars) | 8 calls | 1 call |
| Network traffic | 8x | 1x |
| Server load | High | Low |
| Battery usage | High | Low |
| Race conditions | Possible | Prevented |

## Related Examples

- [Form Submission](./form-submission.md) - Async form validation
- [E-Commerce](./e-commerce.md) - Preventing double orders
- [Chat App](./chat-app.md) - Message throttling

## Learn More

- [Throttle vs Debounce](../guides/throttle-vs-debounce.md)
- [API Reference](https://pub.dev/documentation/flutter_event_limiter)
- [Migration from RxDart](../migration/from-rxdart.md)
