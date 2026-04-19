import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/exam_viewmodel.dart';
import '../viewmodels/exercise_viewmodel.dart';
import 'student_question_bank_view.dart';
import 'student_subject_list_view.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    Future.microtask(() {
      context.read<ExamViewModel>().loadQuestionBank();
      context.read<ExerciseViewModel>().loadExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    final exams = context.watch<ExamViewModel>();
    final exerciseVm = context.watch<ExerciseViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Student Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(onPressed: _refreshData, icon: const Icon(Icons.refresh)),
          TextButton.icon(
              onPressed: () => auth.logout(),
              icon: const Icon(Icons.logout),
              label: const Text("Logout")),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Welcome back,", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const Text("Student", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Primary Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildMenuCard(
                  context,
                  "Start Exercises",
                  Icons.fitness_center,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentSubjectListView()),
                    );
                  },
                  subtitle: "Practice Sets",
                ),
                _buildMenuCard(
                  context,
                  "Question Bank",
                  Icons.storage,
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentQuestionBankView()),
                    );
                  },
                  subtitle: "${exams.bankQuestions.length} Items",
                ),
              ],
            ),

            const SizedBox(height: 32),
            const Text("Your Portfolio", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Recently completed exercises", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),

            if (exerciseVm.completedTitles.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("No exercises completed yet.", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exerciseVm.completedTitles.length,
                itemBuilder: (context, index) {
                  final title = exerciseVm.completedTitles.toList()[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Completed Successfully"),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, {String? subtitle}) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
