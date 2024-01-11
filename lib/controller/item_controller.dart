import 'package:get/get.dart';
import '../class/file.dart';

class FavoriteController extends GetxController {
  RxList<String> favorites = <String>[].obs;
  RxList<Folder> fileList = <Folder>[].obs;

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
