import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  UserRole selectedRole = UserRole.child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join us to build better prayer habits.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<UserRole>(
                value: selectedRole,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: UserRole.values.map((r) => DropdownMenuItem(
                  value: r, 
                  child: Text(r.name.substring(0, 1).toUpperCase() + r.name.substring(1))
                )).toList(),
                onChanged: (val) => setState(() => selectedRole = val!),
                decoration: const InputDecoration(
                  labelText: 'I am a...', 
                  prefixIcon: Icon(Icons.group_outlined)
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(authServiceProvider).register(
                      emailController.text, 
                      passwordController.text, 
                      nameController.text, 
                      selectedRole
                    );
                    if (context.mounted) context.pop();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.redAccent,
                    ));
                  }
                },
                child: const Text('Register'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
