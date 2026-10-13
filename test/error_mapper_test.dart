import 'dart:io';

import 'package:afoso1/core/network/api_responses.dart';
import 'package:afoso1/core/utils/error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMapper', () {
    test('maps ApiException with a useful backend message', () {
      final message = ErrorMapper.toUserMessage(
        ApiException(message: 'Identifiants incorrects', statusCode: 401),
      );

      expect(message, 'Identifiants incorrects');
    });

    test('maps network failures to a human-friendly message', () {
      final message = ErrorMapper.toUserMessage(
        SocketException('Connection refused'),
      );

      expect(message, 'Pas de connexion internet. Vérifiez votre réseau.');
    });
  });
}
