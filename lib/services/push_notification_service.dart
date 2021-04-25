import 'package:ask_help_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotification {
  Future initialize() async {
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  Future<String> getToken() async {
    // use the returned token to send messages to users from your custom server
    String token = await firebaseMessaging.getToken();

    print('This is token ::');
    print(token);

    users.doc(mUser.uid).collection('token').add({'token': token});

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }
}
