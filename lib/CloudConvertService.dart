/*
 * @author: Juan Martos Cuevas
 */

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum estado { pending, uploading, converting, downloading, finished, error }

/// Esta clase se encarga de la subida y conversión de archivos a través de la API de CloudConvert.
///
/// Entra en acción una vez seleccionas el botón DESCARGAR en la interfaz de usuario. Los procesos
/// son:
///
///  - fileUpload: Sube el archivo a la API de CloudConvert.
///  - fileConvert: Se le pide a CloudConvert que convierta el archivo subido.
///  - monitorizarConversion: Se espera hasta que el archivo haya sido convertido para avanzar.
///  - obtenerUrlDescarga: Se le pide a CloudConvert que nos dé la URL de descarga del archivo convertido.
///  - downloadFile: Descarga el archivo convertido a la carpeta de descargas del dispositivo.

class CloudConvertService {

  // Estado de la conversión que se va actualizando a medida que avanza el proceso.
  estado estadoActual = estado.pending;

  // Variables para almacenar cada uno de los posibles parametros que se le pueden pasar a la API segun el tipo de archivo
  String? _fileType;
  String? _outputformat = '';
  String? _videoCodec = '';
  int? _crf = 23;
  int? _width = null;
  int? _height = null;
  String? _audioCodec = '';
  String? _formatoOriginal;
  String? filePath;
  int? _imageQuality = 50;
  String? _imageEngine = '';
  int? _audioBitrate = 128;
  double? _volume = 1.0;
  int? _sample_rate = 44100;
  String? _trim_start = '';
  String? _trim_end = '';
  String? _audioEngine = '';


  // ARRIBA Clave de API real, ABAJO clave de API de sandbox

  //final String apiKey = '-';
  final String apiKey = '-';


  CloudConvertService();

  /// Función encargada de generar un nombre para mostrar en la lista de conversiones en la interfaz de usuario.
  String getName() {
    if(_fileType == 'video'){
      return '${_formatoOriginal?.toUpperCase()} to ${_outputformat?.toUpperCase()} | ${_videoCodec?.toUpperCase()}';
    } else if(_fileType == 'image' && _outputformat == 'webp' || _outputformat == 'png'){
      return '${_formatoOriginal?.toUpperCase()} to ${_outputformat?.toUpperCase()} | Compresión: ${_imageQuality?.toString()}';
    } else if(_fileType == 'image' && _outputformat == 'jpg'){
      return '${_formatoOriginal?.toUpperCase()} to ${_outputformat?.toUpperCase()} | Calidad: ${_imageQuality?.toString()}';
    } else {
      return '${_formatoOriginal?.toUpperCase()} to ${_outputformat?.toUpperCase()}';
    }

  }

  /// Función encargada de devolver el estado de la conversión.
  String getStatus(){
    return estadoActual.toString();
  }

  /// Función encargada de devolver la ruta del archivo original.
  String? getFilePath(){
    return filePath;
  }



  /// Sube el archivo a la API de CloudConvert.
  /// Detecta que tipo de archivo es: imagen, video o audio. En función de esto, decide que parametros de subida usar.
  Future<void> fileUpload(BuildContext context, File file, String format, {outputformat='', videoCodec='', crf=23, width=null, height=null, audioCodec='', imageQuality=50, imageEngine='', audioBitrate = 128, volume = 1.0, sample_rate = 44100, trim_start = '', trim_end = '', engine = ''}) async {

    // Antes de nada, se comprueban los permisos de almacenamiento
    await checkStoragePermission();

    _outputformat = outputformat.toLowerCase();
    _videoCodec = videoCodec;
    _crf = crf;
    _width = width;
    _height = height;
    _audioCodec = audioCodec;
    _formatoOriginal = format.toLowerCase();
    _imageQuality = imageQuality;
    _imageEngine = imageEngine;
    _audioBitrate = audioBitrate;
    _volume = volume;
    _sample_rate = sample_rate;
    _trim_start = trim_start;
    _trim_end = trim_end;
    _audioEngine = engine;


    if(_formatoOriginal == 'jpg' ||
        _formatoOriginal == 'png' ||
        _formatoOriginal == 'gif' ||
        _formatoOriginal == 'webp' ||
        _formatoOriginal == 'bmp')
    {
      _fileType = 'image';
    }
    if(_formatoOriginal == 'mp4' ||
        _formatoOriginal == 'avi' ||
        _formatoOriginal == 'webm' ||
        _formatoOriginal == 'mkv' ||
        _formatoOriginal == 'flv')
    {
      _fileType = 'video';
    }
    if(_formatoOriginal == 'mp3' ||
        _formatoOriginal == 'aac' ||
        _formatoOriginal == 'flac' ||
        _formatoOriginal == 'm4a' ||
        _formatoOriginal == 'wav' ||
        _formatoOriginal == 'aiff' )
    {
      _fileType = 'audio';
    }

    try {

      estadoActual = estado.uploading;


      // Primero se obtiene la url de subida
      var url = Uri.parse('https://api.sandbox.cloudconvert.com/v2/import/upload');
      var response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Error al obtener la URL de subida: ${response.statusCode}');
        print('Respuesta completa: ${response.body}');
        estadoActual = estado.error;
        return;
      }

      var responseJson = json.decode(response.body);
      if (responseJson['data'] == null || responseJson['data']['result'] == null) {
        print('Error: No se recibió la información de subida.');
        print('Respuesta completa: ${response.body}');
        estadoActual = estado.error;
        return;
      }

      // Se saca la url de la respuesta
      String uploadUrl = responseJson['data']['result']['form']['url'];
      Map<String, dynamic> parameters = responseJson['data']['result']['form']['parameters'];

      print('URL de subida: $uploadUrl');
      print('Parámetros de subida: $parameters');

      // Se sube el archivo a la URL obtenida
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));

      // Agregar parámetros como campos del formulario
      parameters.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Agregar el archivo
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var uploadResponse = await request.send();

      if (uploadResponse.statusCode == 201) {
        print('Archivo subido correctamente.');

        // Guardo el id del archivo subido
        String fileId = responseJson['data']['id'];

        // Se inicia la conversion de la id obtenida anteriormente
        await fileConvert(fileId);

      } else {
        print('Error al subir el archivo: ${uploadResponse.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }

  }

  /// Indica como convertir el archivo subido a la API de CloudConvert.
  Future<void> fileConvert(String fileId) async {
    try {

      var url = Uri.parse('https://api.sandbox.cloudconvert.com/v2/convert');
      estadoActual = estado.converting;
      print("=====================");
      print("FILE TYPE: $_fileType");
      print("=====================");

      // Se crea un cuerpo 'base' para la petición a partir del cual modificar según el tipo de archivo
      var body = json.encode({
        'input': {'file': fileId},
        'output_format': _outputformat,
        'autostart': true
      });

      // Se modifica el cuerpo según el tipo de archivo
      if(_fileType == 'video')
      {
        body = json.encode({
          'input': {'file': fileId},
          'output_format': _outputformat,
          'autostart': true,
          'video_codec': _videoCodec,
          'crf': _crf,
          'width': _width,
          'height': _height,
          'audio_codec': _audioCodec
        });
      }
      if(_fileType == 'image') {
        body = json.encode({
          'input': {'file': fileId},
          'output_format': _outputformat,
          'autostart': true,
          'width': _width,
          'height': _height,
          'quality': _imageQuality,
          'engine': _imageEngine
        });
      }
      if(_fileType == 'audio') {
        body = json.encode({
          'input': {'file': fileId},
          'output_format': _outputformat,
          'autostart': true,
          'audio_codec': _audioCodec,
          'audio_bitrate': _audioBitrate,
          'volume': _volume,
          'sample_rate': _sample_rate,
          'trim_start': _trim_start,
          'trim_end': _trim_end,
          'engine': _audioEngine
        });
      }

      // Se espera la respuesta de la API
      var response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseJson = json.decode(response.body);
        String taskId = responseJson['data']['id'];
        print('Tarea de conversión creada con ID: $taskId');

        // Se inicia la monitorización de la conversión
        await monitorizarConversion(taskId);

      } else {
        print('Error al crear la tarea de conversión: ${response.statusCode}');
        print('Respuesta completa: ${response.body}');
        estadoActual = estado.error;
      }

    } catch (e) {
      print('Error: $e');
      estadoActual = estado.error;
    }
  }

  /// Monitorea el estado de la conversión hasta que se complete o falle.
  Future<void> monitorizarConversion(String taskId) async {
    try {

      // Se le pide a la API el estado de la conversión
      var url = Uri.parse('https://api.sandbox.cloudconvert.com/v2/tasks/$taskId');
      var response = await http.get(url, headers: {
        'Authorization': 'Bearer $apiKey',
      });

      if (response.statusCode == 200) {
        var responseJson = json.decode(response.body);
        String status = responseJson['data']['status'];
        print('Respuesta completa: ${response.body}');

        if (status == 'finished') {
          print('Conversión completada.');

          // Una vez terminada la conversión, se obtiene la URL de descarga
          obtenerUrlDescarga(responseJson['data']['id']);

        } else if (status == 'failed' || status == 'error') {

          estadoActual = estado.error;
          print('La conversión falló.');

        } else {

          print('La conversión aún está en progreso...');

          // Volver a intentar en algunos segundos
          await Future.delayed(Duration(seconds: 5));
          await monitorizarConversion(taskId);
        }
      } else {
        print('Error al monitorear la conversión: ${response.statusCode}');
      }
    } catch (e) {
      estadoActual = estado.error;
      print('Error: $e');
    }
  }

  /// Descarga el archivo convertido a la carpeta de descargas del dispositivo.
  Future<void> downloadFile(String url) async {
    try {
      // Se obtiene la carpeta de descargas del dispositivo
      Dio dio = Dio();
      Directory? tempDir = await getDownloadsDirectory();
      filePath = '${tempDir!.path}/ConvallFile.$_outputformat';

      print('Descargando archivo en: $filePath');
      estadoActual = estado.downloading;

      // Se inicia la descarga
      await dio.download(url, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          print('Descarga en progreso: ${(received / total * 100).toStringAsFixed(0)}%');

        }
      });

      estadoActual = estado.finished;
      print('Descarga completada. Archivo guardado en: $filePath');
    } catch (e) {
      estadoActual = estado.error;
      print('Error al descargar el archivo: $e');
    }
  }


  /// Función encargada de obtener la URL de descarga del archivo convertido.
  Future<void> obtenerUrlDescarga(String fileId) async {
    var url = Uri.parse('https://api.sandbox.cloudconvert.com/v2/export/url');

    // Cuerpo de la solicitud
    var body = json.encode({
      "input": fileId,
      "archive_multiple_files": false,
    });

    // Se espera la respuesta de la API
    var response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );
    var responseJson = json.decode(response.body);

    // Aqui obtenermos una segunda respuesta despues de esperar 2 segundos.
    // Esto es porque la API de CloudConvert no devuelve la URL de descarga inmediatamente, sino que
    // primero devuelve un ID de tarea y luego se debe consultar para obtener la URL.
    await Future.delayed(Duration(seconds: 2));
    var urlFinished = Uri.parse('https://api.sandbox.cloudconvert.com/v2/tasks/${responseJson['data']['id']}?include=payload');
    var responseFinished = await http.get(
      urlFinished,
      headers: {
        'Authorization': 'Bearer $apiKey',
      },
    );

    var responseFinishedJson = json.decode(responseFinished.body);

    if (responseFinished.statusCode == 200) {

      print("Estado de la exportacion: ${responseFinishedJson['data']['status']}");
      try {
        String downloadUrl = responseFinishedJson['data']['result']['files'][0]['url'];
        print('URL de descarga: $downloadUrl');
        downloadFile(downloadUrl);
      } catch (e) {
        estadoActual = estado.error;
        print('Error: No se pudo extraer la URL de descarga.');
        print('Detalles: $e');
      }
    } else {
      estadoActual = estado.error;
      print('Error al obtener la URL de descarga: ${response.statusCode}');
      print('Respuesta completa: ${response.body}');
    }



  }

  /// Función encargada de comprobar si se tienen los permisos necesarios
  /// para acceder a la carpeta de descargas.
  Future<bool> checkStoragePermission() async {
    var statusStorage = await Permission.storage.status;

    if (statusStorage.isPermanentlyDenied) {
      /*ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission permanently denied'),
        ),
      );*/
      return false;
    } else {
      statusStorage = await Permission.storage.request();
      if (statusStorage.isGranted) {

        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission granted'),
          ),
        );*/
        return true;
      } else {
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied'),
          ),
        );*/
        return false;
      }
    }
  }




}


