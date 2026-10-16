
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toktok/config/helpers/human_formats.dart';
import 'package:toktok/domain/entities/video_post.dart';

class VideoButtons extends StatelessWidget {
  final VideoPost video;

  const VideoButtons({
    super.key,
    required this.video,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FirebaseLikeButton(videoId: video.id),
        const SizedBox(height: 20),
        _CustomIconButton(
          value: video.views,
          iconData: Icons.remove_red_eye_outlined,
        ),
        const SizedBox(height: 20),
        SpinPerfect(
          infinite: true,
          duration: const Duration(seconds: 5),
          child: const _CustomIconButton(
            value: 0,
            iconData: Icons.play_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _FirebaseLikeButton extends StatefulWidget {
  final String videoId;

  const _FirebaseLikeButton({required this.videoId});

  @override
  State<_FirebaseLikeButton> createState() =>
      _FirebaseLikeButtonState();
}

class _FirebaseLikeButtonState extends State<_FirebaseLikeButton> {
  bool isLoading = false;

  Future<void> toggleLike(bool hasLiked) async {
    if (isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.videoId.isEmpty) return;

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
            content: Text('Error al actualizar el like'),
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

    if (user == null || widget.videoId.isEmpty) {
      return const Icon(Icons.favorite_border,
          color: Colors.grey, size: 30);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(widget.videoId)
          .collection('likes')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Icon(
            Icons.error_outline,
            color: Colors.red,
          );
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final likes = snapshot.data!.docs;
        final hasLiked = likes.any(
          (doc) => doc.id == user.uid,
        );

        return Column(
          children: [
            IconButton(
              onPressed: isLoading
                  ? null
                  : () => toggleLike(hasLiked),
              icon: Icon(
                hasLiked
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: hasLiked ? Colors.red : Colors.white,
                size: 30,
              ),
            ),
            Text(
              HumanFormats.humanReadbleNumber(
                likes.length.toDouble(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        );
      },
    );
  }
}

class _CustomIconButton extends StatelessWidget {
  final int value;
  final IconData iconData;
  final Color color;

  const _CustomIconButton({
    required this.value,
    required this.iconData,
    Color? iconColor,
  }) : color = iconColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(iconData, color: color, size: 30),
        ),
        if (value > 0)
          Text(
            HumanFormats.humanReadbleNumber(value.toDouble()),
          ),
      ],
    );
  }
}
