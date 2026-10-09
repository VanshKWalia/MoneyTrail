import 'package:flutter/material.dart';
import 'package:moneytrail/models/category.dart';
import 'package:moneytrail/models/transaction.dart';

/// Static catalogue of categories. Ids are what get persisted, so never rename them.
class Categories {
  Categories._();

  static const List<Color> _palette = [
    Color(0xFFE53935),
    Color(0xFF8E24AA),
    Color(0xFF3949AB),
    Color(0xFF039BE5),
    Color(0xFF00897B),
    Color(0xFF7CB342),
    Color(0xFFFFB300),
    Color(0xFFF4511E),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
    Color(0xFFD81B60),
    Color(0xFF00ACC1),
  ];

  static Category _expense(int i, String id, String name, {String? asset}) {
    return Category(
      id: id,
      name: name,
      type: TxType.expense,
      color: _palette[i % _palette.length],
      asset: 'assets/images/${asset ?? id}.png',
    );
  }

  static final List<Category> expense = [
    _expense(0, 'food', 'Food'),
    _expense(1, 'vegetables', 'Vegetables'),
    _expense(2, 'fruits', 'Fruits'),
    _expense(3, 'snacks', 'Snacks'),
    _expense(4, 'wine', 'Drinks'),
    _expense(5, 'shopping', 'Shopping'),
    _expense(6, 'clothing', 'Clothing'),
    _expense(7, 'beauty', 'Beauty'),
    _expense(8, 'travel', 'Travel'),
    _expense(9, 'transportation', 'Transport'),
    _expense(10, 'car', 'Car'),
    _expense(11, 'home', 'Home'),
    _expense(0, 'bills', 'Bills'),
    _expense(1, 'telephone', 'Phone'),
    _expense(2, 'entertainment', 'Fun'),
    _expense(3, 'sports', 'Sports'),
    _expense(4, 'health', 'Health'),
    _expense(5, 'education', 'Education'),
    _expense(6, 'book', 'Books'),
    _expense(7, 'pets', 'Pets'),
    _expense(8, 'baby', 'Baby'),
    _expense(9, 'gift', 'Gifts'),
    _expense(10, 'social', 'Social'),
    _expense(11, 'office', 'Office'),
    _expense(0, 'electronics', 'Electronics'),
    _expense(1, 'maintenance', 'Repairs'),
    _expense(2, 'tax', 'Tax'),
    _expense(3, 'insurance', 'Insurance', asset: 'ensurance'),
    _expense(4, 'others', 'Others'),
  ];

  static final List<Category> income = [
    const Category(
      id: 'in_salary',
      name: 'Salary',
      type: TxType.income,
      color: Color(0xFF2E7D32),
      icon: Icons.payments,
    ),
    const Category(
      id: 'in_freelance',
      name: 'Freelance',
      type: TxType.income,
      color: Color(0xFF00838F),
      icon: Icons.laptop_mac,
    ),
    const Category(
      id: 'in_investment',
      name: 'Investments',
      type: TxType.income,
      color: Color(0xFF6A1B9A),
      icon: Icons.trending_up,
    ),
    const Category(
      id: 'in_gift',
      name: 'Gift',
      type: TxType.income,
      color: Color(0xFFD81B60),
      asset: 'assets/images/gift.png',
    ),
    const Category(
      id: 'in_other',
      name: 'Other',
      type: TxType.income,
      color: Color(0xFF546E7A),
      asset: 'assets/images/others.png',
    ),
  ];

  static final Map<String, Category> _byId = {
    for (final c in [...expense, ...income]) c.id: c,
  };

  static Category byId(String id) => _byId[id] ?? _byId['others']!;

  static List<Category> forType(TxType type) =>
      type == TxType.expense ? expense : income;
}
