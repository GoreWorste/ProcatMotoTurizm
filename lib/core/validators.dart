typedef Validator = String? Function(String?);

class V {
  static Validator required([String message = 'Поле обязательно']) {
    return (value) =>
        (value == null || value.trim().isEmpty) ? message : null;
  }

  static Validator length({int min = 0, int max = 255}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.length < min) return 'Не короче $min символов';
      if (text.length > max) return 'Не длиннее $max символов';
      return null;
    };
  }

  static Validator integer({int? min, int? max}) {
    return (value) {
      final n = int.tryParse(value?.trim() ?? '');
      if (n == null) return 'Введите целое число';
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  static Validator decimal({double? min, double? max}) {
    return (value) {
      final n = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
      if (n == null) return 'Введите число';
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  static Validator email() {
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return 'Укажите адрес почты';
      return re.hasMatch(text) ? null : 'Некорректный адрес почты';
    };
  }

  static Validator phoneRu() {
    final digits = RegExp(r'^\+?7[\s\-()]*\d{3}[\s\-()]*\d{3}[\s\-()]*\d{2}[\s\-()]*\d{2}$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return 'Укажите телефон';
      if (!digits.hasMatch(text)) {
        return 'Формат: +7 (XXX) XXX-XX-XX';
      }
      return null;
    };
  }

  static Validator inventoryNumber() {
    return combine([
      required('Укажите инвентарный номер'),
      length(min: 3, max: 32),
      (value) {
        final text = value?.trim() ?? '';
        if (!RegExp(r'^EQ-\d+$').hasMatch(text)) {
          return 'Формат: EQ-XXXX';
        }
        return null;
      },
    ]);
  }

  static Validator combine(List<Validator> validators) {
    return (value) {
      for (final v in validators) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}

String? validateNonEmptySelection<T>(T? value, String message) =>
    value == null ? message : null;

String? validateIdList(List<int>? value, String message) =>
    (value == null || value.isEmpty) ? message : null;
