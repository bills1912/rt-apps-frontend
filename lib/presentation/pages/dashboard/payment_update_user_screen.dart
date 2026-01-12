import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/text_styles.dart';
import 'package:rt_app_apk/models/tagihan_user.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/tagihan_services.dart';

class PaymentUpdateUserScreen extends StatefulWidget {
  final TagihanUser tagihanUser;
  const PaymentUpdateUserScreen({super.key, required this.tagihanUser});
  @override
  State<PaymentUpdateUserScreen> createState() =>
      _PaymentUpdateAdminScreenState();
}

final ApiServices apiServices = ApiServices();
final TagihanServices tagihanServices = TagihanServices(apiServices);

class _PaymentUpdateAdminScreenState extends State<PaymentUpdateUserScreen> {
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
      final response = await tagihanServices.updateTagihanUserByUser(
        widget.tagihanUser.id,
        _listBase64,
        _noteController.text,
      );
      if (response == true) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Success update tagihan')));
          context.go('/success-modal');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo('ID Tagihan', widget.tagihanUser.tagihan.id.toString()),
            _buildInfo(
              'Batas Pembayaran',
              DateFormat(
                'dd MMM yyyy',
              ).format(widget.tagihanUser.tagihan.tagihanDate),
            ),
            _buildInfo(
              'Total Pembayaran',
              'Rp.${widget.tagihanUser.tagihan.totalPrice}',
            ),
            SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Admin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(widget.tagihanUser.adminReply.last.description),
              ],
            ),

            SizedBox(height: 16),
            const Divider(height: 4, thickness: 2, color: Colors.grey),
            SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Text('Catatan Anda'),
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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submit,
            label: _isLoading ? CircularProgressIndicator() : Text('Submit'),
            icon: Icon(Icons.send),
          ),
        ),
      ),
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
