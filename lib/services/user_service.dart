import 'package:flutter/foundation.dart';
import 'package:dramus/models/user_model.dart';

class UserService extends ChangeNotifier {
  late User _currentUser;
  late List<User> _allUsers;

  UserService() {
    _initializeSampleData();
  }

  User get currentUser => _currentUser;
  List<User> get allUsers => _allUsers;

  void _initializeSampleData() {
    _currentUser = User(
      id:"user1",
      firstName: 'Jean',
      lastName: 'Diallo',
      email: 'jean.diallo@example.com',
      password: 'password123',
      phone: '+224 620 123 456',
      role: 'individual',
      avatar  : 'https://i.pravatar.cc/150?img=12',
    );

    _allUsers = [
      _currentUser,
      User(
        id:"agent1",
        firstName: 'Mamadou',
        lastName: 'Diallo',
        email: 'mamadou@dramus.gn',
        password: "agentpass",
        phone: '+224 620 112 233',
        role: 'agent',
        avatar  : 'https://i.pravatar.cc/150?img=5',
      ),
      User(
        id:"agency1",
        firstName: 'Fatoumata',
        lastName: 'Bah',
        email: 'fatoumata@dramus.gn',
        password: "agentpass",
        phone: '+224 620 445 556',
        role: 'agency',
        avatar: 'https://i.pravatar.cc/150?img=8',
      ),
      User(
        id:"agent2",
        firstName: 'Lamine',
        lastName: 'Toure',
        email: 'lamine@dramus.gn',
        password: "agentpass",
        phone: '+224 620 789 123',
        role: 'agent',
        avatar: 'https://i.pravatar.cc/150?img=15',
      ),
      User(
        id:"agent3",
        firstName: 'Mariama',
        lastName: 'Bah',
        email: 'mariama@dramus.gn',
        password: "agentpass",
        phone: '+224 620 234 567',
        role: 'agent',
        avatar: 'https://i.pravatar.cc/150?img=20',
      ),
      User(
        id:"admin1",
        firstName: 'Admin',
        lastName: 'DRAMUS',
        email: 'admin@dramus.gn',
        password: "adminpass",
        phone: '+224 620 000 000',
        role: 'admin',
        avatar: 'https://i.pravatar.cc/150?img=33',
      ),
    ];
  }

  User? getUserById(String id) {
    try {
      return _allUsers.firstWhere((user) => user.email == id);
    } catch (e) {
      return null;
    }
  }

  List<User> getUsersByRole(String role) {
    return _allUsers.where((user) => user.role == role).toList();
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    final index = _allUsers.indexWhere((u) => u == user);
    if (index != -1) {
      _allUsers[index] = user;
    }
    notifyListeners();
  }

  void addFavorite(String listingId) {
    /*if (!_currentUser.favoriteListingIds.contains(listingId)) {
      _currentUser = _currentUser.copyWith(
        favoriteListingIds: [..._currentUser.favoriteListingIds, listingId],
      );
      notifyListeners();
    }*/
  }

  void removeFavorite(String listingId) {
    /*if (_currentUser.favoriteListingIds.contains(listingId)) {
      _currentUser = _currentUser.copyWith(
        favoriteListingIds: _currentUser.favoriteListingIds
            .where((id) => id != listingId)
            .toList(),
      );
      notifyListeners();
    }*/
  }
}
