import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../models/question_model.dart';
import '../models/program_model.dart';
import 'dart:io';

class StudentQuestionBankView extends StatefulWidget {
  const StudentQuestionBankView({super.key});

  @override
  State<StudentQuestionBankView> createState() => _StudentQuestionBankViewState();
}

class _StudentQuestionBankViewState extends State<StudentQuestionBankView> {
  final Map<String, List<String>> _programToClasses = {
    'Primary': ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5', 'Class 6', 'Class 7', 'Class 8'],
    'Secondary': ['Class 9', 'Class 10'],
    '+2': ['Class 11', 'Class 12'],
    'Bachelor': ['1st Year', '2nd Year', '3rd Year', '4th Year'],
    'Bachelor Program': ['1st Year', '2nd Year', '3rd Year', '4th Year'],
    'Masters Program': ['1st Year', '2nd Year'],
    'Masters': ['1st Year', '2nd Year'],
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ExamViewModel>().fetchFilterData());
  }

  @override
  Widget build(BuildContext context) {
    final exams = context.watch<ExamViewModel>();

    // Check if mandatory filters are selected
    final bool filtersSelected = exams.selectedProgram != null && 
                                 exams.selectedClass != null && 
                                 exams.selectedSubject != null;

    // Filtering Logic
    final filteredQuestions = !filtersSelected ? [] : exams.bankQuestions.where((q) {
      if (!q.isForBank) return false;

      // 1. Program Filter
      if (exams.selectedProgram != null) {
        String filterVal = exams.selectedProgram.programType.toString().toLowerCase();
        String qVal = q.program?.toLowerCase() ?? "";
        if (!qVal.contains(filterVal.split(' ')[0]) && !filterVal.contains(qVal)) return false;
      }

      // 2. Class Filter
      if (exams.selectedClass != null) {
        String filterVal = exams.selectedClass.toString().toLowerCase();
        String qVal = q.className?.toLowerCase() ?? "";
        if (!qVal.contains(filterVal) && !filterVal.contains(qVal)) return false;
      }

      // 3. Subject Filter
      if (exams.selectedSubject != null) {
        String filterVal = exams.selectedSubject is Map 
            ? exams.selectedSubject['subject_name'].toString().toLowerCase()
            : exams.selectedSubject.toString().toLowerCase();
        String qVal = q.subject?.toLowerCase() ?? "";
        if (!qVal.contains(filterVal) && !filterVal.contains(qVal)) return false;
      }

      // 4. Institution Filter
      if (exams.selectedInstitution != null) {
        if (q.institution != exams.selectedInstitution) return false;
      }

      // 5. Board Filter
      if (exams.selectedBoard != null) {
        if (q.board != exams.selectedBoard) return false;
      }

      return true;
    }).toList();

    List<String> classList = [];
    if (exams.selectedProgram != null) {
      classList = _programToClasses[exams.selectedProgram.programType] ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Question Bank"),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              exams.setSelectedProgram(null);
              exams.setSelectedClass(null);
              exams.setSelectedSubject(null);
              exams.setSelectedInstitution(null);
              exams.setSelectedBoard(null);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<dynamic>(
                        label: "Program Type",
                        value: exams.selectedProgram,
                        items: exams.bankPrograms,
                        onChanged: (val) {
                          exams.setSelectedProgram(val);
                          exams.setSelectedClass(null);
                        },
                        displayName: (item) => item.programType,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Class", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Color(0xFFFAFAFA)),
                        value: (exams.selectedClass is String && classList.contains(exams.selectedClass)) ? exams.selectedClass : null,
                        items: classList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => exams.setSelectedClass(val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown<dynamic>(
                        label: "Subject",
                        value: exams.selectedSubject,
                        items: exams.subjects,
                        onChanged: (val) => exams.setSelectedSubject(val),
                        displayName: (item) => item is Map ? item['subject_name'] : item.toString(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSimpleDropdown(
                        label: "Institution",
                        value: exams.selectedInstitution,
                        items: exams.institutions,
                        onChanged: (val) => exams.setSelectedInstitution(val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildSimpleDropdown(
                  label: "Board",
                  value: exams.selectedBoard,
                  items: exams.boards,
                  onChanged: (val) => exams.setSelectedBoard(val),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: !filtersSelected
                ? _buildInitialState()
                : filteredQuestions.isEmpty
                    ? const Center(child: Text("No questions found for this selection."))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Container(
                            width: 800, 
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black.withOpacity(0.05),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Column(
                                    children: [
                                      const Text(
                                        "QUESTION BANK",
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 5),
                                      if (exams.selectedInstitution != null || exams.selectedBoard != null)
                                        Text(
                                          "${exams.selectedInstitution ?? ''} ${exams.selectedInstitution != null && exams.selectedBoard != null ? '|' : ''} ${exams.selectedBoard ?? ''}",
                                          style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Divider(),
                                const SizedBox(height: 20),
                                ...List.generate(filteredQuestions.length, (index) {
                                  return _buildPaperQuestion(filteredQuestions[index], index + 1);
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

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("Please select Program, Class, and Subject", 
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("to generate your Question Bank document.", 
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
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
      value: safeValue,
      items: items.map((item) => DropdownMenuItem<T>(value: item, child: Text(displayName(item)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSimpleDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label, 
        border: const OutlineInputBorder(), 
        isDense: true, 
        filled: true, 
        fillColor: Colors.grey[50]
      ),
      value: value,
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPaperQuestion(Question q, int number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Q$number. ${q.text}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (q.marks != null)
                Text("($q.marks)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          if (q.imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Image.file(
                File(q.imagePath!),
                height: 150,
              ),
            ),
          if (q.type == 'MCQ' && q.options != null)
            Column(
              children: q.options!.asMap().entries.map((entry) {
                final i = entry.key;
                final opt = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        "${String.fromCharCode(65 + i)}. ",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(opt)),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 10),
          const Divider(),
        ],
      ),
    );
  }
}
