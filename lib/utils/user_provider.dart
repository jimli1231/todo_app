import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  void setUser(Map<String, dynamic>? user) {
    debugPrint('Setting user: $user');
    _user = user;
    notifyListeners();
  }

  bool get isLoggedIn {
    final loggedIn = _user != null && _user!.isNotEmpty;
    debugPrint('Checking login status: $loggedIn');
    return loggedIn;
  }

  void logout() {
    debugPrint('Logging out user: $_user');
    _user = null;
    notifyListeners();
  }
}
