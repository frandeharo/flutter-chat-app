import 'package:flutter/material.dart';

class BotonAzul extends StatelessWidget {
  final String etiqueta;
  final VoidCallback onPressed;

  const BotonAzul({Key? key, required this.etiqueta, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        primary: Colors.blue,
        shape: StadiumBorder(),
      ),
      onPressed: this.onPressed,
      child: Container(
        width: double.infinity,
        height: 50,
        child: Center(
            child: Text(
          this.etiqueta,
          style: TextStyle(fontSize: 20),
        )),
      ),
    );
  }
}
