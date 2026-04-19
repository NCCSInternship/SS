import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_model.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/exercise_viewmodel.dart';
import 'add_question_screen.dart';

class ExerciseQuestionsView extends StatefulWidget {
  final Exercise exercise;
  const ExerciseQuestionsView({super.key, required this.exercise});

  @override
  State<ExerciseQuestionsView> createState() => _ExerciseQuestionsViewState();
}

class _ExerciseQuestionsViewState extends State<ExerciseQuestionsView> {
  // Store student selections for MCQs: questionIndex -> optionIndex
  Map<int, int?> _selectedAnswers = {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() {
    Future.microtask(() => context.read<ExamViewModel>().loadQuestionBank());
  }

  @override
  Widget build(BuildContext context) {
    final examVm = context.watch<ExamViewModel>();
    final authVm = context.read<AuthViewModel>();
    final exerciseVm = context.read<ExerciseViewModel>();
    final bool isTeacher = authVm.role == "teacher";
    
    // Logic: ONLY show questions specifically linked to THIS exercise title
    final filteredQuestions = examVm.bankQuestions.where((q) {
      return q.exerciseTitle != null && q.exerciseTitle == widget.exercise.title;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text(widget.exercise.title)),
      body: Column(
        children: [
          Expanded(
            child: filteredQuestions.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "No questions linked to this exercise yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Text(widget.exercise.title.toUpperCase(), 
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  const SizedBox(height: 15),
                                  const Divider(),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                            ...List.generate(filteredQuestions.length, (index) {
                              final q = filteredQuestions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("${index + 1}. ", 
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
                                        Expanded(
                                          child: Text(q.text, 
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.2)),
                                        ),
                                        const SizedBox(width: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2), 
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (q.marks != null)
                                                Text("(${q.marks})", 
                                                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                                              if (isTeacher) ...[
                                                const SizedBox(width: 6),
                                                GestureDetector(
                                                  onTap: () {
                                                    final originalIndex = examVm.bankQuestions.indexOf(q);
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => AddQuestionScreen(
                                                          questionToEdit: q,
                                                          editIndex: originalIndex,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: const Icon(Icons.edit, color: Colors.blue, size: 16),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (q.imagePath != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12, left: 20),
                                        child: Image.file(File(q.imagePath!), height: 180, fit: BoxFit.contain),
                                      ),
                                    
                                    // Student Answer Interface
                                    if (q.type == 'MCQ' && q.options != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12, left: 20),
                                        child: Column(
                                          children: q.options!.asMap().entries.map((entry) {
                                            final int optIdx = entry.key;
                                            final String optText = entry.value;
                                            final bool isSelected = _selectedAnswers[index] == optIdx;
                                            final bool isCorrect = q.correctAnswer == optText;

                                            return InkWell(
                                              onTap: _submitted || isTeacher ? null : () {
                                                setState(() {
                                                  _selectedAnswers[index] = optIdx;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: _getOptionColor(isSelected, isCorrect),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text("${String.fromCharCode(65 + optIdx)}. ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    Expanded(child: Text(optText)),
                                                    if (_submitted && isSelected)
                                                      Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red, size: 20),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    
                                    if (q.type == 'Subjective')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12, left: 20),
                                        child: TextField(
                                          enabled: !_submitted && !isTeacher,
                                          decoration: const InputDecoration(
                                            hintText: "Type your answer...",
                                            border: OutlineInputBorder(),
                                          ),
                                          maxLines: 3,
                                        ),
                                      ),

                                    const SizedBox(height: 15),
                                    const Divider(),
                                  ],
                                ),
                              );
                            }),
                            
                            if (!isTeacher && filteredQuestions.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _submitted ? () => Navigator.pop(context) : () {
                                      setState(() => _submitted = true);
                                      exerciseVm.markCompleted(widget.exercise.title);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Exercise submitted and marked as completed!")),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: _submitted ? Colors.grey : Colors.blue),
                                    child: Text(_submitted ? "Go Back" : "Submit Exercise"),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getOptionColor(bool isSelected, bool isCorrect) {
    if (!_submitted) return isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent;
    if (isSelected) return isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
    return Colors.transparent;
  }
}
