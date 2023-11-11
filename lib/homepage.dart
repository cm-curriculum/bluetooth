import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'scanscreen.dart';


class HomePage extends StatefulWidget{
  @override
  State createState() => _State();
}

class _State extends State{
  // Set the name/id of the device you are scanning for
  final String deviceIDSubstring = 'CodingMinds';

  // The BluetoothAdapterState just tracks the current bluetooth state.
  // The states are unknown, unavailable, unauthorized, turningOn, on, turningOff, off
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;

  // The _adapterStateStateSubscription updates the _adapterState variable
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    super.initState();
    // Set up the _adapterStateStateSubscription to start tracking the bluetooth's state
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      setState(() { _adapterState = state; });
    });
  }


  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }


  Widget blueToothOffWidget(){
    // The the device is an Android, FlutterBluePlus can request the user to
    // turn on Bluetooth. iOS users have to turn it on manually

    // Return a button that turns on bluetooth if on an android
    if (Platform.isAndroid) {
      return Column(
        children: [
          ElevatedButton(
              onPressed: () async {
                try {
                  if (Platform.isAndroid) {
                    await FlutterBluePlus.turnOn();
                  }
                } catch (e) {
                  print(e);
                }
              },
              child: const Text("Turn Bluetooth On"))
        ],
      );
    }

    // Return a text asking the user to manually turn on bluetooth
    return Text(
      'Turn on your bluetooth.',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }



  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(title: const Text('Fall Detection Demo'),),
      body: Center(
        child:
          // if the bluetooth state is on the we show the scan screen
          // otherwise we as the user to turn on bluetooth
          _adapterState == BluetoothAdapterState.on ? ScanScreen(deviceID: deviceIDSubstring,) : blueToothOffWidget(),
      ),
    );
  }
}