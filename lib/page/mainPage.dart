import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter_gif/flutter_gif.dart';

import '../component/auth.dart';
import 'reelFavoritePage.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// TickerProviderStateMixin for gif play
class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {

  // gif controller
  // late FlutterGifController controller = FlutterGifController(vsync: this);

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

  // 초기 수행 함수 정의
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

  bool initWorkAllDone = false  ;
  // 초기 세팅 함수 하나로 모으기
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

  // 함수화
  Widget initWorkAllExcute(){
    if (initWorkAllDone == false){
      return Center(
          child: CircularProgressIndicator()
      );
    } else {
      return SafeArea(
        child: PageView.builder(
            itemCount: gifNameListFinal.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {

              String url = nameUrlDataLocal[gifNameListFinal[index]].toString();
              String fileName = gifNameListFinal[index];
              print(url);
              print('file name ${gifNameListFinal[index]}');
              print(index);
              _readStorageProactiveOne(index);
              return ReelItem(
                index: index,
                url:url,
                fileName:fileName,
                favoriteListAdd:_favoriteListAdd,
                favoriteListRemove:_favoriteListRemove,
                nameUrlDataLocal:nameUrlDataLocal,
                favoriteList:favoriteList,
              );
            }
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

  List<String> favoriteList = [];
  // favorite list update
  void _favoriteListAdd(String gifName) async {
    setState(() {
      favoriteList.add(gifName);
    });

    String favoriteListString = favoriteList.join(',');

    await storage.write(
      key: 'favoriteList',
      value: favoriteListString,
    );
    print(favoriteList);
  }

  void _favoriteListRemove(String gifName) async {
    setState(() {
      favoriteList.removeWhere((item) => item == gifName);
    });

    String favoriteListString = favoriteList.join(',');

    await storage.write(
      key: 'favoriteList',
      value: favoriteListString,
    );
    print(favoriteList);
  }

  void _favoriteRead() async {
    String? favoriteListString = await storage.read(key: 'favoriteList');
    if (favoriteListString == null){

    } else {
      setState(() {
        favoriteList = favoriteListString.split(',');
      });
    }
    print(favoriteList);
  }

  @override
  void initState() {
    // gif control 목적
    // controller = FlutterGifController(vsync: this);

    // initState 내 비동기 활용하기 위해여 필요함 WidgetsBinding.instance.addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // gif controller 설정
      // controller.repeat(
      //   min: 0,
      //   max: 10,
      //   period: const Duration(milliseconds: 1500),
      // );
    });

    // call url from local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initWorkAll(db);
      _favoriteRead();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return initWorkAllExcute();

  }
}

class ReelItem extends StatefulWidget {
  const ReelItem({
    required this.index,
    required this.url,
    required this.fileName,
    required this.favoriteListAdd,
    required this.favoriteListRemove,
    required this.nameUrlDataLocal,
    required this.favoriteList,
    Key? key,
  }) : super(key: key);
  final int index;
  final String url;
  final String fileName;
  final favoriteListAdd;
  final favoriteListRemove;
  final Map<String, dynamic> nameUrlDataLocal;
  final List<String> favoriteList;

  static final storage = new FlutterSecureStorage();

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {

  // 삭제 버튼 임시 사용 test 목적
  void _deleteFlutterSecureStorage(String key) async {
    await ReelItem.storage.delete(key: key);
  }

  int favoriteCount = 0 ;

  static final storage = new FlutterSecureStorage();
  // storage read
  void readFavoriteCount() async {

    String? favoriteCountString = await storage.read(key: widget.fileName);
    if (favoriteCountString == null){
      print('favoriteCountString is null');
    } else {
      setState(() {
        favoriteCount = int.parse(favoriteCountString);
      });
    }
  }

  // storage write
  void writeFavoriteCount(int favoriteCount) async {
    await storage.write(
      key: widget.fileName,
      value: favoriteCount.toString(),
    );
  }

  String _value = 'N/A';

  void _updateFavoriteCount() {
    readFavoriteCount();
  }

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // read favorite count
      readFavoriteCount();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 추가
      child: Scaffold(
        body: Stack(
          children: [
            // image
            InkWell(
              onTap: (){
                setState(() {
                  favoriteCount += 1;
                });
                writeFavoriteCount(favoriteCount);
                if (favoriteCount==1){
                  widget.favoriteListAdd(widget.fileName);
                }
              },
              child: Container(
                width: double.infinity,
                height: double.maxFinite,
                decoration: BoxDecoration(
                  color: Colors.black,
                  image: DecorationImage(
                      image:
                      NetworkImage(
                        widget.url,
                      ),
                      fit: BoxFit.cover),
                ),
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "뭐먹짤",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.98),
                              fontSize: 25,
                              fontWeight: FontWeight.w800),
                        ),
                        Expanded(child: SizedBox()),
                        // 즐겨찾기
                        IconButton(
                          icon:Icon(Icons.bookmarks_rounded),
                          color: Colors.white,
                          onPressed: () async {

                            bool isBack = await Navigator.push(context,
                                MaterialPageRoute(builder: (context) =>  ReelItemFavoriteBefore(
                                          favoriteList: widget.favoriteList,
                                          nameUrlDataLocal: widget.nameUrlDataLocal,
                                          favoriteListAdd:widget.favoriteListAdd,
                                          favoriteListRemove:widget.favoriteListRemove,
                                        )
                                    )
                            );
                            if (isBack) {
                              _updateFavoriteCount();
                            }

                            // print('toFavoritePage');
                            // // toFavoritePage();
                            // Navigator.push(
                            //   context, MaterialPageRoute(builder: (context){
                            //     return ReelItemFavoriteBefore(
                            //       favoriteList: widget.favoriteList,
                            //       nameUrlDataLocal: widget.nameUrlDataLocal,
                            //       favoriteListAdd:widget.favoriteListAdd,
                            //       favoriteListRemove:widget.favoriteListRemove,
                            //     );
                            //   })
                            // );
                          },
                        ),
                        SizedBox(width: 13.0,),
                        // 공유
                        Icon(Icons.ios_share,
                          color: Colors.white,
                        ),
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
                          child: SizedBox()
                      ),
                      Padding(
                        padding:
                        EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Column(
                          children: [
                            InkWell(
                              onLongPress:(){
                                setState(() {
                                  favoriteCount = 0;
                                });
                                writeFavoriteCount(favoriteCount);
                                if (favoriteCount==0){
                                  widget.favoriteListRemove(widget.fileName);
                                }
                              },
                              onTap: (){
                                setState(() {
                                  favoriteCount += 1;
                                });
                                writeFavoriteCount(favoriteCount);
                                if (favoriteCount==1){
                                  widget.favoriteListAdd(widget.fileName);
                                }
                              },
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              // ReelsData[index]['LikesCount'],
                              favoriteCount.toString(),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            SizedBox(height: 30.0,)
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
      ),
    );
  }
}