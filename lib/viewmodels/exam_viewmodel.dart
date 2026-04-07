import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/mcq_dummy.dart';
import '../data/program_classes.dart';
import '../models/exam_model.dart';
import '../models/question_model.dart';
import '../models/program_model.dart';
import '../services/api_service.dart';
import 'dart:convert';

class ExamViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Exam> exams = [];
  List<Question> _bankQuestions = [];
  List<Question> get bankQuestions => _bankQuestions;

  // Initialize with dummy data immediately to remove delay
  List<Datum> _bankPrograms = [];
  List<dynamic> _classes = [];
  List<dynamic> _subjects = [];
  
  final List<String> institutions = mockInstitutions;
  final List<String> boards = mockBoards;

  List<Datum> get bankPrograms => _bankPrograms;
  List<dynamic> get classes => _classes;
  List<dynamic> get subjects => _subjects;

  dynamic selectedProgram;
  dynamic selectedClass;
  dynamic selectedSubject;
  String? selectedInstitution;
  String? selectedBoard;

  ExamViewModel() {
    _initializeMockData();
    loadQuestionBank();
  }

  void _initializeMockData() {
    // Populate Programs immediately from programClasses keys
    _bankPrograms = programClasses.keys.toList().asMap().entries.map((entry) {
      String name = entry.value;
      // FIX: Handle short names like "+2" to prevent RangeError
      String code = name.length >= 3 ? name.toUpperCase().substring(0, 3) : name.toUpperCase();
      
      return Datum(
        id: entry.key + 1,
        programType: name,
        programTypeCode: code,
        status: '1',
        createdBy: 1,
        updatedBy: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    // Populate Classes
    _classes = programClasses.values.expand((element) => element).toSet().map((c) => {'class_name': c}).toList();

    // Populate Subjects
    _subjects = mockSubjects.map((s) => {'subject_name': s}).toList();
  }

  Future<void> loadQuestionBank() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('question_bank_data');

    if (data != null) {
      List<dynamic> jsonList = json.decode(data);
      _bankQuestions = jsonList.map((item) => Question.fromMap(item)).toList();
    } else {
      _bankQuestions = [];
    }

    // Still call fetch to sync with API if needed, but UI already has mock data
    fetchFilterData();
    loadExams(); 
    
    for (var q in exams.expand((e) => e.questions)) {
      bool exists = _bankQuestions.any((bq) => bq.text == q.text);
      if (!exists) {
        _bankQuestions.add(q);
      }
    }

    notifyListeners();
  }

  Future<void> fetchFilterData() async {
    final programRes = await _apiService.fetchPrograms();
    if (programRes != null && programRes.data.data.isNotEmpty) {
      _bankPrograms = programRes.data.data;
    }

    final classRes = await _apiService.fetchClasses();
    if (classRes['status'] == true) {
      _classes = classRes['data']['data'] ?? _classes;
    }

    final subjectRes = await _apiService.fetchSubjects();
    if (subjectRes['status'] == true) {
      _subjects = subjectRes['data']['data'] ?? _subjects;
    }

    notifyListeners();
  }

  void setSelectedProgram(dynamic val) {
    selectedProgram = val;
    notifyListeners();
  }

  void setSelectedClass(dynamic val) {
    selectedClass = val;
    notifyListeners();
  }

  void setSelectedSubject(dynamic val) {
    selectedSubject = val;
    notifyListeners();
  }

  void setSelectedInstitution(String? val) {
    selectedInstitution = val;
    notifyListeners();
  }

  void setSelectedBoard(String? val) {
    selectedBoard = val;
    notifyListeners();
  }

  void loadExams() {
    final questions = mcqQuestions.asMap().entries.map((entry) {
      final q = entry.value;
      final options = List<String>.from(q["options"]);

      return Question(
        text: q["q"],
        type: 'MCQ',
        options: options,
        correctAnswer: options[q["answer"]],
        program: q["program"],
        className: q["className"],
        subject: q["subject"],
        isForBank: true, 
      );
    }).toList();

    exams = [
      Exam(
        id: "exam1",
        title: "Computer Basics Test",
        questions: questions,
      ),
    ];
  }
}
