import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/kost_model.dart';
import 'hapus_favorite_dialog.dart';
import 'detail_kost_page.dart';

class DaftarFavoritePage extends StatefulWidget{
  const DaftarFavoritePage({super.key});

  @override
  State<DaftarFavoritePage> createState()=>_DaftarFavoritePageState();
}

class _DaftarFavoritePageState extends State<DaftarFavoritePage>{

  // Menyimpan data kost dari database
  List<KostModel> daftarKost=[];
  bool isLoading=true;


  @override
  void initState(){
    super.initState();
    loadFavorite();
  }


  // Mengambil data favorit dari Supabase
  Future<void> loadFavorite()async{

    final user=
    Supabase.instance.client.auth.currentUser;

    if(user==null){
      setState(()=>isLoading=false);
      return;
    }


    final response=
    await Supabase.instance.client
        .from('favorite')
        .select('''
          id_favorite,
          kost(
            id_kost,
            nama,
            alamat,
            harga,
            deskripsi,
            ketersediaan_kamar,
            foto_kost(foto),
            fasilitas_kost(fasilitas)
          )
        ''')
        .eq('id_user',user.id);



    final data=response.map<KostModel>((item){

      final kost=item['kost'];

      return KostModel(

        idKost:
        kost['id_kost'].toString(),

        nama:
        kost['nama']??"",

        alamat:
        kost['alamat']??"",

        harga:
        kost['harga']??0,

        deskripsi:
        kost['deskripsi']??"",

        ketersediaanKamar:
        kost['ketersediaan_kamar']??0,


        // Mengambil foto dari tabel foto_kost
        foto:

        (kost['foto_kost'] as List)
            .map<String>(
              (e)=>e['foto'].toString(),
        )
            .toList(),


        // Mengambil fasilitas dari tabel fasilitas_kost
        fasilitas:

        (kost['fasilitas_kost'] as List)
            .map<String>(
              (e)=>e['fasilitas'].toString(),
        )
            .toList(),

      );

    }).toList();


    setState((){

      daftarKost=data;

      isLoading=false;

    });

  }



  // Menghapus favorit dari database
  Future<void> hapusFavorite(int index)async{

    final user=
    Supabase.instance.client.auth.currentUser;


    if(user==null)return;


    final kost=
    daftarKost[index];


    await Supabase.instance.client
        .from('favorite')
        .delete()
        .eq(
          'id_user',
          user.id,
        )
        .eq(
          'id_kost',
          kost.idKost,
        );


    setState((){

      daftarKost.removeAt(index);

    });

  }



  @override
  Widget build(BuildContext context){

    return Scaffold(

      backgroundColor:
      Colors.white,


      body:SafeArea(

        child:Column(

          children:[


            // Header halaman

            Padding(

              padding:
              const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                8,
              ),


              child:Row(

                children:[


                  const Icon(
                    Icons.arrow_back_ios,
                    size:18,
                  ),


                  const SizedBox(width:6),


                  const Text(
                    "Kost Favorit",

                    style:
                    TextStyle(

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

                      ),

                    ),

                  ),

                ],

              ),

            ),



            Expanded(

              child:

              isLoading

              ?

              const Center(
                child:
                CircularProgressIndicator(),
              )


              :

              ListView.builder(

                padding:
                const EdgeInsets.symmetric(
                  horizontal:16,
                ),


                itemCount:
                daftarKost.length,


                itemBuilder:
                (context,index){


                  final kost=
                  daftarKost[index];


                  return GestureDetector(

                    // Membuka detail kost
                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:(context)=>
                          DetailKostPage(
                            kost:kost,
                          ),

                        ),

                      ).then((value){

                        loadFavorite();

                      });

                    },


                    child:Card(

                      margin:
                      const EdgeInsets.only(
                        bottom:10,
                      ),


                      child:ListTile(

                        leading:

                        Image.network(

                          kost.foto.isNotEmpty
                          ?kost.foto[0]
                          :"",

                          width:70,

                          fit:
                          BoxFit.cover,

                        ),


                        title:
                        Text(
                          kost.nama,
                        ),


                        subtitle:
                        Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,


                          children:[


                            Text(
                              "Rp ${kost.harga}/bulan",
                            ),


                            Text(
                              kost.alamat,
                            ),


                            Text(
                              kost.fasilitas.join(" • "),
                            ),

                          ],

                        ),


                        trailing:
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

                          ),

                        ),

                      ),

                    ),

                  );

                },

              ),

            ),

          ],

        ),

      ),

    );

  }

}