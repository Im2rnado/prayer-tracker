import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/database_provider.dart';
import '../../providers/auth_provider.dart';

class InviteCodeScreen extends ConsumerStatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  ConsumerState<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends ConsumerState<InviteCodeScreen> {
  final codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.link_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Connect with a Guardian',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter the invite code provided by your parent or community leader to link your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: codeController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                    decoration: const InputDecoration(
                      labelText: 'Invite Code',
                      hintText: 'e.g. A1B2C3',
                      alignLabelWithHint: true,
                      floatingLabelAlignment: FloatingLabelAlignment.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: () async {
                        if (codeController.text.trim().isEmpty) return;
                        
                        final user = ref.read(currentUserProvider).value;
                        if (user != null) {
                          try {
                            await ref.read(databaseProvider).linkChildToGuardian(user.uid, codeController.text.trim());
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Account Linked Successfully!'),
                                backgroundColor: Colors.green,
                              ));
                              context.pop();
                            }
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                               content: Text(e.toString()),
                               backgroundColor: Colors.redAccent,
                             ));
                          }
                        }
                      },
                      child: const Text('Submit Code', style: TextStyle(fontSize: 18)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
