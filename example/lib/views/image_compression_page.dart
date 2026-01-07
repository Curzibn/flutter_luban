import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/image_compression_viewmodel.dart';
import '../models/batch_compress_result.dart';
import 'widgets/image_preview_widget.dart';
import 'widgets/compression_info_widget.dart';
import 'widgets/batch_compress_widget.dart';
import 'widgets/compression_comparison_widget.dart';
import 'widgets/full_screen_image_viewer.dart';
import 'widgets/storage_info_widget.dart';

class ImageCompressionPage extends StatefulWidget {
  const ImageCompressionPage({super.key});

  @override
  State<ImageCompressionPage> createState() => _ImageCompressionPageState();
}

class _ImageCompressionPageState extends State<ImageCompressionPage> {
  BatchCompressResult? _previousBatchResult;

  void _showFullScreenImage(BuildContext context, imageData, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          image: imageData.image,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片压缩示例'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<ImageCompressionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(viewModel.errorMessage!)),
              );
              viewModel.clearError();
            });
          }

          if (viewModel.batchResult != null &&
              viewModel.batchResult != _previousBatchResult) {
            _previousBatchResult = viewModel.batchResult;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '批量压缩完成: 总计 ${viewModel.batchResult!.total}, 成功 ${viewModel.batchResult!.success}, 失败 ${viewModel.batchResult!.failed}',
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            });
          }

            return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StorageInfoWidget(),
                const SizedBox(height: 16),
                BatchCompressWidget(
                  isCompressing: viewModel.isBatchCompressing,
                  progress: viewModel.batchProgress,
                  total: viewModel.batchTotal,
                  result: viewModel.batchResult,
                  onStart: viewModel.compressBatchFromDirectory,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: viewModel.pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('从相册选择图片'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: viewModel.isCompressing ? null : viewModel.compressImage,
                  icon: viewModel.isCompressing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.compress),
                  label: Text(viewModel.isCompressing ? '压缩中...' : '使用Luban算法压缩'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                if (viewModel.lubanTarget != null && viewModel.originalImageData != null) ...[
                  const SizedBox(height: 16),
                  CompressionInfoWidget(
                    originalWidth: viewModel.originalImageData!.width,
                    originalHeight: viewModel.originalImageData!.height,
                    lubanTarget: viewModel.lubanTarget!,
                  ),
                ],
                const SizedBox(height: 24),
                if (viewModel.originalImageData != null || viewModel.compressedImageData != null) ...[
                  ImagePreviewWidget(
                    imageData: viewModel.originalImageData,
                    title: '原图',
                    bytes: viewModel.originalImageData?.bytes.length,
                    onTap: viewModel.originalImageData != null
                        ? () => _showFullScreenImage(
                              context,
                              viewModel.originalImageData!,
                              '原图',
                            )
                        : null,
                  ),
                  const SizedBox(height: 24),
                  ImagePreviewWidget(
                    imageData: viewModel.compressedImageData,
                    title: '压缩后',
                    bytes: viewModel.compressedImageBytes?.length,
                    onTap: viewModel.compressedImageData != null
                        ? () => _showFullScreenImage(
                              context,
                              viewModel.compressedImageData!,
                              '压缩后',
                            )
                        : null,
                  ),
                  if (viewModel.originalImageData != null &&
                      viewModel.compressedImageBytes != null) ...[
                    const SizedBox(height: 24),
                    CompressionComparisonWidget(
                      originalBytes: viewModel.originalImageData!.bytes.length,
                      compressedBytes: viewModel.compressedImageBytes!.length,
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

