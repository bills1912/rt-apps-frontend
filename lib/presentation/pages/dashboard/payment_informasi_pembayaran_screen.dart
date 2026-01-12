import 'package:flutter/material.dart';

class PaymentInformasiPembayaranScreen
    extends StatefulWidget {
  @override
  State<PaymentInformasiPembayaranScreen> createState() =>
      _PaymentInformasiPembayaranScreenState();
}

class _PaymentInformasiPembayaranScreenState
    extends State<PaymentInformasiPembayaranScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Informasi Pembayaran')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ), // Gray border
                borderRadius: BorderRadius.circular(
                  8,
                ), // Optional: rounded corners
              ),
              padding: EdgeInsets.all(
                12,
              ), // Optional: inner padding
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/img/bank_logo.png',
                      fit: BoxFit.cover,
                    ),
                    Divider(),
                    Text('a/n Zahra Meysa Putri'),
                    Text(
                      '732035245612379',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Cara Pembayaran',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                ), // Gray border
                borderRadius: BorderRadius.circular(
                  8,
                ), // Optional: rounded corners
              ),
              padding: EdgeInsets.all(
                12,
              ), // Optional: inner padding
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Silahkan transfer ke rekening di atas melalui transfer bank.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
