import 'package:drift/drift.dart' as drift;

import '../data/database/database.dart';

enum LeadStatus {
  hot('Hot'),
  warm('Warm'),
  cold('Cold'),
  lost('Lost'),
  closed('Closed');

  const LeadStatus(this.value);
  final String value;
}

class LeadModel {
  final int? id;
  final String companyName;
  final String contactPersonName;
  final String mobile;
  final String? email;
  final String? productPitched;
  final String? discussion;
  final DateTime? followUpDate;
  final String? followUpTime;
  final LeadStatus status;
  final int? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LeadModel({
    this.id,
    required this.companyName,
    required this.contactPersonName,
    required this.mobile,
    this.email,
    this.productPitched,
    this.discussion,
    this.followUpDate,
    this.followUpTime,
    this.status = LeadStatus.hot,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  factory LeadModel.fromDrift(Lead lead) {
    return LeadModel(
      id: lead.id,
      companyName: lead.companyName,
      contactPersonName: lead.contactPersonName,
      mobile: lead.mobile,
      email: lead.email,
      productPitched: lead.productPitched,
      discussion: lead.discussion,
      followUpDate: lead.followUpDate,
      followUpTime: lead.followUpTime,
      status: _leadStatusFromString(lead.status),
      ownerId: lead.ownerId,
      createdAt: lead.createdAt,
      updatedAt: lead.updatedAt,
    );
  }

  LeadsCompanion toCompanion() {
    return LeadsCompanion(
      id: id == null ? const drift.Value.absent() : drift.Value(id!),
      companyName: drift.Value(companyName),
      contactPersonName: drift.Value(contactPersonName),
      mobile: drift.Value(mobile),
      email: drift.Value(email),
      productPitched: drift.Value(productPitched),
      discussion: drift.Value(discussion),
      followUpDate: drift.Value(followUpDate),
      followUpTime: drift.Value(followUpTime),
      status: drift.Value(status.value),
      ownerId: drift.Value(ownerId),
      createdAt: createdAt == null
          ? const drift.Value.absent()
          : drift.Value(createdAt!),
      updatedAt: drift.Value(updatedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'contactPersonName': contactPersonName,
      'mobile': mobile,
      'email': email,
      'productPitched': productPitched,
      'discussion': discussion,
      'followUpDate': followUpDate?.toIso8601String(),
      'followUpTime': followUpTime,
      'status': status.value,
      'ownerId': ownerId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] as int?,
      companyName: (json['companyName'] ?? '').toString(),
      contactPersonName: (json['contactPersonName'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      email: json['email'] as String?,
      productPitched: json['productPitched'] as String?,
      discussion: json['discussion'] as String?,
      followUpDate: json['followUpDate'] == null
          ? null
          : DateTime.tryParse(json['followUpDate'].toString()),
      followUpTime: json['followUpTime'] as String?,
      status: _leadStatusFromString((json['status'] ?? 'Hot').toString()),
      ownerId: json['ownerId'] as int?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
    );
  }

  LeadModel copyWith({
    int? id,
    String? companyName,
    String? contactPersonName,
    String? mobile,
    String? email,
    String? productPitched,
    String? discussion,
    DateTime? followUpDate,
    String? followUpTime,
    LeadStatus? status,
    int? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPersonName: contactPersonName ?? this.contactPersonName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      productPitched: productPitched ?? this.productPitched,
      discussion: discussion ?? this.discussion,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpTime: followUpTime ?? this.followUpTime,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

LeadStatus _leadStatusFromString(String raw) {
  switch (raw.toLowerCase()) {
    case 'hot':
      return LeadStatus.hot;
    case 'warm':
      return LeadStatus.warm;
    case 'cold':
      return LeadStatus.cold;
    case 'lost':
      return LeadStatus.lost;
    case 'closed':
      return LeadStatus.closed;
    default:
      return LeadStatus.hot;
  }
}
