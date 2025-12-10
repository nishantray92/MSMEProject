// pump_backend.dart
// Minimal Dart backend using `shelf` + `shelf_router` to serve a simple Pump Information API
// Endpoints:
// GET  /pump/<id>            -> returns pump details (model, serial, lastMaintenanceDate, firmwareVersion, connected)
// POST /pump/<id>/connect    -> simulate a connect request (returns connection status)
// POST /pump/<id>/cancel     -> simulate cancel action
// PUT  /pump/<id>            -> update pump fields (accepts JSON body)

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

class Pump {
  String id;
  String modelNumber;
  String serialNumber;
  DateTime lastMaintenanceDate;
  String firmwareVersion;
  bool connected;

  Pump({
    required this.id,
    required this.modelNumber,
    required this.serialNumber,
    required this.lastMaintenanceDate,
    required this.firmwareVersion,
    this.connected = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'modelNumber': modelNumber,
        'serialNumber': serialNumber,
        'lastMaintenanceDate': lastMaintenanceDate.toIso8601String().split('T').first,
        'firmwareVersion': firmwareVersion,
        'connected': connected,
      };

  void updateFromJson(Map<String, dynamic> json) {
    if (json.containsKey('modelNumber')) modelNumber = json['modelNumber'];
    if (json.containsKey('serialNumber')) serialNumber = json['serialNumber'];
    if (json.containsKey('firmwareVersion')) firmwareVersion = json['firmwareVersion'];
    if (json.containsKey('lastMaintenanceDate')) {
      try {
        lastMaintenanceDate = DateTime.parse(json['lastMaintenanceDate']);
      } catch (_) {}
    }
    if (json.containsKey('connected')) connected = json['connected'] == true;
  }
}

// Simple in-memory "database"
final Map<String, Pump> pumps = {
  '1': Pump(
    id: '1',
    modelNumber: 'Model X100',
    serialNumber: 'SN123456789',
    lastMaintenanceDate: DateTime.parse('2023-08-15'),
    firmwareVersion: 'v2.1.3',
  ),
};

// Middleware: add CORS and JSON content-type
Middleware jsonAndCorsHeader() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Preflight
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders(request));
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        ..._corsHeaders(request),
        ...response.headers,
        'content-type': 'application/json; charset=utf-8'
      });
    };
  };
}

Map<String, String> _corsHeaders(Request request) => {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
    };

// Handlers
Response _notFound(String message) => Response.notFound(jsonEncode({'error': message}));

Future<Response> getPump(Request req, String id) async {
  final pump = pumps[id];
  if (pump == null) return _notFound('Pump with id $id not found');
  return Response.ok(jsonEncode(pump.toJson()));
}

Future<Response> connectPump(Request req, String id) async {
  final pump = pumps[id];
  if (pump == null) return _notFound('Pump with id $id not found');

  // Simulate a connect action. In a real system this would trigger a network/serial action.
  pump.connected = true;

  final body = {
    'message': 'Connected to pump',
    'id': pump.id,
    'connected': pump.connected,
  };
  return Response.ok(jsonEncode(body));
}

Future<Response> cancelPump(Request req, String id) async {
  final pump = pumps[id];
  if (pump == null) return _notFound('Pump with id $id not found');

  // Simulate a cancel action
  pump.connected = false;

  final body = {
    'message': 'Connection cancelled',
    'id': pump.id,
    'connected': pump.connected,
  };
  return Response.ok(jsonEncode(body));
}

Future<Response> updatePump(Request req, String id) async {
  final pump = pumps[id];
  if (pump == null) return _notFound('Pump with id $id not found');

  final payload = await req.readAsString();
  if (payload.isEmpty) {
    return Response(400, body: jsonEncode({'error': 'Empty body'}));
  }

  try {
    final jsonBody = jsonDecode(payload) as Map<String, dynamic>;
    pump.updateFromJson(jsonBody);
    return Response.ok(jsonEncode({'message': 'Pump updated', 'pump': pump.toJson()}));
  } catch (e) {
    return Response(400, body: jsonEncode({'error': 'Invalid JSON: ${e.toString()}'}));
  }
}

void main(List<String> args) async {
  final router = Router();

  router.get('/pump/<id>', getPump);
  router.post('/pump/<id>/connect', connectPump);
  router.post('/pump/<id>/cancel', cancelPump);
  router.put('/pump/<id>', updatePump);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(jsonAndCorsHeader())
      .addHandler(router);

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('Server listening on port ${server.port}');
}
