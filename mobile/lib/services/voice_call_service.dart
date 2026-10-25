
import 'dart:async';

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

  final Map<String, dynamic> rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  Future<void> _prepare(String id, String other) async {
    callId = id;
    otherId = other;

    local = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    peer = await createPeerConnection(rtcConfig);

    for (final track in local!.getAudioTracks()) {
      await peer!.addTrack(track, local!);
    }

    peer!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _send('ice', {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    peer!.onTrack = (_) => onRemoteAudio?.call();

    peer!.onConnectionState = (state) {
      if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onStatus?.call('Terhubung');
      }

      if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        onStatus?.call('Koneksi gagal');
      }
    };

    final ready = Completer<void>();

    channel = db.channel('voice:$id');

    channel!.onBroadcast(
      event: 'signal',
      callback: (payload) async {
        if (payload['sender'] == db.auth.currentUser?.id) {
          return;
        }

        final type = payload['type']?.toString();

        final data = Map<String, dynamic>.from(
          payload['data'] as Map? ?? {},
        );

        if (type == 'offer') {
          await peer!.setRemoteDescription(
            RTCSessionDescription(
              data['sdp'] as String,
              'offer',
            ),
          );

          remoteReady = true;
          await _flushCandidates();

          final answer = await peer!.createAnswer();

          await peer!.setLocalDescription(answer);

          await _send('answer', {
            'sdp': answer.sdp,
          });

          onStatus?.call('Menghubungkan...');
        } else if (type == 'answer') {
          await peer!.setRemoteDescription(
            RTCSessionDescription(
              data['sdp'] as String,
              'answer',
            ),
          );

          remoteReady = true;
          await _flushCandidates();
        } else if (type == 'ice') {
          final candidate = RTCIceCandidate(
            data['candidate'] as String?,
            data['sdpMid'] as String?,
            data['sdpMLineIndex'] as int?,
          );

          if (remoteReady) {
            await peer!.addCandidate(candidate);
          } else {
            pendingCandidates.add(candidate);
          }
        } else if (type == 'hangup') {
          onStatus?.call('Panggilan berakhir');
          await dispose();
        }
      },
    ).subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed &&
          !ready.isCompleted) {
        ready.complete();
      }

      if (status == RealtimeSubscribeStatus.channelError &&
          !ready.isCompleted) {
        ready.completeError(
          error ?? StateError('Realtime gagal'),
        );
      }
    });

    await ready.future.timeout(
      const Duration(seconds: 12),
    );
  }

  Future<void> _flushCandidates() async {
    for (final candidate in pendingCandidates) {
      await peer!.addCandidate(candidate);
    }

    pendingCandidates.clear();
  }

  Future<void> _send(
    String type,
    Map<String, dynamic> data,
  ) async {
    await channel?.sendBroadcastMessage(
      event: 'signal',
      payload: {
        'sender': db.auth.currentUser!.id,
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
      throw StateError(
        'Tidak dapat menelepon diri sendiri',
      );
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
    final description = await peer!.createOffer();

    await peer!.setLocalDescription(description);

    await _send('offer', {
      'sdp': description.sdp,
    });
  }

  Future<void> accept(
    String id,
    String callerId,
  ) async {
    await _prepare(id, callerId);

    await db.from('voice_calls').update({
      'status': 'accepted',
      'answered_at':
          DateTime.now().toUtc().toIso8601String(),
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
    await _send('hangup', {});

    if (callId != null) {
      await db.from('voice_calls').update({
        'status': 'ended',
        'ended_at':
            DateTime.now().toUtc().toIso8601String(),
      }).eq('id', callId!);
    }

    await dispose();
  }

  Future<void> dispose() async {
    if (channel != null) {
      await db.removeChannel(channel!);
    }

    channel = null;

    for (final track
        in local?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }

    await local?.dispose();
    local = null;

    await peer?.close();
    peer = null;
  }
}
