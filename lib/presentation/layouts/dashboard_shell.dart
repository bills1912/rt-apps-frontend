import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rt_app_apk/models/user.dart';
import 'package:rt_app_apk/services/storage_services.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  State<DashboardShell> createState() =>
      _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  User? _user;

  Future<void> _loadUser() async {
    final user = await StorageServices.getUser();
    if (user != null) {
      setState(() {
        _user = user;
      });
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location =
        GoRouterState.of(context).uri.toString();

    if (location.startsWith('/dashboard/payment-history') ||
        (_user?.role == 'admin' &&
            location.startsWith(
              '/dashboard/payment-processing',
            )))
      return 1;
    if (location.startsWith('/dashboard/payment') ||
        (_user?.role == 'admin' &&
            location.startsWith(
              '/dashboard/payment-admin-list',
            )))
      return 0;
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
  void initState() {
    _loadUser();
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
            IconButton(
              onPressed: () {
                context.push('/notifications');
              },
              icon: Icon(
                Icons.notifications,
                color: Color.fromARGB(255, 255, 217, 95),
              ),
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
