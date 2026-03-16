import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../screens/image_viewer_screen.dart';
import 'voice_message_player.dart';
import '../services/translation_service.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showTail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 60 : 8,
        right: isMe ? 8 : 60,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showTail)
            _Avatar(name: message.senderId)
          else if (!isMe)
            const SizedBox(width: 32),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildBubble(context),
                const SizedBox(height: 2),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isSeen ? Icons.done_all : Icons.check,
                        size: 14,
                        color: message.isSeen ? const Color(0xFF48CAE4) : Colors.white.withOpacity(0.3),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context) {
    switch (message.type) {
      case MessageType.image:
        return _ImageBubble(url: message.content, isMe: isMe, context: context);
      case MessageType.voice:
        return _VoiceBubble(
            message: message, isMe: isMe);
      default:
        return _TextBubble(text: message.content, isMe: isMe);
    }
  }
}

// ── Text Bubble ─────────────────────────────────────────────────────────────
class _TextBubble extends StatefulWidget {
  final String text;
  final bool isMe;

  const _TextBubble({required this.text, required this.isMe});

  @override
  State<_TextBubble> createState() => _TextBubbleState();
}

class _TextBubbleState extends State<_TextBubble> {
  String? _translatedText;
  bool _isTranslating = false;
  String _activeLang = '';

  Future<void> _translate(String langCode) async {
    if (_activeLang == langCode && _translatedText != null) {
      // Toggle off if clicking the same language
      setState(() {
        _translatedText = null;
        _activeLang = '';
      });
      return;
    }

    setState(() {
      _isTranslating = true;
      _activeLang = langCode;
    });

    try {
      final res = await TranslationService.translate(widget.text, langCode);
      if (mounted) {
        setState(() {
          _translatedText = res;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      // Max width to prevent overly wide bubbles with long translations
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        gradient: widget.isMe
            ? const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF5b53e0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: widget.isMe ? null : const Color(0xFF1E2535),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(widget.isMe ? 18 : 4),
          bottomRight: Radius.circular(widget.isMe ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.isMe ? const Color(0xFF6C63FF) : Colors.black)
                .withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.text,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
          
          const SizedBox(height: 8),
          
          // Translation Action Row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangBtn('AR', 'ar'),
              const SizedBox(width: 6),
              _buildLangBtn('RU', 'ru'),
              const SizedBox(width: 6),
              _buildLangBtn('EN', 'en'),
            ],
          ),

          // Translation Result
          if (_isTranslating)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(color: Color(0xFF48CAE4), strokeWidth: 2)),
            )
          else if (_translatedText != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _translatedText!,
                style: const TextStyle(
                  color: Color(0xFF48CAE4),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLangBtn(String label, String code) {
    final isActive = _activeLang == code && _translatedText != null;
    return GestureDetector(
      onTap: () => _translate(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF48CAE4) : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF1E2535) : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── Image Bubble ─────────────────────────────────────────────────────────────
class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isMe;
  final BuildContext context;

  const _ImageBubble(
      {required this.url, required this.isMe, required this.context});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ImageViewerScreen(imageUrl: url)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            width: 220,
            height: 220,
            color: const Color(0xFF1E2535),
            child: const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF6C63FF), strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 220,
            height: 100,
            color: const Color(0xFF1E2535),
            child: const Icon(Icons.broken_image_outlined,
                color: Colors.white38),
          ),
        ),
      ),
    );
  }
}

// ── Voice Bubble ─────────────────────────────────────────────────────────────
class _VoiceBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _VoiceBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: isMe
            ? const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF5b53e0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMe ? null : const Color(0xFF1E2535),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.graphic_eq_rounded,
              color: isMe ? Colors.white70 : const Color(0xFF6C63FF),
              size: 18),
          const SizedBox(width: 6),
          VoiceMessagePlayer(
            audioUrl: message.content,
            durationSeconds: message.voiceDuration ?? 0,
            isMe: isMe,
          ),
        ],
      ),
    );
  }
}

// ── Avatar ───────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF48CAE4), Color(0xFF6C63FF)],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
