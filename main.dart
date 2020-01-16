import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modbus_tcp/ModbusTCP_Master.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Modbus TCP test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  ModbusTCP_Master ModbusTCP;//=ModbusTCP_Master("10.0.2.2");
  Int16List write_buffer=Int16List(5);
  Int16List write_buffer2=Int16List(10);
  
  List<bool> coil_buffer=[
    false,false,false,false,false,false,false,false,
    false,false,false,false,false,false,false,false,
  ];
  bool state1=false;
  String values="", connectionState="connection state: false...";

  TextEditingController _IPController=TextEditingController(text:"192.168.1.63");  //192.168.1.63  10.0.2.2
  TextEditingController _portController=TextEditingController(text:"502");
  @override
  Widget build(BuildContext context) {
    write_buffer[0]=1955;
    write_buffer[1]=1956;
    write_buffer[2]=1957;
    write_buffer[3]=1958;
    write_buffer[4]=1959;
    write_buffer2[0]=100;
    write_buffer2[1]=11;
    write_buffer2[2]=22;
    write_buffer2[3]=33;
    write_buffer2[4]=44;
    write_buffer2[5]=55;
    write_buffer2[6]=66;
    write_buffer2[7]=77;
    write_buffer2[8]=88;
    write_buffer2[9]=99;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 40,),
            Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("IP:", style: TextStyle(color: Colors.blue),),
                      Container(
                        height: 20,
                        width: 150,
                        child: TextFormField(
                          controller: _IPController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.text ,
                          //	inputFormatters:  [WhitelistingTextInputFormatter(RegExp("[0-9]"))],
                          scrollPadding: const EdgeInsets.all(10.0),
                          decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                                  hintText: "input IP address here",
                                  hintStyle: TextStyle(fontSize: 14.0, color: Color(0xFF999999)),
                                  border: InputBorder.none),
                        ),
                      ),
                      SizedBox(width: 20,),
                      Text("Port:", style: TextStyle(color: Colors.blue), ),
                      Container(
                        height: 20,
                        width: 150,
                        child: TextFormField(
                          controller: _portController,
                          keyboardType: TextInputType.number ,
                          textAlign: TextAlign.center,
                          inputFormatters:  [WhitelistingTextInputFormatter(RegExp("[0-9]"))],
                          scrollPadding: const EdgeInsets.all(10.0),
                          decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                                  hintText: "input port number here",
                                  hintStyle: TextStyle(fontSize: 14.0, color: Color(0xFF999999)),
                                  border: InputBorder.none),
                        ),
                      ),
                    ]
            ),
            SizedBox(height: 5,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  child: Text("开启连接..."),
                  onPressed: (){
                    ModbusTCP=ModbusTCP_Master(_IPController.text, int.parse(_portController.text));
                    ModbusTCP.EnableModbusTCP().then((value){
                      setState(() {
                        connectionState="connection state: $value...";
                      });
                    });
                  },
                ),
                SizedBox(width: 5,),
                RaisedButton(
                  child: Text("停止连接..."),
                  onPressed: (){
                    ModbusTCP.DisableModbusTCP();
                    setState(() {
                      connectionState="connection state: false...";
                    });
                    
                  },
                ),
                SizedBox(width: 5,),
                Text(connectionState),
              ],
            ),
            SizedBox(height: 5,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  child: Text("写多Int16"),
                  onPressed: (){
                    ModbusTCP.WriteRegisters_Int16(0, 10, write_buffer2);
                    ModbusTCP.WriteRegisters_Int16(10, 5, write_buffer);
                    /*ModbusTCP.ModbusTCP_WriteSingleRegister(16, 32767);
                    state1=!state1;
                    //ModbusTCP.ModbusTCP_WriteSingleCoil(0,state1);
                    List<bool> temp1=[
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                    ];
                    ModbusTCP.ModbusTCP_WriteCoils(0, 16, temp1);*/
                  },
                ),
                SizedBox(width: 5,),
                RaisedButton(
                  child: Text("写单Int16"),
                  onPressed: (){
                    ModbusTCP.WriteSingleRegister_Int16(16, 32767);
                  },
                ),
                SizedBox(width: 5,),
                RaisedButton(
                  child: Text("写多Bit"),
                  onPressed: (){
                    state1=!state1;
                    //ModbusTCP.ModbusTCP_WriteSingleCoil(0,state1);
                    List<bool> temp1=[
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                      state1,
                    ];
                    ModbusTCP.WriteBits(0, 16, temp1);
                  },
                ),
                SizedBox(width: 5,),
                RaisedButton(
                  child: Text("写单Bit"),
                  onPressed: (){
                    state1=!state1;
                    ModbusTCP.WriteSingleBit(0,state1);
                  },
                ),
              ],
            ),
            SizedBox(height: 5,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  child: Text("写单Int32"),
                  onPressed: (){
                    ModbusTCP.WriteSingleRegister_Int32(100, 2718);
                  },
                ),
                SizedBox(width: 5,),
                RaisedButton(
                  child: Text("写单Float"),
                  onPressed: (){
                    ModbusTCP.WriteSingleRegister_Float(200, 2718.5);
                  },
                ),
                SizedBox(width: 5,),
                RaisedButton(
                  child: Text("写多Int32"),
                  onPressed: (){
                    Int32List temp=Int32List(5);
                    for(int i=0;i<5;i++)
                      temp[i]=231+i;
                    ModbusTCP.WriteRegisters_Int32(100,5, temp);
                  },
                ),
                SizedBox(width: 5,),
                RaisedButton(
                  child: Text("写多Float"),
                  onPressed: (){
                    Float32List temp=Float32List(5);
                    for(int i=0;i<5;i++)
                      temp[i]=314.5+i*0.1;
                    ModbusTCP.WriteRegisters_Float(200,5, temp);
                  },
                ),
              ],
            ),
            RaisedButton(
              child: Text("读取数据"),
              onPressed: (){
                bool temp_bit=false;
                int temp_int16=0;
                int temp_int32=0;
                double temp_float=0;
                Int16List read_buffer=Int16List(10);
                Int32List read_buffer2=Int32List(5);
                Float32List read_buffer3=Float32List(5);
                Future.wait([
                  ModbusTCP.ReadRegisters_Int16(0, 10).then((value)=> read_buffer=value),
                  ModbusTCP.ReadSingleBit(0).then((value)=>temp_bit=value),
                  ModbusTCP.ReadSingleRegister_Int16(16).then((value)=>temp_int16=value),
                  ModbusTCP.ReadSingleRegister_Int32(100).then((value)=>temp_int32=value),
                  ModbusTCP.ReadRegisters_Int32(100,5).then((value)=>read_buffer2=value),
                  ModbusTCP.ReadRegisters_Float(200,5).then((value)=>read_buffer3=value),
                  ModbusTCP.ReadSingleRegister_Float(200).then((value)=>temp_float=value),
                  ModbusTCP.ReadSingleRegister_Float(200).then((value)=>temp_float=value),
                  ModbusTCP.ReadBits(0, 16).then((value)=>coil_buffer=value)
                ]).then((obj){
                  setState(() {
                    String temp="[";
                    read_buffer3.forEach((value) {
                      temp+=value.toStringAsFixed(1)+", ";
                    });
                    temp+="]";
                    values="${read_buffer}\n${coil_buffer}\n-->Bit: $temp_bit"+
                            " -->Int16: $temp_int16 -->Int32: $temp_int32 -->Float: ${temp_float.toStringAsFixed(1)}\n"+
                            "${read_buffer2}\n$temp";
                  });
                });
              },
            ),
            Padding(
              padding: EdgeInsets.only(right: 5,left: 5,top: 12,bottom: 8),
              child: RichText(
                textAlign:TextAlign.left,
                softWrap: true,
                text: TextSpan(
                  text: values,
                  style: TextStyle(
                    color: Color(0xFF0000FF),
                    fontSize: 12.0,
                    //fontWeight: FontWeight.w300
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


/*
List<bool> temp=[
    state1,
    !state1,
    state1,
    !state1,
    state1,
    !state1,
    state1,
    !state1,
    state1,
    !state1,
    state1,
    !state1,
    state1,
    !state1,
    state1,
    !state1,
  ];
  List<bool> temp1=[
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
  ];
  List<bool> temp2=[
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
    state1,
  ];

 */