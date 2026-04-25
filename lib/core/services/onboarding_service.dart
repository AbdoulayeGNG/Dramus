import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingKey = 'has_seen_onboarding';

  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool hasSeenOnboarding() {
    return _prefs?.getBool(_onboardingKey) ?? false;
  }

  Future<void> markOnboardingAsSeen() async {
    await _prefs?.setBool(_onboardingKey, true);
  }
}
