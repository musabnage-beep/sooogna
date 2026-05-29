import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/cached_image_widget.dart';
import '../../domain/entities/message_entity.dart';

class ImageMessageWidget extends StatelessWidget {
  final Message message;
  final bool isMe;

  const ImageMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  void _openFullscreen(BuildContext context) {
    if (message.image == null || message.image!.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenImage(imageUrl: message.image!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(message.createdAt);
    final bgColor = isMe ? AppColors.primary : const Color(0xFFEDEDED);
    final timeColor =
        isMe ? Colors.white.withValues(alpha: 0.9) : AppColors.textSecondary;
    final maxWidth = MediaQuery.of(context).size.width * 0.7;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isMe ? 14 : 2),
                bottomRight: Radius.circular(isMe ? 2 : 14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _openFullscreen(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: maxWidth,
                      height: maxWidth,
                      child: CachedImageWidget(
                        imageUrl: message.image,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: TextStyle(color: timeColor, fontSize: 11),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead
                              ? Colors.lightBlueAccent
                              : timeColor,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenImage extends StatelessWidget {
  final String imageUrl;
  const _FullscreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('عرض الصورة'),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: CachedImageWidget(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
