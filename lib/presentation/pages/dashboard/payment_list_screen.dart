import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/models/tagihan.dart';
import 'package:rt_app_apk/models/user.dart';
import 'package:rt_app_apk/presentation/pages/auth/signin_screen.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/storage_services.dart';
import 'package:rt_app_apk/services/tagihan_services.dart';
import 'package:intl/intl.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() =>
      _PaymentListScreenState();
}

final ApiServices apiServices = ApiServices();
final TagihanServices tagihanServices = TagihanServices(
  apiServices,
);

class _PaymentListScreenState
    extends State<PaymentListScreen> {
  final List<Tagihan> _listTagihan = [];
  bool _isLoading = false;
  User? _user;

  Future<void> _fetchTagihan() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final result = await tagihanServices.getAll();
      setState(() {
        _listTagihan.addAll(result);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('fetch tagihan failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUser() async {
    final user = await StorageServices.getUser();
    if (user != null) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchTagihan();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_listTagihan.isEmpty) {
      return Center(child: Text('Belum ada tagihan baru'));
    }
    return PaymentAdmin(
      user: _user,
      listTagihan: _listTagihan,
    );
  }
}

class PaymentAdmin extends StatelessWidget {
  const PaymentAdmin({
    super.key,
    required User? user,
    required List<Tagihan> listTagihan,
  }) : _user = user,
       _listTagihan = listTagihan;

  final User? _user;
  final List<Tagihan> _listTagihan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: ListView.builder(
        itemCount:
            _user != null && _user!.role == 'admin'
                ? _listTagihan.length +
                    1 // extra item for button
                : _listTagihan.length,
        itemBuilder: (context, index) {
          if (_user != null &&
              _user!.role == 'admin' &&
              index == 0) {
            // Button at the top
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        () =>
                            context.push('/tagihan-create'),
                    label: Text('Tagihan'),
                    icon: Icon(Icons.create),
                  ),
                ],
              ),
            );
          }

          // Adjust index for tagihan list
          final tagihanIndex =
              _user != null && _user!.role == 'admin'
                  ? index - 1
                  : index;

          final tagihan = _listTagihan[tagihanIndex];
          return Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              onTap:
                  () => context.push(
                    '/tagihan-pay',
                    extra: tagihan,
                  ),
              title: Text(
                tagihan.tagihanName ??
                    'Tagihan ${DateFormat('dd MMM yyyy').format(tagihan.tagihanDate)}',
              ),
              subtitle: Text(
                'Rp. ${tagihan.totalPrice} - ${DateFormat('dd MMM yyyy').format(tagihan.tagihanDate)}',
              ),
              trailing: Text(
                '${tagihan.items.length} Pembayaran',
              ),
            ), // Replace with your item UI
          );
        },
      ),
    );
  }
}
