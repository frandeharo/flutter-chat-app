import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/services/socket_service.dart';

import 'package:chat_app/models/mensajes_response.dart';

import 'package:chat_app/widgets/chat_message.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final _textController = new TextEditingController();
  final _focusNode = new FocusNode();
  bool _estaEscribiendo = false;

  ChatService? chatService;
  SocketService? socketService;
  AuthService? authService;

  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // No se puede redibujar a menos que esté en un callback
    this.chatService = Provider.of<ChatService>(context, listen: false);
    this.socketService = Provider.of<SocketService>(context, listen: false);
    this.authService = Provider.of<AuthService>(context, listen: false);

    this.socketService!.socket!.on('mensaje-personal', _escucharMensaje);

    _cargarHistorial(this.chatService!.usuarioPara!.uid);
  }

  void _cargarHistorial(String uid) async {
    List<Mensaje>? chat = await this.chatService!.getChat(uid);

    final historial = chat!.map((m) => new ChatMessage(
          texto: m.mensaje,
          uid: m.de,
          animationController: new AnimationController(vsync: this, duration: Duration(milliseconds: 100))..forward(),
        ));

    setState(() {
      _messages.insertAll(0, historial);
    });
  }

  void _escucharMensaje(dynamic payload) {
    ChatMessage message = new ChatMessage(
        texto: payload['mensaje'],
        uid: payload['de'],
        animationController: new AnimationController(vsync: this, duration: Duration(milliseconds: 350)));
    setState(() {
      _messages.insert(0, message);
    });

    message.animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final usuarioPara = this.chatService!.usuarioPara;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            CircleAvatar(
              child: Text(
                usuarioPara!.nombre.substring(0, 2),
                style: TextStyle(fontSize: 12),
              ),
              maxRadius: 14,
              backgroundColor: Colors.blueAccent[100],
            ),
            SizedBox(height: 3),
            Text(
              usuarioPara.nombre,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          ],
        ),
      ),
      body: Container(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _messages[i],
                reverse: true,
              ),
            ),
            Divider(
              height: 1,
            ),
            Container(
              color: Colors.white,
              height: 50,
              child: _inputChat(),
            )
          ],
        ),
      ),
    );
  }

  Widget _inputChat() {
    return SafeArea(
        child: Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmit,
              onChanged: (String texto) {
                setState(() {
                  if (texto.trim().length > 0) {
                    _estaEscribiendo = true;
                  } else {
                    _estaEscribiendo = false;
                  }
                });
              },
              decoration: InputDecoration.collapsed(
                hintText: 'Enviar mensaje',
              ),
              focusNode: _focusNode,
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.0),
            child: Platform.isIOS
                ? CupertinoButton(
                    child: Text('Enviar'),
                    onPressed: _estaEscribiendo ? () => _handleSubmit(_textController.text.trim()) : null,
                  )
                : Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    child: IconTheme(
                      data: IconThemeData(color: Colors.blue[400]),
                      child: IconButton(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onPressed: _estaEscribiendo ? () => _handleSubmit(_textController.text.trim()) : null,
                        icon: Icon(Icons.send),
                      ),
                    ),
                  ),
          )
        ],
      ),
    ));
  }

  _handleSubmit(String texto) {
    if (texto.length == 0) return;

    _focusNode.requestFocus();
    _textController.clear();

    final newMessage = new ChatMessage(
      texto: texto,
      uid: authService!.usuario!.uid,
      animationController: AnimationController(vsync: this, duration: Duration(milliseconds: 300)),
    );
    _messages.insert(0, newMessage);
    newMessage.animationController.forward();

    setState(() {
      _estaEscribiendo = false;
    });

    socketService!.emit('mensaje-personal',
        {'de': this.authService!.usuario!.uid, 'para': this.chatService!.usuarioPara!.uid, 'mensaje': texto});
  }

  @override
  void dispose() {
    // Limpiar
    for (ChatMessage message in _messages) {
      message.animationController.dispose();
    }

    this.socketService!.socket!.off('mensaje-personal');
    super.dispose();
  }
}
