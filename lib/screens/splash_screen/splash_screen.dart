import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:streamplay/screens/video_screen/video_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  Color mainColor = Colors.black;

  @override
  void initState() {
    super.initState();
    Splash();
  }

  Future<void> Splash() async {
    Future.delayed(Duration(seconds: 1), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const VideoScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double imageHeight = MediaQuery.of(context).size.height * 0.2;

    return Center(
      child: SvgPicture.asset(
        'assets/images/logo.svg',
        height: imageHeight,
      ),
    );
  }
}
