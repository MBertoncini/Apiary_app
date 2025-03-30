import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/theme_constants.dart';

/// Widget per disegnare un'arnia in stile "disegnato a mano"
class HandDrawnBeehive extends StatelessWidget {
  final double size;
  final Color color;
  final bool isActive;

  const HandDrawnBeehive({
    Key? key,
    this.size = 60,
    this.color = const Color(0xFFD3A121),
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.2),
      painter: BeehivePainter(
        color: color,
        isActive: isActive,
      ),
    );
  }
}

class BeehivePainter extends CustomPainter {
  final Color color;
  final bool isActive;
  final bool useSketchStyle;

  BeehivePainter({
    required this.color,
    this.isActive = true,
    this.useSketchStyle = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isActive ? color : color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = isActive 
        ? color.withOpacity(0.15)
        : color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final width = size.width;
    final height = size.height;
    
    // Disegno base dell'arnia con "tremolio" per effetto disegnato a mano
    if (useSketchStyle) {
      _drawSketchBeehive(canvas, size, paint, fillPaint);
    } else {
      _drawCleanBeehive(canvas, size, paint, fillPaint);
    }
    
    // Aggiunta di "ape" se l'arnia è attiva
    if (isActive) {
      final beePaint = Paint()
        ..color = ThemeConstants.secondaryColor
        ..style = PaintingStyle.fill;
      
      // Piccole api che volano attorno all'arnia
      canvas.drawCircle(
        Offset(width * 0.2, height * 0.3),
        width * 0.03,
        beePaint,
      );
      
      canvas.drawCircle(
        Offset(width * 0.8, height * 0.4),
        width * 0.025,
        beePaint,
      );
      
      canvas.drawCircle(
        Offset(width * 0.6, height * 0.2),
        width * 0.02,
        beePaint,
      );
    }
  }
  
  // Disegno in stile "sketch" con leggero tremolio delle linee
  void _drawSketchBeehive(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final width = size.width;
    final height = size.height;
    final random = math.Random(12345); // Seed fisso per tremolio consistente
    
    // Funzione per aggiungere "tremolio" alle linee per effetto disegnato a mano
    Offset jitter(double x, double y, double amount) {
      return Offset(
        x + random.nextDouble() * amount - amount / 2,
        y + random.nextDouble() * amount - amount / 2,
      );
    }
    
    // Forma dell'arnia
    final path = Path();
    final jitterAmount = width * 0.02; // Intensità del tremolio
    
    // Base
    Offset baseStart = jitter(width * 0.2, height * 0.9, jitterAmount);
    Offset baseEnd = jitter(width * 0.8, height * 0.9, jitterAmount);
    path.moveTo(baseStart.dx, baseStart.dy);
    path.lineTo(baseEnd.dx, baseEnd.dy);
    
    // Livelli dell'arnia (3 livelli sovrapposti)
    for (int i = 0; i < 3; i++) {
      double y = height * (0.75 - i * 0.2);
      double leftX = width * (0.25 - i * 0.05);
      double rightX = width * (0.75 + i * 0.05);
      
      Offset leftPoint = jitter(leftX, y, jitterAmount);
      Offset rightPoint = jitter(rightX, y, jitterAmount);
      
      path.moveTo(leftPoint.dx, leftPoint.dy);
      path.lineTo(rightPoint.dx, rightPoint.dy);
    }
    
    // Cupola
    final centerTop = jitter(width * 0.5, height * 0.15, jitterAmount);
    final controlPoint1 = jitter(width * 0.25, height * 0.25, jitterAmount);
    final controlPoint2 = jitter(width * 0.75, height * 0.25, jitterAmount);
    
    path.moveTo(jitter(width * 0.15, height * 0.35, jitterAmount).dx, 
                jitter(width * 0.15, height * 0.35, jitterAmount).dy);
    path.quadraticBezierTo(
      controlPoint1.dx, controlPoint1.dy,
      centerTop.dx, centerTop.dy
    );
    path.quadraticBezierTo(
      controlPoint2.dx, controlPoint2.dy,
      jitter(width * 0.85, height * 0.35, jitterAmount).dx,
      jitter(width * 0.85, height * 0.35, jitterAmount).dy
    );
    
    // Apertura per le api
    final entranceLeft = jitter(width * 0.45, height * 0.8, jitterAmount);
    final entranceRight = jitter(width * 0.55, height * 0.8, jitterAmount);
    
    path.moveTo(entranceLeft.dx, entranceLeft.dy);
    path.lineTo(entranceRight.dx, entranceRight.dy);
    
    // Disegna la forma piena e poi il contorno
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }
  
  // Versione pulita senza tremolio
  void _drawCleanBeehive(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final width = size.width;
    final height = size.height;
    
    final path = Path();
    
    // Base
    path.moveTo(width * 0.2, height * 0.9);
    path.lineTo(width * 0.8, height * 0.9);
    
    // Livelli dell'arnia
    for (int i = 0; i < 3; i++) {
      double y = height * (0.75 - i * 0.2);
      double leftX = width * (0.25 - i * 0.05);
      double rightX = width * (0.75 + i * 0.05);
      
      path.moveTo(leftX, y);
      path.lineTo(rightX, y);
    }
    
    // Cupola
    path.moveTo(width * 0.15, height * 0.35);
    path.quadraticBezierTo(
      width * 0.25, height * 0.25,
      width * 0.5, height * 0.15
    );
    path.quadraticBezierTo(
      width * 0.75, height * 0.25,
      width * 0.85, height * 0.35
    );
    
    // Apertura
    path.moveTo(width * 0.45, height * 0.8);
    path.lineTo(width * 0.55, height * 0.8);
    
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget per disegnare un apiario in stile "disegnato a mano"
class HandDrawnApiary extends StatelessWidget {
  final double size;
  final int beehiveCount;
  final Color color;

  const HandDrawnApiary({
    Key? key,
    this.size = 120,
    this.beehiveCount = 3,
    this.color = const Color(0xFFD3A121),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ApiaryPainter(
          color: color,
          beehiveCount: beehiveCount,
        ),
      ),
    );
  }
}

class ApiaryPainter extends CustomPainter {
  final Color color;
  final int beehiveCount;
  
  ApiaryPainter({
    required this.color,
    this.beehiveCount = 3,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Disegna il terreno
    final groundPaint = Paint()
      ..color = ThemeConstants.successColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final groundPath = Path();
    groundPath.moveTo(0, height * 0.85);
    groundPath.quadraticBezierTo(
      width * 0.5, height * 0.78,
      width, height * 0.85
    );
    groundPath.lineTo(width, height);
    groundPath.lineTo(0, height);
    groundPath.close();
    
    canvas.drawPath(groundPath, groundPaint);
    
    // Disegna le arnie in disposizione circolare
    final maxBeehives = math.min(beehiveCount, 5); // Limita a 5 arnie visibili
    final beehiveSize = width * 0.3;
    
    for (int i = 0; i < maxBeehives; i++) {
      final angle = (i / maxBeehives) * math.pi * 0.6 + math.pi * 0.2;
      final beehiveX = width * 0.5 + math.cos(angle) * width * 0.35;
      final beehiveY = height * 0.7 + math.sin(angle) * height * 0.15;
      
      final beehivePainter = BeehivePainter(
        color: color,
        isActive: true,
        useSketchStyle: true,
      );
      
      canvas.save();
      canvas.translate(beehiveX - beehiveSize/2, beehiveY - beehiveSize/2);
      beehivePainter.paint(canvas, Size(beehiveSize, beehiveSize * 1.2));
      canvas.restore();
    }
    
    // Se ci sono più arnie di quelle mostrate, aggiungere indicatore
    if (beehiveCount > 5) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '+${beehiveCount - 5}',
          style: TextStyle(
            color: ThemeConstants.secondaryColor,
            fontSize: width * 0.12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(width * 0.85 - textPainter.width/2, height * 0.7 - textPainter.height/2)
      );
    }
    
    // Disegna fiori o erba
    final flowerPaint = Paint()
      ..color = Colors.purple.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(width * 0.15, height * 0.9), width * 0.02, flowerPaint);
    canvas.drawCircle(Offset(width * 0.85, height * 0.9), width * 0.02, flowerPaint);
    canvas.drawCircle(Offset(width * 0.35, height * 0.95), width * 0.02, flowerPaint);
    canvas.drawCircle(Offset(width * 0.65, height * 0.92), width * 0.02, flowerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget per disegnare una regina delle api
class HandDrawnQueenBee extends StatelessWidget {
  final double size;
  final Color color;

  const HandDrawnQueenBee({
    Key? key,
    this.size = 60,
    this.color = const Color(0xFFD3A121),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: QueenBeePainter(color: color),
      ),
    );
  }
}

class QueenBeePainter extends CustomPainter {
  final Color color;
  
  QueenBeePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    final paint = Paint()
      ..color = ThemeConstants.secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.03
      ..strokeCap = StrokeCap.round;
    
    final bodyFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final random = math.Random(54321);
    
    // Funzione per aggiungere "tremolio" alle linee
    Offset jitter(double x, double y, double amount) {
      return Offset(
        x + random.nextDouble() * amount - amount / 2,
        y + random.nextDouble() * amount - amount / 2,
      );
    }
    
    // Corpo dell'ape
    final bodyPath = Path();
    final bodyCenter = Offset(width * 0.5, height * 0.5);
    
    // Corpo ovale
    bodyPath.addOval(
      Rect.fromCenter(
        center: bodyCenter,
        width: width * 0.7,
        height: width * 0.5,
      )
    );
    
    // Strisce
    for (int i = 0; i < 3; i++) {
      final stripeY = height * 0.4 + i * height * 0.1;
      bodyPath.moveTo(width * 0.3, stripeY);
      bodyPath.lineTo(width * 0.7, stripeY);
    }
    
    // Ali
    final wingPath = Path();
    wingPath.addOval(
      Rect.fromCenter(
        center: jitter(width * 0.4, height * 0.35, width * 0.02),
        width: width * 0.3,
        height: width * 0.2,
      )
    );
    wingPath.addOval(
      Rect.fromCenter(
        center: jitter(width * 0.6, height * 0.35, width * 0.02),
        width: width * 0.3,
        height: width * 0.2,
      )
    );
    
    // Corona (caratteristica della regina)
    final crownPath = Path();
    crownPath.moveTo(jitter(width * 0.4, height * 0.15, width * 0.01).dx, 
                     jitter(width * 0.4, height * 0.15, width * 0.01).dy);
    crownPath.lineTo(jitter(width * 0.45, height * 0.05, width * 0.01).dx, 
                     jitter(width * 0.45, height * 0.05, width * 0.01).dy);
    crownPath.lineTo(jitter(width * 0.5, height * 0.15, width * 0.01).dx, 
                     jitter(width * 0.5, height * 0.15, width * 0.01).dy);
    crownPath.lineTo(jitter(width * 0.55, height * 0.05, width * 0.01).dx, 
                     jitter(width * 0.55, height * 0.05, width * 0.01).dy);
    crownPath.lineTo(jitter(width * 0.6, height * 0.15, width * 0.01).dx, 
                     jitter(width * 0.6, height * 0.15, width * 0.01).dy);
    
    // Disegna il corpo pieno
    canvas.drawPath(bodyPath, bodyFill);
    canvas.drawPath(bodyPath, paint);
    
    // Disegna ali con colore traslucido
    final wingPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(wingPath, wingPaint);
    canvas.drawPath(wingPath, paint..strokeWidth = width * 0.01);
    
    // Disegna la corona
    final crownPaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(crownPath, crownPaint);
    canvas.drawPath(crownPath, paint..strokeWidth = width * 0.02);
    
    // Occhi
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      jitter(width * 0.35, height * 0.4, width * 0.01),
      width * 0.03,
      eyePaint
    );
    
    canvas.drawCircle(
      jitter(width * 0.65, height * 0.4, width * 0.01),
      width * 0.03,
      eyePaint
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}