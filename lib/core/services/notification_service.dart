import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation_service.dart';
import '../../features/sos/repositories/sos_repository.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/petugas/screens/detail_sos_screen.dart';
import '../../features/petugas/screens/pesan_screen.dart';
import '../../features/warga/screens/detail_sos_screen.dart' as warga;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // import kIsWeb

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Channel SOS
  static const _channelId   = 'sos_channel';
  static const _channelName = 'SOS Alerts';

  // Channel Informasi
  static const _infoChannelId   = 'info_channel';
  static const _infoChannelName = 'Informasi';

  static final _vibrationPattern =
      Int64List.fromList([0, 500, 200, 500, 200, 500]);

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );

    if (!kIsWeb) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotif.initialize(
        const InitializationSettings(android: android),
        onDidReceiveNotificationResponse: (details) {
          final payload = details.payload;
          if (payload == null) return;

          // Format payload: "sos:123" atau "info:456"
          if (payload.startsWith('sos:')) {
            _navigateToSosDetail(payload.replaceFirst('sos:', ''));
          } else if (payload.startsWith('info:')) {
            _navigateToInfo();
          }
        },
      );

      // Channel SOS dengan suara sirine
      final sosChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Notifikasi darurat patroli',
        importance: Importance.max,
        sound: const RawResourceAndroidNotificationSound('sirine'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: _vibrationPattern,
      );

      // Channel Informasi dengan suara default
      const infoChannel = AndroidNotificationChannel(
        _infoChannelId,
        _infoChannelName,
        description: 'Notifikasi informasi dari supervisor/admin',
        importance: Importance.high,
      );

      final plugin = _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await plugin?.createNotificationChannel(sosChannel);
      await plugin?.createNotificationChannel(infoChannel);
    }

    // Handle tap saat app background via FCM langsung
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      final type = msg.data['type'] ?? '';
      if (type == 'sos_baru') {
        final sosId = msg.data['sos_id'];
        if (sosId != null) _navigateToSosDetail(sosId);
      } else if (type == 'informasi_baru') {
        _navigateToInfo();
      }
    });

    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen(showLocalNotification);
    }
  }

  static Future<String?> getInitialPayload() async {
    if (!kIsWeb) {
      final launchDetails = await _localNotif.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        return launchDetails.notificationResponse?.payload;
      }
    }

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final type = initial.data['type'] ?? '';
      if (type == 'sos_baru') {
        return 'sos:${initial.data['sos_id']}';
      } else if (type == 'informasi_baru') {
        return 'info:${initial.data['informasi_id']}';
      }
    }
    return null;
  }

  static Future<void> _navigateToSosDetail(String sosId) async {
    final context = NavigationService.navigatorKey.currentContext;
    if (context == null) return;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token == null) return;

      final repo = SosRepository();
      final sos = await repo.getSOS(
        token: auth.token!,
        sosId: int.parse(sosId),
      );

      // Ambil role dari AuthProvider, fallback ke SharedPreferences
      // jika auth.user belum ter-load (misal app baru dibuka dari notif)
      String role = auth.user?.role ?? '';
      if (role.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        role = prefs.getString('user_role') ?? '';
        debugPrint('🔍 Role dari SharedPreferences: "$role"');
      }

      NavigationService.navigator?.push(
        MaterialPageRoute(
          builder: (_) {
            switch (role) {
              case 'warga':
                return warga.DetailSosScreen(sos: sos);
              case 'petugas':
              case 'supervisor':
              default:
                return DetailSosScreen(sos: sos);
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Navigasi ke detail SOS gagal: $e');
    }
  }

  static final StreamController<int> tabStream = StreamController<int>.broadcast();

  static void _navigateToInfo() {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    tabStream.add(3);
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static Future<void> showLocalNotification(RemoteMessage msg) async {
    if (kIsWeb) return;

    final title = msg.notification?.title ?? msg.data['title'];
    final body = msg.notification?.body ?? msg.data['body'];
    
    if (title == null && body == null) return;

    if (!_initialized) {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _localNotif.initialize(const InitializationSettings(android: android));
      _initialized = true;
    }

    final type   = msg.data['type'] ?? '';
    final isInfo = type == 'informasi_baru';

    final channelId   = isInfo ? _infoChannelId : _channelId;
    final channelName = isInfo ? _infoChannelName : _channelName;

    final id      = isInfo ? msg.data['informasi_id'] : msg.data['sos_id'];
    final notifId = id != null ? int.tryParse(id) ?? title.hashCode : title.hashCode;
    final payload = isInfo ? 'info:$id' : 'sos:$id';

    await _localNotif.show(
      notifId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: isInfo ? Importance.high : Importance.max,
          priority: isInfo ? Priority.defaultPriority : Priority.high,
          icon: 'ic_notif_color',
          color: const Color(0xFF142940),
          sound: isInfo
              ? null
              : const RawResourceAndroidNotificationSound('sirine'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: isInfo ? null : _vibrationPattern,
          fullScreenIntent: !isInfo,
        ),
      ),
      payload: payload,
    );
  }
}