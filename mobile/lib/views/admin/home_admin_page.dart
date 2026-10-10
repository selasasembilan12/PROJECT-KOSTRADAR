import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

import 'data_kost_page.dart';
import 'daftar_chat_admin_page.dart';
import 'profil_admin_page.dart';
import 'tambah_edit_kost_page.dart';



// ============================================================
// HALAMAN HOME ADMIN
// ============================================================


class HomeAdminPage extends StatelessWidget {


  const HomeAdminPage({

    super.key,

  });



  @override
  Widget build(BuildContext context) {


    return const AdminHomeView();


  }


}







class AdminHomeView extends StatelessWidget {


  const AdminHomeView({

    super.key,

  });







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





            _buildTopBar(),





            Expanded(



              child:

              SingleChildScrollView(



                padding:

                const EdgeInsets.fromLTRB(

                  16,

                  8,

                  16,

                  16,

                ),





                child:

                Column(



                  crossAxisAlignment:

                  CrossAxisAlignment.start,



                  children: [





                    _buildRingkasanPropertiCard(),





                    const SizedBox(height:16),





                    _buildKelolaUnitButton(

                      context,

                    ),





                    const SizedBox(height:20),





                    _buildKostTerbaruHeader(

                      context,

                    ),





                    const SizedBox(height:10),





                    _buildKostItem(



                      nama:

                      'Kost Adiwarna',



                      harga:

                      'Rp 1.200.000',



                      waktu:

                      '11:30',



                      status:

                      'Tersedia 3 kamar',



                    ),





                    const SizedBox(height:10),





                    _buildKostItem(



                      nama:

                      'Kost Melati',



                      harga:

                      'Rp 1.000.000',



                      waktu:

                      '11:30',



                      status:

                      null,



                    ),




                  ],



                ),



              ),



            ),



          ],



        ),



      ),







      bottomNavigationBar:



      _buildBottomNav(

        context,

      ),



    );



  }

// ============================================================
// TOP BAR
// ============================================================


Widget _buildTopBar() {


  return Container(


    padding:

    const EdgeInsets.fromLTRB(

      16,

      8,

      16,

      12,

    ),


    color:

    AppColors.white,



    child:

    Column(


      crossAxisAlignment:

      CrossAxisAlignment.start,


      children: [



        Row(


          children: [



            Container(


              width:

              22,


              height:

              22,


              decoration:

              BoxDecoration(


                color:

                AppColors.primary,


                borderRadius:

                BorderRadius.circular(6),


              ),



              child:

              const Icon(


                Icons.radar,


                size:

                14,


                color:

                AppColors.white,


              ),


            ),




            const SizedBox(width:6),





            const Text(


              'KOSTRADAR ADMIN',



              style:

              TextStyle(


                fontSize:

                11,


                fontWeight:

                FontWeight.w600,


                color:

                AppColors.textSecondary,


                letterSpacing:

                0.5,


              ),



            ),



          ],


        ),




        const SizedBox(height:4),





        Row(


          mainAxisAlignment:

          MainAxisAlignment.spaceBetween,



          children: [



            const Text(


              'Home',



              style:

              TextStyle(


                fontSize:

                24,


                fontWeight:

                FontWeight.bold,


                color:

                AppColors.textPrimary,


              ),


            ),





            const CircleAvatar(



              radius:

              18,



              backgroundColor:

              AppColors.primary,



              child:

              Icon(


                Icons.person,


                color:

                AppColors.white,


                size:

                20,


              ),



            ),



          ],


        ),



      ],



    ),



  );


}









// ============================================================
// RINGKASAN PROPERTI
// ============================================================


Widget _buildRingkasanPropertiCard() {



  return Container(



    width:

    double.infinity,



    padding:

    const EdgeInsets.all(16),




    decoration:

    BoxDecoration(



      color:

      AppColors.white,



      borderRadius:

      BorderRadius.circular(16),



      border:

      Border.all(



        color:

        AppColors.border,



      ),



    ),





    child:

    Column(



      crossAxisAlignment:

      CrossAxisAlignment.start,



      children: [





        Row(



          mainAxisAlignment:

          MainAxisAlignment.spaceBetween,



          children: [



            const Column(



              crossAxisAlignment:

              CrossAxisAlignment.start,



              children: [



                Text(



                  'Ringkasan Properti',



                  style:

                  TextStyle(



                    fontSize:

                    15,



                    fontWeight:

                    FontWeight.bold,



                    color:

                    AppColors.textPrimary,



                  ),



                ),






                SizedBox(height:2),






                Text(



                  'Pantau aktivitas kost dan calon penghuni hari ini',



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




            _buildStatusBadge(

              'Aktif',

            ),



          ],



        ),





        const SizedBox(height:16),






        Row(



          children: [





            Expanded(



              child:

              _buildStatCard(



                icon:

                Icons.apartment,



                iconColor:

                AppColors.primary,



                value:

                '12',



                label:

                'Total Kost',



                trailing:

                _buildTrendBadge(

                  '+2',

                ),



              ),



            ),






            const SizedBox(width:10),






            Expanded(



              child:

              _buildStatCard(



                icon:

                Icons.meeting_room,



                iconColor:

                AppColors.success,



                value:

                '8',



                label:

                'Kamar Tersedia',



                trailingText:

                'Siap huni',



              ),



            ),



          ],



        ),





        const SizedBox(height:10),






        Row(



          children: [





            Expanded(



              child:

              _buildStatCard(



                icon:

                Icons.mail_outline,



                iconColor:

                AppColors.primary,



                value:

                '4',



                label:

                'Pesan Masuk',



                trailing:

                _buildDot(),



              ),



            ),






            const SizedBox(width:10),






            Expanded(



              child:

              _buildStatCard(



                icon:

                Icons.chat_bubble_outline,



                iconColor:

                AppColors.primary,



                value:

                '25',



                label:

                'Total Chat',



                trailingText:

                'Bulan ini',



              ),



            ),



          ],



        ),





      ],



    ),



  );


}









// ============================================================
// STATUS BADGE
// ============================================================


Widget _buildStatusBadge(String text){


  return Container(



    padding:

    const EdgeInsets.symmetric(



      horizontal:

      10,



      vertical:

      4,



    ),



    decoration:

    BoxDecoration(



      color:

      AppColors.success.withOpacity(0.12),



      borderRadius:

      BorderRadius.circular(20),



    ),





    child:

    Row(



      mainAxisSize:

      MainAxisSize.min,



      children: [



        Container(



          width:

          6,



          height:

          6,



          decoration:

          const BoxDecoration(



            color:

            AppColors.success,



            shape:

            BoxShape.circle,



          ),



        ),




        const SizedBox(width:5),





        Text(



          text,



          style:

          const TextStyle(



            fontSize:

            11,



            fontWeight:

            FontWeight.w600,



            color:

            AppColors.success,



          ),



        ),



      ],



    ),



  );


}









// ============================================================
// STAT CARD
// ============================================================


Widget _buildStatCard({



  required IconData icon,



  required Color iconColor,



  required String value,



  required String label,



  Widget? trailing,



  String? trailingText,



}) {



  return Container(



    padding:

    const EdgeInsets.all(12),



    decoration:

    BoxDecoration(



      color:

      AppColors.backgroundLight,



      borderRadius:

      BorderRadius.circular(12),



    ),





    child:

    Column(



      crossAxisAlignment:

      CrossAxisAlignment.start,



      children: [





        Row(



          mainAxisAlignment:

          MainAxisAlignment.spaceBetween,



          children: [



            Icon(



              icon,



              color:

              iconColor,



              size:

              20,



            ),





            if(trailing != null)

              trailing,





            if(trailingText != null)

              Text(



                trailingText,



                style:

                const TextStyle(



                  fontSize:

                  10,



                  color:

                  AppColors.textSecondary,



                ),



              ),



          ],



        ),






        const SizedBox(height:8),






        Text(



          value,



          style:

          const TextStyle(



            fontSize:

            20,



            fontWeight:

            FontWeight.bold,



            color:

            AppColors.textPrimary,



          ),



        ),






        Text(



          label,



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



  );


}









Widget _buildTrendBadge(String text){


  return Text(



    text,



    style:

    const TextStyle(



      fontSize:

      11,



      fontWeight:

      FontWeight.w600,



      color:

      AppColors.success,



    ),



  );


}









Widget _buildDot(){


  return Container(



    width:

    6,



    height:

    6,



    decoration:

    const BoxDecoration(



      color:

      AppColors.primary,



      shape:

      BoxShape.circle,



    ),



  );


}

// ============================================================
// BUTTON KELOLA UNIT BARU
// ============================================================


Widget _buildKelolaUnitButton(
    BuildContext context
){


  return InkWell(



    onTap:(){



      Navigator.push(



        context,



        MaterialPageRoute(



          builder:(context)=>



          const TambahEditKostPage(),



        ),



      );



    },





    borderRadius:

    BorderRadius.circular(14),





    child:

    Container(



      width:

      double.infinity,



      padding:

      const EdgeInsets.all(14),





      decoration:

      BoxDecoration(



        color:

        AppColors.primary,



        borderRadius:

        BorderRadius.circular(14),



      ),





      child:

      Row(



        children: [





          Container(



            width:

            36,



            height:

            36,



            decoration:

            BoxDecoration(



              color:

              AppColors.white.withOpacity(0.15),



              borderRadius:

              BorderRadius.circular(10),



            ),





            child:

            const Icon(



              Icons.home_work_outlined,



              color:

              AppColors.white,



              size:

              20,



            ),



          ),






          const SizedBox(width:12),





          const Expanded(



            child:

            Column(



              crossAxisAlignment:

              CrossAxisAlignment.start,



              children: [





                Text(



                  'Kelola Unit Baru',



                  style:

                  TextStyle(



                    color:

                    AppColors.white,



                    fontWeight:

                    FontWeight.bold,



                    fontSize:

                    14,



                  ),



                ),






                SizedBox(height:3),






                Text(



                  'Tambahkan kamar & perbarui ketersediaan',



                  style:

                  TextStyle(



                    color:

                    AppColors.white,



                    fontSize:

                    11,



                  ),



                ),





              ],



            ),



          ),





          const Icon(



            Icons.chevron_right,



            color:

            AppColors.white,



          ),





        ],



      ),



    ),



  );


}









// ============================================================
// HEADER KOST TERBARU
// ============================================================


Widget _buildKostTerbaruHeader(

    BuildContext context

){



  return Row(



    mainAxisAlignment:

    MainAxisAlignment.spaceBetween,



    children: [





      const Text(



        'Kost Terbaru',



        style:

        TextStyle(



          fontSize:

          15,



          fontWeight:

          FontWeight.bold,



          color:

          AppColors.textPrimary,



        ),



      ),





      GestureDetector(



        onTap:(){





          Navigator.push(



            context,



            MaterialPageRoute(



              builder:(context)=>



              const DataKostPage(),



            ),



          );



        },





        child:

        Row(



          children: const [





            Text(



              'Lihat Semua',



              style:

              TextStyle(



                fontSize:

                12,



                color:

                AppColors.primary,



                fontWeight:

                FontWeight.w600,



              ),



            ),





            Icon(



              Icons.chevron_right,



              size:

              16,



              color:

              AppColors.primary,



            ),



          ],



        ),



      ),



    ],



  );


}









// ============================================================
// KOST ITEM
// ============================================================


Widget _buildKostItem({



  required String nama,



  required String harga,



  required String waktu,



  required String? status,



}){



  return Container(



    padding:

    const EdgeInsets.all(10),





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



      children: [





        Container(



          width:

          56,



          height:

          56,



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





              Row(



                mainAxisAlignment:

                MainAxisAlignment.spaceBetween,



                children: [





                  Text(



                    nama,



                    style:

                    const TextStyle(



                      fontWeight:

                      FontWeight.bold,



                      fontSize:

                      13,



                      color:

                      AppColors.textPrimary,



                    ),



                  ),






                  Text(



                    waktu,



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





              const SizedBox(height:3),






              Text(



                '$harga/bulan',



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





              if(status != null)

                Row(



                  children: [





                    const Icon(



                      Icons.check_circle,



                      size:

                      12,



                      color:

                      AppColors.success,



                    ),





                    const SizedBox(width:5),






                    Text(



                      status,



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

            Icons.home,

            'Home',

            true,



          ),





          _buildNavItem(



            context,

            Icons.apartment_outlined,

            'Data Kost',

            false,



          ),





          _buildNavItem(



            context,

            Icons.chat_bubble_outline,

            'Chat',

            false,



          ),





          _buildNavItem(



            context,

            Icons.person_outline,

            'Profil',

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



      if(label == "Data Kost"){



        Navigator.pushReplacement(



          context,



          MaterialPageRoute(



            builder:(context)=>



            const DataKostPage(),



          ),



        );



      }







      else if(label == "Chat"){



        Navigator.pushReplacement(



          context,



          MaterialPageRoute(



            builder:(context)=>



            const DaftarChatAdminPage(chatData: {},),



          ),



        );



      }







      else if(label == "Profil"){



        Navigator.pushReplacement(



          context,



          MaterialPageRoute(



            builder:(context)=>



            const ProfilAdminPage(),



          ),



        );



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



            color:

            color,



            size:

            22,



          ),





          const SizedBox(height:2),





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
