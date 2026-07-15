import 'package:flutter/material.dart';
import 'package:pairfi/helper/ui/hint_text_card.dart';

class IdleWaitingScreen extends StatelessWidget {
  final String appBarText;
  final String? hintCardText;
  final String bodyText;

  const IdleWaitingScreen({super.key, required this.appBarText, this.hintCardText, required this.bodyText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hintCardText != null) HintTextCard(hintCardText!),
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
              const SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(strokeWidth: 6.0),
              ),
              const SizedBox(height: 55),
              Text(
                  bodyText,
                  style: Theme.of(context).textTheme.titleLarge
              ),
            ],
          ),
        ),
      ),
    );
  }
}