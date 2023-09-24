import 'package:flutter/material.dart';
import 'package:flutter_gif/flutter_gif.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:expandable_text/expandable_text.dart';

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

      // gif name 순서 변경(shuffle) 및 10배 뻥튀기
      for (var i=0;i<10;i++){
        gifNameList.shuffle();
        gifNameListFinal = gifNameListFinal + gifNameList;
      }

    } else {
      // firestore에서 불러온 데이터가 null인 경우
      gifNameList = [];
      gifNameListFinal = [];
    }
  }

// 3. local url 불러오기
  //flutter_secure_storage 사용을 위한 초기화 작업
  static final storage = new FlutterSecureStorage();
  Map<String, dynamic> nameUrlDataLocal = {};
  String? nameUrlDataLocalString = '';

  Future<void> _callNameUrlDataLocal() async {
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

  // 4. gif file 명 index 0~4 가 local url에 있는지 확인
  // 5. 없으면 firebase storage 에서 불러오고 local url에 저장

  int urlIndex = 0;
  // Create a storage reference from our app
  final storageRef = FirebaseStorage.instance.ref();

  // urlIndex 부터 +5까지
  Future<void> _readStorageProactive() async {
    print('_readStorageProactive work');
    // gifNameList 불러오고 실행
    for (var i = 0;i < 5;i ++){
      // urlIndex 부터 urlIndex + 4까지 5개 검사. 없으면 실행
      if (!nameUrlDataLocal.keys.contains(gifNameListFinal[urlIndex + i])){
        var gifName = gifNameListFinal[urlIndex + i];
        print('call url $gifName');
        final pathReference = storageRef.child("version_001/$gifName");
        final _url = await pathReference.getDownloadURL();
        nameUrlDataLocal[gifName] = _url.toString();

        String _nameUrlDataLocalString = json.encode(nameUrlDataLocal);
        await storage.write(
          key: "urlName",
          value: _nameUrlDataLocalString,
        );
      }
    }
  }

  bool initWorkAllDone = false ;

  void initWorkAll(db) async {
    print('initWorkAll');
    await authAnon();
    print('authAnon');
    await _loadFirestore(db);
    print('_loadFirestore');
    await _callNameUrlDataLocal();
    print('_callNameUrlDataLocal');
    await _readStorageProactive();
    print('_readStorageProactive');
    setState(() {
      initWorkAllDone = true ;
    });
  }

  void _deleteFlutterSecureStorage(String key) async {
    await storage.delete(key: key);
  }

  Widget initWorkAllExcute(){
    if (initWorkAllDone == false){
      return CircularProgressIndicator();
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.network(
          nameUrlDataLocal[gifNameListFinal[urlIndex]].toString(),
          width: 300,
          height: 400,
          fit: BoxFit.contain,
        ),
      );
    }
  }

  // when click next
  void _readStorageProactiveOne(int index) async {
    print('_readStorageProactiveOne work');
    // gifNameList 불러오고 실행
    if (!nameUrlDataLocal.keys.contains(gifNameListFinal[index + 4])){
      var gifName = gifNameListFinal[index + 4];
      print('call url $gifName');
      final pathReference = storageRef.child("version_001/$gifName");
      final _url = await pathReference.getDownloadURL();
      nameUrlDataLocal[gifName] = _url.toString();

      String _nameUrlDataLocalString = json.encode(nameUrlDataLocal);
      await storage.write(
        key: "urlName",
        value: _nameUrlDataLocalString,
      );
    }
  }

  @override
  void initState() {
    // gif control 목적
    controller = FlutterGifController(vsync: this);

    // initState 내 비동기 활용하기 위해여 필요함 WidgetsBinding.instance.addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // gif controller 설정
      controller.repeat(
        min: 0,
        max: 10,
        period: const Duration(milliseconds: 1500),
      );
    });

    // call url from local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initWorkAll(db);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: PageView.builder(
        itemCount: gifNameListFinal.length,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {

          String url = nameUrlDataLocal[gifNameListFinal[index]].toString();
          print(url);
          print(gifNameListFinal[index]);
          print(index);
          _readStorageProactiveOne(index);
          return ReelItem(index: index, url:url);
        }
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(
    //     title: Text('짤방'),
    //   ),
    //   body: Column(
    //     children: [
    //       // Text('testst'),
    //       initWorkAllExcute(),
    //       // file name list get from firestore
    //       // futureBuilderTemp(),
    //       ElevatedButton(
    //         onPressed: () {
    //           setState(() {
    //             urlIndex += 1;
    //           });
    //           _readStorageProactiveOne();
    //           print(urlIndex);
    //           print(gifNameListFinal[urlIndex]);
    //         },
    //         child: Container(
    //           child: Text('다음'),
    //         ),
    //       ),
    //       ElevatedButton(
    //         onPressed: () {
    //           setState(() {
    //             urlIndex -= 1;
    //           });
    //           print(urlIndex);
    //           print(gifNameListFinal[urlIndex]);
    //         },
    //         child: Container(
    //           child: Text('이전'),
    //         ),
    //       ),
    //       ElevatedButton(onPressed: (){
    //         _deleteFlutterSecureStorage('urlName');
    //       }, child: Container(
    //         child: Text('url 정보 초기화'),
    //       ))
    //     ],
    //   ),
    //   // backgroundColor: Colors.black54,
    // );
  }
}



class ReelItem extends StatefulWidget {
  const ReelItem({
    required this.index,
    required this.url,
    Key? key,
  }) : super(key: key);
  final int index;
  final String url;

  static final storage = new FlutterSecureStorage();

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  void _deleteFlutterSecureStorage(String key) async {
    await ReelItem.storage.delete(key: key);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.black,
              image: DecorationImage(
                  image:
                  // Image.network(
                  //   nameUrlDataLocal[gifNameListFinal[urlIndex]].toString(),
                  //   width: 300,
                  //   height: 400,
                  //   fit: BoxFit.contain,
                  // )
                  NetworkImage(
                    // ReelsData[index]['ContentImg'], //ContentImg
                    widget.url,
                  ),
                  fit: BoxFit.cover),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.0),
                        ])),
                height: 80.0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "릴스",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.98),
                            fontSize: 25,
                            fontWeight: FontWeight.w800),
                      ),
                      Icon(Icons.camera),
                      // SvgPicture.asset(
                      //   'assets/images/camera_icon.svg',
                      //   height: 28,
                      // ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.5)
                        ])),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 20),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Container(
                                  //   height: 35,
                                  //   width: 35,
                                  //   decoration: BoxDecoration(
                                  //       shape: BoxShape.circle,
                                  //       image: DecorationImage(
                                  //           image: NetworkImage(
                                  //             ReelsData[index]['UserImg'], //Username
                                  //           ),
                                  //           fit: BoxFit.cover)),
                                  // ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  // Text(
                                  //   ReelsData[index]['Username'], //Username
                                  //   style: TextStyle(
                                  //       color: Colors.white,
                                  //       fontWeight: FontWeight.w600,
                                  //       fontSize: 18),
                                  // ),
                                  // const SizedBox(
                                  //   width: 10,
                                  // ),
                                  // OutlinedButton(
                                  //   onPressed: () {},
                                  //   child: Text(
                                  //       ReelsData[index]['isFollowed']
                                  //           ? '팔로잉'
                                  //           : '팔로우', //isFollowed
                                  //       style: TextStyle(
                                  //         color:  Colors.white,
                                  //         fontWeight: FontWeight.w600,
                                  //       )),
                                  //   style: OutlinedButton.styleFrom(
                                  //     shape: RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.circular(5)),
                                  //     side: const BorderSide(
                                  //       width: 1.5,
                                  //       color:  Colors.white,
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    end: 15.0, start: 5),
                                child: ExpandableText(
                                  'ㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋㅋ',
                                  expandText: '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14),
                                  collapseText: '',
                                  expandOnTextTap: true,
                                  collapseOnTextTap: true,
                                  maxLines: 2,
                                  linkColor: Colors.white.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(
                                height: 15,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.music_note,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  RichText(
                                      text: TextSpan(children: [
                                        TextSpan(
                                          text: '원본 오디오',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                        const TextSpan(
                                          text: ' • ',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14),
                                        ),
                                        // TextSpan(
                                        //   text: ReelsData[index]['Musicname'],
                                        //   style: TextStyle(
                                        //       color: Colors.white,
                                        //       fontWeight: FontWeight.w600,
                                        //       fontSize: 14),
                                        // ),
                                      ])),
                                ],
                              )
                            ],
                          ),
                        )),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          // SvgPicture.asset(
                          //   'assets/images/love_icon.svg',
                          //   height: 28,
                          // ),
                          Icon(Icons.favorite),
                          const SizedBox(
                            height: 7,
                          ),
                          Text(
                            // ReelsData[index]['LikesCount'],
                            '486',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Icon(Icons.comment),
                          // SvgPicture.asset(
                          //   'assets/images/comment_icon.svg',
                          //   height: 28,
                          // ),
                          const SizedBox(
                            height: 7,
                          ),
                          Text(
                            // ReelsData[index]['CommentCount'],
                            '4864',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          IconButton(onPressed: (){
                            _deleteFlutterSecureStorage('urlName');
                            print('url 삭제');
                          },
                            icon: Icon(
                            Icons.message,
                            color: Colors.white,
                            size: 25,
                          ),
                          ),

                          // IconButton(onPressed: (){
                          //   _deleteFlutterSecureStorage('urlName');
                          //   }, icon: Icon(
                          //   Icons.message,
                          //   color: Colors.white,
                          //   size: 25,
                          // )
                          // ),
                          // SvgPicture.asset(
                          //   'assets/images/message_icon.svg',
                          //   height: 28,
                          // ),
                          const SizedBox(
                            height: 20,
                          ),
                          const Icon(
                            Icons.abc,
                            color: Colors.white,
                            size: 25,
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          // Padding(
                          //   padding: const EdgeInsets.all(2.0),
                          //   child: Container(
                          //     height: 32,
                          //     width: 32,
                          //     decoration: BoxDecoration(
                          //         border: Border.all(color: Colors.white, width: 2),
                          //         shape: BoxShape.rectangle,
                          //         borderRadius:
                          //         (BorderRadius.all(Radius.circular(7))),
                          //         image: DecorationImage(
                          //             image: NetworkImage(
                          //               ReelsData[index]['MusicImg'],
                          //             ),
                          //             fit: BoxFit.cover)),
                          //   ),
                          // ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}