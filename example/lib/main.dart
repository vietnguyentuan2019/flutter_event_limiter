import 'package:flutter/material.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Event Limiter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ThrottleDemo(),
    DebounceDemo(),
    AsyncThrottleDemo(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Event Limiter Demo'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app),
            label: 'Throttle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Debounce',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: 'Async',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1: THROTTLE DEMO (Prevent Double Clicks)
// ============================================================

class ThrottleDemo extends StatefulWidget {
  const ThrottleDemo({super.key});

  @override
  State<ThrottleDemo> createState() => _ThrottleDemoState();
}

class _ThrottleDemoState extends State<ThrottleDemo> {
  int _normalClickCount = 0;
  int _throttledClickCount = 0;
  final List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 23)}: $message');
      if (_logs.length > 10) _logs.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '🎯 Double-Click Test',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try clicking both buttons rapidly to see the difference!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Normal Button (No Protection)
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    '❌ Normal Button (No Protection)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      setState(() => _normalClickCount++);
                      _addLog('❌ Normal click #$_normalClickCount');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Click Me Fast!',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clicks: $_normalClickCount',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Throttled Button (Protected)
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    '✅ Throttled Button (Protected)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ThrottledInkWell(
                    duration: const Duration(milliseconds: 500),
                    onTap: () {
                      setState(() => _throttledClickCount++);
                      _addLog('✅ Throttled click #$_throttledClickCount');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Click Me Fast!',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clicks: $_throttledClickCount (500ms throttle)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Logs
          const Text(
            'Event Log:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(child: Text('Click buttons to see logs'))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 2: DEBOUNCE DEMO (Search API)
// ============================================================

class DebounceDemo extends StatefulWidget {
  const DebounceDemo({super.key});

  @override
  State<DebounceDemo> createState() => _DebounceDemoState();
}

class _DebounceDemoState extends State<DebounceDemo> {
  final List<String> _results = [];
  bool _isLoading = false;
  final List<String> _logs = [];

  late final AsyncDebouncedTextController<List<String>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = AsyncDebouncedTextController<List<String>>(
      duration: const Duration(milliseconds: 300),
      onChanged: (text) async {
        _addLog('🔍 Searching for "$text"...');
        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 500));
        _addLog('✅ Got results for "$text"');
        return _mockSearch(text);
      },
      onSuccess: (results) {
        setState(() => _results..clear()..addAll(results));
      },
      onError: (error, stack) {
        _addLog('❌ Error: $error');
      },
      onLoadingChanged: (isLoading) {
        if (mounted) {
          setState(() => _isLoading = isLoading);
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 23)}: $message');
      if (_logs.length > 15) _logs.removeLast();
    });
  }

  List<String> _mockSearch(String query) {
    if (query.isEmpty) return [];
    final mockData = [
      'Apple', 'Banana', 'Cherry', 'Date', 'Elderberry',
      'Fig', 'Grape', 'Honeydew', 'Kiwi', 'Lemon',
      'Mango', 'Orange', 'Papaya', 'Raspberry', 'Strawberry',
    ];
    return mockData
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '🔍 Search API Demo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Type quickly and watch debouncing + auto-cancel in action!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Search Field
          TextField(
            controller: _controller.textController,
            decoration: InputDecoration(
              labelText: 'Search Fruits',
              hintText: 'Try typing "apple" quickly...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          // Results
          Text(
            'Results (${_results.length}):',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('Start typing to search...'))
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.apple),
                          title: Text(_results[index]),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Logs
          const Text(
            'Event Log:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _logs.isEmpty
                ? const Center(child: Text('Type to see logs'))
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 3: ASYNC THROTTLE DEMO (Form Submit)
// ============================================================

class AsyncThrottleDemo extends StatefulWidget {
  const AsyncThrottleDemo({super.key});

  @override
  State<AsyncThrottleDemo> createState() => _AsyncThrottleDemoState();
}

class _AsyncThrottleDemoState extends State<AsyncThrottleDemo> {
  final List<String> _logs = [];
  int _uploadCount = 0;

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 23)}: $message');
      if (_logs.length > 10) _logs.removeLast();
    });
  }

  Future<void> _simulateUpload() async {
    _addLog('📤 Starting upload...');
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    setState(() => _uploadCount++);
    _addLog('✅ Upload #$_uploadCount completed!');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '📤 Async Form Submit Demo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try clicking the button multiple times rapidly!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Async Throttled Button
          AsyncThrottledCallbackBuilder(
            onPressed: _simulateUpload,
            onError: (error, stack) {
              _addLog('❌ Error: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Upload failed: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            onSuccess: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upload successful!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            builder: (context, callback, isLoading) {
              return ElevatedButton.icon(
                onPressed: isLoading ? null : callback,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  isLoading ? 'Uploading...' : 'Upload File (2s delay)',
                  style: const TextStyle(fontSize: 18),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Successful Uploads: $_uploadCount',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 How it works:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('✅ Button locks during async operation'),
                Text('✅ Multiple clicks are ignored'),
                Text('✅ Auto-unlocks after completion'),
                Text('✅ Built-in error handling'),
                Text('✅ Loading state managed automatically'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logs
          const Text(
            'Event Log:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? const Center(child: Text('Click button to see logs'))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
