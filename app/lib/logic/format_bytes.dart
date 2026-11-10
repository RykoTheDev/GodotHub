String formatBytes(num bytes) {
  if (!bytes.isFinite || bytes <= 0) return '0 MB';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String formatBigBytes(BigInt bytes) => formatBytes(bytes.toDouble());
