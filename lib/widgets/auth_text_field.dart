import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final TextEditingController editingController;
  final bool passwordField;
  final TextInputAction textInputAction;
  final Color backgroundColor;
  const AuthTextField(
      {super.key,
      required this.icon,
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
      child: TextFormField(
        textInputAction: textInputAction,
        controller: editingController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18.0,
        ),
        obscureText: passwordField,
        enableSuggestions: !passwordField,
        autocorrect: false,
        maxLines: 1,
        decoration: InputDecoration(
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: Colors.white,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
