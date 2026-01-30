import 'package:flutter/material.dart';
import 'package:vango_parent_app/data/mock_data.dart';
import 'package:vango_parent_app/models/message_thread.dart';
import 'package:vango_parent_app/theme/app_colors.dart';
import 'package:vango_parent_app/theme/app_typography.dart';
import 'package:vango_parent_app/widgets/message_thread_tile.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  void _openChat(BuildContext context, MessageThread thread) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatScreen(thread: thread)));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          elevation: 0,
          backgroundColor: AppColors.background,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: AppTypography.headline.copyWith(fontSize: 20),
              ),
              Text(
                '${MockData.threads.length} conversations',
                style: AppTypography.body.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              var thread = MockData.threads[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: MessageThreadTile(
                  thread: thread,
                  onTap: () => _openChat(context, thread),
                ),
              );
            }, childCount: MockData.threads.length),
          ),
        ),
      ],
    );
  }
}

class ChatScreen extends StatelessWidget {
  final MessageThread thread;

  const ChatScreen({Key? key, required this.thread}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(thread.name),
            Text(
              'Route channel',
              style: AppTypography.body.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.call))],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(20),
              itemCount: thread.messages.length,
              itemBuilder: (context, index) {
                var message = thread.messages[index];

                // Simple if-else instead of complex assignments
                Alignment align;
                if (message.isParent) {
                  align = Alignment.centerRight;
                } else {
                  align = Alignment.centerLeft;
                }

                Color color;
                if (message.isParent) {
                  color = AppColors.accent;
                } else {
                  color = AppColors.surface;
                }

                Color textColor;
                if (message.isParent) {
                  textColor = Colors.white;
                } else {
                  textColor = AppColors.textPrimary;
                }

                return Align(
                  alignment: align,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: message.isParent
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.body,
                          style: AppTypography.body.copyWith(color: textColor),
                        ),
                        SizedBox(height: 4),
                        Text(
                          message.time,
                          style: AppTypography.label.copyWith(
                            fontSize: 10,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.attach_file)),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: 'Send a message'),
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}