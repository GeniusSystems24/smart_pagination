import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service to seed Firebase with demo data
class SeedDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Seeds all collections with demo data
  Future<void> seedAllData({Function(String message)? onProgress}) async {
    onProgress?.call('Starting data seeding...');

    await seedProducts(onProgress: onProgress);
    await seedUsers(onProgress: onProgress);
    await seedMessages(onProgress: onProgress);
    await seedPosts(onProgress: onProgress);

    onProgress?.call('✅ All data seeded successfully!');
  }

  /// Seeds the products collection for Firestore examples
  Future<void> seedProducts({Function(String message)? onProgress}) async {
    onProgress?.call('Seeding products...');

    final batch = _firestore.batch();
    final productsRef = _firestore.collection('products');

    // Check if already seeded
    final existing = await productsRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      onProgress?.call('Products already exist, skipping...');
      return;
    }

    final categories = ['Electronics', 'Clothing', 'Books', 'Home', 'Sports'];
    final productNames = {
      'Electronics': [
        'Wireless Headphones',
        'Smart Watch',
        'Laptop Stand',
        'USB-C Hub',
        'Mechanical Keyboard',
        'Gaming Mouse',
        'Portable Charger',
        'Bluetooth Speaker',
        'Webcam HD',
        'Monitor Light Bar',
        'Wireless Earbuds',
        'Tablet Stand',
        'Smart Plug',
        'LED Desk Lamp',
        'Phone Holder',
      ],
      'Clothing': [
        'Cotton T-Shirt',
        'Denim Jeans',
        'Wool Sweater',
        'Running Shoes',
        'Baseball Cap',
        'Winter Jacket',
        'Casual Shorts',
        'Leather Belt',
        'Sport Socks',
        'Hiking Boots',
        'Rain Coat',
        'Swim Trunks',
        'Formal Shirt',
        'Yoga Pants',
        'Canvas Sneakers',
      ],
      'Books': [
        'Flutter Complete Guide',
        'Clean Code',
        'Design Patterns',
        'The Pragmatic Programmer',
        'Dart Programming',
        'Firebase Essentials',
        'Mobile UI Design',
        'Algorithms Handbook',
        'Software Architecture',
        'Testing Best Practices',
        'DevOps Guide',
        'Cloud Computing',
        'Data Structures',
        'Web Development',
        'Machine Learning Basics',
      ],
      'Home': [
        'Coffee Maker',
        'Air Purifier',
        'Robot Vacuum',
        'Smart Thermostat',
        'Bedside Lamp',
        'Kitchen Scale',
        'Blender Pro',
        'Ceramic Vase',
        'Wall Clock',
        'Plant Pot Set',
        'Throw Pillow',
        'Area Rug',
        'Picture Frame',
        'Candle Set',
        'Storage Basket',
      ],
      'Sports': [
        'Yoga Mat',
        'Resistance Bands',
        'Dumbbell Set',
        'Jump Rope',
        'Foam Roller',
        'Water Bottle',
        'Fitness Tracker',
        'Exercise Ball',
        'Pull-up Bar',
        'Boxing Gloves',
        'Tennis Racket',
        'Soccer Ball',
        'Basketball',
        'Swimming Goggles',
        'Gym Bag',
      ],
    };

    int index = 0;
    for (final category in categories) {
      for (final name in productNames[category]!) {
        final docRef = productsRef.doc();
        final price = 10.0 + (index * 7.3 % 490);
        final rating = 3.0 + (index * 0.3 % 2.0);

        batch.set(docRef, {
          'name': name,
          'category': category,
          'price': price,
          'rating': rating,
          'imageUrl': 'https://picsum.photos/seed/$index/200/200',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(hours: index * 2)),
          ),
        });
        index++;
      }
    }

    await batch.commit();
    onProgress?.call('✅ Added ${index} products');
  }

  /// Seeds the users collection for search example
  Future<void> seedUsers({Function(String message)? onProgress}) async {
    onProgress?.call('Seeding users...');

    final batch = _firestore.batch();
    final usersRef = _firestore.collection('users');

    // Check if already seeded
    final existing = await usersRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      onProgress?.call('Users already exist, skipping...');
      return;
    }

    final users = [
      {
        'name': 'Alice Johnson',
        'email': 'alice@example.com',
        'department': 'Engineering',
        'isOnline': true,
      },
      {
        'name': 'Bob Smith',
        'email': 'bob@example.com',
        'department': 'Design',
        'isOnline': false,
      },
      {
        'name': 'Charlie Brown',
        'email': 'charlie@example.com',
        'department': 'Marketing',
        'isOnline': true,
      },
      {
        'name': 'Diana Ross',
        'email': 'diana@example.com',
        'department': 'Engineering',
        'isOnline': false,
      },
      {
        'name': 'Eve Wilson',
        'email': 'eve@example.com',
        'department': 'Sales',
        'isOnline': true,
      },
      {
        'name': 'Frank Miller',
        'email': 'frank@example.com',
        'department': 'Support',
        'isOnline': false,
      },
      {
        'name': 'Grace Lee',
        'email': 'grace@example.com',
        'department': 'Engineering',
        'isOnline': true,
      },
      {
        'name': 'Henry Davis',
        'email': 'henry@example.com',
        'department': 'Design',
        'isOnline': false,
      },
      {
        'name': 'Ivy Chen',
        'email': 'ivy@example.com',
        'department': 'Marketing',
        'isOnline': true,
      },
      {
        'name': 'Jack Taylor',
        'email': 'jack@example.com',
        'department': 'Engineering',
        'isOnline': false,
      },
      {
        'name': 'Kate Martin',
        'email': 'kate@example.com',
        'department': 'HR',
        'isOnline': true,
      },
      {
        'name': 'Leo Anderson',
        'email': 'leo@example.com',
        'department': 'Engineering',
        'isOnline': false,
      },
      {
        'name': 'Mia Thompson',
        'email': 'mia@example.com',
        'department': 'Design',
        'isOnline': true,
      },
      {
        'name': 'Nathan White',
        'email': 'nathan@example.com',
        'department': 'Sales',
        'isOnline': false,
      },
      {
        'name': 'Olivia Harris',
        'email': 'olivia@example.com',
        'department': 'Marketing',
        'isOnline': true,
      },
      {
        'name': 'Peter Clark',
        'email': 'peter@example.com',
        'department': 'Engineering',
        'isOnline': false,
      },
      {
        'name': 'Quinn Lewis',
        'email': 'quinn@example.com',
        'department': 'Support',
        'isOnline': true,
      },
      {
        'name': 'Rachel Walker',
        'email': 'rachel@example.com',
        'department': 'Design',
        'isOnline': false,
      },
      {
        'name': 'Sam Robinson',
        'email': 'sam@example.com',
        'department': 'Engineering',
        'isOnline': true,
      },
      {
        'name': 'Tina Hall',
        'email': 'tina@example.com',
        'department': 'HR',
        'isOnline': false,
      },
      {
        'name': 'Uma Young',
        'email': 'uma@example.com',
        'department': 'Marketing',
        'isOnline': true,
      },
      {
        'name': 'Victor King',
        'email': 'victor@example.com',
        'department': 'Sales',
        'isOnline': false,
      },
      {
        'name': 'Wendy Wright',
        'email': 'wendy@example.com',
        'department': 'Engineering',
        'isOnline': true,
      },
      {
        'name': 'Xavier Lopez',
        'email': 'xavier@example.com',
        'department': 'Design',
        'isOnline': false,
      },
      {
        'name': 'Yara Scott',
        'email': 'yara@example.com',
        'department': 'Support',
        'isOnline': true,
      },
      {
        'name': 'Zack Green',
        'email': 'zack@example.com',
        'department': 'Engineering',
        'isOnline': false,
      },
      {
        'name': 'Amy Baker',
        'email': 'amy@example.com',
        'department': 'Marketing',
        'isOnline': true,
      },
      {
        'name': 'Brian Adams',
        'email': 'brian@example.com',
        'department': 'Sales',
        'isOnline': false,
      },
      {
        'name': 'Cathy Nelson',
        'email': 'cathy@example.com',
        'department': 'Engineering',
        'isOnline': true,
      },
      {
        'name': 'David Carter',
        'email': 'david@example.com',
        'department': 'HR',
        'isOnline': false,
      },
    ];

    for (int i = 0; i < users.length; i++) {
      final docRef = usersRef.doc();
      final user = users[i];

      batch.set(docRef, {
        ...user,
        'avatarUrl': 'https://i.pravatar.cc/150?u=${user['email']}',
        'lastActive': Timestamp.fromDate(
          DateTime.now().subtract(Duration(minutes: i * 15)),
        ),
      });
    }

    await batch.commit();
    onProgress?.call('✅ Added ${users.length} users');
  }

  /// Seeds the messages collection for realtime example
  Future<void> seedMessages({Function(String message)? onProgress}) async {
    onProgress?.call('Seeding messages...');

    final batch = _firestore.batch();
    final messagesRef = _firestore.collection('messages');

    // Check if already seeded
    final existing = await messagesRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      onProgress?.call('Messages already exist, skipping...');
      return;
    }

    final messages = [
      {'userName': 'Alice', 'content': 'Hello everyone! 👋'},
      {'userName': 'Bob', 'content': 'Hey Alice! How are you?'},
      {'userName': 'Charlie', 'content': 'Just joined the chat!'},
      {'userName': 'Diana', 'content': 'Working on the new feature today'},
      {'userName': 'Eve', 'content': 'Can someone review my PR? 🙏'},
      {'userName': 'Frank', 'content': 'Sure, I\'ll take a look'},
      {'userName': 'Alice', 'content': 'Great progress on the project!'},
      {'userName': 'Bob', 'content': 'Thanks! The team is doing amazing'},
      {'userName': 'Charlie', 'content': 'Meeting in 10 minutes'},
      {'userName': 'Diana', 'content': 'On my way! 🏃‍♀️'},
      {'userName': 'Eve', 'content': 'The tests are passing now'},
      {'userName': 'Frank', 'content': 'Excellent work everyone!'},
      {'userName': 'Alice', 'content': 'Let\'s celebrate our milestone 🎉'},
      {'userName': 'Bob', 'content': 'Pizza party? 🍕'},
      {'userName': 'Charlie', 'content': 'Count me in!'},
      {'userName': 'Diana', 'content': 'Sounds fun!'},
      {'userName': 'Eve', 'content': 'I\'ll bring the drinks'},
      {'userName': 'Frank', 'content': 'Friday evening works for me'},
      {'userName': 'Alice', 'content': 'Perfect! See you all then'},
      {'userName': 'Bob', 'content': 'Can\'t wait! 😄'},
    ];

    for (int i = 0; i < messages.length; i++) {
      final docRef = messagesRef.doc();
      final msg = messages[i];

      batch.set(docRef, {
        'userName': msg['userName'],
        'content': msg['content'],
        'avatarUrl': 'https://i.pravatar.cc/150?u=${msg['userName']}',
        'timestamp': Timestamp.fromDate(
          DateTime.now().subtract(Duration(minutes: (messages.length - i) * 5)),
        ),
      });
    }

    await batch.commit();
    onProgress?.call('✅ Added ${messages.length} messages');
  }

  /// Seeds the posts node for Realtime Database example
  Future<void> seedPosts({Function(String message)? onProgress}) async {
    onProgress?.call('Seeding posts to Realtime Database...');

    final postsRef = _database.ref('posts');

    // Check if already seeded
    final existing = await postsRef.limitToFirst(1).get();
    if (existing.exists) {
      onProgress?.call('Posts already exist, skipping...');
      return;
    }

    final posts = [
      {
        'author': 'TechGuru',
        'content':
            'Just discovered an amazing Flutter package for pagination! The SmartPagination library makes infinite scrolling so easy to implement. Highly recommend checking it out! 🚀 #Flutter #MobileDev',
        'likes': 142,
        'comments': 28,
      },
      {
        'author': 'DevJane',
        'content':
            'Working on a new e-commerce app using Firebase. The real-time sync is incredible! Anyone else building with Firestore? 💻',
        'likes': 89,
        'comments': 15,
      },
      {
        'author': 'CodeMaster',
        'content':
            'Pro tip: Always use cursor-based pagination for large datasets. It\'s more efficient than offset-based pagination. Here\'s why... 🧵',
        'likes': 256,
        'comments': 42,
      },
      {
        'author': 'StartupSam',
        'content':
            'Launching our MVP next week! 6 months of hard work finally paying off. Thanks to everyone who supported us! 🎉',
        'likes': 312,
        'comments': 56,
      },
      {
        'author': 'UIDesigner',
        'content':
            'New design system just dropped! Check out these beautiful Material 3 components. The dark mode looks stunning! 🎨',
        'likes': 178,
        'comments': 31,
      },
      {
        'author': 'BackendBob',
        'content':
            'Migrated our entire backend to serverless. 50% cost reduction! Cloud Functions are a game changer. ☁️',
        'likes': 203,
        'comments': 38,
      },
      {
        'author': 'MobileMary',
        'content':
            'Cross-platform development has come so far. Building for iOS and Android simultaneously feels like magic! ✨',
        'likes': 165,
        'comments': 24,
      },
      {
        'author': 'DataDan',
        'content':
            'The importance of proper data modeling cannot be overstated. Spent 2 days restructuring our Firestore collections. Worth it! 📊',
        'likes': 94,
        'comments': 17,
      },
      {
        'author': 'TechGuru',
        'content':
            'Hot take: Dart is becoming one of the best languages for full-stack development. Backend with shelf, frontend with Flutter. Thoughts? 🤔',
        'likes': 287,
        'comments': 63,
      },
      {
        'author': 'DevJane',
        'content':
            'Just hit 1M downloads on our app! Thank you to this amazing community for all the support! 🙏💜',
        'likes': 542,
        'comments': 89,
      },
      {
        'author': 'SecuritySue',
        'content':
            'Reminder: Always sanitize user inputs and use Firebase Security Rules properly. Your users trust you with their data! 🔐',
        'likes': 198,
        'comments': 22,
      },
      {
        'author': 'FullStackFred',
        'content':
            'Built a complete chat app with Flutter and Firebase in a weekend. Real-time updates, offline support, push notifications - all working! 💬',
        'likes': 234,
        'comments': 45,
      },
      {
        'author': 'OpenSourceOlly',
        'content':
            'Contributing to open source has been the best decision of my career. Learning so much from the community! 🌟',
        'likes': 156,
        'comments': 19,
      },
      {
        'author': 'StartupSam',
        'content':
            'User feedback is gold. Just added a feature our users have been requesting for months. The response has been incredible! 📈',
        'likes': 127,
        'comments': 21,
      },
      {
        'author': 'PerfPatty',
        'content':
            'Optimized our app loading time from 4s to 800ms. Key: lazy loading, code splitting, and image optimization. Details in thread! ⚡',
        'likes': 321,
        'comments': 54,
      },
      {
        'author': 'UIDesigner',
        'content':
            'Accessibility is not optional. Made our app fully accessible today - screen readers, keyboard navigation, high contrast. Everyone deserves great UX! ♿',
        'likes': 289,
        'comments': 36,
      },
      {
        'author': 'CloudCarl',
        'content':
            'Firebase Hosting + Cloud Functions + Firestore = the holy trinity of rapid development. Ship fast, scale easily! 🚢',
        'likes': 187,
        'comments': 29,
      },
      {
        'author': 'MobileMary',
        'content':
            'Animation tip: Use curves wisely! The right easing can make your UI feel 10x more polished. My favorite: Curves.easeOutCubic 🎭',
        'likes': 143,
        'comments': 18,
      },
      {
        'author': 'TechGuru',
        'content':
            'Finally mastered state management in Flutter. After trying them all, here\'s my honest comparison of the top solutions... 📝',
        'likes': 412,
        'comments': 78,
      },
      {
        'author': 'TestingTom',
        'content':
            'Unit tests saved us from a critical bug today. 100% coverage might be overkill, but 0% coverage is definitely asking for trouble! 🐛',
        'likes': 176,
        'comments': 25,
      },
    ];

    for (int i = 0; i < posts.length; i++) {
      final post = posts[i];
      await postsRef.push().set({
        'author': post['author'],
        'content': post['content'],
        'likes': post['likes'],
        'comments': post['comments'],
        'timestamp': DateTime.now()
            .subtract(Duration(hours: (posts.length - i) * 3))
            .millisecondsSinceEpoch,
      });
    }

    onProgress?.call('✅ Added ${posts.length} posts');
  }

  /// Clears all seeded data
  Future<void> clearAllData({Function(String message)? onProgress}) async {
    onProgress?.call('Clearing all data...');

    // Clear Firestore collections
    await _clearCollection('products', onProgress);
    await _clearCollection('users', onProgress);
    await _clearCollection('messages', onProgress);

    // Clear Realtime Database
    await _database.ref('posts').remove();
    onProgress?.call('✅ Cleared posts from Realtime Database');

    onProgress?.call('✅ All data cleared!');
  }

  Future<void> _clearCollection(
    String collection,
    Function(String message)? onProgress,
  ) async {
    final snapshot = await _firestore.collection(collection).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    onProgress?.call(
      '✅ Cleared $collection (${snapshot.docs.length} documents)',
    );
  }
}
