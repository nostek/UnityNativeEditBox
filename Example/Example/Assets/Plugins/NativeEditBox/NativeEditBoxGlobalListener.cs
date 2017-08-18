using UnityEngine;
using System;

public class NativeEditBoxGlobalListener : MonoBehaviour
{
	static Rect keyboard = default(Rect);

	void FromNative_KeyboardChange(string stringRect)
	{
		if (string.IsNullOrEmpty(stringRect))
		{
			keyboard = new Rect(0, 0, 0, 0);
		}
		else
		{
			string[] split = stringRect.Split('|');
			keyboard = new Rect(
				float.Parse(split[0]),
				float.Parse(split[1]),
				float.Parse(split[2]),
				float.Parse(split[3])
			);
		}
	}

	#region Public Methods

	public static Rect KeyboardArea
	{
		get
		{
			return keyboard;
		}
	}

	#endregion
}
