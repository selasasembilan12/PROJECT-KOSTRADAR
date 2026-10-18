import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT STANDAR TIM ---
import '../../core/theme/app_theme.dart';
import '../../models/kost_model.dart';
import '../kost/detail_kost_page.dart';

// ==========================================
// HALAMAN HASIL PENCARIAN (TERINTEGRASI SUPABASE)
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
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  late String _keyword;
  late String _priceRange;
  late String _location;
  late String _availability;
  late List<String> _facilities;

  bool _sortAscending = true;

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
  // FETCH DATA KOST DARI SUPABASE + FILTERING
  // ==========================================
  Future<List<KostModel>> _fetchFilteredKostFromSupabase() async {
    // Query Dasar Supabase
    var query = supabase.from('kost').select('*, foto_kost(*), fasilitas_kost(*)');

    // 1. Filter Keyword (Nama atau Alamat)
    if (_keyword.trim().isNotEmpty) {
      final q = _keyword.trim();
      query = query.or('nama.ilike.%$q%,alamat.ilike.%$q%');
    }

    // 2. Filter Lokasi
    if (_location != 'Semua Lokasi' && _location.isNotEmpty) {
      query = query.ilike('alamat', '%$_location%');
    }

    // 3. Filter Status Ketersediaan Kamar
    if (_availability == 'Tersedia') {
      query = query.gt('ketersediaan_kamar', 0);
    } else if (_availability == 'Hampir Penuh') {
      query = query.eq('ketersediaan_kamar', 1);
    } else if (_availability == 'Penuh') {
      query = query.eq('ketersediaan_kamar', 0);
    }

    // Eksekusi data dari Supabase
    final response = await query;
    final List<dynamic> rawData = response as List<dynamic>;
    List<KostModel> listKost = rawData.map((e) => KostModel.fromJson(e)).toList();

    // 4. Filter Rentang Harga (Lokal Dart)
    if (_priceRange != 'Semua Harga' && _priceRange.isNotEmpty) {
      listKost = listKost.where((kost) {
        final double harga = double.tryParse(kost.harga.toString()) ?? 0.0;
        if (_priceRange == 'Rp 400.000 - Rp 1.000.000') {
          return harga >= 400000 && harga <= 1000000;
        } else if (_priceRange == 'Rp 1.000.000 - Rp 2.000.000') {
          return harga >= 1000000 && harga <= 2000000;
        } else if (_priceRange == 'Rp 2.000.000 - Rp 3.000.000') {
          return harga >= 2000000 && harga <= 3000000;
        } else if (_priceRange == '> Rp 3.000.000') {
          return harga > 3000000;
        }
        return true;
      }).toList();
    }

    // 5. Filter Fasilitas (Lokal Dart)
    if (_facilities.isNotEmpty) {
      listKost = listKost.where((kost) {
        final kostFac = kost.fasilitas.map((f) => f.toLowerCase()).toList();
        return _facilities.every(
          (fac) => kostFac.contains(fac.toLowerCase()),
        );
      }).toList();
    }

    // 6. Urutkan berdasarkan Harga
    listKost.sort((a, b) {
      final double hargaA = double.tryParse(a.harga.toString()) ?? 0.0;
      final double hargaB = double.tryParse(b.harga.toString()) ?? 0.0;
      return _sortAscending ? hargaA.compareTo(hargaB) : hargaB.compareTo(hargaA);
    });

    return listKost;
  }

  List<String> get _activeFilters {
    final filters = <String>[];
    if (_keyword.isNotEmpty) filters.add(_keyword);
    if (_priceRange != 'Semua Harga' && _priceRange.isNotEmpty) {
      filters.add(_priceRange);
    }
    if (_location != 'Semua Lokasi' && _location.isNotEmpty) {
      filters.add(_location);
    }
    if (_availability != 'Semua Status' && _availability.isNotEmpty) {
      filters.add(_availability);
    }
    filters.addAll(_facilities);
    return filters;
  }

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

  void _sortResults() {
    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  String _formatRupiah(dynamic number) {
    final double hargaVal = double.tryParse(number.toString()) ?? 0.0;
    return hargaVal.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
  }

  void _openDetail(KostModel kost) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailKostPage(kost: kost),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFilters = _activeFilters;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Hasil Pencarian',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _sortAscending
                ? 'Harga termurah dahulu'
                : 'Harga termahal dahulu',
            onPressed: _sortResults,
            icon: const Icon(Icons.sort, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<KostModel>>(
        future: _fetchFilteredKostFromSupabase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat hasil: ${snapshot.error}'),
            );
          }

          final results = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  children: [
                    Text(
                      '${_location == "Semua Lokasi" ? "Semua Lokasi" : _location}\n${results.length} Kost Ditemukan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sortAscending
                          ? 'Urutan harga: Termurah'
                          : 'Urutan harga: Termahal',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (activeFilters.isNotEmpty) ...[
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: activeFilters.map((filter) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(
                                  filter,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => _removeFilter(filter),
                                backgroundColor: AppColors.primaryLight,
                                side: const BorderSide(color: AppColors.primary),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (results.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 70,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Kost Tidak Ditemukan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Coba ubah atau hapus beberapa filter pencarian.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),

                    ...results.map((kost) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildKostCard(kost),
                      );
                    }),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.white,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur peta interaktif belum terhubung.'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
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
          );
        },
      ),
    );
  }

  // ==========================================
  // CARD KOST TERINTEGRASI DENGAN KOSTMODEL
  // ==========================================
  Widget _buildKostCard(KostModel kost) {
    final imageUrl = kost.foto.isNotEmpty ? kost.foto[0] : '';

    return GestureDetector(
      onTap: () => _openDetail(kost),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: 120,
                    height: 190,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 120,
                        height: 190,
                        color: AppColors.chipBackground,
                        child: const Icon(
                          Icons.home_outlined,
                          size: 45,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                  if (kost.terverifikasi)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '✓ Verified',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kost.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatRupiah(kost.harga)}/bulan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            kost.alamat,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kost.fasilitas.map((facility) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.chipBackground,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            facility,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kost.ketersediaanKamar > 0
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kost.ketersediaanKamar > 0
                            ? 'Tersedia ${kost.ketersediaanKamar} kmr'
                            : 'Kamar Penuh',
                        style: TextStyle(
                          color: kost.ketersediaanKamar > 0
                              ? AppColors.success
                              : AppColors.error,
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