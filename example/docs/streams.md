# Streams Examples

Real-time data updates with stream-based pagination.

## Table of Contents

- [Single Stream](#single-stream)
- [Multi Stream](#multi-stream)
- [Merged Streams](#merged-streams)

---

## Single Stream

Real-time updates from a single stream source:

```dart
class SingleStreamScreen extends StatelessWidget {
  // Simulated stream that emits new data periodically
  Stream<List<StockPrice>> streamStockPrices(PaginationRequest request) async* {
    // Initial data
    yield await fetchInitialPrices();

    // Real-time updates every 2 seconds
    await for (final update in Stream.periodic(
      const Duration(seconds: 2),
      (_) => generatePriceUpdate(),
    )) {
      yield update;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Stock Prices'),
        actions: [
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('LIVE', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: SmartPagination.listViewWithProvider<StockPrice>(
        request: const PaginationRequest(page: 1, pageSize: 50),
        provider: PaginationProvider.stream(streamStockPrices),
        itemBuilder: (context, items, index) {
          final stock = items[index];
          final isPositive = stock.change >= 0;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isPositive ? Colors.green : Colors.red,
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
              ),
            ),
            title: Text(stock.symbol),
            subtitle: Text(stock.name),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${stock.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${isPositive ? '+' : ''}${stock.change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### Firebase Firestore Example

```dart
Stream<List<Message>> streamMessages(PaginationRequest request) {
  return FirebaseFirestore.instance
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .limit(request.pageSize ?? 50)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList());
}
```

---

## Multi Stream

Multiple streams with different update rates:

```dart
class MultiStreamScreen extends StatefulWidget {
  @override
  State<MultiStreamScreen> createState() => _MultiStreamScreenState();
}

class _MultiStreamScreenState extends State<MultiStreamScreen> {
  late final StreamController<List<Notification>> _notificationController;
  late final StreamController<List<Activity>> _activityController;

  @override
  void initState() {
    super.initState();
    _notificationController = StreamController<List<Notification>>.broadcast();
    _activityController = StreamController<List<Activity>>.broadcast();

    // Start streams with different rates
    _startNotificationStream();
    _startActivityStream();
  }

  void _startNotificationStream() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _notificationController.add(generateNotifications());
    });
  }

  void _startActivityStream() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      _activityController.add(generateActivities());
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Multi Stream'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
              Tab(icon: Icon(Icons.timeline), text: 'Activity'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Notifications stream (updates every 5 seconds)
            SmartPagination.listViewWithProvider<Notification>(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.stream(
                (_) => _notificationController.stream,
              ),
              itemBuilder: (context, items, index) {
                final notification = items[index];
                return ListTile(
                  leading: Icon(
                    notification.icon,
                    color: notification.color,
                  ),
                  title: Text(notification.title),
                  subtitle: Text(notification.message),
                  trailing: Text(
                    timeAgo(notification.timestamp),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                );
              },
            ),

            // Activity stream (updates every 3 seconds)
            SmartPagination.listViewWithProvider<Activity>(
              request: const PaginationRequest(page: 1, pageSize: 20),
              provider: PaginationProvider.stream(
                (_) => _activityController.stream,
              ),
              itemBuilder: (context, items, index) {
                final activity = items[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(activity.userAvatar),
                  ),
                  title: Text(activity.description),
                  subtitle: Text(activity.details),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notificationController.close();
    _activityController.close();
    super.dispose();
  }
}
```

---

## Merged Streams

Combine multiple streams into one unified stream:

```dart
class MergedStreamsScreen extends StatelessWidget {
  Stream<List<FeedItem>> mergedFeedStream(PaginationRequest request) {
    // Stream 1: Posts
    final postsStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((s) => s.docs.map((d) => FeedItem.post(d)).toList());

    // Stream 2: Stories
    final storiesStream = FirebaseFirestore.instance
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((s) => s.docs.map((d) => FeedItem.story(d)).toList());

    // Stream 3: Ads
    final adsStream = Stream.periodic(
      const Duration(seconds: 30),
      (_) => [FeedItem.ad(generateAd())],
    );

    // Merge all streams
    return Rx.combineLatest3(
      postsStream,
      storiesStream,
      adsStream,
      (posts, stories, ads) {
        final combined = [...stories, ...posts];
        // Insert ads every 5 items
        for (var i = 5; i < combined.length; i += 6) {
          if (ads.isNotEmpty) {
            combined.insert(i, ads.first);
          }
        }
        return combined;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merged Feed')),
      body: SmartPagination.listViewWithProvider<FeedItem>(
        request: const PaginationRequest(page: 1, pageSize: 50),
        provider: PaginationProvider.stream(mergedFeedStream),
        itemBuilder: (context, items, index) {
          final item = items[index];
          return switch (item.type) {
            FeedItemType.post => _buildPostCard(item),
            FeedItemType.story => _buildStoryCard(item),
            FeedItemType.ad => _buildAdCard(item),
          };
        },
      ),
    );
  }

  Widget _buildPostCard(FeedItem item) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(item.authorAvatar)),
            title: Text(item.authorName),
            subtitle: Text(timeAgo(item.timestamp)),
          ),
          if (item.imageUrl != null)
            Image.network(item.imageUrl!, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(item.content),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(FeedItem item) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          item.content,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildAdCard(FeedItem item) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: Row(
        children: [
          const Icon(Icons.ad_units, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(child: Text(item.content)),
          const Text('Ad', style: TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
```

---

[Back to Examples](../example.md)
