# Example: Chat App - Prevent Message Spam

## Problem Statement

Chat applications need to prevent:

- **Message spam:** User presses Enter/Send rapidly → Duplicate messages sent
- **API overload:** Too many requests in short time
- **Poor UX:** No feedback that message is being sent
- **Rate limiting issues:** Backend may reject rapid requests

## Solution: Throttled Message Sending

Use `ThrottledBuilder` or `ThrottledInkWell` to limit message sending rate.

## Basic Implementation

```dart
import 'package:flutter/material.dart';
import 'package:flutter_event_limiter/flutter_event_limiter.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Clear input immediately for better UX
    _messageController.clear();

    // Send to backend
    await ChatApi.sendMessage(
      chatId: widget.chatId,
      text: text,
    );

    // Scroll to bottom
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (text) {
                      // Handle Enter key
                      _sendMessage(text);
                    },
                  ),
                ),
                SizedBox(width: 8),

                // Send button with throttling
                ThrottledBuilder(
                  duration: Duration(seconds: 1), // Max 1 message per second
                  builder: (context, throttle) {
                    return IconButton(
                      icon: Icon(Icons.send, color: Colors.blue),
                      onPressed: throttle(() {
                        _sendMessage(_messageController.text);
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
```

## Advanced: With Typing Indicator & Read Receipts

```dart
class AdvancedChatScreen extends StatefulWidget {
  @override
  _AdvancedChatScreenState createState() => _AdvancedChatScreenState();
}

class _AdvancedChatScreenState extends State<AdvancedChatScreen> {
  final _messageController = TextEditingController();
  List<Message> _messages = [];
  bool _isSending = false;
  bool _otherUserTyping = false;

  // Debounce typing indicator (stop after 2s of no typing)
  final _typingDebouncer = Debouncer(
    duration: Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _listenToTypingIndicator();
  }

  void _onTextChanged() {
    // Send typing indicator to other user
    _typingDebouncer.call(() {
      ChatApi.sendTypingIndicator(widget.chatId, isTyping: false);
    });

    // User is typing
    ChatApi.sendTypingIndicator(widget.chatId, isTyping: true);
  }

  void _listenToTypingIndicator() {
    ChatApi.onTypingIndicator(widget.chatId).listen((isTyping) {
      setState(() => _otherUserTyping = isTyping);
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      // Optimistic UI update
      final tempMessage = Message(
        id: DateTime.now().toString(),
        text: text,
        senderId: 'me',
        timestamp: DateTime.now(),
        status: MessageStatus.sending,
      );

      setState(() {
        _messages.add(tempMessage);
        _messageController.clear();
      });

      // Send to backend
      final sentMessage = await ChatApi.sendMessage(
        chatId: widget.chatId,
        text: text,
      );

      // Update with real message
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage.copyWith(status: MessageStatus.sent);
        }
      });

      // Stop typing indicator
      ChatApi.sendTypingIndicator(widget.chatId, isTyping: false);
    } catch (e) {
      // Mark as failed
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            status: MessageStatus.failed,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _sendMessage(text),
          ),
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('John Doe'),
            if (_otherUserTyping)
              Text(
                'typing...',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // Throttled send button
                ThrottledBuilder(
                  duration: Duration(milliseconds: 1000),
                  builder: (context, throttle) {
                    return IconButton(
                      icon: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.send),
                      onPressed: throttle(() {
                        _sendMessage(_messageController.text);
                      }),
                      color: Colors.blue,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingDebouncer.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
```

## Comparison: Manual vs Library

### Without flutter_event_limiter (Manual):

```dart
DateTime? _lastSendTime;

void _onSendPressed() {
  // Manual throttle check
  final now = DateTime.now();
  if (_lastSendTime != null &&
      now.difference(_lastSendTime!) < Duration(seconds: 1)) {
    return; // Ignore rapid clicks
  }
  _lastSendTime = now;

  _sendMessage(_messageController.text);
}

Widget build(BuildContext context) {
  return IconButton(
    onPressed: _onSendPressed,
    icon: Icon(Icons.send),
  );
}
```

**Issues:** Manual state management, easy to forget throttle check

### With flutter_event_limiter:

```dart
ThrottledBuilder(
  duration: Duration(seconds: 1),
  builder: (context, throttle) {
    return IconButton(
      onPressed: throttle(() => _sendMessage(_messageController.text)),
      icon: Icon(Icons.send),
    );
  },
)
```

**Benefits:** 5 lines, automatic throttling, cleaner code ✅

## Key Features

✅ **Prevents message spam** - Max 1 message per second (configurable)
✅ **Protects backend** - Reduces API load
✅ **Better UX** - Users see instant feedback (optimistic UI)
✅ **Rate limiting friendly** - Won't trigger backend rate limits
✅ **Auto cleanup** - No manual state management

## Best Practices

### 1. Combine with Optimistic UI

```dart
// Show message immediately, update status later
_messages.add(Message(text: text, status: MessageStatus.sending));
await ChatApi.sendMessage(text);
_messages.last.status = MessageStatus.sent;
```

### 2. Handle Message Failures

```dart
try {
  await ChatApi.sendMessage(text);
} catch (e) {
  _messages.last.status = MessageStatus.failed;
  // Show retry option
}
```

### 3. Add Typing Indicator (Debounced)

```dart
// Stop showing "typing..." after 2s of inactivity
final typingDebouncer = Debouncer(duration: Duration(seconds: 2));

_messageController.addListener(() {
  typingDebouncer.call(() {
    ChatApi.sendTypingIndicator(isTyping: false);
  });
  ChatApi.sendTypingIndicator(isTyping: true);
});
```

### 4. Throttle Both Button and Enter Key

```dart
final sendThrottler = Throttler();

TextField(
  onSubmitted: (text) => sendThrottler.call(() => _sendMessage(text)),
  // ...
)

IconButton(
  onPressed: () => sendThrottler.call(() => _sendMessage(text)),
  // ...
)
```

## Message Status Indicators

```dart
enum MessageStatus { sending, sent, delivered, read, failed }

Widget _buildStatusIcon(MessageStatus status) {
  switch (status) {
    case MessageStatus.sending:
      return SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      );
    case MessageStatus.sent:
      return Icon(Icons.check, size: 16);
    case MessageStatus.delivered:
      return Icon(Icons.done_all, size: 16);
    case MessageStatus.read:
      return Icon(Icons.done_all, size: 16, color: Colors.blue);
    case MessageStatus.failed:
      return Icon(Icons.error_outline, size: 16, color: Colors.red);
  }
}
```

## Related Examples

- [E-Commerce](./e-commerce.md) - Preventing double submissions
- [Form Submission](./form-submission.md) - Async form handling
- [Search](./search.md) - Debounced search input

## Learn More

- [Throttle vs Debounce](../guides/throttle-vs-debounce.md)
- [API Reference](https://pub.dev/documentation/flutter_event_limiter)
- [Real-time App Best Practices](../guides/realtime-apps.md)
