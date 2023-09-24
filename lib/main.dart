import 'package:flutter/material.dart';
import 'package:streamplay/screens/splash_screen/splash_screen.dart';

Future<void> main() async {
  runApp(
    MaterialApp(
      home: const SplashScreen(),
      theme: ThemeData(
        fontFamily: 'Pretendard',
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}