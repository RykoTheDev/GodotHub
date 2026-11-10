const _categories = <String, List<String>>{
  'en': ['one', 'other'],
  'es': ['one', 'many', 'other'],
  'fr': ['one', 'many', 'other'],
  'pt': ['one', 'many', 'other'],
  'ru': ['one', 'few', 'many', 'other'],
  'ar': ['zero', 'one', 'two', 'few', 'many', 'other'],
  'ja': ['other'],
  'zh': ['other'],
  'vi': ['other'],
};

List<String> cardinalCategories(String language) => _categories[language] ?? const ['one', 'other'];

class _Operands {
  _Operands(num value) {
    final abs = value.abs();
    final text = abs == abs.truncate() ? abs.truncate().toString() : abs.toString();
    final dot = text.indexOf('.');
    i = int.parse(dot < 0 ? text : text.substring(0, dot));
    v = dot < 0 ? 0 : text.length - dot - 1;
    n = abs;
  }

  late final num n;
  late final int i;
  late final int v;
}

bool _millions(_Operands o) => o.i != 0 && o.i % 1000000 == 0 && o.v == 0;

String cardinalCategory(String language, num value) {
  final o = _Operands(value);
  switch (language) {
    case 'en':
      return o.i == 1 && o.v == 0 ? 'one' : 'other';
    case 'es':
      if (o.n == 1) return 'one';
      return _millions(o) ? 'many' : 'other';
    case 'fr':
      if (o.i == 0 || o.i == 1) return 'one';
      return _millions(o) ? 'many' : 'other';
    case 'pt':
      if (o.i == 0 || o.i == 1) return 'one';
      return _millions(o) ? 'many' : 'other';
    case 'ru':
      if (o.v != 0) return 'other';
      final mod10 = o.i % 10;
      final mod100 = o.i % 100;
      if (mod10 == 1 && mod100 != 11) return 'one';
      if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return 'few';
      return 'many';
    case 'ar':
      if (o.n == 0) return 'zero';
      if (o.n == 1) return 'one';
      if (o.n == 2) return 'two';
      if (o.v == 0) {
        final mod100 = o.i % 100;
        if (mod100 >= 3 && mod100 <= 10) return 'few';
        if (mod100 >= 11) return 'many';
      }
      return 'other';
    case 'ja' || 'zh' || 'vi':
      return 'other';
    default:
      return o.i == 1 && o.v == 0 ? 'one' : 'other';
  }
}

String Function(num n, {String? zero, String? one, String? two, String? few, String? many, String? other}) i18nextCardinal(
  String language,
) {
  return (n, {zero, one, two, few, many, other}) {
    if (n == 0 && zero != null) {
      return zero;
    }
    final form = switch (cardinalCategory(language, n)) {
      'zero' => zero,
      'one' => one,
      'two' => two,
      'few' => few,
      'many' => many,
      _ => other,
    };
    return form ?? other ?? '';
  };
}
