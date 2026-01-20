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

// Model for published period
class PublishedPeriod {
  final int id;
  final String periode;
  final String displayName;
  final DateTime publishedAt;
  final String publishedBy;

  PublishedPeriod({
    required this.id,
    required this.periode,
    required this.displayName,
    required this.publishedAt,
    required this.publishedBy,
  });

  factory PublishedPeriod.fromJson(Map<String, dynamic> json) {
    return PublishedPeriod(
      id: json['id'],
      periode: json['periode'],
      displayName: json['displayName'],
      publishedAt: DateTime.parse(json['publishedAt']),
      publishedBy: json['publishedBy'],
    );
  }
}

class LaporanKeuanganUserScreen extends StatefulWidget {
  const LaporanKeuanganUserScreen({Key? key}) : super(key: key);

  @override
  State<LaporanKeuanganUserScreen> createState() => _LaporanKeuanganUserScreenState();
}

final ApiServices apiServices = ApiServices();
final LaporanKeuanganService laporanService = LaporanKeuanganService(apiServices);

class _LaporanKeuanganUserScreenState extends State<LaporanKeuanganUserScreen> {
  List<PublishedPeriod> _publishedPeriods = [];
  PublishedPeriod? _selectedPeriod;

  List<LaporanKeuangan> _allLaporan = [];
  List<LaporanKeuangan> _filteredLaporan = [];
  LaporanSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPublishedPeriods();
  }

  // Fetch list of published periods
  Future<void> _fetchPublishedPeriods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await apiServices.dio.get('/laporan-keuangan/published/periods');
      final body = response.data;

      if (body['error'] != null) {
        throw Exception(body['error']);
      }

      final List<dynamic> periodsData = body['data'];
      final periods = periodsData.map((p) => PublishedPeriod.fromJson(p)).toList();

      setState(() {
        _publishedPeriods = periods;
        if (periods.isNotEmpty) {
          _selectedPeriod = periods.first;
        }
      });

      // If there's a selected period, fetch its data
      if (_selectedPeriod != null) {
        await _fetchLaporanForPeriod(_selectedPeriod!.periode);
      }
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

  // Fetch laporan for specific period
  Future<void> _fetchLaporanForPeriod(String periode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await laporanService.getPublishedReports(periode: periode);
      final summaries = await laporanService.getPublishedSummary(periode: periode);

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

  // Fungsi Export PDF
  Future<void> _exportPDF() async {
    if (_selectedPeriod == null) return;

    try {
      setState(() => _isLoading = true);

      // Menggunakan endpoint export-pdf dengan parameter periode
      final response = await apiServices.dio.get(
        '/laporan-keuangan/export-pdf',
        queryParameters: {'periode': _selectedPeriod!.periode},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/laporan-keuangan-${_selectedPeriod!.periode}.pdf');
      await file.writeAsBytes(response.data as List<int>);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF berhasil diunduh'), backgroundColor: Colors.green),
      );

      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal export PDF: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _publishedPeriods.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _publishedPeriods.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Keuangan RT', style: TextStyle(color: Colors.white)),
          backgroundColor: ColorList.primary50,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Tidak ada laporan yang dipublikasikan',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchPublishedPeriods,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorList.primary50,
                ),
                child: const Text('Muat Ulang', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ColorList.primary50,
      appBar: AppBar(
        title: const Text('Laporan Keuangan RT', style: TextStyle(color: Colors.white)),
        backgroundColor: ColorList.primary50,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: ColorList.primary50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Periode:',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PublishedPeriod>(
                      value: _selectedPeriod,
                      isExpanded: true,
                      items: _publishedPeriods.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(period.displayName),
                              Text(
                                DateFormat('dd MMM yyyy').format(period.publishedAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPeriod = value;
                            _currentTabIndex = 0; // Reset tab
                          });
                          _fetchLaporanForPeriod(value.periode);
                        }
                      },
                    ),
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

                  // Info Banner
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
                            _selectedPeriod != null
                                ? 'Dipublikasikan oleh ${_selectedPeriod!.publishedBy} pada ${DateFormat('dd MMMM yyyy').format(_selectedPeriod!.publishedAt)}'
                                : 'Laporan ini telah dipublikasikan oleh Admin RT',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Summary Cards (Fixed Overflow)
                  _buildSummaryCards(),

                  const SizedBox(height: 16),

                  // Export Buttons (Fixed Overflow)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _exportPDF,
                            icon: const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
                            label: const Text('Export PDF', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
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
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tabs
                  _buildTabs(),

                  // Chart (only on Arus Kas tab/default)
                  if (_currentTabIndex == 2 && _summary != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AspectRatio(
                        aspectRatio: 1.5,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                color: Colors.green,
                                value: _summary!.pemasukan,
                                title: '${((_summary!.pemasukan / (_summary!.pemasukan + _summary!.pengeluaran)) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              PieChartSectionData(
                                color: Colors.red,
                                value: _summary!.pengeluaran,
                                title: '${((_summary!.pengeluaran / (_summary!.pemasukan + _summary!.pengeluaran)) * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                          ),
                        ),
                      ),
                    ),

                  // List
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredLaporan.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada data untuk kategori ini',
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

  // Widget Summary Cards yang sudah diperbaiki agar tidak overflow
  Widget _buildSummaryCards() {
    final pemasukan = _summary?.pemasukan ?? 0.0;
    final pengeluaran = _summary?.pengeluaran ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.green, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Pemasukan',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rp ${NumberFormat('#,###').format(pemasukan)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.red, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Pengeluaran',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rp ${NumberFormat('#,###').format(pengeluaran)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
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

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Pemasukan', 0),
          ),
          Expanded(
            child: _buildTabButton('Pengeluaran', 1),
          ),
          Expanded(
            child: _buildTabButton('Grafik', 2), // Tab tambahan untuk konsistensi
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _currentTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
        _filterData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLaporanCard(LaporanKeuangan laporan) {
    final isIncome = laporan.jenisTransaksi == 'pemasukan';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                Text(
                    laporan.kategori,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy').format(laporan.tanggal),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (laporan.pihakKetiga != null && laporan.pihakKetiga!.isNotEmpty)
                  Text(
                      'Pihak: ${laporan.pihakKetiga}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)
                  ),
                if (laporan.keterangan != null && laporan.keterangan!.isNotEmpty)
                  Text(
                    '${laporan.keterangan}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
}