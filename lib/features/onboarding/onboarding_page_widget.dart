import 'package:flutter/material.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/features/onboarding/onboarding_page_data.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPageData data;

  const OnboardingPageWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image - Prend la majorité de l'espace sur les grands écrans
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: data.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: DramusColors.primaryTeal,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Icon(Icons.broken_image,
                      size: 50, color: Theme.of(context).disabledColor),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          // Texte - Scrollable sur les petits écrans pour éviter l'overflow
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 24, // Taille fixe raisonnable
                              ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: DramusColors.secondaryText,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
