import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

import 'home_admin_page.dart';
import 'daftar_chat_admin_page.dart';
import 'profil_admin_page.dart';
import 'tambah_edit_kost_page.dart';




// ============================================================
// MODEL DATA KOST
// ============================================================


class KostItem {


  final String nama;


  final String harga;


  final String ketersediaan;





  const KostItem({


    required this.nama,


    required this.harga,


    required this.ketersediaan,


  });






  Map<String,dynamic> toMap(){


    return {


      "nama":
      nama,


      "harga":
      harga,


      "ketersediaan":
      ketersediaan,


    };


  }


}







// ============================================================
// DATA KOST PAGE
// ============================================================


class DataKostPage extends StatelessWidget {


  const DataKostPage({


    super.key,


  });








  static const List<KostItem> daftarKost = [



    KostItem(


      nama:

      "Kost Adiwarna",


      harga:

      "Rp 1.200.000",


      ketersediaan:

      "Tersedia 3 kamar",


    ),






    KostItem(


      nama:

      "Kost Melati",


      harga:

      "Rp 1.000.000",


      ketersediaan:

      "Tersedia 2 kamar",


    ),






    KostItem(


      nama:

      "Kost Cemara",


      harga:

      "Rp 950.000",


      ketersediaan:

      "Tersedia 5 kamar",


    ),



  ];









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



              ListView(



                padding:



                const EdgeInsets.all(16),





                children: [






                  for(final kost in daftarKost)



                    Padding(



                      padding:



                      const EdgeInsets.only(



                        bottom:12,



                      ),





                      child:



                      _buildKostCard(



                        context,



                        kost,



                      ),





                    ),








                  _buildManajemenKamarInfo(),





                ],



              ),



            ),





          ],



        ),



      ),







      bottomNavigationBar:



      _buildBottomNav(context),





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

    const EdgeInsets.fromLTRB(

      16,

      12,

      16,

      12,

    ),




    color:

    AppColors.white,





    child:

    Row(



      mainAxisAlignment:

      MainAxisAlignment.spaceBetween,



      children: [





        const Text(



          "Data Kost",



          style:

          TextStyle(



            fontSize:

            22,



            fontWeight:

            FontWeight.bold,



            color:

            AppColors.textPrimary,



          ),



        ),







        ElevatedButton.icon(



          onPressed:(){



            Navigator.push(



              context,



              MaterialPageRoute(



                builder:(context)=>



                const TambahEditKostPage(),



              ),



            );



          },





          style:

          ElevatedButton.styleFrom(



            backgroundColor:

            AppColors.primary,



            foregroundColor:

            AppColors.white,



            elevation:

            0,



            padding:

            const EdgeInsets.symmetric(



              horizontal:

              12,



              vertical:

              10,



            ),



            shape:

            RoundedRectangleBorder(



              borderRadius:

              BorderRadius.circular(10),



            ),



          ),






          icon:

          const Icon(



            Icons.add,



            size:

            16,



          ),






          label:

          const Text(



            "Tambah Kost",



            style:

            TextStyle(



              fontSize:

              12,



              fontWeight:

              FontWeight.w600,



            ),



          ),





        ),




      ],



    ),



  );


}









// ============================================================
// CARD DATA KOST
// ============================================================


Widget _buildKostCard(



    BuildContext context,



    KostItem kost,



){



  return Container(



    padding:

    const EdgeInsets.all(12),





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

    Row(



      crossAxisAlignment:

      CrossAxisAlignment.start,



      children: [





        Container(



          width:

          64,



          height:

          64,



          decoration:

          BoxDecoration(



            color:

            AppColors.backgroundLight,



            borderRadius:

            BorderRadius.circular(10),



          ),





          child:

          const Icon(



            Icons.apartment,



            size:

            30,



            color:

            AppColors.textSecondary,



          ),



        ),







        const SizedBox(width:12),







        Expanded(



          child:

          Column(



            crossAxisAlignment:

            CrossAxisAlignment.start,



            children: [





              Text(



                kost.nama,



                style:

                const TextStyle(



                  fontSize:

                  14,



                  fontWeight:

                  FontWeight.bold,



                  color:

                  AppColors.textPrimary,



                ),



              ),





              const SizedBox(height:4),





              Text(



                "${kost.harga}/bulan",



                style:

                const TextStyle(



                  fontSize:

                  13,



                  fontWeight:

                  FontWeight.w600,



                  color:

                  AppColors.primary,



                ),



              ),






              const SizedBox(height:6),







              Row(



                children: [





                  Container(



                    width:

                    7,



                    height:

                    7,



                    decoration:

                    const BoxDecoration(



                      color:

                      AppColors.success,



                      shape:

                      BoxShape.circle,



                    ),



                  ),






                  const SizedBox(width:6),






                  Text(



                    kost.ketersediaan,



                    style:

                    const TextStyle(



                      fontSize:

                      11,



                      color:

                      AppColors.success,



                    ),



                  ),



                ],



              ),





            ],



          ),



        ),








        Column(



          children: [





            IconButton(



              constraints:

              const BoxConstraints(),



              padding:

              EdgeInsets.zero,





              onPressed:(){



                Navigator.push(



                  context,



                  MaterialPageRoute(



                    builder:(context)=>



                    TambahEditKostPage(



                      kostData:

                      kost.toMap(),



                    ),



                  ),



                );



              },







              icon:

              const Icon(



                Icons.edit,



                size:

                18,



                color:

                AppColors.primary,



              ),





            ),







            const SizedBox(height:12),








            IconButton(



              constraints:

              const BoxConstraints(),



              padding:

              EdgeInsets.zero,





              onPressed:(){



                _showDeleteDialog(



                  context,



                  kost,



                );



              },







              icon:

              const Icon(



                Icons.delete_outline,



                size:

                18,



                color:

                AppColors.error,



              ),





            ),





          ],



        ),





      ],



    ),



  );


}

// ============================================================
// DELETE CONFIRMATION
// ============================================================


void _showDeleteDialog(



    BuildContext context,



    KostItem kost,



){



  showDialog(



    context:

    context,



    builder:(context){



      return AlertDialog(





        title:

        const Text(



          "Hapus Kost",



        ),







        content:

        Text(



          "Apakah Anda yakin ingin menghapus ${kost.nama}?",



        ),








        actions: [





          TextButton(



            onPressed:(){



              Navigator.pop(context);



            },





            child:

            const Text(



              "Batal",



            ),



          ),







          TextButton(



            onPressed:(){



              Navigator.pop(context);







              // sementara lokal

              // nanti diganti:

              // DELETE DATA SUPABASE





              ScaffoldMessenger.of(context)

              .showSnackBar(





                SnackBar(



                  content:

                  Text(



                    "${kost.nama} berhasil dihapus",



                  ),





                  backgroundColor:

                  AppColors.success,



                ),





              );





            },





            child:

            const Text(



              "Hapus",



              style:

              TextStyle(



                color:

                AppColors.error,



              ),



            ),





          ),





        ],





      );



    },



  );


}











// ============================================================
// INFO MANAJEMEN KAMAR
// ============================================================


Widget _buildManajemenKamarInfo(){



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





        const Icon(



          Icons.info_outline,



          size:

          20,



          color:

          AppColors.primary,



        ),







        const SizedBox(width:10),







        const Expanded(



          child:

          Column(



            crossAxisAlignment:

            CrossAxisAlignment.start,



            children: [





              Text(



                "Manajemen Kamar",



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



                "Perbarui data ketersediaan kamar secara berkala untuk memudahkan calon penghuni menemukan unit Anda.",



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
// BOTTOM NAVIGATION
// ============================================================


Widget _buildBottomNav(

    BuildContext context

){



  return Container(



    decoration:

    const BoxDecoration(



      color:

      AppColors.white,



      border:



      Border(



        top:

        BorderSide(



          color:

          AppColors.border,



        ),



      ),



    ),





    child:

    SafeArea(



      child:

      Row(



        mainAxisAlignment:

        MainAxisAlignment.spaceAround,



        children: [





          _buildNavItem(



            context,



            Icons.home_outlined,



            "Home",



            false,



          ),







          _buildNavItem(



            context,



            Icons.apartment,



            "Data Kost",



            true,



          ),







          _buildNavItem(



            context,



            Icons.chat_bubble_outline,



            "Chat",



            false,



          ),







          _buildNavItem(



            context,



            Icons.person_outline,



            "Profil",



            false,



          ),





        ],



      ),



    ),



  );


}











// ============================================================
// NAVIGATION ITEM
// ============================================================


Widget _buildNavItem(



    BuildContext context,



    IconData icon,



    String label,



    bool isActive,



){



  final color = isActive



      ?



  AppColors.primary



      :



  AppColors.textSecondary;







  return GestureDetector(



    onTap:(){





      switch(label){





        case "Home":



          Navigator.pushReplacement(



            context,



            MaterialPageRoute(



              builder:(context)=>



              const HomeAdminPage(),



            ),



          );



          break;








        case "Chat":



          Navigator.pushReplacement(



            context,



            MaterialPageRoute(



              builder:(context)=>



              const DaftarChatAdminPage(chatData: {},),



            ),



          );



          break;








        case "Profil":



          Navigator.pushReplacement(



            context,



            MaterialPageRoute(



              builder:(context)=>



              const ProfilAdminPage(),



            ),



          );



          break;







        case "Data Kost":



          break;





      }



    },







    child:



    Padding(



      padding:



      const EdgeInsets.symmetric(



        vertical:

        8,



      ),





      child:



      Column(



        mainAxisSize:

        MainAxisSize.min,



        children: [





          Icon(



            icon,



            size:

            22,



            color:

            color,



          ),





          const SizedBox(height:3),






          Text(



            label,



            style:

            TextStyle(



              fontSize:

              10,



              color:

              color,



              fontWeight:



              isActive



                  ?



              FontWeight.w600



                  :



              FontWeight.normal,



            ),



          ),





        ],



      ),



    ),



  );


}



}
