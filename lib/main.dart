import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'mDNS Service',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      home: const MDNSServicePage(),
    );
  }
}

class MDNSServicePage extends StatefulWidget {
  const MDNSServicePage({super.key});

  @override
  _MDNSServicePageState createState() => _MDNSServicePageState();
}

class _MDNSServicePageState extends State<MDNSServicePage> {
  static const platform = MethodChannel('com.devakash.mdns/initalize');
  bool _loading = false;
  bool _isRunning = false;
  bool _showFields = false;
  String _statusMessage = "Press Start to begin";
  String _ftpUrl = "";
  final TextEditingController hostnameController =
      TextEditingController(text: "");
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_methodCallHandler);
  }

  Future<void> _methodCallHandler(MethodCall call) async {
    if (call.method == "onError") {
      setState(() {
        _statusMessage = "Error: ${call.arguments}";
        _loading = false;
      });
    } else if (call.method == "onSuccess") {
      setState(() {
        _statusMessage = "Service started successfully!";
        _loading = false;
        _isRunning = true;
      });
    }
  }

  Future<void> _toggleService() async {
    setState(() {
      _loading = true;
    });
    try {
      if (_isRunning) {
        final bool res =
            await platform.invokeMethod<bool>('stopService') ?? false;
        setState(() {
          _statusMessage = res ? "Service stopped" : "Failed to Stop Service";
          _isRunning = false;
          _loading = false;
        });
      } else {
        final bool res = await platform.invokeMethod<bool>('startService', {
              'serviceName': 'FTP MDNS SERVICE',
              'hostname': hostnameController.text,
              'ip': ipController.text,
              'port': int.tryParse(portController.text) ?? 0,
            }) ??
            false;
        setState(() {
          if (res) {
            _ftpUrl =
                "ftp://${ipController.text}:${portController.text}\n Or ftp://${hostnameController.text}.local";
          }
          _statusMessage =
              res ? "Service started successfully!" : "Failed to Start";
          _showFields = false;
          _isRunning = true;
          _loading = false;
        });
      }
    } on PlatformException catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.message}";
        _loading = false;
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Make Scaffold background transparent
        appBar: AppBar(
          title: const Text(
            'FTP mDNS Service',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Fallback color if ShaderMask fails
            ),
          ),
          backgroundColor: Colors.transparent, // Make AppBar transparent
          elevation: 0, // Remove AppBar shadow
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (_ftpUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                SelectableText(
                  _ftpUrl,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _showFields
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildTextField(hostnameController, 'Hostname'),
                      _buildTextField(ipController, 'IP Address'),
                      _buildTextField(portController, 'Port',
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFields = !_showFields;
                  });
                },
                child: Text(
                  _showFields ? 'Hide Settings' : 'Show Settings',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: _loading ? null : _toggleService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning
                      ? Colors.red
                      : const Color.fromARGB(255, 8, 130, 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isRunning ? 'Stop Service' : 'Start Service',
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 4),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
