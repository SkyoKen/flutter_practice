import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/components/cart_item.dart';
import 'package:test_app/models/cart.dart';
import 'package:test_app/models/shoe.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<Cart>(
        builder: (context, value, child) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
          crossAxisAlignment:CrossAxisAlignment.start,
              children: [
                // heading
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 25),
                  child: const Text(
                    'My Cart',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 25),
                Expanded(
                    child: ListView.builder(
                  itemCount: value.getUserCart().length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    // get individual shoe
                    Shoe individualShoe = value.getUserCart()[index];
                    return CartItem(shoe: individualShoe);
                  },
                )),
              ],
            )));
  }
}
