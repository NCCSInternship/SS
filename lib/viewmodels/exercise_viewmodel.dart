import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/exercise_model.dart';

class ExerciseViewModel extends ChangeNotifier {
  List<Exercise> _exercises = [];
  List<Exercise> get exercises => _exercises;

  Future<void> loadExercises() async {
    final prefs = await SharedPreferences.getInstance();
    final String? exercisesJson = prefs.getString('saved_exercises');
    if (exercisesJson != null) {
      final List<dynamic> decoded = json.decode(exercisesJson);
      _exercises = decoded.map((item) => Exercise.fromMap(item)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_exercises.map((e) => e.toMap()).toList());
    await prefs.setString('saved_exercises', encoded);
  }

  Future<void> addExercise({
    required String title,
    String? program,
    String? className,
    String? subject,
    List<String>? questionIds,
  }) async {
    final newExercise = Exercise(
      title: title,
      program: program,
      className: className,
      subject: subject,
      questionIds: questionIds,
    );
    _exercises.add(newExercise);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateExercise(int index, {
    required String title,
    String? program,
    String? className,
    String? subject,
    List<String>? questionIds,
  }) async {
    if (index >= 0 && index < _exercises.length) {
      _exercises[index] = Exercise(
        title: title,
        program: program,
        className: className,
        subject: subject,
        questionIds: questionIds,
      );
      await _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> deleteExercise(int index) async {
    if (index >= 0 && index < _exercises.length) {
      _exercises.removeAt(index);
      await _saveToPrefs();
      notifyListeners();
    }
  }
}
