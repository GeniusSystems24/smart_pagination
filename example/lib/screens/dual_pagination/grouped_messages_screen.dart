import 'package:flutter/material.dart';
import 'package:custom_pagination/pagination.dart';
import 'package:intl/intl.dart';
import '../../models/message.dart';
import '../../services/mock_api_service.dart';

/// Grouped messages example using DualPagination
class GroupedMessagesScreen extends StatelessWidget {
  const GroupedMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grouped Messages'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.teal),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Messages are automatically grouped by date. '
                    'Each group has a header showing the date.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: DualPaginatedListView<String, Message>(
              request: const PaginationRequest(page: 1, pageSize: 50),
              dataProvider: (request) => MockApiService.fetchMessages(request),
              groupKeyGenerator: (message) {
                // Group by date (YYYY-MM-DD)
                return DateFormat('yyyy-MM-dd').format(message.timestamp);
              },
              groupHeaderBuilder: (context, dateKey, messages) {
                final date = DateTime.parse(dateKey);
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final yesterday = today.subtract(const Duration(days: 1));
                final messageDate = DateTime(date.year, date.month, date.day);

                String dateLabel;
                if (messageDate == today) {
                  dateLabel = 'Today';
                } else if (messageDate == yesterday) {
                  dateLabel = 'Yesterday';
                } else {
                  dateLabel = DateFormat('MMMM dd, yyyy').format(date);
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${messages.length} messages)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childBuilder: (context, message, index) {
                return _buildMessageCard(message);
              },
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 72,
              ),
              emptyBuilder: (context) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.message_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No messages',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, exception, retryCallback) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: $exception',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: retryCallback,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
              initialLoadingBuilder: (context) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              bottomLoadingBuilder: (context) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Message message) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: message.isRead ? Colors.grey[300] : Colors.teal,
        child: Text(
          message.author[0].toUpperCase(),
          style: TextStyle(
            color: message.isRead ? Colors.grey[600] : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              message.author,
              style: TextStyle(
                fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          message.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ),
      trailing: message.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}
