import 'package:googleapis_auth/auth_io.dart';
import 'package:grpc/grpc.dart';
import 'package:http/http.dart' as http;

import '../firedart.dart';

abstract class TokenAuthenticator {

  CallOptions get toCallOptions;
}


class FirebaseAuthTokenAuthenticator extends TokenAuthenticator {

  final FirebaseAuth auth;

  FirebaseAuthTokenAuthenticator._internal(this.auth);

  static FirebaseAuthTokenAuthenticator? from(FirebaseAuth? auth) =>
      auth != null ? FirebaseAuthTokenAuthenticator._internal(auth) : null;

  Future<void> authenticate(Map<String, String> metadata, String uri) async {
    var idToken = await auth.tokenProvider.idToken;
    metadata['authorization'] = 'Bearer $idToken';
  }

  CallOptions get toCallOptions => CallOptions(providers: [authenticate]);
}

class ServiceAccountTokenAuthenticator extends TokenAuthenticator {
  final ServiceAccountCredentials credentials;

  ServiceAccountTokenAuthenticator(this.credentials);

  Future<void> authenticate(Map<String, String> metadata, String uri) async {

    final client = http.Client();
    var accessCredentials = await obtainAccessCredentialsViaServiceAccount(
      credentials,
      [
        'https://www.googleapis.com/auth/datastore'
      ],
      client,
    );
    var idToken = accessCredentials.accessToken.data;
    metadata['authorization'] = 'Bearer $idToken';
  }

  CallOptions get toCallOptions => CallOptions(providers: [authenticate]);
}