# Android export and phone test

This project targets Android phones in landscape orientation and uses Godot 4.7
Standard with the Compatibility renderer.

## Prepare Godot

1. Install the Android export templates matching the installed Godot 4.7 version.
2. Install and configure the Java SDK and Android SDK using the
   [Godot Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).
   Set their paths in Godot's Editor Settings under Export > Android.
3. Open this project in Godot and choose Project > Export. Add an Android preset
   if one is not already present.
4. In the preset's permissions, enable **Internet** and **Access Network State**.
   Internet is needed for the same-Wi-Fi ENet match.
5. Keep the project orientation set to landscape. Do not add a keystore or
   signing password to the project folder or source control.

## Export and test

1. Export a debug APK to a location outside the project folder.
2. Install it on two Android phones connected to the same Wi-Fi network.
3. Test offline campaign and versus-bot in airplane mode.
4. Test online by hosting on one phone and joining from the other using the
   host phone's Wi-Fi IP. Also test a wrong host IP and a mid-match disconnect.
5. Confirm the game stays in landscape and that touch controls, pause, saved
   progress, and sound setting work on-device.

Do not commit APK/AAB files, keystores, passwords, or machine-specific export
configuration.
