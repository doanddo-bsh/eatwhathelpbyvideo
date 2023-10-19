import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'videoPage.dart';
import 'dart:collection';
import 'dart:convert';


class ReelItemFavoriteBefore extends StatefulWidget {
  ReelItemFavoriteBefore({
    required this.favoriteListMap,
    required this.favoriteListAdd,
    required this.favoriteListRemove,
    required this.nameUrlMap,
    Key? key,
  }) : super(key: key);
  final Map<String,dynamic> favoriteListMap;
  final favoriteListAdd;
  final favoriteListRemove;
  final Map<dynamic,dynamic> nameUrlMap;

  static final storage = new FlutterSecureStorage();

  @override
  State<ReelItemFavoriteBefore> createState() => _ReelItemFavoriteBeforeState();
}

class _ReelItemFavoriteBeforeState extends State<ReelItemFavoriteBefore> {

  int favoriteListFixCount = 0;
  Map<String,dynamic> favoriteListFix = {};
  bool favoriteListFixLoad = false;
  // 처음 가지고온 favoriteList 을 고정해놓기

  Widget favoriteAddDone(){

    if (favoriteListFixLoad){

      print('favoriteListFixLoad is true work here');
      print('favoriteListFix.length, ${favoriteListFix.length}');
      print('favoriteList22 ${widget.favoriteListMap}');
      print('favoriteListFix22 $favoriteListFix');

      return SafeArea(
          child:
          PageView.builder(
            // itemCount: favoriteList.length,
              itemCount: favoriteListFix.length,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index)
              {
                // sort by value
                var sortedKeys = favoriteListFix.keys.toList(growable:false)
                  ..sort((k1, k2) => favoriteListFix[k2].compareTo
                    (favoriteListFix[k1]));
                LinkedHashMap sortedMap = new LinkedHashMap
                    .fromIterable(sortedKeys, key: (k) => k, value: (k) => favoriteListFix[k]);

                List<dynamic> favoriteListFixSort = sortedMap.keys.toList();
                // String fileName = favoriteList[index];
                String fileName = favoriteListFixSort[index].toString();
                String url = widget.nameUrlMap[fileName];

                return ReelItemFavoriteAfter(
                  index:index,
                  fileName:fileName,
                  url:url,
                  favoriteListAdd:widget.favoriteListAdd,
                  favoriteListRemove:widget.favoriteListRemove,
                );
              }
          )
      );
    } else {
      print('favoriteListFixLoad is false work here');
      return SafeArea(
        child: Center(
            child: CircularProgressIndicator()
        ),
      );
    }
  }

  @override
  void initState() {

    print('initState 실행');

    // favoriteListFix = widget.favoriteList;
    // to avoid hashCode same
    favoriteListFix.addAll(widget.favoriteListMap);
    favoriteListFixLoad = true;
    // TODO: implement initState

    print('favoriteListFix id      : ${favoriteListFix.hashCode}');
    print('widget.favoriteList id : ${widget.favoriteListMap.hashCode}');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return favoriteAddDone();
  }
}





class ReelItemFavoriteAfter extends StatefulWidget {
  const ReelItemFavoriteAfter({
    required this.index,
    required this.url,
    required this.fileName,
    required this.favoriteListAdd,
    required this.favoriteListRemove,
    Key? key,
  }) : super(key: key);
  final int index;
  final String url;
  final String fileName;
  final favoriteListAdd;
  final favoriteListRemove;

  @override
  State<ReelItemFavoriteAfter> createState() => ReelItemFavoriteAfterState();
}

class ReelItemFavoriteAfterState extends State<ReelItemFavoriteAfter> {

  static final storage = new FlutterSecureStorage();

  int favoriteCount = 0 ;

  // void readFavoriteCount() async {
  //
  //   String? favoriteCountString = await storage.read(key: widget.fileName);
  //   if (favoriteCountString == null){
  //     print('favoriteCountString is null');
  //   } else {
  //     setState(() {
  //       favoriteCount = int.parse(favoriteCountString);
  //     });
  //   }
  // }

  Map<dynamic, dynamic> favoriteListMap = {};

  void readFavoriteCount() async {
    String? favoriteListString = await storage.read(key: 'favoriteListMap');
    if (favoriteListString == null){
      print('favoriteListMap is null');
    } else {
      favoriteListMap = json.decode(favoriteListString);
    }

    {
      setState(() {
        favoriteCount = favoriteListMap[widget.fileName]!;
      });
    }
    // String? favoriteCountString = await storage.read(key: widget.fileName);
    // if (favoriteCountString == null){
    //   print('favoriteCountString is null');
    // } else {
    //   setState(() {
    //     favoriteCount = int.parse(favoriteCountString);
    //   });
    // }
  }

  // 삭제 버튼 임시 사용 test 목적
  void _deleteFlutterSecureStorage(String key) async {
    await ReelItemFavoriteBefore.storage.delete(key: key);
  }

  // storage write
  void writeFavoriteCount(int favoriteCount) async {
    await storage.write(
      key: widget.fileName,
      value: favoriteCount.toString(),
    );
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
              onDoubleTap: (){
                setState(() {
                  favoriteCount += 1;
                });
                // writeFavoriteCount(favoriteCount);
                // if (favoriteCount==1){
                widget.favoriteListAdd(widget.fileName, favoriteCount);
                // }
              },
              child: Container(
                width: double.infinity,
                height: double.maxFinite,
                color: Colors.black,
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
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "즐겨찾기",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.98),
                              fontSize: 25,
                              fontWeight: FontWeight.w800),
                        ),
                        Expanded(child: SizedBox()),
                        // go home
                        IconButton(
                          icon: Icon(Icons.home),
                          color: Colors.white,
                          onPressed: () {
                            Navigator.pop(context, true);
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
                              onLongPress: () {
                                setState(() {
                                  favoriteCount = 0;
                                });
                                // writeFavoriteCount(favoriteCount);
                                // if (favoriteCount == 0) {
                                widget.favoriteListRemove(
                                    widget.fileName);
                                // }
                              },
                              onTap: () {
                                setState(() {
                                  favoriteCount += 1;
                                });
                                // writeFavoriteCount(favoriteCount);
                                // if (favoriteCount == 1) {
                                widget.favoriteListAdd(widget.fileName, favoriteCount);
                                // }
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
