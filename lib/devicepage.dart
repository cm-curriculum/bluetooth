import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DevicePage extends StatefulWidget{

  final BluetoothDevice device;

  const DevicePage({super.key, required this.device});

  @override
  State createState() => _State();

}

class _State extends State<DevicePage>{

  //Create a ValueNotifier to update the UI without calling setstate().
  ValueNotifier<String> bluetoothData = ValueNotifier("");

  bool fallen = false;


  @override
  void initState() {
    super.initState();

    // This block of code listens to the state of the connected bluetooth device,
    // and if it gets disconnected it goes back to the previous page (the scan page)
    widget.device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        Navigator.pop(context);
      }
    });
  }

  // This function converts the byte data from the uart service to a string
  String bytesToString(List<int> bytes) {
    String charValues = '';
    for(int i in bytes){
      charValues = charValues + String.fromCharCode(i) ;
    }

    return charValues;
  }


  // This function converts the byte data from the uart service to an integer
  int bytesToInteger(List<int> bytes) {
    String charValues = '';
    for(int i in bytes){
      charValues = charValues + String.fromCharCode(i) ;
    }

    print(charValues);
    return int.parse(charValues);
  }

  // This function converts the byte data from the uart service to an List of doubles
  List<double> bytesToDoubleList(List<int> bytes) {
    String charValues = '';
    for(int i in bytes){
      charValues = charValues + String.fromCharCode(i) ;
    }

    print(charValues);
    List<String> splitVals = charValues.split(',');

    List<double> doublesList = splitVals.map((str) => double.parse(str)).toList();

    return doublesList;
  }


  Future<bool> getValueChangeFromCharacteristics(BluetoothService service) async {
    var characteristics = service.characteristics;

    for(BluetoothCharacteristic characteristic in characteristics) {
      await characteristic.setNotifyValue(true);

      // get the incoming data from the bluetooth device, decode the byte to a string and update the state
      // checks if the incoming data is the string "fallen"
      StreamSubscription<dynamic> stream = characteristic.lastValueStream.listen((value) {
        print(value);
        String data = bytesToString(value);
        print("Incoming Data: $data");
        bluetoothData.value = data;


        // check if the data is "fallen" to update the state for fallen.
        if (data.toString() == "fallen"){
          fallen = true;
          setState(() {});
        }

      });
    }

    return true;
  }


  Widget bodyView(){
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Card(
            child: Column(
              children: [
                const Row(),
                Text(
                  "Incoming Data",
                  style: Theme.of(context).textTheme.titleLarge,
                ),

                // auto updates the ui when the bluetoothData variable changes
                ValueListenableBuilder<String>(
                    valueListenable: bluetoothData,
                    builder: (context, value, child){

                      return bluetoothData.value.isNotEmpty ?
                        Text('${bluetoothData.value} % ',
                          style: Theme.of(context).textTheme.displayMedium,
                        ) :
                        const Text('LOADING...');
                    }
                ),
              ],
            ),
          ),
        ),

        // if the app thinks the device has fallen, this will show a a fallen message
        fallen ?
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
            child: Text( 'fallen',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          ) :
          Container(),


        // if the app thinks the device has fallen, this will show a dismiss button
        fallen ? ElevatedButton(
                onPressed: (){
                  setState(() {
                    fallen = false;
                  });
                },
                child: const Text('Dismissed')
              )
            :
            Container()
      ],
    );
  }


  FutureBuilder bluetoothBody(){
    // the UUID of the UART service
    // check what the UUID is on the bluetooth device
    String uart_uuid = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";


    // look for the services that the bluetooth device has.
    // here were are only looking for the first UART service
    return FutureBuilder<List<BluetoothService>>(
        future: widget.device.discoverServices(),
        builder: (BuildContext context, AsyncSnapshot<List<BluetoothService>> snapshot){

          //
          if (snapshot.hasData){
            List<BluetoothService> services = snapshot.data!;
            bool found = false;
            for (var service in services) {
              // make sure to only connect to one service
              if(found){ continue; }
              if(uart_uuid == service.uuid.toString()){
                // listen to the changes from the uart service
                getValueChangeFromCharacteristics(service);
                found = true;
              }
            }
            return bodyView();

          }
          // Catch any errors
          else if (snapshot.hasError){
            return const Center(child: Text('An Error Has Occurred'));
          }
          // Waiting for the future to return
          return const Center(child: CircularProgressIndicator());
        }
    );
  }


  @override
  Widget build(context){
    return Scaffold(
      appBar: AppBar(
          title: const Text('Device')
      ),
      body: Column(
        children: [
          bluetoothBody(),
        ],
      ),
    );
  }


}