// screens/notification_list_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rt_app_apk/models/notification_model.dart';
import 'package:rt_app_apk/services/api_services.dart';
import 'package:rt_app_apk/services/notification_services.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({Key? key})
    : super(key: key);

  @override
  State<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

final ApiServices apiServices = ApiServices();
final NotificationServices notificationServices =
    NotificationServices(apiServices);

class _NotificationListScreenState
    extends State<NotificationListScreen> {
  late Future<List<NotificationModel>> _futureNotifications;

  @override
  void initState() {
    super.initState();
    _futureNotifications = notificationServices.getAll();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureNotifications = notificationServices.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 16,
            ), // 👈 actual padding
            child: SizedBox(),
          ),
        ),
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          final notifications = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  title: Text(
                    'Tagihan Iuran Baru',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.start,
                    children: [
                      Text(n.message),
                      Text(
                        DateFormat(
                          'dd MMMM yyyy',
                        ).format(n.createdAt),
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade500,
                    ),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade800,
                    ),
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            title: Text('Hapus pesan ini?'),
                            content: Column(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                const Text(
                                  'Setelah dihapus, pesan tidak akan muncul lagi di halaman ini.',
                                ),
                                const SizedBox(height: 24),
                                Column(
                                  children: [
                                    SizedBox(
                                      width:
                                          double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close dialog
                                          await notificationServices
                                              .delete(n.id);
                                          _refresh();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                  5,
                                                ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Hapus',
                                          style: TextStyle(
                                            color:
                                                Colors
                                                    .white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    SizedBox(
                                      width:
                                          double.infinity,
                                      child: OutlinedButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(
                                                  context,
                                                ).pop(),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor:
                                              Colors.white,
                                          side: BorderSide(
                                            color:
                                                Colors
                                                    .grey
                                                    .shade300,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                  5,
                                                ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Batal',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
