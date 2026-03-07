import "package:flutter/material.dart";
import "package:muna/muna.dart";

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final Muna _muna;
  final List<Message> _messages = [];
  bool _loading = false;
  String _streamedContent = "";

  @override
  void initState() {
    super.initState();
    _muna = Muna();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.add(Message(role: "user", content: text));
      _loading = true;
      _streamedContent = "";
    });
    _scrollToBottom();
    try {
      final chunks = await _muna.beta.openai.chat.completions.stream(
        messages: _messages,
        model: "@anon/smollm_2_135m",
        acceleration: "local_auto",
      );
      final content = chunks
          .expand((c) => c.choices)
          .map((c) => c.delta?.content ?? "")
          .join();
      setState(() {
        _messages.add(
          Message(role: "assistant", content: content),
        );
      });
    } catch (e) {
      setState(() {
        _streamedContent = "";
        _messages.add(
          Message(role: "assistant", content: "Error: $e"),
        );
      });
    } finally {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Build display list: all messages + streaming partial if active
    final displayCount =
        _messages.length + (_streamedContent.isNotEmpty ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: displayCount == 0
                ? Center(
                    child: Text(
                      "Send a message to start chatting",
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: displayCount,
                    itemBuilder: (context, index) {
                      final bool isStreaming = index == _messages.length &&
                          _streamedContent.isNotEmpty;
                      final role = isStreaming
                          ? "assistant"
                          : _messages[index].role;
                      final content = isStreaming
                          ? _streamedContent
                          : (_messages[index].content ?? "");
                      final isUser = role == "user";
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.78,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            content,
                            style: TextStyle(
                              color: isUser
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _onSend(),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _onSend,
                    icon: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
