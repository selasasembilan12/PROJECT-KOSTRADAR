//Hesti

import 'package:flutter/material.dart';

import 'hasil_pencarian.dart';

// =====================================================
// WARNA HALAMAN PENCARIAN
// Tidak membutuhkan import theme atau constants.
// =====================================================

class PencarianColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF12233F);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color white = Colors.white;
  static const Color success = Color(0xFF16A34A);
}

// =====================================================
// HALAMAN PENCARIAN KOST
// =====================================================

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedPriceRange = 'Rp 400.000 - Rp 1.000.000';

  String _selectedLocation = 'Jati';

  String _selectedAvailability = 'Tersedia';

  final Map<String, bool> _facilities = {
    'WiFi': true,
    'AC': true,
    'Kamar Mandi Dalam': false,
    'Dapur': false,
    'Parkir': false,
  };

  final List<String> _priceRanges = [
    'Rp 400.000 - Rp 1.000.000',
    'Rp 1.000.000 - Rp 2.000.000',
    'Rp 2.000.000 - Rp 3.000.000',
    '> Rp 3.000.000',
  ];

  final List<String> _locations = ['Jati', 'Jati Metro', 'Jati Perumnas'];

  final List<String> _availabilityOptions = [
    'Tersedia',
    'Hampir Penuh',
    'Penuh',
  ];

  // ===================================================
  // RESET FILTER
  // ===================================================

  void _resetFilters() {
    setState(() {
      _searchController.clear();

      _selectedPriceRange = 'Rp 400.000 - Rp 1.000.000';

      _selectedLocation = 'Jati';

      _selectedAvailability = 'Tersedia';

      _facilities.updateAll((key, value) => false);
    });
  }

  // ===================================================
  // NAVIGASI KE HASIL PENCARIAN
  // ===================================================

  void _applyFilters() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchResultsScreen()),
    );
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // ===================================================
  // TAMPILAN UTAMA
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PencarianColors.background,

      appBar: AppBar(
        backgroundColor: PencarianColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: PencarianColors.textPrimary,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),

        title: const Text(
          'Pencarian Kost',
          style: TextStyle(
            color: PencarianColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        centerTitle: true,

        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: PencarianColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =======================================
              // INPUT PENCARIAN
              // =======================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: PencarianColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: PencarianColors.border),
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: PencarianColors.textSecondary,
                      size: 20,
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _applyFilters(),

                        decoration: const InputDecoration(
                          hintText: 'Cari nama kost atau lokasi...',

                          hintStyle: TextStyle(
                            color: PencarianColors.textHint,
                            fontSize: 14,
                          ),

                          border: InputBorder.none,
                          isDense: true,

                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),

                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: PencarianColors.textSecondary,
                        ),

                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =======================================
              // RENTANG HARGA
              // =======================================
              _buildDropdownSection(
                title: 'Rentang Harga',
                value: _selectedPriceRange,
                items: _priceRanges,

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPriceRange = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // =======================================
              // PILIH FASILITAS
              // =======================================
              const Text(
                'Fasilitas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: PencarianColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),

                decoration: BoxDecoration(
                  color: PencarianColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),

                  border: Border.all(color: PencarianColors.border),
                ),

                child: Column(
                  children: _facilities.keys.map((facility) {
                    return CheckboxListTile(
                      title: Text(
                        facility,
                        style: const TextStyle(
                          fontSize: 14,
                          color: PencarianColors.textPrimary,
                        ),
                      ),

                      value: _facilities[facility] ?? false,

                      activeColor: PencarianColors.primary,
                      checkColor: PencarianColors.white,

                      controlAffinity: ListTileControlAffinity.trailing,

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),

                      onChanged: (bool? value) {
                        setState(() {
                          _facilities[facility] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // =======================================
              // PILIH LOKASI
              // =======================================
              _buildDropdownSection(
                title: 'Lokasi',
                value: _selectedLocation,
                items: _locations,

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // =======================================
              // KETERSEDIAAN KAMAR
              // =======================================
              _buildDropdownSection(
                title: 'Ketersediaan Kamar',
                value: _selectedAvailability,
                items: _availabilityOptions,
                showStatusDot: true,

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAvailability = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 32),

              // =======================================
              // TOMBOL TERAPKAN FILTER
              // =======================================
              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: _applyFilters,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: PencarianColors.primary,
                    foregroundColor: PencarianColors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: const Text(
                    'Terapkan Filter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================
  // WIDGET DROPDOWN
  // ===================================================

  Widget _buildDropdownSection({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool showStatusDot = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: PencarianColors.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),

          decoration: BoxDecoration(
            color: PencarianColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),

            border: Border.all(color: PencarianColors.border),
          ),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,

              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: PencarianColors.textSecondary,
              ),

              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,

                  child: Row(
                    children: [
                      if (showStatusDot) ...[
                        Container(
                          width: 8,
                          height: 8,

                          decoration: BoxDecoration(
                            color: item == 'Tersedia'
                                ? PencarianColors.success
                                : item == 'Hampir Penuh'
                                ? Colors.orange
                                : Colors.red,

                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 8),
                      ],

                      Expanded(
                        child: Text(
                          item,
                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 14,
                            color: PencarianColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// NAMA ALTERNATIF SESUAI NAMA FILE
// =====================================================

class PencarianPage extends SearchScreen {
  const PencarianPage({super.key});
}
