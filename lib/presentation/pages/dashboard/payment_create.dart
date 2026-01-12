import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/core/theme/text_styles.dart';
import 'package:rt_app_apk/models/payment_add_item_args.dart';
import 'package:rt_app_apk/models/tagihan_item.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/tagihan_services.dart';

class PaymentCreate extends StatefulWidget {
  @override
  State<PaymentCreate> createState() =>
      _PaymentCreateState();
}

ApiServices apiServices = ApiServices();
TagihanServices tagihanServices = TagihanServices(
  apiServices,
);

class _PaymentCreateState extends State<PaymentCreate> {
  DateTime? _tagihanDate;
  final _datetimeController = TextEditingController();
  final _tagihanNameController = TextEditingController();
  final _tagihanDescriptionController =
      TextEditingController();
  final _totalPembayaranController =
      TextEditingController();

  List<TagihanItem> _listItem = [];
  bool _isLoading = false;
  bool _dateValidation = false;
  bool _itemValidation = false;

  Future<void> _addItem() async {
    try {
      final List<TagihanItem>? item = await context
          .push<List<TagihanItem>>(
            '/tagihan-add-item',
            extra: PaymentAddItemArgs(
              tagihanItems: _listItem,
              tagihanName:
                  _tagihanNameController
                      .text, // Example name
            ),
          );
      if (item != null) {
        int counter = 0;
        for (var d in item) {
          counter += d.price;
        }
        setState(() {
          _listItem.clear();
          _listItem.addAll(item);
          _totalPembayaranController.text = '$counter';
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add item error: $e')),
      );
    }
  }

  Future<void> _showDatepicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2025, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _tagihanDate = picked;
        _datetimeController.text = DateFormat(
          'dd MMM yyyy',
        ).format(picked);
        _datetimeController.value = TextEditingValue(
          text: picked.toIso8601String(),
        );
      });
    }
  }

  Future<void> _submit() async {
    if (_tagihanDate == null) {
      setState(() {
        _dateValidation = true;
      });
      return;
    }

    if (_tagihanNameController.text.isEmpty ||
        _tagihanDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nama and Deskripsi tagihan required',
          ),
        ),
      );
      return;
    }

    if (_listItem.isEmpty) {
      setState(() {
        _itemValidation = true;
      });
    }

    setState(() {
      _dateValidation = false;
      _itemValidation = false;
    });

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await tagihanServices.create(
        _listItem,
        _tagihanDate!,
        _tagihanNameController.text,
        _tagihanDescriptionController.text,
      );
      if (response) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Create tagihan success '),
            ),
          );
          context.go('/success-modal');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create tagihan error $e')),
      );
    } finally {
      if (mounted) {
        _isLoading = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _totalPembayaranController.text = '0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Buat Tagihan')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Tagihan'),
            SizedBox(height: 12),
            TextFormField(
              controller: _tagihanNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text('Deskripsi Tagihan'),
            SizedBox(height: 12),
            TextFormField(
              controller: _tagihanDescriptionController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text('Batas Pembayaran'),
            SizedBox(height: 12),
            GestureDetector(
              onTap: _showDatepicker,
              child: TextFormField(
                controller: _datetimeController,
                enabled: false,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Calendar is required';
                  }
                  return null;
                },
              ),
            ),
            if (_dateValidation == true)
              Text(
                'Please pick a date!',
                style: TextStyle(color: Colors.red),
              ),

            SizedBox(height: 12),
            Text('Total Pembayaran'),
            SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              controller: _totalPembayaranController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _addItem,
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Buat Rincian Tagihan',
                      style: TextStyle(color: Colors.blue),
                    ),
                    Icon(
                      Icons.chevron_right_outlined,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),
            if (_itemValidation == true)
              Text(
                'Please add item!',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
      bottomNavigationBar:
          _listItem.isEmpty
              ? null
              : Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    label:
                        _isLoading
                            ? CircularProgressIndicator()
                            : Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                    icon: Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.blue, // Remove background
                      elevation: 0, // Text color (optional)
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
