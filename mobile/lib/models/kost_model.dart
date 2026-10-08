class KostModel{

  // ID kost
  final String idKost;

  // Informasi utama kost
  final String nama;
  final String alamat;
  final int harga;
  final String deskripsi;
  final int ketersediaanKamar;

  // Data relasi
  final List<String> foto;
  final List<String> fasilitas;


  KostModel({
    required this.idKost,
    required this.nama,
    required this.alamat,
    required this.harga,
    required this.deskripsi,
    required this.ketersediaanKamar,
    required this.foto,
    required this.fasilitas,
  });


  // Konversi data Supabase menjadi object KostModel
  factory KostModel.fromJson(Map<String,dynamic> json){

    return KostModel(

      idKost:
      json['id_kost']?.toString() ?? "",

      nama:
      json['nama'] ?? "",

      alamat:
      json['alamat'] ?? "",

      // Mengubah harga menjadi int agar aman
      harga:
      int.tryParse(
        json['harga']?.toString() ?? "0",
      ) ?? 0,

      deskripsi:
      json['deskripsi'] ?? "",

      ketersediaanKamar:
      int.tryParse(
        json['ketersediaan_kamar']?.toString() ?? "0",
      ) ?? 0,


      // Mengambil daftar foto kost
      foto:

      json['foto_kost'] is List

      ? (json['foto_kost'] as List)
          .map<String>(
            (item)=>item['foto'].toString(),
          )
          .toList()

      : [],


      // Mengambil daftar fasilitas kost
      fasilitas:

      json['fasilitas_kost'] is List

      ? (json['fasilitas_kost'] as List)
          .map<String>(
            (item)=>item['fasilitas'].toString(),
          )
          .toList()

      : [],

    );

  }


  // Konversi object menjadi JSON
  Map<String,dynamic> toJson(){

    return{

      "id_kost":idKost,

      "nama":nama,

      "alamat":alamat,

      "harga":harga,

      "deskripsi":deskripsi,

      "ketersediaan_kamar":
      ketersediaanKamar,


      "foto_kost":

      foto.map(

        (item)=>{

          "foto":item,

        },

      ).toList(),


      "fasilitas_kost":

      fasilitas.map(

        (item)=>{

          "fasilitas":item,

        },

      ).toList(),

    };

  }

}