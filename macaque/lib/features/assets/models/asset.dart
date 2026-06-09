import 'package:equatable/equatable.dart';

enum AssetStatus {
  available,
  missing,
}

class Asset extends Equatable {
  final String id;
  final String filename;
  final String path;
  final AssetStatus status;
  final DateTime lastModified;

  const Asset({
    required this.id,
    required this.filename,
    required this.path,
    required this.status,
    required this.lastModified,
  });

  Asset copyWith({
    String? id,
    String? filename,
    String? path,
    AssetStatus? status,
    DateTime? lastModified,
  }) {
    return Asset(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      path: path ?? this.path,
      status: status ?? this.status,
      lastModified: lastModified ?? this.lastModified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'path': path,
      'status': status.name,
      'lastModified': lastModified.toIso8601String(),
    };
  }

  factory Asset.fromJson(Map<String, dynamic> json) {
    return Asset(
      id: json['id'] as String,
      filename: json['filename'] as String,
      path: json['path'] as String,
      status: AssetStatus.values.byName(json['status'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
    );
  }

  @override
  List<Object?> get props => [id, filename, path, status, lastModified];
}
