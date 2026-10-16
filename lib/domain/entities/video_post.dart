
class VideoPost {
  final String id;
  final String caption;
  final String videoUrl;
  final int likes;
  final int views;

  VideoPost({
    this.id = '',
    required this.caption,
    required this.videoUrl,
    this.likes = 0,
    this.views = 0,
  });
}
