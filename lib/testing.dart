import 'package:flutter/material.dart';

class testing extends StatelessWidget {
  const testing({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proot Remote'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Column(children: [
            Image.network('https://placehold.co/300x300.png?text=Proot+Here')
          ]),
        ),
      ),
    );
  }
}
