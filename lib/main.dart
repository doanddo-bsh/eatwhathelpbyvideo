import 'package:flutter/material.dart';
import 'package:flutter_gif/flutter_gif.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:async/async.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // <- firebase add init setting
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'help',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  ////////////////////////////////////////////////////////////
  // variable setting
  late FlutterGifController controller= FlutterGifController(vsync: this);

  late Future<List<String>> gifNameList ;
  late List<String> gifNameListNow ;

  late Future<String> urlFuture ;
  late String urlNow ;

  int urlIndex = 0 ;

  // read firestore
  final db = FirebaseFirestore.instance;

  // Create a storage reference from our app
  final storageRef = FirebaseStorage.instance.ref();

  // local data
  // flutter_secure_storage
  Map<String, dynamic> nameUrlDataLocal = {};
  String? nameUrlDataLocalString = '';
  bool callUrl = false ;
  //flutter_secure_storage 사용을 위한 초기화 작업
  static final storage = new FlutterSecureStorage();

  ////////////////////////////////////////////////////////////
  // function

  // encode decode func 생성
  //
  // import 'dart:convert';
  //
  // Map<String, int> a = {'ss':3,'aac':5};
  //
  // void main() {
  //   print(a['ss']);
  //   print(a.toString());
  //   String jsonstringmap = json.encode(a);
  //   print(jsonstringmap);
  //   Map<String, dynamic> valueMap = jsonDecode(jsonstringmap);
  //   print(valueMap['ss']);
  //   print(valueMap['aac']);
  //
  // }

  // future builder 순서
  // 짤이름리스트 -> local storage 불러오고 없으면 -> firestore
  // init 에서  https://eory96study.tistory.com/36
  // 저거 보고 짤리스트의 초기 5개 확인해서 없으면 url 추가
  // 짤리스트 추가되면 기존거 지우고 새거 저장

  // firestore - 파일명 리스트 가져오기
  Future<List<String>> _loadFirestore(db) async{

    List<String> gifNameList = [];

    var rlt_test =
    await db
        .collection("gif_name_list_by_version")
        .doc('version_001')
        .get();

    // null check
    if (rlt_test.data() != null) {
      var list = List.generate(rlt_test
          .data()
          .length, (i) => i);

      print('여기가 되고 있음 firestore호출');
      List<String> gifNameList_tmp = [];

      for (var i in list) {

        gifNameList_tmp.add(rlt_test.data()![i.toString()].toString());
      }
      gifNameList = gifNameList_tmp;

    } else {
      gifNameList = [];
    }
    return gifNameList;
  }

  // read firebase storage
  Future<String> readStorage(String gifName) async {
    print('url 호출');
    final pathReference = storageRef.child("version_001/$gifName");
    final _url = await pathReference.getDownloadURL();
    callUrl = true ;

    return _url;
  }

  late Future myFuture;

  void _callNameUrlDataLocal() async {
    print('_callNameUrlDataLocal');
    //read 함수를 통하여 key값에 맞는 정보를 불러오게 됩니다. 이때 불러오는 결과의 타입은 String 타입임을 기억해야 합니다.
    //(데이터가 없을때는 null을 반환을 합니다.)
    nameUrlDataLocalString = await storage.read(key: "urlName");
    print(nameUrlDataLocalString);

    //user의 정보가 있다면 바로 로그아웃 페이지로 넝어가게 합니다.
    if (nameUrlDataLocalString != null) {
      print(nameUrlDataLocalString);
      // Navigator.pushReplacement(
      //     context,
      //     CupertinoPageRoute(
      //         builder: (context) => LogOutPage(
      //           id: nameUrlDataLocalString.split(" ")[1],
      //           pass: nameUrlDataLocalString.split(" ")[3],
      //         )));
      nameUrlDataLocal = jsonDecode(nameUrlDataLocalString!);
      print(nameUrlDataLocal);
    } else {
      print('yet null');
    }
  }

  void _writeNameUrlDataLocal(nameUrlDataLocal) async {

    print('_writeNameUrlDataLocal work');
    String _nameUrlDataLocalString = json.encode(nameUrlDataLocal);

    if (callUrl){

      print('_writeNameUrlDataLocal real work callUrl : $callUrl');

      await storage.write(
        key: "urlName",
        value: _nameUrlDataLocalString,
      );
      callUrl = false ;
    }
  }

  //   print(a['ss']);
  //   print(a.toString());
  //   String jsonstringmap = json.encode(a);
  //   print(jsonstringmap);
  //   Map<String, dynamic> valueMap = jsonDecode(jsonstringmap);
  //   print(valueMap['ss']);
  //   print(valueMap['aac']);

  @override
  void initState() {
    controller = FlutterGifController(vsync: this);
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      controller.repeat(
        min: 0,
        max: 10,
        period: const Duration(milliseconds: 1500),
      );
    });

    myFuture = _loadFirestore(db);


    // call url from local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callNameUrlDataLocal();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    // write url to local db when after load url
    _writeNameUrlDataLocal(nameUrlDataLocal);

    return Scaffold(
      appBar: AppBar(
        title: Text('짤방'),
      ),
      body: Column(
        children: [
          // Text('testst'),

          // file name list get from firestore
          FutureBuilder(
              future: myFuture,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분을 의미한다.
                if (snapshot.hasData == false) {
                  return CircularProgressIndicator();
                }
                //error가 발생하게 될 경우 반환하게 되는 부분
                else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(fontSize: 15),
                    ),
                  );
                }
                // 데이터를 정상적으로 받아오게 되면 다음 부분을 실행하게 되는 것이다.
                else {
                  // print("이게 짤 리스트 ${snapshot.data.toString()}");
                  gifNameListNow = snapshot.data;
                  // 짤 파일명 리스트 랜덤 순서 적용
                  // gifNameListNow.shuffle();

                  // 있는지 확인
                  bool haveUrl = nameUrlDataLocal.keys.contains(gifNameListNow[urlIndex]);

                  return haveUrl? Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      nameUrlDataLocal[gifNameListNow[urlIndex]].toString(),
                      width: 300,
                      height: 400,
                      fit: BoxFit.contain,
                    ),
                  ):FutureBuilder(
                      future: readStorage(gifNameListNow[urlIndex]),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분을 의미한다.
                        if (snapshot.hasData == false) {
                          return CircularProgressIndicator();
                        }
                        //error가 발생하게 될 경우 반환하게 되는 부분
                        else if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(fontSize: 15),
                            ),
                          );
                        }
                        // 데이터를 정상적으로 받아오게 되면 다음 부분을 실행하게 되는 것이다.
                        else {
                          print('여기 되고 있음??? ${snapshot.data.toString()}');
                          print('nameUrlDataLocal $nameUrlDataLocal');
                          nameUrlDataLocal[gifNameListNow[urlIndex]] =
                              snapshot.data.toString();
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(
                              snapshot.data.toString(),
                              width: 300,
                              height: 400,
                              fit: BoxFit.contain,
                            ),
                          );
                        }
                      }
                  );
                }
              }
          ),
          ElevatedButton(
            onPressed: (){
              setState(() {
                urlIndex += 1;
              });
              print(gifNameListNow.length);
            },
              child: Container(child: Text('다음'),),
          ),
          ElevatedButton(
            onPressed: (){
              setState(() {
                urlIndex -= 1;
              });
            },
            child: Container(
              child: Text('이전'),
            ),
          )
        ],
      ),
      // backgroundColor: Colors.black54,
    );
  }
}

