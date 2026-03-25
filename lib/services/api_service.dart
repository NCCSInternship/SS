import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/program_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    return {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  final String baseUrl = "http://192.168.0.117:8000/api";

  // 1. AUTH: LOGIN
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("Login error: $e");
      return {
        "status": false,
        "message": "Network error"
      };
    }
  }

  // 2. AUTH: PROFILE
  Future<Map<String, dynamic>> fetchProfile(String token) async {
    return {"status": true, "data": {"name": "Test User", "email": "user@test.com"}};
  }

  // 3. PROGRAM TYPES: GET ALL (Instant)
  Future<ProgramResponse?> fetchPrograms() async {
    final url = Uri.parse("$baseUrl/v1/program-types");

    try {
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      print("PROGRAM API STATUS: ${response.statusCode}");
      print("PROGRAM API BODY: ${response.body}");

      if (response.statusCode == 200) {
        return programResponseFromJson(response.body);
      } else {
        print("Program API failed");
        return null;
      }
    } catch (e) {
      print("Program API error: $e");
      return null;
    }
  }

  // 7. SUBJECTS: GET ALL (Instant)
  Future<Map<String, dynamic>> fetchSubjects() async {
    final url = Uri.parse("$baseUrl/v1/subjects");

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      print("SUBJECT API: ${response.body}");

      return jsonDecode(response.body);
    } catch (e) {
      print("Subject API error: $e");
      return {};
    }
  }

  // 8. CLASSES: GET ALL (Instant)
  Future<Map<String, dynamic>> fetchClasses() async {
      final url = Uri.parse("$baseUrl/v1/classes");

      try {
        final headers = await _getHeaders();
        final response = await http.get(url, headers: headers);

        print("CLASS API: ${response.body}");

        return jsonDecode(response.body);
      } catch (e) {
        print("Class API error: $e");
        return {};
      }
  }

  Map<String, dynamic> _fallbackSubjects() {
    return {
      "status": true,
      "data": {
        "data": [
          {"id": 1, "subject_name": "Math"},
          {"id": 2, "subject_name": "Science"},
          {"id": 3, "subject_name": "English"},
          {"id": 4, "subject_name": "Computer"},
          {"id": 5, "subject_name": "Social Studies"}
        ]
      }
    };
  }

  Map<String, dynamic> _fallbackClasses() {
    return {
      "status": true,
      "data": {
        "data": [
          {"id": 1, "class_name": "Class 1"},
          {"id": 2, "class_name": "Class 2"},
          {"id": 3, "class_name": "Class 3"},
          {"id": 4, "class_name": "Class 4"},
          {"id": 5, "class_name": "Class 5"},
          {"id": 6, "class_name": "Class 6"},
          {"id": 7, "class_name": "Class 7"},
          {"id": 8, "class_name": "Class 8"},
          {"id": 9, "class_name": "Class 9"},
          {"id": 10, "class_name": "Class 10"},
          {"id": 11, "class_name": "Class 11"},
          {"id": 12, "class_name": "Class 12"},
          {"id": 13, "class_name": "1st Year"},
          {"id": 14, "class_name": "2nd Year"},
          {"id": 15, "class_name": "3rd Year"},
          {"id": 16, "class_name": "4th Year"}
        ]
      }
    };
  }

  ProgramResponse? _fallbackPrograms() {
    String jsonString = '''
    {
      "status": true,
      "data": {
        "current_page": 1,
        "data": [
          { "id": 1, "program_type": "Primary", "program_type_code": "PRI", "status": "1", "created_by": 1, "updated_by": 1, "created_at": "2023-01-01T00:00:00.000000Z", "updated_at": "2023-01-01T00:00:00.000000Z" },
          { "id": 2, "program_type": "Secondary", "program_type_code": "SEC", "status": "1", "created_by": 1, "updated_by": 1, "created_at": "2023-01-01T00:00:00.000000Z", "updated_at": "2023-01-01T00:00:00.000000Z" },
          { "id": 3, "program_type": "+2", "program_type_code": "HSE", "status": "1", "created_by": 1, "updated_by": 1, "created_at": "2023-01-01T00:00:00.000000Z", "updated_at": "2023-01-01T00:00:00.000000Z" },
          { "id": 4, "program_type": "Bachelor", "program_type_code": "BAC", "status": "1", "created_by": 1, "updated_by": 1, "created_at": "2023-01-01T00:00:00.000000Z", "updated_at": "2023-01-01T00:00:00.000000Z" },
          { "id": 5, "program_type": "Masters Program", "program_type_code": "MAS", "status": "1", "created_by": 1, "updated_by": 1, "created_at": "2023-01-01T00:00:00.000000Z", "updated_at": "2023-01-01T00:00:00.000000Z" }
        ],
        "first_page_url": "", "from": 1, "last_page": 1, "last_page_url": "", "links": [], "next_page_url": null, "path": "", "per_page": 10, "prev_page_url": null, "to": 5, "total": 5
      }
    }
    ''';
    return programResponseFromJson(jsonString);
  }
}
