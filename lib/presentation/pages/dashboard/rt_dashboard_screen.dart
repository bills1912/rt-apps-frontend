import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rt_app_apk/core/theme/color_list.dart';
import 'package:rt_app_apk/models/data_warga.dart';
import 'package:rt_app_apk/models/user.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/data_warga_service.dart';
import 'package:rt_app_apk/services/storage_services.dart';

class RTDashboardScreen extends StatefulWidget {
  const RTDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RTDashboardScreen> createState() => _RTDashboardScreenState();
}

final ApiServices apiServices = ApiServices();
final DataWargaService dataWargaService = DataWargaService(apiServices);

class _RTDashboardScreenState extends State<RTDashboardScreen> {
  User? _user;
  PaymentStats? _stats;
  bool _isLoading = false;
  String _selectedMonth = 'January';

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    // Set default month to current month
    final currentMonth = DateTime.now().month - 1;
    _selectedMonth = _months[currentMonth];

    _loadUser();
    _fetchStats();
  }

  Future<void> _loadUser() async {
    final user = await StorageServices.getUser();
    if (user != null) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch stats with selected month filter
      print('📊 Fetching stats for month: $_selectedMonth');
      final stats = await dataWargaService.getPaymentStats(month: _selectedMonth);
      if (mounted) {
        setState(() {
          _stats = stats;
        });
        print('✅ Stats loaded: ${stats.monthlyStats[_selectedMonth]?.paid ?? 0} paid out of ${stats.totalWarga}');
      }
    } catch (e) {
      print('❌ Error fetching stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorList.primary50,
      body: SafeArea(
        child: _isLoading && _stats == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user?.name ?? 'Ketua RT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dashboard Monitoring',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Content Card
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Selector
                      const Text(
                        'Pilih Bulan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedMonth,
                            isExpanded: true,
                            items: _months.map((month) {
                              return DropdownMenuItem(
                                value: month,
                                child: Text(month),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedMonth = value;
                                });
                                // Refresh data when month changes
                                _fetchStats();
                              }
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Statistics
                      if (_stats != null) ...[
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                      ],

                      // Action Buttons
                      _buildActionButton(
                        icon: Icons.people,
                        title: 'Lihat Data Warga',
                        subtitle: 'Status pembayaran per warga',
                        onTap: () {
                          context.push('/dashboard/data-warga');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        icon: Icons.assessment,
                        title: 'Laporan Keuangan',
                        subtitle: 'Lihat laporan lengkap',
                        onTap: () {
                          context.push('/dashboard/laporan-keuangan');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final monthStats = _stats!.monthlyStats[_selectedMonth];

    if (monthStats == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Data tidak tersedia untuk bulan $_selectedMonth',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    final total = monthStats.paid + monthStats.unpaid;
    final percentage = total > 0 ? (monthStats.paid / total * 100) : 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik $_selectedMonth',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Warga',
                  '${_stats!.totalWarga}',
                  Colors.blue,
                ),
                _buildStatItem(
                  'Sudah Bayar',
                  '${monthStats.paid}',
                  Colors.green,
                ),
                _buildStatItem(
                  'Belum Bayar',
                  '${monthStats.unpaid}',
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage > 75 ? Colors.green : Colors.orange,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}% sudah membayar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorList.primary50.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: ColorList.primary50,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}