using System.Collections;
using UnityEngine;
using TMPro;

[RequireComponent(typeof(TMP_InputField))]
public partial class NativeEditBox : MonoBehaviour
{
	const string GlobalListenerName = "NativeEditBoxGlobalListener_1000";

	static GameObject globalListener = null;

	static int uniqueId = 1;

	enum ReturnButtonType
	{
		Default,
		Go,
		Next,
		Search,
		Send,
		Done,
	}

	public delegate void OnEventHandler();
	public delegate void OnTextChangedHandler(string text);
	public delegate void OnSubmitHandler(string text);

	public event OnTextChangedHandler OnTextChanged;
	public event OnSubmitHandler OnSubmit;
	public event OnEventHandler OnGotFocus;
	public event OnEventHandler OnDidEnd;
	public event OnEventHandler OnTapOutside;

#pragma warning disable 0414

	[SerializeField]
	ReturnButtonType returnButtonType = ReturnButtonType.Default;

	[Tooltip("iOS ONLY")]
	[SerializeField]
	bool showClearButton = true;

	[SerializeField]
	bool selectAllOnFocus = false;

	[SerializeField]
	bool switchBetweenNativeAndUnity = false;

#pragma warning restore 0414

	TMP_InputField inputField = null;

	Coroutine coUpdatePlacement = null;

	void Awake()
	{
		if (globalListener == null)
			CreateGlobalListener();

		this.name += "NEB" + (uniqueId++).ToString();

		inputField = GetComponent<TMP_InputField>();
	}

	void OnEnable()
	{
		AwakeNative();

		StartCoroutine(CoCheckPosition());
	}

	void CreateGlobalListener()
	{
		globalListener = new GameObject();
		globalListener.name = GlobalListenerName;
		GameObject.DontDestroyOnLoad(globalListener);

		globalListener.AddComponent<NativeEditBoxGlobalListener>();
	}

	IEnumerator CoCheckPosition()
	{
		Vector3 current = this.transform.position;

		while (this != null)
		{
			Vector3 pos = this.transform.position;

			if (pos != current)
			{
				current = pos;

				OnRectTransformDimensionsChange();
			}

			yield return 0;
		}
	}

	void OnRectTransformDimensionsChange()
	{
		if (inputField == null || inputField.textComponent == null)
			return;

		if (coUpdatePlacement != null)
			return;

		if (this.gameObject.activeInHierarchy)
			coUpdatePlacement = StartCoroutine(CoUpdatePlacement());
	}

	IEnumerator CoUpdatePlacement()
	{
		yield return new WaitForEndOfFrame();

		if (this == null)
			yield break;

		UpdatePlacementNow();

		coUpdatePlacement = null;
	}

	void UpdatePlacementNow()
	{
		Rect rectScreen = GetScreenRectFromRectTransform(inputField.textComponent.rectTransform);

		SetPlacement((int)rectScreen.x, (int)rectScreen.y, (int)rectScreen.width, (int)rectScreen.height);
	}

	Rect GetScreenRectFromRectTransform(RectTransform rectTransform)
	{
		Rect r = rectTransform.rect;
		Vector2 zero = rectTransform.localToWorldMatrix.MultiplyPoint(new Vector3(r.x, r.y));
		Vector2 one = rectTransform.localToWorldMatrix.MultiplyPoint(new Vector3(r.x + r.width, r.y + r.height));

		return new Rect(zero.x, Screen.height - one.y, one.x, Screen.height - zero.y);
	}

	#region Public Methods

	public static Rect KeyboardArea
	{
		get
		{
			return NativeEditBoxGlobalListener.KeyboardArea;
		}
	}

	#endregion
}
