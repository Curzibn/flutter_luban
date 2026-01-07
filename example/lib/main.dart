import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/image_compression_viewmodel.dart';
import 'views/image_compression_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Luban Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (_) => ImageCompressionViewModel(),
        child: const ImageCompressionPage(),
      ),
    );
  }
}
