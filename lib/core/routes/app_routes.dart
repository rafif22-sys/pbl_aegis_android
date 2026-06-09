import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/petugas/screens/petugas_home_screen.dart';
import '../../features/petugas/screens/pesan_screen.dart';   // ← tambahkan
import '../../features/supervisor/screens/home_page.dart';
import '../../features/warga/screens/warga_home_screen.dart';

class AppRoutes {
  static const String login          = '/login';
  static const String petugasHome    = '/petugas/home';
  static const String supervisorHome = '/supervisor/home';
  static const String wargaHome      = '/warga/home';
  static const String pesan          = '/pesan';             

  static Map<String, WidgetBuilder> routes = {
    login:          (_) => const LoginScreen(),
    petugasHome:    (_) => const PetugasHomeScreen(),
    supervisorHome: (_) => const SupervisorHomePage(),
    wargaHome:      (_) => const WargaHomeScreen(),
    pesan:          (_) => const MessageScreen(),            
  };
}