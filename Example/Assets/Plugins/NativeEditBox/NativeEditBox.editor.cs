#if UNITY_EDITOR
// #if false

using UnityEngine;

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

	public void SelectRange(int from, int to)
	{
		inputField.selectionAnchorPosition = from;
		inputField.selectionFocusPosition = to;
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
		set => SetText(value);
		get => inputField.text;
	}

	#endregion

	void AwakeNative()
	{
		inputField.onEndEdit.AddListener(OnEndEdit);
		inputField.onValueChanged.AddListener(OnValueChanged);
	}

	void OnValueChanged(string text)
	{
		OnTextChanged?.Invoke(text);
	}

	void OnEndEdit(string text)
	{
		if (Input.GetKey(KeyCode.KeypadEnter) || Input.GetKey(KeyCode.Return))
			OnSubmit?.Invoke(inputField.text);

		OnDidEnd?.Invoke();
		OnTapOutside?.Invoke();
	}

	#region BAD FOCUS CHECK

	bool isFocused = false;

	void UpdateNative()
	{
		bool focus = inputField.isFocused;

		if (focus != isFocused)
		{
			isFocused = focus;

			if (focus)
			{
				OnGotFocus?.Invoke();

				if (inputField.onFocusSelectAll)
					SelectRange(0, inputField.text.Length);
			}
		}
	}

	#endregion
}

#endif
