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

  // Pagination & Search
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;
  final int _itemsPerPage = 10;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await dataWargaService.getAllWargaPaginated(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchQuery,
      );

      setState(() {
        _wargaList = result['data'] as List<DataWarga>;
        final pagination = result['pagination'] as Map<String, dynamic>;
        _totalPages = pagination['totalPages'] ?? 1;
        _totalItems = pagination['totalItems'] ?? 0;
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1; // Reset to first page when searching
    });
    _fetchData();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _wargaList.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _wargaList.isEmpty) {
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama warga...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _onSearchChanged(value);
                  }
                });
              },
            ),
          ),

          // Info Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: $_totalItems warga',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColorList.primary50.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hasil pencarian: "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorList.primary50,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Data Table
          Expanded(
            child: _wargaList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Tidak ada data warga'
                        : 'Tidak ada hasil untuk "$_searchQuery"',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
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
                      final globalIndex = (_currentPage - 1) * _itemsPerPage + index + 1;

                      return DataRow(
                        cells: [
                          DataCell(Text('$globalIndex')),
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
          ),

          // Pagination Controls
          if (_totalPages > 1)
            Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Button
                  ElevatedButton.icon(
                    onPressed: _currentPage > 1
                        ? () => _goToPage(_currentPage - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Sebelumnya'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorList.primary50,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),

                  // Page Info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Halaman $_currentPage dari $_totalPages',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Next Button
                  ElevatedButton.icon(
                    onPressed: _currentPage < _totalPages
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Selanjutnya'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorList.primary50,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}