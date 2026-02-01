import 'package:flutter/material.dart';
import 'package:vango_parent_app/models/message_thread.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';

class MessageThreadTile extends StatelessWidget {
  final MessageThread thread;
  final VoidCallback onTap;

  const MessageThreadTile({super.key, required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Basic logic for styling
    Color borderColor;
    if (thread.unread) {
      borderColor = AppColors.accent.withOpacity(0.2);
    } else {
      borderColor = AppColors.stroke.withOpacity(0.2);
    }

    double borderWidth;
    if (thread.unread) {
      borderWidth = 1.5;
    } else {
      borderWidth = 1;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withOpacity(thread.unread ? 1 : 0.7),
                    AppColors.accent.withOpacity(thread.unread ? 0.8 : 0.5),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  thread.name.substring(0, 1),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (thread.unread)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          thread.name,
          style: AppTypography.title.copyWith(
            fontSize: 15,
            fontWeight: thread.unread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            thread.snippet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              fontSize: 13,
              color: thread.unread
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: thread.unread
                    ? AppColors.accent.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                thread.time,
                style: AppTypography.label.copyWith(
                  fontSize: 11,
                  color: thread.unread
                      ? AppColors.accent
                      : AppColors.textSecondary,
                  fontWeight: thread.unread
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
            if (thread.unread)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.circle, size: 8, color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }
}