/*
 * @author: Juan Martos Cuevas
 */

import 'package:flutter/material.dart';
import 'package:convall/conversor_pagina_principal.dart';


class ConversorApp extends StatelessWidget {
  const ConversorApp({super.key});


  @override
  Widget build(BuildContext context) {
    // 2
    return MaterialApp(
      title: 'Convall',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      debugShowCheckedModeBanner: false,
      // 3
      home: const ConversorPaginaPrincipal(),
    );


  }
}
