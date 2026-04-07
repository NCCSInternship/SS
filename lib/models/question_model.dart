class Question {
  final String text;
  final String? imagePath;
  final String type; // 'MCQ' or 'Subjective'
  final List<String>? options;
  final String? correctAnswer;
  final String? program;
  final String? className;
  final String? subject;
  final String? marks;
  final bool isForBank;
  final String? exerciseTitle;
  final String? institution; // New field
  final String? board;       // New field

  Question({
    required this.text,
    this.imagePath,
    required this.type,
    this.options,
    this.correctAnswer,
    this.program,
    this.className,
    this.subject,
    this.marks,
    this.isForBank = false,
    this.exerciseTitle,
    this.institution,
    this.board,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'imagePath': imagePath,
      'type': type,
      'options': options,
      'correctAnswer': correctAnswer,
      'program': program,
      'className': className,
      'subject': subject,
      'marks': marks,
      'isForBank': isForBank,
      'exerciseTitle': exerciseTitle,
      'institution': institution,
      'board': board,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      text: map['text'] ?? '',
      imagePath: map['imagePath'],
      type: map['type'] ?? 'Subjective',
      options: map['options'] != null ? List<String>.from(map['options']) : null,
      correctAnswer: map['correctAnswer'],
      program: map['program'],
      className: map['className'],
      subject: map['subject'],
      marks: map['marks'],
      isForBank: map['isForBank'] ?? false,
      exerciseTitle: map['exerciseTitle'],
      institution: map['institution'],
      board: map['board'],
    );
  }
}
