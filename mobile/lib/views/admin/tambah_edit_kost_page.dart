import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

// ============================================================
// TAMBAH / EDIT KOST PAGE (Terintegrasi Supabase Storage & Database)
// ============================================================

class TambahEditKostPage extends StatefulWidget {
  final Map<String, dynamic>? kostData;

  const TambahEditKostPage({super.key, this.kostData});

  @override
  State<TambahEditKostPage> createState() => _TambahEditKostPageState();
}

class _TambahEditKostPageState extends State<TambahEditKostPage> {
  static const int maxFoto = 5;
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController namaController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController ketersediaanController = TextEditingController();

  bool _isLoading = false;

  // List menampung file foto yang dipilih dari galeri
  final List<XFile> fotoTerunggah = [];

  @override
  void initState() {
    super.initState();

    if (widget.kostData != null) {
      namaController.text = widget.kostData!['nama'] ?? '';
      hargaController.text = widget.kostData!['harga'] != null
          ? widget.kostData!['harga'].toString().split('.').first
          : '';
      alamatController.text = widget.kostData!['alamat'] ?? '';
      ketersediaanController.text = widget.kostData!['ketersediaan_kamar'] != null
          ? widget.kostData!['ketersediaan_kamar'].toString()
          : '1';
    } else {
      namaController.text = 'Kost Adiwarna Eksklusif';
      hargaController.text = '1200000';
      alamatController.text = 'Jl. Gegerkalong Hilir No.12, Sukasari, Bandung';
      ketersediaanController.text = '3';
    }
  }

  @override
  void dispose() {
    namaController.dispose();
    hargaController.dispose();
    alamatController.dispose();
    ketersediaanController.dispose();
    super.dispose();
  }

  // Fungsi membuka galeri untuk memilih foto
  Future<void> _pickImage() async {
    if (fotoTerunggah.length >= maxFoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maksimal 5 foto yang dapat diunggah"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          fotoTerunggah.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memilih foto: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormInfo(),
                    const SizedBox(height: 18),
                    _buildFieldLabel("Foto Unit Kost"),
                    const SizedBox(height: 8),
                    _buildUploadBox(),
                    const SizedBox(height: 10),
                    if (fotoTerunggah.isNotEmpty) _buildFotoThumbnailRow(),
                    const SizedBox(height: 20),
                    _buildFieldLabel("Nama Kost"),
                    _buildTextField(
                      controller: namaController,
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel("Harga Kost"),
                    _buildHargaField(),
                    const SizedBox(height: 16),
                    _buildFieldLabel("Ketersediaan Kamar (Jumlah)"),
                    _buildTextField(
                      controller: ketersediaanController,
                      icon: Icons.meeting_room_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel("Alamat / Lokasi Lengkap"),
                    _buildTextField(
                      controller: alamatController,
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
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

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: AppColors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const Expanded(
            child: Text(
              "Tambah / Edit Kost",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Informasi"),
                    content: const Text(
                      "Lengkapi data kost dengan benar agar mudah ditemukan calon penghuni.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("OK"),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.help_outline,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO FORM
  // ============================================================

  Widget _buildFormInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.home_work_outlined,
              color: AppColors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Formulir Unit Kost",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Lengkapi data akurat properti Anda agar mahasiswa mudah menemukan dan memilih kamar sesuai kebutuhan.",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
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

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // ============================================================
  // UPLOAD FOTO BOX
  // ============================================================

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tambah Foto Kost",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Maksimal $maxFoto foto",
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
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

  Widget _buildFotoThumbnailRow() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fotoTerunggah.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(File(fotoTerunggah[index].path)),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 4,
                  top: 4,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        fotoTerunggah.removeAt(index);
                      });
                    },
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: AppColors.white,
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  // ============================================================
  // HARGA FIELD
  // ============================================================

  Widget _buildHargaField() {
    return TextField(
      controller: hargaController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixText: "Rp ",
        prefixIcon: const Icon(
          Icons.payments_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON SIMPAN DATA KOST
  // ============================================================

  Widget _buildSimpanButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      color: AppColors.white,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveKost,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  widget.kostData == null
                      ? "Simpan Data Kost"
                      : "Perbarui Data Kost",
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // ============================================================
  // SIMPAN KE SUPABASE & UPLOAD FOTO KE STORAGE
  // ============================================================

  Future<void> _saveKost() async {
    if (namaController.text.trim().isEmpty ||
        hargaController.text.trim().isEmpty ||
        alamatController.text.trim().isEmpty ||
        ketersediaanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap lengkapi semua data kost"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool isEdit = widget.kostData != null;
      final double harga = double.parse(hargaController.text.trim());
      final int ketersediaan = int.parse(ketersediaanController.text.trim());

      final Map<String, dynamic> dataToSave = {
        "nama": namaController.text.trim(),
        "harga": harga,
        "alamat": alamatController.text.trim(),
        "ketersediaan_kamar": ketersediaan,
      };

      String idKostTujuan = '';

      if (isEdit) {
        idKostTujuan = widget.kostData!['id_kost']?.toString() ?? 
                       widget.kostData!['id']?.toString() ?? '';
                       
        if (idKostTujuan.isNotEmpty) {
          await supabase.from('kost').update(dataToSave).eq('id_kost', idKostTujuan);
        } else {
          throw Exception("ID Kost tidak ditemukan.");
        }
      } else {
        final response = await supabase
            .from('kost')
            .insert(dataToSave)
            .select('id_kost')
            .single();
            
        idKostTujuan = response['id_kost']?.toString() ?? '';
      }

      // UPLOAD FOTO KE SUPABASE STORAGE BUCKET 'kost-images'
      if (idKostTujuan.isNotEmpty && fotoTerunggah.isNotEmpty) {
        if (isEdit) {
          await supabase.from('foto_kost').delete().eq('id_kost', idKostTujuan);
        }

        for (int i = 0; i < fotoTerunggah.length; i++) {
          final fileX = fotoTerunggah[i];
          final bytes = await fileX.readAsBytes();
          final fileExt = fileX.name.split('.').last;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$fileExt';
          final filePath = 'kost_$idKostTujuan/$fileName';

          // 1. Upload file binary ke Supabase Storage
          await supabase.storage.from('kost-images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true),
          );

          // 2. Ambil Public URL gambar
          final imageUrl = supabase.storage.from('kost-images').getPublicUrl(filePath);

          // 3. Simpan Public URL ke tabel 'foto_kost'
          await supabase.from('foto_kost').insert({
            "id_kost": idKostTujuan,
            "foto": imageUrl,
          });
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(isEdit ? "Berhasil Memperbarui" : "Berhasil Menambahkan"),
            content: Text(
              isEdit
                  ? "Data kost beserta foto berhasil diperbarui."
                  : "Data kost baru beserta foto berhasil disimpan.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan data: $e"),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}