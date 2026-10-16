class KostModel {
  // ID kost
  final String idKost;

  // Informasi utama kost
  final String nama;
  final String alamat;
  final int harga;
  final String deskripsi;
  final int ketersediaanKamar;

  // Atribut Tambahan / Filter Admin (Diberi nilai default agar aman)
  final String tipe;
  final bool terverifikasi;
  final bool termasukListrik;

  // Data relasi / list
  final List<String> foto;
  final List<String> fasilitas;

  KostModel({
    required this.idKost,
    required this.nama,
    required this.alamat,
    required this.harga,
    required this.deskripsi,
    required this.ketersediaanKamar,
    this.tipe = "Campur",
    this.terverifikasi = true,
    this.termasukListrik = true,
    required this.foto,
    required this.fasilitas,
  });

  // Konversi data Supabase menjadi object KostModel
  factory KostModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedFasilitas = [];
    if (json['fasilitas'] is String) {
      parsedFasilitas = (json['fasilitas'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['fasilitas_kost'] is List) {
      parsedFasilitas = (json['fasilitas_kost'] as List)
          .map<String>((item) => item['fasilitas']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return KostModel(
      idKost: json['id_kost']?.toString() ?? json['id']?.toString() ?? "",
      nama: json['nama'] ?? "",
      alamat: json['alamat'] ?? "",
      harga: int.tryParse(json['harga']?.toString() ?? "0") ?? 0,
      deskripsi: json['deskripsi'] ?? "",
      ketersediaanKamar:
          int.tryParse(json['ketersediaan_kamar']?.toString() ?? "0") ?? 0,
      tipe: json['tipe'] ?? "Campur",
      terverifikasi: json['terverifikasi'] ?? true,
      termasukListrik: json['termasuk_listrik'] ?? true,
      
      // Mengambil daftar foto kost dari relasi 'foto_kost'
      foto: json['foto_kost'] is List
          ? (json['foto_kost'] as List)
              .map<String>((item) => item['foto'].toString())
              .toList()
          : [],

      fasilitas: parsedFasilitas,
    );
  }

  // Konversi object menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      "id_kost": idKost,
      "nama": nama,
      "alamat": alamat,
      "harga": harga,
      "deskripsi": deskripsi,
      "ketersediaan_kamar": ketersediaanKamar,
      "tipe": tipe,
      "terverifikasi": terverifikasi,
      "termasuk_listrik": termasukListrik,
      "fasilitas": fasilitas.join(', '),
      "foto_kost": foto
          .map(
            (item) => {
              "foto": item,
            },
          )
          .toList(),
      "fasilitas_kost": fasilitas
          .map(
            (item) => {
              "fasilitas": item,
            },
          )
          .toList(),
    };
  }
}