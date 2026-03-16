import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String) onSendText;
  final Function(File) onSendImage;
  final Function(File, int) onSendVoice;

  const ChatInputBar({
    super.key,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendVoice,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textCtrl = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  DateTime? _recordStart;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
        lowerBound: 0.85,
        upperBound: 1.0);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _recorder.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final status = await Permission.photos.request();
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      widget.onSendImage(File(picked.path));
    }
  }

  Future<void> _pickCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 75);
    if (picked != null) {
      widget.onSendImage(File(picked.path));
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    final dir = await getTemporaryDirectory();
    _recordingPath =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordingPath!,
    );
    _recordStart = DateTime.now();
    setState(() => _isRecording = true);
    _pulseCtrl.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    _pulseCtrl.stop();
    _pulseCtrl.value = 1.0;
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path != null && _recordStart != null) {
      final duration =
          DateTime.now().difference(_recordStart!).inSeconds;
      if (duration >= 1) {
        widget.onSendVoice(File(path), duration);
      }
    }
  }

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    widget.onSendText(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          // ── Image / Camera buttons ───────────────────────
          if (!_isRecording) ...[
            _InputIconBtn(
              icon: Icons.image_outlined,
              onTap: _pickImage,
            ),
            const SizedBox(width: 4),
            _InputIconBtn(
              icon: Icons.camera_alt_outlined,
              onTap: _pickCamera,
            ),
            const SizedBox(width: 8),
          ],
          // ── Text field ───────────────────────────────────
          Expanded(
            child: _isRecording
                ? _RecordingIndicator(pulseAnim: _pulseAnim)
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: (_) => _sendText(),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 15),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        // send button inside field
                        ValueListenableBuilder(
                          valueListenable: _textCtrl,
                          builder: (_, val, __) => val.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: _sendText,
                                  child: Container(
                                    margin: const EdgeInsets.all(6),
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6C63FF),
                                          Color(0xFF48CAE4)
                                        ],
                                      ),
                                    ),
                                    child: const Icon(Icons.send_rounded,
                                        color: Colors.white, size: 18),
                                  ),
                                )
                              : const SizedBox(width: 8),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // ── Mic button ───────────────────────────────────
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _isRecording
                    ? const LinearGradient(
                        colors: [Colors.redAccent, Colors.deepOrange])
                    : const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)]),
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording
                            ? Colors.redAccent
                            : const Color(0xFF6C63FF))
                        .withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _InputIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
      ),
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  final Animation<double> pulseAnim;

  const _RecordingIndicator({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: pulseAnim,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.redAccent),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Recording... release to send',
            style: TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
