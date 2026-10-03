import 'package:flutter/material.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';

// Aquest fitxer defineix la barra de navegació inferior (BottomNavigationBar) de l'aplicació, que permet
// moure's ràpidament entre les pantalles principals (mascotes, calendari, rutes, perfil) mantenint l’estat seleccionat.

class NavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavBar({required this.currentIndex, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: false,
      selectedLabelStyle: AppTextStyles.tinyText(
        context,
      ).copyWith(fontWeight: FontWeight.w600),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Mascotes'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month),
          label: 'Calendari',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.navigation), label: 'Rutes'),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Perfil',
        ),
      ],
    );
  }
}
