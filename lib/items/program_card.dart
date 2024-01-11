import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:streamplay/class/video_url.dart';
import 'package:streamplay/screens/folder_screen/folder_screen.dart';
import '../class/file.dart';
import '../controller/item_controller.dart';

class CategoryCard extends StatefulWidget {
  final String imageUrl;
  final String programTitle;

  const CategoryCard({
    super.key,
    required this.imageUrl,
    required this.programTitle,
  });

  @override
  FavoritePageState createState() => FavoritePageState();
}

class FavoritePageState extends State<CategoryCard> {
  final FavoriteController favoriteController = Get.put(FavoriteController());
  Dio dio = Dio();

  Future<void> fetchDataAndNavigate() async {
    try {
      final fileList = await fetchFileList();
      favoriteController.setFileList(fileList);
      Get.to(FolderScreen(), arguments: widget.programTitle);
    } catch (e) {
      // 오류 처리
      print('Failed to fetch file list: $e');
    }
  }

  Future<List<Folder>> fetchFileList() async {
    final response = await dio.post(
      '${URL().baseURL}/list_video',
      data: {
        'category': widget.programTitle,
      },
    );
    if (response.statusCode == 200) {
      final lines = response.data.toString().split('\n');
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        fetchDataAndNavigate();
      },
      child: Column(
        children: [
          SizedBox(
            width: mq.width * .25,
            height: mq.width * .25,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.asset(
                  widget.imageUrl,
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.programTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xff111111),
            ),
          ),
        ],
      ),
    );
  }
}
