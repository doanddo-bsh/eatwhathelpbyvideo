import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerEatWhat extends StatefulWidget {
  VideoPlayerEatWhat({
    required this.urlString,
    Key? key}) : super(key: key);
  final String urlString;

  @override
  State<VideoPlayerEatWhat> createState() => VideoPlayerEatWhatState();
}

class VideoPlayerEatWhatState extends State<VideoPlayerEatWhat> {
  late VideoPlayerController controller;
  // Uri videoUrl =
  //     Uri.parse(urlString);

  @override
  void initState() {
    super.initState();

    print(widget.urlString);

    Uri videoUrl = Uri.parse(widget.urlString);
    // VideoPlayerController.networkUrl(url)
    controller = VideoPlayerController.networkUrl(videoUrl);

    controller.addListener(() {
      setState(() {});
    });
    controller.setLooping(true);
    controller.initialize().then((_) => setState(() {}));
    controller.play();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: InkWell(
          onTap: () {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          },
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: Container(
                width: controller.value.size?.width ?? 0,
                height: controller.value.size?.height ?? 0,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          // child: Container(
          //   child: AspectRatio(
          //     aspectRatio: 16 / 9,
          //     child: VideoPlayer(
          //         controller
          //     ),
          //   ),
          // ),
        ),
      ),
    );
  }
}