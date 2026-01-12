import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/core/theme/text_styles.dart';
import 'package:rt_app_apk/models/tagihan_user.dart';
import 'package:rt_app_apk/models/user.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/storage_services.dart';
import 'package:rt_app_apk/services/tagihan_services.dart';

class PaymentTagihanUserScreen extends StatefulWidget {
  @override
  State<PaymentTagihanUserScreen> createState() =>
      _PaymentTagihanUserScreenState();
}

final ApiServices apiServices = ApiServices();
final TagihanServices tagihanServices = TagihanServices(
  apiServices,
);

class _PaymentTagihanUserScreenState
    extends State<PaymentTagihanUserScreen> {
  final List<TagihanUser> _listTagihanUser = [];
  bool _isLoading = false;

  User? _user;

  Future<void> _fetchTagihanUser() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final result =
          await tagihanServices.getAllTagihanUser();
      setState(() {
        _listTagihanUser.addAll(result);
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
    _fetchTagihanUser();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: null,
            ),
            Expanded(
              child:
                  _listTagihanUser.isEmpty
                      ? Center(
                        child: Text(
                          'Belum ada data tagihan',
                        ),
                      )
                      : ListView.builder(
                        itemCount: _listTagihanUser.length,
                        itemBuilder: (context, index) {
                          final tagihan =
                              _listTagihanUser[index];
                          return Container(
                            padding: EdgeInsets.all(8.0),
                            margin: EdgeInsets.only(
                              left: 25.0,
                              right: 25.0,
                              top: 18,
                              bottom: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                    12.0,
                                  ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                'Tagihan Iuran Bulanan',
                                style: TextStyle(
                                  color: Color.fromARGB(
                                    255,
                                    139,
                                    175,
                                    214,
                                  ),
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Text(
                                        'Batas Pembayaran',
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMMM yyyy',
                                        ).format(
                                          tagihan
                                              .tagihan
                                              .tagihanDate,
                                        ),
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,
                                    children: [
                                      Text(
                                        'Total Pembayaran',
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        'Rp. ${tagihan.tagihan.totalPrice}',
                                        style: TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Chip(
                                    label: Text(
                                      tagihan.status
                                          .toUpperCase(),
                                      style:
                                          TextStyles.chip,
                                    ),
                                    backgroundColor:
                                        tagihan.status ==
                                                'processing'
                                            ? const Color.fromARGB(
                                              255,
                                              139,
                                              175,
                                              214,
                                            )
                                            : const Color.fromARGB(
                                              255,
                                              96,
                                              93,
                                              44,
                                            ),
                                  ),
                                  Column(
                                    children: [
                                      if (tagihan.status ==
                                              'processing' &&
                                          _user != null &&
                                          _user!.role ==
                                              'admin')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                            ),
                                          ),
                                          onPressed: () {
                                            context.push(
                                              '/payment-update-admin',
                                              extra:
                                                  tagihan,
                                            );
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .center,
                                            children: [
                                              Icon(
                                                Icons.save,
                                              ),
                                              SizedBox(
                                                width: 8,
                                              ),
                                              Text(
                                                'Update Status',
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (tagihan.status !=
                                              'processing' &&
                                          _user != null &&
                                          _user!.role ==
                                              'user')
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    12,
                                                  ),
                                            ),
                                          ),
                                          onPressed: () {
                                            context.push(
                                              '/payment-update-user',
                                              extra:
                                                  tagihan,
                                            );
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .center,
                                            children: [
                                              Icon(
                                                Icons
                                                    .settings,
                                              ),
                                              SizedBox(
                                                width: 8,
                                              ),
                                              Text(
                                                'Fix Data',
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        );
  }
}
