import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'confirm_dialog.dart';

class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.dirty,
    required this.onDirty,
    required this.onSubmit,
    required this.submitLabel,
    required this.child,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final bool dirty;
  final VoidCallback onDirty;
  final Future<void> Function() onSubmit;
  final String submitLabel;
  final Widget child;

  Future<bool> _confirmLeave(BuildContext context) async {
    if (!dirty) return true;
    return confirmAction(
      context,
      title: 'Несохранённые изменения',
      message: 'Выйти без сохранения?',
      confirmLabel: 'Выйти',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmLeave(context);
        if (leave && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmLeave(context) && context.mounted) {
                context.pop();
              }
            },
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(child: child),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async => await onSubmit(),
                      child: Text(submitLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
