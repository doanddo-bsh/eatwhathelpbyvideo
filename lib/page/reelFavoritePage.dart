import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReelItemFavoriteBefore extends StatelessWidget {
  const ReelItemFavoriteBefore({
    required this.favoriteList,
    required this.nameUrlDataLocal,
    required this.favoriteListAdd,
    required this.favoriteListRemove,
    Key? key,
  }) : super(key: key);
  final List<String> favoriteList;
  final Map<String, dynamic> nameUrlDataLocal;
  final favoriteListAdd;
  final favoriteListRemove;

  static final storage = new FlutterSecureStorage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child:
        PageView.builder(
            itemCount: favoriteList.length,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index)
            {
              String url = nameUrlDataLocal[favoriteList[index]].toString();
              String fileName = favoriteList[index];

              print(url);
              print('file name ${favoriteList[index]}');
              print(index);

              // int favoriteCount = 0 ;

              final storage = new FlutterSecureStorage();
              // storage read

              return ReelItemFavoriteAfter(
                  index:index,
                  fileName:fileName,
                  url:url,
                  favoriteListAdd:favoriteListAdd,
                  favoriteListRemove:favoriteListRemove,
              );
            }
        )
    );
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

  void readFavoriteCount() async {
    print('readFavoriteCount work');
    print('$favoriteCount before');
    String? favoriteCountString = await storage.read(key: widget.fileName);
    if (favoriteCountString == null){
      print('favoriteCountString is null');
    } else {
      setState(() {
        favoriteCount = int.parse(favoriteCountString);
      });
    }
    print('readFavoriteCount done');
    print('$favoriteCount after');

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
              onTap: () {
                setState(() {
                  favoriteCount += 1;
                });
                writeFavoriteCount(favoriteCount);
                if (favoriteCount == 1) {
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
                                writeFavoriteCount(favoriteCount);
                                if (favoriteCount == 0) {
                                  widget.favoriteListRemove(
                                      widget.fileName);
                                }
                              },
                              onTap: () {
                                setState(() {
                                  favoriteCount += 1;
                                });
                                writeFavoriteCount(favoriteCount);
                                if (favoriteCount == 1) {
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
