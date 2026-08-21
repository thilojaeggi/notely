import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notely/features/auth/kaschuso_auth_service.dart';

String? _getHeader(http.Request request, String name) {
  final lower = name.toLowerCase();
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == lower) {
      return entry.value;
    }
  }
  return null;
}

void main() {
  group('KaschusoAuthService PKCE & Token tests', () {
    test('generatePkce generates valid PKCE bundle without base64 padding', () {
      final pkce = KaschusoAuthService.generatePkce();
      expect(pkce.verifier, isNotEmpty);
      expect(pkce.challenge, isNotEmpty);
      expect(pkce.state, isNotEmpty);
      expect(pkce.nonce, isNotEmpty);

      // Verifier and challenge should not contain '=' padding or standard base64 + / chars
      expect(pkce.verifier.contains('='), isFalse);
      expect(pkce.challenge.contains('='), isFalse);
      expect(pkce.state.contains('='), isFalse);
      expect(pkce.nonce.contains('='), isFalse);
      expect(pkce.verifier.contains('+'), isFalse);
      expect(pkce.verifier.contains('/'), isFalse);
    });

    test('KaschusoTokens parses JSON with numeric expires_in correctly', () {
      final json = {
        'access_token': 'test_access_123',
        'refresh_token': 'test_refresh_456',
        'expires_in': 3600,
        'token_type': 'Bearer',
      };

      final tokens = KaschusoTokens.fromJson(json);
      expect(tokens.accessToken, equals('test_access_123'));
      expect(tokens.refreshToken, equals('test_refresh_456'));
      expect(tokens.expiresIn, equals(3600));
      expect(tokens.expiresAt, isNotNull);
      expect(tokens.expiresAt!.isAfter(DateTime.now()), isTrue);
    });

    test('KaschusoTokens parses JSON with string expires_in correctly', () {
      final json = {
        'access_token': 'test_access_abc',
        'expires_in': '1800',
      };

      final tokens = KaschusoTokens.fromJson(json);
      expect(tokens.accessToken, equals('test_access_abc'));
      expect(tokens.refreshToken, isNull);
      expect(tokens.expiresIn, equals(1800));
      expect(tokens.expiresAt, isNotNull);
    });

    test('KaschusoTokens throws when access_token is missing', () {
      expect(
        () => KaschusoTokens.fromJson({'expires_in': 3600}),
        throwsA(isA<KaschusoAuthException>()),
      );
    });
  });

  group('KaschusoAuthService mock HTTP login flows', () {
    test('Successful direct login (no 2FA)', () async {
      final mockClient = MockClient((http.Request request) async {
        final uri = request.url.toString();

        // 1. Initial GET authorize.php
        if (request.method == 'GET' && uri.contains('authorize.php')) {
          return http.Response(
            '<html><form><input type="hidden" name="csrf" value="12345"/><input id="login"/><input id="passwort"/></form></html>',
            200,
            headers: {'set-cookie': 'PHPSESSID=session_abc123; path=/'},
          );
        }

        // 2. POST credentials to authorize.php
        if (request.method == 'POST' && uri.contains('authorize.php')) {
          expect(request.bodyFields['login'], equals('user1'));
          expect(request.bodyFields['passwort'], equals('pass1'));
          expect(request.bodyFields['csrf'], equals('12345'));
          expect(_getHeader(request, 'cookie'), contains('PHPSESSID=session_abc123'));

          return http.Response(
            'Redirecting...',
            302,
            headers: {
              'location': 'https://kaschuso.so.ch/public/ksso/authorize.php?code=auth_code_999&state=xyz',
              'set-cookie': 'PHPSESSID=session_abc123; path=/',
            },
          );
        }

        // 3. POST token.php
        if (request.method == 'POST' && uri.contains('token.php')) {
          expect(request.bodyFields['grant_type'], equals('authorization_code'));
          expect(request.bodyFields['code'], equals('auth_code_999'));
          expect(request.bodyFields['client_id'], equals(KaschusoAuthService.clientId));
          expect(request.bodyFields['code_verifier'], isNotEmpty);

          return http.Response(
            jsonEncode({
              'access_token': 'final_access_token',
              'refresh_token': 'final_refresh_token',
              'expires_in': 3600,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }

        return http.Response('Not Found', 404);
      });

      final authService = KaschusoAuthService(client: mockClient);
      final tokens = await authService.login(
        username: 'user1',
        password: 'pass1',
        school: 'KSSO',
      );

      expect(tokens.accessToken, equals('final_access_token'));
      expect(tokens.refreshToken, equals('final_refresh_token'));
      expect(tokens.expiresIn, equals(3600));
      expect(authService.hasActiveSession, isFalse);
    });

    test('Two-Factor Authentication flow (2FA prompt + submitOtp)', () async {
      final mockClient = MockClient((http.Request request) async {
        final uri = request.url.toString();

        // 1. Initial GET authorize.php
        if (request.method == 'GET' && uri.contains('authorize.php')) {
          return http.Response(
            '<html><form><input id="login"/><input id="passwort"/></form></html>',
            200,
            headers: {'set-cookie': 'PHPSESSID=session_2fa; path=/'},
          );
        }

        // 2. POST credentials -> returns 2FA PIN page
        if (request.method == 'POST' && uri.contains('authorize.php') && request.bodyFields.containsKey('login')) {
          return http.Response(
            '<html><body><input type="text" id="pin" name="pin" class="pin-input"/><button class="login-submit">Login</button></body></html>',
            200,
            headers: {'set-cookie': 'PHPSESSID=session_2fa; path=/'},
          );
        }

        // 3. POST OTP PIN
        if (request.method == 'POST' && uri.contains('authorize.php') && request.bodyFields.containsKey('pin')) {
          expect(request.bodyFields['pin'], equals('654321'));
          expect(_getHeader(request, 'cookie'), contains('PHPSESSID=session_2fa'));

          return http.Response(
            'Redirecting...',
            302,
            headers: {
              'location': '?code=auth_code_from_2fa&state=abc',
            },
          );
        }

        // 4. Token exchange
        if (request.method == 'POST' && uri.contains('token.php')) {
          expect(request.bodyFields['code'], equals('auth_code_from_2fa'));

          return http.Response(
            jsonEncode({
              'access_token': 'token_2fa_success',
              'refresh_token': 'refresh_2fa_success',
              'expires_in': 7200,
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final authService = KaschusoAuthService(client: mockClient);

      // Should throw KaschusoOtpRequiredException when OTP is needed
      await expectLater(
        authService.login(
          username: 'user2',
          password: 'pass2',
          school: 'ksso',
        ),
        throwsA(isA<KaschusoOtpRequiredException>()),
      );

      // Active session should be waiting
      expect(authService.hasActiveSession, isTrue);

      // Now submit OTP
      final tokens = await authService.submitOtp(otpCode: '654321');
      expect(tokens.accessToken, equals('token_2fa_success'));
      expect(tokens.refreshToken, equals('refresh_2fa_success'));
      expect(authService.hasActiveSession, isFalse);
    });

    test('Two-Factor Authentication with pre-provided otpCode logs in immediately', () async {
      final mockClient = MockClient((http.Request request) async {
        final uri = request.url.toString();

        if (request.method == 'GET' && uri.contains('authorize.php')) {
          return http.Response('<html><body><input id="login"/></body></html>', 200, headers: {'set-cookie': 'PHPSESSID=session_totp;'});
        }

        if (request.method == 'POST' && uri.contains('authorize.php') && request.bodyFields.containsKey('login')) {
          return http.Response('<html><body><input id="pin" name="pin"/></body></html>', 200);
        }

        if (request.method == 'POST' && uri.contains('authorize.php') && request.bodyFields.containsKey('pin')) {
          expect(request.bodyFields['pin'], equals('123456'));
          return http.Response('', 302, headers: {'location': '?code=code_from_stored_totp'});
        }

        if (request.method == 'POST' && uri.contains('token.php')) {
          return http.Response(jsonEncode({'access_token': 'token_auto_totp'}), 200);
        }

        return http.Response('Not Found', 404);
      });

      final authService = KaschusoAuthService(client: mockClient);
      final tokens = await authService.login(
        username: 'user_totp',
        password: 'pass_totp',
        school: 'ksso',
        otpCode: '123456',
      );

      expect(tokens.accessToken, equals('token_auto_totp'));
    });

    test('Invalid credentials error extraction', () async {
      final mockClient = MockClient((http.Request request) async {
        final uri = request.url.toString();

        if (request.method == 'GET') {
          return http.Response('<html><body><input id="login"/></body></html>', 200);
        }

        if (request.method == 'POST' && uri.contains('authorize.php')) {
          return http.Response(
            '<html><body><div class="mdl-cell mdl-cell--12-col" style="background-color: #ffb138;">Fehler: Benutzername oder Passwort ungültig. Ihre Aktion wurde aufgezeichnet.</div></body></html>',
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final authService = KaschusoAuthService(client: mockClient);

      await expectLater(
        authService.login(
          username: 'bad_user',
          password: 'bad_password',
          school: 'ksso',
        ),
        throwsA(predicate((e) =>
            e is KaschusoInvalidCredentialsException &&
            e.message == 'Fehler: Benutzername oder Passwort ungültig.')),
      );
    });

    test('Token refresh succeeds when server returns 200', () async {
      final mockClient = MockClient((http.Request request) async {
        if (request.method == 'POST' && request.url.toString().contains('token.php')) {
          expect(request.bodyFields['grant_type'], equals('refresh_token'));
          expect(request.bodyFields['refresh_token'], equals('valid_refresh_token'));

          return http.Response(
            jsonEncode({
              'access_token': 'new_access_token',
              'refresh_token': 'new_refresh_token',
              'expires_in': 3600,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final authService = KaschusoAuthService(client: mockClient);
      final tokens = await authService.refreshToken(
        school: 'ksso',
        refreshToken: 'valid_refresh_token',
      );

      expect(tokens, isNotNull);
      expect(tokens!.accessToken, equals('new_access_token'));
      expect(tokens.refreshToken, equals('new_refresh_token'));
    });

    test('Token refresh returns null on 400/401 failure', () async {
      final mockClient = MockClient((http.Request request) async {
        return http.Response('{"error":"invalid_grant"}', 400);
      });

      final authService = KaschusoAuthService(client: mockClient);
      final tokens = await authService.refreshToken(
        school: 'ksso',
        refreshToken: 'expired_refresh_token',
      );

      expect(tokens, isNull);
    });
  });
}
