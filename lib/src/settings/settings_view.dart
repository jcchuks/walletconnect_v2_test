// import 'dart:developer';

import 'dart:developer';

import 'package:app/src/walletconnect/qrcode.dart';
import 'package:app/src/walletconnect/wallet_connect_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import 'settings_controller.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({Key? key, required this.controller}) : super(key: key);

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16),
          // Glue the SettingsController to the theme selection DropdownButton.
          //
          // When a user selects a theme from the dropdown list, the
          // SettingsController is updated, which rebuilds the MaterialApp.
          child: Consumer<WalletConnectProvider>(builder: (context, wc, _) {
            SchedulerBinding.instance?.addPostFrameCallback((_) {
              // if (wc.isConnected && wc.isDialogOpen) {
              //   wc.isDialogOpen = false;
              //   Navigator.pop(context);
              // }
              if (wc.isConnected && !wc.isDialogOpen) {
                showQrCode(context, wc.outBandUri, wc);
              }
            });
            return Column(
              children: [
                DropdownButton<ThemeMode>(
                  // Read the selected themeMode from the controller
                  value: controller.themeMode,
                  // Call the updateThemeMode method any time the user selects a theme.
                  onChanged: controller.updateThemeMode,
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light Theme'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark Theme'),
                    )
                  ],
                ),
                TextButton(
                    onPressed: () {
                      if (!wc.isConnected) {
                        wc.connect();
                      }
                    },
                    child: const Text("Connect Wallet")),
                wc.isConnected
                    ? TextButton(
                        onPressed: () {
                          wc.newSession();
                        },
                        child: const Text("Connect Etherium Session"))
                    : Container(),
                wc.isConnected
                    ? TextButton(
                        onPressed: () {
                          wc.disconnect();
                        },
                        child: const Text("Disconnect"))
                    : Container(),
              ],
            );
          })),
    );
  }

  void showQrCode(
      BuildContext context, String wcUri, WalletConnectProvider wc) {
    wcUri = wcUri.replaceAll("https://", "https%3A%2F%2F2.");
    log("jhgj");
    log(wcUri);

    showDialog(
        context: context,
        builder: (_) {
          wc.isDialogOpen = true;
          return AlertDialog(
            content: WCQRcode(wcUri: wcUri),
          );
        });
  }
}
