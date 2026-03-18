import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  final List<Map> products = [
    {
      "name": "Diamond Ring",
      "price": "\$299",
      "image": "https://i.imgur.com/8Km9tLL.jpg"
    }
  ];
}