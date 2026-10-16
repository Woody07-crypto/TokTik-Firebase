
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreTest extends StatelessWidget {
  const FirestoreTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos de Firebase'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('videos')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al leer videos'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final videos = snapshot.data!.docs;

          if (videos.isEmpty) {
            return const Center(
              child: Text('No hay videos'),
            );
          }

          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final documento = videos[index];

              return VideoLikeTile(
                key: ValueKey(documento.id),
                videoId: documento.id,
                description:
                    documento.data()['description'] ??
                    'Sin descripción',
              );
            },
          );
        },
      ),
    );
  }
}

class VideoLikeTile extends StatefulWidget {
  final String videoId;
  final String description;

  const VideoLikeTile({
    super.key,
    required this.videoId,
    required this.description,
  });

  @override
  State<VideoLikeTile> createState() => _VideoLikeTileState();
}

class _VideoLikeTileState extends State<VideoLikeTile> {
  bool isLoading = false;

  Future<void> toggleLike(bool hasLiked) async {
    if (isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    final likeRef = FirebaseFirestore.instance
        .collection('videos')
        .doc(widget.videoId)
        .collection('likes')
        .doc(user.uid);

    try {
      if (hasLiked) {
        await likeRef.delete();
      } else {
        await likeRef.set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar el like'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .collection('likes')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const ListTile(
            title: Text('Error al cargar likes'),
          );
        }

        if (!snapshot.hasData) {
          return const ListTile(
            title: Text('Cargando likes...'),
          );
        }

        final likes = snapshot.data!.docs;

        final hasLiked = likes.any(
          (documento) => documento.id == user.uid,
        );

        return ListTile(
          leading: const Icon(Icons.play_circle),
          title: Text(widget.description),
          subtitle: Text('Likes: ${likes.length}'),
          trailing: IconButton(
            onPressed: isLoading
                ? null
                : () => toggleLike(hasLiked),
            icon: Icon(
              hasLiked
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: hasLiked
                  ? Colors.red
                  : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
