import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatter.dart';

class KostFormView extends StatefulWidget {
  const KostFormView({super.key});

  @override
  State<KostFormView> createState() => _KostFormViewState();
}

class _KostFormViewState extends State<KostFormView> {
  static const int _maxFoto = 5;

  final TextEditingController _namaController = TextEditingController(
    text: 'Kost Adiwarna Eksklusif',
  );
  final TextEditingController _hargaController = TextEditingController(
    text: '1.200.000',
  );
  final TextEditingController _alamatController = TextEditingController(
    text: 'Jl. Gegerkalong Hilir No. 12, Sukasari, Bandung /5 menit jalan kaki dari Gerbang Kampus',
  );

  // Placeholder warna, mewakili foto yang sudah diunggah (foto asli diganti lewat image_picker)
  final List<Color> _fotoTerunggah = [
    const Color(0xFFD7C9A6),
    const Color(0xFFB9D8E3),
  ];

  void _hapusFoto(int index) {
    setState(() => _fotoTerunggah.removeAt(index));
  }

  void _tambahFoto() {
    if (_fotoTerunggah.length >= _maxFoto) return;
    setState(() => _fotoTerunggah.add(const Color(0xFFCBD5E0)));
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // <-- DIUBAH (pengganti bgLight)
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormulirInfoCard(),
                    const SizedBox(height: 18),
                    _buildFotoSectionHeader(),
                    const SizedBox(height: 8),
                    _buildUploadBox(),
                    const SizedBox(height: 10),
                    _buildFotoThumbnailRow(),
                    const SizedBox(height: 18),
                    _buildFieldLabel('Nama Kost'),
                    _buildTextField(
                      controller: _namaController,
                      prefixIcon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Harga Kost'),
                    _buildHargaField(),
                    const SizedBox(height: 16),
                    _buildFieldLabel('Alamat / Lokasi Lengkap'),
                    _buildTextField(
                      controller: _alamatController,
                      prefixIcon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
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

  // ---------------- TOP BAR ----------------
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: AppColors.white, // <-- DIUBAH
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back,
              size: 22,
              color: AppColors.textPrimary,
            ), // <-- DIUBAH
          ),
          const Expanded(
            child: Text(
              'Tambah / Edit Kost',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // <-- DIUBAH
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.help_outline,
              size: 22,
              color: AppColors.textSecondary,
            ), // <-- DIUBAH (pengganti textGrey)
          ),
        ],
      ),
    );
  }

  // ---------------- INFO FORMULIR ----------------
  Widget _buildFormulirInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight, // <-- DIUBAH (pengganti infoBg)
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
            ), // <-- DIUBAH
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Formulir Unit Kost',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary, // <-- DIUBAH
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Lengkapi data akurat properti Anda agar mahasiswa mudah menemukan dan memilih kamar sesuai kebutuhan.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors
                        .textSecondary, // <-- DIUBAH (pengganti textGrey)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FOTO SECTION ----------------
  Widget _buildFotoSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildFieldLabel('Foto Unit Kost', bottomPadding: false),
        Text(
          '${_fotoTerunggah.length} dari $_maxFoto Foto',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadBox() {
    return InkWell(
      onTap: _tambahFoto,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.white, // <-- DIUBAH
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
          ), // <-- DIUBAH (pengganti cardBorder)
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primaryLight, // <-- DIUBAH (pengganti infoBg)
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
                size: 20,
              ), // <-- DIUBAH
            ),
            const SizedBox(height: 10),
            const Text(
              'Unggah Foto Kost',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Format JPG, PNG (Maksimal 5MB per file)',
              style: TextStyle(
                fontSize: 11,
                color:
                    AppColors.textSecondary, // <-- DIUBAH (pengganti textGrey)
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:
                    AppColors.successLight, // <-- DIUBAH (pengganti successBg)
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: AppColors.success,
                  ), // <-- DIUBAH
                  SizedBox(width: 5),
                  Text(
                    'Tampak depan, dalam kamar, & fasilitas',
                    style: TextStyle(fontSize: 10, color: AppColors.success),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFotoThumbnailRow() {
    return SizedBox(
      height: 78,
      child: Row(
        children: [
          for (int i = 0; i < _fotoTerunggah.length; i++) ...[
            _buildFotoThumbnail(i),
            const SizedBox(width: 10),
          ],
          if (_fotoTerunggah.length < _maxFoto) _buildTambahFotoThumbnail(),
        ],
      ),
    );
  }

  Widget _buildFotoThumbnail(int index) {
    final isUtama = index == 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: _fotoTerunggah[index],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(6),
          child: isUtama
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Utama',
                    style: TextStyle(
                      color: AppColors.white, // <-- DIUBAH
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _hapusFoto(index),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withOpacity(
                  0.8,
                ), // <-- DIUBAH (pengganti 0xCC000000)
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 12,
                color: AppColors.white,
              ), // <-- DIUBAH
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTambahFotoThumbnail() {
    return InkWell(
      onTap: _tambahFoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 78,
        height: 78,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white, // <-- DIUBAH
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
          ), // <-- DIUBAH (pengganti cardBorder)
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.textSecondary,
              size: 18,
            ), // <-- DIUBAH
            SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ), // <-- DIUBAH
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FORM FIELDS ----------------
  Widget _buildFieldLabel(String label, {bool bottomPadding = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding ? 6 : 0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                AppColors.textPrimary, // <-- DIUBAH (pengganti Colors.black87)
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ), // <-- DIUBAH (pengganti Colors.red)
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white, // <-- DIUBAH
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ), // <-- DIUBAH (pengganti cardBorder)
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(
              prefixIcon,
              size: 18,
              color: AppColors.textSecondary,
            ), // <-- DIUBAH (pengganti textGrey)
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary, // <-- DIUBAH
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHargaField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white, // <-- DIUBAH
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ), // <-- DIUBAH (pengganti cardBorder)
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Text(
            'Rp',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _hargaController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary, // <-- DIUBAH
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const Text(
            '/ bulan',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary, // <-- DIUBAH (pengganti textGrey)
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TOMBOL SIMPAN ----------------
  Widget _buildSimpanButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.white, // <-- DIUBAH
      child: ElevatedButton.icon(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white, // <-- DIUBAH
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.save_outlined, size: 18),
        label: const Text(
          'Simpan Data Kost',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
