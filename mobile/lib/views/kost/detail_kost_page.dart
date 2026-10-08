//Ilham
import 'package:flutter/material.dart';
import '../../models/kost_model.dart';


class DetailKostPage extends StatefulWidget {

  // Data kost yang dikirim dari halaman sebelumnya
  final KostModel kost;

  const DetailKostPage({
    super.key,
    required this.kost,
  });

  @override
  State<DetailKostPage> createState() =>
      _DetailKostPageState();
}


class _DetailKostPageState extends State<DetailKostPage> {

  // Status favorit kost
  bool isFavorite = false;


  // Mengubah status favorit
  void toggleFavorite() {

    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        duration: const Duration(seconds:1),
        content: Text(
          isFavorite
              ? "Kost ditambahkan ke favorit"
              : "Kost dihapus dari favorit",
        ),
      ),
    );
  }


  // Tombol kembali
  void goBack() {

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [

          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom:100),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // =====================
                // FOTO KOST
                // =====================

                Stack(
                  children: [

                    Image.network(

                      // Mengambil foto dari tabel foto_kost
                      widget.kost.foto.isNotEmpty
                          ? widget.kost.foto[0]
                          : "",

                      height:330,
                      width:double.infinity,
                      fit:BoxFit.cover,

                      errorBuilder:
                      (context,error,stackTrace){

                        return Container(
                          height:330,
                          color:Colors.grey.shade300,

                          child:const Icon(
                            Icons.image_not_supported,
                            size:50,
                            color:Colors.grey,
                          ),
                        );

                      },

                    ),


                    // Tombol kembali

                    Positioned(
                      top:40,
                      left:20,

                      child:circleButton(
                        icon:Icons.arrow_back_ios_new,
                        onTap:goBack,
                      ),
                    ),



                    // Tombol share

                    Positioned(
                      top:40,
                      right:70,

                      child:circleButton(
                        icon:Icons.share_outlined,

                        onTap:(){

                          ScaffoldMessenger.of(context)
                          .showSnackBar(

                            const SnackBar(
                              content:
                              Text(
                                "Fitur berbagi akan tersedia",
                              ),
                            ),

                          );

                        },
                      ),
                    ),



                    // Tombol favorit

                    Positioned(
                      top:40,
                      right:20,

                      child:circleButton(

                        icon:isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,

                        color:isFavorite
                            ? Colors.red
                            : Colors.black,

                        onTap:toggleFavorite,

                      ),
                    ),



                    // Jumlah foto

                    Positioned(
                      bottom:20,
                      right:20,

                      child:Container(

                        padding:
                        const EdgeInsets.symmetric(
                          horizontal:12,
                          vertical:6,
                        ),

                        decoration:BoxDecoration(
                          color:Colors.black54,
                          borderRadius:
                          BorderRadius.circular(20),
                        ),

                        child:Row(

                          children:[

                            const Icon(
                              Icons.photo_library_outlined,
                              size:14,
                              color:Colors.white,
                            ),

                            const SizedBox(width:5),

                            Text(

                              "${widget.kost.foto.length} Foto",

                              style:
                              const TextStyle(
                                color:Colors.white,
                                fontSize:12,
                              ),

                            ),

                          ],

                        ),

                      ),

                    ),

                  ],

                ),