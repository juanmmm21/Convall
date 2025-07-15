/*
 * @author: Juan Martos Cuevas
 */

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'CloudConvertService.dart';
import 'drawer_widget.dart';
import 'package:path/path.dart' as p;


/// Esta pagina es la encargada de la conversión de videos.
/// Una vez has abierto un archivo, se muestra un reproductor y todas las
/// opciones de conversión disponibles personalizadas para tu archivo.

class paginaVideo extends StatefulWidget {
  const paginaVideo({super.key});

  @override
  State<paginaVideo> createState() => _paginaVideoState();
}

class _paginaVideoState extends State<paginaVideo> {

  // Colores principales de la aplicación
  static const Color FloralWhite = Color(0xFFFFFCF2);
  static const Color Timberwolf = Color(0xFFCCC5B9);
  static const Color BlackOlive = Color(0xFF403D39);
  static const Color EerieBlack = Color(0xFF252422);
  static const Color Flame = Color(0xFFEB5E28);

  // Lista de elementos convertidos en la sesión actual
  List<CloudConvertService> elementos = [];

  // Variables para almacenar el archivo de video y su información
  File? _videoFile;
  String? _selectedFilePath;
  String? _videoFormat;
  int? _altoOriginal;
  int? _anchoOriginal;

  // Controlador de video para reproducir el video seleccionado
  VideoPlayerController? _videoController;

  // Parametros de salida
  String? _outputFormat;
  String? _outputCodec;
  double? _crf = 23;
  int? _outputHeight;
  int? _outputWidth;
  String? _outputAudioCodec;

  // Posibles formatos de salida
  List<String> _outputFormats = ['mp4', 'avi', 'webm', 'mkv', 'flv'];

  // Posibles codecs de video y audio para cada formato
  List<String> _mp4Codecs = ['copy', 'x264', 'x265', 'av1'];
  List<String> _aviCodecs = ['copy', 'x264', 'x265', 'xvid'];
  List<String> _webmCodecs = ['vp8', 'vp9', 'av1'];
  List<String> _mkvCodecs = ['copy', 'x264', 'x265', 'vp8', 'vp9', 'av1'];
  List<String> _flvCodecs = ['copy', 'h264', 'sorenson'];

  List<String> _audioCodecs = ['copy', 'none', 'aac', 'aac_he_1', 'aac_he_2', 'opus', 'vorbis'];
  List<String> _webmAudioCodecs = ['none', 'opus', 'vorbis'];


  /// Verifica si el botón de descarga debería estar habilitado o no.
  bool isReadyToDownload()
  {
    if(_outputFormat == null)
    {
      return false;
    }
    else
    {
      return true;
    }
  }

  /// Abre el selector de archivos para elegir un audio.
  /// Una vez seleccionado, se inicializa el reproductor y se obtienen los datos del archivo.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      String filePath = result.files.single.path!;
      _videoFormat = await _identifyVideoFormat(filePath);
      print(filePath);

      _videoController?.dispose();
      _videoController = VideoPlayerController.file(File(filePath))
        ..initialize().then((_) {
          setState(() {
            _selectedFilePath = filePath;
            _videoFile = File(filePath);
            _altoOriginal = _videoController!.value.size.height.toInt();
            _anchoOriginal = _videoController!.value.size.width.toInt();
          });
        });
    }

  }

  /// Sube todos los parametros para la conversión a la clase CloudConvertService
  /// Si hay parametros que el usuario no ha seleccionado, se ponen por defecto.
  void _convertVideo()
  {
    if(_videoFile != null)
    {
      if(_outputFormat == 'webm')
      {
        _outputCodec ??= 'vp8';
        _outputAudioCodec ??= 'opus';
      }
      _outputCodec ??= 'copy';
      _outputAudioCodec ??= 'copy';
      CloudConvertService ccs1 = CloudConvertService();
      ccs1.fileUpload(context, _videoFile!, _videoFormat!,
        outputformat: _outputFormat!,
        videoCodec: _outputCodec!,
        crf: _crf!.toInt(),
        width: _outputWidth,
        height: _outputHeight,
        audioCodec: _outputAudioCodec!
      );

      setState(() {
        elementos.add(ccs1);
      });

    }
    else
    {
      print('No se ha seleccionado un archivo de video');
    }
  }

  /// Identifica el formato del video a partir de su firma.
  Future<String> _identifyVideoFormat(String filepath) async {
    final file = File(filepath);
    final bytes = await file.readAsBytes();

    const Map<String, List<int>> firmasDeVideo = {
      'mp4': [0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70],
      'avi': [0x52, 0x49, 0x46, 0x46],
      'webm/mkv': [0x1A, 0x45, 0xDF, 0xA3],
      'flv': [0x46, 0x4C, 0x56, 0x01],
    };

    for (var formato in firmasDeVideo.keys) {
      final firma = firmasDeVideo[formato];

      if (_empiezaCon(bytes, firma!)) {
        return formato;
      }
    }

    return detectarFormatoArchivo(filepath);
  }

  String detectarFormatoArchivo(String path) {
    final nombreArchivo = p.basename(path);
    final partes = nombreArchivo.split('.');
    if (partes.length < 2) {
      return 'desconocido';
    }
    return partes.last.toLowerCase();
  }

  bool _empiezaCon(Uint8List bytes, List<int> firma) {
    if (bytes.length < firma.length) return false;
    for (int i = 0; i < firma.length; i++) {
      if (bytes[i] != firma[i]) return false;
    }
    return true;
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FloralWhite,

      // Menu lateral de conversiones
      drawer: DrawerWidget(elementos: elementos),

      // Logo arriba en grande
      appBar: AppBar(
        title: const Text(
          'Convall',
          style: TextStyle(
            color: Flame,
            fontSize: 100,
            fontFamily: 'Outward'
          ),
        ),
        centerTitle: true,
        toolbarHeight: 100,
        backgroundColor: FloralWhite,
        leading: Builder(
          builder: (context) => Align(
            alignment: Alignment(1.6, -0.3),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Material(
                color: Flame,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Center(
                    child: Icon(
                      Icons.archive_rounded,
                      color: FloralWhite,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),



      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  // Al hacer click en el icono, se abre el selector de archivos
                  // Si ya hay un video seleccionado, se reproduce o pausa
                  onTap: () {
                    if (_videoController != null && _videoController!.value.isInitialized) {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                    } else {
                      _pickFile();
                    }
                  },
                  child: _selectedFilePath == null
                      ? Column(
                      children: [
                        const SizedBox(height: 100),
                        Icon(Icons.add_box_outlined, size: 200, color: EerieBlack)
                      ]
                      )
                      : Column(
                    children: [

                      // Reproductor de video
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 400,
                                  maxHeight: 400,
                                  minHeight: 200,
                                  minWidth: 200,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                    if(!_videoController!.value.isPlaying)
                                      Icon(Icons.play_circle_fill, size: 50, color: Colors.white),
                                  ],
                                ),
                            );
                          },
                        ),
                      ),

                      // Indica el formato del video
                      Container(
                        width: 100,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Flame,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        ),
                        child: Center(
                          child: Text(
                            '$_videoFormat'.toUpperCase(),
                            style: TextStyle(
                              color: FloralWhite,
                              fontSize: 21,
                              fontFamily: 'SF-ProText-Heavy',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),


                      if(_selectedFilePath != null) ...[


                        //Muestra una lista para seleccionar un formato de salida

                        DropdownButtonFormField<String>(
                          value: _outputFormat,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Timberwolf,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: EerieBlack, width: 2),
                            ),
                          ),
                          hint: Text(
                            "Selecciona un formato de salida",
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                          ),
                          icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                          dropdownColor: Timberwolf,
                          items: _outputFormats.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                            );
                          }).toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return _outputFormats.map((String value) {
                              return Text(
                                'Formato seleccionado: ${value.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700,
                                  fontFamily: 'SF-ProText-Heavy',
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                          onChanged: (String? value) {
                            setState(() {
                              _outputFormat = value;
                            });
                          },
                        ),



                        const SizedBox(height: 20),

                        // Muestra una lista de codecs de video dependiendo del formato seleccionado

                        if(_outputFormat == 'mp4') ...[
                          DropdownButtonFormField<String>(
                            value: _outputCodec,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Timberwolf,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: EerieBlack, width: 2),
                              ),
                            ),
                            hint: Text(
                              "Selecciona un codec",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                            dropdownColor: Timberwolf,
                            items: _mp4Codecs.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _mp4Codecs.map((String value) {
                                return Text(
                                  'Codec de video seleccionado: ${value.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (String? value) {
                              setState(() {
                                _outputCodec = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        if(_outputFormat == 'avi') ...[
                          DropdownButtonFormField<String>(
                            value: _outputCodec,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Timberwolf,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: EerieBlack, width: 2),
                              ),
                            ),
                            hint: Text(
                              "Selecciona un codec",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                            dropdownColor: Timberwolf,
                            items: _aviCodecs.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _aviCodecs.map((String value) {
                                return Text(
                                  'Codec de video seleccionado: ${value.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (String? value) {
                              setState(() {
                                _outputCodec = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        if(_outputFormat == 'webm') ...[
                          DropdownButtonFormField<String>(
                            value: _outputCodec,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Timberwolf,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: EerieBlack, width: 2),
                              ),
                            ),
                            hint: Text(
                              "Selecciona un codec",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                            dropdownColor: Timberwolf,
                            items: _webmCodecs.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _webmCodecs.map((String value) {
                                return Text(
                                  'Codec de video seleccionado: ${value.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (String? value) {
                              setState(() {
                                _outputCodec = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                        ],


                        if(_outputFormat == 'mkv') ...[
                          DropdownButtonFormField<String>(
                            value: _outputCodec,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Timberwolf,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: EerieBlack, width: 2),
                              ),
                            ),
                            hint: Text(
                              "Selecciona un codec",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                            dropdownColor: Timberwolf,
                            items: _mkvCodecs.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _mkvCodecs.map((String value) {
                                return Text(
                                  'Codec de video seleccionado: ${value.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (String? value) {
                              setState(() {
                                _outputCodec = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        if(_outputFormat == 'flv') ...[
                          DropdownButtonFormField<String>(
                            value: _outputCodec,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Timberwolf,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: EerieBlack, width: 2),
                              ),
                            ),
                            hint: Text(
                              "Selecciona un codec",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                            dropdownColor: Timberwolf,
                            items: _flvCodecs.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _flvCodecs.map((String value) {
                                return Text(
                                  'Codec de video seleccionado: ${value.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (String? value) {
                              setState(() {
                                _outputCodec = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Barra deslizable para aumentar o reducir la compresión de video

                        Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Timberwolf,
                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Column(
                              children: [

                                Text(
                                  'CRF - Compresión del video',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade700,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                Slider(
                                  value: _crf!,
                                  year2023: false,
                                  min: 0,
                                  max: 51,
                                  divisions: 51,
                                  label: _crf?.toInt().toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      _crf = value;
                                    });
                                  },
                                  activeColor: Flame,
                                  inactiveColor: BlackOlive,
                                  //thumbColor: Colors.transparent,
                                  overlayColor: MaterialStateProperty.resolveWith<Color?>(
                                        (Set<MaterialState> states) {
                                      if (states.contains(MaterialState.pressed)) {
                                        // Si está presionado, usa un color semitransparente
                                        return Colors.transparent;
                                      }
                                      return Colors.transparent; // Sin color cuando no está presionado
                                    },
                                  ),

                                ),
                              ],
                            )
                        ),

                        const SizedBox(height: 20),

                        // Campos de texto para especificar la resolución del video

                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Timberwolf,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [

                              Text(
                                'Resolución',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'SF-ProText-Heavy',
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade700,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                        padding: EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: FloralWhite,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Ancho',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'SF-ProText-Heavy',
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            SizedBox(width: 16), // Add some spacing between the text and the text field
                                            Expanded(
                                              child: TextField(
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  hintText: '${_anchoOriginal.toString()}',
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _outputWidth = int.tryParse(value);
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  Expanded(
                                    child: Container(
                                        padding: EdgeInsets.all(16.0),
                                        decoration: BoxDecoration(
                                          color: FloralWhite,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Alto',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontFamily: 'SF-ProText-Heavy',
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            SizedBox(width: 16), // Add some spacing between the text and the text field
                                            Expanded(
                                              child: TextField(
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  hintText: '${_altoOriginal.toString()}',
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _outputHeight = int.tryParse(value);
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                    ),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),

                        // Se muestra una lista de codecs de audio dependiendo del formato de salida

                        if(_outputFormat == 'webm') ...[

                          const SizedBox(height: 20),

                          DropdownButtonFormField<String>(
                            value: _outputAudioCodec,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Timberwolf,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: EerieBlack, width: 2),
                              ),
                            ),
                            hint: Text(
                              "Selecciona un Codec de audio",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                            dropdownColor: Timberwolf,
                            items: _webmAudioCodecs.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _webmAudioCodecs.map((String value) {
                                return Text(
                                  'Codec de audio seleccionado: ${value.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (String? value) {
                              setState(() {
                                _outputAudioCodec = value;
                              });
                            },
                          ),


                        ],

                        if(_outputFormat != 'webm') ...[

                          const SizedBox(height: 20),


                          DropdownButtonFormField<String>(
                            value: _outputAudioCodec,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Timberwolf,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: EerieBlack, width: 2),
                              ),
                            ),
                            hint: Text(
                              "Selecciona un Codec de audio",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                            dropdownColor: Timberwolf,
                            items: _audioCodecs.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value.toUpperCase(), style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _audioCodecs.map((String value) {
                                return Text(
                                  'Codec de audio seleccionado: ${value.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade700,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (String? value) {
                              setState(() {
                                _outputAudioCodec = value;
                              });
                            },
                          ),


                        ],



                      ],



                      // Boton de descarga

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: isReadyToDownload() ? _convertVideo : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReadyToDownload() ? BlackOlive : BlackOlive.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                          elevation: 2,
                        ),
                        child: const Text(
                          'DESCARGAR',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // Texto en blanco para buen contraste
                            fontFamily: 'SF-ProText-Heavy', // Mismo estilo que otros textos
                          ),
                        ),
                      ),

                      const SizedBox(height: 100),





                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),


    );
  }
}
