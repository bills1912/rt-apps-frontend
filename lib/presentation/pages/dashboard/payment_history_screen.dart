import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/text_styles.dart';
import 'package:rt_app_apk/models/tagihan_user.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/tagihan_services.dart';
import 'package:rt_app_apk/utils/mont_filter_bar.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

final ApiServices apiServices = ApiServices();
final TagihanServices tagihanServices = TagihanServices(
  apiServices,
);

class _PaymentHistoryScreenState
    extends State<PaymentHistoryScreen> {
  final List<TagihanUser> _listTagihanUser = [];
  bool _isLoading = false;
  final List<String> months = List.generate(
    12,
    (i) => DateFormat.MMMM().format(DateTime(0, i + 1)),
  );
  late int selectedIndex;

  Future<void> _fetchTagihanUser() async {
    try {
      setState(() {
        _isLoading = true;
        _listTagihanUser.clear();
      });
      final result = await tagihanServices
          .getAllTagihanUserHistory(
            month: months[selectedIndex],
          );
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

  @override
  void initState() {
    super.initState();
    selectedIndex = DateTime.now().month - 1;
    _fetchTagihanUser();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final isSelected = selectedIndex == index;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),
                child: ChoiceChip(
                  label: Text(
                    months[index].substring(0, 3),
                  ),
                  selected: isSelected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) {
                    setState(() => selectedIndex = index);
                    _fetchTagihanUser();
                  },
                  selectedColor: Color.fromARGB(
                    255,
                    255,
                    217,
                    95,
                  ),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Colors.black,
                  ),
                ),
              );
            },
          ),
        ),
        _listTagihanUser.isEmpty
            ? Expanded(
              child: Center(
                child: Text('Belum ada data history'),
              ),
            )
            : Expanded(
              child: ListView.builder(
                itemCount: _listTagihanUser.length,
                itemBuilder: (context, index) {
                  final tagihan = _listTagihanUser[index];
                  return Container(
                    // padding: EdgeInsets.all(8.0),
                    // margin: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      // borderRadius: BorderRadius.circular(12.0),
                      // boxShadow: [
                      //   BoxShadow(
                      //     color: Colors.black12,
                      //     blurRadius: 8,
                      //     offset: Offset(0, 4),
                      //   ),
                      // ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(
                          8,
                        ), // adjust size
                        decoration: BoxDecoration(
                          color:
                              Colors
                                  .grey
                                  .shade300, // background color
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history,
                          color:
                              Colors.black87, // icon color
                          size: 24, // icon size
                        ),
                      ),
                      title: Text('Iuran Bulanan'),
                      subtitle: Text(
                        DateFormat(
                          'dd MMMM yyyy',
                        ).format(tagihan.paidAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      trailing: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 10),
                          Text(
                            'Rp. ${tagihan.tagihan.totalPrice}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Berhasil',
                            style: TextStyle(
                              color: Colors.green.shade400,
                            ),
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
