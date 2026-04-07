import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/exam_viewmodel.dart';

class SubjectQuestionsView extends StatefulWidget {
  final String subject;
  const SubjectQuestionsView({super.key, required this.subject});

  @override
  State<SubjectQuestionsView> createState() => _SubjectQuestionsViewState();
}

class _SubjectQuestionsViewState extends State<SubjectQuestionsView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ExamViewModel>().loadQuestionBank());
  }

  @override
  Widget build(BuildContext context) {
    final examVm = context.watch<ExamViewModel>();
    
    // Filter all questions in the bank by the selected subject
    final filteredQuestions = examVm.bankQuestions.where((q) {
      return q.subject == widget.subject;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text("${widget.subject} Questions")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Subject: ${widget.subject}", style: const TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 8),
            Text("${filteredQuestions.length} Questions found", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const Divider(height: 32),
            Expanded(
              child: filteredQuestions.isEmpty
                  ? const Center(child: Text("No questions found for this subject"))
                  : ListView.builder(
                      itemCount: filteredQuestions.length,
                      itemBuilder: (context, index) {
                        final q = filteredQuestions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(q.type, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ),
                                    if (q.marks != null)
                                      Text("Marks: ${q.marks}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text("Q${index + 1}: ${q.text}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                                
                                if (q.imagePath != null) ...[
                                  const SizedBox(height: 12),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(q.imagePath!), 
                                      height: 180, 
                                      width: double.infinity, 
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                                    ),
                                  ),
                                ],
                                
                                if (q.type == 'MCQ' && q.options != null) ...[
                                  const SizedBox(height: 12),
                                  const Text("Options:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  ...q.options!.asMap().entries.map((entry) {
                                    int idx = entry.key;
                                    String opt = entry.value;
                                    String label = String.fromCharCode(65 + idx); // A, B, C, D
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.grey.shade200,
                                            child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(opt)),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                
                                if (q.type == 'Subjective') ...[
                                  const SizedBox(height: 16),
                                  const TextField(
                                    decoration: InputDecoration(
                                      hintText: "Type your answer here...",
                                      border: OutlineInputBorder(),
                                      filled: true,
                                      fillColor: Color(0xFFF9F9F9),
                                    ),
                                    maxLines: 3,
                                  ),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
