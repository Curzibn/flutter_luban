import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/file_service.dart';

class StorageInfoWidget extends StatefulWidget {
  const StorageInfoWidget({super.key});

  @override
  State<StorageInfoWidget> createState() => _StorageInfoWidgetState();
}

class _StorageInfoWidgetState extends State<StorageInfoWidget> {
  final FileService _fileService = FileService();
  String? _inputImagesPath;
  String? _outputCompressedPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    try {
      _inputImagesPath = await _fileService.getInputImagesDirectoryPath();
      _outputCompressedPath = await _fileService.getOutputCompressedDirectoryPath();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('路径已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                '存储目录信息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_inputImagesPath != null) ...[
            _buildPathRow('输入目录（images）', _inputImagesPath!),
            const SizedBox(height: 8),
            Text(
              '请将需要压缩的图片放到此目录',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_outputCompressedPath != null) ...[
            _buildPathRow('输出目录（compressed）', _outputCompressedPath!),
            const SizedBox(height: 8),
            Text(
              '压缩后的图片将保存到此目录',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPathRow(String label, String path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _copyToClipboard(path),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  path,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.copy,
                size: 16,
                color: Colors.orange.shade700,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

