import 'package:flutter/material.dart';
import 'hapus_favorite_dialog.dart';


class DaftarFavoritePage extends StatefulWidget {

  const DaftarFavoritePage({super.key});


  @override
  State<DaftarFavoritePage> createState() =>
      _DaftarFavoritePageState();

}



class _DaftarFavoritePageState 
extends State<DaftarFavoritePage> {


  // DATA SEMENTARA
  // Nanti diganti dengan data dari tabel favorite + kost

  List<Map<String,dynamic>> daftarKost = [

    {
      "id_kost": "1",
      "foto": "assets/images/kost1.jpg",
      "nama": "Kost Adiwarna",
      "harga": 1200000,
      "alamat": "Jl. Danau Toba No.12, Ternate",
      "rating": "4.9",
      "fasilitas": "WiFi • AC",
      "ketersediaan_kamar": 3,
    },


    {
      "id_kost": "2",
      "foto": "assets/images/kost2.jpg",
      "nama": "Kost Melati",
      "harga": 1000000,
      "alamat": "Jl. Setiabudi, Ternate",
      "rating": "4.7",
      "fasilitas": "WiFi • AC",
      "ketersediaan_kamar": 2,
    },


    {
      "id_kost": "3",
      "foto": "assets/images/kost3.jpg",
      "nama": "Kost Cemara",
      "harga": 950000,
      "alamat": "Jl. Dago, Ternate",
      "rating": "4.8",
      "fasilitas": "WiFi • AC",
      "ketersediaan_kamar": 5,
    },

  ];



  void hapusFavorite(int index){

    setState((){

      daftarKost.removeAt(index);

    });

  }



  @override
  Widget build(BuildContext context) {


    return Scaffold(

      backgroundColor:
      Colors.white,


      body: SafeArea(

        child: Column(

          children:[


            // HEADER

            Padding(

              padding:
              const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                8,
              ),


              child: Row(

                children:[


                  const Icon(

                    Icons.arrow_back_ios,

                    size:18,

                  ),



                  const SizedBox(width:6),



                  const Text(

                    "Kost Favorit",

                    style: TextStyle(

                      fontSize:18,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),



                  const Spacer(),



                  Container(

                    padding:
                    const EdgeInsets.symmetric(

                      horizontal:10,

                      vertical:5,

                    ),


                    decoration:
                    BoxDecoration(

                      color:
                      Colors.red.shade50,

                      borderRadius:
                      BorderRadius.circular(20),

                    ),


                    child:Text(

                      "${daftarKost.length} Tersimpan",

                      style:
                      const TextStyle(

                        color:
                        Colors.red,

                        fontSize:11,

                        fontWeight:
                        FontWeight.bold,

                      ),

                    ),

                  )

                ],

              ),

            ),



            // LOKASI

            Padding(

              padding:
              const EdgeInsets.symmetric(
                horizontal:16,
              ),


              child:Row(

                children:[


                  const Icon(

                    Icons.location_on,

                    color:
                    Colors.blue,

                    size:15,

                  ),



                  const SizedBox(width:5),



                  const Text(

                    "Ternate • Kost Tersimpan",

                    style:
                    TextStyle(

                      fontSize:12,

                    ),

                  ),



                  const Spacer(),



                  Text(

                    "Sinkron Otomatis",

                    style:
                    TextStyle(

                      fontSize:11,

                      color:
                      Colors.grey.shade600,

                    ),

                  ),

                ],

              ),

            ),



            const SizedBox(height:10),



            // BANNER

            Container(

              margin:
              const EdgeInsets.symmetric(
                horizontal:16,
              ),


              padding:
              const EdgeInsets.all(10),


              decoration:
              BoxDecoration(

                color:
                Colors.blue.shade50,

                borderRadius:
                BorderRadius.circular(10),

              ),


              child:Row(

                children:[


                  const Icon(

                    Icons.notifications_none,

                    color:
                    Colors.blue,

                  ),



                  const SizedBox(width:8),



                  const Expanded(

                    child:Text(

                      "Ketersediaan kamar dan harga dapat berubah sewaktu-waktu.",

                      style:
                      TextStyle(

                        fontSize:11,

                      ),

                    ),

                  )

                ],

              ),

            ),



            const SizedBox(height:10),



            // LIST KOST

            Expanded(

              child:
              ListView.builder(

                padding:
                const EdgeInsets.symmetric(
                  horizontal:16,
                ),


                itemCount:
                daftarKost.length,


                itemBuilder:
                (context,index){


                  final kost =
                  daftarKost[index];


                  return Container(

                    margin:
                    const EdgeInsets.only(
                      bottom:10,
                    ),


                    padding:
                    const EdgeInsets.all(8),


                    decoration:
                    BoxDecoration(

                      color:
                      Colors.white,

                      borderRadius:
                      BorderRadius.circular(12),


                      boxShadow:[

                        const BoxShadow(

                          color:
                          Colors.black12,

                          blurRadius:
                          5,

                        )

                      ],

                    ),



                    child:Row(

                      children:[


                        ClipRRect(

                          borderRadius:
                          BorderRadius.circular(8),


                          child:
                          Image.asset(

                            kost["foto"],

                            width:75,

                            height:75,

                            fit:
                            BoxFit.cover,

                          ),

                        ),



                        const SizedBox(width:10),



                        Expanded(

                          child:Column(

                            crossAxisAlignment:
                            CrossAxisAlignment.start,


                            children:[


                              Row(

                                children:[


                                  Expanded(

                                    child:Text(

                                      kost["nama"],

                                      style:
                                      const TextStyle(

                                        fontSize:13,

                                        fontWeight:
                                        FontWeight.bold,

                                      ),

                                    ),

                                  ),



                                  GestureDetector(

                                    onTap:(){

                                      showHapusFavoriteDialog(

                                        context,

                                        (){

                                          hapusFavorite(index);

                                        },

                                      );

                                    },


                                    child:
                                    const Icon(

                                      Icons.favorite,

                                      color:
                                      Colors.red,

                                      size:20,

                                    ),

                                  )

                                ],

                              ),



                              Text(

                                "Rp ${kost["harga"]}/bulan",

                                style:
                                const TextStyle(

                                  color:
                                  Colors.blue,

                                  fontWeight:
                                  FontWeight.bold,

                                  fontSize:12,

                                ),

                              ),



                              Text(

                                kost["alamat"],

                                maxLines:1,

                                overflow:
                                TextOverflow.ellipsis,


                                style:
                                const TextStyle(

                                  color:
                                  Colors.grey,

                                  fontSize:10,

                                ),

                              ),



                              Text(

                                "⭐ ${kost["rating"]}  ${kost["fasilitas"]}",

                                style:
                                const TextStyle(

                                  fontSize:10,

                                ),

                              ),

                            ],

                          ),

                        )

                      ],

                    ),

                  );

                },

              ),

            )

          ],

        ),

      ),

    );

  }

}