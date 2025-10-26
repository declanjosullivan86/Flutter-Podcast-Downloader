# **Flutter Podcast Downloader (Web)**

This document provides instructions on how to build and run this Flutter web application.

## **Prerequisites**

1. **Flutter SDK:** You must have the Flutter SDK installed on your machine. You can find installation instructions on the [official Flutter website](https://flutter.dev/docs/get-started/install).  
2. **Web Support:** Ensure Flutter web support is enabled. You can check and enable it with the following commands:
```
   flutter doctor  
   # If web is not listed as an available device, enable it:  
   flutter config --enable-web
```
4. **Chrome:** You'll need the Chrome browser to run the web app.

## **Running the Application**

1. Create the Project:  
   Open your terminal, navigate to your development directory, and create a new Flutter project:  
```
flutter create podcast_downloader  
cd podcast_downloader
```
3. Replace pubspec.yaml:  
   Open the newly created podcast\_downloader project in your code editor. Replace the entire contents of the pubspec.yaml file with the code from the pubspec.yaml block above.  
4. Replace lib/main.dart:  
   Replace the entire contents of the lib/main.dart file with the code from the lib/main.dart block above.  
5. Get Dependencies:  
   In your terminal (inside the podcast\_downloader directory), run:  

```
flutter pub get
```
   This will download the http and webfeed\_plus packages.  
7. Run the App:  
   You can now run the application. The flutter run command will build the app and host it on a local development server.  
```
flutter run -d chrome
```
This command will automatically open a new Chrome window with your application running.

You can now paste any public podcast RSS feed URL into the text field and click "Fetch Feed" to see the episodes and download them.
