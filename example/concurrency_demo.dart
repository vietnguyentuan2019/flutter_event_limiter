// example/concurrency_demo.dart
//
// Demonstrates all ConcurrencyMode strategies in v1.2.0

import 'package:flutter/material.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

void main() {
  runApp(const ConcurrencyDemoApp());
}

class ConcurrencyDemoApp extends StatelessWidget {
  const ConcurrencyDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Concurrency Mode Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ConcurrencyDemoPage(),
    );
  }
}

class ConcurrencyDemoPage extends StatefulWidget {
  const ConcurrencyDemoPage({super.key});

  @override
  State<ConcurrencyDemoPage> createState() => _ConcurrencyDemoPageState();
}

class _ConcurrencyDemoPageState extends State<ConcurrencyDemoPage> {
  final List<String> _dropLog = [];
  final List<String> _enqueueLog = [];
  final List<String> _replaceLog = [];
  final List<String> _keepLatestLog = [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Concurrency Mode Demo (v1.2.0)'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Drop'),
              Tab(text: 'Enqueue'),
              Tab(text: 'Replace'),
              Tab(text: 'Keep Latest'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDropModeDemo(),
            _buildEnqueueModeDemo(),
            _buildReplaceModeDemo(),
            _buildKeepLatestModeDemo(),
          ],
        ),
      ),
    );
  }

  // Drop Mode: Ignore new calls while busy
  Widget _buildDropModeDemo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Drop Mode (Default)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ignores new calls while processing. Perfect for preventing double-clicks.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ConcurrentAsyncThrottledBuilder(
            mode: ConcurrencyMode.drop,
            maxDuration: const Duration(seconds: 3),
            debugMode: true,
            name: 'drop-mode',
            onPressed: () async {
              final timestamp = DateTime.now().toString().substring(11, 23);
              setState(() {
                _dropLog.add('[$timestamp] Processing...');
              });
              await Future.delayed(const Duration(seconds: 2));
              setState(() {
                _dropLog.add('[$timestamp] ✓ Completed');
              });
            },
            builder: (context, callback, isLoading, pendingCount) {
              return Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : callback,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.touch_app),
                    label: Text(isLoading
                        ? 'Processing... ($pendingCount)'
                        : 'Click Me Multiple Times'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoading
                        ? '🔴 Busy - new clicks are DROPPED'
                        : '🟢 Ready to accept clicks',
                    style: TextStyle(
                      color: isLoading ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Event Log:', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _dropLog.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      _dropLog[index],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _dropLog.clear()),
            child: const Text('Clear Log'),
          ),
        ],
      ),
    );
  }

  // Enqueue Mode: Queue calls and execute sequentially
  Widget _buildEnqueueModeDemo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enqueue Mode',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Queues all calls and executes them sequentially (FIFO). Perfect for chat apps.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ConcurrentAsyncThrottledBuilder(
            mode: ConcurrencyMode.enqueue,
            maxDuration: const Duration(seconds: 5),
            debugMode: true,
            name: 'enqueue-mode',
            onPressed: () async {
              final messageNumber = _enqueueLog.length ~/ 2 + 1;
              final timestamp = DateTime.now().toString().substring(11, 23);
              setState(() {
                _enqueueLog.add('[$timestamp] Message #$messageNumber queued');
              });
              await Future.delayed(const Duration(seconds: 1));
              setState(() {
                _enqueueLog.add('[$timestamp] Message #$messageNumber ✓ sent');
              });
            },
            builder: (context, callback, isLoading, pendingCount) {
              return Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: callback,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Message'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pendingCount > 0
                        ? '📤 Sending... Queue: $pendingCount'
                        : '✅ All messages sent',
                    style: TextStyle(
                      color: pendingCount > 0 ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Message Log:', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _enqueueLog.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      _enqueueLog[index],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _enqueueLog.clear()),
            child: const Text('Clear Log'),
          ),
        ],
      ),
    );
  }

  // Replace Mode: Cancel current and start new
  Widget _buildReplaceModeDemo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Replace Mode',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cancels current execution and starts new one. Perfect for search queries.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ConcurrentAsyncThrottledBuilder(
            mode: ConcurrencyMode.replace,
            maxDuration: const Duration(seconds: 5),
            debugMode: true,
            name: 'replace-mode',
            onPressed: () async {
              final queryNumber = _replaceLog.length ~/ 2 + 1;
              final timestamp = DateTime.now().toString().substring(11, 23);
              setState(() {
                _replaceLog.add('[$timestamp] Search query #$queryNumber started');
              });
              await Future.delayed(const Duration(milliseconds: 1500));
              setState(() {
                _replaceLog.add('[$timestamp] Query #$queryNumber ✓ completed');
              });
            },
            builder: (context, callback, isLoading, pendingCount) {
              return Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: callback,
                    icon: const Icon(Icons.search),
                    label: const Text('Search'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoading
                        ? '🔄 Searching... (clicking again will replace current search)'
                        : '🔍 Ready to search',
                    style: TextStyle(
                      color: isLoading ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Search Log:', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _replaceLog.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      _replaceLog[index],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _replaceLog.clear()),
            child: const Text('Clear Log'),
          ),
        ],
      ),
    );
  }

  // Keep Latest Mode: Execute current + latest only
  Widget _buildKeepLatestModeDemo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Keep Latest Mode',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Executes current operation fully, then executes latest pending. Perfect for auto-save.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ConcurrentAsyncThrottledBuilder(
            mode: ConcurrencyMode.keepLatest,
            maxDuration: const Duration(seconds: 5),
            debugMode: true,
            name: 'keep-latest-mode',
            onPressed: () async {
              final versionNumber = _keepLatestLog.length ~/ 2 + 1;
              final timestamp = DateTime.now().toString().substring(11, 23);
              setState(() {
                _keepLatestLog.add('[$timestamp] Saving version #$versionNumber...');
              });
              await Future.delayed(const Duration(seconds: 2));
              setState(() {
                _keepLatestLog.add('[$timestamp] Version #$versionNumber ✓ saved');
              });
            },
            builder: (context, callback, isLoading, pendingCount) {
              return Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: callback,
                    icon: const Icon(Icons.save),
                    label: const Text('Auto-Save'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pendingCount > 1
                        ? '💾 Saving current... Latest queued (pending: $pendingCount)'
                        : pendingCount == 1
                            ? '💾 Saving...'
                            : '✅ All versions saved',
                    style: TextStyle(
                      color: pendingCount > 0 ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Save Log:', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _keepLatestLog.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    dense: true,
                    title: Text(
                      _keepLatestLog[index],
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _keepLatestLog.clear()),
            child: const Text('Clear Log'),
          ),
        ],
      ),
    );
  }
}
