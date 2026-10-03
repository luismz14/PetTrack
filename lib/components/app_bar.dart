import 'package:flutter/material.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Aquest fitxer defineix un widget personalitzat de barra superior (AppBar) per a
// l'aplicació, amb un estil i funcionalitats comunes.

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Color? iconColor;
  final List<Widget>? actions;

  const AppBarWidget({
    super.key,
    required this.height,
    this.iconColor,
    this.actions,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: height,
      iconTheme: IconThemeData(color: iconColor ?? Colors.white),
      title: Row(
        children: [
          Text("PetTr", style: AppTextStyles.logoText(context)),
          SvgPicture.asset(
            "assets/images/icon_bold.svg",
            height: AppTextStyles.logoText(context).fontSize,
          ),
          Text("ck", style: AppTextStyles.logoText(context)),
        ],
      ),
      actions: actions,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(gradient: AppColors.gradient),
      ),
    );
  }
}
