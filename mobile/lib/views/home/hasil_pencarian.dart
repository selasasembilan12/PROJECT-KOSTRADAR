//Hesti

import 'package:flutter/material.dart';

// ======================================================
// WARNA KHUSUS HALAMAN HASIL PENCARIAN
// Tidak memerlukan import theme atau constants tambahan.
// ======================================================

class SearchPageColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF12233F);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color chipBackground = Color(0xFFF1F5F9);
  static const Color chipText = Color(0xFF475569);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
}

// ======================================================
// MODEL DATA KOST
// ======================================================

class KostResult {
  final String name;
  final String address;
  final int price;
  final String image;
  final List<String> facilities;
  final int availableRooms;
  final bool isVerified;

  const KostResult({
    required this.name,
    required this.address,
    required this.price,
    required this.image,
    required this.facilities,
    required this.availableRooms,
    this.isVerified = false,
  });
}

// ======================================================
// HALAMAN HASIL PENCARIAN
// ======================================================

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  State<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState
    extends State<SearchResultsScreen> {

  final List<String> _activeFilters = [
    'WiFi',
    'AC',
    'Rp 400rb - 1jt',
    'Jati',
  ];

  final List<KostResult> _results = [
    const KostResult(
      name: 'Kost Adiwarna',
      address: 'Jl. Gegerkalong No. 12, Bandung',
      price: 1200000,
      image:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800',
      facilities: [
        'WiFi',
        'AC',
        'Kamar Mandi Dalam',
      ],
      availableRooms: 3,
      isVerified: true,
    ),
    const KostResult(
      name: 'Kost Melati',
      address: 'Jl. Setiabudi, Bandung',
      price: 1000000,
      image:
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
      facilities: [
        'WiFi',
        'AC',
      ],
      availableRooms: 2,
    ),
    const KostResult(
      name: 'Kost Cemara',
      address: 'Jl. Dago, Bandung',
      price: 950000,
      image:
          'https://images.unsplash.com/photo-1596276020587-8044fe049813?w=800',
      facilities: [
        'WiFi',
        'AC',
      ],
      availableRooms: 5,
    ),
  ];

  bool _sortAscending = true;

  // Menghapus filter yang dipilih.
  void _removeFilter(String filter) {
    setState(() {
      _activeFilters.remove(filter);
    });
  }

  // Mengurutkan harga kost.
  void _sortResults() {
    setState(() {
      _results.sort((a, b) {
        return _sortAscending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price);
      });

      _sortAscending = !_sortAscending;
    });
  }

  // Format harga menjadi Rupiah.
  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  // ====================================================
  // TAMPILAN UTAMA
  // ====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SearchPageColors.background,

      appBar: AppBar(
        backgroundColor: SearchPageColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: SearchPageColors.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),

        title: const Text(
          'Hasil Pencarian',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SearchPageColors.textPrimary,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Urutkan berdasarkan harga',
            onPressed: _sortResults,
            icon: const Icon(
              Icons.sort,
              color: SearchPageColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [

          // ============================================
          // INFORMASI LOKASI
          // ============================================

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),

              children: [
                Text(
                  'Bandung • ${_results.length} Kost Ditemukan',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: SearchPageColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                // ======================================
                // FILTER YANG AKTIF
                // ======================================

                if (_activeFilters.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _activeFilters.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: 8,
                          ),
                          child: Chip(
                            label: Text(
                              filter,
                              style: const TextStyle(
                                fontSize: 12,
                                color: SearchPageColors.textPrimary,
                              ),
                            ),

                            deleteIcon: const Icon(
                              Icons.close,
                              size: 16,
                            ),

                            onDeleted: () {
                              _removeFilter(filter);
                            },

                            backgroundColor:
                                SearchPageColors.primaryLight,

                            side: const BorderSide(
                              color: SearchPageColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],

                // ======================================
                // DAFTAR KOST
                // ======================================

                ..._results.map((kost) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 16,
                    ),
                    child: _buildKostCard(kost),
                  );
                }),
              ],
            ),
          ),

          // ============================================
          // TOMBOL PETA
          // ============================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: SearchPageColors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),

            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur peta interaktif belum terhubung.',
                        ),
                      ),
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        SearchPageColors.primary,
                    foregroundColor:
                        SearchPageColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  icon: const Icon(Icons.map),

                  label: const Text(
                    'Lihat di Peta Interaktif',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // WIDGET CARD KOST
  // ====================================================

  Widget _buildKostCard(KostResult kost) {
    return Container(
      decoration: BoxDecoration(
        color: SearchPageColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ============================================
          // GAMBAR KOST
          // ============================================

          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),

            child: Stack(
              children: [
                Image.network(
                  kost.image,
                  width: 120,
                  height: 175,
                  fit: BoxFit.cover,

                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      width: 120,
                      height: 175,
                      color: SearchPageColors.chipBackground,
                      child: const Icon(
                        Icons.home_outlined,
                        size: 45,
                        color: SearchPageColors.textSecondary,
                      ),
                    );
                  },
                ),

                if (kost.isVerified)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),

                      decoration: BoxDecoration(
                        color: SearchPageColors.primary,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),

                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 11,
                          ),

                          SizedBox(width: 3),

                          Text(
                            'Terverifikasi',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ============================================
          // INFORMASI KOST
          // ============================================

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                    kost.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: SearchPageColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Rp ${_formatRupiah(kost.price)}/bulan',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: SearchPageColors.primary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: SearchPageColors.textSecondary,
                        size: 14,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          kost.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color:
                                SearchPageColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ====================================
                  // FASILITAS KOST
                  // ====================================

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,

                    children: kost.facilities.map((facility) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color:
                              SearchPageColors.chipBackground,
                          borderRadius:
                              BorderRadius.circular(6),
                        ),

                        child: Text(
                          facility,
                          style: const TextStyle(
                            fontSize: 10,
                            color: SearchPageColors.chipText,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // ====================================
                  // STATUS KETERSEDIAAN
                  // ====================================

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),

                    decoration: BoxDecoration(
                      color: SearchPageColors.successLight,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),

                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: SearchPageColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 6),

                        Text(
                          'Tersedia ${kost.availableRooms} kmr',
                          style: const TextStyle(
                            color: SearchPageColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// NAMA ALTERNATIF SESUAI NAMA FILE PROJECT
// ======================================================

class HasilPencarianPage extends SearchResultsScreen {
  const HasilPencarianPage({super.key});
}
