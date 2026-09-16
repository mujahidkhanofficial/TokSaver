import 'package:flutter_test/flutter_test.dart';
import 'package:tiktok_downloader/shared/models/video_metadata.dart';

void main() {
  group('Photo Slides & Carousel Metadata Tests', () {
    test('Correctly identifies photo post and image count', () {
      const photoMetadata = VideoMetadata(
        id: '71234567890',
        originalUrl: 'https://www.tiktok.com/@traveler/video/71234567890',
        title: 'Summer Vacation Photos',
        authorName: 'Traveler',
        authorUsername: 'traveler',
        videoUrlNoWatermark: 'https://example.com/img1.jpg',
        images: [
          'https://example.com/img1.jpg',
          'https://example.com/img2.jpg',
          'https://example.com/img3.jpg',
          'https://example.com/img4.jpg',
        ],
        audioUrl: 'https://example.com/soundtrack.mp3',
      );

      expect(photoMetadata.isPhotoPost, isTrue);
      expect(photoMetadata.images.length, equals(4));
      expect(photoMetadata.defaultPhotoFileName(1), equals('tiktok_traveler_71234567890_01.jpg'));
      expect(photoMetadata.defaultPhotoFileName(4), equals('tiktok_traveler_71234567890_04.jpg'));
      expect(photoMetadata.defaultPhotoFileName(10), equals('tiktok_traveler_71234567890_10.jpg'));
    });

    test('Video post is not identified as photo post', () {
      const videoMetadata = VideoMetadata(
        id: '79876543210',
        originalUrl: 'https://www.tiktok.com/@creator/video/79876543210',
        title: 'Dance Performance',
        authorName: 'Dancer',
        authorUsername: 'dancer',
        videoUrlNoWatermark: 'https://example.com/video.mp4',
        images: [],
      );

      expect(videoMetadata.isPhotoPost, isFalse);
      expect(videoMetadata.images, isEmpty);
    });

    test('Single image photo post generates correct default file name', () {
      const singleImageMetadata = VideoMetadata(
        id: '70000000001',
        originalUrl: 'https://www.tiktok.com/@photographer/video/70000000001',
        title: 'A Beautiful Sunset',
        authorName: 'Photographer',
        authorUsername: 'photographer',
        videoUrlNoWatermark: 'https://example.com/sunset.jpg',
        images: ['https://example.com/sunset.jpg'],
      );

      expect(singleImageMetadata.isPhotoPost, isTrue);
      expect(singleImageMetadata.images.length, equals(1));
      expect(singleImageMetadata.defaultPhotoFileName(1), equals('tiktok_photographer_70000000001_01.jpg'));
    });
  });
}
