// ignore_for_file: unused_import

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

import 'home_admin_page.dart';
import 'data_kost_page.dart';
import 'profil_admin_page.dart';
import 'daftar_chat_admin_page.dart';




// ============================================================
// DAFTAR CHAT ADMIN
// ============================================================


class DaftarChatAdminPage extends StatefulWidget {


  const DaftarChatAdminPage({

    super.key, required Map<String, dynamic> chatData,

  });




  @override
  State<DaftarChatAdminPage> createState() =>

      _DaftarChatAdminPageState();



}








class _DaftarChatAdminPageState

extends State<DaftarChatAdminPage> {



  final TextEditingController searchController =

  TextEditingController();




  int selectedTab = 0;






  final List<Map<String,dynamic>> chats = [



    {


      "id": "1",


      "nama": "Alya Putri",


      "email": "alya@gmail.com",


      "kost": "Kost Adiwarna",


      "pesan": "Apakah kamar masih tersedia?",


      "waktu": "10:30",


      "unread": true,


    },






    {


      "id": "2",


      "nama": "Budi Santoso",


      "email": "budi@gmail.com",


      "kost": "Kost Melati",


      "pesan": "Saya ingin melakukan survey kamar.",


      "waktu": "09:20",


      "unread": false,


    },






    {


      "id": "3",


      "nama": "Siti Rahma",


      "email": "siti@gmail.com",


      "kost": "Kost Cemara",


      "pesan": "Apakah bisa booking minggu ini?",


      "waktu": "Kemarin",


      "unread": true,


    },


  ];








  List<Map<String,dynamic>> get filteredChats {



    List<Map<String,dynamic>> result =

    List.from(chats);






    if(selectedTab == 1){



      result = result.where((item){



        return item["unread"] == true;



      }).toList();



    }






    final keyword =

    searchController.text

        .toLowerCase();






    if(keyword.isNotEmpty){



      result = result.where((item){



        return

          item["nama"]

              .toString()

              .toLowerCase()

              .contains(keyword)

              ||

              item["pesan"]

                  .toString()

                  .toLowerCase()

                  .contains(keyword);



      }).toList();



    }





    return result;



  }








  @override

  void dispose(){


    searchController.dispose();


    super.dispose();


  }

  // ============================================================
// BUILD PAGE
// ============================================================


@override
Widget build(BuildContext context){


  return Scaffold(



    backgroundColor:

    AppColors.background,





    body:

    SafeArea(



      child:

      Column(



        children: [





          _buildHeader(),







          _buildSearch(),







          _buildTabs(),







          Expanded(



            child:

            _buildChatList(),



          ),





        ],



      ),



    ),







    bottomNavigationBar:

    _buildBottomNav(context),





  );


}









// ============================================================
// HEADER
// ============================================================


Widget _buildHeader(){



  return Container(



    padding:

    const EdgeInsets.all(16),





    color:

    AppColors.white,





    child:

    Row(



      mainAxisAlignment:

      MainAxisAlignment.spaceBetween,



      children: [





        const Column(



          crossAxisAlignment:

          CrossAxisAlignment.start,



          children: [





            Text(



              "Daftar Chat",



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







            SizedBox(height:4),







            Text(



              "Komunikasi dengan calon penghuni",



              style:

              TextStyle(



                fontSize:

                12,



                color:

                AppColors.textSecondary,



              ),



            ),





          ],



        ),







        Container(



          width:

          40,



          height:

          40,





          decoration:

          BoxDecoration(



            color:

            AppColors.primaryLight,



            borderRadius:

            BorderRadius.circular(12),



          ),





          child:

          const Icon(



            Icons.chat_outlined,



            color:

            AppColors.primary,



          ),





        ),





      ],



    ),



  );


}











// ============================================================
// SEARCH
// ============================================================


Widget _buildSearch(){



  return Padding(



    padding:

    const EdgeInsets.all(16),





    child:

    TextField(



      controller:

      searchController,







      onChanged:(value){



        setState(() {});



      },







      decoration:

      InputDecoration(



        hintText:

        "Cari nama atau pesan...",







        prefixIcon:

        const Icon(



          Icons.search,



          color:

          AppColors.textSecondary,



        ),







        suffixIcon:

        searchController.text.isNotEmpty



            ?



        IconButton(



          icon:

          const Icon(



            Icons.close,



          ),



          onPressed:(){



            searchController.clear();



            setState(() {});



          },



        )



            :



        null,







        filled:

        true,



        fillColor:

        AppColors.white,









        border:

        OutlineInputBorder(



          borderRadius:

          BorderRadius.circular(14),



          borderSide:

          BorderSide.none,



        ),





      ),



    ),



  );


}











// ============================================================
// TAB
// ============================================================


Widget _buildTabs(){



  return Container(



    margin:

    const EdgeInsets.symmetric(



      horizontal:

      16,



    ),





    padding:

    const EdgeInsets.all(4),





    decoration:

    BoxDecoration(



      color:

      AppColors.white,



      borderRadius:

      BorderRadius.circular(12),



    ),





    child:

    Row(



      children: [





        _buildTabButton(



          "Semua",



          0,



        ),







        _buildTabButton(



          "Belum Dibaca",



          1,



        ),





      ],



    ),



  );


}









Widget _buildTabButton(



    String text,



    int index,



){



  final active =

      selectedTab == index;







  return Expanded(



    child:

    GestureDetector(



      onTap:(){



        setState(() {



          selectedTab = index;



        });



      },





      child:

      Container(



        padding:

        const EdgeInsets.symmetric(



          vertical:

          10,



        ),





        decoration:

        BoxDecoration(



          color:



          active



              ?



          AppColors.primary



              :



          Colors.transparent,



          borderRadius:

          BorderRadius.circular(10),



        ),





        child:

        Text(



          text,



          textAlign:

          TextAlign.center,



          style:

          TextStyle(



            fontSize:

            12,



            fontWeight:

            FontWeight.w600,



            color:



            active



                ?



            AppColors.white



                :



            AppColors.textSecondary,



          ),



        ),



      ),



    ),



  );


}









// ============================================================
// CHAT LIST
// ============================================================


Widget _buildChatList(){



  final data = filteredChats;







  if(data.isEmpty){



    return const Center(



      child:

      Text(



        "Belum ada chat",



        style:

        TextStyle(



          color:

          AppColors.textSecondary,



        ),



      ),



    );



  }







  return ListView.builder(



    padding:

    const EdgeInsets.all(16),





    itemCount:

    data.length,





    itemBuilder:(context,index){



      return _buildChatCard(



        context,



        data[index],



      );



    },



  );


}

// ============================================================
// CHAT CARD
// ============================================================


Widget _buildChatCard(



    BuildContext context,



    Map<String,dynamic> chat,



){



  return GestureDetector(



    onTap:(){



      Navigator.push(



        context,



        MaterialPageRoute(



          builder:(context)=>



          DaftarChatAdminPage(



            chatData: chat,



          ),



        ),



      );



    },







    child:

    Container(



      margin:

      const EdgeInsets.only(



        bottom:

        12,



      ),







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





          _buildAvatar(



            chat["nama"].toString(),



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





                    Expanded(



                      child:

                      Text(



                        chat["nama"].toString(),







                        maxLines:

                        1,



                        overflow:

                        TextOverflow.ellipsis,







                        style:

                        TextStyle(



                          fontSize:

                          14,



                          fontWeight:



                          chat["unread"] == true



                              ?



                          FontWeight.bold



                              :



                          FontWeight.w600,



                          color:

                          AppColors.textPrimary,



                        ),



                      ),



                    ),







                    Text(



                      chat["waktu"].toString(),







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







                const SizedBox(height:6),







                Text(



                  chat["kost"].toString(),







                  style:

                  const TextStyle(



                    fontSize:

                    11,



                    color:

                    AppColors.primary,



                    fontWeight:

                    FontWeight.w500,



                  ),



                ),







                const SizedBox(height:5),







                Row(



                  children: [





                    Expanded(



                      child:

                      Text(



                        chat["pesan"].toString(),







                        maxLines:

                        1,



                        overflow:

                        TextOverflow.ellipsis,







                        style:

                        TextStyle(



                          fontSize:

                          12,



                          color:



                          chat["unread"] == true



                              ?



                          AppColors.textPrimary



                              :



                          AppColors.textSecondary,



                          fontWeight:



                          chat["unread"] == true



                              ?



                          FontWeight.w600



                              :



                          FontWeight.normal,



                        ),



                      ),



                    ),







                    if(chat["unread"] == true)



                      Container(



                        width:

                        8,



                        height:

                        8,





                        decoration:

                        const BoxDecoration(



                          color:

                          AppColors.primary,



                          shape:

                          BoxShape.circle,



                        ),



                      ),





                  ],



                ),





              ],



            ),



          ),





        ],



      ),



    ),



  );


}









// ============================================================
// AVATAR
// ============================================================


Widget _buildAvatar(

    String name

){



  String initial =

      name.isNotEmpty



          ?



      name.substring(0,1).toUpperCase()



          :



      "?";







  return Container(



    width:

    48,



    height:

    48,







    decoration:

    BoxDecoration(



      color:

      AppColors.primaryLight,



      shape:

      BoxShape.circle,



    ),





    child:

    Center(



      child:

      Text(



        initial,







        style:

        const TextStyle(



          fontSize:

          18,



          fontWeight:

          FontWeight.bold,



          color:

          AppColors.primary,



        ),



      ),



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



            Icons.apartment_outlined,



            "Data Kost",



            false,



          ),







          _buildNavItem(



            context,



            Icons.chat_bubble,



            "Chat",



            true,



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



  final Color color = isActive



      ?



  AppColors.primary



      :



  AppColors.textSecondary;







  return GestureDetector(



    onTap:(){





      if(label == "Home"){





        Navigator.pushReplacement(



          context,



          MaterialPageRoute(



            builder:(context)=>



            const HomeAdminPage(),



          ),



        );





      }







      else if(label == "Data Kost"){





        Navigator.pushReplacement(



          context,



          MaterialPageRoute(



            builder:(context)=>



            const DataKostPage(),



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