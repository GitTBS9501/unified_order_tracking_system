import 'package:flutter/material.dart';
import 'order_item.dart';

class Order {
  final String orderId;
  final String platform;
  final DateTime orderDate;
  final String status;
  final double totalAmount;
  final List<OrderItem> items;

  Order({
    required this.orderId,
    required this.platform,
    required this.orderDate,
    required this.status,
    required this.totalAmount,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] as String,
      platform: json['platform'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'platform': platform,
      'order_date': orderDate.toIso8601String(),
      'status': status,
      'total_amount': totalAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  // Helper method to get platform color
  static Color getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'amazon':
        return const Color(0xFFFF9900);
      case 'flipkart':
        return const Color(0xFF2874F0);
      case 'ikea':
        return const Color(0xFFFFDA1A);
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// Made with Bob
