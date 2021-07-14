import 'dart:convert';

import 'package:firedart/auth/exceptions.dart';
import 'package:firedart/firedart.dart';
import 'package:firedart/firestore/token_authenticator.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:test/test.dart';

import 'test_config.dart';

Future main() async {
  var firestore = Firestore(projectId, tokenAuthenticator: ServiceAccountTokenAuthenticator(serviceAccountCredentials),);

  test('Create reference', () async {
    var reference = firestore.document('test/reference');
    await reference.set({'field': 'test'});

    var collectionReference = firestore.reference('test');
    expect(collectionReference.runtimeType, equals(CollectionReference));
    var documentReference = firestore.reference('test/types');
    expect(documentReference.runtimeType, equals(DocumentReference));

    await reference.delete();
  });

  test('Get collection', () async {
    var reference = firestore.collection('test');
    var documents = await reference.get();
    expect(documents.isNotEmpty, true);
  });

  test('Limit collection page size', () async {
    var reference = firestore.collection('test');
    var documents = await reference.get(pageSize: 1);
    expect(documents.length, 1);
    expect(documents.hasNextPage, isTrue);
  });

  test('Get next collection page', () async {
    var reference = firestore.collection('test');
    var documents = await reference.get(pageSize: 1);
    var first = documents[0];
    documents = await reference.get(
        pageSize: 1, nextPageToken: documents.nextPageToken);
    var second = documents[0];
    expect(first.id, isNot(second.id));
  });

  test('Simple query', () async {
    await firestore.document('test/query').set({'test_field': 'test_value'});
    var query = await firestore
        .collection('test')
        .where('test_field', isEqualTo: 'test_value')
        .get();
    expect(query.isNotEmpty, true);
  });

  test('Multiple query parameters', () async {
    await firestore.document('test/query').set({'test_field': 42});
    var query = await firestore
        .collection('test')
        .where('test_field', isEqualTo: 42, isGreaterThan: 41, isLessThan: 43)
        .get();
    expect(query.isNotEmpty, true);
  });

  test('Add and delete collection document', () async {
    var reference = firestore.collection('test');
    var docReference = await reference.add({'field': 'test'});
    expect(docReference['field'], 'test');
    var document = reference.document(docReference.id);
    expect(await document.exists, true);
    await document.delete();
    expect(await document.exists, false);
  });

  test('Add and delete named document', () async {
    var reference = firestore.document('test/add_remove');
    await reference.set({'field': 'test'});
    expect(await reference.exists, true);
    await reference.delete();
    expect(await reference.exists, false);
  });

  test('Path with leading slash', () async {
    var reference = firestore.document('/test/path');
    await reference.set({'field': 'test'});
    expect(await reference.exists, true);
    await reference.delete();
    expect(await reference.exists, false);
  });

  test('Path with trailing slash', () async {
    var reference = firestore.document('test/path/');
    await reference.set({'field': 'test'});
    expect(await reference.exists, true);
    await reference.delete();
    expect(await reference.exists, false);
  });

  test('Path with leading and trailing slashes', () async {
    var reference = firestore.document('/test/path/');
    await reference.set({'field': 'test'});
    expect(await reference.exists, true);
    await reference.delete();
    expect(await reference.exists, false);
  });

  test('Read data from document', () async {
    var reference = firestore.collection('test').document('read_data');
    await reference.set({'field': 'test'});
    var map = await reference.get();
    expect(map['field'], 'test');
    await reference.delete();
  });

  test('Overwrite document', () async {
    var reference = firestore.collection('test').document('overwrite');
    await reference.set({'field1': 'test1', 'field2': 'test1'});
    await reference.set({'field1': 'test2'});
    var doc = await reference.get();
    expect(doc['field1'], 'test2');
    expect(doc['field2'], null);
    await reference.delete();
  });

  test('Update document', () async {
    var reference = firestore.collection('test').document('update');
    await reference.set({'field1': 'test1', 'field2': 'test1'});
    await reference.update({'field1': 'test2'});
    var doc = await reference.get();
    expect(doc['field1'], 'test2');
    expect(doc['field2'], 'test1');
    await reference.delete();
  });

  // test('Stream document changes', () async {
  //   var reference = firestore.document('test/subscribe');
  //
  //   // Firestore may send empty events on subscription because we're reusing the
  //   // document path.
  //   expect(reference.stream.where((doc) => doc != null),
  //       emits((document) => document['field'] == 'test'));
  //
  //   await reference.set({'field': 'test'});
  //   await reference.delete();
  // });

  test('Stream collection changes', () async {
    var reference = firestore.collection('test');

    var document = await reference.add({'field': 'test'});
    expect(reference.stream,
        emits((List<Document> documents) => documents.isNotEmpty));
    await document.reference.delete();
  });

  test('Document field types', () async {
    var reference = firestore.collection('test').document('types');
    var dateTime = DateTime.now();
    var geoPoint = GeoPoint(38.7223, 9.1393);
    await reference.set({
      'null': null,
      'bool': true,
      'int': 1,
      'double': 0.1,
      'timestamp': dateTime,
      'bytes': utf8.encode('byte array'),
      'string': 'text',
      'reference': reference,
      'coordinates': geoPoint,
      'list': [1, 'text'],
      'map': {'int': 1, 'string': 'text'},
    });
    var doc = await reference.get();
    expect(doc['null'], null);
    expect(doc['bool'], true);
    expect(doc['int'], 1);
    expect(doc['double'], 0.1);
    expect(doc['timestamp'], dateTime);
    expect(doc['bytes'], utf8.encode('byte array'));
    expect(doc['string'], 'text');
    expect(doc['reference'], reference);
    expect(doc['coordinates'], geoPoint);
    expect(doc['list'], [1, 'text']);
    expect(doc['map'], {'int': 1, 'string': 'text'});
  });

  test('Refresh token when expired', () async {
   // tokenStore.expireToken();
    var map = await firestore.collection('test').get();
    //expect(auth.isSignedIn, true);
    //expect(map, isNot(null));
  });

  test('Sign out on bad refresh token', () async {
    //tokenStore.setToken('user_id', 'bad_token', 'bad_token', 0);
    try {
      await firestore.collection('test').get();
    } catch (_) {}
    //expect(auth.isSignedIn, false);
  });
}

/// firebase-adminsdk-ryd6u@pub-pod.iam.gserviceaccount.com
/// Obtain the service account credentials from the Google Developers Console by
/// creating new OAuth credentials of application type "Service account".
/// This will give you a JSON file with the following fields.
final serviceAccountCredentials = ServiceAccountCredentials.fromJson(r'''
{
  "type": "service_account",
  "project_id": "pub-pod",
  "private_key_id": "8e70ec7729e59fdfc7d6806fcb547d11934774d4",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCg5WisMh6AStk+\n3HBGArBlWCItEGvIpGI8iUAMxypWddvSe52GOw7ub/V8Y7cpuofyaApZOPp36L+S\nLi4aZJZKn/KiDlvfjE/9rGKmdd9BkLyha5qtvelRvcP3v0c12UCFjNOK5JXxW4Qx\njdSsY0wLvczXksfvyEENGqxwFUqeGA67i0cw/VAcVPkaBtnYxmlYX3Da7CBDbF/N\n9B8CLdkrSSpknn3vz0efy6w3+UbeJEU8ctjl0ARfHC6pj+teB2hns7Hdm7nPnnQn\nwDSma5Mt3QlqZwVF9Ye1O6JYNGT112KK/CfA/MNAkOVsmxOVD/o0P0H6nKOHAGYs\n0l2vNzwpAgMBAAECggEAB/pizqm24iJT/rj23DyFO1E7yJjthJ0aEz8JrQMx3JMA\nMRdYv++CawekLY8oOup5PpIyySp5Hk8CiMtqFSbzCNpA3BDy30qEK45LtKNYTFZS\nntJzcLVfsgzt1bASEN/Sl4yxxKEBtQkWV1AIFqWJ1MnhiWL0L7Xx+9Cxx5EBX9tk\nuo86J9e4IsZZkTRJ0h/wbx25RzBQgh6BgkIqj03FTJ82VhARho6BbgsaMhI9oPJP\ntFN2Gjln5dxYyTHdyDhd/r1fOBcC1258AKtzE8F3tbyKyBSH2hbEdSpvFNYdW2/y\n26lFWkg6HKcFKfkfAJ24WW6L8nwSrirorWMfXcRAXQKBgQDQd+EjibuLK0qNXQQI\np3IqRnx/GNzh9CwGAQoRHS4Wc2HA1aAz565mppPzapqAUpWJZGXrGTXBBxrVac5k\n87lZY+59FE/QptVlcutyeFOtDZdrj2lQ58DdJsbiQDcwO5fkRs/3H01BW1xqKfXt\nlSagKC/LIVxj/IwJVMj3MwDkswKBgQDFlMhOok3Feve//IRTOLNWzcIJc13pzMTO\nA/qcoNSl7wi2UYqZBbyEf4snjKjgSmMeXtNPFnSmgN8VAvDl9x7oFx7iYAgq7gSh\no+J1nlxR2eCwNstlwH9N10E8no0yFZsJE46OM6P5kUv4uhNH8nZkYZgxGhv/Zavw\nbEj+OBLhswKBgEwfakOq2KPR9BA4pe9vDX4obO+QKaAMpEKxAHcNW7Xw/gIHP8+U\nSxfKvf3FsJMpFNetpJW7h+hrar4BO8+bO9RLbFuaHicHtKat1xHepFdtvhwVqxRS\n/BcFQNx/LGfdavJ9dRU9Bd3WuaE+n0HZE9iptAINtYoBPzVtE1FI+4uHAoGBAL2m\nNCaWT8QwZkJX5cPj9vBpC8j6fbh/HqEI3LMfBT5JFLm7xydehDdCHZXWw/qWLFHo\nfze4vDteE8MdUZHLBFWOa8yqlOxwDu4AWsy/NqoyUiOSVOXUQd27shi3r5vVdTzf\nEsSX+NsChkO2h+9VYiK0MttezmT1eHaL2fx6YlVVAoGBALAd721s2KVzgun228GQ\nSjPC++agmYZ8LYyp21RuGE9S/J5yGUuwNZB2j2oJECCXWcR5k4nSAL/FSF8u309l\ng2LUdzKVHY/3YyO99nPYr8C3alE4GD7Pvv13sLOHyB5wWfNPKcp0Ums34NLstT8B\nyC9nIoG8BNqcKoVQ+EJXMlq/\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-ryd6u@pub-pod.iam.gserviceaccount.com",
  "client_id": "109982449345576227043",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-ryd6u%40pub-pod.iam.gserviceaccount.com"
}
''');