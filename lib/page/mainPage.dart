import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../component/auth.dart';
import 'reelFavoritePage.dart';
// import 'package:gif_view/gif_view.dart';
import 'videoPage.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_review/in_app_review.dart';
import '../model/firebase_file.dart';
import '../api/firebase_api.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// TickerProviderStateMixin for gif play
class _MyHomePageState extends State<MyHomePage> {
  // 익명 로그임
  final AuthService _auth = AuthService();

  // favoriteList 변경 후
  Map<String, dynamic> favoriteListMap = {};
  static final storage = new FlutterSecureStorage();

  // favorite list update
  void _favoriteListAdd(String gifName, int favoriteCount) async {
    favoriteListMap[gifName] = favoriteCount;

    String favoriteListString = json.encode(favoriteListMap);

    await storage.write(
      key: 'favoriteListMap',
      value: favoriteListString,
    );
    print('_favoriteListAdd $favoriteListMap');
  }

  void _favoriteListRemove(String gifName) async {
    // setState(() {
    favoriteListMap.remove(gifName);
    // });

    String favoriteListString = json.encode(favoriteListMap);

    await storage.write(
      key: 'favoriteListMap',
      value: favoriteListString,
    );
    print('_favoriteListRemove $favoriteListMap');
  }

  void _favoriteRead() async {
    String? favoriteListString = await storage.read(key: 'favoriteListMap');
    if (favoriteListString == null) {
    } else {
      setState(() {
        favoriteListMap = json.decode(favoriteListString);
        favoriteListMap.remove(''); // 혹시 모를 ''이 key로 들어갈 경우를 방지
      });
    }
    print('_favoriteRead $favoriteListMap');
  }

  late Future<List<FirebaseFile>> futureFiles ;
  late Future<User?> futureAuth ;

  @override
  void initState() {
    // initState 내 비동기 활용하기 위해여 필요함 WidgetsBinding.instance.addPostFrameCallback
    // call url from local
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // futureAuth = _auth.signInAnon();
      // futureFiles = ;
      _favoriteRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _auth.signInAnon(),
      builder: (context, snapshot) {
        if (snapshot.hasData == false){
          print('FutureBuilder (snapshot.hasData == false)');
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.connectionState ==  ConnectionState.waiting){
          print('FutureBuilder (snapshot.connectionState ==  ConnectionState.waiting)');
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.data == null){
          print('FutureBuilder (snapshot.data == null)');
          return Center(child: CircularProgressIndicator());
        } else {
          print('FutureBuilder else');
          return FutureBuilder<List<FirebaseFile>>(
              future: FirebaseApi.listAll('version_002/'),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return Center(child: CircularProgressIndicator());
                  default:
                    if (snapshot.hasError) {
                      return Center(child: Text('some error occurred! at futureFiles'));
                    } else {
                      final files = snapshot.data!;
                      final nameUrlMap =
                      Map.fromIterable(files,
                          key: (v) => v.name,
                          value: (v) => v.url
                      );
                      return SafeArea(child:
                      PageView.builder(
                          scrollDirection: Axis.vertical,
                          // itemCount:files.length,
                          itemBuilder: (context, index) {

                            index = index % files.length;
                            if (index == 0){
                              print('shuffle work');
                              files.shuffle();
                            }

                            return ReelItem(
                              index: index,
                              url: files[index].url,
                              fileName: files[index].name,
                              ref : files[index].ref,
                              favoriteListAdd: _favoriteListAdd,
                              favoriteListRemove: _favoriteListRemove,
                              favoriteListMap: favoriteListMap,
                              nameUrlMap:nameUrlMap,
                            );
                          }
                      )
                      );
                    }
                }
              }
          );
        }
      }
    );
  }
}


class ReelItem extends StatefulWidget {
  ReelItem({
    required this.index,
    required this.url,
    required this.fileName,
    required this.ref,
    required this.favoriteListAdd,
    required this.favoriteListRemove,
    required this.favoriteListMap,
    required this.nameUrlMap,
    Key? key,
  }) : super(key: key);
  final int index;
  final String url;
  final String fileName;
  final ref;
  final favoriteListAdd;
  final favoriteListRemove;
  final Map<String, dynamic> favoriteListMap;
  final Map<dynamic,dynamic> nameUrlMap;

  static final storage = new FlutterSecureStorage();

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  // to dropdownbutton
  final List<String> items = [
    // 어플 공유 버튼은 향후 업데이트
    // '어플 공유하기',
    '개선점 보내기',
    '평점 주기',
  ];
  // String? selectedValue;

  // final controller = GifController();

  // 삭제 버튼 임시 사용 test 목적
  void _deleteFlutterSecureStorage(String key) async {
    await ReelItem.storage.delete(key: key);
  }

  int favoriteCount = 0;

  static final storage = new FlutterSecureStorage();

  // storage read
  void readFavoriteCount() async {
    String? favoriteListString = await storage.read(key: 'favoriteListMap');
    if (favoriteListString == null) {
      print('favoriteListMap is null');
    } else if (widget.favoriteListMap[widget.fileName] == null) {
      print('widget.favoriteListMap[widget.fileName] is null');
    } else {
      setState(() {
        favoriteCount = widget.favoriteListMap[widget.fileName]!;
        // favoriteCount = int.parse(favoriteCountString);
      });
    }
  }

  // email 관련 정보
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  void _updateFavoriteCount() {
    readFavoriteCount();
  }

  Future<String> _getEmailBody() async {
    // Map<String, dynamic> userInfo = _getUserInfo();
    // Map<String, dynamic> appInfo = await _getAppInfo();
    // Map<String, dynamic> deviceInfo = await _getDeviceInfo();

    String body = "";

    body += "\n";
    body += "\n";
    body += "==============\n";
    body += "아래 내용을 함께 보내주시면 큰 도움이 됩니다 🧅\n";

    // userInfo.forEach((key, value) {
    //   body += "$key: $value\n";
    // });

    body += "App name, ${_packageInfo.appName}\n";
    body += "Package name, ${_packageInfo.packageName}\n";
    body += "App version, ${_packageInfo.version}\n";
    body += "Build number, ${_packageInfo.buildNumber}\n";
    body += "Build signature, ${_packageInfo.buildSignature}\n";
    body += "Installer store, ${_packageInfo.installerStore ?? 'not available'}\n";

    body += "==============\n";

    return body;
  }

  void _showErrorAlert({String? title, String? message}) {
    showDialog(
        context: context,
        //barrierDismissible - Dialog를 제외한 다른 화면 터치 x
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            // RoundedRectangleBorder - Dialog 화면 모서리 둥글게 조절
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            //Dialog Main Title
            title: Column(
              children: <Widget>[
                new Text(title.toString()),
              ],
            ),
            //
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.toString(),
                ),
              ],
            ),
            actions: <Widget>[
              new ElevatedButton(
                child: new Text("확인"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        });
  }

  void _sendEmail() async {

    String body = await _getEmailBody();

    final Email email = Email(
      body: body,
      subject: '[뭐먹짤 관련 문의]',
      recipients: ['tjghk7056@gmail.com'],
      cc: [],
      bcc: [],
      attachmentPaths: [],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
    } catch (error) {
      String title = "기본 메일 앱을 사용할 수 없기 때문에 앱에서 바로 문의를 전송하기 어려운 상황입니다.\n\n아래 이메일로 연락주시면 친절하게 답변해드릴게요 :)\n\ntjghk7056@gmail.com";
      String message = "";
      _showErrorAlert(title: title, message: message);
    }
  }

  // review
  final InAppReview inAppReview = InAppReview.instance;
  Future<void> _openStoreListing() => inAppReview.openStoreListing(
    appStoreId: '6461532717',
    // microsoftStoreId: _microsoftStoreId,
  );

  @override
  void initState() {
    // TODO: implement initState

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // read favorite count
      readFavoriteCount();
    });

    super.initState();

    _initPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // 추가
      child: Scaffold(
        body: Stack(
          // to fast loading
          children: [
            // Container(
            //   height: 0, width: 0,
            //   child: GifView.network(widget.url_next1,),
            // ),
            // Container(
            //   height: 0, width: 0,
            //   child: GifView.network(widget.url_next2,),
            // ),
            // Container(
            //   height: 0, width: 0,
            //   child: GifView.network(widget.url_next3,),
            // ),
            // image
            InkWell(
              onDoubleTap: () {
                setState(() {
                  favoriteCount += 1;
                });

                widget.favoriteListAdd(widget.fileName, favoriteCount);
              },
              child: Container(
                width: double.infinity,
                height: double.maxFinite,
                color: Colors.black,
                // child: GifView.network(
                //       widget.url,
                //       controller: controller,
                //       fit: BoxFit.cover,
                //       progress: const Center(
                //           child: CircularProgressIndicator(),
                //         ),
                //       ),
                child: VideoPlayerEatWhat(urlString: widget.url),
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 5.0, 20.0),
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
                          icon: Icon(Icons.bookmarks_rounded),
                          color: Colors.white,
                          onPressed: () async {
                            if (widget.favoriteListMap.length > 0) {
                              bool isBack = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ReelItemFavoriteBefore(
                                            favoriteListMap:
                                                widget.favoriteListMap,
                                            favoriteListAdd:
                                                widget.favoriteListAdd,
                                            favoriteListRemove:
                                                widget.favoriteListRemove,
                                            nameUrlMap:widget.nameUrlMap,
                                          )));
                              if (isBack) {
                                _updateFavoriteCount();
                              }
                            } else {
                              print('즐겨찾기 없음');
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('즐겨찾기가 없습니다.'),
                                      content: const Text('우측 하단 하트를 눌러 즐겨찾기를'
                                          ' 추가하세요.'),
                                      actions: <Widget>[
                                        // TextButton(
                                        //   onPressed: () => Navigator.pop(context, 'Cancel'),
                                        //   child: const Text('Cancel'),
                                        // ),
                                        Center(
                                          child: TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, 'OK'),
                                            child: const Text('OK'),
                                          ),
                                        ),
                                      ],
                                    );
                                  });
                            }
                          },
                        ),
                        // SizedBox(width: 3.0,),
                        // 공유
                        IconButton(
                          icon: Icon(Icons.ios_share),
                          color: Colors.white,
                          onPressed: () async {
                            await FirebaseApi.downloadFile(widget.ref);

                            final snackBar = SnackBar(
                                content: Text('Downloaded ${widget.fileName}'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          },
                        ),
                        // SizedBox(width: 3.0,),

                        DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            hint: const Row(
                              children: [
                                Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                // SizedBox(
                                //   width: 4,
                                // ),
                                // Expanded(
                                //   child: Text(
                                //     'Select Item',
                                //     style: TextStyle(
                                //       fontSize: 14,
                                //       fontWeight: FontWeight.bold,
                                //       color: Colors.yellow,
                                //     ),
                                //     overflow: TextOverflow.ellipsis,
                                //   ),
                                // ),
                              ],
                            ),
                            items: items
                                .map((String item) => DropdownMenuItem<String>(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          // fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ))
                                .toList(),
                            // value: selectedValue,
                            onChanged: (String? value) {
                              setState(() {
                                // selectedValue = value;
                                // if (value == items[0]){
                                //   print(value);
                                //   // platform 확인 후 공유
                                //   if (Platform.isAndroid){
                                //     Share.share('check out my website '
                                //         'https://aos_address',
                                //         subject: '안드로이드 주소 공ㅇ');
                                //   } else if (Platform.isIOS){
                                //     Share.share('check out my website '
                                //         'ios_address',
                                //         subject: 'ios 주소 공유');
                                //   }
                                //   // app 공유 버튼
                                // } else
                                if (value == items[0]){
                                  print(value);
                                  // 개선점 이메일로 보내기 버튼
                                  // https://eunjin3786.tistory.com/332
                                  _sendEmail();
                                } else if (value == items[1]){
                                  print(value);
                                  // 평점 주는 버튼
                                  // https://velog.io/@adbr/flutter-Google-Play-Store-App-Store-%EB%A6%AC%EB%B7%B0-%ED%8C%9D%EC%97%85-%EB%9D%84%EC%9A%B0%EA%B8%B0
                                  _openStoreListing();
                                }
                              });
                            },
                            buttonStyleData: ButtonStyleData(
                              // height: 50,
                              width: 50,
                              // padding:
                              //     const EdgeInsets.only(left: 14, right: 14),
                              // decoration: BoxDecoration(
                              //   borderRadius: BorderRadius.circular(14),
                              //   border: Border.all(
                              //     color: Colors.black26,
                              //   ),
                              //   color: Colors.redAccent,
                              // ),
                              // elevation: 2,
                            ),
                            iconStyleData: const IconStyleData(
                              // icon: Icon(
                              //   Icons.arrow_forward_ios_outlined,
                              // ),
                              iconSize: 0,
                              // iconEnabledColor: Colors.yellow,
                              // iconDisabledColor: Colors.grey,
                            ),
                            dropdownStyleData: DropdownStyleData(
                              maxHeight: 200,
                              width: 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.white,
                              ),
                              offset: const Offset(-30, 0),
                              scrollbarTheme: ScrollbarThemeData(
                                radius: const Radius.circular(40),
                                thickness: MaterialStateProperty.all<double>(6),
                                thumbVisibility:
                                    MaterialStateProperty.all<bool>(true),
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 40,
                              padding: EdgeInsets.only(left: 14, right: 14),
                            ),
                          ),
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
                        Colors.black.withOpacity(0.5),
                      ])),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: SizedBox()),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: InkWell(
                          onLongPress: () {
                            setState(() {
                              favoriteCount = 0;
                            });
                            // writeFavoriteCount(favoriteCount);
                            // if (favoriteCount==0){
                            widget.favoriteListRemove(widget.fileName);
                            // }
                          },
                          onTap: () {
                            setState(() {
                              favoriteCount += 1;
                            });
                            // writeFavoriteCount(favoriteCount);
                            // if (favoriteCount==1){
                            widget.favoriteListAdd(
                                widget.fileName, favoriteCount);
                            // }
                          },
                          child: Container(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.red,
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
                                SizedBox(
                                  height: 30.0,
                                ),
                              ],
                            ),
                          ),
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
