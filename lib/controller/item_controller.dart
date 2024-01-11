import 'package:get/get.dart';
import '../class/file.dart';

class FavoriteController extends GetxController {
  RxList<String> favorites = <String>[].obs;
  RxList<Folder> fileList = <Folder>[].obs; // 파일 목록을 저장하는 RxList 추가

  void toggleFavorite(String title) {
    if (favorites.contains(title)) {
      favorites.remove(title);
    } else {
      favorites.add(title);
    }
  }

  void setFileList(List<Folder> list) {
    fileList.assignAll(list);
  }
}
