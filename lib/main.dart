import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sharewheel/infoHandler/app_info.dart';
import 'package:sharewheel/screens/login_screen.dart';
import 'package:sharewheel/themeProvider/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  Platform.isAndroid?
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: "AIzaSyA8mpDMA-8qMFED6v3rwy_DBxnbPlELO2s",
        appId: "1:1031896056916:android:124ccb5c9e663f087159c1",
        messagingSenderId: "1031896056916",
        projectId: "share-wheel",

    ),
  )
  :await Firebase.initializeApp( );
  try {
    await Firebase.initializeApp();
    // FirebaseAppCheck.instance.installAppCheckProviderFactory(
    //   SafetyNetAppCheckProviderFactory(), // Choose the appropriate provider
    // );
    runApp(const MyApp());
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context)=> AppInfo(),
    child: MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      theme:MyThemes.lightTheme,
      darkTheme:MyThemes.darkTheme,
      debugShowCheckedModeBanner: false,
      home:  const LoginScreen(),
    ),
    );
  }
}




//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;
//
//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return MaterialApp(
//      title:'Flutter Demo',
//      theme: ThemeData(
//
//         colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.lightBlue).copyWith(background: Theme.of(context).colorScheme.inversePrimary),
//       ),
//       debugShowCheckedModeBanner: false,
//       home:const RegisterScreen(),// This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
