import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'timetableDB.dart';
import 'storage.dart';
import 'create.dart';
import 'login.dart';
import 'table.dart';

final TT = TTModel();

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<StorageUploadTask> _tasks = <StorageUploadTask>[];
  final FirebaseStorage storage = FirebaseStorage.instance;
  final List<Widget> children = <Widget>[];
  bool is_home = true;

  @override
  void initState() {
    _tasks.forEach((StorageUploadTask task) {
      final Widget tile = UploadTaskListTile(
        task: task,
        onDismissed: () => setState(() => _tasks.remove(task)),
        onDownload: () => _downloadFile(task.lastSnapshot.ref),
      );
      children.add(tile);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: _mybody(),
      bottomNavigationBar: _makeBottom(),
      floatingActionButton: is_home
          ? FloatingActionButton(
              child: Icon(Icons.add),
              backgroundColor: Color(0xFFFFCA55),
              onPressed: () => _dialog(),
            )
          : FloatingActionButton(
              child: Icon(Icons.file_upload),
              backgroundColor: Color(0xFFFFCA55),
              onPressed: () => _selecDialog(context),
            ),
    );
  }

  Widget _makeBottom() {
    return Container(
      height: 55.0,
      child: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.home, color: Colors.black),
              onPressed: () {
                setState(() {
                  is_home = true;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.storage, color: Colors.black),
              onPressed: () {
                setState(() {
                  is_home = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _mybody() {
    final _logo = Column(
      children: <Widget>[
        Image.asset(
          'image/logo_small.png',
          width: 80,
          height: 20,
          fit: BoxFit.contain,
        ),
        Text(
          '이번 학기를 채울 모든 경우의 수',
          style: TextStyle(fontSize: 7),
        ),
      ],
    );

    final _top = Row(
      children: <Widget>[
        _logo,
        Expanded(
          child: SizedBox(),
        ),
        Text(
          "${user.displayName} 님, 반가워요!",
          style: TextStyle(fontSize: 12),
        ),
        SizedBox(
          width: 7,
        ),
        SizedBox(
          width: 80,
          height: 25,
          child: RaisedButton(
            color: const Color(0xFFFFCA55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(55)),
            child: Text('Logout', style: TextStyle(color: Colors.white),),
            onPressed: () {
              signOut();
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );

    Widget slideRightBackground() {
      return Container(
        color: Colors.green,
        child: Align(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 20,
              ),
              Icon(
                Icons.edit,
                color: Colors.white,
              ),
              Text(
                " Edit",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
        ),
      );
    }

    Widget slideLeftBackground() {
      return Container(
        color: Colors.red,
        child: Align(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                Icons.delete,
                color: Colors.white,
              ),
              Text(
                " Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(
                width: 20,
              ),
            ],
          ),
          alignment: Alignment.centerRight,
        ),
      );
    }

    _updateLst() {
      for (int i = 0; i < TT.tts.length; i++) {
        TT.tts[i].order = i;
        TT.updateProduct(TT.tts[i], TT.tts[i].id);
      }
    }

    _makeListTile(DocumentSnapshot data) {
      final tt = TimeTable.fromSnapshot(data);
      TT.tts.add(tt);

      return Dismissible(
        key: UniqueKey(),
        background: slideRightBackground(),
        secondaryBackground: slideLeftBackground(),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            bool isCheck;
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  content: Text("\n'${tt.name}'\n시간표를 삭제하시겠습니까?",
                    textAlign: TextAlign.center,),
                  actions: <Widget>[
                    FlatButton(
                      child: Text("취소",),
                      onPressed: () {
                        isCheck = false;
                        Navigator.pop(context);
                      },
                    ),
                    FlatButton(
                      child: Text(
                        "확인",
                        style: TextStyle(color: Color(0xFF225B95),
                          fontWeight: FontWeight.bold,),
                      ),
                      onPressed: () {
                        TT.removeProduct(tt.id);
                        TT.tts.remove(tt);
                        _updateLst();
//                        print(TT.tts[0]);
                        isCheck = true;
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              });
            print("check:" + isCheck.toString());
            return isCheck;
          } else {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return CupertinoAlertDialog(
                  content: Text("\n'${tt.name}'\n시간표를 수정하시겠습니까?",
                    textAlign: TextAlign.center,),
                  actions: <Widget>[
                    FlatButton(
                      child: Text("취소",),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    FlatButton(
                      child: Text(
                        "확인",
                        style: TextStyle(color: Color(0xFF225B95),
                          fontWeight: FontWeight.bold,),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) => CreatePage(tt: tt)));
                      },
                    ),
                  ],
                );
              });
            return false;
          }
        },
        child: Container(
          margin:  EdgeInsets.symmetric(vertical: 8.0),
          decoration: BoxDecoration(color: Color(0xFF9CBADF)),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.only(right: 12.0),
              child: Icon(Icons.menu, color: Colors.white),
            ),
            title: Text(
              tt.name,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: <Widget>[
                Icon(Icons.flash_on, color: Color(0xFFFFCA55), size: 17),
                Text("credit : " + tt.credit.toString(), style: TextStyle(color: Colors.white))
              ],
            ),
            onTap: () => showTable(context, tt),
          ),
        ),
      );
    }

    _makeList(BuildContext context, List<DocumentSnapshot> snapshots) {
      if (snapshots == null || snapshots.isEmpty) {
        return const [];
      }

      return ListView(
        children: snapshots.map((data) => _makeListTile(data)).toList(),
      );
    }

    final _homebody = Container(
      padding: EdgeInsets.fromLTRB(10, 30, 10, 0),
      child: StreamBuilder<QuerySnapshot>(
        stream: TT.fetchProductsAsStream(user.uid),
        builder: (context, snapshot) {
          TT.tts.clear();
          if (!snapshot.hasData)
            return Center(
              child: Text("생성된 시간표가 없습니다.\n\n아래의 '+' 버튼을 통해 시간표를 생성해주세요.", textAlign: TextAlign.center, ),
            );
          else return _makeList(context, snapshot.data.documents);
        }
      ),
    );

    final _emptybox = SizedBox(
      height: 85,
    );

    final _docbody = Container(
      padding: EdgeInsets.fromLTRB(10, 30, 10, 0),
      child: ListView(
        children: children,
      ),
    );

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _top,
            Expanded(
              child: is_home? _homebody : _docbody,
            ),
            _emptybox,
          ],
        ),
      ),
    );
  }

  Future<void> uploadFile(String content) async {
    Directory tempDir = await getTemporaryDirectory();
    final File f = await File("${tempDir.path}/test.txt").create(); // 이름 적어

    await f.writeAsString(content);
    assert(await f.readAsString() == content);

    final StorageReference ref = storage.ref().child("test"); // 이름 적어
    final StorageUploadTask uploadTask = ref.putFile(f);

    setState(() {
      _tasks.add(uploadTask);
      _tasks.forEach((StorageUploadTask task) {
        final Widget tile = UploadTaskListTile(
          task: task,
          onDismissed: () => setState(() => _tasks.remove(task)),
          onDownload: () => _downloadFile(task.lastSnapshot.ref),
        );
        children.add(tile);
      });
    });
  }

  Future<void> _downloadFile(StorageReference ref) async {
    final String url = await ref.getDownloadURL();
    final http.Response downloadData = await http.get(url);

    final String fileContents = downloadData.body;

    print("contents:" + fileContents);
    final String name = await ref.getName();
    final String bucket = await ref.getBucket();
    final String path = await ref.getPath();
//    _scaffoldKey.currentState.showSnackBar(SnackBar(
//      content: Text(
//        'Success!\n Downloaded $name \n from url: $url @ bucket: $bucket\n '
//            'at path: $path \n\nFile contents: "$fileContents" \n'
//            'Wrote "$tempFileContents" to tmp.txt',
//        style: const TextStyle(color: Color.fromARGB(255, 0, 155, 0)),
//      ),
//    ));
  }

  TextEditingController _tableNameController = new TextEditingController();
  final _formKey = GlobalKey<FormState>();

  _isSame(String name) {
    for(int i = 0; i < TT.tts.length; i++) {
      if (TT.tts[i].name == name) return true;
    }
    return false;
  }

  _dialog() {
    bool isWrong = false;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog (
          title: Text(
            '새로운 시간표 만들기',
            style: TextStyle(color: Color(0xFF225B95), fontWeight: FontWeight.bold),
          ),
          content: Column(
            children: <Widget>[
              SizedBox(height: 8,),
              Form(
                key: _formKey,
                child: CupertinoTextField(
                  controller: _tableNameController,
                  placeholder: "시간표의 이름을 입력하세요",
//                  decoration: BoxDecoration(color: Colors.white30),
                // TODO add validator!!
//                  validator: (value) {
//                    if (isWrong) {
//                      return '시간표의 이름을 다시 확인해주세요';
//                    }
//                    return null;
//                  },
                ),

              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('취소'),
              onPressed: () {
                isWrong = false;
                Navigator.pop(context);
              },
            ),
            FlatButton(
              child: Text(
                  '확인',
                  style: TextStyle(color: Color(0xFF225B95), fontWeight: FontWeight.bold)
              ),
              onPressed: () {
                if (_tableNameController.text == null || _isSame(_tableNameController.text)) {
                  setState(() {
                    isWrong = true;
                  });
                } else {
                  isWrong = false;
                  TimeTable newTT = TimeTable(_tableNameController.text, TT.tts.length);
                  _tableNameController.clear();
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => CreatePage(tt: newTT,)));
                }
              },
            ),
          ],
        );
      },
    );
  }

  _selecDialog(BuildContext context) {
    return _containerForSheet<String>(
      context: context,
      child: CupertinoActionSheet(
        title: Text('사진을 선택해주세요.'),
        actions: <Widget>[
          CupertinoActionSheetAction(
            child: Text('Album'),
            onPressed: () {
              Navigator.pop(context, 'Album');
            },
          ),
          CupertinoActionSheetAction(
            child: Text('Camera'),
            onPressed: () {
              Navigator.pop(context, 'Camera');
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text("Cancel"),
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context, "Cancel"),
        ),
      ),
    );
  }

  _containerForSheet<String>({BuildContext context, Widget child}) {
    showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((String value) {
      if (value == 'Camera') {
        _cameraMlKit();
      } else if (value == 'Album') {
        _albumMlKit();
      }
    });
  }

  _cameraMlKit() async {
    final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    var _image = await ImagePicker.pickImage(source: ImageSource.camera);
    File image = _image;

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(image);
    final VisionText visionText = await textRecognizer.processImage(visionImage);

    String text = visionText.text;
    textRecognizer.close();

    uploadFile(text);
  }

  _albumMlKit() async {
    final TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    var _image = await ImagePicker.pickImage(source: ImageSource.gallery);
    File image = _image;

    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(image);
    final VisionText visionText = await textRecognizer.processImage(visionImage);

    String text = visionText.text;
    textRecognizer.close();

    uploadFile(text);
  }

}