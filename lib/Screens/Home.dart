import 'package:flutter/material.dart';
import 'package:neerad_store/Styles/Stylebook.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing', style: Stylebook.heading1)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Item ID:  ', style: Stylebook.heading2),
                SizedBox(
                  width: 250, // ← fixed width here
                  height: 50,
                  child: TextField(
                    decoration: InputDecoration(
                        hintText: 'Scan the Bar code here!',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        )
                      ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Item Name:  ', style: Stylebook.heading2),
                SizedBox(
                  width: 250, // ← fixed width here
                  height: 50,
                  child: TextField(
                    decoration: InputDecoration(
                        hintText: 'Type the item to search here',
                        border: OutlineInputBorder()
                      ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
