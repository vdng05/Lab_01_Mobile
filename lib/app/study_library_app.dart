import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../application/study_document_controller.dart';
import '../domain/repositories/authentication_repository.dart';
import '../domain/repositories/user_profile_repository.dart';
import '../presentation/pages/authentication_gate.dart';
import '../presentation/pages/document_library_page.dart';

class StudyLibraryApp extends StatelessWidget {
  const StudyLibraryApp({
    super.key,
    this.controller,
    this.authenticationRepository,
    this.profileRepository,
    this.supabaseClient,
  });

  final StudyDocumentController? controller;
  final AuthenticationRepository? authenticationRepository;
  final UserProfileRepository? profileRepository;
  final SupabaseClient? supabaseClient;

  @override
  Widget build(BuildContext context) {
    const navyBackground = Color(0xFF0B132B);
    const navyCard = Color(0xFF1E293B);
    const cyanAccent = Color(0xFF38BDF8);
    const bluePrimary = Color(0xFF0284C7);
    const borderColor = Color(0xFF334155);

    return MaterialApp(
      title: 'Study Library',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: navyBackground,
        colorScheme: const ColorScheme.dark(
          primary: cyanAccent,
          secondary: Color(0xFF06B6D4),
          surface: navyCard,
          error: Color(0xFFEF4444),
          onPrimary: Colors.white,
          onSurface: Color(0xFFF8FAFC),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFF8FAFC),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: navyCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderColor),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1E293B),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: borderColor),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A),
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cyanAccent, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: bluePrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: cyanAccent,
            side: const BorderSide(color: Color(0xFF0284C7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: authenticationRepository != null
          ? AuthenticationGate(
              authenticationRepository: authenticationRepository!,
              profileRepository: profileRepository,
              supabaseClient: supabaseClient,
              localController: controller,
            )
          : DocumentLibraryPage(controller: controller!),
    );
  }
}
