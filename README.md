# UnityNativeEditBox

A native implementation of UITextField on iOS and EditText on Android for Unity.
Works with Unitys InputField.

##Installation
1. Copy the Plugins folder to your Assets folder.
2. Add NativeEditBox to your InputField component.
3. Done!

##Usage
Use the delegates on NativeEditBox for user information.

Use the static rect KeyboardArea on NativeEditBox for information about the keyboard.
If the rect is zero, then the keyboard is hidden.

##Known issues
The NativeEditBox is always on top of Unity, nothing can go above it.

-Use DestroyNative() to destroy the native version and show Unitys InputField instead.

-Activate "Switch Between Native And Unity" to make NativeEditBox to switch by itself when the inputfield gets deactivated.

##Big thanks to for inspiration and help

https://github.com/gree/unity-webview 

https://github.com/indeego/UnityNativeEdit



Tested with Unity 5.5.0
