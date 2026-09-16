import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/video_metadata_service.dart';
import '../../shared/models/video_metadata.dart';

/// Provider for the VideoMetadataService instance.
final videoMetadataServiceProvider = Provider<VideoMetadataService>((ref) {
  return TikWMVideoMetadataService();
});

/// State for the video analyzer (loading, data, or error).
final analyzerStateProvider =
    StateNotifierProvider.autoDispose<AnalyzerNotifier, AsyncValue<VideoMetadata?>>((ref) {
  final service = ref.watch(videoMetadataServiceProvider);
  return AnalyzerNotifier(service);
});

class AnalyzerNotifier extends StateNotifier<AsyncValue<VideoMetadata?>> {
  AnalyzerNotifier(this._service) : super(const AsyncValue.data(null));

  final VideoMetadataService _service;

  Future<VideoMetadata?> analyze(String url) async {
    state = const AsyncValue.loading();

    final result = await _service.fetchMetadata(url);

    return result.fold(
      onOk: (metadata) {
        state = AsyncValue.data(metadata);
        return metadata;
      },
      onErr: (error) {
        state = AsyncValue.error(error, StackTrace.current);
        return null;
      },
    );
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
