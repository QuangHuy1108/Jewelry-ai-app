import 'package:flutter/material.dart';

class ProductProvider extends ChangeNotifier {
  final List<Map> products = [
    {
      "name": "Diamond Ring",
      "price": "\$299",
      "image": "https://i.postimg.cc/4yh339Lk/h7.jpg"
    }
  ];
}