import 'package:flutter/material.dart';

const routineColors = <int>[
  0xFF6750A4,
  0xFF00696D,
  0xFF8B5000,
  0xFFBA1A1A,
  0xFF326D20,
  0xFF005FAF,
  0xFF9A4069,
  0xFF455A64,
];

const routineIcons = <IconData>[
  Icons.fitness_center,
  Icons.self_improvement,
  Icons.directions_run,
  Icons.restaurant,
  Icons.water_drop,
  Icons.menu_book,
  Icons.spa,
  Icons.bedtime,
  Icons.music_note,
  Icons.work_outline,
  Icons.pets,
];

IconData iconFromCodePoint(int codePoint) =>
    IconData(codePoint, fontFamily: 'MaterialIcons');
