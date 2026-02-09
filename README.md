# Convall
#### Video Demo:  [youtu.be/QuRssJKqhT4](https://youtu.be/QuRssJKqhT4)
#### Description:

(This is my very first app :) )

Convall: A Cloud-Based File Converter Mobile App Built with Flutter

Convall is a mobile application I developed using Flutter, a framework that allows me to build cross-platform applications from a single codebase. One of the main reasons I chose Flutter is its ability to seamlessly export the app for both iOS and Android, ensuring maximum reach and flexibility for future deployment.

The core functionality of Convall revolves around cloud-based file conversion. The user selects a file on their device, which is then uploaded to the cloud. The actual conversion process is handled remotely through an API. Once the file has been successfully converted, it is automatically downloaded back to the user’s device, ensuring a smooth and efficient experience with minimal effort required from the user.

App Workflow

When the user opens the app, the first step is to select a file they want to convert. Based on the file type (audio, video, image), the app dynamically displays a set of available conversion options. The interface is designed to be intuitive, guiding users through the process step by step.

Code Structure and Key Components

All the main source code files are located within the lib/ directory, which is standard in Flutter projects. The most important files and their purposes are as follows:

1. CloudConvertService.dart

This file acts as the bridge between the app and the external API used for file conversion. It contains all the core functions necessary to:
	•	Upload files to the cloud
	•	Send and manage conversion parameters
	•	Monitor conversion progress
	•	Download the final converted file

All conversion-related logic is centralized here, allowing other parts of the app to remain clean and focused on UI and user interaction.

2. main_page_converter.dart

This file can be considered the main layout manager of the app. It acts as the primary frame or container where all tabs and conversion-related views are displayed. It coordinates navigation and manages the main screen’s layout, ensuring a consistent experience across different file types and user actions.

3. drawer_widget.dart

This file defines the sliding navigation drawer that appears from the left side of the screen. It displays a list of active and past conversion processes. Each process is accompanied by a status icon (emojis), giving the user a quick overview of whether a process is pending, ongoing, completed, or has failed. This helps users track their activity history and stay informed in real-time.

4. page_audio.dart, page_image.dart, and page_video.dart

These are the specialized pages for handling different file types:
	•	page_audio.dart handles audio files
	•	page_image.dart handles image files
	•	page_video.dart handles video files

Each page is responsible for:
	•	Displaying the selected file’s details
	•	Analyzing the file to determine available output formats and parameters
	•	Interacting with the API through CloudConvertService to start and manage the conversion

These pages are modular, and their design ensures that adding support for new file types in the future would be straightforward.
