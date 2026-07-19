import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/features/onboarding/onboarding_page_data.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPageWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Utilisation de MediaQuery pour des calculs 100% fluides (sans seuil fixe)
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    // Calcul proportionnel et borné pour les polices
    final titleFontSize = (size.width * 0.065).clamp(20.0, 32.0);
    final descFontSize = (size.width * 0.04).clamp(14.0, 18.0);

    // Padding proportionnel fluides
    final paddingValue = (size.width * 0.05).clamp(16.0, 32.0);

    // Hauteur d'image ajustée organiquement selon l'orientation
    final imageHeightRatio = isLandscape ? 0.35 : 0.45;
    final imageHeight = (size.height * imageHeightRatio).clamp(150.0, 500.0);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              // Empêche la vue de s'écraser, garantissant un scroll si nécessaire
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.all(paddingValue),
                child: Center(
                  child: ConstrainedBox(
                    // Contrainte élégante pour tablettes
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // S'adapte au contenu
                      children: [
                        // Image
                        Container(
                          height: imageHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            child: Image.asset(
                              data.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                debugPrint('Error loading image: $error');
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.image_not_supported,
                                        size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: paddingValue),

                        // Texte
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: titleFontSize,
                                height: 1.2,
                              ),
                        ),

                        SizedBox(
                            height: paddingValue * 0.5), // Espace dynamique

                        Text(
                          data.description,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: DramusColors.secondaryText,
                                    height: 1.5,
                                    fontSize: descFontSize,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
