import 'package:flutter/material.dart';
import 'package:neerad_store/Styles/Stylebook.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing', style: Stylebook.heading1)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text('Item Name:  ', style: Stylebook.heading2),
            Expanded(child: 
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter the name of the product:',
                border: OutlineInputBorder(),
              ),
              )
            ),
          ],
        ),
        
      ),
    );
  }
}
