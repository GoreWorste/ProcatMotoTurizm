import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../models/equipment.dart';
import '../repositories/equipment_repository.dart';
import '../state/catalog_notifier.dart';
import '../state/equipment_list_notifier.dart';
import '../widgets/form_scaffold.dart';
import '../widgets/multi_id_chips_field.dart';

class EquipmentFormScreen extends StatefulWidget {
  const EquipmentFormScreen({super.key, this.id});

  final int? id;

  bool get isEditing => id != null;

  @override
  State<EquipmentFormScreen> createState() => _EquipmentFormScreenState();
}

class _EquipmentFormScreenState extends State<EquipmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _dirty = false;
  bool _loading = true;
  bool _saving = false;

  final _nameController = TextEditingController();
  final _inventoryController = TextEditingController();
  final _yearController = TextEditingController();
  final _rateController = TextEditingController();
  final _unitsTotalController = TextEditingController();
  final _unitsAvailableController = TextEditingController();

  int? _categoryId;
  int? _brandId;
  List<int> _tagIds = [];
  String _condition = 'хорошее';

  Map<String, String> _serverErrors = {};

  static const _conditions = ['новое', 'хорошее', 'требует обслуживания'];

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<CatalogNotifier>().refresh();
    if (widget.isEditing) {
      final item = await context.read<EquipmentRepository>().findById(widget.id!);
      if (item != null && mounted) {
        _nameController.text = item.name;
        _inventoryController.text = item.inventoryNumber;
        _yearController.text = '${item.purchaseYear}';
        _rateController.text = item.dailyRate.toStringAsFixed(0);
        _unitsTotalController.text = '${item.unitsTotal}';
        _unitsAvailableController.text = '${item.unitsAvailable}';
        _categoryId = item.categoryId;
        _brandId = item.brandId;
        _tagIds = [...item.tagIds];
        _condition = item.condition;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  List<int> _brandIdsForCategory(int? categoryId) {
    final catalog = context.read<CatalogNotifier>();
    if (categoryId == null) {
      return catalog.brands.map((b) => b.id).toList();
    }
    final repo = context.read<EquipmentRepository>();
    final ids = repo.brandIdsForCategory(categoryId);
    if (ids.isEmpty) {
      return catalog.brands.map((b) => b.id).toList();
    }
    return ids;
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = context.read<EquipmentRepository>();
    final year = int.parse(_yearController.text.trim());
    final rate = double.parse(_rateController.text.trim().replaceAll(',', '.'));
    final unitsTotal = int.parse(_unitsTotalController.text.trim());
    final unitsAvailable = int.parse(_unitsAvailableController.text.trim());

    final equipment = Equipment(
      id: widget.id ?? 0,
      name: _nameController.text.trim(),
      inventoryNumber: _inventoryController.text.trim(),
      categoryId: _categoryId!,
      brandId: _brandId!,
      purchaseYear: year,
      dailyRate: rate,
      condition: _condition,
      unitsTotal: unitsTotal,
      unitsAvailable: unitsAvailable,
      tagIds: _tagIds,
    );

    try {
      if (widget.isEditing) {
        await repo.update(equipment);
      } else {
        await repo.create(equipment);
      }
      if (!mounted) return;
      context.read<CatalogNotifier>().invalidateCache();
      await context.read<EquipmentListNotifier>().load();
      if (mounted) {
        setState(() => _dirty = false);
        context.pop();
      }
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
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
    _nameController.dispose();
    _inventoryController.dispose();
    _yearController.dispose();
    _rateController.dispose();
    _unitsTotalController.dispose();
    _unitsAvailableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final catalog = context.watch<CatalogNotifier>();
    final allowedBrandIds = _brandIdsForCategory(_categoryId);
    final brandOptions = catalog.brands
        .where((b) => allowedBrandIds.contains(b.id))
        .toList();
    if (_brandId != null && !allowedBrandIds.contains(_brandId)) {
      _brandId = null;
    }

    return FormScaffold(
      title: widget.isEditing ? 'Редактирование оборудования' : 'Новое оборудование',
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
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Название',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirty(),
            validator: V.combine([V.required('Укажите название'), V.length(min: 2, max: 200)]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _inventoryController,
            decoration: const InputDecoration(
              labelText: 'Инвентарный номер',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              _markDirty();
              if (_serverErrors.containsKey('inventoryNumber')) {
                setState(() => _serverErrors.remove('inventoryNumber'));
              }
            },
            validator: (value) {
              final local = V.inventoryNumber()(value);
              if (local != null) return local;
              final repo = context.read<EquipmentRepository>();
              if (repo.isInventoryNumberTaken(
                value!.trim(),
                exceptId: widget.id,
              )) {
                return _serverErrors['inventoryNumber'] ??
                    'Такой инвентарный номер уже есть';
              }
              return _serverErrors['inventoryNumber'];
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Связи с другими сущностями',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Категория и бренд — связь «многие к одному»; теги — «многие ко многим». '
            'Список брендов сужается после выбора категории.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _categoryId,
            decoration: const InputDecoration(
              labelText: 'Категория (M2O)',
              border: OutlineInputBorder(),
            ),
            items: catalog.categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _categoryId = value;
                _brandId = null;
                _markDirty();
              });
            },
            validator: (value) =>
                value == null ? 'Выберите категорию' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: _brandId,
            decoration: const InputDecoration(
              labelText: 'Бренд (M2O)',
              border: OutlineInputBorder(),
            ),
            items: brandOptions
                .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _brandId = value;
                _markDirty();
              });
            },
            validator: (value) => value == null ? 'Выберите бренд' : null,
          ),
          const SizedBox(height: 16),
          MultiIdChipsField(
            label: 'Теги (M2M)',
            selectedIds: _tagIds,
            options: catalog.tags.map((t) => (id: t.id, name: t.name)).toList(),
            onChanged: (next) {
              setState(() {
                _tagIds = next;
                _markDirty();
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _yearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Год покупки',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirty(),
            validator: V.integer(min: 1990, max: DateTime.now().year + 1),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rateController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Тариф за сутки (₽)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirty(),
            validator: V.decimal(min: 1, max: 100000),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _condition,
            decoration: const InputDecoration(
              labelText: 'Состояние',
              border: OutlineInputBorder(),
            ),
            items: _conditions
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _condition = value;
                _markDirty();
              });
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _unitsTotalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Всего единиц',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirty(),
            validator: V.integer(min: 1, max: 9999),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _unitsAvailableController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Доступно',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _markDirty(),
            validator: (value) {
              final base = V.integer(min: 0, max: 9999)(value);
              if (base != null) return base;
              final total = int.tryParse(_unitsTotalController.text.trim());
              final avail = int.tryParse(value?.trim() ?? '');
              if (total != null && avail != null && avail > total) {
                return 'Не больше, чем всего единиц';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
