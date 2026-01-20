import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/models/payment_add_item_args.dart';
import 'package:rt_app_apk/models/tagihan.dart';
import 'package:rt_app_apk/models/tagihan_item.dart';
import 'package:rt_app_apk/models/tagihan_user.dart';
import 'package:rt_app_apk/models/user.dart';
import 'package:rt_app_apk/presentation/layouts/dashboard_shell.dart';
import 'package:rt_app_apk/presentation/pages/auth/signin_screen.dart';
import 'package:rt_app_apk/presentation/pages/auth/signup_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/laporan_keuangan_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/laporan_keuangan_user_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/notification_list_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_add_item.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_admin_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_create.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_detail_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_history_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_informasi_pembayaran_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_list_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_pay_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_tagihan_user_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_update_user_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/profile_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/data_warga_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/rt_dashboard_screen.dart';
import 'package:rt_app_apk/presentation/pages/dashboard/payment_update_admin_screen.dart';
import 'package:rt_app_apk/presentation/pages/modal/success_modal.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp();
  print('📩 [Background] Title: ${message.notification?.title}');
  print('📩 [Background] Body: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _initLocalNotification();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackroundHandler);
  runApp(const MyApp());
  _requestPermission();
  _setupFCMListeners();
}

Future<void> _initLocalNotification() async {
  const AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

void _requestPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('🛡 Permission status: ${settings.authorizationStatus}');
}

void _setupFCMListeners() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📥 [Foreground] Title: ${message.data['title']}');
    print('📥 [Foreground] Body: ${message.data['body']}');

    if (message.data['title'] != null && message.data['body'] != null) {
      _showLocalNotification(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🚪 App opened via notification: ${message.data}');
  });
}

void _showLocalNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidDetails =
  AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidDetails);

  flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.data['title'],
    message.data['body'],
    notificationDetails,
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/sign-in',
  redirect: (context, state) async {
    final isUnauthenticatedRoute =
        state.fullPath == '/sign-in' || state.fullPath == '/sign-up';

    final authToken = await ApiServices().storage.read(key: 'auth_token');
    final isLoggedIn = authToken != null;

    // Jika belum login dan bukan di halaman auth, redirect ke sign-in
    if (!isLoggedIn && !isUnauthenticatedRoute) {
      return '/sign-in';
    }

    // Jika sudah login dan di halaman auth, redirect berdasarkan role
    if (isLoggedIn && isUnauthenticatedRoute) {
      try {
        final userJson = await ApiServices().storage.read(key: 'user_info');

        if (userJson != null && userJson.isNotEmpty) {
          final user = User.fromJson(jsonDecode(userJson));

          print('🔐 User logged in with role: ${user.role}');

          // Route berdasarkan role
          if (user.role == 'rt') {
            print('🏠 Redirecting RT to dashboard');
            return '/dashboard/rt-dashboard';
          } else if (user.role == 'admin') {
            print('🏠 Redirecting Admin to payment');
            return '/dashboard/payment';
          } else {
            print('🏠 Redirecting User to payment');
            return '/dashboard/payment';
          }
        }
      } catch (e) {
        print('❌ Error parsing user: $e');
      }

      // Default fallback
      return '/dashboard/payment';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/sign-up',
      builder: (_, _) => SignupScreen(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (_, _) => SigninScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => DashboardShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard/payment',
          builder: (_, _) => const PaymentScreen(),
        ),
        GoRoute(
          path: '/dashboard/profile',
          builder: (_, _) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/dashboard/payment-history',
          builder: (_, _) => const PaymentHistoryScreen(),
        ),
        GoRoute(
          path: '/dashboard/payment-processing',
          builder: (_, _) => PaymentTagihanUserScreen(),
        ),
        GoRoute(
          path: '/dashboard/payment-admin-list',
          builder: (_, _) => PaymentScreenAdmin(),
        ),
        GoRoute(
          path: '/dashboard/data-warga',
          builder: (_, _) => const DataWargaScreen(),
        ),
        GoRoute(
          path: '/dashboard/rt-dashboard',
          builder: (_, _) => const RTDashboardScreen(),
        ),
        GoRoute(
          path: '/dashboard/laporan-keuangan',
          builder: (_, _) => const LaporanKeuanganScreen(),
        ),
        GoRoute(
          path: '/laporan-keuangan-warga',
          builder: (_, _) => const LaporanKeuanganUserScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/tagihan-pay',
      builder: (context, state) {
        final tagihan = state.extra as Tagihan;
        return PaymentPayScreen(tagihan: tagihan);
      },
    ),
    GoRoute(
      path: '/payment-update-admin',
      builder: (context, state) {
        final tagihanUser = state.extra as TagihanUser;
        return PaymentUpdateAdminScreen(tagihanUser: tagihanUser);
      },
    ),
    GoRoute(
      path: '/payment-update-user',
      builder: (context, state) {
        final tagihanUser = state.extra as TagihanUser;
        return PaymentUpdateUserScreen(tagihanUser: tagihanUser);
      },
    ),
    GoRoute(
      path: '/tagihan-detail',
      builder: (context, state) {
        final tagihanUser = state.extra as TagihanUser;
        return PaymentDetailScreen(tagihanUser: tagihanUser);
      },
    ),
    GoRoute(
      path: '/tagihan-create',
      builder: (_, _) => PaymentCreate(),
    ),
    GoRoute(
      path: '/informasi-pembayaran',
      builder: (_, _) => PaymentInformasiPembayaranScreen(),
    ),
    GoRoute(
      path: '/payment-list',
      builder: (_, _) => PaymentListScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (_, _) => NotificationListScreen(),
    ),
    GoRoute(
      path: '/tagihan-add-item',
      builder: (context, state) {
        final args = state.extra as PaymentAddItemArgs;
        return PaymentAddItem(
          tagihanItems: args.tagihanItems,
          tagihanName: args.tagihanName,
        );
      },
    ),
    GoRoute(
      path: '/success-modal',
      builder: (_, _) => SuccessModal(),
    ),
    GoRoute(
      path: '/data-warga',
      builder: (_, _) => const DataWargaScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WargaPay',
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        appBarTheme: AppBarTheme(
          backgroundColor: ColorList.primary50,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: ColorList.primary50,
          surfaceTintColor: ColorList.primary50,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: ColorList.primary50,
          unselectedItemColor: Color.fromARGB(255, 105, 105, 102),
          showSelectedLabels: false,
          showUnselectedLabels: false,
        ),
      ),
    );
  }
}