import 'package:flutter/material.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: Column(
        children: [
          const Text("Total: \$299"),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Pay Now"),
          )
        ],
      ),
    );
  }
}