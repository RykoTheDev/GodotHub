enum NamingConvention {
  keep('keep'),
  kebabCase('kebab-case'),
  snakeCase('snake_case'),
  camelCase('camelCase'),
  pascalCase('PascalCase'),
  titleCase('Title Case');

  const NamingConvention(this.id);

  final String id;

  static NamingConvention parse(String id) {
    for (final value in values) {
      if (value.id == id) return value;
    }
    return keep;
  }
}

final _alnum = RegExp('[a-zA-Z0-9]');
final _lowerOrDigit = RegExp('[a-z0-9]');
final _upper = RegExp('[A-Z]');
final _lower = RegExp('[a-z]');

String _capitalizeWord(String word) =>
    word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase();

List<String> _splitNamingWords(String name) {
  final words = <String>[];
  var current = '';
  for (var i = 0; i < name.length; i++) {
    final c = name[i];
    if (!_alnum.hasMatch(c)) {
      if (current.isNotEmpty) {
        words.add(current);
        current = '';
      }
      continue;
    }
    if (current.isNotEmpty) {
      final last = current[current.length - 1];
      final next = i + 1 < name.length ? name[i + 1] : null;
      final split = (_lowerOrDigit.hasMatch(last) && _upper.hasMatch(c)) ||
          (_upper.hasMatch(last) && _upper.hasMatch(c) && next != null && _lower.hasMatch(next));
      if (split) {
        words.add(current);
        current = '';
      }
    }
    current += c;
  }
  if (current.isNotEmpty) words.add(current);
  return words;
}

String applyNamingConvention(String name, NamingConvention convention) {
  final words = _splitNamingWords(name);
  if (words.isEmpty) return name.trim();
  return switch (convention) {
    NamingConvention.kebabCase => words.map((w) => w.toLowerCase()).join('-'),
    NamingConvention.snakeCase => words.map((w) => w.toLowerCase()).join('_'),
    NamingConvention.camelCase => [
      for (var i = 0; i < words.length; i++) i == 0 ? words[i].toLowerCase() : _capitalizeWord(words[i]),
    ].join(),
    NamingConvention.pascalCase => words.map(_capitalizeWord).join(),
    NamingConvention.titleCase => words.map(_capitalizeWord).join(' '),
    NamingConvention.keep => name,
  };
}
