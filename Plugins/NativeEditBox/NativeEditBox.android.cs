#if !UNITY_EDITOR && UNITY_ANDROID
//#if UNITY_ANDROID

using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using System.Collections;

public partial class NativeEditBox : IPointerClickHandler
{
	AndroidJavaObject editBox;

#region Public Methods

	public static bool IsKeyboardSupported()
	{
		return true;
	}

	public void SetText(string text)
	{
		inputField.text = text;

		if (editBox != null)
			editBox.Call("SetText", text);
	}

	void SetPlacement(int left, int top, int right, int bottom)
	{
		if (editBox == null)
			return;

		editBox.Call("SetPlacement", left, top, right, bottom);
	}

	public void ActivateInputField()
	{
		if (editBox != null)
		{
			editBox.Call("SetFocus", true);
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

		if (editBox != null)
			yield break;

		SetupInputField();

		ShowText = false;

		if (doFocus)
			editBox.Call("SetFocus", true);
	}

	void DestroyNow()
	{
		if (editBox == null)
			return;

		editBox.Call("Destroy");
		editBox = null;

		ShowText = true;
	}

#region IPointerClickHandler implementation

	public void OnPointerClick(UnityEngine.EventSystems.PointerEventData eventData)
	{
		if (editBox == null)
			StartCoroutine(CreateNow(true));
	}

#endregion

	void SetupInputField()
	{
		Text text = inputField.textComponent;
		Text placeholder = inputField.placeholder as Text;

		editBox = new AndroidJavaObject("com.unityextensions.nativeeditbox.NativeEditBox");
		editBox.Call("Init", name, inputField.lineType != InputField.LineType.SingleLine);

		UpdatePlacementNow();

		editBox.Call("SetFontSize", Mathf.RoundToInt(text.fontSize * text.pixelsPerUnit));
		editBox.Call("SetFontColor", text.color.r, text.color.g, text.color.b, text.color.a);
		editBox.Call("SetPlaceholder", placeholder.text, placeholder.color.r, placeholder.color.g, placeholder.color.b, placeholder.color.a);
		editBox.Call("SetTextAlignment", (int)text.alignment);
		editBox.Call("SetInputType", (int)inputField.inputType);
		editBox.Call("SetKeyboardType", (int)inputField.keyboardType);
		editBox.Call("SetReturnButtonType", (int)returnButtonType);
		editBox.Call("SetCharacterLimit", inputField.characterLimit);
		editBox.Call("SetText", inputField.text);
	}

	void Android_GotFocus(string nothing)
	{
		if (OnGotFocus != null)
			OnGotFocus();
	}

	void Android_TextChanged(string text)
	{
		inputField.text = text;
	}

	void Android_TapOutside(string nothing)
	{
		if (switchBetweenNativeAndUnity)
			DestroyNow();
	}

	void Android_DidEnd(string text)
	{
		inputField.text = text;

		if (switchBetweenNativeAndUnity)
			DestroyNow();
	}

	void Android_SubmitPressed(string text)
	{
		inputField.text = text;

		if (OnSubmit != null)
			OnSubmit(text);
	}
}

#endif
