#if !UNITY_EDITOR && UNITY_ANDROID
// #if UNITY_EDITOR || UNITY_ANDROID

using UnityEngine;
using UnityEngine.EventSystems;
using System.Collections;
using TMPro;

public partial class NativeEditBox : IPointerClickHandler
{
	class GlobalProxy : AndroidJavaProxy
	{
		public GlobalProxy() : base("com.unityextensions.nativeeditbox.NativeEditBoxGlobalProxy")
		{
		}

		void OnJavaKeyboardChange(float x, float y, float width, float height)
		{
			NativeEditBox.keyboard = new Rect(x, y, width, height);
		}
	}

	class InstanceProxy : AndroidJavaProxy
	{
		NativeEditBox owner = null;

		public InstanceProxy(NativeEditBox owner) : base("com.unityextensions.nativeeditbox.NativeEditBoxInstanceProxy")
		{
			this.owner = owner;
		}

		void OnJavaTextChanged(string text)
		{
			owner.inputField.text = text;

			owner.OnTextChanged?.Invoke(text);
		}

		void OnJavaDidEnd(string text)
		{
			owner.inputField.text = text;

			if (owner.switchBetweenNativeAndUnity)
				owner.DestroyNow();

			owner.OnDidEnd?.Invoke();
		}

		void OnJavaSubmitPressed(string text)
		{
			owner.inputField.text = text;

			owner.OnSubmit?.Invoke(text);

			Debug.Log("submit pressed " + text);
		}

		void OnJavaGotFocus()
		{
			owner.OnGotFocus?.Invoke();

			if (owner.inputField.onFocusSelectAll)
				owner.StartCoroutine(owner.CoSelectAll());
		}

		void OnJavaTapOutside()
		{
			if (owner.switchBetweenNativeAndUnity)
				owner.DestroyNow();

			owner.OnTapOutside?.Invoke();
		}
	}

	static GlobalProxy globalProxy = null;
	InstanceProxy instanceProxy = null;

	AndroidJavaObject editBox = default;

	#region Public Methods

	public static bool IsKeyboardSupported()
	{
		return true;
	}

	public void SetText(string text)
	{
		inputField.text = text;

		editBox?.Call("SetText", text);
	}

	public void SelectRange(int from, int to)
	{
		editBox?.Call("SelectRange", from, to);
	}

	void SetPlacement(int left, int top, int right, int bottom)
	{
		editBox?.Call("SetPlacement", left, top, right, bottom);
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
		set => SetText(value);
		get => inputField.text;
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

	void UpdateNative()
	{

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

		instanceProxy = null;

		editBox.Call("Destroy");
		editBox = null;

		ShowText = true;
	}

	#region IPointerClickHandler implementation

	public void OnPointerClick(PointerEventData eventData)
	{
		if (editBox == null)
			StartCoroutine(CreateNow(true));
	}

	#endregion

	void SetupInputField()
	{
		TMP_Text text = inputField.textComponent;
		TMP_Text placeholder = inputField.placeholder as TMP_Text;

		//ugly, fix enum
		TextAnchor alignment = text.verticalAlignment switch
		{
			VerticalAlignmentOptions.Top => text.horizontalAlignment switch
			{
				HorizontalAlignmentOptions.Left => TextAnchor.TextAnchorUpperLeft,
				HorizontalAlignmentOptions.Center => TextAnchor.TextAnchorUpperCenter,
				HorizontalAlignmentOptions.Right => TextAnchor.TextAnchorUpperRight,
				_ => TextAnchor.TextAnchorUpperLeft
			},
			VerticalAlignmentOptions.Middle => text.horizontalAlignment switch
			{
				HorizontalAlignmentOptions.Left => TextAnchor.TextAnchorMiddleLeft,
				HorizontalAlignmentOptions.Center => TextAnchor.TextAnchorMiddleCenter,
				HorizontalAlignmentOptions.Right => TextAnchor.TextAnchorMiddleRight,
				_ => TextAnchor.TextAnchorMiddleLeft
			},
			VerticalAlignmentOptions.Bottom => text.horizontalAlignment switch
			{
				HorizontalAlignmentOptions.Left => TextAnchor.TextAnchorLowerLeft,
				HorizontalAlignmentOptions.Center => TextAnchor.TextAnchorLowerCenter,
				HorizontalAlignmentOptions.Right => TextAnchor.TextAnchorLowerRight,
				_ => TextAnchor.TextAnchorLowerLeft
			},
			_ => TextAnchor.TextAnchorUpperLeft
		};

		if (globalProxy == null)
			globalProxy = new GlobalProxy();

		instanceProxy = new InstanceProxy(this);

		editBox = new AndroidJavaObject("com.unityextensions.nativeeditbox.NativeEditBox", globalProxy, instanceProxy);
		editBox.Call("Init", inputField.lineType != TMP_InputField.LineType.SingleLine);

		UpdatePlacementNow();

		editBox.Call("SetFontSize", Mathf.RoundToInt(text.fontSize * text.pixelsPerUnit));
		editBox.Call("SetFontColor", text.color.r, text.color.g, text.color.b, text.color.a);
		editBox.Call("SetPlaceholder", placeholder.text, placeholder.color.r, placeholder.color.g, placeholder.color.b, placeholder.color.a);
		editBox.Call("SetTextAlignment", (int)alignment);
		editBox.Call("SetInputType", (int)inputField.inputType);
		editBox.Call("SetKeyboardType", (int)inputField.keyboardType);
		editBox.Call("SetReturnButtonType", (int)returnButtonType);
		editBox.Call("SetCharacterLimit", inputField.characterLimit);
		editBox.Call("SetText", inputField.text);
	}

	IEnumerator CoSelectAll()
	{
		//Looks bad, but works 98% of the times..... Sad.
		SelectRange(0, inputField.text.Length);
		SelectRange(0, inputField.text.Length);
		yield return null;
		SelectRange(0, inputField.text.Length);
		SelectRange(0, inputField.text.Length);
		yield return null;
		SelectRange(0, inputField.text.Length);
		SelectRange(0, inputField.text.Length);
	}
}

#endif
