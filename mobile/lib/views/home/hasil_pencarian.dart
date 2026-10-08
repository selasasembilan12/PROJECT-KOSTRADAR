
import 'package:flutter/material.dart';

// ==========================================
// WARNA HALAMAN HASIL PENCARIAN
// ==========================================

class SearchPageColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF12233F);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color chipBackground = Color(0xFFF1F5F9);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
}

// ==========================================
// MODEL DATA KOST
// ==========================================

class KostResult {
  final String name;
  final String address;
  final String location;
  final int price;
  final String image;
  final List<String> facilities;
  final int availableRooms;
  final bool isVerified;

  const KostResult({
    required this.name,
    required this.address,
    required this.location,
    required this.price,
    required this.image,
    required this.facilities,
    required this.availableRooms,
    this.isVerified = false,
  });
}

// ==========================================
// DATA KOST BERSAMA
// DIGUNAKAN HOME DAN HASIL PENCARIAN
// ==========================================

const List<KostResult> kostRadarData = [
  KostResult(
    name: 'Kost Adiwarna',
    address: 'Jl. Jati No. 12',
    location: 'Jati',
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
  KostResult(
    name: 'Kost Melati',
    address: 'Jl. Jati Metro No. 45',
    location: 'Jati Metro',
    price: 1000000,
    image:
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800',
    facilities: [
      'WiFi',
      'AC',
      'Parkir',
    ],
    availableRooms: 2,
    isVerified: true,
  ),
  KostResult(
    name: 'Kost Cemara',
    address: 'Jl. Jati Perumnas No. 8',
    location: 'Jati Perumnas',
    price: 950000,
    image:
        'https://images.unsplash.com/photo-1596276020587-8044fe049813?w=800',
    facilities: [
      'WiFi',
      'AC',
      'Dapur',
    ],
    availableRooms: 5,
  ),
  KostResult(
    name: 'Kost Anggrek',
    address: 'Jl. Jati No. 24',
    location: 'Jati',
    price: 750000,
    image:
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
    facilities: [
      'WiFi',
      'Parkir',
      'Dapur',
    ],
    availableRooms: 1,
    isVerified: true,
  ),
  KostResult(
    name: 'Kost Permata',
    address: 'Jl. Jati Metro No. 17',
    location: 'Jati Metro',
    price: 1500000,
    image:
        'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=800',
    facilities: [
      'WiFi',
      'AC',
      'Kamar Mandi Dalam',
      'Parkir',
    ],
    availableRooms: 0,
  ),
];

// ==========================================
// HALAMAN HASIL PENCARIAN
// ==========================================

class SearchResultsScreen extends StatefulWidget {
  final String keyword;
  final String priceRange;
  final String location;
  final String availability;
  final List<String> facilities;

  const SearchResultsScreen({
    super.key,
    this.keyword = '',
    this.priceRange = 'Semua Harga',
    this.location = 'Semua Lokasi',
    this.availability = 'Semua Status',
    this.facilities = const [],
  });

  @override
  State<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState
    extends State<SearchResultsScreen> {
  late String _keyword;
  late String _priceRange;
  late String _location;
  late String _availability;
  late List<String> _facilities;

  bool _sortAscending = true;

  // ==========================================
  // MENERIMA FILTER DARI HALAMAN PENCARIAN
  // ==========================================

  @override
  void initState() {
    super.initState();

    _keyword = widget.keyword;
    _priceRange = widget.priceRange;
    _location = widget.location;
    _availability = widget.availability;
    _facilities = List.from(widget.facilities);
  }

  // ==========================================
  // FILTER DATA KOST
  // ==========================================

  List<KostResult> get _filteredResults {
    final results = kostRadarData.where((kost) {
      // Pencarian nama dan alamat
      final query = _keyword.toLowerCase().trim();

      final matchKeyword = query.isEmpty ||
          kost.name.toLowerCase().contains(query) ||
          kost.address.toLowerCase().contains(query);

      // Filter lokasi
      final matchLocation =
          _location == 'Semua Lokasi' ||
          _location.isEmpty ||
          kost.location == _location;

      // Filter fasilitas
      final matchFacilities = _facilities.every(
        (facility) => kost.facilities.any(
          (item) =>
              item.toLowerCase() == facility.toLowerCase(),
        ),
      );

      // Filter harga
      bool matchPrice = true;

      switch (_priceRange) {
        case 'Rp 400.000 - Rp 1.000.000':
          matchPrice =
              kost.price >= 400000 &&
              kost.price <= 1000000;
          break;

        case 'Rp 1.000.000 - Rp 2.000.000':
          matchPrice =
              kost.price >= 1000000 &&
              kost.price <= 2000000;
          break;

        case 'Rp 2.000.000 - Rp 3.000.000':
          matchPrice =
              kost.price >= 2000000 &&
              kost.price <= 3000000;
          break;

        case '> Rp 3.000.000':
          matchPrice = kost.price > 3000000;
          break;

        default:
          matchPrice = true;
      }

      // Filter ketersediaan
      bool matchAvailability = true;

      switch (_availability) {
        case 'Tersedia':
          matchAvailability = kost.availableRooms > 0;
          break;

        case 'Hampir Penuh':
          matchAvailability = kost.availableRooms == 1;
          break;

        case 'Penuh':
          matchAvailability = kost.availableRooms == 0;
          break;

        default:
          matchAvailability = true;
      }

      return matchKeyword &&
          matchLocation &&
          matchFacilities &&
          matchPrice &&
          matchAvailability;
    }).toList();

    // Urutkan harga
    results.sort((a, b) {
      if (_sortAscending) {
        return a.price.compareTo(b.price);
      } else {
        return b.price.compareTo(a.price);
      }
    });

    return results;
  }

  // ==========================================
  // FILTER YANG SEDANG AKTIF
  // ==========================================

  List<String> get _activeFilters {
    final filters = <String>[];

    if (_keyword.isNotEmpty) {
      filters.add(_keyword);
    }

    if (_priceRange != 'Semua Harga' &&
        _priceRange.isNotEmpty) {
      filters.add(_priceRange);
    }

    if (_location != 'Semua Lokasi' &&
        _location.isNotEmpty) {
      filters.add(_location);
    }

    if (_availability != 'Semua Status' &&
        _availability.isNotEmpty) {
      filters.add(_availability);
    }

    filters.addAll(_facilities);

    return filters;
  }

  // ==========================================
  // HAPUS FILTER
  // ==========================================

  void _removeFilter(String filter) {
    setState(() {
      if (filter == _keyword) {
        _keyword = '';
      } else if (filter == _priceRange) {
        _priceRange = 'Semua Harga';
      } else if (filter == _location) {
        _location = 'Semua Lokasi';
      } else if (filter == _availability) {
        _availability = 'Semua Status';
      } else {
        _facilities.remove(filter);
      }
    });
  }

  // ==========================================
  // URUTKAN HARGA
  // ==========================================

  void _sortResults() {
    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  // ==========================================
  // FORMAT RUPIAH
  // ==========================================

  String _formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  // ==========================================
  // TAMPILAN UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;
    final activeFilters = _activeFilters;

    return Scaffold(
      backgroundColor: SearchPageColors.background,

      appBar: AppBar(
        backgroundColor: SearchPageColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: SearchPageColors.textPrimary,
          ),
          onPressed: () {
            Navigator.pop(context);
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
            tooltip: _sortAscending
                ? 'Harga termurah dahulu'
                : 'Harga termahal dahulu',
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),

              children: [
                // ==================================
                // INFORMASI JUMLAH KOST
                // ==================================

                Text(
                  '${_location == "Semua Lokasi" ? "Semua Lokasi" : _location} • ${results.length} Kost Ditemukan',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: SearchPageColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _sortAscending
                      ? 'Urutan harga: Termurah'
                      : 'Urutan harga: Termahal',
                  style: const TextStyle(
                    fontSize: 12,
                    color: SearchPageColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================
                // FILTER AKTIF
                // ==================================

                if (activeFilters.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: activeFilters.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: 8,
                          ),
                          child: Chip(
                            label: Text(
                              filter,
                              style: const TextStyle(
                                fontSize: 12,
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

                  const SizedBox(height: 20),
                ],

                // ==================================
                // HASIL PENCARIAN KOSONG
                // ==================================

                if (results.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 70,
                          color: SearchPageColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Kost Tidak Ditemukan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Coba ubah atau hapus beberapa filter pencarian.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: SearchPageColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ==================================
                // TAMPILKAN DATA KOST
                // ==================================

                ...results.map((kost) {
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

          // ======================================
          // TOMBOL PETA
          // ======================================

          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
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
                width: double.infinity,
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
                    backgroundColor: SearchPageColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  // ==========================================
  // CARD HASIL PENCARIAN
  // ==========================================

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
          // ==================================
          // GAMBAR KOST
          // ==================================

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
                  height: 190,
                  fit: BoxFit.cover,
                  errorBuilder: (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      width: 120,
                      height: 190,
                      color: SearchPageColors.chipBackground,
                      child: const Icon(
                        Icons.home_outlined,
                        size: 45,
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
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SearchPageColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '✓ Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ==================================
          // INFORMASI KOST
          // ==================================

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        size: 14,
                        color: SearchPageColors.textSecondary,
                      ),

                      const SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          kost.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: SearchPageColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

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
                          color: SearchPageColors.chipBackground,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          facility,
                          style: const TextStyle(
                            fontSize: 10,
                            color: SearchPageColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 10),

                  // ==================================
                  // STATUS KAMAR
                  // ==================================

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: kost.availableRooms > 0
                          ? SearchPageColors.successLight
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      kost.availableRooms > 0
                          ? 'Tersedia ${kost.availableRooms} kmr'
                          : 'Kamar Penuh',
                      style: TextStyle(
                        color: kost.availableRooms > 0
                            ? SearchPageColors.success
                            : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
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

// ==========================================
// ALIAS NAMA SESUAI PROJECT
// ==========================================

class HasilPencarianPage extends SearchResultsScreen {
  const HasilPencarianPage({
    super.key,
    super.keyword,
    super.priceRange,
    super.location,
    super.availability,
    super.facilities,
  });
}
