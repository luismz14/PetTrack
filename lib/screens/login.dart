import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pet_track/components/google_auth.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:pet_track/screens/home_screen.dart';
import 'package:pet_track/services/fcm_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final googleSignIn = GoogleSignIn(scopes: ['openid', 'email']);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to PetTrack!',
              style: AppTextStyles.bigText(context),
            ),
            const SizedBox(height: 20),
            Material(
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    try {
                      final account = await googleSignIn.signIn();
                      if (account == null) return;

                      final auth = await account.authentication;
                      final googleIdToken = auth.idToken;
                      if (googleIdToken == null) {
                        throw Exception('Could not obtain the Google ID token');
                      }

                      final firebaseIdToken =
                          await AuthService().signInWithGoogle();

                      await FCMService.instance.initForCurrentUser();

                      await callCloudFunction(
                        functionName: 'get_pets',
                        firebaseIdToken: firebaseIdToken,
                      );

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder:
                              (_) => AlertDialog(
                                title: const Text('Sign-in failed'),
                                content: const Text(
                                  'Sign-in could not be completed. '
                                  'Check your local service configuration.',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Ok'),
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                  ),
                                ],
                              ),
                        );
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.white,
                          size: screenHeight * 0.03,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Sign in with Google',
                          style: AppTextStyles.midText(
                            context,
                          ).copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
