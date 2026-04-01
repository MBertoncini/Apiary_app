import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum OsmVegetazioneTipo { bosco, macchia, prato, frutteto, coltura, altro }

class OsmVegetazione {
  final int id;
  final OsmVegetazioneTipo tipo;
  final Map<String, String> tags;
  final List<LatLng> punti;

  const OsmVegetazione({
    required this.id,
    required this.tipo,
    required this.tags,
    required this.punti,
  });

  String get etichetta {
    final crop = tags['crop'];
    final species = tags['species'] ?? tags['species:it'];
    final wood = tags['wood'];
    switch (tipo) {
      case OsmVegetazioneTipo.bosco:
        if (species != null) return 'Bosco ($species)';
        if (wood != null) return 'Bosco ($wood)';
        return tags['landuse'] == 'forest' ? 'Foresta' : 'Bosco';
      case OsmVegetazioneTipo.macchia:
        return 'Macchia / Gariga';
      case OsmVegetazioneTipo.prato:
        return tags['landuse'] == 'meadow' ? 'Prato' : 'Pascolo';
      case OsmVegetazioneTipo.frutteto:
        final trees = tags['trees'] ?? crop;
        return trees != null ? 'Frutteto ($trees)' : 'Frutteto';
      case OsmVegetazioneTipo.coltura:
        return crop != null ? 'Coltura: $crop' : 'Coltivazione';
      default:
        return 'Vegetazione';
    }
  }

  Color get colore {
    switch (tipo) {
      case OsmVegetazioneTipo.bosco:
        return const Color(0xFF2E7D32); // green[800]
      case OsmVegetazioneTipo.macchia:
        return const Color(0xFF689F38); // lightGreen[700]
      case OsmVegetazioneTipo.prato:
        return const Color(0xFF9CCC65); // lightGreen[400]
      case OsmVegetazioneTipo.frutteto:
        return const Color(0xFF00897B); // teal[600]
      case OsmVegetazioneTipo.coltura:
        return const Color(0xFFF9A825); // amber[800]
      default:
        return const Color(0xFF558B2F);
    }
  }

  static OsmVegetazioneTipo _tipoFromTags(Map<String, String> tags) {
    final natural = tags['natural'];
    final landuse = tags['landuse'];
    if (natural == 'wood' || landuse == 'forest') return OsmVegetazioneTipo.bosco;
    if (natural == 'scrub') return OsmVegetazioneTipo.macchia;
    if (natural == 'grassland' || landuse == 'meadow') return OsmVegetazioneTipo.prato;
    if (landuse == 'orchard') return OsmVegetazioneTipo.frutteto;
    if (landuse == 'farmland') return OsmVegetazioneTipo.coltura;
    return OsmVegetazioneTipo.altro;
  }

  factory OsmVegetazione.fromOsm({
    required int id,
    required Map<String, String> tags,
    required List<LatLng> punti,
  }) =>
      OsmVegetazione(
        id: id,
        tipo: _tipoFromTags(tags),
        tags: tags,
        punti: punti,
      );
}
