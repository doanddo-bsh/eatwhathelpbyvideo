import 'package:firebase_storage/firebase_storage.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../model/firebase_file.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';

class FirebaseApi {

  static Future<List<String>> _getDownloadLinks(List<Reference> refs) =>
    Future.wait(refs.map((ref) => ref.getDownloadURL()).toList());

  static Future<List<FirebaseFile>> listAll(String path) async {
    final ref = FirebaseStorage.instance.ref(path);
    final result = await ref.listAll();

    final urls = await _getDownloadLinks(result.items);

    return urls
        .asMap()
        .map((index, url) {
          final ref = result.items[index];
          final name = ref.name;
          final file = FirebaseFile(ref:ref, name:name, url:url);

          return MapEntry(index, file);

         })
        .values
        .toList();
  }

  // static Future downloadFile(Reference ref) async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   final file = File('${dir.path}/${ref.name}');
  //
  //   print('try downloadFile work');
  //   try {
  //     print('try downloadFile work!!');
  //     await FirebaseStorage.instance
  //         .ref('version_002/${ref.name}')
  //         .writeToFile(file);
  //     print('try downloadFile work done');
  //   } on FirebaseException catch (e) {
  //     print('exception occur!!');
  //     print(e.code);
  //     // e.g, e.code == 'canceled'
  //   }
  //
  //   // await ref.writeToFile(file);
  // }

  // try3
  static Future downloadFile(Reference ref) async {

    // Create a storage reference from our app
    print('downloadFile work');
    // final storageRef = FirebaseStorage.instance.ref();
    //
    // final Reference islandRef = storageRef.child("version_002/korea_ramen_1.mp4");
    final url = await ref.getDownloadURL();

    // get to gallery
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/${ref.name}';

    await Dio().download(url, path);
    print('dio work');

    if (url.contains('.mp4')){
      await GallerySaver.saveVideo(path, toDcim:true);
      print(' GallerySaver.saveVideo work');
      print(path);
    } else if (url.contains('.jpg')){
      await GallerySaver.saveImage(path, toDcim:true);
      print(' GallerySaver.saveImage work');
      print(path);
    }


  }

  // static Future downloadFile(Reference ref) async {
  // static Future downloadFile() async {
  //
  //   final Reference ref =
  //       FirebaseStorage.instance
  //       .ref('panduan/Pedoman_pemantauan.pdf');
  //   // Create a storage reference from our app
  //   final storageRef = FirebaseStorage.instance.ref();
  //
  //   // final islandRef = storageRef.child('version_002/${ref.name}');
  //   final islandRef = storageRef.child('version_002/korea_ramen_1.mp4');
  //   // gs://eatwhathelpbyvideo.appspot.com/version_002/korea_ramen_1.mp4
  //
  //   final dir = await getApplicationDocumentsDirectory();
  //   final filePath = "${dir.absolute.path}/images/island.jpg";
  //   // final filePath = "${dir.absolute.path}/images/${ref.name}";
  //   final file = File(filePath);
  //   // gs://eatwhathelpbyvideo.appspot.com/version_002/korea_ramen_1.mp4
  //   // final downloadTask = await FirebaseStorage.instance.ref('version_002/${ref.name}').writeToFile(file);
  //   final downloadTask = islandRef.writeToFile(file);
  //   downloadTask.snapshotEvents.listen((taskSnapshot) {
  //     switch (taskSnapshot.state) {
  //       case TaskState.running:
  //       // TODO: Handle this case.
  //         print('TaskState.running');
  //         print('${islandRef.fullPath}');
  //         break;
  //       case TaskState.paused:
  //       // TODO: Handle this case.
  //         print('TaskState.paused');
  //         break;
  //       case TaskState.success:
  //       // TODO: Handle this case.
  //         print('TaskState.success');
  //         break;
  //       case TaskState.canceled:
  //       // TODO: Handle this case.
  //         print('TaskState.canceled');
  //         break;
  //       case TaskState.error:
  //       // TODO: Handle this case.
  //         print('TaskState.error');
  //         break;
  //     }
  //   });
  //
  // }

  // final islandRef = storageRef.child("images/island.jpg");
  // final file = File(filePath);
  //
  // final downloadTask = islandRef.writeToFile(file);
  // downloadTask.snapshotEvents.listen((taskSnapshot) {
  // switch (taskSnapshot.state) {
  // case TaskState.running:
  // // TODO: Handle this case.
  // break;
  // case TaskState.paused:
  // // TODO: Handle this case.
  // break;
  // case TaskState.success:
  // // TODO: Handle this case.
  // break;
  // case TaskState.canceled:
  // // TODO: Handle this case.
  // break;
  // case TaskState.error:
  // // TODO: Handle this case.
  // break;
  // }
  // });

}