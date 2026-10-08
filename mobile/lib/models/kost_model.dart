class KostModel {

  // ID kost dari tabel kost
  final String idKost;

  // Nama kost
  final String nama;

  // Alamat lengkap kost
  final String alamat;

  // Harga sewa per bulan
  final int harga;

  // Deskripsi kost
  final String deskripsi;

  // Jumlah kamar yang tersedia
  final int ketersediaanKamar;

  // Daftar foto kost dari tabel foto_kost
  final List<String> foto;

  // Daftar fasilitas dari tabel fasilitas_kost
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



  // Mengubah data JSON/database menjadi object KostModel
  factory KostModel.fromJson(
    Map<String,dynamic> json,
  ){

    return KostModel(

      idKost:
      json['id_kost']?.toString() ?? "",


      nama:
      json['nama'] ?? "",


      alamat:
      json['alamat'] ?? "",


      harga:
      json['harga'] ?? 0,


      deskripsi:
      json['deskripsi'] ?? "",


      ketersediaanKamar:
      json['ketersediaan_kamar'] ?? 0,



      // Mengambil data foto kost
      foto:

      json['foto_kost'] != null

      ? List<String>.from(

          json['foto_kost'].map(

            (item)=>item['foto'],

          ),

        )

      : [],



      // Mengambil data fasilitas kost
      fasilitas:

      json['fasilitas_kost'] != null

      ? List<String>.from(

          json['fasilitas_kost'].map(

            (item)=>item['fasilitas'],

          ),

        )

      : [],

    );

  }



  // Mengubah object KostModel menjadi JSON
  Map<String,dynamic> toJson(){

    return {

      "id_kost":
      idKost,


      "nama":
      nama,


      "alamat":
      alamat,


      "harga":
      harga,


      "deskripsi":
      deskripsi,


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