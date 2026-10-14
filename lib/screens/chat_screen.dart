import 'package:flutter/material.dart';
import '../constants/app_routes.dart';
import '../constants/app_theme.dart';
import '../widgets/bottom_navbar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _currentNavIndex = 3;
  final TextEditingController _messageController = TextEditingController();
  bool _showConversation = false;
  final List<Map<String, dynamic>> _messages = [];

  // Mock driver data
  final Map<String, dynamic> _driverData = {
    'name': 'Jane Cooper',
    'image': 'assets/person.png',
    'rating': 4.9,
    'status': 'Online',
  };

  @override
  void initState() {
    super.initState();

    // Check if we got arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null && args.containsKey('driver')) {
        setState(() {
          _showConversation = true;

          // Add initial message from driver
          _messages.add({
            'text':
                'Hi there! I\'m on my way to pick you up. Should be there in a few minutes.',
            'isFromMe': false,
            'time': DateTime.now().subtract(const Duration(minutes: 5)),
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _messages.add({
        'text': _messageController.text,
        'isFromMe': true,
        'time': DateTime.now(),
      });
      _messageController.clear();

      // Simulate driver response after a short delay
      if (_messages.length == 1) {
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _messages.add({
              'text': 'No problem! See you soon.',
              'isFromMe': false,
              'time': DateTime.now(),
            });
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title:
            _showConversation
                ? Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(_driverData['image']),
                      radius: 16,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _driverData['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          _driverData['status'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                )
                : const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
        centerTitle: false,
        actions: [
          if (_showConversation)
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.black),
              onPressed: () {
                // TODO: Implement call functionality
              },
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // TODO: Implement more options
            },
          ),
        ],
      ),
      body: _showConversation ? _buildChatInterface() : _buildEmptyChat(),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty message bubble image
          Image.asset(
            'assets/images/message.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 32),

          // No messages text
          const Text(
            'No Messages, yet.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'No messages in your inbox, yet!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Start conversation button - for demo purposes
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showConversation = true;
                // Add initial message from driver
                _messages.add({
                  'text':
                      'Hi there! I\'m on my way to pick you up. Should be there in a few minutes.',
                  'isFromMe': false,
                  'time': DateTime.now().subtract(const Duration(minutes: 5)),
                });
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text(
              'Start Sample Conversation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface() {
    return Column(
      children: [
        // Messages list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            reverse: true,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[_messages.length - 1 - index];
              return _buildMessageBubble(message);
            },
          ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                color: Colors.grey,
                onPressed: () {
                  // TODO: Implement attachment
                },
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.white,
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromMe = message['isFromMe'] as bool;
    final time = message['time'] as DateTime;
    final text = message['text'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe)
            CircleAvatar(
              backgroundImage: AssetImage(_driverData['image']),
              radius: 16,
            ),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFromMe ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isFromMe ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color:
                          isFromMe
                              ? Colors.white.withOpacity(0.7)
                              : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          if (isFromMe)
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
        ],
      ),
    );
  }
}
