import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class MainRemote extends StatefulWidget {
  final BluetoothDevice server;

  const MainRemote({super.key, required this.server});

  @override
  State<MainRemote> createState() => _MainRemoteState();
}


class _MainRemoteState extends State<MainRemote> {
  int currentPageIndex = 0;

  static const clientID = 0;
  BluetoothConnection? connection;

  String message = '';
  String _messageBuffer = '';

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  BluetoothData? _bluetoothData;

  final Map<String, int> FaceStates = {
    'Default': 0,
    'Angry': 1,
    'Doubt': 2,
    'Frown': 3,
    'LookUp': 4,
    'Sad': 5,
    'AudioReactive': 6,
    'Oscilloscope': 7,
    'SpectrumAnalyzer':8
  };

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen((Uint8List data) {
        //Data entry point
        print(ascii.decode(data));
        _onDataReceived(ascii.decode(data));
      }).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.gamepad),
            label: 'Controls',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text('Vesper Remote'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SafeArea(
        child: <Widget>[
          // ==============================
          //         Controls Page
          // ==============================
          Container(
              child: Column(children: [
                for (var entry in FaceStates.entries)
                  Container(
                    margin: EdgeInsets.all(5),
                    child: 
                    ElevatedButton(
                      onPressed: () { _setFaceVal(entry.value); },
                      child: Text(entry.key,)
                    ),
                  )
              ],)),
          // ==============================
          //         Settings Page
          // ==============================
          Page2()
        ][currentPageIndex],
      ),
    );
  }

  void _setFaceVal(int val) {
    if (_bluetoothData != null) {
      _bluetoothData?.faceState = val;
    }
    _sendCommand();
    print(val);
  }

  void _sendCommand() {
    if (_bluetoothData != null) {
      _sendMessage('<${BluetoothData.toJson(_bluetoothData!)}>');
      print(BluetoothData.toJson(_bluetoothData!));
    }
    print("SendCommand");
  }

  void _onDataReceived(String data) {
    Map<String, dynamic> messageMap = jsonDecode(data);
    _bluetoothData = BluetoothData.fromJson(messageMap);
    print(BluetoothData.toJson(_bluetoothData!));
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}

class BluetoothData {
  int faceState;
  int brightness;
  int accentBrightness;
  bool useMic;
  int micLevel;
  bool useBoop;
  bool spectrumMirror;
  int faceSize;
  int faceColor;

  BluetoothData(
      this.faceState,
      this.brightness,
      this.accentBrightness,
      this.useMic,
      this.micLevel,
      this.useBoop,
      this.spectrumMirror,
      this.faceSize,
      this.faceColor);

  BluetoothData.fromJson(Map<String, dynamic> json)
      : faceState = json['faceState'],
        brightness = json['brightness'],
        accentBrightness = json['accentBrightness'],
        useMic = json['useMic'],
        micLevel = json['micLevel'],
        useBoop = json['useBoop'],
        spectrumMirror = json['spectrumMirror'],
        faceSize = json['faceSize'],
        faceColor = json['faceColor'];

  static Map<String, dynamic> toJson(BluetoothData value) => {
        "faceState": value.faceState,
        "brightness": value.brightness,
        "accentBrightness": value.accentBrightness,
        "useMic": value.useMic,
        "micLevel": value.micLevel,
        "useBoop": value.useBoop,
        "spectrumMirror": value.spectrumMirror,
        "faceSize": value.faceSize,
        "faceColor": value.faceColor
      };
}

/*class Page1 extends StatelessWidget {
  Page1({Key? key}) : super(key: key);

  final mainRemote = _MainRemoteState();

  @override
  Widget build(BuildContext context) {
    return;
  }
}*/

class Page2 extends StatelessWidget {
  const Page2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        Center(
          child: Text("Page 2"),
        ),
      ],
    ));
  }
}
