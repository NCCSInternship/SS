import 'package:online_exam_application/viewmodels/exercise_viewmodel.dart';
import 'package:online_exam_application/views/teacher_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/exam_viewmodel.dart';
import 'views/login_view.dart';
import 'views/dashboard.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()..init()),
        ChangeNotifierProvider(create: (_) => ExamViewModel()..loadExams()),
        ChangeNotifierProvider(create: (_) => ExerciseViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, auth, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            // Primary background color matched from the provided graduation image
            scaffoldBackgroundColor: const Color(0xFFCAD5FF),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.black),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
            ),
            useMaterial3: true,
          ),
          home: !auth.isLoggedIn
              ? const LoginView()
              : auth.role == "teacher"
                  ? const TeacherDashboard()
                  : const Dashboard(),
        );
      },
    );
  }
}
