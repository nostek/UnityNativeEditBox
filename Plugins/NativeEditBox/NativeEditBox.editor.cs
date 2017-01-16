#if UNITY_EDITOR
//#if false

using UnityEngine;
using System;

public partial class NativeEditBox
{
	#region Public Methods

	public static bool IsKeyboardSupported()
	{
		return false;
	}

	public void SetText(string text)
	{
		inputField.text = text;
	}

	public void SetPlacement(int left, int top, int right, int bottom)
	{
		//Do nothing
	}

	public void ActivateInputField()
	{
		inputField.ActivateInputField();
	}

	public void DestroyNative()
	{
		//Do nothing
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
		inputField.onEndEdit.AddListener(OnEndEdit);
	}

	void OnEndEdit(string text)
	{
		if (Input.GetKey(KeyCode.KeypadEnter) || Input.GetKey(KeyCode.Return))
		{
			if (OnSubmit != null)
				OnSubmit(inputField.text);
		}
	}
}

#endif
