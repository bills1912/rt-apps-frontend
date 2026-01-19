import 'package:flutter/material.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/models/data_warga.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/data_warga_service.dart';

class DataWargaScreen extends StatefulWidget {
  const DataWargaScreen({Key? key}) : super(key: key);

  @override
  State<DataWargaScreen> createState() => _DataWargaScreenState();
}

final ApiServices apiServices = ApiServices();
final DataWargaService dataWargaService = DataWargaService(apiServices);

class _DataWargaScreenState extends State<DataWargaScreen> {
  List<DataWarga> _wargaList = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await dataWargaService.getAllWarga();
      setState(() {
        _wargaList = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncData() async {
    try {
      await dataWargaService.syncWargaData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil disinkronisasi')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal sinkronisasi: $e')),
      );
    }
  }

  Future<void> _togglePaymentStatus(
      DataWarga warga,
      String month,
      bool currentStatus,
      ) async {
    try {
      await dataWargaService.updatePaymentStatus(
        warga.id,
        month,
        !currentStatus,
      );
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status pembayaran diperbarui')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Warga')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Warga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncData,
            tooltip: 'Sinkronisasi Data',
          ),
        ],
      ),
      body: _wargaList.isEmpty
          ? const Center(
        child: Text('Tidak ada data warga'),
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: MaterialStateProperty.all(
                ColorList.primary50.withOpacity(0.1),
              ),
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              columns: [
                const DataColumn(
                  label: Text(
                    'No',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Nama',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'Alamat',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ..._months.map(
                      (month) => DataColumn(
                    label: Text(
                      month.substring(0, 3),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              rows: _wargaList.asMap().entries.map((entry) {
                final index = entry.key;
                final warga = entry.value;

                return DataRow(
                  cells: [
                    DataCell(Text('${index + 1}')),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          warga.nama,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          warga.alamat,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    ..._months.map((month) {
                      final isPaid = warga.paymentStatus[month] ?? false;
                      return DataCell(
                        InkWell(
                          onTap: () => _togglePaymentStatus(
                            warga,
                            month,
                            isPaid,
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? Colors.green.shade100
                                  : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              isPaid ? Icons.check : Icons.close,
                              color: isPaid
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}