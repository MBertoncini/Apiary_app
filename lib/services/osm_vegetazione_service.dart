import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/osm_vegetazione.dart';

class OsmVegetazioneService {
  static const _overpassUrl = 'https://overpass-api.de/api/interpreter';

  static String _buildQuery(
      double south, double west, double north, double east) {
    final bbox = '$south,$west,$north,$east';
    // out geom include la geometria inline per way e members di relation
    return '[out:json][timeout:25];'
        '('
        // Way: bosco/foresta
        'way["natural"="wood"]($bbox);'
        'way["landuse"="forest"]($bbox);'
        // Way: frutteto
        'way["landuse"="orchard"]($bbox);'
        // Way: colture con specie dichiarata
        'way["landuse"="farmland"]["crop"]($bbox);'
        // Way: macchia e prato
        'way["natural"="scrub"]($bbox);'
        'way["natural"="grassland"]($bbox);'
        'way["landuse"="meadow"]($bbox);'
        // Relation multipolygon: grandi foreste e boschi
        'relation["natural"="wood"]["type"="multipolygon"]($bbox);'
        'relation["landuse"="forest"]["type"="multipolygon"]($bbox);'
        'relation["landuse"="orchard"]["type"="multipolygon"]($bbox);'
        'relation["natural"="scrub"]["type"="multipolygon"]($bbox);'
        ');'
        'out geom;';
  }

  Future<List<OsmVegetazione>> fetchVegetazione({
    required double south,
    required double west,
    required double north,
    required double east,
  }) async {
    final query = _buildQuery(south, west, north, east);
    debugPrint('OSM Overpass query bbox: $south,$west,$north,$east');

    final response = await http
        .post(
          Uri.parse(_overpassUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'data=${Uri.encodeComponent(query)}',
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Overpass API errore: ${response.statusCode}');
    }

    final data =
        json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final elements = data['elements'] as List<dynamic>;

    final result = <OsmVegetazione>[];

    for (final el in elements) {
      final type = el['type'] as String;
      final rawTags = el['tags'] as Map<String, dynamic>? ?? {};
      final tags = rawTags.map((k, v) => MapEntry(k, v.toString()));

      if (type == 'way') {
        final polygon = _geometryToLatLng(el['geometry'] as List<dynamic>?);
        _addIfValid(result, el['id'] as int, tags, polygon);
      } else if (type == 'relation') {
        final members = el['members'] as List<dynamic>? ?? [];
        final outerSegments = <List<LatLng>>[];

        for (final member in members) {
          if (member['role'] != 'outer') continue;
          final seg = _geometryToLatLng(member['geometry'] as List<dynamic>?);
          if (seg.length >= 2) outerSegments.add(seg);
        }

        if (outerSegments.isNotEmpty) {
          final polygon = _assembleRing(outerSegments);
          _addIfValid(result, el['id'] as int, tags, polygon);
        }
      }
    }

    debugPrint('OSM Vegetazione: ${result.length} poligoni caricati');
    return result;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<LatLng> _geometryToLatLng(List<dynamic>? geometry) {
    if (geometry == null) return [];
    return geometry
        .map((g) => LatLng(
              (g['lat'] as num).toDouble(),
              (g['lon'] as num).toDouble(),
            ))
        .toList();
  }

  /// Assembla segmenti di way adiacenti in un anello chiuso continuo.
  static List<LatLng> _assembleRing(List<List<LatLng>> segments) {
    if (segments.length == 1) return segments[0];

    final result = <LatLng>[...segments[0]];
    final remaining = segments.sublist(1).toList();
    int maxIter = remaining.length * remaining.length + remaining.length;

    while (remaining.isNotEmpty && maxIter > 0) {
      maxIter--;
      final last = result.last;
      bool joined = false;
      for (int i = 0; i < remaining.length; i++) {
        final seg = remaining[i];
        if (_approxEq(seg.first, last)) {
          result.addAll(seg.sublist(1));
          remaining.removeAt(i);
          joined = true;
          break;
        } else if (_approxEq(seg.last, last)) {
          result.addAll(seg.reversed.toList().sublist(1));
          remaining.removeAt(i);
          joined = true;
          break;
        }
      }
      if (!joined) break;
    }

    return result;
  }

  static bool _approxEq(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 1e-7 &&
      (a.longitude - b.longitude).abs() < 1e-7;

  static void _addIfValid(
    List<OsmVegetazione> result,
    int id,
    Map<String, String> tags,
    List<LatLng> punti,
  ) {
    if (punti.length < 3) return;
    // Solo way chiuse
    if (!_approxEq(punti.first, punti.last) && punti.first != punti.last) {
      return;
    }
    // Filtra punti troppo grande (errori OSM o multipolygon parziali)
    final lats = punti.map((p) => p.latitude);
    final lngs = punti.map((p) => p.longitude);
    final latSpan = lats.reduce(max) - lats.reduce(min);
    final lngSpan = lngs.reduce(max) - lngs.reduce(min);
    if (latSpan > 0.25 || lngSpan > 0.35) return;
    // Filtra poligoni con troppi punti
    if (punti.length > 2000) return;

    result.add(OsmVegetazione.fromOsm(id: id, tags: tags, punti: punti));
  }
}
