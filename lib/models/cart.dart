import 'package:flutter/material.dart';
import 'package:test_app/models/shoe.dart';

class Cart extends ChangeNotifier{
  // list of shoes for sale
  List<Shoe> shoeShop = [
    Shoe(
        name: 'Zoom FREAK',
        price: "236",
        description:
            "The forward-thinking design of his latest signature shoe.",
        imagePath: 'lib/images/logo.jpg'),
    Shoe(
        name: "Air Jordan",
        price: "1000",
        description: "cool shoe",
        imagePath: "lib/images/logo.jpg")
  ];

// list of imtes in user cart
  List<Shoe> userCart = [];

  // get list of shoes for sale
  List<Shoe> getShoeList(){
    return shoeShop;
  }

  // get cart
  List<Shoe> getUserCart(){
    return userCart;
  }

  // add items to cart
  void addItemToCart(Shoe shoe){
    userCart.add(shoe);
    notifyListeners();
  }

  // remove item from cart
  void removeItemFromCart(Shoe shoe){
    userCart.remove(shoe);
    notifyListeners();
  }
}
