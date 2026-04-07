import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/exercise_viewmodel.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../models/program_model.dart';
import 'exercise_questions_view.dart';

class AddExerciseScreen extends StatefulWidget {
  const AddExerciseScreen({super.key});

  @override
  State<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends State<AddExerciseScreen> {
  final _titleController = TextEditingController();
  
  int? _selectedProgramId;
  String? _selectedClass;
  String? _selectedSubject;
  int? _editingIndex; 

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExamViewModel>().fetchFilterData();
    });
  }

  void _clearForm() {
    setState(() {
      _titleController.clear();
      _editingIndex = null;
      _selectedProgramId = null;
      _selectedClass = null;
      _selectedSubject = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final examVm = context.watch<ExamViewModel>();
    final exerciseVm = context.watch<ExerciseViewModel>();

    final currentProgram = _selectedProgramId != null 
        ? examVm.bankPrograms.firstWhere((p) => p.id == _selectedProgramId, orElse: () => examVm.bankPrograms.first)
        : null;
    
    final List<String> classList = currentProgram != null 
        ? List<String>.from(_programToClasses[currentProgram.programType] ?? []) 
        : [];

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Exercises")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Exercise Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Program Dropdown
            DropdownButtonFormField<int>(
              value: _selectedProgramId,
              hint: const Text("Select Program"),
              items: examVm.bankPrograms.map<DropdownMenuItem<int>>((p) {
                return DropdownMenuItem<int>(value: p.id, child: Text(p.programType));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedProgramId = val;
                  final p = examVm.bankPrograms.firstWhere((p) => p.id == val);
                  _updateDefaultClass(p.programType);
                });
              },
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Program"),
            ),
            const SizedBox(height: 16),

            // Class Dropdown
            DropdownButtonFormField<String>(
              value: _selectedClass,
              hint: const Text("Select Class"),
              items: classList.map<DropdownMenuItem<String>>((c) {
                return DropdownMenuItem<String>(value: c, child: Text(c));
              }).toList(),
              onChanged: (val) => setState(() => _selectedClass = val),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Class"),
            ),
            const SizedBox(height: 16),

            // Subject Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              hint: const Text("Select Subject"),
              items: examVm.subjects.map<DropdownMenuItem<String>>((s) {
                final name = s['subject_name'] as String;
                return DropdownMenuItem<String>(value: name, child: Text(name));
              }).toList(),
              onChanged: (val) => setState(() => _selectedSubject = val),
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Subject"),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_titleController.text.isNotEmpty) {
                          if (_editingIndex != null) {
                            exerciseVm.updateExercise(
                              _editingIndex!,
                              title: _titleController.text,
                              program: currentProgram!.programType,
                              className: _selectedClass,
                              subject: _selectedSubject,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Exercise updated!")),
                            );
                          } else {
                            exerciseVm.addExercise(
                              title: _titleController.text,
                              program: currentProgram?.programType,
                              className: _selectedClass,
                              subject: _selectedSubject,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Exercise added!")),
                            );
                          }
                          _clearForm();
                        }
                      },
                      child: Text(_editingIndex != null ? "Update Exercise" : "Add Exercise"),
                    ),
                  ),
                ),
                if (_editingIndex != null) ...[
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _clearForm,
                      child: const Text("Cancel"),
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 40),
            const Text("Saved Exercises", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("(Click to view questions)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exerciseVm.exercises.length,
              itemBuilder: (context, index) {
                final ex = exerciseVm.exercises[index];
                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseQuestionsView(exercise: ex),
                        ),
                      );
                    },
                    title: Text(ex.title),
                    subtitle: Text("${ex.program ?? ''} - ${ex.className ?? ''} - ${ex.subject ?? ''}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              _editingIndex = index;
                              _titleController.text = ex.title;
                              _selectedClass = ex.className;
                              _selectedSubject = ex.subject;
                              
                              try {
                                final p = examVm.bankPrograms.firstWhere((p) => p.programType == ex.program);
                                _selectedProgramId = p.id;
                              } catch (_) {}
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => exerciseVm.deleteExercise(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateDefaultClass(String programType) {
    if (_programToClasses.containsKey(programType)) {
      _selectedClass = _programToClasses[programType]!.first;
    } else {
      _selectedClass = null;
    }
  }
}
