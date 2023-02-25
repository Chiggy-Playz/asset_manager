import 'screens/home/home.dart';
import 'services/database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'shared/constants.dart';

import 'models/asset.dart';
import 'models/model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(builder: (context, orientation, screenType) {
      return MultiProvider(
          providers: [
            StreamProvider<List<Asset>>.value(
              value: DatabaseService().assets,
              initialData: const [],
            ),
            StreamProvider<List<Model>>.value(
              value: DatabaseService().models,
              initialData: const [],
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
            darkTheme:
                ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
            home: const Home(),
          ));
    });
  }
}
