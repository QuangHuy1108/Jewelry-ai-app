import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/cart_provider.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("GIỎ HÀNG CỦA BẠN"), centerTitle: true),
      body: cart.items.isEmpty
          ? const Center(child: Text("Giỏ hàng đang trống!"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return ListTile(
                  leading: Image.network(item.product.imageUrl, width: 50, fit: BoxFit.cover),
                  title: Text(item.product.name),
                  subtitle: Text("\$${item.product.price} x ${item.quantity}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => cart.removeFromCart(item.product.id),
                  ),
                );
              },
            ),
          ),
          // Phần thanh toán tổng tiền
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng thanh toán:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("\$${cart.totalAmount}", style: const TextStyle(fontSize: 22, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    context.push('/checkout');
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: const Text("TIẾN HÀNH THANH TOÁN", style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}