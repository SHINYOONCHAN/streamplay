import 'dart:convert';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../class/Video_URL.dart';
import '../class/custom_chewie_controller.dart';

class Videoview extends StatefulWidget {
  const Videoview({Key? key}) : super(key: key);

  @override
  VideoviewState createState() => VideoviewState();
}

class VideoviewState extends State<Videoview> {
  late VideoPlayerController videoPlayerController;
  ChewieController? chewieController;
  Future<void>? initializeVideoPlayerFuture;
  final dio = Dio();

  @override
  void initState() {
    super.initState();
    initializeVideoPlayer();
  }

  @override
  void dispose() {
    videoPlayerController.dispose();
    chewieController?.dispose();
    super.dispose();
  }

  List<Subtitle> parseSubtitles(String subtitleContent) {
    final lines = subtitleContent.trim().split('\n');
    final subtitles = <Subtitle>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty && line.contains('-->')) {
        final parts = line.split('-->');
        final startTime = parseSubtitleTime(parts[0].trim());
        final endTime = parseSubtitleTime(parts[1].trim());

        final textLines = <String>[];
        int j = i + 1;
        while (j < lines.length && lines[j].trim().isNotEmpty) {
          textLines.add(lines[j].trim());
          j++;
        }
        final text = textLines.join('\n');

        subtitles.add(
            Subtitle(index: i, start: startTime, end: endTime, text: text));
      }
    }
    return subtitles;
  }

  Duration parseSubtitleTime(String time) {
    final timeParts = time.split(':');
    final hours = int.parse(timeParts[0]);
    final minutes = int.parse(timeParts[1]);
    final seconds = double.parse(timeParts[2].replaceAll(',', '.'));

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds.toInt(),
    );
  }

  Future<void> initializeVideoPlayer() async {
    videoPlayerController = VideoPlayerController.network(URL().videoURL);

    initializeVideoPlayerFuture = videoPlayerController.initialize();
    await initializeVideoPlayerFuture;
    final subtitleResponse = await dio
        .get('${URL().baseURL}/${URL().foldername}/${URL().filename}.srt');
    final subtitleContent = utf8.decode(subtitleResponse.data);
    final subtitles = parseSubtitles(subtitleContent);
    setState(() {
      chewieController = ChewieController(
        videoPlayerController: videoPlayerController,
        autoPlay: true,
        looping: false,
        subtitle: Subtitles(subtitles),
        subtitleBuilder: (context, subtitle) => Container(
          padding: const EdgeInsets.all(20.0),
          alignment: Alignment.center,
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center, // 가운데 정렬
          ),
        ),
        customControls: const CustomCupertinoControls(
          backgroundColor: Colors.transparent,
          iconColor: Colors.white,
          showPlayButton: true,
        ),
      );
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: chewieController != null &&
                chewieController!.videoPlayerController.value.isInitialized
            ? Chewie(
                controller: chewieController!,
              )
            : FutureBuilder<void>(
                future: initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.black),
                        SizedBox(height: 8),
                        Text('로딩중')
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return const Text('Error');
                  } else {
                    return const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text('로딩중'),
                      ],
                    );
                  }
                },
              ),
      ),
    );
  }
}
