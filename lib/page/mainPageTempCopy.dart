// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'dart:convert';
// import '../component/auth.dart';
// import 'reelFavoritePage.dart';
// import 'package:gif_view/gif_view.dart';
// import 'videoPage.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:share_plus/share_plus.dart';
// import 'dart:io' show Platform;
// import 'package:flutter_email_sender/flutter_email_sender.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'package:in_app_review/in_app_review.dart';
// import '../model/firebase_file.dart';
// import '../api/firebase_api.dart';
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({Key? key}) : super(key: key);
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// // TickerProviderStateMixin for gif play
// class _MyHomePageState extends State<MyHomePage> {
//   // 초기 수행 정리
//   // 1. 익명 로그임
//   // 2. gif file 명 가져오기
//   // 3. local url 불러오기
//   // 4. gif file 명 index 0~4 가 local url에 있는지 확인
//   // 5. 없으면 firebase storage 에서 불러오고 local url에 저장
//   // 이게 완료될때까지 circle 돌기
//
//   // 스크롤 넘길때 마다
//   // 4. gif file 명 index 0~4 가 local url에 있는지 확인
//   // 5. 없으면 firebase storage 에서 불러오고 local url에 저장
//
//   // 초기 수행 함수 정의
//   // 1. 익명 로그임
//   final AuthService _auth = AuthService();
//
//   Future<void> authAnon() async {
//     dynamic result = await _auth.signInAnon();
//
//     if (result == null) {
//       print('@@ error signing in');
//     } else {
//       print('@@ signed in');
//       print(result); // return Instance of UserModel
//       print(result.uid); // return uid value in UserModel class
//     }
//   }
//
//   // 2. gif file 명 가져오기
//   final db = FirebaseFirestore.instance;
//   bool gifNameListCalled = false;
//   List<String> gifNameList = [];
//   List<String> gifNameListFinal = [];
//
//   // firestore(db gif이름이 저장된 곳)에서 파일명 리스트 가져오기
//   Future<void> _loadFirestore(db) async {
//     // List<String> gifNameList = [];
//
//     // read all file name
//     var rlt_test = await db
//         .collection("gif_name_list_by_version")
//         .doc('version_002')
//         .get();
//
//     // null check // not null 일때 작동
//     if (rlt_test.data() != null) {
//       // data 수 만큼 list 0~n 생성
//       var list = List.generate(rlt_test.data().length, (i) => i);
//
//       // temp var setting
//       List<String> gifNameList_tmp = [];
//
//       // parsing
//       for (var i in list) {
//         gifNameList_tmp.add(rlt_test.data()![i.toString()].toString());
//       }
//
//       // 전역변수에 넣어주기
//       gifNameList = gifNameList_tmp;
//
//       // gif name 순서 변경(shuffle) 및 10배 뻥튀기
//       for (var i = 0; i < 10; i++) {
//         gifNameList.shuffle();
//         gifNameListFinal = gifNameListFinal + gifNameList;
//       }
//     } else {
//       // firestore에서 불러온 데이터가 null인 경우
//       gifNameList = [];
//       gifNameListFinal = [];
//     }
//   }
//
//   // 3. local url 불러오기
//   //flutter_secure_storage 사용을 위한 초기화 작업
//   static final storage = new FlutterSecureStorage();
//   Map<String, dynamic> nameUrlDataLocal = {};
//   String? nameUrlDataLocalString = '';
//
//   Future<void> _callNameUrlDataLocal() async {
//     print('_callNameUrlDataLocal');
//     // read 함수를 통하여 key값에 맞는 정보를 불러오게 됩니다. 이때 불러오는 결과의 타입은 String 타입임을 기억해야 합니다.
//     // (데이터가 없을때는 null을 반환을 합니다.)
//     nameUrlDataLocalString = await storage.read(key: "urlName");
//
//     // null 이 아닌 경우 string을 decode 하여 저장
//     if (nameUrlDataLocalString != null) {
//       nameUrlDataLocal = jsonDecode(nameUrlDataLocalString!);
//     } else {
//       print('yet, null check');
//     }
//   }
//
//   // 4. gif file 명 index 0~4 가 local url에 있는지 확인
//   // 5. 없으면 firebase storage 에서 불러오고 local url에 저장
//   int urlIndex = 0;
//
//   // Create a storage reference from our app
//   final storageRef = FirebaseStorage.instance.ref();
//
//   // urlIndex 부터 +5까지
//   Future<void> _readStorageProactive() async {
//     print('_readStorageProactive work');
//     // gifNameList 불러오고 실행
//     for (var i = 0; i < 5; i++) {
//       // urlIndex 부터 urlIndex + 4까지 5개 검사. 없으면 실행
//       if (!nameUrlDataLocal.keys.contains(gifNameListFinal[urlIndex + i])) {
//         var gifName = gifNameListFinal[urlIndex + i];
//         print('call url $gifName');
//         final pathReference = storageRef.child("version_002/$gifName");
//         final _url = await pathReference.getDownloadURL();
//         nameUrlDataLocal[gifName] = _url.toString();
//
//         String _nameUrlDataLocalString = json.encode(nameUrlDataLocal);
//         await storage.write(
//           key: "urlName",
//           value: _nameUrlDataLocalString,
//         );
//       }
//     }
//   }
//
//   bool initWorkAllDone = false;
//
//   // 초기 세팅 함수 하나로 모으기
//   void initWorkAll(db) async {
//     print('initWorkAll');
//     await authAnon();
//     print('authAnon');
//     await _loadFirestore(db);
//     print('_loadFirestore');
//     await _callNameUrlDataLocal();
//     print('_callNameUrlDataLocal');
//     await _readStorageProactive();
//     print('_readStorageProactive');
//     setState(() {
//       initWorkAllDone = true;
//     });
//   }
//
//   // 함수화
//   Widget initWorkAllExcute() {
//     if (initWorkAllDone == false) {
//       return Center(child: CircularProgressIndicator());
//     } else {
//       return SafeArea(
//         child: PageView.builder(
//           // to make infinite (ref) https://stackoverflow.com/questions/74961995/how-can-i-make-items-repeat-again-if-i-arrive-the-end-of-list
//           // itemCount: gifNameListFinal.length,
//             scrollDirection: Axis.vertical,
//             itemBuilder: (context, index) {
//               if (index == (gifNameListFinal.length - 3)) {
//                 index = index % gifNameListFinal.length - 3;
//               }
//
//               String url = nameUrlDataLocal[gifNameListFinal[index]].toString();
//               // to fast loading
//               String url_next1 =
//               nameUrlDataLocal[gifNameListFinal[index + 1]].toString();
//               String url_next2 =
//               nameUrlDataLocal[gifNameListFinal[index + 2]].toString();
//               String url_next3 =
//               nameUrlDataLocal[gifNameListFinal[index + 3]].toString();
//
//               String fileName = gifNameListFinal[index];
//               print(url);
//               print('file name ${gifNameListFinal[index]}');
//               print(index);
//               _readStorageProactiveOne(index);
//               return ReelItem(
//                 index: index,
//                 url: url,
//                 fileName: fileName,
//                 url_next1: url_next1,
//                 url_next2: url_next2,
//                 url_next3: url_next3,
//                 favoriteListAdd: _favoriteListAdd,
//                 favoriteListRemove: _favoriteListRemove,
//                 nameUrlDataLocal: nameUrlDataLocal,
//                 favoriteListMap: favoriteListMap,
//               );
//             }),
//       );
//     }
//   }
//
//   // when click next
//   void _readStorageProactiveOne(int index) async {
//     print('_readStorageProactiveOne work');
//     // gifNameList 불러오고 실행
//     if (!nameUrlDataLocal.keys.contains(gifNameListFinal[index + 4])) {
//       var gifName = gifNameListFinal[index + 4];
//       print('call url $gifName');
//       final pathReference = storageRef.child("version_002/$gifName");
//       final _url = await pathReference.getDownloadURL();
//       nameUrlDataLocal[gifName] = _url.toString();
//
//       String _nameUrlDataLocalString = json.encode(nameUrlDataLocal);
//       await storage.write(
//         key: "urlName",
//         value: _nameUrlDataLocalString,
//       );
//     }
//   }
//
//   // favoriteList 변경 후
//   Map<String, dynamic> favoriteListMap = {};
//
//   // favorite list update
//   void _favoriteListAdd(String gifName, int favoriteCount) async {
//     favoriteListMap[gifName] = favoriteCount;
//
//     String favoriteListString = json.encode(favoriteListMap);
//
//     await storage.write(
//       key: 'favoriteListMap',
//       value: favoriteListString,
//     );
//     print('_favoriteListAdd $favoriteListMap');
//   }
//
//   void _favoriteListRemove(String gifName) async {
//     // setState(() {
//     favoriteListMap.remove(gifName);
//     // });
//
//     String favoriteListString = json.encode(favoriteListMap);
//
//     await storage.write(
//       key: 'favoriteListMap',
//       value: favoriteListString,
//     );
//     print('_favoriteListRemove $favoriteListMap');
//   }
//
//   void _favoriteRead() async {
//     String? favoriteListString = await storage.read(key: 'favoriteListMap');
//     if (favoriteListString == null) {
//     } else {
//       setState(() {
//         favoriteListMap = json.decode(favoriteListString);
//         favoriteListMap.remove(''); // 혹시 모를 ''이 key로 들어갈 경우를 방지
//       });
//     }
//     print('_favoriteRead $favoriteListMap');
//   }
//
//   // // favoriteList 변경 전
//   // List<String> favoriteList = [];
//   // // favorite list update
//   // void _favoriteListAdd(String gifName) async {
//   //   // setState(() {
//   //     favoriteList.add(gifName);
//   //   // });
//   //
//   //   String favoriteListString = favoriteList.join(',');
//   //
//   //   await storage.write(
//   //     key: 'favoriteList',
//   //     value: favoriteListString,
//   //   );
//   //   print(favoriteList);
//   // }
//   //
//   // void _favoriteListRemove(String gifName) async {
//   //   // setState(() {
//   //   favoriteList.removeWhere((item) => item == gifName);
//   //   // });
//   //
//   //   String favoriteListString = favoriteList.join(',');
//   //
//   //   await storage.write(
//   //     key: 'favoriteList',
//   //     value: favoriteListString,
//   //   );
//   //   print('_favoriteListRemove $favoriteList');
//   // }
//   //
//   // void _favoriteRead() async {
//   //   String? favoriteListString = await storage.read(key: 'favoriteList');
//   //   if (favoriteListString == null){
//   //
//   //   } else {
//   //     setState(() {
//   //       favoriteList = favoriteListString.split(',');
//   //       favoriteList.removeWhere((item) => item == '');
//   //     });
//   //   }
//   //   print('_favoriteRead $favoriteList');
//   // }
//
//   late Future<List<FirebaseFile>> futureFiles ;
//
//   @override
//   void initState() {
//     // initState 내 비동기 활용하기 위해여 필요함 WidgetsBinding.instance.addPostFrameCallback
//     // call url from local
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       initWorkAll(db);
//       _favoriteRead();
//     });
//
//     super.initState();
//
//     futureFiles = FirebaseApi.listAll('version_002/');
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return initWorkAllExcute();
//   }
// }
//
// class ReelItem extends StatefulWidget {
//   ReelItem({
//     required this.index,
//     required this.url,
//     required this.fileName,
//     required this.url_next1,
//     required this.url_next2,
//     required this.url_next3,
//     required this.favoriteListAdd,
//     required this.favoriteListRemove,
//     required this.nameUrlDataLocal,
//     required this.favoriteListMap,
//     Key? key,
//   }) : super(key: key);
//   final int index;
//   final String url;
//   final String fileName;
//   final String url_next1;
//   final String url_next2;
//   final String url_next3;
//   final favoriteListAdd;
//   final favoriteListRemove;
//   final Map<String, dynamic> nameUrlDataLocal;
//   final Map<String, dynamic> favoriteListMap;
//
//   static final storage = new FlutterSecureStorage();
//
//   @override
//   State<ReelItem> createState() => _ReelItemState();
// }
//
// class _ReelItemState extends State<ReelItem> {
//   // to dropdownbutton
//   final List<String> items = [
//     // 어플 공유 버튼은 향후 업데이트
//     // '어플 공유하기',
//     '개선점 보내기',
//     '평점 주기',
//   ];
//   // String? selectedValue;
//
//   final controller = GifController();
//
//   // 삭제 버튼 임시 사용 test 목적
//   void _deleteFlutterSecureStorage(String key) async {
//     await ReelItem.storage.delete(key: key);
//   }
//
//   int favoriteCount = 0;
//
//   static final storage = new FlutterSecureStorage();
//
//   // storage read
//   void readFavoriteCount() async {
//     String? favoriteListString = await storage.read(key: 'favoriteListMap');
//     if (favoriteListString == null) {
//       print('favoriteListMap is null');
//     } else if (widget.favoriteListMap[widget.fileName] == null) {
//       print('widget.favoriteListMap[widget.fileName] is null');
//     } else {
//       setState(() {
//         favoriteCount = widget.favoriteListMap[widget.fileName]!;
//         // favoriteCount = int.parse(favoriteCountString);
//       });
//     }
//     // String? favoriteCountString = await storage.read(key: widget.fileName);
//     // if (favoriteCountString == null){
//     //   print('favoriteCountString is null');
//     // } else {
//     //   setState(() {
//     //     favoriteCount = int.parse(favoriteCountString);
//     //   });
//     // }
//   }
//
//   // storage write
//   // void writeFavoriteCount(int favoriteCount) async {
//   //   await storage.write(
//   //     key: widget.fileName,
//   //     value: favoriteCount.toString(),
//   //   );
//   // }
//
//   String _value = 'N/A';
//
//   PackageInfo _packageInfo = PackageInfo(
//     appName: 'Unknown',
//     packageName: 'Unknown',
//     version: 'Unknown',
//     buildNumber: 'Unknown',
//     buildSignature: 'Unknown',
//     installerStore: 'Unknown',
//   );
//
//   Future<void> _initPackageInfo() async {
//     final info = await PackageInfo.fromPlatform();
//     setState(() {
//       _packageInfo = info;
//     });
//   }
//
//   void _updateFavoriteCount() {
//     readFavoriteCount();
//   }
//
//   Future<String> _getEmailBody() async {
//     // Map<String, dynamic> userInfo = _getUserInfo();
//     // Map<String, dynamic> appInfo = await _getAppInfo();
//     // Map<String, dynamic> deviceInfo = await _getDeviceInfo();
//
//     String body = "";
//
//     body += "\n";
//     body += "\n";
//     body += "==============\n";
//     body += "아래 내용을 함께 보내주시면 큰 도움이 됩니다 🧅\n";
//
//     // userInfo.forEach((key, value) {
//     //   body += "$key: $value\n";
//     // });
//
//     body += "App name, ${_packageInfo.appName}\n";
//     body += "Package name, ${_packageInfo.packageName}\n";
//     body += "App version, ${_packageInfo.version}\n";
//     body += "Build number, ${_packageInfo.buildNumber}\n";
//     body += "Build signature, ${_packageInfo.buildSignature}\n";
//     body += "Installer store, ${_packageInfo.installerStore ?? 'not available'}\n";
//
//     body += "==============\n";
//
//     return body;
//   }
//
//   void _showErrorAlert({String? title, String? message}) {
//     showDialog(
//         context: context,
//         //barrierDismissible - Dialog를 제외한 다른 화면 터치 x
//         barrierDismissible: false,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             // RoundedRectangleBorder - Dialog 화면 모서리 둥글게 조절
//             shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10.0)),
//             //Dialog Main Title
//             title: Column(
//               children: <Widget>[
//                 new Text(title.toString()),
//               ],
//             ),
//             //
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: <Widget>[
//                 Text(
//                   message.toString(),
//                 ),
//               ],
//             ),
//             actions: <Widget>[
//               new ElevatedButton(
//                 child: new Text("확인"),
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//               ),
//             ],
//           );
//         });
//   }
//
//   void _sendEmail() async {
//
//     String body = await _getEmailBody();
//
//     final Email email = Email(
//       body: body,
//       subject: '[뭐먹짤 관련 문의]',
//       recipients: ['tjghk7056@gmail.com'],
//       cc: [],
//       bcc: [],
//       attachmentPaths: [],
//       isHTML: false,
//     );
//
//     try {
//       await FlutterEmailSender.send(email);
//     } catch (error) {
//       String title = "기본 메일 앱을 사용할 수 없기 때문에 앱에서 바로 문의를 전송하기 어려운 상황입니다.\n\n아래 이메일로 연락주시면 친절하게 답변해드릴게요 :)\n\ntjghk7056@gmail.com";
//       String message = "";
//       _showErrorAlert(title: title, message: message);
//     }
//   }
//
//   // review
//   final InAppReview inAppReview = InAppReview.instance;
//   Future<void> _openStoreListing() => inAppReview.openStoreListing(
//     appStoreId: '6461532717',
//     // microsoftStoreId: _microsoftStoreId,
//   );
//
//   @override
//   void initState() {
//     // TODO: implement initState
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // read favorite count
//       readFavoriteCount();
//     });
//
//     super.initState();
//
//     _initPackageInfo();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent, // 추가
//       child: Scaffold(
//         body: Stack(
//           // to fast loading
//           children: [
//             // Container(
//             //   height: 0, width: 0,
//             //   child: GifView.network(widget.url_next1,),
//             // ),
//             // Container(
//             //   height: 0, width: 0,
//             //   child: GifView.network(widget.url_next2,),
//             // ),
//             // Container(
//             //   height: 0, width: 0,
//             //   child: GifView.network(widget.url_next3,),
//             // ),
//             // image
//             InkWell(
//               onDoubleTap: () {
//                 setState(() {
//                   favoriteCount += 1;
//                 });
//
//                 widget.favoriteListAdd(widget.fileName, favoriteCount);
//               },
//               child: Container(
//                 width: double.infinity,
//                 height: double.maxFinite,
//                 color: Colors.black,
//                 // child: GifView.network(
//                 //       widget.url,
//                 //       controller: controller,
//                 //       fit: BoxFit.cover,
//                 //       progress: const Center(
//                 //           child: CircularProgressIndicator(),
//                 //         ),
//                 //       ),
//                 child: VideoPlayerEatWhat(urlString: widget.url),
//               ),
//             ),
//             Column(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             Colors.black.withOpacity(0.5),
//                             Colors.black.withOpacity(0.0),
//                           ])),
//                   height: 80.0,
//                   child: Padding(
//                     padding: const EdgeInsets.fromLTRB(20.0, 20.0, 5.0, 20.0),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       children: [
//                         Text(
//                           "뭐먹짤",
//                           style: TextStyle(
//                               color: Colors.white.withOpacity(0.98),
//                               fontSize: 25,
//                               fontWeight: FontWeight.w800),
//                         ),
//                         Expanded(child: SizedBox()),
//                         // 즐겨찾기
//                         IconButton(
//                           icon: Icon(Icons.bookmarks_rounded),
//                           color: Colors.white,
//                           onPressed: () async {
//                             if (widget.favoriteListMap.length > 0) {
//                               bool isBack = await Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                       builder: (context) =>
//                                           ReelItemFavoriteBefore(
//                                             favoriteListMap:
//                                             widget.favoriteListMap,
//                                             nameUrlDataLocal:
//                                             widget.nameUrlDataLocal,
//                                             favoriteListAdd:
//                                             widget.favoriteListAdd,
//                                             favoriteListRemove:
//                                             widget.favoriteListRemove,
//                                           )));
//                               if (isBack) {
//                                 _updateFavoriteCount();
//                               }
//                             } else {
//                               print('즐겨찾기 없음');
//                               showDialog(
//                                   context: context,
//                                   builder: (BuildContext context) {
//                                     return AlertDialog(
//                                       title: const Text('즐겨찾기가 없습니다.'),
//                                       content: const Text('우측 하단 하트를 눌러 즐겨찾기를'
//                                           ' 추가하세요.'),
//                                       actions: <Widget>[
//                                         // TextButton(
//                                         //   onPressed: () => Navigator.pop(context, 'Cancel'),
//                                         //   child: const Text('Cancel'),
//                                         // ),
//                                         Center(
//                                           child: TextButton(
//                                             onPressed: () =>
//                                                 Navigator.pop(context, 'OK'),
//                                             child: const Text('OK'),
//                                           ),
//                                         ),
//                                       ],
//                                     );
//                                   });
//                             }
//                           },
//                         ),
//                         // SizedBox(width: 3.0,),
//                         // 공유
//                         IconButton(
//                           icon: Icon(Icons.ios_share),
//                           color: Colors.white,
//                           onPressed: () {
//                             print('_deleteFlutterSecureStorage(urlName)');
//                             _deleteFlutterSecureStorage('urlName');
//                             _deleteFlutterSecureStorage('favoriteList');
//                           },
//                         ),
//                         // SizedBox(width: 3.0,),
//
//                         DropdownButtonHideUnderline(
//                           child: DropdownButton2<String>(
//                             isExpanded: true,
//                             hint: const Row(
//                               children: [
//                                 Icon(
//                                   Icons.more_vert,
//                                   color: Colors.white,
//                                 ),
//                                 // SizedBox(
//                                 //   width: 4,
//                                 // ),
//                                 // Expanded(
//                                 //   child: Text(
//                                 //     'Select Item',
//                                 //     style: TextStyle(
//                                 //       fontSize: 14,
//                                 //       fontWeight: FontWeight.bold,
//                                 //       color: Colors.yellow,
//                                 //     ),
//                                 //     overflow: TextOverflow.ellipsis,
//                                 //   ),
//                                 // ),
//                               ],
//                             ),
//                             items: items
//                                 .map((String item) => DropdownMenuItem<String>(
//                               value: item,
//                               child: Text(
//                                 item,
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   // fontWeight: FontWeight.bold,
//                                   color: Colors.black,
//                                 ),
//                                 overflow: TextOverflow.visible,
//                               ),
//                             ))
//                                 .toList(),
//                             // value: selectedValue,
//                             onChanged: (String? value) {
//                               setState(() {
//                                 // selectedValue = value;
//                                 // if (value == items[0]){
//                                 //   print(value);
//                                 //   // platform 확인 후 공유
//                                 //   if (Platform.isAndroid){
//                                 //     Share.share('check out my website '
//                                 //         'https://aos_address',
//                                 //         subject: '안드로이드 주소 공ㅇ');
//                                 //   } else if (Platform.isIOS){
//                                 //     Share.share('check out my website '
//                                 //         'ios_address',
//                                 //         subject: 'ios 주소 공유');
//                                 //   }
//                                 //   // app 공유 버튼
//                                 // } else
//                                 if (value == items[0]){
//                                   print(value);
//                                   // 개선점 이메일로 보내기 버튼
//                                   // https://eunjin3786.tistory.com/332
//                                   _sendEmail();
//                                 } else if (value == items[1]){
//                                   print(value);
//                                   // 평점 주는 버튼
//                                   // https://velog.io/@adbr/flutter-Google-Play-Store-App-Store-%EB%A6%AC%EB%B7%B0-%ED%8C%9D%EC%97%85-%EB%9D%84%EC%9A%B0%EA%B8%B0
//                                   _openStoreListing();
//                                 }
//                               });
//                             },
//                             buttonStyleData: ButtonStyleData(
//                               // height: 50,
//                               width: 50,
//                               // padding:
//                               //     const EdgeInsets.only(left: 14, right: 14),
//                               // decoration: BoxDecoration(
//                               //   borderRadius: BorderRadius.circular(14),
//                               //   border: Border.all(
//                               //     color: Colors.black26,
//                               //   ),
//                               //   color: Colors.redAccent,
//                               // ),
//                               // elevation: 2,
//                             ),
//                             iconStyleData: const IconStyleData(
//                               // icon: Icon(
//                               //   Icons.arrow_forward_ios_outlined,
//                               // ),
//                               iconSize: 0,
//                               // iconEnabledColor: Colors.yellow,
//                               // iconDisabledColor: Colors.grey,
//                             ),
//                             dropdownStyleData: DropdownStyleData(
//                               maxHeight: 200,
//                               width: 130,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(14),
//                                 color: Colors.white,
//                               ),
//                               offset: const Offset(-30, 0),
//                               scrollbarTheme: ScrollbarThemeData(
//                                 radius: const Radius.circular(40),
//                                 thickness: MaterialStateProperty.all<double>(6),
//                                 thumbVisibility:
//                                 MaterialStateProperty.all<bool>(true),
//                               ),
//                             ),
//                             menuItemStyleData: const MenuItemStyleData(
//                               height: 40,
//                               padding: EdgeInsets.only(left: 14, right: 14),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Container(
//                   decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             Colors.black.withOpacity(0.0),
//                             Colors.black.withOpacity(0.5)
//                           ])),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Expanded(child: SizedBox()),
//                       Padding(
//                         padding:
//                         EdgeInsets.symmetric(horizontal: 15, vertical: 5),
//                         child: Column(
//                           children: [
//                             InkWell(
//                               onLongPress: () {
//                                 setState(() {
//                                   favoriteCount = 0;
//                                 });
//                                 // writeFavoriteCount(favoriteCount);
//                                 // if (favoriteCount==0){
//                                 widget.favoriteListRemove(widget.fileName);
//                                 // }
//                               },
//                               onTap: () {
//                                 setState(() {
//                                   favoriteCount += 1;
//                                 });
//                                 // writeFavoriteCount(favoriteCount);
//                                 // if (favoriteCount==1){
//                                 widget.favoriteListAdd(
//                                     widget.fileName, favoriteCount);
//                                 // }
//                               },
//                               child: const Icon(
//                                 Icons.favorite,
//                                 color: Colors.red,
//                               ),
//                             ),
//                             SizedBox(
//                               height: 5,
//                             ),
//                             Text(
//                               // ReelsData[index]['LikesCount'],
//                               favoriteCount.toString(),
//                               style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 14),
//                             ),
//                             SizedBox(
//                               height: 30.0,
//                             )
//                           ],
//                         ),
//                       )
//                     ],
//                   ),
//                 )
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
