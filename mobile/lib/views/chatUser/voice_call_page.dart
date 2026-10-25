import 'dart:async';

import 'package:flutter/foundation.dart';
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

  final SupabaseClient supabase = Supabase.instance.client;

  StreamSubscription<List<Map<String, dynamic>>>?
      subscription;

  String status = 'Menyiapkan panggilan...';

  String? activeCallId;

  bool muted = false;
  bool speaker = false;
  bool finished = false;
  bool connecting = false;
  bool offerSent = false;

  @override
  void initState() {
    super.initState();

    service.onStatus = (value) {
      debugPrint('WEBRTC STATUS: $value');

      if (!mounted || finished) return;

      setState(() {
        status = value;
      });

      if (value == 'Panggilan berakhir') {
        _close();
      }
    };

    service.onRemoteAudio = () {
      debugPrint('REMOTE AUDIO TRACK RECEIVED');

      if (!mounted || finished) return;

      setState(() {
        status = 'Menghubungkan audio...';
      });
    };

    _start();
  }

  // =====================================================
  // MEMULAI ATAU MENERIMA PANGGILAN
  // =====================================================

  Future<void> _start() async {
    if (connecting || finished) return;

    connecting = true;

    try {
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw StateError(
          'Pengguna belum login ke Supabase.',
        );
      }

      debugPrint('================================');
      debugPrint('VOICE CALL START');
      debugPrint('CURRENT USER: $currentUserId');
      debugPrint('PEER ID: ${widget.peerId}');
      debugPrint('INCOMING ID: ${widget.incomingCallId}');
      debugPrint('================================');

      if (widget.incomingCallId != null) {
        await _acceptIncomingCall();
      } else {
        await _startOutgoingCall();
      }
    } catch (e, stackTrace) {
      debugPrint('VOICE CALL ERROR: $e');
      debugPrint('VOICE CALL STACKTRACE: $stackTrace');

      if (mounted && !finished) {
        setState(() {
          status = 'Gagal memulai panggilan: $e';
        });
      }

      // Jika koneksi awal gagal, hentikan sesi.
      // Pertahankan tampilan error agar dapat diperiksa.
      try {
        await service.hangup();
      } catch (cleanupError) {
        debugPrint(
          'VOICE CALL CLEANUP ERROR: $cleanupError',
        );
      }
    } finally {
      connecting = false;
    }
  }

  // =====================================================
  // PANGGILAN KELUAR
  // =====================================================

  Future<void> _startOutgoingCall() async {
    debugPrint('START OUTGOING CALL');

    final id = await service.start(widget.peerId);

    activeCallId = id;

    debugPrint('CALL ID: $id');
    debugPrint(
      'CALLER ID: ${supabase.auth.currentUser?.id}',
    );
    debugPrint('RECEIVER ID: ${widget.peerId}');

    if (!mounted || finished) return;

    setState(() {
      status = 'Memanggil...';
    });

    // Memantau perubahan status panggilan.
    subscription = supabase
        .from('voice_calls')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .listen(
      (rows) async {
        if (finished || rows.isEmpty) return;

        final callStatus =
            rows.first['status']?.toString();

        debugPrint('CALL STATUS: $callStatus');

        if (callStatus == 'accepted') {
          if (offerSent) return;

          offerSent = true;

          debugPrint(
            'RECEIVER ACCEPTED. CREATING OFFER...',
          );

          try {
            await service.offer();

            if (mounted && !finished) {
              setState(() {
                status = 'Menghubungkan...';
              });
            }
          } catch (e, stackTrace) {
            debugPrint('OFFER ERROR: $e');
            debugPrint(
              'OFFER STACKTRACE: $stackTrace',
            );

            if (mounted && !finished) {
              setState(() {
                status = 'Gagal menghubungkan: $e';
              });
            }
          }
        } else if (callStatus == 'declined') {
          debugPrint('CALL DECLINED');

          if (mounted && !finished) {
            setState(() {
              status = 'Panggilan ditolak';
            });
          }

          await Future<void>.delayed(
            const Duration(seconds: 1),
          );

          await _close(updateRemote: false);
        } else if (callStatus == 'ended') {
          debugPrint('CALL ENDED BY REMOTE');

          await _close(updateRemote: false);
        }
      },
      onError: (error, stackTrace) {
        debugPrint('CALL STREAM ERROR: $error');
        debugPrint(
          'CALL STREAM STACKTRACE: $stackTrace',
        );

        if (mounted && !finished) {
          setState(() {
            status = 'Gagal memantau panggilan';
          });
        }
      },
    );
  }

  // =====================================================
  // MENERIMA PANGGILAN MASUK
  // =====================================================

  Future<void> _acceptIncomingCall() async {
    final id = widget.incomingCallId!;

    activeCallId = id;

    debugPrint('ACCEPT INCOMING CALL');
    debugPrint('CALL ID: $id');
    debugPrint('CALLER: ${widget.peerId}');

    // Pastikan panggilan masih menunggu jawaban.
    final record = await supabase
        .from('voice_calls')
        .select('id, caller_id, receiver_id, status')
        .eq('id', id)
        .maybeSingle();

    if (record == null) {
      throw StateError(
        'Data panggilan tidak ditemukan.',
      );
    }

    if (record['receiver_id'] !=
        supabase.auth.currentUser?.id) {
      throw StateError(
        'Akun ini bukan penerima panggilan.',
      );
    }

    if (record['caller_id'] != widget.peerId) {
      throw StateError(
        'Identitas pemanggil tidak sesuai.',
      );
    }

    if (record['status'] != 'ringing') {
      throw StateError(
        'Panggilan tidak lagi aktif.',
      );
    }

    await service.accept(
      id,
      widget.peerId,
    );

    debugPrint('CALL ACCEPTED');

    if (mounted && !finished) {
      setState(() {
        status = 'Menghubungkan...';
      });
    }

    // Memantau apabila pemanggil mengakhiri panggilan.
    subscription = supabase
        .from('voice_calls')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .listen(
      (rows) async {
        if (finished || rows.isEmpty) return;

        final callStatus =
            rows.first['status']?.toString();

        debugPrint(
          'INCOMING CALL STATUS: $callStatus',
        );

        if (callStatus == 'ended' ||
            callStatus == 'declined') {
          await _close(updateRemote: false);
        }
      },
      onError: (error) {
        debugPrint(
          'INCOMING STREAM ERROR: $error',
        );
      },
    );
  }

  // =====================================================
  // MUTE MIKROFON
  // =====================================================

  Future<void> _toggleMute() async {
    if (finished) return;

    try {
      await service.toggleMute();

      if (!mounted) return;

      setState(() {
        muted = service.muted;
      });

      debugPrint(
        'MICROPHONE MUTED: $muted',
      );
    } catch (e) {
      debugPrint('MUTE ERROR: $e');
    }
  }

  // =====================================================
  // PENGATURAN SPEAKER
  // =====================================================

  Future<void> _toggleSpeaker() async {
    if (finished) return;

    try {
      if (kIsWeb) {
        // Browser mengelola output audio melalui
        // pengaturan perangkat dan izin browser.
        debugPrint(
          'WEB: Speaker selection is browser-managed.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Untuk Chrome, atur keluaran suara '
                'melalui pengaturan audio perangkat.',
              ),
            ),
          );
        }

        return;
      }

      final newValue = !speaker;

      await Helper.setSpeakerphoneOn(newValue);

      if (!mounted) return;

      setState(() {
        speaker = newValue;
      });

      debugPrint(
        'SPEAKER ENABLED: $speaker',
      );
    } catch (e) {
      debugPrint('SPEAKER ERROR: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat mengubah speaker: $e',
            ),
          ),
        );
      }
    }
  }

  // =====================================================
  // MENGAKHIRI PANGGILAN
  // =====================================================

  Future<void> _close({
    bool updateRemote = true,
  }) async {
    if (finished) return;

    finished = true;

    debugPrint('CLOSING CALL: $activeCallId');

    try {
      await subscription?.cancel();
      subscription = null;

      if (updateRemote) {
        await service.hangup();
      } else {
        await service.dispose();
      }
    } catch (e) {
      debugPrint('CLOSE CALL ERROR: $e');

      try {
        await service.dispose();
      } catch (cleanupError) {
        debugPrint(
          'DISPOSE ERROR: $cleanupError',
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    subscription?.cancel();

    if (!finished) {
      finished = true;
      service.hangup().catchError((Object error) {
        debugPrint('DISPOSE HANGUP ERROR: $error');
      });
    }

    super.dispose();
  }

  // =====================================================
  // TAMPILAN HALAMAN PANGGILAN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17232B),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Panggilan suara'),
      ),

      body: SafeArea(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Spacer(),

            // FOTO PROFIL
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF334854),
              child: Icon(
                Icons.person,
                size: 55,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // NAMA PENERIMA / PEMANGGIL
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Text(
                widget.peerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // STATUS PANGGILAN
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // INDIKATOR
            if (status == 'Memanggil...' ||
                status == 'Menghubungkan...' ||
                status == 'Menyiapkan panggilan...')
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),

            const Spacer(),

            // KONTROL PANGGILAN
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
              children: [
                // MUTE
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: muted
                          ? 'Aktifkan mikrofon'
                          : 'Matikan mikrofon',
                      onPressed:
                          finished ? null : _toggleMute,
                      icon: Icon(
                        muted
                            ? Icons.mic_off
                            : Icons.mic,
                        color: Colors.white,
                      ),
                      iconSize: 32,
                    ),
                    const Text(
                      'Mikrofon',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // SPEAKER
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Pengaturan speaker',
                      onPressed:
                          finished ? null : _toggleSpeaker,
                      icon: Icon(
                        speaker
                            ? Icons.volume_up
                            : Icons.hearing,
                        color: Colors.white,
                      ),
                      iconSize: 32,
                    ),
                    const Text(
                      'Speaker',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // AKHIRI PANGGILAN
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Akhiri panggilan',
                      onPressed: finished
                          ? null
                          : () => _close(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(
                        Icons.call_end,
                        color: Colors.white,
                      ),
                      iconSize: 32,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Akhiri',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
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