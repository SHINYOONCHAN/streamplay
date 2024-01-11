import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../class/file.dart';
import '../../controller/item_controller.dart';
import '../../class/Video_URL.dart';
import '../../views/video_view.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({Key? key}) : super(key: key);

  @override
  FolderScreenState createState() => FolderScreenState();
}

class FolderScreenState extends State<FolderScreen> {
  late VideoPlayerController _controller;
  final FavoriteController favoriteController = Get.find();
  var category = Get.arguments;
  List<Folder> fileList = [];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(''))
      ..initialize().then((_) {
        setState(() {});
      });
    fileList = favoriteController.fileList;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playVideo(String videoUrl) async {
    URL().videoURL = videoUrl;
    Get.to(const Videoview(), arguments: category);
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = Color(0xFFD74848);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: mainColor,
        title: const Text(
          'Stream Play',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: fileList.isEmpty
          ? const Center(
              child: Text(
                '리스트가 비었습니다.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
            )
          : Obx(() => ListView.builder(
                itemCount: fileList.length,
                itemBuilder: (BuildContext context, int index) {
                  Folder folder = fileList[index];
                  return Column(
                    children: [
                      Theme(
                        data: ThemeData().copyWith(
                          dividerColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          title: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              folder.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          textColor: Colors.grey,
                          iconColor: Colors.grey.shade600,
                          children: folder.files.expand((File file) {
                            return [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 35,
                                ),
                                leading: const Icon(
                                  Icons.movie,
                                  size: 30,
                                  color: Colors.black54,
                                ),
                                title: Text(file.name),
                                onTap: () {
                                  String videoUrl =
                                      '${URL().baseURL}/static/video/${category}/${folder.name}/${file.name}';
                                  URL().foldername = folder.name;
                                  int extensionIndex =
                                      file.name.lastIndexOf('.');
                                  String pureName =
                                      file.name.substring(0, extensionIndex);
                                  URL().filename = pureName;
                                  _playVideo(videoUrl);
                                },
                              ),
                              Container(
                                height: 0.5,
                                width: MediaQuery.of(context).size.width * 0.87,
                                color: Colors.grey.shade400,
                              ),
                            ];
                          }).toList(),
                        ),
                      ),
                      Container(
                        height: 0.5,
                        width: MediaQuery.of(context).size.width * 0.87,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  );
                },
              )),
    );
  }
}
