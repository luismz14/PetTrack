import 'package:flutter/material.dart';
import 'package:pet_track/components/pet_card.dart';
import 'package:pet_track/core/app_colors.dart';
import 'package:pet_track/core/app_styles.dart';
import 'package:pet_track/models/pets_db.dart';
import 'package:pet_track/screens/add_edit_pet_screen.dart';
import 'package:pet_track/screens/pet_details_screen.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  late Future<List<Map<String, dynamic>>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _petsFuture = getPets();
  }

  Future<void> _refreshPets() async {
    if (!mounted) return;
    setState(() {
      _petsFuture = getPets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _petsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Could not load pets.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'You have no pets yet',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bigText(context),
                  ),
                  Text(
                    'Add a pet by pressing "+"',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.midText(context),
                  ),
                ],
              ),
            );
          } else {
            final pets = snapshot.data!;
            for (final pet in pets) {
              final url = pet['imageUrl'] as String?;
              if (url != null && url.isNotEmpty) {
                imageCache.evict(NetworkImage(url));
              }
            }
            return RefreshIndicator(
              onRefresh: _refreshPets,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                    child: Text(
                      'My pets',
                      style: AppTextStyles.titleText(context),
                    ),
                  ),
                  ...pets.map(
                    (pet) => PetCard(
                      petData: pet,
                      onTap: () async {
                        await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetDetailsScreen(petData: pet),
                          ),
                        );
                        _refreshPets();
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AddEditPetScreen(),
              transitionsBuilder: (_, animation, __, child) {
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );

          if (result == true) {
            _refreshPets();
          }
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: screenHeight * 0.08,
            height: screenHeight * 0.08,
            alignment: Alignment.center,
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
