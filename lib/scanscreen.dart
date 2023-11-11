import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'devicepage.dart';

class ScanScreen extends StatefulWidget {

  // the deviceID variable is the name of the bluetooth device.
  final String deviceID;

  const ScanScreen({Key? key, required this.deviceID}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  // Create two StreamSubscription to track changes in the scan results and the app is scanning.
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();


    // Set up the StreamSubscription for the scan results.
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      setState(() {});
    });

    // Set up the StreamSubscription for the scan results.
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }


  void navigateToDevicePage(BluetoothDevice device){
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {

    }


    Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DevicePage(device: device))
    ).then( (value) async{
      if(device.isConnected){
        await device.disconnect();
        print('disconnect');
      }
    });
  }



  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    setState(() {});
    return Future.delayed(Duration(milliseconds: 500));
  }



  void onDevicePress(BluetoothDevice device) async {
    // This function is called when a listview for a device is tapped.
    // This function will navigate to the DevicePage for the tapped device, if we can connect to the device.

    await device.connect();

    if(device.isConnected){
      print('connected');
      navigateToDevicePage(device);
    }
    else{
      print('error connecting');
    }
  }

  Widget deviceListViewBuilder(){
    // Build a ListView for the bluetooth devices that contain the deviceID in their name
    List<ScanResult> results = [];
    for(ScanResult r in _scanResults){
      if(r.advertisementData.localName.contains(widget.deviceID)){
        results.add(r);
      }
    }

    return ListView.builder(
        shrinkWrap: true,
        itemCount: results.length,
        itemBuilder: (context, index){
          print('Name: ${results[index].rssi.toString()}');
          print('advertisementData: ${results[index].advertisementData}');
          var adv = results[index].advertisementData;
          BluetoothDevice device = results[index].device;
          return Card(child:
          ListTile(
            title: Text(adv.localName),
            trailing: const Icon(Icons.chevron_right),
            onTap: (){ onDevicePress(device); },
          ),
          );
        }
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: onRefresh,
            child: const Text('Refresh')
        ),
        Expanded(child: deviceListViewBuilder()),
      ],
    );


  }
}