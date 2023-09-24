import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../../views/video_view.dart';
import '../../class/Video_URL.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({Key? key}) : super(key: key);

  @override
  VideoScreenState createState() => VideoScreenState();
}

class Folder {
  final String name;
  final List<File> files;

  Folder(this.name, this.files);
}

class File {
  final String name;

  File(this.name);
}

Future<List<Folder>> fetchFileList() async {
  final url = Uri.parse('https://ailyproject.shop/list_video');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final lines = response.body.split('\n');
    List<Folder> folders = [];
    String? currentFolder;
    List<File> currentFiles = [];

    for (var line in lines) {
      if (line.contains(':')) {
        if (currentFolder != null) {
          folders.add(Folder(currentFolder, currentFiles));
          currentFiles = [];
        }
        currentFolder = line.replaceAll(':', '').trim();
      } else if (line.isNotEmpty) {
        final fileName = line.trim().substring(line.indexOf('.') + 1);
        currentFiles.add(File(fileName));
      }
    }

    if (currentFolder != null) {
      folders.add(Folder(currentFolder, currentFiles));
    }

    return folders;
  } else {
    throw Exception('Failed to fetch file list');
  }
}

class VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  List<Folder> fileList = [];

  @override
  void initState() {
    super.initState();
    fetchFileList().then((result) {
      setState(() {
        fileList = result;
      });
    }).catchError((error) {
      //
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshFileList() async {
    try {
      List<Folder> result = await fetchFileList();
      setState(() {
        fileList = result;
      });
    } catch (error) {
      //
    }
  }

  Future<void> _playVideo(String videoUrl) async {
    URL().videoURL = videoUrl;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const Videoview()));
  }

  @override
  Widget build(BuildContext context) {
    Color mainColor = Color(0xFF1E1E1E);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: mainColor,
        title: const Text('Stream Play', style: TextStyle(fontSize: 20, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: _refreshFileList,
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: fileList.isEmpty ?
      const Center(
        child: Text('리스트가 비었습니다.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400))) :
      ListView.builder(
        itemCount: fileList.length,
        itemBuilder: (BuildContext context, int index) {
          Folder folder = fileList[index];
          return Column(
            children: [
              Theme(
                data: ThemeData().copyWith(
                    dividerColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent
                ),
                child: ExpansionTile(
                  title: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(folder.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400))
                  ),
                  textColor: Colors.grey,
                  iconColor: Colors.grey.shade600,
                  children: folder.files.expand((File file) {
                    return [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 35),
                        leading: const Icon(Icons.movie,
                          size: 30,
                          color: Colors.black54,
                        ),
                        title: Text(file.name),
                        onTap: () {
                          String videoUrl = '${URL().baseURL}/${folder.name}/${file.name}';
                          URL().foldername = folder.name;
                          int extensionIndex = file.name.lastIndexOf('.');
                          String pureName = file.name.substring(0, extensionIndex);
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
      ),
    );
  }
}

