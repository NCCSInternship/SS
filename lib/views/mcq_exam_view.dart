import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../models/program_model.dart';

class MCQExamView extends StatefulWidget {
  const MCQExamView({super.key});

  @override
  State<MCQExamView> createState() => _MCQExamViewState();
}

class _MCQExamViewState extends State<MCQExamView> {
  final Map<String, List<String>> _programToClasses = {
    'Primary': ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5', 'Class 6', 'Class 7', 'Class 8'],
    'Secondary': ['Class 9', 'Class 10'],
    '+2': ['Class 11', 'Class 12'],
    'Bachelor': ['1st Year', '2nd Year', '3rd Year', '4th Year'],
    'Bachelor Program': ['1st Year', '2nd Year', '3rd Year', '4th Year'],
    'Masters Program': ['1st Year', '2nd Year'],
    'Masters': ['1st Year', '2nd Year'],
  };

  Map<int, int?> selected = {};
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ExamViewModel>().fetchFilterData());
  }

  @override
  Widget build(BuildContext context) {
    final exams = context.watch<ExamViewModel>();

    // Filtering Logic for Exam
    final mcqs = exams.bankQuestions.where((q) {
      if (q.type != 'MCQ') return false;

      if (exams.selectedProgram != null) {
        String filterVal = exams.selectedProgram.programType.toString().toLowerCase();
        String qVal = q.program?.toLowerCase() ?? "";
        if (!qVal.contains(filterVal.split(' ')[0]) && !filterVal.contains(qVal)) return false;
      }

      if (exams.selectedClass != null) {
        String filterVal = exams.selectedClass.toString().toLowerCase();
        String qVal = q.className?.toLowerCase() ?? "";
        if (!qVal.contains(filterVal) && !filterVal.contains(qVal)) return false;
      }

      if (exams.selectedSubject != null) {
        String filterVal = exams.selectedSubject is Map 
            ? exams.selectedSubject['subject_name'].toString().toLowerCase()
            : exams.selectedSubject.toString().toLowerCase();
        String qVal = q.subject?.toLowerCase() ?? "";
        if (!qVal.contains(filterVal) && !filterVal.contains(qVal)) return false;
      }

      return true;
    }).toList();

    List<String> classList = [];
    if (exams.selectedProgram != null) {
      classList = _programToClasses[exams.selectedProgram.programType] ?? [];
    }

    double totalMarksEarned = 0;
    double maxPossibleMarks = 0;
    int correctCount = 0;

    if (submitted) {
      for (int i = 0; i < mcqs.length; i++) {
        final q = mcqs[i];
        final options = q.options ?? [];
        final qMarks = double.tryParse(q.marks ?? '0') ?? 0;
        maxPossibleMarks += qMarks;

        if (selected[i] != null && options[selected[i]!] == q.correctAnswer) {
          correctCount++;
          totalMarksEarned += qMarks;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("MCQ Exam"),
        actions: [
          if (!submitted)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                exams.setSelectedProgram(null);
                exams.setSelectedClass(null);
                exams.setSelectedSubject(null);
                setState(() => selected = {});
              },
            )
        ],
      ),
      body: Column(
        children: [
          // --- FILTER HEADER (Only visible if not submitted) ---
          if (!submitted)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  _buildDropdown<dynamic>(
                    label: "Program Type",
                    value: exams.selectedProgram,
                    items: exams.bankPrograms,
                    onChanged: (val) {
                      exams.setSelectedProgram(val);
                      exams.setSelectedClass(null);
                      setState(() => selected = {});
                    },
                    displayName: (item) => item.programType,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Class", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Color(0xFFFAFAFA)),
                          initialValue: (exams.selectedClass is String && classList.contains(exams.selectedClass)) ? exams.selectedClass : null,
                          items: classList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            exams.setSelectedClass(val);
                            setState(() => selected = {});
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildDropdown<dynamic>(
                          label: "Subject",
                          value: exams.selectedSubject,
                          items: exams.subjects,
                          onChanged: (val) {
                            exams.setSelectedSubject(val);
                            setState(() => selected = {});
                          },
                          displayName: (item) => item is Map ? item['subject_name'] : item.toString(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (submitted)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  const Text("Exam Result", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Score: $correctCount / ${mcqs.length}", style: const TextStyle(fontSize: 18)),
                  Text("Total Marks: ${totalMarksEarned.toStringAsFixed(1)} / ${maxPossibleMarks.toStringAsFixed(1)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),

          Expanded(
            child: mcqs.isEmpty
                ? const Center(child: Text("No questions match your selection."))
                : ListView.builder(
                    itemCount: mcqs.length,
                    itemBuilder: (_, i) {
                      final q = mcqs[i];
                      final options = q.options ?? [];

                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Question ${i + 1}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                      if (q.marks != null)
                                        Text("Marks: ${q.marks}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(q.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            if (q.imagePath != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(q.imagePath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                                ),
                              ),
                            const SizedBox(height: 8),
                            ...List.generate(options.length, (o) {
                              return RadioListTile<int>(
                                value: o,
                                groupValue: selected[i],
                                title: Text(options[o]),
                                onChanged: submitted ? null : (v) => setState(() => selected[i] = v),
                              );
                            }),
                            if (submitted)
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  (selected[i] != null && options[selected[i]!] == q.correctAnswer)
                                      ? "✔ Correct"
                                      : "❌ Wrong (Correct: ${q.correctAnswer})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: (selected[i] != null && options[selected[i]!] == q.correctAnswer) ? Colors.green : Colors.red,
                                  ),
                                ),
                              )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: mcqs.isEmpty
              ? null
              : submitted
                  ? () => Navigator.pop(context)
                  : () {
                      if (selected.length < mcqs.length) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please answer all questions before submitting.'), backgroundColor: Colors.red),
                        );
                      } else {
                        setState(() => submitted = true);
                      }
                    },
          child: Text(submitted ? "Finish" : "Submit Exam"),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required dynamic value,
    required List<T> items,
    required Function(dynamic) onChanged,
    required String Function(dynamic) displayName,
  }) {
    // FIX: Explicitly handle the T type to prevent '() => Null' casting issues
    T? safeValue;
    try {
      safeValue = items.firstWhere(
        (item) {
          if (value == null) return false;
          if (item == value) return true;
          if (item is Map && value is Map) return item['id'] == value['id'];
          if (item is Datum && value is Datum) return item.id == value.id;
          return false;
        }
      );
    } catch (_) {
      safeValue = null;
    }

    return DropdownButtonFormField<T>(
      isExpanded: true,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.grey[50]),
      initialValue: safeValue,
      items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(displayName(item)))).toList(),
      onChanged: onChanged,
    );
  }
}
