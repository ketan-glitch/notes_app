import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Note {
  final String? id;
  String? title;
  String? content;
  Color? color;
  NoteState? state;
  final DateTime? createdAt;
  DateTime? modifiedAt;

  /// Instantiates a [Note].
  Note({
    this.id,
    this.title,
    this.content,
    this.color,
    this.state,
    DateTime? createdAt,
    DateTime? modifiedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json["id"],
        title: json["title"],
        content: json["note"],
        color: json["color"],
        state: json["state"],
        createdAt: json["createdAt"],
        modifiedAt: json["modifiedAt"],
      );

  /// Transforms the Firestore query [snapshot] into a list of [Note] instances.
  static List<Note?> fromQuery(QuerySnapshot snapshot) => snapshot != null ? toNotes(snapshot) : [];
}

/// State enum for a note.
enum NoteState {
  unspecified,
  pinned,
  archived,
  deleted,
}

/// Transforms the query result into a list of notes.
List<Note?> toNotes(QuerySnapshot query) => query.docs.map((d) => toNote(d)).where((n) => n != null).toList();

/// Transforms a document into a single note.
Note? toNote(DocumentSnapshot doc) => doc.exists
    ? Note(
        id: doc.id,
        title: doc['title'],
        content: doc['content'],
        state: NoteState.values[doc['state'] ?? 0],
        color: _parseColor(doc['color']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(doc['createdAt'] ?? 0),
        modifiedAt: DateTime.fromMillisecondsSinceEpoch(doc['modifiedAt'] ?? 0),
      )
    : null;

Color _parseColor(int? colorInt) => Color(colorInt ?? 0xFFFFFFFF);
