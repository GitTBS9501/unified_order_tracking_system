import 'package:dio/dio.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class OrderService {
  final Dio _dio;
  
  // Mock API base URL - replace with actual API endpoint
  static const String baseUrl = 'https://api.example.com';
  
  OrderService({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Fetch all orders from the unified /orders API
  Future<List<Order>> fetchOrders({String? token}) async {
    try {
      final response = await _dio.get(
        '/orders',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> ordersJson = response.data['orders'] as List<dynamic>;
        return ordersJson
            .map((json) => Order.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Orders endpoint not found.');
      } else {
        throw Exception('Failed to load orders: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  /// Mock method to get sample orders for testing
  /// This should be removed once the actual API is available
  Future<List<Order>> fetchMockOrders() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    return [
      Order(
        orderId: 'AMZ-2024-001',
        platform: 'Amazon',
        orderDate: DateTime.now().subtract(const Duration(days: 2)),
        status: 'Delivered',
        totalAmount: 1299.99,
        items: [
          OrderItem(
            productId: 'P001',
            productName: 'Wireless Headphones',
            quantity: 1,
            price: 1299.99,
          ),
        ],
      ),
      Order(
        orderId: 'FLP-2024-002',
        platform: 'Flipkart',
        orderDate: DateTime.now().subtract(const Duration(days: 5)),
        status: 'Shipped',
        totalAmount: 2499.50,
        items: [
          OrderItem(
            productId: 'P002',
            productName: 'Smart Watch',
            quantity: 1,
            price: 2499.50,
          ),
        ],
      ),
      Order(
        orderId: 'IKEA-2024-003',
        platform: 'IKEA',
        orderDate: DateTime.now().subtract(const Duration(days: 7)),
        status: 'Processing',
        totalAmount: 4599.00,
        items: [
          OrderItem(
            productId: 'P003',
            productName: 'Office Chair',
            quantity: 1,
            price: 3999.00,
          ),
          OrderItem(
            productId: 'P004',
            productName: 'Desk Lamp',
            quantity: 1,
            price: 600.00,
          ),
        ],
      ),
      Order(
        orderId: 'AMZ-2024-004',
        platform: 'Amazon',
        orderDate: DateTime.now().subtract(const Duration(days: 10)),
        status: 'Delivered',
        totalAmount: 899.00,
        items: [
          OrderItem(
            productId: 'P005',
            productName: 'Bluetooth Speaker',
            quantity: 1,
            price: 899.00,
          ),
        ],
      ),
      Order(
        orderId: 'FLP-2024-005',
        platform: 'Flipkart',
        orderDate: DateTime.now().subtract(const Duration(days: 15)),
        status: 'Delivered',
        totalAmount: 15999.00,
        items: [
          OrderItem(
            productId: 'P006',
            productName: 'Laptop Backpack',
            quantity: 1,
            price: 1999.00,
          ),
          OrderItem(
            productId: 'P007',
            productName: 'Wireless Mouse',
            quantity: 2,
            price: 7000.00,
          ),
        ],
      ),
      Order(
        orderId: 'IKEA-2024-006',
        platform: 'IKEA',
        orderDate: DateTime.now().subtract(const Duration(days: 20)),
        status: 'Cancelled',
        totalAmount: 2999.00,
        items: [
          OrderItem(
            productId: 'P008',
            productName: 'Bookshelf',
            quantity: 1,
            price: 2999.00,
          ),
        ],
      ),
      Order(
        orderId: 'AMZ-2024-007',
        platform: 'Amazon',
        orderDate: DateTime.now().subtract(const Duration(days: 25)),
        status: 'Delivered',
        totalAmount: 599.00,
        items: [
          OrderItem(
            productId: 'P009',
            productName: 'Phone Case',
            quantity: 1,
            price: 299.00,
          ),
          OrderItem(
            productId: 'P010',
            productName: 'Screen Protector',
            quantity: 1,
            price: 300.00,
          ),
        ],
      ),
    ];
  }
}

// Made with Bob
