import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final TextEditingController editingController;
  final bool passwordField;
  final TextInputAction textInputAction;
  final Color backgroundColor;
  const AuthTextField(
      {required this.icon,
      required this.hintText,
      required this.editingController,
      required this.passwordField,
      required this.textInputAction,
      required this.backgroundColor});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        textInputAction: textInputAction,
        controller: editingController,
        style: const TextStyle(
          color: Colors.white,
        ),
        obscureText: passwordField,
        enableSuggestions: !passwordField,
        autocorrect: false,
        maxLines: 1,
        decoration: InputDecoration(
          hintStyle: const TextStyle(color: Colors.white),
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: Colors.white,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
            borderSide: BorderSide(color: Colors.white, width: 2.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(16),
            ),
            borderSide: BorderSide(color: Colors.white, width: 4.0),
          ),
        ),
      ),
    );
  }
}
