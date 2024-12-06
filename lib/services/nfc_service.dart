import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:io' show Platform;

class NFCService {
  static StreamController<String>? _tagStreamController;
  static bool _isScanning = false;
  static bool get isMobile {
    if (kIsWeb) {
      return false;
    } else {
      return Platform.isIOS || Platform.isAndroid;
    }
  }
  static Stream<String> get tagStream {
    _tagStreamController ??= StreamController<String>.broadcast();
    return _tagStreamController!.stream;
  }

  static Future<void> startContinuousScanning() async {
    if (!isMobile) {
      print('NFC scanning is only supported on Android');
      return;
    }

    if (_isScanning) return;
    _isScanning = true;

    while (_isScanning) {
      try {
        var availability = await FlutterNfcKit.nfcAvailability;
        print('NFC Availability: $availability');
        
        if (availability != NFCAvailability.available) {
          throw Exception('NFC not available on this device');
        }

        print('Starting NFC polling...');
        var tag = await FlutterNfcKit.poll(
          timeout: Duration(seconds: 20),
          androidPlatformSound: true,
        );
        
        print('NFC Tag detected: ${tag.toString()}');
        String tagId = tag.id;
        print('Tag ID: $tagId');
        
        await FlutterNfcKit.finish();
        
        if (_tagStreamController != null && !_tagStreamController!.isClosed) {
          _tagStreamController!.add(tagId);
        }
      } catch (e) {
        print('NFC Error: $e');
        await FlutterNfcKit.finish();
        // Wait a bit before retrying
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  static void stopScanning() {
    if (!isMobile) return;
    _isScanning = false;
    FlutterNfcKit.finish();
  }

  static void dispose() {
    stopScanning();
    _tagStreamController?.close();
    _tagStreamController = null;
  }
}
