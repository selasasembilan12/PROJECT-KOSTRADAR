
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/voice_call_service.dart';

class VoiceCallPage extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String? incomingCallId;

  const VoiceCallPage({
    super.key,
    required this.peerId,
    required this.peerName,
    this.incomingCallId,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  final VoiceCallService service = VoiceCallService();

  String status = 'Menyiapkan panggilan...';

  bool muted = false;
  bool speaker = false;
  bool finished = false;

  StreamSubscription<List<Map<String, dynamic>>>?
      subscription;

  @override
  void initState() {
    super.initState();

    service.onStatus = (value) {
      if (mounted) {
        setState(() => status = value);
      }

      if (value == 'Panggilan berakhir' && mounted) {
        _close();
      }
    };

    _start();
  }

  Future<void> _start() async {
    try {
      if (widget.incomingCallId != null) {
        await service.accept(
          widget.incomingCallId!,
          widget.peerId,
        );

        if (mounted) {
          setState(() => status = 'Menghubungkan...');
        }
      } else {
        final id = await service.start(widget.peerId);

        if (!mounted) return;

        setState(() => status = 'Memanggil...');

        subscription = Supabase.instance.client
            .from('voice_calls')
            .stream(primaryKey: ['id'])
            .eq('id', id)
            .listen((rows) async {
          if (rows.isEmpty || finished) return;

          final callStatus = rows.first['status'];

          if (callStatus == 'accepted') {
            await subscription?.cancel();
            subscription = null;

            await service.offer();
          } else if (
              callStatus == 'ended' ||
              callStatus == 'declined') {
            if (mounted) {
              _close();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => status = 'Gagal: $e');
      }
    }
  }

  Future<void> _close() async {
    if (finished) return;

    finished = true;

    await subscription?.cancel();
    await service.hangup();

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    subscription?.cancel();

    if (!finished) {
      service.hangup();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17232B),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Panggilan suara'),
      ),

      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            const CircleAvatar(
              radius: 48,
              child: Icon(
                Icons.person,
                size: 52,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              widget.peerName,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              status,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),

            const Spacer(),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () async {
                    await service.toggleMute();

                    if (mounted) {
                      setState(() {
                        muted = service.muted;
                      });
                    }
                  },
                  icon: Icon(
                    muted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                  iconSize: 32,
                ),

                IconButton(
                  onPressed: () async {
                    speaker = !speaker;

                    await Helper.setSpeakerphoneOn(speaker);

                    if (mounted) {
                      setState(() {});
                    }
                  },
                  icon: Icon(
                    speaker
                        ? Icons.volume_up
                        : Icons.hearing,
                    color: Colors.white,
                  ),
                  iconSize: 32,
                ),

                IconButton(
                  onPressed: _close,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  icon: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                  ),
                  iconSize: 34,
                ),
              ],
            ),

            const SizedBox(height: 55),
          ],
        ),
      ),
    );
  }
}
