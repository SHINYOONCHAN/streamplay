import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import '../../class/file.dart';
import '../../items/program_card.dart';
import '../../items/recent_card.dart';
import '../../views/video_view.dart';
import '../../class/Video_URL.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  VideoScreenState createState() => VideoScreenState();
}

class VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  Dio dio = Dio();
  List<Folder> fileList = [];

  @override
  void initState() {
    super.initState();
    // fetchFileList().then((result) {
    //   setState(() {
    //     fileList = result;
    //   });
    // }).catchError((error) {
    //   //
    // });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Future<void> _refreshFileList() async {
  //   try {
  //     List<Folder> result = await fetchFileList();
  //     setState(() {
  //       fileList = result;
  //     });
  //   } catch (error) {
  //     //
  //   }
  // }

  Future<void> _playVideo(String videoUrl) async {
    URL().videoURL = videoUrl;
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Videoview()));
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    Color mainColor = Color(0xFFD74848);
    Color blackColor = Color(0xFF111111);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: mainColor,
        title: const Text('Stream Play',
            style: TextStyle(fontSize: 20, color: Colors.white)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              color: Colors.white,
              onPressed: () {} //_refreshFileList,
              ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CategoryCard(
                        imageUrl: 'assets/images/드라마.png', programTitle: '드라마'),
                    CategoryCard(
                        imageUrl: 'assets/images/영화.png', programTitle: '영화'),
                    CategoryCard(
                        imageUrl: 'assets/images/예능.png', programTitle: '예능'),
                  ],
                ),
                SizedBox(height: 18),
                CategoryCard(
                    imageUrl: 'assets/images/애니.png', programTitle: '애니'),
                SizedBox(height: 26),
                Text(
                  '최근에 본 영상',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: blackColor),
                ),
                SizedBox(height: 12),
              ],
            ),
            Column(children: [
              SizedBox(
                width: mq.width,
                height: mq.height * .35,
                child: ListView.builder(
                  itemCount: 3,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    List<String> contentTitles = [
                      '이재 곧, 죽습니다',
                      '경성크리처',
                      '스위트홈 시즌2'
                    ];
                    List<String> imagePaths = [
                      'assets/images/이재.png',
                      'assets/images/경성.png',
                      'assets/images/스위트홈.png',
                    ];

                    return Row(
                      children: [
                        RecentCard(
                            imageUrl: imagePaths[index],
                            programTitle: contentTitles[index]),
                        SizedBox(width: 8),
                      ],
                    );
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
