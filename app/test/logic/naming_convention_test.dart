import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/logic/naming_convention.dart';

const _expected =
    '[["MyGame",["MyGame","my-game","my_game","myGame","MyGame","My Game"]],["my_game",["my_game","my-game","my_game","myGame","MyGame","My Game"]],["HTTPServer",["HTTPServer","http-server","http_server","httpServer","HttpServer","Http Server"]],["XMLHttpRequest",["XMLHttpRequest","xml-http-request","xml_http_request","xmlHttpRequest","XmlHttpRequest","Xml Http Request"]],["game2D",["game2D","game2-d","game2_d","game2D","Game2D","Game2 D"]],["2DGame",["2DGame","2-d-game","2_d_game","2DGame","2DGame","2 D Game"]],["my-cool game!",["my-cool game!","my-cool-game","my_cool_game","myCoolGame","MyCoolGame","My Cool Game"]],["  ",["","","","","",""]],["___",["___","___","___","___","___","___"]],["a",["a","a","a","a","A","A"]],["ABC",["ABC","abc","abc","abc","Abc","Abc"]],["ABCdef",["ABCdef","ab-cdef","ab_cdef","abCdef","AbCdef","Ab Cdef"]],["snake_case_name",["snake_case_name","snake-case-name","snake_case_name","snakeCaseName","SnakeCaseName","Snake Case Name"]],["Title Case Name",["Title Case Name","title-case-name","title_case_name","titleCaseName","TitleCaseName","Title Case Name"]],["üner Spiel",["üner Spiel","ner-spiel","ner_spiel","nerSpiel","NerSpiel","Ner Spiel"]],["v1.2.3",["v1.2.3","v1-2-3","v1_2_3","v123","V123","V1 2 3"]]]';

void main() {
  test('ids and parse', () {
    expect([for (final c in NamingConvention.values) c.id], [
      'keep',
      'kebab-case',
      'snake_case',
      'camelCase',
      'PascalCase',
      'Title Case',
    ]);
    expect(NamingConvention.parse('snake_case'), NamingConvention.snakeCase);
    expect(NamingConvention.parse('SCREAMING'), NamingConvention.keep);
  });

  for (final row in jsonDecode(_expected) as List) {
    final name = row[0] as String;
    test('"$name" converts like the TypeScript implementation', () {
      expect([for (final c in NamingConvention.values) applyNamingConvention(name, c)], row[1]);
    });
  }
}
