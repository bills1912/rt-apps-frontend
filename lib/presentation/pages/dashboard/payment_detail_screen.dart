import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/text_styles.dart';
import 'package:rt_app_apk/models/tagihan_user.dart';

class PaymentDetailScreen extends StatelessWidget {
  final TagihanUser tagihanUser;
  PaymentDetailScreen({super.key, required this.tagihanUser});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo('ID Tagihan', tagihanUser.tagihan.id.toString()),
            _buildInfo(
              'Batas Pembayaran',
              DateFormat('dd MMM yyyy').format(tagihanUser.tagihan.tagihanDate),
            ),
            _buildInfo(
              'Total Pembayaran',
              'Rp.${tagihanUser.tagihan.totalPrice}',
            ),
            ListView.builder(
              shrinkWrap: true,
              physics:
                  NeverScrollableScrollPhysics(), // prevent nested scrolling
              itemCount: tagihanUser.tagihan.items.length,
              itemBuilder: (context, index) {
                final item = tagihanUser.tagihan.items[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: TextStyles.h2),
                        Text(item.description, style: TextStyles.p),
                      ],
                    ),
                    Text('Rp. ${item.price}', style: TextStyles.h3),
                  ],
                );
              },
            ),
            Chip(
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    tagihanUser.status.toUpperCase(),
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: const Color.fromARGB(255, 68, 130, 60),
            ),
            const Divider(height: 4, thickness: 2, color: Colors.grey),
            SizedBox(height: 12),
            if (tagihanUser.adminReply.isNotEmpty)
              Column(
                children: [
                  _buildInfo(
                    'Admin Reply',
                    tagihanUser.adminReply.last.description,
                  ),
                  _buildInfo(
                    'Date',
                    DateFormat(
                      'dd MMM yyyy',
                    ).format(tagihanUser.adminReply.last.date),
                  ),
                ],
              ),
            SizedBox(height: 16),
            const Divider(height: 4, thickness: 2, color: Colors.grey),
            SizedBox(height: 12),
            _buildInfo('User Data', ''),
            _buildInfo('User Note', tagihanUser.userInfo.last.description),
            _buildInfo(
              'Date',
              DateFormat('dd MMM yyyy').format(tagihanUser.userInfo.last.date),
            ),
            _buildInfo('Transfer Proof', ''),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tagihanUser.userInfo.last.transferProof.length,
              itemBuilder: (context, index) {
                final image = tagihanUser.userInfo.last.transferProof[index];
                try {
                  return Image.network(image, fit: BoxFit.cover);
                } catch (e) {
                  return const Text('Invalid image');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildInfo(String label, String? value, {TextStyle? style}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text.rich(
      TextSpan(
        text: '$label: ',
        style: const TextStyle(fontWeight: FontWeight.bold),
        children: [
          TextSpan(
            text: value ?? '-',
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    ),
  );
}
