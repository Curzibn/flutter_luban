import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/batch_compress_result.dart';

class BatchCompressWidget extends StatelessWidget {
  final bool isCompressing;
  final int progress;
  final int total;
  final BatchCompressResult? result;
  final VoidCallback onStart;

  const BatchCompressWidget({
    super.key,
    required this.isCompressing,
    required this.progress,
    required this.total,
    this.result,
    required this.onStart,
  });

  void _copyToClipboard(BuildContext context, String text) {
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
          Text(
            '批量压缩测试',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 12),
          if (isCompressing) ...[
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text('压缩中: $progress/$total'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total > 0 ? progress / total : 0,
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.folder),
                label: const Text('批量压缩'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
          if (result != null) ...[
            const SizedBox(height: 8),
            Text(
              '压缩完成: 总计 ${result!.total}, 成功 ${result!.success}, 失败 ${result!.failed}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: result!.failed == 0 ? Colors.green : Colors.orange,
              ),
            ),
            if (result!.savedPaths.isNotEmpty && result!.directoryPath != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder, size: 18, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          '保存位置',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, result!.directoryPath!),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              result!.directoryPath!,
                              style: TextStyle(
                                fontSize: 12,
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
                            color: Colors.green.shade700,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '已保存 ${result!.savedPaths.length} 张图片',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}


