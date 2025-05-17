import 'dart:io';

import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

class PanaromaImageScreen extends StatelessWidget {
  final String imageUrl;
  final bool? isFileImage;
  const PanaromaImageScreen({
    Key? key,
    required this.imageUrl,
    this.isFileImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Image image;
    if ((isFileImage ?? false)) {
      image = Image.file(File(imageUrl));
    } else {
      image = Image.network(imageUrl);
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PanoramaViewer(child: image),
      ),
    );
  }
}
