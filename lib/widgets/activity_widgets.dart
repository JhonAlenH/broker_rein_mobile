import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ActivityWidget extends StatefulWidget {
  const ActivityWidget({Key? key}) : super(key: key);

  @override
  _ActivityWidgetState createState() => _ActivityWidgetState();
}

class _ActivityWidgetState extends State<ActivityWidget> {
  late Future<List<Map<String, dynamic>>> _activitiesFuture;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _fetchActivities(); // Inicializa el Future
    _startPeriodicFetch(); // Comienza el fetch periódico
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela el timer cuando el widget se destruye
    super.dispose();
  }

  void _startPeriodicFetch() {
    _timer = Timer.periodic(Duration(seconds: 60), (Timer timer) {
      setState(() {
        _activitiesFuture = _fetchActivities(); // Actualiza la future para que el FutureBuilder se reconstruya
      });
    });
  }

  Future<List<Map<String, dynamic>>> _fetchActivities() async {
    final response = await http.post(
      Uri.parse('https://apiglobex.tecno-prog.com/api/v1/mobile/activity'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['activity'];
      return data.map((activity) => {
            'title': activity['xactividad'],
            'date': activity['fecha_formateada'],
          }).toList();
    } else {
      throw Exception('Error al obtener actividades: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _activitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No hay actividades recientes.'));
        } else {
          final activities = snapshot.data!;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(39, 144, 214, 1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Actividades recientes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: activities.map((activity) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sección 1: Ícono
                            Icon(
                              Icons.flight_takeoff,
                              color: Color.fromRGBO(72, 175, 243, 0.733),
                            ),
                            SizedBox(width: 30),

                            // Sección 2: Título y Fecha
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    activity['date'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Sección 3: Espacio vacío por ahora
                            SizedBox(width: 20),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
