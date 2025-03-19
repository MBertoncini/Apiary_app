import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  
  const LoadingWidget({Key? key, this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class CustomErrorWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;
  
  const CustomErrorWidget({
    Key? key,
    required this.errorMessage,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Riprova'),
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}