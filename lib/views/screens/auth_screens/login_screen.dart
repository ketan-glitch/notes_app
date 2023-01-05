import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:notes_app/controllers/firebase_controller.dart';
import 'package:notes_app/views/base/common_button.dart';
import 'package:notes_app/views/base/custom_image.dart';

import '../../../services/input_decoration.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController lottieController;

  @override
  void initState() {
    super.initState();

    lottieController = AnimationController(
      vsync: this,
    );

    lottieController.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        // lottieController.reset();
      }
    });
  }

  @override
  void dispose() {
    lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            Lottie.asset(
              Assets.lotties10609Note,
              repeat: false,
              height: size.height * .4,
              width: size.width,
              controller: lottieController,
              onLoaded: (composition) {
                lottieController.duration = composition.duration;
                lottieController.forward();
              },
            ),
            Text(
              "LOGIN",
              style: GoogleFonts.montserrat(
                fontSize: 32.0,
                letterSpacing: 2.0,
                color: textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            CustomButton(
              type: ButtonType.primary,
              onTap: () {
                Get.find<FirebaseController>().signInWithGoogle(context);
              },
              title: "Sign in with Google",
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
