import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dramus/theme.dart';
import 'package:dramus/features/onboarding/onboarding_provider.dart';
import 'package:dramus/features/onboarding/onboarding_page_data.dart';
import 'package:dramus/features/onboarding/onboarding_page_widget.dart';
import 'package:dramus/screens/auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Trouvez votre bien idéal',
      description:
          'Explorez des maisons, terrains et appartements partout à Conakry en quelques clics.',
      imageUrl:
          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?q=80&w=1000&auto=format&fit=crop',
    ),
    OnboardingPageData(
      title: 'Achetez ou louez en toute confiance',
      description:
          'Accédez à des annonces fiables, avec photos, localisation et informations détaillées.',
      imageUrl:
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=1000&auto=format&fit=crop',
    ),
    OnboardingPageData(
      title: 'Discutez directement avec les annonceurs',
      description:
          'Contactez rapidement les agences, agents et particuliers grâce à la messagerie DRAMUS.',
      imageUrl:
          'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?q=80&w=1000&auto=format&fit=crop',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingProvider(),
      child: Scaffold(
        backgroundColor: DramusColors.white,
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
                  provider.completeOnboarding(context, const LoginScreen()),
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
              color: DramusColors.lightGray,
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
              provider.completeOnboarding(context, const LoginScreen());
            } else {
              provider.nextPage();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DramusColors.primaryTeal,
            foregroundColor: DramusColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
          child: Text(
            isLastPage ? 'Commencer' : 'Suivant',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DramusColors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
