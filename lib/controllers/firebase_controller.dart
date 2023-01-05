import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/instance_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/models/response/user.dart';
import '../services/custom_snackbar.dart';
import '../services/route_helper.dart';
import '../views/base/common_button.dart';
import '../views/base/custom_image.dart';
import '../views/screens/dashboard/dashboard_screen.dart';
import 'auth_controller.dart';

class FirebaseController extends GetxController implements GetxService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _message = '';
  late String _verificationId;
  // CountryCode? code = const CountryCode(name: 'India', code: 'IN', dialCode: '+91');

  bool get isLoading => _isLoading;
  FirebaseAuth get firebaseAuth => _firebaseAuth;

  loadingOff() {
    _isLoading = false;
    update();
  }

  Future<void> verifyPhoneNumber({required BuildContext context}) async {
    _isLoading = true;
    update();
    String number = '+91';
    number += Get.find<AuthController>().numberController.text;
    log(number);
    verificationCompleted(PhoneAuthCredential phoneAuthCredential) async {
      try {
        log("${phoneAuthCredential.smsCode}");
        Get.find<AuthController>().otpController.text = (phoneAuthCredential.smsCode) ?? '';
        Get.find<AuthController>().update();
        await Future.delayed(const Duration(milliseconds: 500));
        UserCredential userCredential = await _firebaseAuth.signInWithCredential(phoneAuthCredential);
        if (userCredential.user != null) {
          User user = userCredential.user!;

          ScaffoldSnackBar.of(context).show('Phone number automatically verified and user signed in.');
          // log("$phoneAuthCredential");
          Get.find<AuthController>().login(await user.getIdToken()).then((status) async {
            if (status.isSuccess) {
              log('${status.isSuccess}', name: 'isSuccess');
              // Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const Dashboard()), (route) => false);
              Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const DashboardScreen()), (route) => false);
              /*Get.find<AuthController>().getUserProfileData().then((value) {
                if (Get.find<AuthController>().checkUserData()) {
                  // Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const Dashboard()), (route) => false);
                  Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const DashboardScreen()), (route) => false);
                } else {
                  Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const DashboardScreen()), (route) => false);
                }
              });*/
            } else {
              ScaffoldSnackBar.of(context).show(status.message);
              _isLoading = false;
              update();
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return Center(
                    child: Dialog(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CustomAssetImage(
                              path: Assets.imagesLogo,
                              height: 100,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Failed to sign in",
                              style: GoogleFonts.montserrat(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            CustomButton(
                              type: ButtonType.primary,
                              onTap: () {
                                Navigator.pop(context);
                              },
                              title: "OK",
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          });
        } else {
          ScaffoldSnackBar.of(context).show('Login Failed.');
        }
      } catch (e) {
        log('++++++++++++++++++++++++++++++++++++++++++++ ${e.toString()} +++++++++++++++++++++++++++++++++++++++++++++', name: "ERROR AT verifyPhoneNumber()");
      }
    }

    verificationFailed(FirebaseAuthException authException) {
      try {
        _message = 'Phone number verification failed. Code: ${authException.code}. '
            'Message: ${authException.message}';
        log(_message);
        _isLoading = false;
        ScaffoldSnackBar.of(context).show(_message);
        update();
      } catch (e) {
        log('++++++++++++++++++++++++++++++++++++++++++++ ${e.toString()} +++++++++++++++++++++++++++++++++++++++++++++', name: "ERROR AT verifyPhoneNumber()");
      }
    }

    codeSent(String verificationId, [int? forceResendingToken]) async {
      try {
        // ScaffoldSnackBar.of(context).show('Please check your phone for the verification code.');
        _verificationId = verificationId;
        log(_verificationId, name: 'codeSent');
        _isLoading = false;
        update();
      } catch (e) {
        log('++++++++++++++++++++++++++++++++++++++++++++ ${e.toString()} +++++++++++++++++++++++++++++++++++++++++++++', name: "ERROR AT codeSent()");
      }
    }

    codeAutoRetrievalTimeout(String verificationId) {
      try {
        _verificationId = verificationId;
        log(_verificationId, name: 'codeAutoRetrievalTimeout');
        _isLoading = false;
        update();
      } catch (e) {
        _isLoading = false;
        update();
        log('++++++++++++++++++++++++++++++++++++++++++++ ${e.toString()} +++++++++++++++++++++++++++++++++++++++++++++',
            name: "ERROR AT codeAutoRetrievalTimeout()");
      }
    }

    try {
      await _firebaseAuth.verifyPhoneNumber(
          phoneNumber: number,
          timeout: const Duration(seconds: 10),
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    } catch (e) {
      _isLoading = false;
      update();
      ScaffoldSnackBar.of(context).show('Failed to Verify Phone Number: $e');
    }
  }

  Future<void> signInWithPhoneNumber(
    context,
    /*Function(bool success, bool newUser) onSuccess*/
  ) async {
    _isLoading = true;
    update();
    try {
      log(_verificationId);
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: Get.find<AuthController>().otpController.text,
      );
      log("${credential.asMap()}");
      var userCredential = (await _firebaseAuth.signInWithCredential(credential));
      final User user = userCredential.user!;
      ScaffoldSnackBar.of(context).show('Successfully signed in with: ${user.phoneNumber}');
      Get.find<AuthController>().login(await user.getIdToken()).then((status) async {
        try {
          if (status.isSuccess) {
            log('${status.isSuccess}', name: 'isSuccess');
            Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const DashboardScreen()), (route) => false);
            /*Get.find<AuthController>().getUserProfileData().then((value) {
                if (Get.find<AuthController>().checkUserData()) {
                  // Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const Dashboard()), (route) => false);
                  Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const DashboardScreen()), (route) => false);
                } else {
                  Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const DashboardScreen()), (route) => false);
                }
              });*/
          } else {
            ScaffoldSnackBar.of(context).show(status.message);
            _isLoading = false;
            update();
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Center(
                  child: Dialog(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CustomAssetImage(
                            path: Assets.imagesLogo,
                            height: 100,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Failed to sign in",
                            style: GoogleFonts.montserrat(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            type: ButtonType.primary,
                            onTap: () {
                              Navigator.pop(context);
                            },
                            title: "OK",
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        } catch (e) {
          log('---- ${e.toString()} ----', name: "ERROR AT signInWithPhoneNumber()");
        }
      });

      _isLoading = false;
      update();
    } catch (e) {
      log(e.toString(), name: "ERROR AT signInWithPhoneNumber");
      ScaffoldSnackBar.of(context).show('Failed to sign in');
      _isLoading = false;
      update();
    }
  }

  GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
    ],
  );

  Future<bool> isNewUser(User user) async {
    var fireStore = FirebaseFirestore.instance;
    QuerySnapshot result = await fireStore.collection("users").where("email", isEqualTo: user.email).get();
    final List<DocumentSnapshot> docs = result.docs;
    return docs.isEmpty ? true : false;
  }

  Future<void> addUserToDb(User currentUser) async {
    try {
      var fireStore = FirebaseFirestore.instance;
      UserModel user = UserModel(
        uid: currentUser.uid,
        email: currentUser.email,
        name: currentUser.displayName,
        profilePhoto: currentUser.photoURL,
      );
      await fireStore.collection("users").doc(currentUser.uid).set(user.toJson());
    } catch (error) {
      log("$error");
    }
  }

  Future<void> signInWithGoogle(context) async {
    _isLoading = true;
    update();
    if (await googleSignIn.isSignedIn()) {
      googleSignIn.signOut();
    }
    try {
      UserCredential userCredential;
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      final googleAuthCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      _firebaseAuth.signInWithCredential(googleAuthCredential).then((value) async {
        userCredential = value;
        if (userCredential.user != null) {
          User user = userCredential.user!;
          log("$user");
          ScaffoldSnackBar.of(context).show("Login Successful with ${user.email}");
          if (await isNewUser(user)) {
            await addUserToDb(user);
            Navigator.pushAndRemoveUntil(context, getCustomRoute(child: const DashboardScreen()), (route) => false);
          }
        } else {
          log("User not found");
        }
      }).catchError((error) {
        ScaffoldSnackBar.of(context).show(error.toString());
      });
      // Get.find<AuthController>().email.text = userCredential.user!.email!;

    } catch (e) {
      log(e.toString(), name: "ERROR GOOGLE SIGNIN");
      _isLoading = false;
      update();
    }
  }
}
