import 'package:flutter/material.dart';

class CompressionComparisonWidget extends StatelessWidget {
  final int originalBytes;
  final int compressedBytes;

  const CompressionComparisonWidget({
    super.key,
    required this.originalBytes,
    required this.compressedBytes,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildComparisonRow(
    String label,
    String original,
    String compressed,
  ) {
    final double ratio = (1 - compressedBytes / originalBytes) * 100;
    final Color color = ratio > 50
        ? Colors.green
        : ratio > 20
            ? Colors.blue
            : Colors.orange;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        Row(
          children: [
            Text(
              original,
              style: const TextStyle(color: Colors.grey),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 16),
            ),
            Text(
              compressed,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '压缩对比',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            '文件大小',
            _formatBytes(originalBytes),
            _formatBytes(compressedBytes),
          ),
          const SizedBox(height: 8),
          _buildComparisonRow(
            '压缩率',
            '100%',
            '${((compressedBytes / originalBytes) * 100).toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          _buildComparisonRow(
            '节省空间',
            '-',
            _formatBytes(originalBytes - compressedBytes),
          ),
        ],
      ),
    );
  }
}

