import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VoiceCallService {
  final SupabaseClient db = Supabase.instance.client;

  RTCPeerConnection? peer;
  MediaStream? local;
  RealtimeChannel? channel;

  final List<RTCIceCandidate> pendingCandidates = [];

  bool remoteReady = false;
  bool muted = false;

  String? callId;
  String? otherId;

  void Function(String)? onStatus;
  void Function()? onRemoteAudio;

  Completer<void>? _channelReady;
  int _localCandidateCount = 0;
  int _remoteCandidateCount = 0;

  // STUN membantu menemukan jalur langsung. Jika ICE berakhir FAILED
  // pada jaringan berbeda, tambahkan TURN dengan kredensial sementara
  // yang diterbitkan server. Jangan menanam kredensial TURN permanen di app.
  final Map<String, dynamic> rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  Future<void> _prepare(String id, String other) async {
    callId = id;
    otherId = other;
    remoteReady = false;
    pendingCandidates.clear();
    _localCandidateCount = 0;
    _remoteCandidateCount = 0;

    debugPrint('[VOICE][$id] Preparing peer for other=$other');

    local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    debugPrint(
      '[VOICE][$id] Local audio tracks=${local?.getAudioTracks().length ?? 0}',
    );

    peer = await createPeerConnection(rtcConfig);

    for (final track in local!.getAudioTracks()) {
      await peer!.addTrack(track, local!);
    }

    peer!.onIceCandidate = (candidate) async {
      if (candidate.candidate == null ||
          candidate.candidate!.isEmpty) {
        debugPrint('[ICE][$id] Empty/end-of-candidates event');
        return;
      }

      _localCandidateCount++;
      debugPrint(
        '[ICE][$id] Local candidate #$_localCandidateCount '
        'mid=${candidate.sdpMid} mLine=${candidate.sdpMLineIndex}',
      );

      try {
        // _send waits for the Broadcast channel to be subscribed,
        // so candidates cannot be silently sent before the channel is ready.
        await _send('ice', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      } catch (error, stackTrace) {
        debugPrint('[SIGNAL][$id] Failed to send ICE: $error');
        debugPrint('$stackTrace');
      }
    };

    peer!.onIceConnectionState = (state) {
      final stateText = state.toString();
      debugPrint(
        '[ICE][$id] iceConnectionState=$stateText '
        'localCandidates=$_localCandidateCount '
        'remoteCandidates=$_remoteCandidateCount '
        'queued=${pendingCandidates.length}',
      );

      if (stateText.contains('Connected') ||
          stateText.contains('Completed')) {
        onStatus?.call('Menghubungkan audio...');
      } else if (stateText.contains('Checking')) {
        onStatus?.call('Mencari jalur koneksi...');
      } else if (stateText.contains('Failed')) {
        onStatus?.call('Koneksi ICE gagal');
      } else if (stateText.contains('Disconnected')) {
        onStatus?.call('Koneksi terputus');
      }
    };

    peer!.onConnectionState = (state) {
      final stateText = state.toString();
      debugPrint('[WEBRTC][$id] peerConnectionState=$stateText');

      if (stateText.contains('Connected')) {
        onStatus?.call('Terhubung');
      } else if (stateText.contains('Failed')) {
        onStatus?.call('Koneksi gagal');
      } else if (stateText.contains('Disconnected')) {
        onStatus?.call('Koneksi terputus');
      }
    };

    peer!.onSignalingState = (state) {
      debugPrint('[SIGNAL][$id] signalingState=$state');
    };

    peer!.onIceGatheringState = (state) {
      debugPrint('[ICE][$id] iceGatheringState=$state');
    };

    peer!.onTrack = (event) {
      debugPrint(
        '[MEDIA][$id] onTrack kind=${event.track.kind} '
        'enabled=${event.track.enabled} '
        'streams=${event.streams.length}',
      );
      onRemoteAudio?.call();
    };

    final ready = Completer<void>();
    _channelReady = ready;

    channel = db.channel('voice:$id');

    channel!.onBroadcast(
      event: 'signal',
      callback: (payload) async {
        try {
          final currentUserId = db.auth.currentUser?.id;
          if (payload['sender'] == currentUserId) {
            return;
          }

          final type = payload['type']?.toString();
          final data = Map<String, dynamic>.from(
            payload['data'] as Map? ?? {},
          );

          debugPrint(
            '[SIGNAL][$id] Received type=$type '
            'from=${payload['sender']}',
          );

          if (peer == null) {
            debugPrint(
              '[SIGNAL][$id] Ignored $type because peer is disposed',
            );
            return;
          }

          if (type == 'offer') {
            final sdp = data['sdp']?.toString();
            if (sdp == null || sdp.isEmpty) {
              throw StateError('Offer SDP kosong.');
            }

            await peer!.setRemoteDescription(
              RTCSessionDescription(sdp, 'offer'),
            );

            remoteReady = true;
            await _flushCandidates();

            final answer = await peer!.createAnswer();
            await peer!.setLocalDescription(answer);

            await _send('answer', {'sdp': answer.sdp});
            onStatus?.call('Mencari jalur koneksi...');
          } else if (type == 'answer') {
            final sdp = data['sdp']?.toString();
            if (sdp == null || sdp.isEmpty) {
              throw StateError('Answer SDP kosong.');
            }

            await peer!.setRemoteDescription(
              RTCSessionDescription(sdp, 'answer'),
            );

            remoteReady = true;
            await _flushCandidates();
          } else if (type == 'ice') {
            final candidateText = data['candidate']?.toString();
            if (candidateText == null || candidateText.isEmpty) {
              debugPrint('[ICE][$id] Ignored empty remote candidate');
              return;
            }

            final rawMLine = data['sdpMLineIndex'];
            final int? mLineIndex = rawMLine is num
                ? rawMLine.toInt()
                : int.tryParse(rawMLine?.toString() ?? '');

            final candidate = RTCIceCandidate(
              candidateText,
              data['sdpMid']?.toString(),
              mLineIndex,
            );

            if (remoteReady) {
              await _addRemoteCandidate(candidate);
            } else {
              pendingCandidates.add(candidate);
              debugPrint(
                '[ICE][$id] Queued remote candidate; '
                'remote description not ready. '
                'queue=${pendingCandidates.length}',
              );
            }
          } else if (type == 'hangup') {
            onStatus?.call('Panggilan berakhir');
            await dispose();
          } else {
            debugPrint('[SIGNAL][$id] Unknown signal type=$type');
          }
        } catch (error, stackTrace) {
          debugPrint('[SIGNAL][$id] Error processing signal: $error');
          debugPrint('$stackTrace');
          onStatus?.call('Gangguan pertukaran sinyal');
        }
      },
    ).subscribe((status, [error]) {
      debugPrint('[SIGNAL][$id] channel status=$status error=$error');

      if (status == RealtimeSubscribeStatus.subscribed &&
          !ready.isCompleted) {
        ready.complete();
      }

      if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.closed) {
        if (!ready.isCompleted) {
          ready.completeError(
            error ?? StateError('Realtime channel status: $status'),
          );
        }
      }
    });

    await ready.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException(
        'Channel voice:$id tidak berhasil subscribe dalam 12 detik.',
      ),
    );

    debugPrint('[SIGNAL][$id] Broadcast channel subscribed and ready');
  }

  Future<void> _addRemoteCandidate(
    RTCIceCandidate candidate,
  ) async {
    final currentPeer = peer;
    if (currentPeer == null) return;

    try {
      await currentPeer.addCandidate(candidate);
      _remoteCandidateCount++;
      debugPrint(
        '[ICE][$callId] Added remote candidate #$_remoteCandidateCount '
        'mid=${candidate.sdpMid} mLine=${candidate.sdpMLineIndex}',
      );
    } catch (error, stackTrace) {
      debugPrint('[ICE][$callId] Failed to add remote candidate: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<void> _flushCandidates() async {
    if (pendingCandidates.isEmpty) {
      debugPrint('[ICE][$callId] No queued remote candidates to flush');
      return;
    }

    final queued = List<RTCIceCandidate>.from(pendingCandidates);
    pendingCandidates.clear();

    debugPrint(
      '[ICE][$callId] Flushing ${queued.length} queued remote candidates',
    );

    for (final candidate in queued) {
      await _addRemoteCandidate(candidate);
    }
  }

  Future<void> _send(
    String type,
    Map<String, dynamic> data,
  ) async {
    final currentChannel = channel;
    if (currentChannel == null) {
      throw StateError('Broadcast channel belum dibuat.');
    }

    final ready = _channelReady;
    if (ready == null) {
      throw StateError('Status kesiapan Broadcast belum tersedia.');
    }

    await ready.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => throw TimeoutException(
        'Menunggu Broadcast channel sebelum mengirim $type.',
      ),
    );

    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Pengguna tidak lagi login.');
    }

    debugPrint('[SIGNAL][$callId] Sending type=$type');

    await currentChannel.sendBroadcastMessage(
      event: 'signal',
      payload: {
        'sender': userId,
        'type': type,
        'data': data,
      },
    );
  }

  Future<String> start(String receiverId) async {
    final user = db.auth.currentUser;

    if (user == null) {
      throw StateError('Harus login');
    }

    if (user.id == receiverId) {
      throw StateError('Tidak dapat menelepon diri sendiri');
    }

    final result = await db
        .from('voice_calls')
        .insert({
          'caller_id': user.id,
          'receiver_id': receiverId,
          'status': 'ringing',
        })
        .select('id')
        .single();

    final id = result['id'] as String;

    try {
      await _prepare(id, receiverId);
      return id;
    } catch (_) {
      await db.from('voice_calls').update({
        'status': 'ended',
      }).eq('id', id);
      rethrow;
    }
  }

  Future<void> offer() async {
    final currentPeer = peer;
    if (currentPeer == null) {
      throw StateError('PeerConnection belum siap untuk membuat offer.');
    }

    final description = await currentPeer.createOffer();
    await currentPeer.setLocalDescription(description);

    debugPrint('[SIGNAL][$callId] Local offer set; sending SDP');
    await _send('offer', {'sdp': description.sdp});
  }

  Future<void> accept(
    String id,
    String callerId,
  ) async {
    await _prepare(id, callerId);

    await db.from('voice_calls').update({
      'status': 'accepted',
      'answered_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> toggleMute() async {
    muted = !muted;

    for (final track
        in local?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> hangup() async {
    try {
      if (channel != null &&
          _channelReady?.isCompleted == true &&
          peer != null) {
        await _send('hangup', {});
      }
    } catch (error) {
      debugPrint('[SIGNAL][$callId] Could not send hangup: $error');
    }

    if (callId != null) {
      try {
        await db.from('voice_calls').update({
          'status': 'ended',
          'ended_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', callId!);
      } catch (error) {
        debugPrint('[VOICE][$callId] Failed to update ended status: $error');
      }
    }

    await dispose();
  }

  Future<void> dispose() async {
    final oldChannel = channel;
    channel = null;
    _channelReady = null;
    remoteReady = false;
    pendingCandidates.clear();

    if (oldChannel != null) {
      try {
        await db.removeChannel(oldChannel);
      } catch (error) {
        debugPrint('[SIGNAL][$callId] Channel cleanup error: $error');
      }
    }

    for (final track
        in local?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }

    await local?.dispose();
    local = null;

    final oldPeer = peer;
    peer = null;
    await oldPeer?.close();

    debugPrint('[VOICE][$callId] Peer and local media disposed');
  }
}
