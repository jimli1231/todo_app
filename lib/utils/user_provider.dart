import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  void setUser(Map<String, dynamic>? user) {
    _user = user;
    notifyListeners();
  }

  bool get isLoggedIn => _user != null;

  void logout() {
    _user = null;
    notifyListeners();
  }
}
