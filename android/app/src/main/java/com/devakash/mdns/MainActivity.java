package com.devakash.mdns;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import javax.jmdns.JmDNS;
import javax.jmdns.ServiceInfo;
import android.os.Handler;
import java.net.InetAddress;
import android.widget.Toast;

public class MainActivity extends FlutterActivity {
        private static final String CHANNEL = "com.devakash.mdns/initalize";
        private String[] constant ={"serviceName","hostname","ip","port",".local"};
        private JmDNS jmdns;
        private static  final String SERVICE_TYPE ="_ftp._tcp.local.";
        private MethodChannel methodChannel=null;
        private int count=0;

        @Override
        protected void onDestroy() {
            super.onDestroy();
            stopService();
        }

        @Override
        public void onBackPressed() {
             backButtonCloseCustom();       
            
        }

        private void backButtonCloseCustom(){
                if (count >= 1) {
                    stopService();
                        // If the back button is pressed again within 2 seconds, exit the app or perform any action
                        finishAffinity();
                    } else {
                        // Show a toast message to inform the user
                        Toast.makeText(this, "Press back again to exit", Toast.LENGTH_SHORT).show();

                        // Increment the counter
                        count++;

                        // Reset the counter in 2 seconds
                        new Handler().postDelayed(new Runnable() {
                            @Override
                            public void run() {
                                count = 0;
                            }
                        }, 2000);
                    }
        }


        @Override
        public void configureFlutterEngine(FlutterEngine flutterEngine) {
            super.configureFlutterEngine(flutterEngine);

            methodChannel= new MethodChannel(flutterEngine.getDartExecutor(), CHANNEL);
            methodChannel.setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "startService":
                            String serviceName = call.argument(constant[0]);
                            String hostname = call.argument(constant[1]);
                            String ip = call.argument(constant[2]);
                            int port = call.argument(constant[3]);
                            
                            if (serviceName != null && hostname != null && ip != null && port != 0) {
                                startServiceAsync(serviceName, hostname, ip, port,result);
                            } else {
                                result.error("INVALID_ARGUMENTS", "Arguments cannot be null", null);
                            }
                            break;

                        case "stopService":
                            stopServiceAsync(result);
                            break;

                        default:
                            result.notImplemented();
                            break;
                    }
                });
        }

        private void startServiceAsync(String serviceName, String hostname, String ip, int port, MethodChannel.Result result) {

            new Thread(() -> {
                boolean success;

                    //isServiceOwnedByApp(serviceName,ip);
                    success = startService(serviceName, hostname, ip, port);
                    if(success){
                        runOnUiThread(() -> {
                            result.success(true);
                            Toast.makeText(MainActivity.this, "Service started successfully!", Toast.LENGTH_SHORT).show();
                        });
                    }else{
                        runOnUiThread(() -> {
                            result.success(false);
                            Toast.makeText(MainActivity.this, "Failed to start service", Toast.LENGTH_SHORT).show();
                        });
                    }

            }).start();
        }


        private boolean startService(String serviceName, String hostname, String ip, int port)  {
            // Validate IP/hostname
            try {
                InetAddress address = InetAddress.getByName(ip);

                if (address == null) {
                    return  false;
                }

                // Create JmDNS instance (Network operation)
                jmdns = JmDNS.create(address, hostname + constant[4]);

                // Register the service

                ServiceInfo serviceInfo = ServiceInfo.create(
                        SERVICE_TYPE, // Service type
                        serviceName,        // Service name
                        port,               // Port
                        "Android FTP Server" // Metadata
                );


                jmdns.registerService(serviceInfo);

                return true;
            } catch (Exception e) {
                return  false;
            }

        }

        private void stopServiceAsync(MethodChannel.Result result) {
            new Thread(() -> {
                boolean res= stopService(result);
                runOnUiThread(() -> Toast.makeText(MainActivity.this, res? "Service stopped":"Failed to Stop, SomeThing Went Wrong", Toast.LENGTH_SHORT).show());
            }).start();
        }

        private boolean stopService(MethodChannel.Result result) {
            boolean res = true;
            if (jmdns != null) {
                try {
                    jmdns.unregisterAllServices();
                    jmdns.close();
                } catch (Exception e) {
                    res=false;
                    e.printStackTrace();
                }
                jmdns = null;
            }
            if(result!=null){
                result.success(res);
            }

         return  res;
        }

   //oveload to empty param of stopService
    private void stopService() {
        if (jmdns != null) {
            try {
                jmdns.unregisterAllServices();
                jmdns.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
            jmdns = null;
        }
    }

    
}
