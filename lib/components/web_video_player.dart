import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class WebVideoPlayer extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const WebVideoPlayer({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return NowaWebView(url: url);
  }
}
