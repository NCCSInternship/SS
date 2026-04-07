import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/question_model.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../viewmodels/exercise_viewmodel.dart';
import '../data/program_classes.dart';

class AddQuestionScreen extends StatefulWidget {
  final Question? questionToEdit;
  final int? editIndex;

  const AddQuestionScreen({super.key, this.questionToEdit, this.editIndex});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _marksController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final _optAController = TextEditingController();
  final _optBController = TextEditingController();
  final _optCController = TextEditingController();
  final _optDController = TextEditingController();
  String _selectedCorrectOption = 'A';

  int? _selectedProgramId;
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedInstitution;
  String? _selectedBoard;
  String _selectedType = 'Subjective';
  bool _isForBank = false; 
  bool _isForExercise = false; 
  String? _selectedExerciseTitle; 

  @override
  void initState() {
    super.initState();
    if (widget.questionToEdit != null) {
      _populateFields(widget.questionToEdit!);
    }
    Future.microtask(() {
      context.read<ExamViewModel>().fetchFilterData();
      context.read<ExerciseViewModel>().loadExercises();
    });
  }

  void _populateFields(Question q) {
    _questionController.text = q.text;
    _marksController.text = q.marks ?? '';
    _selectedType = q.type;
    _selectedClass = q.className;
    _selectedSubject = q.subject;
    _selectedInstitution = q.institution;
    _selectedBoard = q.board;
    _isForBank = q.isForBank;
    _isForExercise = q.exerciseTitle != null;
    _selectedExerciseTitle = q.exerciseTitle;
    
    if (q.type == 'MCQ' && q.options != null && q.options!.length >= 4) {
      _optAController.text = q.options![0];
      _optBController.text = q.options![1];
      _optCController.text = q.options![2];
      _optDController.text = q.options![3];
      
      if (q.correctAnswer == q.options![0]) {
        _selectedCorrectOption = 'A';
      } else if (q.correctAnswer == q.options![1]) {
        _selectedCorrectOption = 'B';
      } else if (q.correctAnswer == q.options![2]) {
        _selectedCorrectOption = 'C';
      } else if (q.correctAnswer == q.options![3]) {
        _selectedCorrectOption = 'D';
      }
    }
    
    if (q.imagePath != null) {
      _selectedImage = File(q.imagePath!);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter question first")));
      return;
    }
    
    if (_selectedProgramId == null || _selectedClass == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select all academic criteria")));
      return;
    }

    final exams = context.read<ExamViewModel>();
    final program = exams.bankPrograms.firstWhere((p) => p.id == _selectedProgramId);

    List<String>? options;
    String? correctAnswer;

    if (_selectedType == 'MCQ') {
      options = [_optAController.text, _optBController.text, _optCController.text, _optDController.text];
      if (options.any((opt) => opt.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all MCQ options")));
        return;
      }
      if (_selectedCorrectOption == 'A') {
        correctAnswer = _optAController.text;
      } else if (_selectedCorrectOption == 'B') {
        correctAnswer = _optBController.text;
      } else if (_selectedCorrectOption == 'C') {
        correctAnswer = _optCController.text;
      } else if (_selectedCorrectOption == 'D') {
        correctAnswer = _optDController.text;
      }
    }

    final newQuestion = Question(
      text: _questionController.text,
      type: _selectedType,
      program: program.programType,
      className: _selectedClass,
      subject: _selectedSubject,
      institution: _selectedInstitution,
      board: _selectedBoard,
      options: options,
      correctAnswer: correctAnswer,
      marks: _marksController.text,
      imagePath: _selectedImage?.path,
      isForBank: _isForBank,
      exerciseTitle: _isForExercise ? _selectedExerciseTitle : null,
    );

    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('question_bank_data');
    List<dynamic> allQuestions = savedData != null ? json.decode(savedData) : [];

    if (widget.editIndex != null && widget.editIndex! < allQuestions.length) {
      allQuestions[widget.editIndex!] = newQuestion.toMap();
    } else {
      allQuestions.add(newQuestion.toMap());
    }
    
    await prefs.setString('question_bank_data', json.encode(allQuestions));

    if (mounted) {
      context.read<ExamViewModel>().loadQuestionBank();
    }

    if (widget.editIndex != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Question updated!")));
        Navigator.pop(context);
      }
      return;
    }

    _questionController.clear();
    _marksController.clear();
    _optAController.clear();
    _optBController.clear();
    _optCController.clear();
    _optDController.clear();
    setState(() {
      _selectedImage = null;
      _isForBank = false;
      _isForExercise = false;
      _selectedExerciseTitle = null;
      _selectedProgramId = null;
      _selectedClass = null;
      _selectedSubject = null;
      _selectedInstitution = null;
      _selectedBoard = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Question saved!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final exams = context.watch<ExamViewModel>();
    final exerciseVm = context.watch<ExerciseViewModel>();
    
    if (widget.questionToEdit != null && _selectedProgramId == null && exams.bankPrograms.isNotEmpty) {
      try {
        final p = exams.bankPrograms.firstWhere((p) => p.programType == widget.questionToEdit!.program);
        _selectedProgramId = p.id;
      } catch (_) {}
    }

    final currentProgram = _selectedProgramId != null 
        ? exams.bankPrograms.firstWhere((p) => p.id == _selectedProgramId, orElse: () => exams.bankPrograms.first)
        : null;
    
    final List<String> classList = currentProgram != null 
        ? List<String>.from(programClasses[currentProgram.programType] ?? []) 
        : [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.editIndex != null ? "Edit Question" : "Manage Questions")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Institution", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildStrictDropdown(
              hint: "Select Institution",
              value: _selectedInstitution,
              items: exams.institutions,
              onChanged: (val) => setState(() => _selectedInstitution = val),
            ),
            const SizedBox(height: 10),

            const Text("Board", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildStrictDropdown(
              hint: "Select Board",
              value: _selectedBoard,
              items: exams.boards,
              onChanged: (val) => setState(() => _selectedBoard = val),
            ),
            const SizedBox(height: 10),

            const Text("Program Type", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              isExpanded: true,
              hint: const Text("Select Program"),
              value: _selectedProgramId,
              items: exams.bankPrograms.map((program) {
                return DropdownMenuItem<int>(value: program.id, child: Text(program.programType));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedProgramId = val;
                  _selectedClass = null; 
                });
              },
            ),
            const SizedBox(height: 10),

            const Text("Class", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildStrictDropdown(
              hint: "Select Class",
              value: _selectedClass,
              items: classList,
              onChanged: (val) => setState(() => _selectedClass = val),
            ),
            const SizedBox(height: 10),

            const Text("Subject", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildStrictDropdown(
              hint: "Select Subject",
              value: _selectedSubject,
              items: exams.subjects.map((s) => s['subject_name'].toString()).toList(),
              onChanged: (val) => setState(() => _selectedSubject = val),
            ),
            const SizedBox(height: 10),

            const Text("Question Type", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildStrictDropdown(
              hint: "Select Type",
              value: _selectedType,
              items: const ['Subjective', 'MCQ'],
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Question Text", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            if (_selectedImage != null)
              Container(height: 100, margin: const EdgeInsets.only(bottom: 10), child: Image.file(_selectedImage!)),

            ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.add_a_photo), label: const Text("Add Image")),
            const SizedBox(height: 10),

            TextField(
              controller: _marksController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Marks", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),

            if (_selectedType == 'MCQ') ...[
              _buildOptionField(_optAController, "Option A"),
              const SizedBox(height: 5),
              _buildOptionField(_optBController, "Option B"),
              const SizedBox(height: 5),
              _buildOptionField(_optCController, "Option C"),
              const SizedBox(height: 5),
              _buildOptionField(_optDController, "Option D"),
              const SizedBox(height: 10),
              const Text("Correct Option"),
              _buildStrictDropdown(
                hint: "Correct Answer",
                value: _selectedCorrectOption,
                items: const ['A', 'B', 'C', 'D'],
                onChanged: (v) => setState(() => _selectedCorrectOption = v!),
              ),
            ],

            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Push to Question Bank", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(value: _isForBank, onChanged: (val) => setState(() => _isForBank = val)),
              ],
            ),
            
            Row(
              children: [
                const Text("Push to Exercise", style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Switch(value: _isForExercise, onChanged: (val) => setState(() => _isForExercise = val)),
              ],
            ),

            if (_isForExercise) ...[
              const SizedBox(height: 10),
              const Text("Select Exercise", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildStrictDropdown(
                hint: "Select exercise",
                value: _selectedExerciseTitle,
                items: exerciseVm.exercises.map((ex) => ex.title).toList(),
                onChanged: (val) => setState(() => _selectedExerciseTitle = val),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(onPressed: _saveQuestion, child: Text(widget.editIndex != null ? "Update Question" : "Save Question")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrictDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    final String? safeValue = items.contains(value) ? value : null;

    return DropdownButton<String>(
      isExpanded: true,
      hint: Text(hint),
      value: safeValue,
      items: items.map((String val) {
        return DropdownMenuItem<String>(value: val, child: Text(val));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildOptionField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
    );
  }
}
