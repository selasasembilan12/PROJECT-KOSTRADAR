import 'package:flutter/material.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';

import 'hasil_pencarian.dart';

// ==========================================
// HALAMAN PENCARIAN KOST
// ==========================================

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedPriceRange = 'Semua Harga';
  String _selectedLocation = 'Semua Lokasi';
  String _selectedAvailability = 'Semua Status';

  final Map<String, bool> _facilities = {
    'WiFi': false,
    'AC': false,
    'Kamar Mandi Dalam': false,
    'Dapur': false,
    'Parkir': false,
  };

  final List<String> _priceRanges = [
    'Semua Harga',
    'Rp 400.000 - Rp 1.000.000',
    'Rp 1.000.000 - Rp 2.000.000',
    'Rp 2.000.000 - Rp 3.000.000',
    '> Rp 3.000.000',
  ];

  final List<String> _locations = [
    'Semua Lokasi',
    'Jati',
    'Jati Metro',
    'Jati Perumnas',
  ];

  final List<String> _availabilityOptions = [
    'Semua Status',
    'Tersedia',
    'Hampir Penuh',
    'Penuh',
  ];

  // ==========================================
  // RESET FILTER
  // ==========================================

  void _resetFilters() {
    setState(() {
      _searchController.clear();

      _selectedPriceRange = 'Semua Harga';
      _selectedLocation = 'Semua Lokasi';
      _selectedAvailability = 'Semua Status';

      _facilities.updateAll((key, value) => false);
    });
  }

  // ==========================================
  // TERAPKAN FILTER
  // ==========================================

  void _applyFilters() {
    final selectedFacilities = _facilities.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          keyword: _searchController.text.trim(),
          priceRange: _selectedPriceRange,
          location: _selectedLocation,
          availability: _selectedAvailability,
          facilities: selectedFacilities,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // TAMPILAN HALAMAN PENCARIAN
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // <-- DIUBAH

      appBar: AppBar(
        backgroundColor: AppColors.background, // <-- DIUBAH
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary, // <-- DIUBAH
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Pencarian Kost',
          style: TextStyle(
            color: AppColors.textPrimary, // <-- DIUBAH
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reset',
              style: TextStyle(
                color: AppColors.primary, // <-- DIUBAH
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
              // ======================================
              // INPUT PENCARIAN
              // ======================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),

                decoration: BoxDecoration(
                  color: AppColors.white, // <-- DIUBAH
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border), // <-- DIUBAH
                ),

                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.textSecondary, // <-- DIUBAH
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) => _applyFilters(),
                        onChanged: (value) {
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          hintText: 'Cari nama kost atau lokasi...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ), // <-- DIUBAH (biar icon close juga rapi)
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ======================================
              // RENTANG HARGA
              // ======================================
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

              // ======================================
              // FASILITAS
              // ======================================
              const Text(
                'Fasilitas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, // <-- DIUBAH
                ),
              ),

              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.white, // <-- DIUBAH
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border), // <-- DIUBAH
                ),

                child: Column(
                  children: _facilities.keys.map((facility) {
                    return CheckboxListTile(
                      title: Text(
                        facility,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ), // <-- DIUBAH
                      ),
                      value: _facilities[facility] ?? false,
                      activeColor: AppColors.primary, // <-- DIUBAH
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (value) {
                        setState(() {
                          _facilities[facility] = value ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // ======================================
              // LOKASI
              // ======================================
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

              // ======================================
              // KETERSEDIAAN KAMAR
              // ======================================
              _buildDropdownSection(
                title: 'Ketersediaan Kamar',
                value: _selectedAvailability,
                items: _availabilityOptions,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAvailability = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 32),

              // ======================================
              // TOMBOL TERAPKAN FILTER
              // ======================================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _applyFilters,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // <-- DIUBAH
                    foregroundColor: AppColors.white, // <-- DIUBAH
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  icon: const Icon(Icons.search),

                  label: const Text(
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

  // ==========================================
  // WIDGET DROPDOWN
  // ==========================================

  Widget _buildDropdownSection({
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary, // <-- DIUBAH
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white, // <-- DIUBAH
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border), // <-- DIUBAH
          ),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ), // <-- DIUBAH
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary, // <-- DIUBAH
                    ),
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

// ==========================================
// ALIAS SESUAI NAMA FILE PROJECT
// ==========================================

class PencarianPage extends SearchScreen {
  const PencarianPage({super.key});
}
