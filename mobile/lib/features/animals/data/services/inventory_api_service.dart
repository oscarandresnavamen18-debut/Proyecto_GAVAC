import '../../../../core/network/api_client.dart';
import '../../../../core/utils/app_session.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.quantity,
    required this.minimumQuantity,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
        id: json['id'] as int,
        name: json['name'] as String,
        category: json['category'] as String,
        unit: json['unit'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        minimumQuantity: (json['minimum_quantity'] as num).toDouble(),
      );

  final int id;
  final String name;
  final String category;
  final String unit;
  final double quantity;
  final double minimumQuantity;

  bool get isLowStock => quantity <= minimumQuantity;
}

abstract interface class InventoryRepository {
  Future<List<InventoryItem>> listItems();
  Future<InventoryItem> createItem(String name, double quantity);
  Future<void> deactivateItem(int id);
}

class InventoryApiService implements InventoryRepository {
  const InventoryApiService();

  String get _token {
    final token = AppSession.accessToken;
    if (token == null || token.isEmpty) {
      throw const ApiException(
          401, 'Inicia sesión para consultar el inventario.');
    }
    return token;
  }

  @override
  Future<List<InventoryItem>> listItems() async {
    final response = await ApiClient.get('/api/v1/inventory', token: _token);
    if (response is! List) {
      throw const FormatException('La respuesta del inventario no es válida.');
    }
    return response
        .map(
          (item) => InventoryItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  Future<InventoryItem> createItem(String name, double quantity) async {
    final response = await ApiClient.post(
      '/api/v1/inventory',
      {
        'name': name,
        'category': 'GENERAL',
        'unit': 'unidades',
        'quantity': quantity,
      },
      token: _token,
    );
    return InventoryItem.fromJson(response);
  }

  @override
  Future<void> deactivateItem(int id) =>
      ApiClient.delete('/api/v1/inventory/$id', token: _token);
}
