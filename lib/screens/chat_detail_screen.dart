import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../core/theme.dart';
import '../l10n/strings_ar.dart';
import '../main.dart';
import '../models/chat_message.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// 1:1 chat: text, image, and voice-message bubbles (hold mic to record).
class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherName;
  final String? bookingId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    this.bookingId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  bool _recording = false;
  String? _recordPath;
  DateTime? _recordStart;
  String? _playingId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirestoreService>();
    final uid = currentUid();
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: fs.messages(widget.chatId),
              builder: (context, snap) {
                final msgs = snap.data ?? [];
                if (snap.connectionState ==
                        ConnectionState.waiting &&
                    msgs.isEmpty) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(
                        _scrollCtrl.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) =>
                      _bubble(msgs[i], msgs[i].senderId == uid),
                );
              },
            ),
          ),
          _inputBar(fs, uid),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m, bool mine) {
    final align =
        mine ? Alignment.centerLeft : Alignment.centerRight;
    // RTL: mine on the left looks odd; keep classic: mine → end side.
    final alignment =
        Directionality.of(context) == TextDirection.rtl
            ? (mine ? Alignment.centerLeft : Alignment.centerRight)
            : align;
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine
              ? BricolaTheme.primary
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: _bubbleContent(m, mine),
      ),
    );
  }

  Widget _bubbleContent(ChatMessage m, bool mine) {
    final fg = mine ? Colors.white : BricolaTheme.ink;
    if (m.isImage && m.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(m.mediaUrl!,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image)),
      );
    }
    if (m.isVoice && m.mediaUrl != null) {
      final playing = _playingId == m.id;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _togglePlay(m),
            icon: Icon(
                playing ? Icons.stop : Icons.play_arrow,
                color: fg),
          ),
          Text(
            '🎙️ ${_fmtDuration(m.durationSec)}',
            style: TextStyle(color: fg),
          ),
        ],
      );
    }
    return Text(m.textContent,
        style: TextStyle(color: fg, fontSize: 15, height: 1.4));
  }

  String _fmtDuration(int s) {
    if (s <= 0) return S.voiceMessage;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlay(ChatMessage m) async {
    if (_playingId == m.id) {
      await _player.stop();
      setState(() => _playingId = null);
    } else {
      await _player.play(UrlSource(m.mediaUrl!));
      setState(() => _playingId = m.id);
    }
  }

  Widget _inputBar(FirestoreService fs, String uid) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image,
                  color: BricolaTheme.primary),
              onPressed: _sending ? null : () => _sendImage(fs, uid),
            ),
            // Hold-to-record voice button
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressEnd: (_) =>
                  _stopAndSend(fs, uid),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _recording
                      ? BricolaTheme.danger
                      : BricolaTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _recording ? Icons.fiber_manual_record : Icons.mic,
                  color: _recording
                      ? Colors.white
                      : BricolaTheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _textCtrl,
                decoration: InputDecoration(
                  hintText: _recording
                      ? '🎙️ ${S.holdToRecord}'
                      : S.typeMessage,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
            IconButton(
              icon: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2))
                  : const Icon(Icons.send,
                      color: BricolaTheme.primary),
              onPressed: _sending
                  ? null
                  : () => _sendText(fs, uid),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText(
      FirestoreService fs, String uid) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _sending = true);
    try {
      await fs.sendMessage(
        bookingId: widget.bookingId ?? widget.chatId,
        chatId: widget.chatId,
        senderId: uid,
        receiverId: '',
        receiverName: widget.otherName,
        text: text,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage(
      FirestoreService fs, String uid) async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      final url = await context
          .read<StorageService>()
          .uploadChatAttachment(
            chatId: widget.chatId,
            file: File(picked.path),
            name:
                'img_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
      await fs.sendMessage(
        bookingId: widget.bookingId ?? widget.chatId,
        chatId: widget.chatId,
        senderId: uid,
        receiverId: '',
        receiverName: widget.otherName,
        type: ChatMessage.image,
        mediaUrl: url,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) return;
    _recordPath =
        '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordPath!,
    );
    _recordStart = DateTime.now();
    setState(() => _recording = true);
  }

  Future<void> _stopAndSend(
      FirestoreService fs, String uid) async {
    if (!_recording) return;
    final path = await _recorder.stop();
    final secs = _recordStart != null
        ? DateTime.now().difference(_recordStart!).inSeconds
        : 0;
    setState(() => _recording = false);
    if (path == null || secs < 1) return;
    setState(() => _sending = true);
    try {
      final url = await context
          .read<StorageService>()
          .uploadVoiceMessage(
            chatId: widget.chatId,
            file: File(path),
            name: 'v_${DateTime.now().millisecondsSinceEpoch}',
          );
      await fs.sendMessage(
        bookingId: widget.bookingId ?? widget.chatId,
        chatId: widget.chatId,
        senderId: uid,
        receiverId: '',
        receiverName: widget.otherName,
        type: ChatMessage.voice,
        mediaUrl: url,
        durationSec: secs,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}
