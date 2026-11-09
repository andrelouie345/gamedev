# Android export and phone test

This project targets Android phones in landscape orientation and uses Godot 4.7
Standard with the Compatibility renderer.

## Prepare Godot

1. Install the Android export templates matching the installed Godot 4.7
   Standard version.
2. Install OpenJDK 17 and the Android SDK, including the platform/build tools
   required by the Godot 4.7 export templates. Configure the JDK and Android
   SDK paths in Godot's Editor Settings under Export > Android, following the
   [Godot Android export documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html).
3. Open this project in Godot and choose Project > Export. Add an Android preset
   if one is not already present. The project currently has no verified
   Android export preset; select landscape for the export orientation.
4. In the preset's permissions, enable **Internet** and **Access Network State**
   for same-Wi-Fi ENet hosting/joining.
5. Use Godot's debug signing for a local test build. Confirm the application
   ID, package name and application icon in the export preset before creating a
   release build. Do not create or commit a release keystore, signing password
   or machine-specific export credentials in the project folder or source
   control.
6. Keep the project orientation set to landscape.

## Export and test

1. Export a debug APK to a location outside the project folder.
2. Install it on an Android phone using Android Studio/ADB or the system
   package installer. Allow installation from the chosen local source when
   prompted.
3. Test offline campaign and Versus Bot in airplane mode.
4. Install the same build on a second phone connected to the same Wi-Fi network.
   Test online by hosting on one phone and joining from the other using the
   host phone's Wi-Fi IP. Also test a wrong host IP and a mid-match disconnect.
5. Confirm the game stays in landscape and that touch movement, camera look,
   fire, reload, pause, saved progress, and sound setting work on-device.

No Android export or phone installation has yet been verified. Do not claim
real-device compatibility until the above checks have been performed and
recorded in the phone compatibility matrix.

Do not commit APK/AAB files, keystores, passwords, `export_presets.cfg`, or
machine-specific export configuration.
