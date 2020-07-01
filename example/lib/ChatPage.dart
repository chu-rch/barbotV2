import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:holding_gesture/holding_gesture.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = List<_Message>();
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;

  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  get geolocator => null;

  get appBar => null;

  bool modeManuel = false;
  String getMM(bool mm){
    if(mm = true) Text("Activé");
    else Text("Désactivé");
  }

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

      connection.input.listen(_onDataReceived).onDone(() {
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
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  /* @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                    _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();*/

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.home)),
                Tab(icon: Icon(Icons.settings_remote)),
              ],
              unselectedLabelColor: Colors.black38,
              indicatorColor: Colors.white,
            ),
            title: Text('Barbot : Le robot pompier'),
          ),
          body: TabBarView(
            children: [
              Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Card(
                              //color: Colors.red,
                              child: Container(
                                width: 170,
                                height: 200,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                          padding: new EdgeInsets.all(15.0),
                                          height: 110.0,
                                          child: Image.asset(
                                              'assets/Image/safe.png')),
                                      Text("Alerte Feu",
                                          style: TextStyle(
                                            fontSize: 24.0,
                                          )),
                                    ]),
                              ),
                            ),
                            Card(
                              //color: Colors.red,
                              child: Container(
                                width: 170,
                                height: 200,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                          padding: new EdgeInsets.all(15.0),
                                          height: 110.0,
                                          child: Image.asset(
                                              'assets/Image/eau.png')),
                                      Text("Réservoir",
                                          style: TextStyle(
                                            fontSize: 24.0,
                                          )),
                                    ]),
                              ),
                            ),
                          ]),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Card(
                              //color: Colors.red,
                              child: Container(
                                width: 170,
                                height: 200,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                          padding: new EdgeInsets.all(15.0),
                                          height: 110.0,
                                          child: Image.asset(
                                              'assets/Image/manual.jpg')),
                                      Text("Mode manuel",
                                          style: TextStyle(
                                            fontSize: 24.0,
                                          )),
                                      Text(getMM(modeManuel))
                                    ]),
                              ),
                            ),
                          ]),
                    ]),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(
                    "CONTROLE LANCE",
                    style: TextStyle(
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  Container(
                      color: Colors.lightBlue,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              HoldDetector(
                                  onHold: () => _sendMessage("SL"),
                                  child: FloatingActionButton(
                                    heroTag: "btn1",
                                    onPressed: () => _sendMessage("SL"),
                                    child:
                                        Center(child: Icon(Icons.arrow_back)),
                                    backgroundColor: Colors.red,
                                    focusColor: Colors.black26,
                                  )),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: HoldDetector(
                                  onHold: () => _sendMessage("SU"),
                                  child: FloatingActionButton(
                                    heroTag: "btn2",
                                    onPressed: () => _sendMessage("SU"),
                                    child:
                                        Center(child: Icon(Icons.arrow_upward)),
                                    backgroundColor: Colors.blueGrey,
                                    focusColor: Colors.black26,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: HoldDetector(
                                  onHold: () => _sendMessage("SD"),
                                  child: FloatingActionButton(
                                    heroTag: "btn3",
                                    onPressed: () => _sendMessage("SD"),
                                    child: Center(
                                        child: Icon(Icons.arrow_downward)),
                                    backgroundColor: Colors.blueGrey,
                                    focusColor: Colors.black26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              HoldDetector(
                                onHold: () => _sendMessage("SR"),
                                child: FloatingActionButton(
                                  heroTag: "btn4",
                                  onPressed: () => _sendMessage("SR"),
                                  child:
                                      Center(child: Icon(Icons.arrow_forward)),
                                  backgroundColor: Colors.red,
                                  focusColor: Colors.black26,
                                ),
                              )
                            ],
                          ),
                        ],
                      )),
                  Text(
                    "CONTROLE ROBOT",
                    style: TextStyle(
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.bold,
                      fontSize: 25,
                    ),
                  ),
                  Container(
                      color: Colors.grey,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              HoldDetector(
                                onHold: () => _sendMessage("ML"),
                                child: FloatingActionButton(
                                  heroTag: "btn5",
                                  onPressed: () => _sendMessage("ML"),
                                  child: Center(child: Icon(Icons.arrow_back)),
                                  backgroundColor: Colors.blueGrey,
                                  focusColor: Colors.black26,
                                ),
                              )
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: HoldDetector(
                                  onHold: () => _sendMessage("MU"),
                                  child: FloatingActionButton(
                                    heroTag: "btn6",
                                    onPressed: () => _sendMessage("MU"),
                                    child:
                                        Center(child: Icon(Icons.arrow_upward)),
                                    backgroundColor: Colors.red,
                                    focusColor: Colors.black26,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: HoldDetector(
                                  onHold: () => _sendMessage("MD"),
                                  child: FloatingActionButton(
                                    heroTag: "btn7",
                                    onPressed: () => _sendMessage("MD"),
                                    child: Center(
                                        child: Icon(Icons.arrow_downward)),
                                    backgroundColor: Colors.red,
                                    focusColor: Colors.black26,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: <Widget>[
                              HoldDetector(
                                onHold: () => _sendMessage("MR"),
                                child: FloatingActionButton(
                                  heroTag: "btn8",
                                  onPressed: () => _sendMessage("MR"),
                                  child:
                                      Center(child: Icon(Icons.arrow_forward)),
                                  backgroundColor: Colors.blueGrey,
                                  focusColor: Colors.black26,
                                ),
                              )
                            ],
                          ),
                        ],
                      )),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        HoldDetector(
                          onHold: () => _sendMessage("W"),
                          child: FloatingActionButton(
                            heroTag: "btn9",
                            onPressed: () => _sendMessage("W"),
                            child: Center(child: Text("EAU")),
                          ),
                        ),
                        HoldDetector(
                          onHold: () => _sendMessage("H"),
                          child: FloatingActionButton(
                            heroTag: "btn10",
                            onPressed: () => _sendMessage("H"),
                            backgroundColor: Colors.red,
                            child: Center(
                              child: Icon(Icons.volume_up),
                            ),
                          ),
                        ),
                        HoldDetector(
                          onHold: () => _sendMessage("ST"),
                          child: FloatingActionButton(
                            heroTag: "btn11",
                            onPressed: () {
                              _sendMessage("ST");
                              modeManuel = true;
                            },
                            child: Center(child: Text("Start")),
                          ),
                        ),
                        HoldDetector(
                            onHold: () => _sendMessage("SP"),
                            child: FloatingActionButton(
                              heroTag: "btn12",
                              onPressed: () {
                                _sendMessage("SP");
                                modeManuel = false;
                              },
                              backgroundColor: Colors.red,
                              child: Center(child: Text("Stop")),
                            )),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );

    /*

  final Geolocator geolocator = Geolocator()
    ..forceAndroidLocationManager;

  Position _currentPosition;
  String _currentAddress;

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });

      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geolocator.placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
        "${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  */
  }
}
