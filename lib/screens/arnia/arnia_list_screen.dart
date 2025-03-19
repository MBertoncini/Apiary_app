import 'package:flutter/material.dart';
import '../../widgets/drawer_widget.dart';
import '../../constants/app_constants.dart';
import '../../constants/api_constants.dart';
import '../../services/api_service.dart';
import '../../models/arnia.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ArniaListScreen extends StatefulWidget {
  @override
  _ArniaListScreenState createState() => _ArniaListScreenState();
}

class _ArniaListScreenState extends State<ArniaListScreen> {
  late Future<List<Arnia>> _arnieFuture;
  late ApiService _apiService;
  
  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _apiService = ApiService(authService);
    _refreshArnie();
  }
  
  Future<void> _refreshArnie() async {
    setState(() {
      _arnieFuture = _loadArnie();
    });
  }
  
  Future<List<Arnia>> _loadArnie() async {
    try {
      final response = await _apiService.get(ApiConstants.arnieUrl);
      if (response is List) {
        return response
            .map((item) => Arnia.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error loading arnie: $e');
      throw e;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Le mie Arnie'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshArnie,
          ),
        ],
      ),
      drawer: AppDrawer(currentRoute: AppConstants.arniaListRoute),
      body: FutureBuilder<List<Arnia>>(
        future: _arnieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Errore nel caricamento delle arnie: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Nessuna arnia trovata',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Crea arnia'),
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppConstants.creaArniaRoute);
                    },
                  ),
                ],
              ),
            );
          } else {
            return RefreshIndicator(
              onRefresh: _refreshArnie,
              child: ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final arnia = snapshot.data![index];
                  return ArniaListItem(arnia: arnia);
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed(AppConstants.creaArniaRoute);
        },
      ),
    );
  }
}

class ArniaListItem extends StatelessWidget {
  final Arnia arnia;
  
  const ArniaListItem({required this.arnia});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorFromHex(arnia.coloreHex),
          child: Text(
            arnia.numero.toString(),
            style: TextStyle(
              color: _getContrastColor(_getColorFromHex(arnia.coloreHex)),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text('Arnia ${arnia.numero}'),
        subtitle: Text('Apiario: ${arnia.apiarioNome}'),
        trailing: arnia.attiva
            ? Icon(Icons.check_circle, color: Colors.green)
            : Icon(Icons.cancel, color: Colors.red),
        onTap: () {
          Navigator.of(context).pushNamed(
            AppConstants.arniaDetailRoute,
            arguments: arnia.id,
          );
        },
      ),
    );
  }
  
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
  
  Color _getContrastColor(Color backgroundColor) {
    // Calcola se il testo dovrebbe essere chiaro o scuro
    double luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}