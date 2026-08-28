class Appointment {
  final int id;
  final String doctor;
  final String date;
  final String time;
  final String notes;

  Appointment({
    required this.id,
    required this.doctor,
    required this.date,
    required this.time,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctor': doctor,
    'date': date,
    'time': time,
    'notes': notes,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctor: json['doctor'],
      date: json['date'],
      time: json['time'],
      notes: json['notes'],
    );
  }
}