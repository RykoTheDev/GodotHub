import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:godothub/motion/ease.dart';

void main() {
  final fixture = jsonDecode(File('test/fixtures/gsap_eases.json').readAsStringSync()) as Map<String, dynamic>;
  final samples = (fixture['samples'] as List).cast<num>().map((n) => n.toDouble()).toList();
  final eases = (fixture['eases'] as Map<String, dynamic>);

  for (final entry in eases.entries) {
    test('${entry.key} matches GSAP 3.15', () {
      final curve = GsapEase(entry.key);
      final expected = (entry.value as List).cast<num>();
      for (var i = 0; i < samples.length; i++) {
        expect(curve.transform(samples[i]), closeTo(expected[i].toDouble(), 1e-12), reason: '${entry.key} at ${samples[i]}');
      }
    });
  }

  test('app aliases resolve to the GSAP names', () {
    expect(GhEase.out.name, 'expo.out');
    expect(GhEase.soft.name, 'power3.out');
    expect(GhEase.easeIn.name, 'power2.in');
    expect(GhEase.spring.name, 'back.out(1.8)');
    expect(GhEase.pop.name, 'back.out(2.6)');
    expect(GhEase.elastic.name, 'elastic.out(1.1, 0.4)');
    expect(GhEase.defaultEase.name, 'power1.out');
  });
}
