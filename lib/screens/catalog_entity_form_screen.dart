import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/tag.dart';
import '../repositories/brand_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/tag_repository.dart';
import '../state/catalog_notifier.dart';
import '../widgets/declarative_form_fields.dart';
import '../widgets/form_scaffold.dart';
import 'catalog_entity_list_screen.dart';

class CatalogEntityFormScreen extends StatefulWidget {
  const CatalogEntityFormScreen({
    super.key,
    required this.kind,
    this.id,
  });

  final CatalogEntityKind kind;
  final int? id;

  bool get isEditing => id != null;

  @override
  State<CatalogEntityFormScreen> createState() =>
      _CatalogEntityFormScreenState();
}

class _CatalogEntityFormScreenState extends State<CatalogEntityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _dirty = false;
  bool _loading = true;

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
      switch (widget.kind) {
        case CatalogEntityKind.category:
          final item =
              await context.read<CategoryRepository>().findById(widget.id!);
          if (item != null) _nameController.text = item.name;
        case CatalogEntityKind.brand:
          final item =
              await context.read<BrandRepository>().findById(widget.id!);
          if (item != null) _nameController.text = item.name;
        case CatalogEntityKind.tag:
          final item = await context.read<TagRepository>().findById(widget.id!);
          if (item != null) _nameController.text = item.name;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String get _title => switch (widget.kind) {
        CatalogEntityKind.category =>
          widget.isEditing ? 'Категория' : 'Новая категория',
        CatalogEntityKind.brand =>
          widget.isEditing ? 'Бренд' : 'Новый бренд',
        CatalogEntityKind.tag => widget.isEditing ? 'Тег' : 'Новый тег',
      };

  List<TextFieldSpec> get _fieldSpecs => [
        TextFieldSpec(
          label: 'Название',
          controller: _nameController,
          validator: V.combine([V.required(), V.length(min: 2, max: 80)]),
        ),
      ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    switch (widget.kind) {
      case CatalogEntityKind.category:
        if (widget.isEditing) {
          await context.read<CategoryRepository>().update(
                Category(id: widget.id!, name: name),
              );
        } else {
          await context.read<CategoryRepository>().create(
                Category(id: 0, name: name),
              );
        }
      case CatalogEntityKind.brand:
        if (widget.isEditing) {
          await context.read<BrandRepository>().update(
                Brand(id: widget.id!, name: name),
              );
        } else {
          await context.read<BrandRepository>().create(Brand(id: 0, name: name));
        }
      case CatalogEntityKind.tag:
        if (widget.isEditing) {
          await context.read<TagRepository>().update(
                Tag(id: widget.id!, name: name),
              );
        } else {
          await context.read<TagRepository>().create(Tag(id: 0, name: name));
        }
    }
    if (!mounted) return;
    await context.read<CatalogNotifier>().refresh();
    setState(() => _dirty = false);
    context.pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return FormScaffold(
      title: _title,
      formKey: _formKey,
      dirty: _dirty,
      onDirty: _markDirty,
      submitLabel: widget.isEditing ? 'Сохранить' : 'Создать',
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buildDeclarativeTextFields(
          fields: _fieldSpecs,
          onDirty: _markDirty,
        ),
      ),
    );
  }
}
