import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lab_keeper/src/auth_handler.dart';
import 'package:lab_keeper/src/models/borrow_request.dart';
import 'package:lab_keeper/src/models/borrow_status.dart';
import 'package:lab_keeper/src/services/auth_service.dart';
import 'package:lab_keeper/src/ui/screens/home_screen.dart';
import 'package:lab_keeper/src/ui/screens/splash_screen.dart';
import 'package:lab_keeper/src/ui/widgets/request_return_page.dart';
import 'package:lab_keeper/src/ui/widgets/request_review_page.dart';
import 'package:lab_keeper/src/ui/widgets/returned_detail_page.dart';
import 'package:lab_keeper/src/ui/widgets/student_request_detail_page.dart';
import 'src/config/app_theme.dart';
import 'src/routes/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();
final _localNotif = FlutterLocalNotificationsPlugin();

void main()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyD8fHckSfnZ-xgbH-LJ448SeLrwHr_gics',
        appId: '1:626524693046:android:c86098bee404f9b6f82e97',
        messagingSenderId: '626524693046',
        projectId: 'labkeeper-b82bb',
        storageBucket: 'labkeeper-b82bb.firebasestorage.app',
      )
  );

  // Ask once per install
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: true
  );
  await _initLocalNotifications();

  // Obtain & store token
  String? _fcmToken = await FirebaseMessaging.instance.getToken();

  // Handle refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((token){
    _fcmToken = token;
    if (FirebaseAuth.instance.currentUser != null) {
      _saveFcmToken(token);
    }
  });

   FirebaseAuth.instance
     .authStateChanges()
      .listen((user) {
        if (user != null && _fcmToken != null) {
          _saveFcmToken(_fcmToken);
        }
      });

  // Optional: foreground local notif
  FirebaseMessaging.onMessage.listen(_showForegroundNotif);

  // 1) Cold-start handler
  final initMsg = await FirebaseMessaging.instance.getInitialMessage();

  final pendingRequestId = initMsg?.data['requestId'];

  // if (initMsg?.data['requestId'] != null) {
  //   _handleNotificationTap(initMsg!.data['requestId']!);
  // }

  // 2) Background & foreground tap handler
  FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    final rid = msg.data['requestId'];
    if (rid != null) {
      _handleNotificationTap(rid);
    }
  });

  runApp( LabKeeperApp(pendingRequestId: pendingRequestId));
}

class LabKeeperApp extends StatelessWidget {
  final String? pendingRequestId;
  const LabKeeperApp({this.pendingRequestId,super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'LabKeeper',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.generate,
      home: SplashScreen(pendingRequestId: pendingRequestId),
      // routes: {
      //   "/": (context)=>HomeScreen()
      // },
    );
  }
}

Future<void> _saveFcmToken(String? token) async {
  if (token == null) return;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // users/{uid}/tokens/{token}
  await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('tokens')
      .doc(token)
      .set({
    'createdAt': FieldValue.serverTimestamp(),
    'platform' : defaultTargetPlatform.name,
  });
}

Future<void> _initLocalNotifications() async {
  const channel = AndroidNotificationChannel(
    'high_importance',             // id
    'High Importance Notifications', // name
    description: 'Used for important alerts',
    importance: Importance.max,
    playSound: true,
  );

  // create the channel on the device
  await _localNotif
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // initialize plugin
  await _localNotif.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;
      if (payload != null) _handleNotificationTap(payload);
    },
  );
}

Future<void> _showForegroundNotif(RemoteMessage msg) async {
  // make sure we’ve already called _initLocalNotifications()
  final rid = msg.data['requestId'];
  await _localNotif.show(
    msg.hashCode,
    msg.notification?.title,
    msg.notification?.body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
    payload: rid,   // ← pass the requestId along
  );
}

Future<void> _handleNotificationTap(String requestId) async {
  // Fetch the latest request document
  final doc = await FirebaseFirestore.instance
      .collection('borrow_requests')
      .doc(requestId)
      .get();
  if (!doc.exists) return;

  // Parse into your model
  final request = BorrowRequest.fromJson(
    doc.id,
    doc.data()! as Map<String, dynamic>,
  );

  // Decide which page to show
  final profile = await AuthService.instance.currentUserProfile();

  if(profile == null) return;

  late Widget page;
  if(profile.role == 'Admin'){
    switch (request.status) {
      case BorrowStatus.pending:
        page = RequestReviewPage(request: request);
        break;
      case BorrowStatus.approved:
        page = ReturnReviewPage(request: request);
        break;
      case BorrowStatus.returned:
        page = ReturnedDetailPage(request: request);
        break;
      default:
        page = ReturnedDetailPage(request: request);
    }
  }
  else{
    page = StudentRequestDetailPage(request: request);
  }

  // Navigate on the root navigator
  navigatorKey.currentState?.push(
    MaterialPageRoute(builder: (_) => page),
  );
}

