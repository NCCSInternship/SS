import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../viewmodels/exercise_viewmodel.dart';

class SubjectQuestionsView extends StatefulWidget {
  final String subject;
  const SubjectQuestionsView({super.key, required this.subject});

  @override
  State<SubjectQuestionsView> createState() => _SubjectQuestionsViewState();
}

class _SubjectQuestionsViewState extends State<SubjectQuestionsView> {
  Map<int, int?> _selectedAnswers = {};
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ExamViewModel>().loadQuestionBank());
  }

  @override
  Widget build(BuildContext context) {
    final examVm = context.watch<ExamViewModel>();
    final exerciseVm = context.read<ExerciseViewModel>();
    
    final filteredQuestions = examVm.bankQuestions.where((q) {
      bool matches = q.subject == widget.subject;
      if (examVm.selectedProgram != null) {
        String filterVal = examVm.selectedProgram.programType.toString().toLowerCase();
        String qVal = q.program?.toLowerCase() ?? "";
        if (!qVal.contains(filterVal.split(' ')[0]) && !filterVal.contains(qVal)) matches = false;
      }
      if (examVm.selectedClass != null) {
        String filterVal = examVm.selectedClass.toString().toLowerCase();
        String qVal = q.className?.toLowerCase() ?? "";
        if (!qVal.contains(filterVal) && !filterVal.contains(qVal)) matches = false;
      }
      return matches;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text("${widget.subject} Exercise")),
      body: Column(
        children: [
          Expanded(
            child: filteredQuestions.isEmpty
                ? const Center(child: Text("No questions found for this criteria."))
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
                                  Text("${widget.subject.toUpperCase()} PRACTICE SET", 
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  const SizedBox(height: 5),
                                  Text("${examVm.selectedProgram?.programType ?? ''} - ${examVm.selectedClass ?? ''}",
                                    style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600)),
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
                                        Text("${index + 1}. ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
                                        Expanded(child: Text(q.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.2))),
                                        if (q.marks != null) Text("(${q.marks})", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
                                      ],
                                    ),
                                    if (q.imagePath != null) Padding(padding: const EdgeInsets.only(top: 12, left: 20), child: Image.file(File(q.imagePath!), height: 180, fit: BoxFit.contain)),
                                    
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
                                              onTap: _submitted ? null : () => setState(() => _selectedAnswers[index] = optIdx),
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
                                                    if (_submitted && isSelected) Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red, size: 20),
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
                                          enabled: !_submitted,
                                          decoration: const InputDecoration(hintText: "Type your answer...", border: OutlineInputBorder()),
                                          maxLines: 3,
                                        ),
                                      ),
                                    const SizedBox(height: 15),
                                    const Divider(),
                                  ],
                                ),
                              );
                            }),
                            
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _submitted ? () => Navigator.pop(context) : () {
                                    setState(() => _submitted = true);
                                    exerciseVm.markCompleted("${widget.subject} Exercise (${examVm.selectedClass})");
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Exercise submitted and added to portfolio!")));
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: _submitted ? Colors.grey : Colors.blue),
                                  child: Text(_submitted ? "Finish" : "Submit and Mark Completed"),
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
