import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:chat_app/models/usuario.dart';

import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/services/socket_service.dart';
import 'package:chat_app/services/usuarios_service.dart';

class UsuariosPage extends StatefulWidget {
  @override
  _UsuariosPageState createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  final usuarioService = new UsuariosService();

  List<Usuario> usuarios = [];

  @override
  void initState() {
    _cargarUsuarios();
    super.initState();
  }

  // final usuarios = [
  //   Usuario(uid: '1', online: true, email: 'macarenapinto02@gmail.com', nombre: 'Macarena'),
  //   Usuario(uid: '2', online: true, email: 'frandeharo@gmail.com', nombre: 'Fran'),
  //   Usuario(uid: '3', online: false, email: 'salseo@salseo.com', nombre: 'Salseo'),
  // ];

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final socketService = Provider.of<SocketService>(context);
    final usuario = authService.usuario;

    return Scaffold(
        appBar: AppBar(
          title: Text(
            usuario!.nombre,
            style: TextStyle(color: Colors.black54),
          ),
          elevation: 1,
          backgroundColor: Colors.white,
          leading: IconButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, 'login');
              socketService.disconnect();
              AuthService.deleteToken();
            },
            icon: Icon(
              Icons.exit_to_app,
              color: Colors.black54,
            ),
          ),
          actions: [
            Container(
                margin: EdgeInsets.only(right: 10),
                child: (socketService.serverStatus == ServerStatus.Online)
                    ? Icon(Icons.check_circle, color: Colors.blue[400])
                    : Icon(Icons.offline_bolt, color: Colors.redAccent))
          ],
        ),
        body: SmartRefresher(
          controller: _refreshController,
          child: _listViewUsuarios(),
          onRefresh: _cargarUsuarios,
          header: WaterDropHeader(
            complete: Icon(
              Icons.check,
              color: Colors.blue[400],
            ),
            waterDropColor: Colors.blueAccent,
          ),
        ));
  }

  ListView _listViewUsuarios() {
    return ListView.separated(
      physics: BouncingScrollPhysics(),
      itemBuilder: (_, i) => _usuarioListTile(usuarios[i]),
      separatorBuilder: (_, i) => Divider(),
      itemCount: usuarios.length,
    );
  }

  ListTile _usuarioListTile(Usuario usuario) {
    return ListTile(
      title: Text(usuario.nombre),
      subtitle: Text(usuario.email),
      leading: CircleAvatar(
        backgroundColor: Colors.blue[200],
        child: Text(usuario.nombre.substring(0, 2)),
      ),
      trailing: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: usuario.online ? Colors.green[300] : Colors.red,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      onTap: () {
        final chatService = Provider.of<ChatService>(context, listen: false);
        chatService.usuarioPara = usuario;
        Navigator.pushNamed(context, 'chat');
      },
    );
  }

  _cargarUsuarios() async {
    this.usuarios = await usuarioService.getUsuarios();
    setState(() {});

    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use refreshFailed()
    _refreshController.refreshCompleted();
  }
}
