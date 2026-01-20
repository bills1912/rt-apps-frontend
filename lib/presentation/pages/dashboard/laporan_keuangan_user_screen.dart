import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/models/laporan_keuangan.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/laporan_keuangan_service.dart';
import 'package:fl_chart/fl_chart.dart';

class LaporanKeuanganUserScreen extends StatefulWidget {
  const LaporanKeuanganUserScreen({Key? key}) : super(key: key);

  @override
  State<LaporanKeuanganUserScreen> createState() => _LaporanKeuanganUserScreenState();
}

final ApiServices apiServices = ApiServices();
final LaporanKeuanganService laporanService = LaporanKeuanganService(apiServices);

class _LaporanKeuanganUserScreenState extends State<LaporanKeuanganUserScreen>
    with SingleTickerProviderStateMixin {
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
      // User hanya bisa lihat laporan yang sudah dipublikasi
      final data = await laporanService.getPublishedReports(periode: _selectedPeriode);
      final summaries = await laporanService.getPublishedSummary(periode: _selectedPeriode);

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _allLaporan.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: ColorList.primary50,
      appBar: AppBar(
        title: const Text('Laporan Keuangan RT', style: TextStyle(color: Colors.white)),
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

          // Content area
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

                  // Info Banner (Read-only)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Laporan ini telah dipublikasikan oleh Admin RT',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(height: 42, child: Center(child: Text('Pemasukan'))),
                        Tab(height: 42, child: Center(child: Text('Pengeluaran'))),
                        Tab(height: 42, child: Center(child: Text('Arus Kas'))),
                      ],
                    ),
                  ),

                  // Chart (hanya tampil di tab Arus Kas)
                  if (_currentTabIndex == 2) _buildChart(),

                  // List
                  Expanded(
                    child: _filteredLaporan.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada laporan dipublikasi\nuntuk periode ini',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredLaporan.length,
                      itemBuilder: (context, index) {
                        final laporan = _filteredLaporan[index];
                        return _buildLaporanCard(laporan);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summary == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Belum ada data untuk periode ini',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Saldo Akhir
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
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt() == 0 ? 'Masuk' : 'Keluar',
                          style: const TextStyle(fontSize: 10),
                        );
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
                    barRods: [BarChartRodData(toY: _summary!.pemasukan, color: Colors.green, width: 40)],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [BarChartRodData(toY: _summary!.pengeluaran, color: Colors.red, width: 40)],
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(laporan.kategori, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy').format(laporan.tanggal),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (laporan.pihakKetiga != null)
                  Text('Pihak: ${laporan.pihakKetiga}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            'Rp ${NumberFormat('#,###').format(laporan.jumlah)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isIncome ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }
}