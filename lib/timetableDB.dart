import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'login.dart';

class TimeTable {
  bool isNew = false;
  int order;
  String id;
  String uid;
  String name;
  double credit;
  List<dynamic> subject;
  Map<dynamic, dynamic> subjects;

  TimeTable(String name, int order) {
    this.name = name;
    this.isNew = true;
    this.credit = 0;
    this.order = order;
    this.uid = user.uid;
    subject = new List(77);
    subjects = new Map<dynamic, dynamic>();
  }

  TimeTable.fromMap(Map<String, dynamic> map, String id)
      : assert(map['order'] != null),
        assert(map['uid'] != null),
        assert(map['name'] != null),
        assert(map['credit'] != null),
        assert(map['subject'] != null),
        assert(map['subjects'] != null),
        id = id ?? '',
        order = map['order'],
        uid = map['uid'],
        name = map['name'],
        credit = map['credit'].toDouble(),
        subject = map['subject'],
        subjects = map['subjects'];

  toJson() {
    return {
      "order": order,
      "uid": uid,
      "name": name,
      "credit": credit,
      "subject": subject,
      "subjects": subjects,
    };
  }

//  setName(String n) => name = n;

  TimeTable.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, snapshot.documentID);

//  @override
//  String toString() => "Record<$name:$votes>";
}

class CRUD{
  final Firestore _db = Firestore.instance;
  final String path;
  CollectionReference ref;

  CRUD( this.path ) {
    ref = _db.collection(path);
  }

  Future<QuerySnapshot> getDataCollection(String uid) {
    return ref.where('uid', isEqualTo: uid).getDocuments();
    
  }
  Stream<QuerySnapshot> streamDataCollection(String uid) {
    return ref.where('uid', isEqualTo: uid).orderBy("order", descending: false).snapshots();
  }
  Future<DocumentSnapshot> getDocumentById(String id) {
    return ref.document(id).get();
  }
  Future<void> removeDocument(String id){
    return ref.document(id).delete();
  }
  Future<DocumentReference> addDocument(Map data) {
    return ref.add(data);
  }
  Future<void> updateDocument(Map data , String id) {
    return ref.document(id).updateData(data) ;
  }

}

class CRUDModel extends ChangeNotifier {
  CRUD crud = CRUD('table');

  List<TimeTable> tts = [];

  Future<List<TimeTable>> fetchProducts(String uid) async {
    var result = await crud.getDataCollection(uid);
    tts = result.documents
        .map((doc) => TimeTable.fromMap(doc.data, doc.documentID))
        .toList();
    return tts;
  }

  Stream<QuerySnapshot> fetchProductsAsStream(String uid) {
    return crud.streamDataCollection(uid);
  }

  Future<TimeTable> getProductById(String id) async {
    var doc = await crud.getDocumentById(id);
    return  TimeTable.fromMap(doc.data, doc.documentID) ;
  }


  Future removeProduct(String id) async{
    await crud.removeDocument(id);
    return ;
  }

  Future updateProduct(TimeTable data,String id) async{
    await crud.updateDocument(data.toJson(), id) ;
    return ;
  }

  Future addProduct(TimeTable data) async{
    var result  = await crud.addDocument(data.toJson()) ;

    return ;

  }
}