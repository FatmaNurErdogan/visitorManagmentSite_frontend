/// `Message.senderType` değerleri — backend'de serbest metin (bkz. prisma/schema.prisma).
class SenderType {
  SenderType._();

  static const visitor = 'VISITOR';
  static const staff = 'STAFF';
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderType,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String senderType;
  final String body;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderType: json['senderType'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
