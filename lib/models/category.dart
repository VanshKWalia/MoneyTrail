import 'package:flutter/material.dart';
import 'package:moneytrail/models/transaction.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.asset,
    this.icon,
  });

  final String id;
  final String name;
  final TxType type;
  final Color color;
  final String? asset;
  final IconData? icon;
}
