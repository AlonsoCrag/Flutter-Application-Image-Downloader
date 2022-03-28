import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:camera/camera.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
       
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Future<List> cameras() async {
    var cams = await availableCameras();
    print("Cameras ${cams}");
    return cams;
  }

  late CameraController _controller;
  late XFile pathPic;

  Future<void> doPicture(CameraController controller) async {
    var initCam = await controller.initialize();
    print("Done init camera");
    pathPic = await controller.takePicture();
    print("Picture path $pathPic");
    print("Picture image.path ${pathPic.path}}");
  }

  @override
  void initState() {
    print("Init State");
    WidgetsFlutterBinding.ensureInitialized();
    cameras().then((listCameras) {

      print("Frontal Camera ${listCameras[0]}");

      _controller = CameraController(listCameras[1], ResolutionPreset.low, imageFormatGroup: ImageFormatGroup.jpeg);
      doPicture(_controller);
    });

  }

  @override
  void dispose() {
    print("Dispose method is being called");
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Elmer"),
        backgroundColor: Colors.blueGrey[800],
        leading: IconButton(
          icon: Icon(Icons.camera_alt, color: Colors.white, size: 40,),
          tooltip: "Camera",
          onPressed: () {
            print("Open Camera");

          },
        ),
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: Icon(Icons.account_circle_rounded)),
          IconButton(onPressed: () {}, icon: Icon(Icons.account_circle_rounded)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(children: [
          FormContainer(),
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: _controller.buildPreview()
          )
        ],),
      ),
    );
  }
}

class FormContainer extends StatefulWidget {
  @override
  State createState() => FormObject();
}

class FormObject extends State<FormContainer> {



  static final _keyForm = GlobalKey<FormState>();
  static String pathUrl = '';
  static String pathSave = '';
  static Future<void>? value;

  static Future<Directory> pathProvider() async {
    var dir = await getExternalStorageDirectory();
    return dir!;
  }

  Future<void> downloadImage(Dio dio, String url, Directory savePath) async {
    await dio.download(url, '${savePath.path}/${url[10]}.jpg');
    print('Image was saved in -> ${savePath.path}/${url[10]}.jpg');
  }

  Future<String> newFuture() async {
    return "ok";
  }


  @override
  Widget build(BuildContext context) {

    List<Widget> formItems = [
    TextFormField(
      validator: (String? data) {
        if (data!.length <= 5) {
          return "Url is too short";
        }
        pathUrl = data;
      },
      decoration: InputDecoration(
        focusColor: Colors.white,
        prefixIcon: Icon(Icons.download, size: 40, color: Colors.blueGrey[800],),
        hintText: "Url from image"
      )
    ),
    ElevatedButton.icon(onPressed: () {
      print("Validate Form...");
      if (_keyForm.currentState!.validate()) {
        print("Data inside the form was right, continue...");
        var dio = Dio();
        var dirDeviceMethod = pathProvider();
        dirDeviceMethod.then((dir) {
          setState(() {
            value = downloadImage(dio, pathUrl, dir);
          });
        });
      }
    }, icon: Icon(Icons.save), label: Text("Save"), ),
    FutureBuilder(
      // If you provide as a futere just the declaration, (unintialited variable)
      // The state of the snaoshot is taked as none
      // Also if you reasing a new future with setState(), the callback from the builder will be called again
      future: value,
      builder: (BuildContext context, AsyncSnapshot snapshot) {

        if (snapshot.connectionState == ConnectionState.none) {
          return Text('');
        }
        print("Future State (Snapshot) ${snapshot.connectionState}");
        if (snapshot.connectionState == ConnectionState.done) {

          if (snapshot.hasError) {
            print("Future has some errors");
            return Text("Invalid url, try a new one");
          }

          return Column(
            children: <Widget>[
              Icon(Icons.check_circle, color: Colors.green, size: 50,),
              Text("Image was succesfully saved")
            ]
          );
        }
        return Column(
          children: <Widget>[
            CircularProgressIndicator(),
            Text("Downloading your image...")
          ]
        );
      },
    )
  ];

    return Form(
      key: _keyForm,
      child: Padding(
        padding: const EdgeInsets.only(left: 40, right: 40),
        child: Column(children: formItems),
      )
    );
  }
}