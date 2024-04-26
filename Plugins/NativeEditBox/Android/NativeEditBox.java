package com.unityextensions.nativeeditbox;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Point;
import android.graphics.Rect;
import android.text.Editable;
import android.text.InputFilter;
import android.text.TextWatcher;
import android.util.TypedValue;
import android.view.Display;
import android.view.Gravity;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewTreeObserver;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.TextView;

import com.unity3d.player.UnityPlayer;

import java.util.Locale;

@SuppressWarnings("unused")
public class NativeEditBox {
    private enum TextAnchor
    {
        UpperLeft,
        UpperCenter,
        UpperRight,
        MiddleLeft,
        MiddleCenter,
        MiddleRight,
        LowerLeft,
        LowerCenter,
        LowerRight
    }

    private enum ReturnButtonType
    {
        Default,
        Go,
        Join,
        Next,
        Search,
        Send,
        Done,
    }

    private enum InputType
    {
        Standard,
        AutoCorrect,
        Password,
    }

    private enum TouchScreenKeyboardType
    {
        Default,
        ASCIICapable,
        NumbersAndPunctuation,
        URL,
        NumberPad,
        PhonePad,
        NamePhonePad,
        EmailAddress,
    }

    private static ViewTreeObserver.OnGlobalLayoutListener sGlobalListener = null;
    private static FrameLayout sLayout = null;

    private static NativeEditBoxGlobalProxy globalProxy = null;
    private NativeEditBoxInstanceProxy instanceProxy = null;

    private EditText mEditBox = null;

    private boolean currentMultiline = false;
    private InputType currentInputType = InputType.Standard;
    private TouchScreenKeyboardType currentKeyboardType = TouchScreenKeyboardType.Default;

    public NativeEditBox(NativeEditBoxGlobalProxy global, NativeEditBoxInstanceProxy instance)
    {
        globalProxy = global;
        instanceProxy = instance;
    }

    @SuppressWarnings("unused")
    public void Init(final boolean multiline)
    {
        this.currentMultiline = multiline;

        final Activity activity = UnityPlayer.currentActivity;
        final View activityRootView = activity.getWindow().getDecorView().getRootView();
        final NativeEditBox eb = this;

        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox != null)
                    return;

                mEditBox = new EditText(activity);

                // It's important to set this first as it resets some things, for example character hiding if content type is password.
                mEditBox.setSingleLine(!multiline);

                mEditBox.setId(0);
                mEditBox.setPadding(0,0,0,0);
                mEditBox.setBackgroundColor(Color.TRANSPARENT);

                mEditBox.setFocusable(true);
                mEditBox.setFocusableInTouchMode(true);

                if(sLayout == null)
                {
                    sLayout = new FrameLayout(activity);
                    sLayout.setFocusable(true);
                    sLayout.setFocusableInTouchMode(true);
                    activity.addContentView(
                            sLayout,
                            new FrameLayout.LayoutParams(
                                    FrameLayout.LayoutParams.MATCH_PARENT,
                                    FrameLayout.LayoutParams.MATCH_PARENT,
                                    Gravity.NO_GRAVITY
                            )
                    );
                }

                sLayout.addView(
                        mEditBox,
                        new FrameLayout.LayoutParams(
                                FrameLayout.LayoutParams.MATCH_PARENT,
                                FrameLayout.LayoutParams.MATCH_PARENT,
                                Gravity.NO_GRAVITY
                        )
                );

                mEditBox.setOnFocusChangeListener(new View.OnFocusChangeListener() {
                    @Override
                    public void onFocusChange(View v, boolean hasFocus) {
                        if (!hasFocus) {
                            String txt = eb.getText();

                            sLayout.setClickable(false);

                            eb.showKeyboard(false);

                            instanceProxy.OnJavaDidEnd(txt);
                            instanceProxy.OnJavaTapOutside();
                        }else
                        {
                            sLayout.setClickable(true);

                            instanceProxy.OnJavaGotFocus();
                        }
                    }
                });

                mEditBox.addTextChangedListener(new TextWatcher() {
                    @Override
                    public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

                    }

                    @Override
                    public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {

                    }

                    @Override
                    public void afterTextChanged(Editable editable) {
                        instanceProxy.OnJavaTextChanged(editable.toString());
                    }
                });

                mEditBox.setOnEditorActionListener( new TextView.OnEditorActionListener() {
                    @Override
                    public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                        if(actionId >= EditorInfo.IME_ACTION_NONE && actionId <= EditorInfo.IME_ACTION_PREVIOUS)
                        {
                            instanceProxy.OnJavaSubmitPressed(v.getText().toString());
                            return true;
                        }
                        return false;
                    }
                });
            }
        });

        if(sGlobalListener == null)
        {
            sGlobalListener = new ViewTreeObserver.OnGlobalLayoutListener() {
                @Override
                public void onGlobalLayout() {
                    Rect r = new Rect();
                    activityRootView.getWindowVisibleDisplayFrame(r);

                    Display display = activity.getWindowManager().getDefaultDisplay();
                    Point screen = new Point();
                    display.getSize(screen);

                    int kbHeight = screen.y - (r.bottom - r.top);

                    if(kbHeight > 2)
                    {
                        //Showing
                        if(globalProxy != null)
                            globalProxy.OnJavaKeyboardChange(0, screen.x, r.bottom, kbHeight);
                    }else{
                        //Not showing
                        if(globalProxy != null)
                            globalProxy.OnJavaKeyboardChange(0, 0, 0, 0);
                    }
                }
            };
            activityRootView.getViewTreeObserver().addOnGlobalLayoutListener(sGlobalListener);
        }
    }

    @SuppressWarnings("unused")
    public void Destroy()
    {
        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                showKeyboard(false);

                sLayout.removeView(mEditBox);

                mEditBox = null;
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetPlacement(int left, int top, int right, int bottom)
    {
        final FrameLayout.LayoutParams params
                = new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
                Gravity.NO_GRAVITY
        );
        params.leftMargin = left;
        params.topMargin = top;
        params.width = right - left;
        params.height = bottom - top;

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                mEditBox.setLayoutParams(params);
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetFontSize(int fontSize)
    {
        final float fsize = (float)fontSize;

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                mEditBox.setTextSize(TypedValue.COMPLEX_UNIT_PX, fsize);
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetFontColor(float r, float g, float b, float a)
    {
        final int clr = Color.argb(
                (int)(255.0f*a),
                (int)(255.0f*r),
                (int)(255.0f*g),
                (int)(255.0f*b)
        );

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                mEditBox.setTextColor(clr);
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetPlaceholder(final String hintText, float r, float g, float b, float a)
    {
        final int clr = Color.argb(
                (int)(255.0f*a),
                (int)(255.0f*r),
                (int)(255.0f*g),
                (int)(255.0f*b)
        );

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                mEditBox.setHint(hintText);
                mEditBox.setHintTextColor(clr);
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetTextAlignment(int textAlignment)
    {
        TextAnchor alignment = TextAnchor.values()[textAlignment];

        int gravity = 0;

        switch(alignment)
        {
            case UpperLeft:
                gravity = Gravity.TOP | Gravity.START;
                break;
            case UpperCenter:
                gravity = Gravity.TOP | Gravity.CENTER_HORIZONTAL;
                break;
            case UpperRight:
                gravity = Gravity.TOP | Gravity.END;
                break;
            case MiddleLeft:
                gravity = Gravity.CENTER_VERTICAL | Gravity.START;
                break;
            case MiddleCenter:
                gravity = Gravity.CENTER_VERTICAL | Gravity.CENTER_HORIZONTAL;
                break;
            case MiddleRight:
                gravity = Gravity.CENTER_VERTICAL | Gravity.END;
                break;
            case LowerLeft:
                gravity = Gravity.BOTTOM | Gravity.START;
                break;
            case LowerCenter:
                gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL;
                break;
            case LowerRight:
                gravity = Gravity.BOTTOM | Gravity.END;
                break;
        }

        final int g = gravity;

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                mEditBox.setGravity(g);
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetInputType(int inputType)
    {
        currentInputType = InputType.values()[inputType];

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                updateInputValues();
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetKeyboardType(int keyboardType)
    {
        currentKeyboardType = TouchScreenKeyboardType.values()[keyboardType];

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                updateInputValues();
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetReturnButtonType(int returnButtonType)
    {
        ReturnButtonType buttonType = ReturnButtonType.values()[returnButtonType];

        int imeType = EditorInfo.IME_ACTION_UNSPECIFIED;

        switch(buttonType)
        {
            case Default:
                break;
            case Go:
                imeType = EditorInfo.IME_ACTION_GO;
                break;
            case Next:
                imeType = EditorInfo.IME_ACTION_NEXT;
                break;
            case Search:
                imeType = EditorInfo.IME_ACTION_SEARCH;
                break;
            case Send:
                imeType = EditorInfo.IME_ACTION_SEND;
                break;
            case Done:
                imeType = EditorInfo.IME_ACTION_DONE;
                break;
        }

        final int i = EditorInfo.IME_FLAG_NO_EXTRACT_UI | imeType;

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                mEditBox.setImeOptions(i);
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetCharacterLimit(int characterLimit)
    {
        final int limit = characterLimit;

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                InputFilter[] filters;

                if(limit == 0)
                {
                    filters = new InputFilter[0];
                }
                else
                {
                    filters = new InputFilter[1];
                    filters[0] = new InputFilter.LengthFilter(limit);
                }

                mEditBox.setFilters(filters);
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetFocus(boolean doFocus)
    {
        final boolean d = doFocus;

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                if(d)
                {
                    if(mEditBox.requestFocus())
                        showKeyboard(true);
                }
                else
                {
                    showKeyboard(false);
                }
            }
        });
    }

    @SuppressWarnings("unused")
    public void SetText(final String newText)
    {
        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                mEditBox.setText(newText);
            }
        });
    }

    @SuppressWarnings("unused")
    public void SelectRange(int from, int to)
    {
        final int ifrom = from;
        final int ito = to;

        final Activity activity = UnityPlayer.currentActivity;
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mEditBox == null)
                    return;

                mEditBox.setSelection(ifrom, ito);
            }
        });
    }

    ///

    private void updateInputValues()
    {
        if(mEditBox == null)
            return;

        int editInputType = 0;

        switch(currentKeyboardType)
        {
            case Default:
                editInputType = android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
                break;
            case ASCIICapable:
                editInputType = android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS;
                break;
            case NumbersAndPunctuation:
                editInputType = android.text.InputType.TYPE_CLASS_NUMBER | android.text.InputType.TYPE_NUMBER_FLAG_DECIMAL | android.text.InputType.TYPE_NUMBER_FLAG_SIGNED;
                break;
            case URL:
                editInputType = android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_FLAG_NO_SUGGESTIONS | android.text.InputType.TYPE_TEXT_VARIATION_URI;
                break;
            case NumberPad:
                editInputType = android.text.InputType.TYPE_CLASS_NUMBER;
                break;
            case PhonePad:
                editInputType = android.text.InputType.TYPE_CLASS_PHONE;
                break;
            case NamePhonePad:
                editInputType = android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_VARIATION_PERSON_NAME;
                break;
            case EmailAddress:
                editInputType = android.text.InputType.TYPE_CLASS_TEXT | android.text.InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS;
                break;
        }

        if(currentMultiline)
            editInputType |= android.text.InputType.TYPE_TEXT_FLAG_MULTI_LINE;

        boolean autoCorrect = false;
        boolean secure = false;

        switch(currentInputType)
        {
            case Standard:
                autoCorrect = false;
                secure = false;
                break;
            case AutoCorrect:
                autoCorrect = true;
                secure = false;
                break;
            case Password:
                autoCorrect = false;
                secure = true;
                break;
        }

        if(autoCorrect)
            editInputType |= android.text.InputType.TYPE_TEXT_FLAG_AUTO_CORRECT;

        if(secure)
        {
            if((editInputType & android.text.InputType.TYPE_CLASS_TEXT) == android.text.InputType.TYPE_CLASS_TEXT)
            {
                //Text input
                editInputType &= ~android.text.InputType.TYPE_TEXT_FLAG_CAP_SENTENCES;
                editInputType |= android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD;
            }
            else
            {
                //Number input
                editInputType |= android.text.InputType.TYPE_NUMBER_VARIATION_PASSWORD;
            }
        }

        mEditBox.setInputType(editInputType);
    }

    private String getText()
    {
        if(mEditBox == null)
            return "";

        return mEditBox.getText().toString();
    }

    private void showKeyboard(boolean isShow)
    {
        if(mEditBox == null)
            return;

        InputMethodManager imm = (InputMethodManager) UnityPlayer.currentActivity.getSystemService(Activity.INPUT_METHOD_SERVICE);
        if (isShow)
        {
            imm.showSoftInput(mEditBox, InputMethodManager.SHOW_FORCED);
        }
        else
        {
            if(mEditBox.hasFocus())
                mEditBox.clearFocus();
            if(sLayout.hasFocus())
                sLayout.clearFocus();

            imm.hideSoftInputFromWindow(mEditBox.getWindowToken(), 0);
        }
    }
}
