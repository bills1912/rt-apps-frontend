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
      _filteredLaporan = _allLaporan.where((l) => l.jenisTransaksi == 'pemasukan').toList();
    } else if (_currentTabIndex == 1) {
      _filteredLaporan = _allLaporan.where((l) => l.jenisTransaksi == 'pengeluaran').toList();
    } else {
      _filteredLaporan = _allLaporan;
    }
    setState(() {});
  }

  void _showPeriodPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
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
    final formKey = GlobalKey<FormState>();
    final tanggalController = TextEditingController();
    final kategoriController = TextEditingController();
    final pihakKetigaController = TextEditingController();
    final jumlahController = TextEditingController();
    final keteranganController = TextEditingController();
    String jenisTransaksi = 'pengeluaran';
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Transaksi'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tanggalController,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
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
                          selectedDate = date;
                          tanggalController.text = DateFormat('dd MMMM yyyy').format(date);
                        });
                      }
                    },
                    validator: (value) => value == null || value.isEmpty ? 'Tanggal harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: jenisTransaksi,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Transaksi',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pemasukan', child: Text('Pemasukan')),
                      DropdownMenuItem(value: 'pengeluaran', child: Text('Pengeluaran')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => jenisTransaksi = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: kategoriController,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      hintText: 'Contoh: Sampah, Keamanan, Kebersihan',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Kategori harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: pihakKetigaController,
                    decoration: const InputDecoration(
                      labelText: 'Pihak Ketiga (Opsional)',
                      hintText: 'Contoh: Tukang Sampah, Hansip',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: jumlahController,
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
                    controller: keteranganController,
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
                if (formKey.currentState!.validate()) {
                  try {
                    await laporanService.create(
                      tanggal: selectedDate!,
                      jenisTransaksi: jenisTransaksi,
                      kategori: kategoriController.text,
                      pihakKetiga: pihakKetigaController.text.isNotEmpty ? pihakKetigaController.text : null,
                      jumlah: double.parse(jumlahController.text),
                      keterangan: keteranganController.text.isNotEmpty ? keteranganController.text : null,
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

  void _showPublishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.send, color: ColorList.primary50),
            const SizedBox(width: 12),
            const Text('Publikasikan Laporan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Laporan keuangan periode $_selectedPeriode akan dipublikasikan ke semua warga.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warga hanya dapat melihat laporan ini, tidak dapat mengedit.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _publishLaporan();
            },
            style: ElevatedButton.styleFrom(backgroundColor: ColorList.primary50),
            child: const Text('Publikasikan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _publishLaporan() async {
    try {
      setState(() => _isLoading = true);
      await laporanService.publishToWarga(periode: _selectedPeriode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dipublikasikan ke warga'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal publikasi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          Container(
            padding: const EdgeInsets.all(16),
            color: ColorList.primary50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Periode:', style: TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedPeriode-01')),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSummaryCards(),
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
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(height: 42, child: Center(child: Text('Pemasukan'))),
                        Tab(height: 42, child: Center(child: Text('Pengeluaran'))),
                        Tab(height: 42, child: Center(child: Text('Arus Kas'))),
                      ],
                    ),
                  ),
                  if (_currentTabIndex == 2) _buildChart(),
                  Expanded(
                    child: _filteredLaporan.isEmpty
                        ? const Center(child: Text('Belum ada data'))
                        : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredLaporan.length,
                      itemBuilder: (context, index) => _buildLaporanCard(_filteredLaporan[index]),
                    ),
                  ),
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
    if (_summary == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: ColorList.primary, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saldo Akhir', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  'Rp ${NumberFormat('#,###').format(_summary!.saldo)}',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pemasukan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${NumberFormat('#,###').format(_summary!.pemasukan)}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pengeluaran', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${NumberFormat('#,###').format(_summary!.pengeluaran)}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
          const Text('Pemasukan & Pengeluaran', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt() == 0 ? 'Masuk' : 'Keluar',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _summary!.pemasukan, color: Colors.green, width: 40)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _summary!.pengeluaran, color: Colors.red, width: 40)]),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: isIncome ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(laporan.kategori, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd MMMM yyyy').format(laporan.tanggal), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                if (laporan.pihakKetiga != null) Text('Pihak: ${laporan.pihakKetiga}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text('Rp ${NumberFormat('#,###').format(laporan.jumlah)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isIncome ? Colors.green : Colors.red)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exportPDF,
                  icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
                  label: const Text('Export PDF', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Excel belum tersedia')));
                  },
                  icon: const Icon(Icons.table_chart, size: 20, color: Colors.green),
                  label: const Text('Export Excel', style: TextStyle(color: Colors.green)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green), padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPublishDialog,
              icon: const Icon(Icons.send, size: 20, color: Colors.white),
              label: const Text('Publikasikan ke Warga', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(backgroundColor: ColorList.primary50, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }
}