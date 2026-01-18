import 'package:flutter/foundation.dart';
import 'package:dramus/models/user_model.dart';
import 'package:dramus/core/api/token_storage.dart';

class AuthController extends ChangeNotifier {
  AuthController();

  final TokenStorage _storage = TokenStorage();
  User? _user;

  User? get user => _user;
  String? get role => _user?.role;

  Future<void> loadFromStorage() async {
    final json = await _storage.getUserJson();
    if (json != null) {
      _user = User.fromJson(json);
      notifyListeners();
    }
  }

  void setUser(User? u) {
    _user = u;
    notifyListeners();
  }

  Future<void> signOut() async {
    _user = null;
    await _storage.clear();
    notifyListeners();
  }
}
