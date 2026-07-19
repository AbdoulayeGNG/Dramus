import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/features/onboarding/onboarding_provider.dart';
import 'package:dramus/features/onboarding/onboarding_page_data.dart';
import 'package:dramus/features/onboarding/onboarding_page_widget.dart';
import 'package:dramus/screens/clients/main_app_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Trouvez votre bien idéal',
      description:
          'Explorez des maisons, terrains et appartements partout à Conakry en quelques clics.',
      imageUrl: 'assets/images/onboarding1.jpeg',
    ),
    OnboardingPageData(
      title: 'Achetez ou louez en toute confiance',
      description:
          'Accédez à des annonces fiables, avec photos, localisation et informations détaillées.',
      imageUrl: 'assets/images/onboarding2.jpeg',
    ),
    OnboardingPageData(
      title: 'Discutez directement avec les annonceurs ou clients',
      description:
          'Contactez rapidement les agences, agents et particuliers grâce à la messagerie DRAMUS.',
      imageUrl: 'assets/images/onboarding3.jpeg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Consumer<OnboardingProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  _buildHeader(context, provider),
                  _buildProgressBar(context, provider.currentIndex),
                  Expanded(
                    child: PageView.builder(
                      controller: provider.pageController,
                      itemCount: _pages.length,
                      onPageChanged: provider.onPageChanged,
                      itemBuilder: (context, index) {
                        return OnboardingPageWidget(data: _pages[index]);
                      },
                    ),
                  ),
                  _buildBottomButton(context, provider),
                  const SizedBox(height: AppSpacing.xl),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, OnboardingProvider provider) {
    return Padding(
      padding: AppSpacing.paddingLg,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: provider.currentIndex > 0
                ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios,
                        size: 20, color: DramusColors.primaryTeal),
                    onPressed: provider.previousPage,
                  )
                : const SizedBox.shrink(),
          ),
          Text(
            'DRAMUS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: DramusColors.primaryTeal,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
          ),
          const Spacer(),
          if (provider.currentIndex < 2)
            TextButton(
              onPressed: () =>
                  provider.completeOnboarding(context, const MainAppScreen()),
              child: Text(
                'Passer',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: DramusColors.secondaryText,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            )
          else
            const SizedBox(width: 60), // Match Passer button width roughly
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, int currentIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Stack(
        children: [
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: MediaQuery.of(context).size.width * ((currentIndex + 1) / 3),
            decoration: BoxDecoration(
              color: DramusColors.primaryTeal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, OnboardingProvider provider) {
    final isLastPage = provider.currentIndex == 2;
    return Padding(
      padding: AppSpacing.paddingLg,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () {
            if (isLastPage) {
              provider.completeOnboarding(context, const MainAppScreen());
            } else {
              provider.nextPage();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DramusColors.primaryTeal,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
          child: Text(
            isLastPage ? 'Commencer' : 'Suivant',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
