import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:local_auth/local_auth.dart';
import 'package:notes_app/services/route_helper.dart';
import 'package:notes_app/views/base/custom_image.dart';
import 'package:notes_app/views/screens/dashboard/dashboard_screen.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/firebase_controller.dart';
import '../auth_screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  @override
  void initState() {
    super.initState();
    Timer.run(() async {
      var nav = Navigator.of(context);

      var canCheckBiometrics = await auth.canCheckBiometrics;

      if (!canCheckBiometrics) {
        Fluttertoast.showToast(msg: "Device do not support biometric auth");
      }

      await Future.delayed(const Duration(seconds: 2), () {});
      // var user = FirebaseAuth.instance.authStateChanges();
      // user.listen((event) {
      //   (event!.isisInitialValue);
      // });
      log("${await Get.find<FirebaseController>().googleSignIn.isSignedIn()}", name: "LOGIN");
      if (await Get.find<AuthController>().isLoggedIn()) {
        if (canCheckBiometrics) {
          await auth
              .authenticate(
            localizedReason: 'Notes App',
            options: const AuthenticationOptions(
              stickyAuth: true,
            ),
          )
              .then((value) {
            if (value) {
              nav.pushReplacement(
                getCustomRoute(
                  child: const DashboardScreen(),
                ),
              );
            } else {
              exit(0);
            }
          });
        }
      } else {
        nav.pushReplacement(
          getCustomRoute(
            child: const LoginScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            CustomAssetImage(
              path: Assets.imagesLogo,
              height: size.height * .3,
              width: size.height * .3,
            ),
            const Spacer(flex: 3),
            Text(
              "App Title",
              style: Theme.of(context).textTheme.bodyText1?.copyWith(
                    fontSize: 26.0,
                  ),
            ),
            Text(
              "Subtitle",
              style: Theme.of(context).textTheme.bodyText2,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
