import 'package:flutter/material.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final Function(String?) onSelected;

  CustomFilterChip({
    required this.label,
    required this.options,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(selected ?? label),
      onSelected: (_) {
        showModalBottomSheet(
          context: context,
          builder: (context) => ListView(
            children: [
              ListTile(
                title: Text('Clear $label'),
                onTap: () {
                  onSelected(null);
                  Navigator.pop(context);
                },
              ),
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
