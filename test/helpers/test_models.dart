/// Test models and helpers for pagination tests
library;

/// Simple test model for pagination
class TestItem {
  final String id;
  final String name;
  final int value;

  const TestItem({
    required this.id,
    required this.name,
    required this.value,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestItem &&
        other.id == id &&
        other.name == name &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(id, name, value);

  @override
  String toString() => 'TestItem(id: $id, name: $name, value: $value)';
}

/// Factory for creating test items
class TestItemFactory {
  static List<TestItem> createList(int count, {int startIndex = 0}) {
    return List.generate(
      count,
      (index) => TestItem(
        id: '${startIndex + index}',
        name: 'Item ${startIndex + index}',
        value: startIndex + index,
      ),
    );
  }

  static TestItem create(int index) {
    return TestItem(
      id: '$index',
      name: 'Item $index',
      value: index,
    );
  }
}
