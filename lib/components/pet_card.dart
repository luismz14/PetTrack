import 'package:flutter/material.dart';
import 'package:pet_track/components/feed_button.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

// Aquest fitxer defineix el widget de targeta de mascota (PetCard). Mostra una imatge, dades bàsiques (nom, raça, edat, sexe)
// i incorpora el botó FeedButton per registrar racions de menjar i l’última hora d’alimentació.

class PetCard extends StatefulWidget {
  final Map<String, dynamic> petData;
  final VoidCallback? onTap;
  const PetCard({super.key, required this.petData, this.onTap});

  @override
  State<PetCard> createState() => _PetCardState();
}

class _PetCardState extends State<PetCard> {
  @override
  Widget build(BuildContext context) {
    final pet = widget.petData;
    final name = pet['name'] ?? 'Sense nom';
    final species = pet['species'] ?? 'Espècie desconeguda';
    final breed = pet['breed'] ?? 'Raça desconeguda';
    final birthDate =
        pet['birthDate'] is Timestamp
            ? (pet['birthDate'] as Timestamp).toDate()
            : null;
    final ageText =
        birthDate != null
            ? () {
              final now = DateTime.now();
              final days = now.difference(birthDate).inDays;
              final months = (days / 30).floor();
              return days < 30
                  ? '$days dies'
                  : months < 12
                  ? '$months mesos'
                  : '${(months / 12).floor()} anys';
            }()
            : '';
    final petId = pet['id'];
    final lastFed =
        pet['lastFed'] is Timestamp
            ? (pet['lastFed'] as Timestamp).toDate()
            : DateTime(2025, 1, 1);
    final dailyFeedGoal = pet['dailyFeedGoal'];
    var dailyFeedCount = pet['dailyFeedCount'];
    final sex = pet['sex'] ?? '?';
    final String? imageUrl = pet['imageUrl'];
    final ImageProvider imageProvider =
        imageUrl != null && imageUrl.isNotEmpty
            ? NetworkImage(imageUrl)
            : AssetImage('assets/images/$species.png');

    // Actualitza a Firestore el recompte diari i, si cal, la data "lastFed" de la mascota.
    void updateLastFed(bool add) {
      dailyFeedCount =
          add
              ? min(dailyFeedCount + 1, dailyFeedGoal)
              : max(dailyFeedCount - 1, 0);

      final user = FirebaseAuth.instance.currentUser;

      final updateData = {'dailyFeedCount': dailyFeedCount};
      if (add) updateData['lastFed'] = DateTime.now();

      FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('pets')
          .doc(petId)
          .update(updateData);
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardHeight = screenHeight * 0.24;
    const double borderRadius = 20.0;
    const double horizontalPadding = 16.0;
    const double topPadding = 16.0;
    const double bottomPadding = 4.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        clipBehavior: Clip.hardEdge,
        shadowColor: Colors.transparent,
        color: AppColors.backgroundComponent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: SizedBox(
          width: double.infinity,
          height: cardHeight,
          child: Stack(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                splashColor: AppColors.accent.withAlpha(30),
                onTap: widget.onTap,
                child: Row(
                  children: [
                    SizedBox(
                      width: cardHeight,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(borderRadius),
                          bottomLeft: Radius.circular(borderRadius),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Ink.image(image: imageProvider, fit: BoxFit.cover),
                            Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.center,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.backgroundComponent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: horizontalPadding,
                          right: horizontalPadding,
                          top: topPadding,
                          bottom: bottomPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(breed, style: AppTextStyles.tinyText(context)),
                            Text(name, style: AppTextStyles.bigText(context)),
                            Text(
                              '${sex.isNotEmpty ? sex[0].toUpperCase() : ''}   $ageText',
                              style: AppTextStyles.midText(context),
                            ),
                            const Spacer(),
                            FeedButton(
                              size: cardHeight * 0.335,
                              lastFed: lastFed,
                              onFeed: updateLastFed,
                              dailyFeedCount: dailyFeedCount,
                              dailyFeedGoal: dailyFeedGoal,
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
