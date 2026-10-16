
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/entities/video_post.dart';

class DiscoverProvider extends ChangeNotifier {
  bool initialLoading = true;
  List<VideoPost> videos = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _subscription;

  Future<void> loadNextPage() async {
    await _subscription?.cancel();

    initialLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('videos')
        .snapshots()
        .listen(
      (snapshot) {
        videos = snapshot.docs.map((doc) {
          final data = doc.data();

          return VideoPost(
            id: doc.id,
            caption: data['description'] ?? 'Sin descripción',
            videoUrl: data['videoUrl'] ?? '',
            views: (data['views'] as num?)?.toInt() ?? 0,
          );
        }).toList();

        initialLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error al cargar videos: $error');
        initialLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
