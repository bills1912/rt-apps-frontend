import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rt_app_apk/models/notification_model.dart';
import 'package:rt_app_apk/models/user.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/notification_services.dart';
import 'package:rt_app_apk/services/storage_services.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  User? _user;
  int _notificationCount = 0;
  final ApiServices _apiServices = ApiServices();
  late NotificationServices _notificationServices;

  @override
  void initState() {
    super.initState();
    _notificationServices = NotificationServices(_apiServices);
    _loadUser();
    _loadNotificationCount();

    // Auto refresh notification count every time dashboard becomes visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAutoRefresh();
    });
  }

  void _setupAutoRefresh() {
    // Refresh when app comes to foreground
    // This will update badge when user returns to app
    if (_user?.role == 'user') {
      _loadNotificationCount();
    }
  }

  @override
  void didUpdateWidget(DashboardShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh notification count when widget updates
    if (_user?.role == 'user') {
      _loadNotificationCount();
    }
  }

  Future<void> _loadUser() async {
    final user = await StorageServices.getUser();
    if (user != null) {
      setState(() {
        _user = user;
      });
      // Refresh notification count after user loaded
      if (_user?.role == 'user') {
        _loadNotificationCount();
      }
    }
  }

  Future<void> _loadNotificationCount() async {
    if (_user?.role != 'user') return;

    try {
      final notifications = await _notificationServices.getAll();
      if (mounted) {
        setState(() {
          _notificationCount = notifications.length;
        });
      }
    } catch (e) {
      print('Error loading notification count: $e');
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final role = _user?.role;

    // --- LOGIKA KHUSUS ADMIN (4 Tombol) ---
    if (role == 'admin') {
      // Index 0: Home
      if (location.startsWith('/dashboard/payment') ||
          location.startsWith('/dashboard/payment-admin-list')) return 0;

      // Index 1: List / Payment Processing
      if (location.startsWith('/dashboard/payment-processing') ||
          location.startsWith('/dashboard/payment-history')) return 1;

      // Index 2: Data Warga (Ini yang sebelumnya hilang/salah)
      if (location.startsWith('/dashboard/data-warga')) return 2;

      // Index 3: Profile (Sebelumnya tertulis return 2)
      if (location.startsWith('/dashboard/profile')) return 3;

      return 0;
    }

    // --- LOGIKA KHUSUS RT (3 Tombol) ---
    if (role == 'rt') {
      if (location.startsWith('/dashboard/rt-dashboard')) return 0;
      if (location.startsWith('/dashboard/data-warga')) return 1;
      if (location.startsWith('/dashboard/profile')) return 2;
      return 0;
    }

    // --- LOGIKA KHUSUS USER BIASA (3 Tombol) ---
    // Index 0: Home
    if (location.startsWith('/dashboard/payment')) return 0;
    // Index 1: History
    if (location.startsWith('/dashboard/payment-history')) return 1;
    // Index 2: Profile
    if (location.startsWith('/dashboard/profile')) return 2;

    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
      // For RT role, go to RT dashboard instead of payment
        if (_user != null && _user!.role == 'rt') {
          context.go('/dashboard/rt-dashboard');
        } else {
          context.go('/dashboard/payment');
        }
        break;
      case 1:
        if (_user != null && _user!.role == 'user') {
          context.go('/dashboard/payment-history');
        } else if (_user != null && _user!.role == 'rt') {
          context.go('/dashboard/data-warga');
        } else {
          context.go('/dashboard/payment-processing');
        }
        break;
      case 2:
        if (_user != null && _user!.role == 'rt' || _user != null && _user!.role == 'user') {
          context.go('/dashboard/profile');
        } else {
          context.go('/dashboard/data-warga');
        }
        break;
      case 3:
        context.go('/dashboard/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.child,
      appBar: AppBar(
        title: Image.asset(
          'assets/img/simpruglogo.png',
          scale: 40,
        ),
        elevation: 0,
        actions: [
          if (_user != null && _user!.role == 'admin')
            Padding( // Gunakan padding agar tidak terlalu mepet
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: () {
                  context.push('/dashboard/laporan-keuangan');
                },
                // Gunakan icon wallet yang sesuai dengan desain Anda
                icon: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white, // Sesuaikan warna
                  size: 28,
                ),
                tooltip: 'Laporan Keuangan',
              ),
            ),
          if (_user != null && _user!.role == 'user')
            Stack(
              children: [
                IconButton(
                  onPressed: () async {
                    // Reset counter when opening notifications
                    setState(() {
                      _notificationCount = 0;
                    });

                    // Navigate to notifications
                    await context.push('/notifications');

                    // Reload count after returning
                    _loadNotificationCount();
                  },
                  icon: Icon(
                    Icons.notifications,
                    color: Color.fromARGB(255, 255, 217, 95),
                  ),
                ),
                // Badge counter
                if (_notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        _notificationCount > 99 ? '99+' : '$_notificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(context, index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          if (_user != null && _user!.role == 'user')
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: '',
            ),
          if (_user != null && _user!.role == 'admin')
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: '',
            ),
          if (_user != null && _user!.role == 'rt')
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: '',
            ),
          if (_user != null && _user!.role == 'admin')
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: '',
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }
}