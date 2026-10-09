import 'package:flutter/material.dart';
import 'package:moneytrail/app.dart';
import 'package:moneytrail/data/transaction_repository.dart';
import 'package:moneytrail/providers/settings_provider.dart';
import 'package:moneytrail/providers/transaction_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsProvider(prefs);
  final transactions = TransactionProvider(SharedPrefsTransactionRepository(prefs));
  await transactions.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<TransactionProvider>.value(value: transactions),
      ],
      child: const MoneyTrailApp(),
    ),
  );
}
