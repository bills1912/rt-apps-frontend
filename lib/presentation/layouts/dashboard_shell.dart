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

    if (location.startsWith('/dashboard/payment-history') ||
        (_user?.role == 'admin' &&
            location.startsWith('/dashboard/payment-processing'))) return 1;
    if (location.startsWith('/dashboard/payment') ||
        (_user?.role == 'admin' &&
            location.startsWith('/dashboard/payment-admin-list'))) return 0;
    if (location.startsWith('/dashboard/profile')) return 2;

    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard/payment');
      case 1:
        if (_user != null && _user!.role == 'user') {
          context.go('/dashboard/payment-history');
          break;
        } else {
          context.go('/dashboard/payment-processing');
          break;
        }
      case 2:
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }
}