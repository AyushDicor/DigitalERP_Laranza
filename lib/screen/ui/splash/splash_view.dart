import 'package:digitalerp/screen/ui/splash/splash_controller.dart';
import 'package:digitalerp/utils/app_constant.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/app_constant_new.dart';

class SplashView extends StatelessWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      init: SplashController(),
      builder: (ctrl) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //  Stacked layers logo 
              // The Laranza wordmark is a wide 4:1 lockup, so give it a wide
              // box — a 100x100 square shrank it to a sliver.
              Image.asset(
                'assets/images/laranzalogo.png',
                width: 240,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),


              const Text(
                'Laranza',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
