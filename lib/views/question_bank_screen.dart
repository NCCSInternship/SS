import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../models/question_model.dart';
import '../models/program_model.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text("Teacher's Question Bank"),
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
          // Filter Header
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
          
          // Page Content
          Expanded(
            child: !filtersSelected
                ? _buildInitialState()
                : filteredQuestions.isEmpty
                    ? _buildEmptyState(exams)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 800),
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Document Header
                                Center(
                                  child: Column(
                                    children: [
                                      const Text("QUESTION BANK", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                      const SizedBox(height: 10),
                                      Text(
                                        "${exams.selectedInstitution ?? 'All Institutions'} | ${exams.selectedBoard ?? 'All Boards'}",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${exams.selectedProgram?.programType ?? 'All Programs'} - ${exams.selectedClass ?? 'All Classes'} - ${exams.selectedSubject is Map ? exams.selectedSubject['subject_name'] : exams.selectedSubject ?? 'All Subjects'}",
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                      const SizedBox(height: 20),
                                      Container(height: 1.5, color: Colors.black87),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                ),
                                
                                ...List.generate(filteredQuestions.length, (index) {
                                  return _buildPageQuestionItem(filteredQuestions[index], index);
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
          const Text("to generate the Question Bank document.", 
            style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPageQuestionItem(Question q, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${index + 1}. ", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    if (q.marks != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text("(${q.marks} marks)", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (q.imagePath != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(File(q.imagePath!), height: 180, fit: BoxFit.contain),
              ),
            ),
          
          if (q.type == 'MCQ' && q.options != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: Column(
                children: q.options!.asMap().entries.map((entry) {
                  final label = String.fromCharCode(97 + entry.key); 
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$label) ", style: const TextStyle(fontWeight: FontWeight.w600)),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 15),
          Divider(color: Colors.grey.shade300, thickness: 0.5),
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
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, filled: true, fillColor: Colors.grey[50]),
      value: value,
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildEmptyState(ExamViewModel exams) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No shared questions found."),
          TextButton(onPressed: () {
            exams.setSelectedProgram(null);
            exams.setSelectedClass(null);
            exams.setSelectedSubject(null);
            exams.setSelectedInstitution(null);
            exams.setSelectedBoard(null);
          }, child: const Text("Reset filters")),
        ],
      ),
    );
  }
}
