#if !UNITY_EDITOR && UNITY_IOS
//#if UNITY_IOS

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System;
using System.Collections;
using System.Runtime.InteropServices;

public partial class NativeEditBox : IPointerClickHandler
{
	[DllImport("__Internal")]
	static extern IntPtr _CNativeEditBox_Init(string gameObject, bool multiline);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_Destroy(IntPtr instance);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetFocus(IntPtr instance, bool doFocus);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetPlacement(IntPtr instance, int left, int top, int right, int bottom);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetPlaceholder(IntPtr instance, string text, float r, float g, float b, float a);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetFontSize(IntPtr instance, int size);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetFontColor(IntPtr instance, float r, float g, float b, float a);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetTextAlignment(IntPtr instance, int alignment);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetInputType(IntPtr instance, int inputType);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetKeyboardType(IntPtr instance, int keyboardType);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetReturnButtonType(IntPtr instance, int returnButtonType);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetCharacterLimit(IntPtr instance, int characterLimit);

	[DllImport("__Internal")]
	static extern void _CNativeEditBox_SetText(IntPtr instance, string newText);

	IntPtr editBox;

#region Public Methods

	public static bool IsKeyboardSupported()
	{
		return true;
	}

	public void SetText(string text)
	{
		inputField.text = text;

		if (editBox != IntPtr.Zero)
			_CNativeEditBox_SetText(editBox, text);
	}

	public void SetPlacement(int left, int top, int right, int bottom)
	{
		if (editBox == IntPtr.Zero)
			return;

		_CNativeEditBox_SetPlacement(editBox, left, top, right, bottom);
	}

	public void ActivateInputField()
	{
		if (editBox != IntPtr.Zero)
		{
			_CNativeEditBox_SetFocus(editBox, true);
			return;
		}

		StartCoroutine(CreateNow(true));
	}

	public void DestroyNative()
	{
		DestroyNow();
	}

	public string text
	{
		set
		{
			SetText(value);
		}
		get
		{
			return inputField.text;
		}
	}

#endregion

	void AwakeNative()
	{
		inputField.interactable = false;

		if (!switchBetweenNativeAndUnity)
			StartCoroutine(CreateNow(false));
	}

	bool ShowText
	{
		set
		{
			inputField.placeholder.gameObject.SetActive(value);
			inputField.textComponent.enabled = value;
			inputField.enabled = value;
		}
	}

	void OnDestroy()
	{
		DestroyNow();
	}

	void OnDisable()
	{
		DestroyNow();
	}

	IEnumerator CreateNow(bool doFocus)
	{
		yield return new WaitForEndOfFrame();

		if (editBox != IntPtr.Zero)
			yield break;

		SetupInputField();

		ShowText = false;

		if (doFocus)
			_CNativeEditBox_SetFocus(editBox, true);
	}

	void DestroyNow()
	{
		if (editBox == IntPtr.Zero)
			return;

		_CNativeEditBox_Destroy(editBox);
		editBox = IntPtr.Zero;

		ShowText = true;
	}

#region IPointerClickHandler implementation

	public void OnPointerClick(UnityEngine.EventSystems.PointerEventData eventData)
	{
		if (editBox == IntPtr.Zero)
			StartCoroutine(CreateNow(true));
	}

#endregion

	void SetupInputField()
	{
		Text text = inputField.textComponent;
		Text placeholder = inputField.placeholder as Text;

		editBox = _CNativeEditBox_Init(name, inputField.lineType != InputField.LineType.SingleLine);

		UpdatePlacementNow();

		_CNativeEditBox_SetFontSize(editBox, Mathf.RoundToInt(text.fontSize * text.pixelsPerUnit));
		_CNativeEditBox_SetFontColor(editBox, text.color.r, text.color.g, text.color.b, text.color.a);
		_CNativeEditBox_SetPlaceholder(editBox, placeholder.text, placeholder.color.r, placeholder.color.g, placeholder.color.b, placeholder.color.a);
		_CNativeEditBox_SetTextAlignment(editBox, (int)text.alignment);
		_CNativeEditBox_SetInputType(editBox, (int)inputField.inputType);
		_CNativeEditBox_SetKeyboardType(editBox, (int)inputField.keyboardType);
		_CNativeEditBox_SetReturnButtonType(editBox, (int)returnButtonType);
		_CNativeEditBox_SetCharacterLimit(editBox, inputField.characterLimit);
		_CNativeEditBox_SetText(editBox, inputField.text);
	}

#region CALLBACKS

	void iOS_TextChanged(string text)
	{
		inputField.text = text;
	}

	void iOS_TapOutside(string nothing)
	{
		if (switchBetweenNativeAndUnity)
			DestroyNow();
	}

	void iOS_DidEnd(string text)
	{
		inputField.text = text;

		if (switchBetweenNativeAndUnity)
			DestroyNow();
	}

	void iOS_SubmitPressed(string text)
	{
		inputField.text = text;

		if (OnSubmit != null)
			OnSubmit(text);
	}

#endregion
}

#endif
