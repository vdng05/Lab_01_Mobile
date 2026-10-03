import 'package:flutter/material.dart';

import '../application/study_document_controller.dart';
import '../presentation/pages/document_library_page.dart';

class StudyLibraryApp extends StatelessWidget {
  const StudyLibraryApp({super.key, required this.controller});

  final StudyDocumentController controller;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF176B52);
    return MaterialApp(
      title: 'Cashew Study Library',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          surface: const Color(0xFFF5F5F0),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F0),
          foregroundColor: Color(0xFF17231E),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDE3DE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDDE3DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
        ),
      ),
      home: DocumentLibraryPage(controller: controller),
    );
  }
}
