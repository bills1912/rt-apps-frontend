import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/models/laporan_keuangan.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/laporan_keuangan_service.dart';

class LaporanKeuanganScreen extends StatefulWidget {
  const LaporanKeuanganScreen({Key? key}) : super(key: key);

  @override
  State<LaporanKeuanganScreen> createState() => _LaporanKeuanganScreenState();
}

final ApiServices apiServices = ApiServices();
final LaporanKeuanganService laporanService = LaporanKeuanganService(apiServices);

class _LaporanKeuanganScreenState extends State<LaporanKeuanganScreen> {
  List<LaporanKeuangan> _laporanList = [];
  List<LaporanSummary> _summaryList = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedPeriode;

  final _formKey = GlobalKey<FormState>();
  final _tanggalController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _pihakKetigaController = TextEditingController();
  final _jumlahController = TextEditingController();
  final _keteranganController = TextEditingController();
  String _jenisTransaksi = 'pengeluaran';

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchSummary();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await laporanService.getAll(periode: _selectedPeriode);
      setState(() {
        _laporanList = data;
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

  Future<void> _fetchSummary() async {
    try {
      final summary = await laporanService.getSummary(periode: _selectedPeriode);
      setState(() {
        _summaryList = summary;
      });
    } catch (e) {
      print('Error fetching summary: $e');
    }
  }

  void _showCreateDialog() {
    _tanggalController.clear();
    _kategoriController.clear();
    _pihakKetigaController.clear();
    _jumlahController.clear();
    _keteranganController.clear();
    _selectedDate = DateTime.now();
    _jenisTransaksi = 'pengeluaran';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buat Laporan Keuangan'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tanggal
                  TextFormField(
                    controller: _tanggalController,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setDialogState(() {
                          _selectedDate = date;
                          _tanggalController.text =
                              DateFormat('dd MMMM yyyy').format(date);
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tanggal harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Jenis Transaksi
                  DropdownButtonFormField<String>(
                    value: _jenisTransaksi,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Transaksi',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pemasukan',
                        child: Text('Pemasukan'),
                      ),
                      DropdownMenuItem(
                        value: 'pengeluaran',
                        child: Text('Pengeluaran'),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _jenisTransaksi = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Kategori
                  TextFormField(
                    controller: _kategoriController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'Contoh: Sampah, Keamanan, Kebersihan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kategori harus diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pihak Ketiga
                  TextFormField(
                    controller: _pihakKetigaController,
                    decoration: const InputDecoration(
                      labelText: 'Pihak Ketiga (Opsional)',
                      hintText: 'Contoh: Tukang Sampah, Hansip',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Jumlah
                  TextFormField(
                    controller: _jumlahController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Rp)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Jumlah harus diisi';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Jumlah harus berupa angka';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Keterangan
                  TextFormField(
                    controller: _keteranganController,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await laporanService.create(
                      tanggal: _selectedDate!,
                      jenisTransaksi: _jenisTransaksi,
                      kategori: _kategoriController.text,
                      pihakKetiga: _pihakKetigaController.text.isNotEmpty
                          ? _pihakKetigaController.text
                          : null,
                      jumlah: double.parse(_jumlahController.text),
                      keterangan: _keteranganController.text.isNotEmpty
                          ? _keteranganController.text
                          : null,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Laporan berhasil dibuat'),
                      ),
                    );
                    _fetchData();
                    _fetchSummary();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorList.primary,
              ),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: ColorList.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Summary Card
          if (_summaryList.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ringkasan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_summaryList.map((summary) => Column(
                    children: [
                      _buildSummaryRow(
                        'Pemasukan',
                        summary.pemasukan,
                        Colors.green,
                      ),
                      _buildSummaryRow(
                        'Pengeluaran',
                        summary.pengeluaran,
                        Colors.red,
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Saldo',
                        summary.saldo,
                        summary.saldo >= 0 ? Colors.blue : Colors.red,
                      ),
                    ],
                  ))),
                ],
              ),
            ),

          // List Laporan
          Expanded(
            child: _laporanList.isEmpty
                ? const Center(child: Text('Belum ada laporan'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _laporanList.length,
              itemBuilder: (context, index) {
                final laporan = _laporanList[index];
                final isIncome = laporan.jenisTransaksi == 'pemasukan';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        isIncome
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: isIncome
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                    title: Text(
                      laporan.kategori,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy')
                              .format(laporan.tanggal),
                        ),
                        if (laporan.pihakKetiga != null)
                          Text('Pihak: ${laporan.pihakKetiga}'),
                        if (laporan.keterangan != null)
                          Text(
                            laporan.keterangan!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: Text(
                      'Rp ${NumberFormat('#,###').format(laporan.jumlah)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            'Rp ${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _kategoriController.dispose();
    _pihakKetigaController.dispose();
    _jumlahController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }
}