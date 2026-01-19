class LaporanKeuangan {
  final int id;
  final DateTime tanggal;
  final String jenisTransaksi; // pemasukan/pengeluaran
  final String kategori;
  final String? pihakKetiga;
  final double jumlah;
  final String? keterangan;
  final String periode;
  final List<String> buktiTransaksi;
  final int createdBy;

  LaporanKeuangan({
    required this.id,
    required this.tanggal,
    required this.jenisTransaksi,
    required this.kategori,
    this.pihakKetiga,
    required this.jumlah,
    this.keterangan,
    required this.periode,
    required this.buktiTransaksi,
    required this.createdBy,
  });

  factory LaporanKeuangan.fromJson(Map<String, dynamic> json) {
    List<String> bukti = [];
    if (json['buktiTransaksi'] != null) {
      if (json['buktiTransaksi'] is List) {
        bukti = (json['buktiTransaksi'] as List)
            .map((e) => e.toString())
            .toList();
      }
    }

    return LaporanKeuangan(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      tanggal: json['tanggal'] != null
          ? DateTime.parse(json['tanggal'])
          : DateTime.now(),
      jenisTransaksi: json['jenisTransaksi']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? '',
      pihakKetiga: json['pihakKetiga']?.toString(),
      jumlah: json['jumlah'] is num
          ? (json['jumlah'] as num).toDouble()
          : double.tryParse(json['jumlah'].toString()) ?? 0.0,
      keterangan: json['keterangan']?.toString(),
      periode: json['periode']?.toString() ?? '',
      buktiTransaksi: bukti,
      createdBy: json['createdBy'] is int
          ? json['createdBy']
          : int.tryParse(json['createdBy'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal.toIso8601String(),
      'jenisTransaksi': jenisTransaksi,
      'kategori': kategori,
      'pihakKetiga': pihakKetiga,
      'jumlah': jumlah,
      'keterangan': keterangan,
      'periode': periode,
      'buktiTransaksi': buktiTransaksi,
      'createdBy': createdBy,
    };
  }
}

class LaporanSummary {
  final String periode;
  final double pemasukan;
  final double pengeluaran;
  final double saldo;

  LaporanSummary({
    required this.periode,
    required this.pemasukan,
    required this.pengeluaran,
    required this.saldo,
  });

  factory LaporanSummary.fromJson(Map<String, dynamic> json) {
    return LaporanSummary(
      periode: json['periode']?.toString() ?? '',
      pemasukan: json['pemasukan'] is num
          ? (json['pemasukan'] as num).toDouble()
          : double.tryParse(json['pemasukan'].toString()) ?? 0.0,
      pengeluaran: json['pengeluaran'] is num
          ? (json['pengeluaran'] as num).toDouble()
          : double.tryParse(json['pengeluaran'].toString()) ?? 0.0,
      saldo: json['saldo'] is num
          ? (json['saldo'] as num).toDouble()
          : double.tryParse(json['saldo'].toString()) ?? 0.0,
    );
  }
}