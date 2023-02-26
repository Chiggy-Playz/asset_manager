import 'package:asset_manager/models/asset.dart';
import 'package:asset_manager/models/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  // Collection reference
  final CollectionReference assetCollection =
      FirebaseFirestore.instance.collection('assets');
  final CollectionReference modelCollection =
      FirebaseFirestore.instance.collection('models');

  Stream<List<Asset>> get assets {
    return assetCollection.snapshots().map(_assetListFromSnapshot);
  }

  Stream<List<Model>> get models {
    return modelCollection.snapshots().map(_modelListFromSnapshot);
  }

  // Asset list from snapshot
  List<Asset> _assetListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return Asset(
        id: doc.id,
        type: data['type'] ?? 'Unknown',
        fields: data['fields'] ?? {},
      );
    }).toList();
  }

  // Model list from snapshot
  List<Model> _modelListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return Model(
        id: doc.id,
        fields: Map<String, String>.from(data['fields'] ?? {}),
        identifyingField: data['identifyingField'] ?? 'Unknown',
        fieldOrder: List<String>.from(data['fieldOrder']),
      );
    }).toList();
  }

  // Create model
  Future<void> createModel(String id, Map<String, dynamic> data) {
    return modelCollection.doc(id).set(data);
  }

  // Update model
  Future<void> updateModel(String id, Map<String, dynamic> data) {
    return modelCollection.doc(id).update(data);
  }

  // Create asset
  Future<void> createAsset(Map<String, dynamic> data) {
    return assetCollection.add(data);
  }

  // Update asset
  Future<void> updateAsset(String id, Map<String, dynamic> data) {
    return assetCollection.doc(id).update(data);
  }
}
