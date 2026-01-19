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

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

final ApiServices apiServices = ApiServices();
final TagihanServices tagihanServices = TagihanServices(apiServices);

class _PaymentScreenState extends State<PaymentScreen> {
  final List<Tagihan> _listTagihan = [];
  bool _isLoading = false;
  User? _user;

  Future<void> _fetchTagihan() async {
    try {
      setState(() {
        _isLoading = true;
        _listTagihan.clear(); // Clear list untuk refresh
      });
      final result = await tagihanServices.getAll();
      setState(() {
        _listTagihan.addAll(result);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('fetch tagihan failed: $e')));
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

    // Check user role first before checking empty state
    if (_user != null && _user!.role == 'admin') {
      return PaymentAdmin(user: _user, listTagihan: _listTagihan);
    }

    // For regular users, show empty state if no tagihan
    if (_listTagihan.isEmpty) {
      return Center(child: Text('Belum ada tagihan baru'));
    }

    return PaymentUser(user: _user, listTagihan: _listTagihan);
  }
}

class PaymentUser extends StatelessWidget {
  const PaymentUser({super.key, User? user, required List<Tagihan> listTagihan})
    : _user = user,
      _listTagihan = listTagihan;

  final User? _user;
  final List<Tagihan> _listTagihan;
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // FIX: Cari tagihan yang belum dibayar untuk ditampilkan
    Tagihan displayTagihan = _listTagihan.last; // Default ke yang terbaru
    
    // Cari tagihan pertama yang belum dibayar
    for (var tagihan in _listTagihan.reversed) {
      if (tagihan.isPaid == false) {
        displayTagihan = tagihan;
        break;
      }
    }
    
    return Container(
      color: ColorList.primary50,
      width: double.infinity,
      height: size.height,
      child: Stack(
        children: [
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  Icon(Icons.account_circle, size: 50, color: Colors.white),
                  Text(
                    textAlign: TextAlign.justify,
                    _user != null ? _user!.name : 'User',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height / 2,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(top: 100, left: 40, right: 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      // FIX: Kirim tagihan yang belum dibayar
                      context.push('/tagihan-pay', extra: displayTagihan);
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color.fromARGB(33, 140, 198, 246),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wallet,
                            size: 42,
                            color: ColorList.primary900,
                          ),
                          Flexible(
                            child: Text(
                              'Pembayaran\nIuran',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_user != null && _user!.role == 'admin')
                    GestureDetector(
                      onTap: () {
                        context.push('/dashboard/laporan-keuangan');
                      },
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Color.fromARGB(33, 76, 175, 80),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              size: 42,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                'Laporan\nKeuangan',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      context.push('/dashboard/payment-processing');
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color.fromARGB(33, 140, 198, 246),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list,
                            size: 42,
                            color: ColorList.primary900,
                          ),
                          Flexible(
                            child: Text(
                              'Tagihan\nIuran',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      context.push('/informasi-pembayaran');
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color.fromARGB(33, 140, 198, 246),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 42,
                            color: ColorList.primary900,
                          ),
                          Flexible(
                            child: Text(
                              'Informasi Pembayaran',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: size.width * 0.08,
            child: Container(
              width: size.width * 0.85,
              height: 192,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(
                      0,
                      0,
                      0,
                      0.5,
                    ),
                    offset: Offset(0, 0),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detail Tagihan Anda',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          displayTagihan.isPaid == true
                              ? 'Sudah Dibayar'
                              : 'Belum Dibayar',
                          style: TextStyle(
                            color:
                                displayTagihan.isPaid == true
                                    ? Colors.green
                                    : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(
                          'Rp.${displayTagihan.totalPrice.toString()}',
                          style: TextStyle(fontSize: 32),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(left: 13, right: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Batas Pembayaran'),
                          Text(
                            DateFormat(
                              'dd MMMM yyyy',
                            ).format(displayTagihan.tagihanDate),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
    final size = MediaQuery.of(context).size;
    return Container(
      color: ColorList.primary50,
      width: double.infinity,
      height: size.height,
      child: Stack(
        children: [
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                children: [
                  Icon(Icons.account_circle, size: 50, color: Colors.white),
                  Text(
                    textAlign: TextAlign.justify,
                    _user != null ? _user!.name : 'User',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height / 2,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(top: 100, left: 40, right: 40),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      context.push('/dashboard/payment-admin-list');
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color.fromARGB(33, 140, 198, 246),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wallet,
                            size: 42,
                            color: ColorList.primary900,
                          ),
                          Flexible(
                            child: Text(
                              'Buat\nTagihan',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push('/dashboard/payment-processing');
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color.fromARGB(33, 140, 198, 246),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.list,
                            size: 42,
                            color: ColorList.primary900,
                          ),
                          Flexible(
                            child: Text(
                              'Konfirmasi\nPembayaran',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.push('/informasi-pembayaran');
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color.fromARGB(33, 140, 198, 246),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 42,
                            color: ColorList.primary900,
                          ),
                          Flexible(
                            child: Text(
                              'Informasi Pembayaran',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: size.width * 0.08,
            child: Container(
              width: size.width * 0.85,
              height: 192,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(
                      0,
                      0,
                      0,
                      0.5,
                    ),
                    offset: Offset(0, 0),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Image.asset('assets/img/rt_logo.png', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}