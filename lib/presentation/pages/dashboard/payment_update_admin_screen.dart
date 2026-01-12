import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/core/theme/text_styles.dart';
import 'package:rt_app_apk/models/tagihan_user.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/tagihan_services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PaymentUpdateAdminScreen extends StatefulWidget {
  final TagihanUser tagihanUser;
  const PaymentUpdateAdminScreen({super.key, required this.tagihanUser});
  @override
  State<PaymentUpdateAdminScreen> createState() =>
      _PaymentUpdateAdminScreenState();
}

final ApiServices apiServices = ApiServices();
final TagihanServices tagihanServices = TagihanServices(apiServices);

class _PaymentUpdateAdminScreenState extends State<PaymentUpdateAdminScreen> {
  final ImagePicker _picker = ImagePicker();
  List<File> _listImages = [];
  List<String> _listBase64 = [];
  final _noteController = TextEditingController();
  String? _selectedStatus;
  bool _isLoading = false;
  bool _noteValidation = false;
  bool _imageValidation = false;
  bool _statusValidation = false;

  Future<XFile?> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = path.join(
      dir.absolute.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // Adjust quality (0-100), lower = more compression
    );

    return result;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked != null) {
        final XFile? compressed = await _compressImage(File(picked.path));
        if (compressed != null) {
          setState(() {
            _listImages.add(File(compressed.path));
          });
        }
      }
    } catch (e) {
      print('Pick img error $e');
    }
  }

  Future<void> _submit() async {
    _listBase64.clear();
    if (_selectedStatus == null) {
      setState(() {
        _statusValidation = true;
      });
      return;
    }
    if (_selectedStatus == 'need_to_fix' && _noteController.text.isEmpty) {
      setState(() {
        _noteValidation = true;
      });
    }

    try {
      setState(() {
        _isLoading = true;
      });
      final response = await tagihanServices.updateTagihanUser(
        widget.tagihanUser.id,
        _selectedStatus!,
        description:
            _noteController.value.text.isNotEmpty ? _noteController.text : null,
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
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(widget.tagihanUser.userInfo.last.description),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Bukti Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.tagihanUser.userInfo.last.transferProof.length,
              itemBuilder: (context, index) {
                final image =
                    widget.tagihanUser.userInfo.last.transferProof[index];
                try {
                  final imageUrl = image.toString().trim().replaceAll('"', '');
                  return Container(
                    width: double.infinity,
                    height: 200, // increase height
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                Icon(Icons.error, size: 48),
                      ),
                    ),
                  );
                } catch (e) {
                  print('Type of image: ${image.runtimeType}');
                  print(e.toString());
                  return Text(e.toString());
                }
              },
            ),
            SizedBox(height: 16),

            RadioListTile<String>(
              value: 'verified',
              groupValue: _selectedStatus,
              title: const Text('Verified'),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  _listImages = [];
                  _noteController.clear();
                });
              },
            ),
            RadioListTile<String>(
              value: 'need_to_fix',
              groupValue: _selectedStatus,
              title: const Text('Need to Fix'),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                  _listImages = [];
                  _noteController.clear();
                });
              },
            ),
            const SizedBox(height: 12),
            if (_statusValidation == true)
              Column(
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Please select status',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            if (_selectedStatus != null && _selectedStatus == 'need_to_fix')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
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
