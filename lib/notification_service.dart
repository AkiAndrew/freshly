import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> checkAndNotifyExpiry(String userId) async {
    final now = DateTime.now();
    final threeDaysLater = now.add(const Duration(days: 3));

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('products')
            .where(
              'expirationDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(now),
            )
            .where(
              'expirationDate',
              isLessThanOrEqualTo: Timestamp.fromDate(threeDaysLater),
            )
            .get();

    final expiringProducts =
        querySnapshot.docs.map((doc) {
          final data = doc.data();
          return data['name'] ?? 'Unnamed product';
        }).toList();

    if (expiringProducts.isEmpty) return;

    final productNames = expiringProducts.join(', ');

    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'expiry_channel_id',
      'Expiry Notifications',
      channelDescription: 'Notifications for products nearing expiry',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Products Near Expiry',
      'The following products expire soon: $productNames',
      platformChannelSpecifics,
    );
  }
}
