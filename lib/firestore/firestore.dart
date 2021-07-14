import 'package:firedart/auth/firebase_auth.dart';
import 'package:firedart/firestore/token_authenticator.dart';

import 'firestore_gateway.dart';
import 'models.dart';

class Firestore {
  /* Singleton interface */
  static Firestore? _instance;

  static Firestore initialize(String projectId, {String? databaseId, required TokenAuthenticator tokenAuthenticator}) {
    if (_instance != null) {
      throw Exception('Firestore instance was already initialized');
    }
    _instance = Firestore(projectId, databaseId: databaseId, tokenAuthenticator: tokenAuthenticator,);
    return _instance!;
  }

  static Firestore get instance {
    if (_instance == null) {
      throw Exception(
          "Firestore hasn't been initialized. Please call Firestore.initialize() before using it.");
    }
    return _instance!;
  }

  /* Instance interface */
  final FirestoreGateway _gateway;

  Firestore(String projectId, {String? databaseId, required TokenAuthenticator tokenAuthenticator})
      : _gateway =
            FirestoreGateway(projectId, databaseId: databaseId, tokenAuthenticator: tokenAuthenticator,),
        assert(projectId.isNotEmpty);

  Reference reference(String path) => Reference.create(_gateway, path);

  CollectionReference collection(String path) =>
      CollectionReference(_gateway, path);

  DocumentReference document(String path) => DocumentReference(_gateway, path);
}
