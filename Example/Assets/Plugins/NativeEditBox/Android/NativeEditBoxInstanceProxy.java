package com.unityextensions.nativeeditbox;

public interface NativeEditBoxInstanceProxy
{
     void OnJavaTextChanged(String text);
     void OnJavaDidEnd(String text);
     void OnJavaSubmitPressed(String text);

     void OnJavaGotFocus();
     void OnJavaTapOutside();
}
