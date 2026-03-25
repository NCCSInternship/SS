import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool isLoading = false;
  bool isLoggedIn = false;
  String role = "";
  String? token;

  Future init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final savedRole = prefs.getString("role");

    if (token != null && savedRole != null) {
      isLoggedIn = true;
      role = savedRole;
    }

    notifyListeners();
  }

  Future<bool> login(String email, String password, String selectedRole) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(email, password);

      print("LOGIN RESPONSE: $response");

      if (response["status"] == true) {

        final prefs = await SharedPreferences.getInstance();

        final String apiToken = response["token"];
        final String apiRole = response["user"]["username"].toString().toLowerCase();

        //  Role validation
        if (apiRole != selectedRole.toLowerCase()) {
          print("Role mismatch");

          isLoading = false;
          notifyListeners();
          return false;
        }

        // ✅ SAVE TOKEN
        await prefs.setString("token", apiToken);
        await prefs.setString("role", apiRole);

        token = apiToken;
        isLoggedIn = true;
        role = apiRole;

        isLoading = false;
        notifyListeners();
        return true;
      }

    } catch (e) {
      print("Login error: $e");
    }

    isLoggedIn = false;
    role = "";
    isLoading = false;
    notifyListeners();
    return false;
  }

  Future logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("role");

    isLoggedIn = false;
    role = "";
    notifyListeners();
  }
}
