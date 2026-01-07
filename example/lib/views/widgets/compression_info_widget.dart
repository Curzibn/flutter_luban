import 'package:flutter/material.dart';
import 'package:luban/luban.dart';

class CompressionInfoWidget extends StatelessWidget {
  final int originalWidth;
  final int originalHeight;
  final LubanTarget lubanTarget;

  const CompressionInfoWidget({
    super.key,
    required this.originalWidth,
    required this.originalHeight,
    required this.lubanTarget,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? Colors.blue.shade700 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Luban压缩参数',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('原图尺寸', '$originalWidth × $originalHeight'),
          _buildInfoRow(
            '目标尺寸',
            '${lubanTarget.width} × ${lubanTarget.height}',
            highlight: lubanTarget.width != originalWidth ||
                lubanTarget.height != originalHeight,
          ),
          _buildInfoRow('压缩质量', '${lubanTarget.quality}%'),
          _buildInfoRow(
            '预计大小',
            _formatBytes(lubanTarget.estimatedSizeKb * 1024),
          ),
        ],
      ),
    );
  }
}

