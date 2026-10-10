import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';




// ============================================================
// TAMBAH / EDIT KOST PAGE
// ============================================================


class TambahEditKostPage extends StatefulWidget {


  final Map<String,dynamic>? kostData;





  const TambahEditKostPage({



    super.key,



    this.kostData,



  });







  @override
  State<TambahEditKostPage> createState() =>

      _TambahEditKostPageState();



}









class _TambahEditKostPageState

extends State<TambahEditKostPage>{





  static const int maxFoto = 5;







  final TextEditingController namaController =

  TextEditingController();





  final TextEditingController hargaController =

  TextEditingController();





  final TextEditingController alamatController =

  TextEditingController();







  final List<Color> fotoTerunggah = [



    const Color(0xFFD7C9A6),



    const Color(0xFFB9D8E3),



  ];









  @override

  void initState(){



    super.initState();







    if(widget.kostData != null){





      namaController.text =

          widget.kostData!['nama'] ?? '';







      hargaController.text =

          widget.kostData!['harga']

              .toString()

              .replaceAll(

              'Rp ',

              ''

          )

              .replaceAll(

              '.',

              ''

          );







      alamatController.text =

          widget.kostData!['alamat'] ??

              '';







    }

    else{







      namaController.text =

      'Kost Adiwarna Eksklusif';







      hargaController.text =

      '1200000';







      alamatController.text =

      'Jl. Gegerkalong Hilir No.12, Sukasari, Bandung';







    }





  }









  @override

  void dispose(){





    namaController.dispose();



    hargaController.dispose();



    alamatController.dispose();







    super.dispose();





  }









  @override

  Widget build(BuildContext context) {



    return Scaffold(





      backgroundColor:

      AppColors.background,









      body:



      SafeArea(



        child:

        Column(



          children: [





            _buildTopBar(context),







            Expanded(



              child:



              SingleChildScrollView(



                padding:

                const EdgeInsets.fromLTRB(



                  16,

                  12,

                  16,

                  20,



                ),







                child:



                Column(



                  crossAxisAlignment:

                  CrossAxisAlignment.start,



                  children: [





                    _buildFormInfo(),







                    const SizedBox(height:18),







                    _buildFieldLabel(

                      "Foto Unit Kost",

                    ),







                    const SizedBox(height:8),







                    _buildUploadBox(),







                    const SizedBox(height:10),







                    _buildFotoThumbnailRow(),







                    const SizedBox(height:20),







                    _buildFieldLabel(

                      "Nama Kost",

                    ),







                    _buildTextField(



                      controller:

                      namaController,



                      icon:

                      Icons.home_outlined,



                    ),







                    const SizedBox(height:16),







                    _buildFieldLabel(

                      "Harga Kost",

                    ),







                    _buildHargaField(),







                    const SizedBox(height:16),







                    _buildFieldLabel(

                      "Alamat / Lokasi Lengkap",

                    ),







                    _buildTextField(



                      controller:

                      alamatController,



                      icon:

                      Icons.location_on_outlined,



                      maxLines:

                      3,



                    ),





                  ],



                ),



              ),



            ),







            _buildSimpanButton(),







          ],



        ),



      ),



    );



  }

// ============================================================
// TOP BAR
// ============================================================


Widget _buildTopBar(
    BuildContext context
){


  return Container(



    padding:

    const EdgeInsets.symmetric(



      horizontal:

      8,



      vertical:

      10,



    ),





    color:

    AppColors.white,





    child:

    Row(



      children: [





        IconButton(



          onPressed:(){



            Navigator.pop(context);



          },





          icon:

          const Icon(



            Icons.arrow_back,



            color:

            AppColors.textPrimary,



          ),





        ),







        const Expanded(



          child:

          Text(



            "Tambah / Edit Kost",



            textAlign:

            TextAlign.center,



            style:

            TextStyle(



              fontSize:

              16,



              fontWeight:

              FontWeight.bold,



              color:

              AppColors.textPrimary,



            ),



          ),



        ),







        IconButton(



          onPressed:(){





            showDialog(



              context:

              context,



              builder:(context){



                return AlertDialog(



                  title:

                  const Text(

                    "Informasi",

                  ),





                  content:

                  const Text(



                    "Lengkapi data kost dengan benar agar mudah ditemukan calon penghuni.",



                  ),





                  actions:[





                    TextButton(



                      onPressed:(){



                        Navigator.pop(context);



                      },





                      child:

                      const Text(

                        "OK",

                      ),





                    ),





                  ],





                );



              },



            );





          },







          icon:

          const Icon(



            Icons.help_outline,



            color:

            AppColors.textSecondary,



          ),





        ),





      ],



    ),



  );


}











// ============================================================
// INFO FORM
// ============================================================


Widget _buildFormInfo(){



  return Container(



    width:

    double.infinity,



    padding:

    const EdgeInsets.all(14),





    decoration:

    BoxDecoration(



      color:

      AppColors.primaryLight,



      borderRadius:

      BorderRadius.circular(14),



    ),





    child:

    Row(



      crossAxisAlignment:

      CrossAxisAlignment.start,



      children: [





        Container(



          width:

          34,



          height:

          34,



          decoration:

          BoxDecoration(



            color:

            AppColors.primary,



            borderRadius:

            BorderRadius.circular(10),



          ),





          child:

          const Icon(



            Icons.home_work_outlined,



            color:

            AppColors.white,



            size:

            18,



          ),





        ),







        const SizedBox(width:10),







        const Expanded(



          child:

          Column(



            crossAxisAlignment:

            CrossAxisAlignment.start,



            children: [





              Text(



                "Formulir Unit Kost",



                style:

                TextStyle(



                  fontSize:

                  13,



                  fontWeight:

                  FontWeight.bold,



                  color:

                  AppColors.textPrimary,



                ),



              ),







              SizedBox(height:4),







              Text(



                "Lengkapi data akurat properti Anda agar mahasiswa mudah menemukan dan memilih kamar sesuai kebutuhan.",



                style:

                TextStyle(



                  fontSize:

                  11,



                  color:

                  AppColors.textSecondary,



                ),



              ),





            ],



          ),



        ),





      ],



    ),



  );


}











// ============================================================
// LABEL FIELD
// ============================================================


Widget _buildFieldLabel(
    String text
){



  return Text(



    text,



    style:

    const TextStyle(



      fontSize:

      13,



      fontWeight:

      FontWeight.w600,



      color:

      AppColors.textPrimary,



    ),



  );


}











// ============================================================
// UPLOAD FOTO BOX
// ============================================================


Widget _buildUploadBox(){



  return GestureDetector(



    onTap:(){



      if(fotoTerunggah.length < maxFoto){



        setState(() {



          fotoTerunggah.add(

            const Color(0xFFE5D6B8),

          );



        });



      }



    },







    child:

    Container(



      height:

      120,



      width:

      double.infinity,





      decoration:

      BoxDecoration(



        color:

        AppColors.white,



        borderRadius:

        BorderRadius.circular(14),





        border:

        Border.all(



          color:

          AppColors.border,



        ),



      ),





      child:

      Column(



        mainAxisAlignment:

        MainAxisAlignment.center,



        children: [





          Container(



            width:

            42,



            height:

            42,



            decoration:

            BoxDecoration(



              color:

              AppColors.primaryLight,



              borderRadius:

              BorderRadius.circular(12),



            ),





            child:

            const Icon(



              Icons.add_photo_alternate_outlined,



              color:

              AppColors.primary,



              size:

              24,



            ),





          ),







          const SizedBox(height:8),







          const Text(



            "Tambah Foto Kost",



            style:

            TextStyle(



              fontSize:

              13,



              fontWeight:

              FontWeight.w600,



              color:

              AppColors.textPrimary,



            ),



          ),







          const SizedBox(height:4),







          Text(



            "Maksimal $maxFoto foto",



            style:

            const TextStyle(



              fontSize:

              11,



              color:

              AppColors.textSecondary,



            ),



          ),





        ],



      ),



    ),



  );


}











// ============================================================
// FOTO THUMBNAIL
// ============================================================


Widget _buildFotoThumbnailRow(){



  return SizedBox(



    height:

    70,





    child:

    ListView.builder(



      scrollDirection:

      Axis.horizontal,



      itemCount:

      fotoTerunggah.length,



      itemBuilder:(context,index){





        return Container(



          margin:

          const EdgeInsets.only(

            right:

            10,

          ),



          width:

          70,



          height:

          70,





          decoration:

          BoxDecoration(



            color:

            fotoTerunggah[index],



            borderRadius:

            BorderRadius.circular(12),



          ),





          child:

          Stack(



            children: [





              Center(



                child:

                Icon(



                  Icons.image,



                  color:

                  AppColors.white.withOpacity(0.8),



                ),



              ),







              Positioned(



                right:

                4,



                top:

                4,





                child:

                GestureDetector(



                  onTap:(){



                    setState(() {



                      fotoTerunggah.removeAt(index);



                    });



                  },





                  child:

                  Container(



                    width:

                    20,



                    height:

                    20,





                    decoration:

                    const BoxDecoration(



                      color:

                      Colors.black54,



                      shape:

                      BoxShape.circle,



                    ),





                    child:

                    const Icon(



                      Icons.close,



                      size:

                      12,



                      color:

                      AppColors.white,



                    ),





                  ),



                ),



              ),





            ],



          ),



        );





      },



    ),



  );


}

// ============================================================
// TEXT FIELD
// ============================================================


Widget _buildTextField({



  required TextEditingController controller,



  required IconData icon,



  int maxLines = 1,



}){



  return TextField(



    controller:

    controller,



    maxLines:

    maxLines,







    decoration:

    InputDecoration(



      prefixIcon:

      Icon(



        icon,



        size:

        20,



        color:

        AppColors.textSecondary,



      ),







      filled:

      true,



      fillColor:

      AppColors.white,









      border:

      OutlineInputBorder(



        borderRadius:

        BorderRadius.circular(12),



        borderSide:

        const BorderSide(



          color:

          AppColors.border,



        ),



      ),







      enabledBorder:

      OutlineInputBorder(



        borderRadius:

        BorderRadius.circular(12),



        borderSide:

        const BorderSide(



          color:

          AppColors.border,



        ),



      ),







      focusedBorder:

      OutlineInputBorder(



        borderRadius:

        BorderRadius.circular(12),



        borderSide:

        const BorderSide(



          color:

          AppColors.primary,



        ),



      ),







      contentPadding:

      const EdgeInsets.symmetric(



        horizontal:

        14,



        vertical:

        12,



      ),





    ),



  );


}











// ============================================================
// HARGA FIELD
// ============================================================


Widget _buildHargaField(){



  return TextField(



    controller:

    hargaController,



    keyboardType:

    TextInputType.number,







    decoration:

    InputDecoration(



      prefixText:

      "Rp ",







      prefixIcon:

      const Icon(



        Icons.payments_outlined,



        size:

        20,



        color:

        AppColors.textSecondary,



      ),







      filled:

      true,



      fillColor:

      AppColors.white,









      border:

      OutlineInputBorder(



        borderRadius:

        BorderRadius.circular(12),



        borderSide:

        const BorderSide(



          color:

          AppColors.border,



        ),



      ),







      enabledBorder:

      OutlineInputBorder(



        borderRadius:

        BorderRadius.circular(12),



        borderSide:

        const BorderSide(



          color:

          AppColors.border,



        ),



      ),







      focusedBorder:

      OutlineInputBorder(



        borderRadius:

        BorderRadius.circular(12),



        borderSide:

        const BorderSide(



          color:

          AppColors.primary,



        ),



      ),







      contentPadding:

      const EdgeInsets.symmetric(



        horizontal:

        14,



        vertical:

        12,



      ),





    ),



  );


}

// ============================================================
// BUTTON SIMPAN DATA KOST
// ============================================================


Widget _buildSimpanButton(){



  return Container(



    padding:

    const EdgeInsets.fromLTRB(



      16,

      10,

      16,

      16,



    ),





    color:

    AppColors.white,





    child:

    SizedBox(



      width:

      double.infinity,



      height:

      48,







      child:

      ElevatedButton(



        onPressed:

        _saveKost,







        style:

        ElevatedButton.styleFrom(



          backgroundColor:

          AppColors.primary,



          foregroundColor:

          AppColors.white,



          elevation:

          0,







          shape:

          RoundedRectangleBorder(



            borderRadius:

            BorderRadius.circular(12),



          ),



        ),







        child:

        Text(



          widget.kostData == null



              ?



          "Simpan Data Kost"



              :



          "Perbarui Data Kost",







          style:

          const TextStyle(



            fontSize:

            14,



            fontWeight:

            FontWeight.bold,



          ),



        ),





      ),



    ),



  );


}











// ============================================================
// SIMPAN KOST
// ============================================================


void _saveKost(){



  if(



  namaController.text.trim().isEmpty ||



      hargaController.text.trim().isEmpty ||



      alamatController.text.trim().isEmpty



  ){





    ScaffoldMessenger.of(context)

        .showSnackBar(



      const SnackBar(



        content:

        Text(



          "Harap lengkapi semua data kost",



        ),



      ),



    );







    return;



  }









  final bool isEdit =

      widget.kostData != null;









  showDialog(



    context:

    context,



    builder:(context){



      return AlertDialog(



        title:

        Text(



          isEdit



              ?



          "Perbarui Kost"



              :



          "Tambah Kost",



        ),







        content:

        Text(



          isEdit



              ?



          "Data kost berhasil diperbarui"



              :



          "Data kost berhasil ditambahkan",



        ),







        actions:[





          TextButton(



            onPressed:(){



              Navigator.pop(context);



              Navigator.pop(context);



            },





            child:

            const Text(
              "OK",
            ),
          ),
        ],

      );
    },
  );
}

}