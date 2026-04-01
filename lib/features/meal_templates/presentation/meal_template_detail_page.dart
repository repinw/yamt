import 'package:flutter/material.dart';

class MealTemplateDetailPage extends StatelessWidget {
  const MealTemplateDetailPage({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vorlage')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'TODO: Detailansicht fuer Meal Template $templateId bauen. '
          'Hier sollen Zutaten-Tabelle, Portions-Skalierung und spaeter '
          'Inventar-Zuordnung hin.',
        ),
      ),
    );
  }
}
