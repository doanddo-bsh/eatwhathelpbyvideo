import 'package:flutter/material.dart';
import 'package:flutter_gif/flutter_gif.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth.dart';
// import 'package:async/async.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

void main() async {
  // 비동기 되게 하는 문장
  WidgetsFlutterBinding.ensureInitialized();

  // firebase init
  await Firebase.initializeApp(
    // to make lib/firebase_options.dart
    options: DefaultFirebaseOptions.currentPlatform,
  ); // <- firebase add init setting

  // run app
  runApp(const MyApp());
}

// MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eatwhathelpbyvideo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

  // TickerProviderStateMixin for gif play
class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  // gif controller
  late FlutterGifController controller = FlutterGifController(vsync: this);

  // 초기 수행 정리
  // 1. 익명 로그임
  // 2. gif file 명 가져오기
  // 3. local url 불러오기
  // 4. gif file 명 index 0~4 가 local url에 있는지 확인
  // 5. 없으면 firebase storage 에서 불러오고 local url에 저장
  // 이게 완료될때까지 circle 돌기

  // 스크롤 넘길때 마다
  // 4. gif file 명 index 0~4 가 local url에 있는지 확인
  // 5. 없으면 firebase storage 에서 불러오고 local url에 저장

  // 초기 수행



  // 1. 익명 로그임
  final AuthService _auth = AuthService();

  Future<void> authAnon() async {
    dynamic result = await _auth.signInAnon();

    if (result == null) {
      print('@@ error signing in');
    } else {
      print('@@ signed in');
      print(result); // return Instance of UserModel
      print(result.uid); // return uid value in UserModel class
    }
  }

  // 2. gif file 명 가져오기
  final db = FirebaseFirestore.instance;
  bool gifNameListCalled = false;
  List<String> gifNameList = [];
  List<String> gifNameListFinal = [];

  // firestore(db gif이름이 저장된 곳)에서 파일명 리스트 가져오기
  Future<void> _loadFirestore(db) async {
    // List<String> gifNameList = [];

    // read all file name
    var rlt_test = await db
        .collection("gif_name_list_by_version")
        .doc('version_001')
        .get();

    // null check // not null 일때 작동
    if (rlt_test.data() != null) {
      // data 수 만큼 list 0~n 생성
      var list = List.generate(rlt_test.data().length, (i) => i);

      // temp var setting
      List<String> gifNameList_tmp = [];

      // parsing
      for (var i in list) {
        gifNameList_tmp.add(rlt_test.data()![i.toString()].toString());
      }

      // 전역변수에 넣어주기
      gifNameList = gifNameList_tmp;

      setState(() {
        // 불러왔다는걸 알려주기
        gifNameListCalled = true;
      });

      // gif name 순서 변경(shuffle) 및 10배 뻥튀기
      for (var i=0;i<10;i++){
        gifNameList.shuffle();
        gifNameListFinal = gifNameListFinal + gifNameList;
      }

    } else {
      // firestore에서 불러온 데이터가 null인 경우
      gifNameList = [];
    }
  }

  void initWorkAll(db) async {
    await authAnon();
    await _loadFirestore(db);
  }




  late String urlNow;

  int urlIndex = 0;


  // local data
  // flutter_secure_storage
  Map<String, dynamic> nameUrlDataLocal = {};
  String? nameUrlDataLocalString = '';
  bool callUrl = false;
  bool haveUrl = false;





  // Create a storage reference from our app
  final storageRef = FirebaseStorage.instance.ref();

  // read firebase storage
  Future<String> _readStorage(String gifName) async {
    print('url 호출 $gifName');
    final pathReference = storageRef.child("version_001/$gifName");
    final _url = await pathReference.getDownloadURL();
    callUrl = true;

    return _url;
  }

  // urlIndex 부터 +5까지
  void _readStorageProactive() async {
    print('_readStorageProactive work');
    // gifNameList 불러오고 실행
    if (gifNameListCalled){
      for (var i = 0;i < 5;i ++){
        // urlIndex 부터 urlIndex + 4까지 5개 검사. 없으면 실행
        if (!nameUrlDataLocal.keys.contains(gifNameListFinal[urlIndex + i])){
          var gifName = gifNameListFinal[urlIndex + i];
          print('call url $gifName');
          final pathReference = storageRef.child("version_001/$gifName");
          final _url = await pathReference.getDownloadURL();
          nameUrlDataLocal[gifName] = _url.toString();
          callUrl = true;
        }
      }
    }
  }

  //flutter_secure_storage 사용을 위한 초기화 작업
  static final storage = new FlutterSecureStorage();

  void _deleteFlutterSecureStorage(String key) async {
    await storage.delete(key: key);
  }

  void _callNameUrlDataLocal() async {
    print('_callNameUrlDataLocal');
    // read 함수를 통하여 key값에 맞는 정보를 불러오게 됩니다. 이때 불러오는 결과의 타입은 String 타입임을 기억해야 합니다.
    // (데이터가 없을때는 null을 반환을 합니다.)
    nameUrlDataLocalString = await storage.read(key: "urlName");

    // null 이 아닌 경우 string을 decode 하여 저장
    if (nameUrlDataLocalString != null) {
      nameUrlDataLocal = jsonDecode(nameUrlDataLocalString!);

    } else {
      print('yet, null check');
    }
  }

  void _writeNameUrlDataLocal(nameUrlDataLocal) async {
    print('_writeNameUrlDataLocal work');
    String _nameUrlDataLocalString = json.encode(nameUrlDataLocal);

    if (callUrl) {
      print('_writeNameUrlDataLocal real work callUrl : $callUrl');

      await storage.write(
        key: "urlName",
        value: _nameUrlDataLocalString,
      );
      callUrl = false;
    }
  }

  Widget futureBuilderTemp(){

    // bool haveUrl = nameUrlDataLocal.keys.contains(gifNameList[urlIndex]);

    // initState의 함수들 체크
    print('gifNameListCalled $gifNameListCalled');
    print('haveUrl $haveUrl');

    if (gifNameListCalled == true){
      haveUrl = nameUrlDataLocal.keys.contains(gifNameListFinal[urlIndex]);
    }

    if (gifNameListCalled == false){
      return CircularProgressIndicator();
    } else if (haveUrl){
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          nameUrlDataLocal[gifNameListFinal[urlIndex]].toString(),
          width: 300,
          height: 400,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return FutureBuilder(
          future: _readStorage(gifNameListFinal[urlIndex]),
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
              nameUrlDataLocal[gifNameListFinal[urlIndex]] =
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
          });
    }
  }



  @override
  void initState() {
    // gif control 목적
    controller = FlutterGifController(vsync: this);

    // initState 내 비동기 활용하기 위해여 필요함 WidgetsBinding.instance.addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // firebase 익명 로그인 수행
      authAnon();
      // gif controller 설정
      controller.repeat(
        min: 0,
        max: 10,
        period: const Duration(milliseconds: 1500),
      );

    });

    // call url from local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callNameUrlDataLocal();
      _loadFirestore(db);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    // write url to local db when after load url
    _writeNameUrlDataLocal(nameUrlDataLocal);

    // 나중에 천천히 돌면서 / gifNameListCalled true 세팅 이후 현재 gif 이후 5개 더 url 가져오기
    _readStorageProactive();

    return Scaffold(
      appBar: AppBar(
        title: Text('짤방'),
      ),
      body: Column(
        children: [
          // Text('testst'),

          // file name list get from firestore
          futureBuilderTemp(),
          ElevatedButton(
            onPressed: () {
              setState(() {
                urlIndex += 1;
              });
              print(urlIndex);
              print(gifNameListFinal[urlIndex]);
            },
            child: Container(
              child: Text('다음'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                urlIndex -= 1;
              });
              print(urlIndex);
              print(gifNameListFinal[urlIndex]);
            },
            child: Container(
              child: Text('이전'),
            ),
          ),
          ElevatedButton(onPressed: (){
            _deleteFlutterSecureStorage('urlName');
          }, child: Container(
            child: Text('url 정보 초기화'),
          ))
        ],
      ),
      // backgroundColor: Colors.black54,
    );
  }
}
