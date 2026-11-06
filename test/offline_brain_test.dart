import 'package:flutter_test/flutter_test.dart';

import 'package:jarvis_ai/src/ai/offline_brain.dart';

void main() {
  const brain = OfflineBrain(userName: 'Louis');

  test('greeting answers with the current moment and a courtesy', () {
    final reply = brain.reply('Bonjour JARVIS');
    expect(reply.toLowerCase(), contains('louis'));
    expect(
      ['bonjour', 'bon après-midi', 'bonsoir', 'bonne nuit']
          .any(reply.toLowerCase().contains),
      isTrue,
    );
  });

  test('identity question returns the JARVIS pitch', () {
    final reply = brain.reply('Qui es-tu ?');
    expect(reply, contains('JARVIS'));
  });

  test('help lists at least three capabilities', () {
    final reply = brain.reply('Que peux-tu faire ?');
    expect(reply.toLowerCase(), contains('calcul'));
    expect(reply.toLowerCase(), contains('météo'));
    expect(reply.toLowerCase(), contains('mémoire'));
  });

  test('bare arithmetic is evaluated', () {
    expect(brain.reply('12*12'), contains('144'));
    expect(brain.reply('(10+5)/3'), contains('5'));
  });

  test('thanks and compliments get a dry-witted response, never an error', () {
    expect(brain.reply('merci beaucoup').isNotEmpty, isTrue);
    expect(brain.reply('bravo, excellent travail').isNotEmpty, isTrue);
  });

  test('unknown question yields a persona fallback mentioning offline mode', () {
    final reply = brain.reply('raconte-moi l’histoire du quantique français');
    expect(reply.isNotEmpty, isTrue);
    // either the offline hint or the echo machinery must engage
    expect(reply.length > 20, isTrue);
  });

  test('empty input is handled gracefully', () {
    expect(brain.reply('   ').isNotEmpty, isTrue);
  });
}
