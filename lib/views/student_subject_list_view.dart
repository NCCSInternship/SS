import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../models/program_model.dart';
import 'subject_questions_view.dart';

class StudentSubjectListView extends StatefulWidget {
  const StudentSubjectListView({super.key});

  @override
  State<StudentSubjectListView> createState() => _StudentSubjectListViewState();
}

class _StudentSubjectListViewState extends State<StudentSubjectListView> {
  final Map<String, List<String>> _programToClasses = {
    'Primary': ['Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5', 'Class 6', 'Class 7', 'Class 8'],
    'Secondary': ['Class 9', 'Class 10'],
    '+2': ['Class 11', 'Class 12'],
    'Bachelor': ['1st Year', '2nd Year', '3rd Year', '4th Year'],
    'Masters Program': ['1st Year', '2nd Year'],
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ExamViewModel>().fetchFilterData());
  }

  @override
  Widget build(BuildContext context) {
    final examVm = context.watch<ExamViewModel>();
    
    // Check if Program and Class are selected
    final bool filtersSelected = examVm.selectedProgram != null && examVm.selectedClass != null;

    // Filter subjects based on the selected Program and Class
    final subjects = !filtersSelected ? [] : examVm.bankQuestions
        .where((q) {
          bool matches = true;
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
        })
        .map((q) => q.subject)
        .where((s) => s != null && s.isNotEmpty)
        .toSet()
        .toList();

    List<String> classList = [];
    if (examVm.selectedProgram != null) {
      classList = _programToClasses[examVm.selectedProgram.programType] ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Subject"),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              examVm.setSelectedProgram(null);
              examVm.setSelectedClass(null);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // --- FILTER HEADER ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown<dynamic>(
                    label: "Program Type",
                    value: examVm.selectedProgram,
                    items: examVm.bankPrograms,
                    onChanged: (val) {
                      examVm.setSelectedProgram(val);
                      examVm.setSelectedClass(null);
                    },
                    displayName: (item) => item.programType,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Class", border: OutlineInputBorder(), isDense: true, filled: true, fillColor: Color(0xFFFAFAFA)),
                    value: (examVm.selectedClass is String && classList.contains(examVm.selectedClass)) ? examVm.selectedClass : null,
                    items: classList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => examVm.setSelectedClass(val),
                  ),
                ),
              ],
            ),
          ),

          // --- LIST AREA ---
          Expanded(
            child: !filtersSelected
                ? _buildInitialState()
                : subjects.isEmpty
                    ? const Center(child: Text("No subjects found for this selection."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index]!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.book)),
                              title: Text(subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubjectQuestionsView(subject: subject),
                                  ),
                                );
                              },
                            ),
                          );
                        },
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
          Icon(Icons.filter_alt_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text("Please select Program and Class", 
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          const Text("to view available subjects.", 
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
      safeValue = items.firstWhere((item) {
        if (value == null) return false;
        if (item == value) return true;
        if (item is Map && value is Map) return item['id'] == value['id'];
        if (item is Datum && value is Datum) return item.id == value.id;
        return false;
      });
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
}
