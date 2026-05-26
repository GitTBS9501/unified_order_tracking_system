import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Order> _allOrders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedPlatform = 'All';
  Timer? _debounceTimer;

  final List<String> _platforms = ['All', 'Amazon', 'Flipkart', 'IKEA'];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load orders from API
  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      
      // Using mock orders for now - replace with actual API call when available
      // final orders = await _orderService.fetchOrders(token: token);
      final orders = await _orderService.fetchMockOrders();
      
      setState(() {
        _allOrders = orders;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Handle search text changes with debouncing
  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Only trigger search if text length >= 3 or empty
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty || searchText.length >= 3) {
      // Create new timer with 500ms delay
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _applyFilters();
      });
    }
  }

  /// Apply platform filter and search filter
  void _applyFilters() {
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        // Platform filter
        final platformMatch = _selectedPlatform == 'All' || 
            order.platform.toLowerCase() == _selectedPlatform.toLowerCase();
        
        // Search filter (by Order ID or Product Name)
        final searchText = _searchController.text.trim().toLowerCase();
        bool searchMatch = true;
        
        if (searchText.isNotEmpty && searchText.length >= 3) {
          // Search in order ID
          final orderIdMatch = order.orderId.toLowerCase().contains(searchText);
          
          // Search in product names
          final productNameMatch = order.items.any((item) => 
            item.productName.toLowerCase().contains(searchText)
          );
          
          searchMatch = orderIdMatch || productNameMatch;
        }
        
        return platformMatch && searchMatch;
      }).toList();
    });
  }

  /// Handle platform filter change
  void _onPlatformChanged(String platform) {
    setState(() {
      _selectedPlatform = platform;
      _applyFilters();
    });
  }

  /// Handle logout
  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Order ID or Product Name (min 3 chars)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Platform Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _platforms.map((platform) {
                  final isSelected = _selectedPlatform == platform;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(platform),
                      selected: isSelected,
                      onSelected: (selected) {
                        _onPlatformChanged(platform);
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[700],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue[700] : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const Divider(height: 1),

          // Order List
          Expanded(
            child: _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isNotEmpty || _selectedPlatform != 'All'
                    ? 'No orders found'
                    : 'No orders yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty || _selectedPlatform != 'All'
                    ? 'Try adjusting your filters'
                    : 'Your orders will appear here',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final platformColor = Order.getPlatformColor(order.platform);
    final statusColor = Order.getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showOrderDetails(order);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Platform badge and Order ID
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: platformColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: platformColor.withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      order.platform,
                      style: TextStyle(
                        color: platformColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.orderId,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Order Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(order.orderDate),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Items count
              Text(
                '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),

              // Divider
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),

              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final dateFormat = DateFormat('MMM dd, yyyy');
        final platformColor = Order.getPlatformColor(order.platform);
        final statusColor = Order.getStatusColor(order.status);

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Title
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Platform and Order ID
                      _buildDetailRow(
                        'Platform',
                        order.platform,
                        valueColor: platformColor,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Order ID', order.orderId),
                      const SizedBox(height: 12),
                      _buildDetailRow('Date', dateFormat.format(order.orderDate)),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Status',
                        order.status,
                        valueColor: statusColor,
                      ),
                      const SizedBox(height: 24),

                      // Items section
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...order.items.map((item) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '₹${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Made with Bob
