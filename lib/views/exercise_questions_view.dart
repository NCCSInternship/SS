import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise_model.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'add_question_screen.dart';

class ExerciseQuestionsView extends StatefulWidget {
  final Exercise exercise;
  const ExerciseQuestionsView({super.key, required this.exercise});

  @override
  State<ExerciseQuestionsView> createState() => _ExerciseQuestionsViewState();
}

class _ExerciseQuestionsViewState extends State<ExerciseQuestionsView> {
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
    final bool isTeacher = authVm.role == "teacher";
    
    // Logic: Only show questions specifically linked to THIS exercise title
    final filteredQuestions = examVm.bankQuestions.where((q) {
      return q.exerciseTitle == widget.exercise.title;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text(widget.exercise.title)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Metadata Criteria:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[700])),
                const SizedBox(height: 4),
                Text("${widget.exercise.program ?? 'N/A'} - ${widget.exercise.className ?? 'N/A'} - ${widget.exercise.subject ?? 'N/A'}", 
                  style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filteredQuestions.isEmpty
                ? const Center(child: Text("No questions linked to this exercise yet."))
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
                                        // Numbering
                                        Text("${index + 1}. ", 
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
                                        
                                        // Question Text
                                        Expanded(
                                          child: Text(q.text, 
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.2)),
                                        ),
                                        
                                        const SizedBox(width: 8),
                                        
                                        // Metadata (Marks and Edit)
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
                                    if (q.type == 'MCQ' && q.options != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12, left: 20),
                                        child: Column(
                                          children: q.options!.asMap().entries.map((entry) {
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 3),
                                              child: Row(
                                                children: [
                                                  Text("${String.fromCharCode(65 + entry.key)}. ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  Expanded(child: Text(entry.value)),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    const SizedBox(height: 15),
                                    const Divider(),
                                  ],
                                ),
                              );
                            }),
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
}
