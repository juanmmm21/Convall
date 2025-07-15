/*
 * @author: Juan Martos Cuevas
 */

import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:convall/pagina_audio.dart';
import 'package:convall/pagina_imagen.dart';
import 'package:convall/pagina_video.dart';



/// Esta es la página principal de la aplicación.
/// Contiene un BottomNavigationBar que permite navegar entre diferentes páginas de conversión (video, imagen y audio), ademas
/// de un botón de refresco que reinicia la página actual.

class ConversorPaginaPrincipal extends StatefulWidget {
  const ConversorPaginaPrincipal({super.key});

  @override
  State<ConversorPaginaPrincipal> createState() =>
      ConversorPaginaPrincipalState();
}

class ConversorPaginaPrincipalState extends State<ConversorPaginaPrincipal> {

  // Colores principales de la aplicación
  static const Color FloralWhite = Color(0xFFFFFCF2);
  static const Color Timberwolf = Color(0xFFCCC5B9);
  static const Color BlackOlive = Color(0xFF403D39);
  static const Color EerieBlack = Color(0xFF252422);
  static const Color Flame = Color(0xFFEB5E28);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0; // Página seleccionada



  // Lista de constructores para regenerar las páginas
  final List<Widget Function(Key)> _pageBuilders = [
        (key) => paginaVideo(key: key),
        (key) => paginaImagen(key: key),
        (key) => paginaAudio(key: key),
  ];

  // Lista que almacena las instancias actuales de las páginas con Keys únicas
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = List.generate(
      _pageBuilders.length,
          (index) => _pageBuilders[index](UniqueKey()),
    );
  }

  /// Manejar el cambio de página al tocar un elemento del BottomNavigationBar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Reiniciar la página actual generando una nueva instancia de la misma
  void _resetCurrentPage() {
    setState(() {
      _pages[_selectedIndex] = _pageBuilders[_selectedIndex](UniqueKey()); // Reinicia la página actual con una nueva Key
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,

      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),


          // Botón de refresco
          Positioned(
            top: 70,
            right: 20,
            child: FloatingActionButton(
              onPressed: _resetCurrentPage,
              backgroundColor: Flame,
              child: Icon(Icons.refresh_rounded, color: FloralWhite),
              mini: true,
            ),
          ),



          // BottomNavigationBar para seleccionar la página
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Timberwolf.withOpacity(0.7),
                  selectedIconTheme: IconThemeData(
                    color: EerieBlack,
                    opacity: 1,
                    size: 35,
                  ),
                  unselectedIconTheme: IconThemeData(
                    color: BlackOlive,
                    opacity: 0.5,
                    size: 30,
                  ),
                  selectedLabelStyle: TextStyle(
                    color: EerieBlack,
                    fontFamily: 'SF-ProText-Heavy',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: TextStyle(
                    color: BlackOlive,
                    fontFamily: 'SF-ProText-Semibold',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.video_camera_back_rounded),
                        label: 'Video'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.image), label: 'Imagen'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.audiotrack_rounded), label: 'Audio'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


























