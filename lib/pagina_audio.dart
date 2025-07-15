/*
 * @author: Juan Martos Cuevas
 */

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'CloudConvertService.dart';
import 'drawer_widget.dart';


/// Esta pagina es la encargada de la conversión de audios.
/// Una vez has abierto un archivo, se muestra un reproductor y todas las
/// opciones de conversión disponibles personalizadas para tu archivo.

class paginaAudio extends StatefulWidget {
  const paginaAudio({super.key});

  @override
  State<paginaAudio> createState() => _paginaAudioState();
}

class _paginaAudioState extends State<paginaAudio> {

  // Colores principales de la aplicación
  static const Color FloralWhite = Color(0xFFFFFCF2);
  static const Color Timberwolf = Color(0xFFCCC5B9);
  static const Color BlackOlive = Color(0xFF403D39);
  static const Color EerieBlack = Color(0xFF252422);
  static const Color Flame = Color(0xFFEB5E28);



  // Variables para el reproductor
  late AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;


  // Datos del audio seleccionado
  File? _audioFile;
  String? _selectedFilePath;
  String? _audioFormat;
  String? _audioDuration;

  // Variables para la conversión
  String? _outputFormat;
  String? _outputAudioCodec;
  int? _outputAudioBitrate = 128;
  double? _outputVolume = 1.0;
  int? _outputSampleRate = 44100;
  String? _outputTrimStart = '00:00:00';
  String? _outputTrimEnd;
  String? _outputEngine = 'ffmpeg';

  // Posibles formatos de salida
  List<String> _outputFormats = ['mp3', 'aac', 'flac', 'm4a', 'wav', 'aiff'];
  List<String> _mp3AudioCodecs = ['mp3'];
  List<String> _aacAudioCodecs = ['aac', 'aac_he_1', 'aac_he_2'];
  List<String> _flacAudioCodecs = ['flac'];
  List<String> _m4aAudioCodecs = ['aac', 'aac_he_1', 'aac_he_2'];
  List<String> _wavAudioCodecs = ['pcm_s16le', 'pcm_s24le', 'pcm_s32le'];
  List<String> _aiffAudioCodecs = ['pcm_s16le', 'pcm_s24le', 'pcm_s32le'];

  // Posibles motores de conversión
  List<String> _outputEngines = ['ffmpeg'];

  // Lista de elementos convertidos en la sesión actual
  List<CloudConvertService> elementos = [];


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

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  /// Abre el selector de archivos para elegir un audio.
  /// Una vez seleccionado, se inicializa el reproductor y se obtienen los datos del archivo.
  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null && result.files.single.path != null) {
      _selectedFilePath = result.files.single.path;
      _audioFile = File(_selectedFilePath!);
      _audioFormat = _getAudioFormat(_selectedFilePath!);
      _player = AudioPlayer();
      await _player!.setFilePath(_selectedFilePath!);

      setState(() {
        _selectedFilePath = result.files.single.path;
        _audioFormat = _getAudioFormat(_selectedFilePath!);
        _audioDuration = _player.duration.toString();
        _outputTrimEnd = _audioDuration;
      });

      print('DURACION DEL AUDIO: $_audioDuration');

      _player.durationStream.listen((d) {
        if (d != null) {
          setState(() {
            _duration = d;
          });
        }
      });

      _player.positionStream.listen((p) {
        setState(() {
          _position = p;
        });
      });

    }
  }

  /// Obtiene el formato del audio a partir de la ruta del archivo.
  String _getAudioFormat(String path) {
    final extension = path.split('.').last;
    return extension;
  }

  /// Obtiene la duración del audio en formato de texto.
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  /// Sube todos los parametros para la conversión a la clase CloudConvertService
  /// Si hay parametros que el usuario no ha seleccionado, se ponen por defecto.
  void _convertAudio()
  {
    if(_audioFile != null)
    {
      if(_outputFormat == 'mp3'){_outputAudioCodec ??= 'mp3';}
      if(_outputFormat == 'aac'){_outputAudioCodec ??= 'aac';}
      if(_outputFormat == 'flac'){_outputAudioCodec ??= 'flac';}
      if(_outputFormat == 'm4a'){_outputAudioCodec ??= 'aac';}
      if(_outputFormat == 'wav'){_outputAudioCodec ??= 'pcm_s16le';}
      if(_outputFormat == 'aiff'){_outputAudioCodec ??= 'pcm_s16le';}

      _outputEngine ??= 'ffmpeg';
      CloudConvertService ccs1 = CloudConvertService();
      ccs1.fileUpload(context, _audioFile!, _audioFormat!,
        outputformat: _outputFormat,
        audioCodec: _outputAudioCodec,
        audioBitrate: _outputAudioBitrate,
        volume: _outputVolume,
        sample_rate: _outputSampleRate,
        trim_start: _outputTrimStart,
        trim_end: _outputTrimEnd,
        engine: _outputEngine,
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
                  onTap: _pickAudio,
                  child: _selectedFilePath == null
                      ? Column(
                      children: [
                        const SizedBox(height: 100),
                        Icon(Icons.add_box_outlined, size: 200, color: EerieBlack)
                      ]
                    )
                      : Column(
                        children: [

                          // Reproductor de audio
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Timberwolf,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                              ],
                            ),
                            child: Row(
                              children: [
                                StreamBuilder<PlayerState>(
                                  stream: _player!.playerStateStream,
                                  builder: (context, snapshot) {
                                    final isPlaying = snapshot.data?.playing ?? false;
                                    return IconButton(
                                      icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40, color: EerieBlack),
                                      onPressed: () => isPlaying ? _player!.pause() : _player!.play(),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: StreamBuilder<Duration>(
                                    stream: _player!.positionStream,
                                    builder: (context, snapshot) {
                                      final position = snapshot.data ?? Duration.zero;
                                      return StreamBuilder<Duration?>(
                                        stream: _player!.durationStream,
                                        builder: (context, snapshot) {
                                          final duration = snapshot.data ?? Duration.zero;

                                          return SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              thumbColor: Flame, // Círculo rojo
                                              activeTrackColor: BlackOlive, // Línea activa
                                              inactiveTrackColor: Colors.grey[300], // Línea inactiva
                                              overlayColor: Colors.red.withAlpha(32),
                                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
                                              trackHeight: 4,
                                            ),
                                            child: Slider(
                                              min: 0,
                                              max: _duration.inMilliseconds.toDouble(),
                                              value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                                              onChanged: (value) async {
                                                final newPosition = Duration(milliseconds: value.round());
                                                await _player?.seek(newPosition);
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 120,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: FloralWhite,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 4,
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Text(
                                      "${_formatDuration(_position)} / ${_formatDuration(_duration)}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'SF-ProText-Semibold',
                                      ),
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),

                          // Indica el formato del audio
                          Container(
                            width: 100,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Flame,
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                            ),
                            child: Center(
                              child: Text(
                                '$_audioFormat',
                                style: TextStyle(
                                  color: FloralWhite,
                                  fontSize: 21,
                                  fontFamily: 'SF-ProText-Heavy',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),

                          //Muestra una lista para seleccionar un formato de salida
                          const SizedBox(height: 20),
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
                                child: Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _outputFormats.map((String value) {
                                return Text(
                                  'Formato de salida seleccionado: ${value.toUpperCase()}',
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
                                _outputAudioCodec = null;
                              });
                            },
                          ),


                          // A partir de aqui, se muestra una lista de codecs para cada uno de los formatos de audio de salida

                          if (_outputFormat == 'mp3') ... [

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
                              items: _mp3AudioCodecs.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return _mp3AudioCodecs.map((String value) {
                                  return Text(
                                    'Formato de salida seleccionado: ${value.toUpperCase()}',
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


                          if (_outputFormat == 'aac') ... [

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
                              items: _aacAudioCodecs.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return _aacAudioCodecs.map((String value) {
                                  return Text(
                                    'Formato de salida seleccionado: ${value.toUpperCase()}',
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

                          if (_outputFormat == 'flac') ... [

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
                              items: _flacAudioCodecs.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return _flacAudioCodecs.map((String value) {
                                  return Text(
                                    'Formato de salida seleccionado: ${value.toUpperCase()}',
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


                          if (_outputFormat == 'm4a') ... [

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
                              items: _m4aAudioCodecs.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return _m4aAudioCodecs.map((String value) {
                                  return Text(
                                    'Formato de salida seleccionado: ${value.toUpperCase()}',
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


                          if (_outputFormat == 'wav') ... [

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
                              items: _wavAudioCodecs.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return _wavAudioCodecs.map((String value) {
                                  return Text(
                                    'Formato de salida seleccionado: ${value.toUpperCase()}',
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


                          if (_outputFormat == 'aiff') ... [

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
                              items: _aiffAudioCodecs.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                                );
                              }).toList(),
                              selectedItemBuilder: (BuildContext context) {
                                return _aiffAudioCodecs.map((String value) {
                                  return Text(
                                    'Formato de salida seleccionado: ${value.toUpperCase()}',
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

                          const SizedBox(height: 20),

                          // Muestra un campo para seleccionar el bitrate de salida

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Timberwolf,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Audio Bitrate',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: BlackOlive,
                                      fontFamily: 'SF-ProText-Heavy',
                                      fontWeight: FontWeight.w600,
                                  ),
                                ),

                                SizedBox(
                                  width: 120,
                                  child: Container(
                                    alignment: Alignment.bottomRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FloralWhite,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 4,
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: '${_outputAudioBitrate.toString()}',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _outputAudioBitrate = int.tryParse(value);
                                        });
                                      },
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Barra deslizable para aumentar o reducir el volumen

                          Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Timberwolf,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 4,
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),

                              child: Column(
                                children: [

                                  Text(
                                    'Volumen',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'SF-ProText-Heavy',
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  Slider(
                                    value: _outputVolume!,
                                    year2023: false,
                                    min: 0,
                                    max: 2,
                                    divisions: 20,
                                    label: _outputVolume?.toString(),
                                    onChanged: (double value) {
                                      setState(() {
                                        _outputVolume = value;
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

                          // Campo para seleccionar la frecuencia de muestreo de salida

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: Timberwolf,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Sample Rate',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: BlackOlive,
                                    fontFamily: 'SF-ProText-Heavy',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                SizedBox(
                                  width: 120,
                                  child: Container(
                                    alignment: Alignment.bottomRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: FloralWhite,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                          blurRadius: 4,
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: '${_outputSampleRate.toString()}',
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _outputSampleRate = int.tryParse(value);
                                        });
                                      },
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          ),


                          const SizedBox(height: 20),

                          // Campos para modificar la duración del audio

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
                                  'Cortar audio',
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
                                            boxShadow: const [
                                              BoxShadow(
                                                blurRadius: 4,
                                                color: Colors.black26,
                                                offset: Offset(0, 2),
                                              )
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Inicio',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'SF-ProText-Heavy',
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: TextField(
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: '${_outputTrimStart.toString()}',
                                                  ),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _outputTrimStart = value;
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
                                                'Final',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontFamily: 'SF-ProText-Heavy',
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                              SizedBox(width: 16),
                                              Expanded(
                                                child: TextField(
                                                  keyboardType: TextInputType.number,
                                                  decoration: InputDecoration(
                                                    hintText: '${_outputTrimEnd.toString()}',
                                                  ),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _outputTrimEnd = value;
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

                          const SizedBox(height: 20),

                          // Muestra una lista para seleccionar el motor de conversión

                          DropdownButtonFormField<String>(
                            value: _outputEngine,
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
                              "Selecciona un motor de conversión",
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(Icons.expand_circle_down_rounded, color: Colors.grey.shade700),
                            dropdownColor: Timberwolf,
                            items: _outputEngines.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: TextStyle(fontSize: 16, color: Colors.grey.shade700, fontFamily: 'SF-ProText-Heavy', fontWeight: FontWeight.w800)),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return _outputEngines.map((String value) {
                                return Text(
                                  'Motor de conversión seleccionado: ${value.toUpperCase()}',
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
                                _outputEngine = value;
                              });
                            },
                          ),


                          const SizedBox(height: 20),

                          // Botón de descarga


                          ElevatedButton(
                            onPressed: isReadyToDownload() ? _convertAudio : null,
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


                          const SizedBox(height: 200),





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
