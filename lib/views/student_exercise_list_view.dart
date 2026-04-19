import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/exercise_viewmodel.dart';
import '../viewmodels/exam_viewmodel.dart';
import 'exercise_questions_view.dart';
import 'subject_questions_view.dart';

class StudentExerciseListView extends StatelessWidget {
  final String filterSubject;
  
  const StudentExerciseListView({super.key, required this.filterSubject});

  @override
  Widget build(BuildContext context) {
    final exerciseVm = context.watch<ExerciseViewModel>();
    final examVm = context.watch<ExamViewModel>();
    
    // Filter exercises by the selected subject AND current Program/Class
    final filteredExercises = exerciseVm.exercises.where((ex) {
      bool matches = ex.subject == filterSubject;
      
      // Match Program
      if (examVm.selectedProgram != null) {
        if (ex.program != examVm.selectedProgram.programType) matches = false;
      }
      
      // Match Class
      if (examVm.selectedClass != null) {
        if (ex.className != examVm.selectedClass) matches = false;
      }
      
      return matches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: Text("$filterSubject Exercises")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Teacher's Exercise Sets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (filteredExercises.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No specific exercise sets found for this subject.", style: TextStyle(color: Colors.grey)),
              )
            else
              ...filteredExercises.map((ex) => _buildExerciseCard(context, ex)).toList(),
            
            const SizedBox(height: 32),
            const Text("Dynamic Practice", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.psychology, color: Colors.white)),
                title: Text("All $filterSubject Questions"),
                subtitle: const Text("Practice all questions from the bank"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SubjectQuestionsView(subject: filterSubject),
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

  Widget _buildExerciseCard(BuildContext context, dynamic ex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.assignment, color: Colors.white)),
        title: Text(ex.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${ex.program ?? ''} - ${ex.className ?? ''}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseQuestionsView(exercise: ex),
            ),
          );
        },
      ),
    );
  }
}
