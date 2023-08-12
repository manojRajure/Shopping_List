import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';

import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItem = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
    final url = Uri.https(
        'flutter-pre-88c0c-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list.json');
    try {
      final response = await http.get(url);

      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (response.statusCode >= 400) {
        setState(() {
          _error = 'Failed to fatch data. Please try again later.';
        });
      }
      final Map<String, dynamic> listData = json.decode(response.body);

      final List<GroceryItem> loadedItem = [];
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (catItem) => catItem.value.title == item.value['category'])
            .value;
        loadedItem.add(
          GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItem = loadedItem;
        _isLoading = false;
      });
    } catch (er) {
      setState(() {
        _error = 'Something went worng. Please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItem.add(newItem);
    });
  }

  void _removedItem(GroceryItem item) async {
    final index = _groceryItem.indexOf(item);
    setState(() {
      _groceryItem.remove(item);
    });
    final url = Uri.https(
        'flutter-pre-88c0c-default-rtdb.asia-southeast1.firebasedatabase.app',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItem.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No item added yet!'),
    );

    if (_error != null) {
      content = Center(
        child: Text(_error!),
      );
    }

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removedItem(_groceryItem[index]);
          },
          key: ValueKey(_groceryItem[index].id),
          child: ListTile(
            title: Text(_groceryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItem[index].category.color,
            ),
            trailing: Text(
              _groceryItem[index].quantity.toString(),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
