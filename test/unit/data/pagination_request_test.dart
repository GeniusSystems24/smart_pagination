import 'package:custom_pagination/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginationRequest', () {
    test('should create with default values', () {
      const request = PaginationRequest();

      expect(request.page, equals(1));
      expect(request.pageSize, isNull);
      expect(request.cursor, isNull);
      expect(request.filters, isNull);
      expect(request.extra, isNull);
    });

    test('should create with provided values', () {
      const request = PaginationRequest(
        page: 2,
        pageSize: 20,
        cursor: 'next_token',
        filters: {'category': 'books'},
        extra: {'sortBy': 'price'},
      );

      expect(request.page, equals(2));
      expect(request.pageSize, equals(20));
      expect(request.cursor, equals('next_token'));
      expect(request.filters, equals({'category': 'books'}));
      expect(request.extra, equals({'sortBy': 'price'}));
    });

    test('should assert page > 0', () {
      expect(
        () => PaginationRequest(page: 0),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => PaginationRequest(page: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should copy with new values', () {
      const request = PaginationRequest(
        page: 1,
        pageSize: 20,
        filters: {'category': 'books'},
      );

      final copied = request.copyWith(
        page: 2,
        cursor: 'next_token',
      );

      expect(copied.page, equals(2));
      expect(copied.pageSize, equals(20)); // unchanged
      expect(copied.cursor, equals('next_token'));
      expect(copied.filters, equals({'category': 'books'})); // unchanged
    });

    test('should copy with all new values', () {
      const request = PaginationRequest(page: 1);

      final copied = request.copyWith(
        page: 3,
        pageSize: 50,
        cursor: 'cursor_123',
        filters: {'status': 'active'},
        extra: {'debug': true},
      );

      expect(copied.page, equals(3));
      expect(copied.pageSize, equals(50));
      expect(copied.cursor, equals('cursor_123'));
      expect(copied.filters, equals({'status': 'active'}));
      expect(copied.extra, equals({'debug': true}));
    });

    test('should maintain immutability', () {
      const request1 = PaginationRequest(page: 1);
      final request2 = request1.copyWith(page: 2);

      expect(request1.page, equals(1));
      expect(request2.page, equals(2));
      expect(identical(request1, request2), isFalse);
    });

    test('should support cursor-based pagination', () {
      const request = PaginationRequest(
        pageSize: 20,
        cursor: 'eyJpZCI6MTIzfQ==',
      );

      expect(request.cursor, isNotNull);
      expect(request.pageSize, equals(20));
    });

    test('should support filters', () {
      const request = PaginationRequest(
        page: 1,
        pageSize: 20,
        filters: {
          'category': 'electronics',
          'minPrice': 100,
          'maxPrice': 500,
          'inStock': true,
        },
      );

      expect(request.filters, isNotNull);
      expect(request.filters!['category'], equals('electronics'));
      expect(request.filters!['minPrice'], equals(100));
      expect(request.filters!['maxPrice'], equals(500));
      expect(request.filters!['inStock'], isTrue);
    });

    test('should support extra metadata', () {
      const request = PaginationRequest(
        page: 1,
        extra: {
          'sortBy': 'createdAt',
          'sortOrder': 'desc',
          'includeDeleted': false,
        },
      );

      expect(request.extra, isNotNull);
      expect(request.extra!['sortBy'], equals('createdAt'));
      expect(request.extra!['sortOrder'], equals('desc'));
      expect(request.extra!['includeDeleted'], isFalse);
    });
  });
}
