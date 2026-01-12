import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/core/theme/text_styleS.dart';
import 'package:rt_app_apk/models/tagihan.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rt_app_apk/models/user.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/storage_services.dart';
import 'package:rt_app_apk/services/tagihan_services.dart';

class PaymentPayScreen extends StatefulWidget {
  final Tagihan tagihan;
  const PaymentPayScreen({super.key, required this.tagihan});
  @override
  State<PaymentPayScreen> createState() => _PaymentPayState();
}

final ApiServices apiServices = ApiServices();
final TagihanServices tagihanServices = TagihanServices(apiServices);

class _PaymentPayState extends State<PaymentPayScreen> {
  User? _user;
  final ImagePicker _picker = ImagePicker();
  List<File> _listImages = [];
  List<String> _listBase64 = [];
  final _noteController = TextEditingController();
  bool _isLoading = false;
  bool _noteValidation = false;
  bool _imageValidation = false;

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked != null) {
        setState(() {
          _listImages.add(File(picked.path));
        });
      }
    } catch (e) {
      print('Pick img error $e');
    }
  }

  Future<void> _submit() async {
    _listBase64.clear();
    if (_noteController.text.isEmpty) {
      setState(() {
        _noteValidation = true;
      });
    }
    if (_listImages.isEmpty) {
      setState(() {
        _imageValidation = true;
      });
      return;
    }
    setState(() {
      _imageValidation = false;
      _noteValidation = false;
    });
    for (File file in _listImages) {
      final bytes = await file.readAsBytes();
      _listBase64.add(base64Encode(bytes));
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await tagihanServices.payTicket(
        _listBase64,
        widget.tagihan.id,
        _noteController.text,
      );
      if (response == true) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Success pay tagihan')));
          context.go('/success-modal');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 32), // optional padding
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: ColorList.primary, // blue background
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(0),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        title: Text(
          'Pembayaran Iuran',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ColorList.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo('ID Tagihan', widget.tagihan.id.toString()),
            _buildInfo(
              'Batas Pembayaran',
              DateFormat('dd MMMM yyyy').format(widget.tagihan.tagihanDate),
            ),
            _buildInfo('Total Pembayaran', 'Rp.${widget.tagihan.totalPrice}'),
            const Divider(height: 4, thickness: 2, color: Colors.grey),
            SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics:
                  NeverScrollableScrollPhysics(), // prevent nested scrolling
              itemCount: widget.tagihan.items.length,
              itemBuilder: (context, index) {
                final item = widget.tagihan.items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey, // Border color
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: ColorList.primary100,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Pembayaran'),
                              Text('Rp. ${item.price}'),
                            ],
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.8, // 50% of the parent width
                            child: Text(item.description),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),

            if (_user != null && _user!.role == 'user')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nominal Pembayaran'),
                  SizedBox(height: 12),
                  TextFormField(
                    enabled: false,
                    initialValue: 'Rp. ${widget.tagihan.totalPrice}',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Catatan'),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_noteValidation == true)
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Please fill the note',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  _listImages.isEmpty
                      ? Text('No images selected.')
                      : GridView.builder(
                        itemCount: _listImages.length,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: Image.file(
                                  _listImages[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _listImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  SizedBox(height: 12),
                  if (_imageValidation == true)
                    Column(
                      children: [
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Please upload transfer proof',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pickImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Upload Transfer Proof',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar:
          _user != null && _user!.role == 'user'
              ? Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          label:
                              _isLoading
                                  ? CircularProgressIndicator()
                                  : Text(
                                    'Submit',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorList.primary50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }
}

Widget _buildInfo(String label, String? value, {TextStyle? style}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text(value ?? '-')],
    ),
  );
}
