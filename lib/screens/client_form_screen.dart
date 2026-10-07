import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/client.dart';
import '../models/rental_card.dart';
import '../repositories/client_repository.dart';
import '../state/client_list_notifier.dart';
import '../widgets/form_scaffold.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, this.id});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _dirty = false;
  bool _loading = true;
  bool _saving = false;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardIssuedController = TextEditingController();

  Map<String, String> _serverErrors = {};

  static const _cities = [
    'Екатеринбург',
    'Челябинск',
    'Пермь',
    'Тюмень',
  ];

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (widget.isEditing) {
      final item = await context.read<ClientRepository>().findById(widget.id!);
      if (item != null && mounted) {
        _fullNameController.text = item.fullName;
        _emailController.text = item.email;
        _phoneController.text = item.phone;
        _cityController.text = item.city;
        _cardNumberController.text = item.rentalCard.number;
        _cardIssuedController.text =
            '${item.rentalCard.issuedAt.toLocal().toIso8601String().split('T').first}';
      }
    } else {
      _cardIssuedController.text =
          DateTime.now().toIso8601String().split('T').first;
    }
    if (mounted) setState(() => _loading = false);
  }

  DateTime? _parseDate(String text) {
    final parts = text.trim().split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final issued = _parseDate(_cardIssuedController.text);
    if (issued == null) return;

    final client = Client(
      id: widget.id ?? 0,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      city: _cityController.text.trim(),
      registeredAt: widget.isEditing
          ? (await context.read<ClientRepository>().findById(widget.id!))
                  ?.registeredAt ??
              DateTime.now()
          : DateTime.now(),
      rentalCard: RentalCard(
        number: _cardNumberController.text.trim(),
        issuedAt: issued,
      ),
    );

    final repo = context.read<ClientRepository>();
    try {
      if (widget.isEditing) {
        await repo.update(client);
      } else {
        await repo.create(client);
      }
      await context.read<ClientListNotifier>().load();
      if (mounted) {
        setState(() => _dirty = false);
        context.pop();
      }
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _cardNumberController.dispose();
    _cardIssuedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return FormScaffold(
      title: widget.isEditing ? 'Редактирование клиента' : 'Новый клиент',
      formKey: _formKey,
      dirty: _dirty,
      onDirty: _markDirty,
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSubmit: _submit,
      submitting: _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              labelText: 'ФИО',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirty(),
            validator:
                V.combine([V.required('Укажите ФИО'), V.length(min: 5, max: 120)]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Электронная почта',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              _markDirty();
              _serverErrors.remove('email');
            },
            validator: (value) {
              final local = V.email()(value);
              if (local != null) return local;
              final repo = context.read<ClientRepository>();
              if (repo.isEmailTaken(value!.trim(), exceptId: widget.id)) {
                return _serverErrors['email'] ??
                    'Такой адрес почты уже зарегистрирован';
              }
              return _serverErrors['email'];
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Телефон',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              _markDirty();
              _serverErrors.remove('phone');
            },
            validator: (value) {
              final local = V.phoneRu()(value);
              if (local != null) return local;
              final repo = context.read<ClientRepository>();
              if (repo.isPhoneTaken(value!.trim(), exceptId: widget.id)) {
                return _serverErrors['phone'] ?? 'Такой телефон уже зарегистрирован';
              }
              return _serverErrors['phone'];
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _cities.contains(_cityController.text)
                ? _cityController.text
                : (_cityController.text.isEmpty ? null : _cityController.text),
            decoration: const InputDecoration(
              labelText: 'Город',
              border: OutlineInputBorder(),
            ),
            items: _cities
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              _cityController.text = value;
              _markDirty();
              setState(() {});
            },
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Выберите город' : null,
          ),
          const SizedBox(height: 24),
          Text(
            'Прокатный билет (связь 1:1)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Билет хранится внутри клиента — отдельного экрана для него нет.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Номер билета',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirty(),
            validator: V.combine([
              V.required('Укажите номер билета'),
              V.length(min: 4, max: 32),
            ]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _cardIssuedController,
            decoration: const InputDecoration(
              labelText: 'Дата выдачи (ГГГГ-ММ-ДД)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirty(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Укажите дату';
              }
              if (_parseDate(value) == null) return 'Некорректная дата';
              return null;
            },
          ),
        ],
      ),
    );
  }
}
