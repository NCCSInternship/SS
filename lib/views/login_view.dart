    import 'package:flutter/material.dart';
    import 'package:provider/provider.dart';
    import '../viewmodels/auth_viewmodel.dart';
    import 'package:flutter/foundation.dart';

    class LoginView extends StatefulWidget {
      const LoginView({super.key});

      @override
      State<LoginView> createState() => _LoginViewState();
    }

    class _LoginViewState extends State<LoginView> {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();
      String role = "Student";

      String get selectedRole => role.toLowerCase();

      void _applyDebugCredentials(String role) {
        if (!kDebugMode) return;

        if (role == "teacher") {
          emailController.text = "teacher@teacher.com";
          passwordController.text = "teacher";
        } else if (role == "student") {
          emailController.text = "student@student.com";
          passwordController.text = "student";
        }
      }

      @override
      void initState() {
        super.initState();

        _applyDebugCredentials(selectedRole);
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Stack(
            children: [
          // 🔹 BACKGROUND IMAGE
          Positioned.fill(
          child: Transform.scale(
            scale: 1.3,
            child: Image.asset(
            "assets/images/img.png",
            fit: BoxFit.cover,
          ),
         ),
        ),

        Center(
            child: Container(
              width: 380,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Online Exam System",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text("Sign in to continue",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),

                  // Role
                  Align(
                      alignment: Alignment.centerLeft,
                      child: const Text("Select Role")),
                  const SizedBox(height: 6),
                  DropdownButtonFormField(
                    initialValue: role,
                    items: const [
                      DropdownMenuItem(value: "Student", child: Text("Student")),
                      DropdownMenuItem(value: "Teacher", child: Text("Teacher")),
                    ],
                    onChanged: (val) {
                      setState(() { role = val!; });
                      _applyDebugCredentials(selectedRole); // AUTO CHANGE
                    },
                    decoration: _inputStyle(),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  const Align(
                      alignment: Alignment.centerLeft, child: Text("Email")),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    decoration: _inputStyle().copyWith(hintText: "Enter your email"),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  const Align(
                      alignment: Alignment.centerLeft, child: Text("Password")),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputStyle().copyWith(hintText: "Enter your password"),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Minimum 4 characters required",
                          style: TextStyle(fontSize: 12, color: Colors.grey))),
                  const SizedBox(height: 18),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter email and password")),
                          );
                          return;
                        }

                        final success = await context.read<AuthViewModel>().login(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          selectedRole, // 👈 ROLE PASSED HERE
                        );

                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Invalid email, password, or role"),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: const Text("Sign In"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
          ),
        );
      }

      InputDecoration _inputStyle() {
        return InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        );
      }
    }
