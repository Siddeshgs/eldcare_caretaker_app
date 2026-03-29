class Medicine {
  final int id;              // Unique stable ID for notifications
  final String name;
  final String dosage;
  final String time;         // Stored in "hh:mm a" format (e.g., 08:30 PM)

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'time': time,
  };

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      time: json['time'],
    );
  }
}