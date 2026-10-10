import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

import 'home_admin_page.dart';
import 'data_kost_page.dart';
import 'daftar_chat_admin_page.dart';




// ============================================================
// PROFIL ADMIN PAGE
// ============================================================


class ProfilAdminPage extends StatefulWidget {


  const ProfilAdminPage({


    super.key,


  });







  @override
  State<ProfilAdminPage> createState() =>

      _ProfilAdminPageState();



}









class _ProfilAdminPageState

extends State<ProfilAdminPage>{





  // ============================================================
  // DATA ADMIN SEMENTARA
  // NANTI DIGANTI SUPABASE USER
  // ============================================================



  final Map<String,dynamic> admin = {



    "id_user":

    "admin-001",






    "username":

    "Admin KostRadar",






    "email":

    "admin@kostradar.com",






    "foto_profile":

    "",






    "role":

    "admin",





  };









  @override

  Widget build(BuildContext context){



    final username =

    admin['username'] ?? "Admin";






    final email =

    admin['email'] ?? "-";






    final fotoProfile =

    admin['foto_profile'] ?? "";







    return Scaffold(



      backgroundColor:

      AppColors.background,







      body:

      SafeArea(



        child:

        Column(



          children: [





            _buildHeader(),







            Expanded(



              child:

              SingleChildScrollView(



                padding:

                const EdgeInsets.fromLTRB(



                  20,

                  20,

                  20,

                  90,



                ),







                child:

                Column(



                  crossAxisAlignment:

                  CrossAxisAlignment.start,



                  children: [







                    const Text(



                      "Profil",



                      style:

                      TextStyle(



                        fontSize:

                        28,



                        fontWeight:

                        FontWeight.bold,



                        color:

                        AppColors.textPrimary,



                      ),



                    ),







                    const SizedBox(height:6),







                    const Text(



                      "Kelola informasi akun admin Anda",



                      style:

                      TextStyle(



                        fontSize:

                        14,



                        color:

                        AppColors.textSecondary,



                      ),



                    ),







                    const SizedBox(height:24),







                    _buildProfileCard(



                      username,



                      email,



                      fotoProfile,



                    ),







                    const SizedBox(height:24),







                    const Text(



                      "Pengaturan Akun",



                      style:

                      TextStyle(



                        fontSize:

                        18,



                        fontWeight:

                        FontWeight.bold,



                        color:

                        AppColors.textPrimary,



                      ),



                    ),







                    const SizedBox(height:12),







                    _buildSettingItem(



                      icon:

                      Icons.lock_outline,



                      title:

                      "Ubah Password",



                      subtitle:

                      "Perbarui password akun admin",



                      onTap:

                      _showChangePassword,



                    ),







                    const SizedBox(height:10),







                    _buildSettingItem(



                      icon:

                      Icons.logout_outlined,



                      title:

                      "Logout",



                      subtitle:

                      "Keluar dari akun admin",



                      iconColor:

                      AppColors.error,



                      titleColor:

                      AppColors.error,



                      onTap:

                      _showLogoutConfirmation,



                    ),







                  ],



                ),



              ),



            ),





          ],



        ),



      ),







      bottomNavigationBar:

      _buildBottomNav(),





    );



  }

  // ============================================================
// HEADER
// ============================================================


Widget _buildHeader(){



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



          "Profil Admin",



          style:

          TextStyle(



            fontSize:

            20,



            fontWeight:

            FontWeight.bold,



            color:

            AppColors.textPrimary,



          ),



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



            Icons.person_outline,



            color:

            AppColors.primary,



          ),





        ),





      ],



    ),



  );


}











// ============================================================
// PROFILE CARD
// ============================================================


Widget _buildProfileCard(



    String username,



    String email,



    String fotoProfile,



){



  return Container(



    width:

    double.infinity,





    padding:

    const EdgeInsets.all(18),





    decoration:

    BoxDecoration(



      color:

      AppColors.white,



      borderRadius:

      BorderRadius.circular(18),







      border:

      Border.all(



        color:

        AppColors.border,



      ),



    ),







    child:

    Column(



      children: [





        Stack(



          children: [





            Container(



              width:

              90,



              height:

              90,







              decoration:

              BoxDecoration(



                shape:

                BoxShape.circle,



                color:

                AppColors.primaryLight,



              ),





              child:

              fotoProfile.isNotEmpty



                  ?



              ClipOval(



                child:

                Image.network(



                  fotoProfile,



                  fit:

                  BoxFit.cover,



                  width:

                  90,



                  height:

                  90,



                ),



              )



                  :



              const Icon(



                Icons.person,



                size:

                45,



                color:

                AppColors.primary,



              ),





            ),







            Positioned(



              right:

              0,



              bottom:

              0,





              child:

              GestureDetector(



                onTap:

                _editProfile,







                child:

                Container(



                  width:

                  30,



                  height:

                  30,







                  decoration:

                  const BoxDecoration(



                    color:

                    AppColors.primary,



                    shape:

                    BoxShape.circle,



                  ),





                  child:

                  const Icon(



                    Icons.edit,



                    size:

                    15,



                    color:

                    AppColors.white,



                  ),





                ),



              ),



            ),





          ],



        ),







        const SizedBox(height:16),







        Text(



          username,



          style:

          const TextStyle(



            fontSize:

            18,



            fontWeight:

            FontWeight.bold,



            color:

            AppColors.textPrimary,



          ),



        ),







        const SizedBox(height:6),







        Text(



          email,



          style:

          const TextStyle(



            fontSize:

            13,



            color:

            AppColors.textSecondary,



          ),



        ),







        const SizedBox(height:14),







        Container(



          padding:

          const EdgeInsets.symmetric(



            horizontal:

            14,



            vertical:

            6,



          ),







          decoration:

          BoxDecoration(



            color:

            AppColors.primaryLight,



            borderRadius:

            BorderRadius.circular(20),



          ),





          child:

          const Text(



            "ADMIN",



            style:

            TextStyle(



              fontSize:

              11,



              fontWeight:

              FontWeight.bold,



              color:

              AppColors.primary,



            ),



          ),





        ),





      ],



    ),



  );


}









// ============================================================
// EDIT PROFILE
// ============================================================


void _editProfile(){



  showDialog(



    context:

    context,



    builder:(context){



      return AlertDialog(



        title:

        const Text(



          "Edit Profil",



        ),







        content:

        const Text(



          "Fitur edit profil dapat digunakan untuk memperbarui data admin.",



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


}

// ============================================================
// SETTING ITEM
// ============================================================


Widget _buildSettingItem({



  required IconData icon,



  required String title,



  required String subtitle,



  required VoidCallback onTap,



  Color iconColor = AppColors.primary,



  Color titleColor = AppColors.textPrimary,



}){



  return GestureDetector(



    onTap:

    onTap,







    child:

    Container(



      padding:

      const EdgeInsets.all(14),







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

            42,



            height:

            42,







            decoration:

            BoxDecoration(



              color:

              iconColor.withOpacity(0.1),



              borderRadius:

              BorderRadius.circular(12),



            ),





            child:

            Icon(



              icon,



              color:

              iconColor,



              size:

              22,



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



                  title,



                  style:

                  TextStyle(



                    fontSize:

                    14,



                    fontWeight:

                    FontWeight.w600,



                    color:

                    titleColor,



                  ),



                ),







                const SizedBox(height:4),







                Text(



                  subtitle,



                  style:

                  const TextStyle(



                    fontSize:

                    12,



                    color:

                    AppColors.textSecondary,



                  ),



                ),





              ],



            ),



          ),







          Icon(



            Icons.arrow_forward_ios,



            size:

            15,



            color:

            AppColors.textSecondary,



          ),





        ],



      ),



    ),



  );


}











// ============================================================
// CHANGE PASSWORD
// ============================================================


void _showChangePassword(){



  final passwordController =

  TextEditingController();







  showDialog(



    context:

    context,



    builder:(context){



      return AlertDialog(



        title:

        const Text(



          "Ubah Password",



        ),







        content:

        TextField(



          controller:

          passwordController,



          obscureText:

          true,







          decoration:

          InputDecoration(



            hintText:

            "Password baru",



            border:

            OutlineInputBorder(



              borderRadius:

              BorderRadius.circular(10),



            ),



          ),



        ),







        actions:[





          TextButton(



            onPressed:(){



              Navigator.pop(context);



            },





            child:

            const Text(



              "Batal",



            ),



          ),







          ElevatedButton(



            onPressed:(){



              Navigator.pop(context);







              ScaffoldMessenger.of(context)

                  .showSnackBar(



                const SnackBar(



                  content:

                  Text(



                    "Password berhasil diperbarui",



                  ),



                ),



              );



            },





            child:

            const Text(



              "Simpan",



            ),



          ),





        ],





      );



    },



  );


}











// ============================================================
// LOGOUT CONFIRMATION
// ============================================================


void _showLogoutConfirmation(){



  showDialog(



    context:

    context,



    builder:(context){



      return AlertDialog(



        title:

        const Text(



          "Logout",



        ),







        content:

        const Text(



          "Apakah Anda yakin ingin keluar dari akun admin?",



        ),







        actions:[





          TextButton(



            onPressed:(){



              Navigator.pop(context);



            },





            child:

            const Text(



              "Batal",



            ),



          ),







          ElevatedButton(



            onPressed:(){



              Navigator.pop(context);







              Navigator.pushReplacement(



                context,



                MaterialPageRoute(



                  builder:(context)=>



                  const HomeAdminPage(),



                ),



              );



            },





            style:

            ElevatedButton.styleFrom(



              backgroundColor:

              AppColors.error,



              foregroundColor:

              AppColors.white,



            ),





            child:

            const Text(



              "Logout",



            ),



          ),





        ],





      );



    },



  );


}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================


Widget _buildBottomNav(){



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



            Icons.home_outlined,



            "Home",



            false,



          ),







          _buildNavItem(



            Icons.apartment_outlined,



            "Data Kost",



            false,



          ),







          _buildNavItem(



            Icons.chat_bubble_outline,



            "Chat",



            false,



          ),







          _buildNavItem(



            Icons.person,



            "Profil",



            true,



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



    IconData icon,



    String label,



    bool active,



){





  final color = active



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









        case "Data Kost":



          Navigator.pushReplacement(



            context,



            MaterialPageRoute(



              builder:(context)=>



              const DataKostPage(),



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







          const SizedBox(height:4),







          Text(



            label,



            style:

            TextStyle(



              fontSize:

              10,



              fontWeight:



              active



                  ?



              FontWeight.w600



                  :



              FontWeight.normal,



              color:

              color,



            ),



          ),





        ],



      ),



    ),



  );
}
}