using UnityEngine;

public class NativeEditBoxGlobalListener : MonoBehaviour
{
	static Rect keyboard = default(Rect);

	void FromNative_KeyboardChange(string stringRect)
	{
		if (string.IsNullOrEmpty(stringRect))
		{
			keyboard = new Rect(0f, 0f, 0f, 0f);
		}
		else
		{
			stringRect = stringRect.Replace(',', '.');
			string[] split = stringRect.Split('|');
			keyboard = new Rect(
				float.Parse(split[0], System.Globalization.CultureInfo.InvariantCulture),
				float.Parse(split[1], System.Globalization.CultureInfo.InvariantCulture),
				float.Parse(split[2], System.Globalization.CultureInfo.InvariantCulture),
				float.Parse(split[3], System.Globalization.CultureInfo.InvariantCulture)
			);
		}
	}

	#region Public Methods

	public static Rect KeyboardArea => keyboard;

	#endregion
}
