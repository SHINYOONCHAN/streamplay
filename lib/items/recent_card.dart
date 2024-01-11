import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/item_controller.dart';

class RecentCard extends StatefulWidget {
  final String imageUrl;
  final String programTitle;

  const RecentCard({
    super.key,
    required this.imageUrl,
    required this.programTitle,
  });

  @override
  FavoritePageState createState() => FavoritePageState();
}

class FavoritePageState extends State<RecentCard> {
  final FavoriteController favoriteController = Get.put(FavoriteController());

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: mq.width * .4,
            height: mq.width * .54,
            child: Image.asset(
              widget.imageUrl,
              fit: BoxFit.fill,
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
    );
  }
}
