import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/models/laporan_keuangan.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/laporan_keuangan_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';

class LaporanKeuanganScreen extends StatefulWidget {
  const LaporanKeuanganScreen({Key? key}) : super(key: key);

  @override
  State<LaporanKeuanganScreen> createState() => _LaporanKeuanganScreenState();
}

final ApiServices apiServices = ApiServices();
final LaporanKeuanganService laporanService = LaporanKeuanganService(apiServices);

class _LaporanKeuanganScreenState extends State<LaporanKeuanganScreen> with SingleTickerProviderStateMixin {
  List<LaporanKeuangan> _allLaporan = [];
  List<LaporanKeuangan> _filteredLaporan = [];
  LaporanSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPeriode = DateFormat('yyyy-MM').format(DateTime.now());

  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
      _filterData();
    });
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await laporanService.getAll(periode: _selectedPeriode);
      final summaries = await laporanService.getSummary(periode: _selectedPeriode);

      setState(() {
        _allLaporan = data;
        _summary = summaries.isNotEmpty ? summaries.first : null;
      });

      _filterData();
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

  void _filterData() {
    if (_currentTabIndex == 0) {
      // Pemasukan
      _filteredLaporan = _allLaporan.where((l) => l.jenisTransaksi == 'pemasukan').toList();
    } else if (_currentTabIndex == 1) {
      // Pengeluaran
      _filteredLaporan = _allLaporan.where((l) => l.jenisTransaksi == 'pengeluaran').toList();
    } else {
      // Arus Kas - semua
      _filteredLaporan = _allLaporan;
    }
    setState(() {});
  }

  void _showPeriodPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedPeriode = DateFormat('yyyy-MM').format(picked);
      });
      _fetchData();
    }
  }

  Future<void> _exportPDF() async {
    try {
      setState(() => _isLoading = true);

      final response = await apiServices.dio.get(
        '/laporan-keuangan/export-pdf',
        queryParameters: {'periode': _selectedPeriode},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/laporan-keuangan-$_selectedPeriode.pdf');
      await file.writeAsBytes(response.data as List<int>);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF berhasil diunduh')),
      );

      await OpenFile.open(file.path);

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddDialog() {
    final _formKey = GlobalKey<FormState>();
    final _tanggalController = TextEditingController();
    final _kategoriController = TextEditingController();
    final _pihakKetigaController = TextEditingController();
    final _jumlahController = TextEditingController();
    final _keteranganController = TextEditingController();
    String _jenisTransaksi = 'pengeluaran';
    DateTime? _selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Pengeluaran'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          _tanggalController.text = DateFormat('dd MMMM yyyy').format(date);
                        });
                      }
                    },
                    validator: (value) => value == null || value.isEmpty ? 'Tanggal harus diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _jenisTransaksi,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Transaksi',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pemasukan', child: Text('Pemasukan')),
                      DropdownMenuItem(value: 'pengeluaran', child: Text('Pengeluaran')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => _jenisTransaksi = value!);
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _kategoriController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'Contoh: Sampah, Keamanan, Kebersihan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Kategori harus diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _pihakKetigaController,
                    decoration: const InputDecoration(
                      labelText: 'Pihak Ketiga (Opsional)',
                      hintText: 'Contoh: Tukang Sampah, Hansip',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _jumlahController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Rp)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Jumlah harus diisi';
                      if (double.tryParse(value) == null) return 'Jumlah harus berupa angka';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

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
                      pihakKetiga: _pihakKetigaController.text.isNotEmpty ? _pihakKetigaController.text : null,
                      jumlah: double.parse(_jumlahController.text),
                      keterangan: _keteranganController.text.isNotEmpty ? _keteranganController.text : null,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Laporan berhasil dibuat')),
                    );
                    _fetchData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: ColorList.primary),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _allLaporan.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: ColorList.primary50,
      appBar: AppBar(
        title: const Text('Laporan Keuangan', style: TextStyle(color: Colors.white)),
        backgroundColor: ColorList.primary50,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            onPressed: _showPeriodPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dengan periode
          Container(
            padding: const EdgeInsets.all(16),
            color: ColorList.primary50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Periode:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedPeriode-01')),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content area dengan background putih
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Summary Cards
                  _buildSummaryCards(),

                  // Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: ColorList.primary50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.black87,
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      tabs: const [
                        Tab(
                          height: 42,
                          child: Center(child: Text('Pemasukan')),
                        ),
                        Tab(
                          height: 42,
                          child: Center(child: Text('Pengeluaran')),
                        ),
                        Tab(
                          height: 42,
                          child: Center(child: Text('Arus Kas')),
                        ),
                      ],
                    ),
                  ),

                  // Chart (hanya tampil di tab Arus Kas)
                  if (_currentTabIndex == 2) _buildChart(),

                  // List
                  Expanded(
                    child: _filteredLaporan.isEmpty
                        ? const Center(child: Text('Belum ada data'))
                        : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredLaporan.length,
                      itemBuilder: (context, index) {
                        final laporan = _filteredLaporan[index];
                        return _buildLaporanCard(laporan);
                      },
                    ),
                  ),

                  // Bottom buttons
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: ColorList.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summary == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Saldo Akhir (Biru)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ColorList.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Akhir',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${NumberFormat('#,###').format(_summary!.saldo)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Pemasukan & Pengeluaran
          Row(
            children: [
              // Pemasukan (Hijau)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pemasukan',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${NumberFormat('#,###').format(_summary!.pemasukan)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Pengeluaran (Merah)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pengeluaran',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${NumberFormat('#,###').format(_summary!.pengeluaran)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_summary == null) return const SizedBox();

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pemasukan & Pengeluaran',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: [_summary!.pemasukan, _summary!.pengeluaran].reduce((a, b) => a > b ? a : b) * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Masuk', style: TextStyle(fontSize: 10));
                          case 1:
                            return const Text('Keluar', style: TextStyle(fontSize: 10));
                          default:
                            return const Text('');
                        }
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: _summary!.pemasukan,
                        color: Colors.green,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: _summary!.pengeluaran,
                        color: Colors.red,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanCard(LaporanKeuangan laporan) {
    final isIncome = laporan.jenisTransaksi == 'pemasukan';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.red,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      laporan.kategori,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Status Lunas
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle, size: 12, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Lunas',
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy').format(laporan.tanggal),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (laporan.pihakKetiga != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Pihak: ${laporan.pihakKetiga}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
                if (laporan.keterangan != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    laporan.keterangan!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Amount
          Text(
            'Rp ${NumberFormat('#,###').format(laporan.jumlah)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Export PDF
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _exportPDF,
              icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.white),
              label: const Text('Export ke PDF', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Export Excel
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement Excel export
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur Excel belum tersedia')),
                );
              },
              icon: const Icon(Icons.table_chart, size: 20, color: Colors.white),
              label: const Text('Export ke Excel', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}