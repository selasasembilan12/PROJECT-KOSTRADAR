import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  String _nama = "Memuat...";
  String _email = "Memuat...";
  bool _isLoading = false;
  String get nama => _nama;
  String get email => _email;
  bool get isLoading => _isLoading;

  // Fungsi buat narik data dari Supabase
  Future<void> loadUserData() async {
    _isLoading = true;
    notifyListeners(); // Kasih tau UI buat muter loading

    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _email = user.email ?? 'Tidak ada email';
        
        // PENTING: Ganti 'users' dengan nama tabel lu di database (misal: 'mahasiswa')
        final data = await _supabase
            .from('users') 
            .select('nama')
            .eq('id', user.id)
            .maybeSingle();

        _nama = data != null ? data['nama'] ?? 'Pengguna' : 'Pengguna';
      }
    } catch (e) {
      _nama = "Gagal memuat";
      _email = "Gagal memuat";
    } finally {
      _isLoading = false;
      notifyListeners(); // Kasih tau UI kalau data udah dapet
    }
  }
}