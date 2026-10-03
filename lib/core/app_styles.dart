import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_track/core/app_colors.dart';

// Aquest fitxer agrupa diversos estils comuns utilitzats en els components visuals de l'aplicació,
// com ara marges, espaiats, decoracions i ombres.

class AppTextStyles {
  // Retorna l'estil del text del logotip principal de l'aplicació.
  static TextStyle logoText(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.height;

    return GoogleFonts.outfit(
      color: Colors.white,
      fontSize: screenWidth * 0.05625,
      fontWeight: FontWeight.w600,
    );
  }

  // Retorna l'estil dels títols generals dins l'app.
  static TextStyle titleText(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.height;

    return GoogleFonts.outfit(
      color: AppColors.black,
      fontSize: screenWidth * 0.035,
      fontWeight: FontWeight.w600,
    );
  }

  // Retorna un estil de text gran i destacat, per a seccions importants.
  static TextStyle bigText(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.height;

    return GoogleFonts.outfit(
      color: AppColors.black,
      fontSize: screenWidth * 0.035,
      fontWeight: FontWeight.w700,
    );
  }

  // Retorna un estil de text molt petit, pensat per a detalls o informació auxiliar.
  static TextStyle tinyText(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.height;

    return GoogleFonts.outfit(
      color: AppColors.grey,
      fontSize: screenWidth * 0.018,
      fontWeight: FontWeight.w300,
    );
  }

  // Retorna un estil de text mitjà, habitualment usat en descripcions o textos de suport.
  static TextStyle midText(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.height;

    return GoogleFonts.outfit(
      color: AppColors.grey,
      fontSize: screenWidth * 0.021,
      fontWeight: FontWeight.w500,
    );
  }

  // Retorna un estil de text primari, utilitzat habitualment per a textos destacats però no principals.
  static TextStyle primaryText(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.height;

    return GoogleFonts.outfit(
      color: AppColors.grey,
      fontSize: screenWidth * 0.025,
      fontWeight: FontWeight.w500,
    );
  }
}
