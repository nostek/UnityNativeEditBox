enum TextAnchor
{
    TextAnchorUpperLeft,
    TextAnchorUpperCenter,
    TextAnchorUpperRight,
    TextAnchorMiddleLeft,
    TextAnchorMiddleCenter,
    TextAnchorMiddleRight,
    TextAnchorLowerLeft,
    TextAnchorLowerCenter,
    TextAnchorLowerRight
};

enum InputType
{
    InputTypeStandard,
    InputTypeAutoCorrect,
    InputTypePassword,
};

enum TouchScreenKeyboardType
{
    TouchScreenKeyboardTypeDefault,
    TouchScreenKeyboardTypeASCIICapable,
    TouchScreenKeyboardTypeNumbersAndPunctuation,
    TouchScreenKeyboardTypeURL,
    TouchScreenKeyboardTypeNumberPad,
    TouchScreenKeyboardTypePhonePad,
    TouchScreenKeyboardTypeNamePhonePad,
    TouchScreenKeyboardTypeEmailAddress,
};

enum ReturnButtonType
{
    ReturnButtonTypeDefault,
    ReturnButtonTypeGo,
    ReturnButtonTypeNext,
    ReturnButtonTypeSearch,
    ReturnButtonTypeSend,
    ReturnButtonTypeDone,
};

// NOTE: we need extern without "C" before unity 4.5
//extern UIViewController *UnityGetGLViewController();
extern "C" UIViewController *UnityGetGLViewController();

char* MakeStringCopy(const char* string)
{
    if(string == NULL)
        return NULL;

    char* res = (char*)malloc(strlen(string) +1);
    strcpy(res, string);
    return res;
}

typedef void (*DelegateKeyboardChanged)(float x, float y, float width, float height);
typedef void (*DelegateWithText)(int instanceId, const char* text);
typedef void (*DelegateEmpty)(int instanceId);

static DelegateKeyboardChanged delegateKeyboardChanged = NULL;
static DelegateWithText delegateTextChanged = NULL;
static DelegateWithText delegateDidEnd = NULL;
static DelegateWithText delegateSubmitPressed = NULL;
static DelegateEmpty delegateGotFocus = NULL;
static DelegateEmpty delegateTapOutside = NULL;

@interface CEditBoxPlugin : NSObject<UITextFieldDelegate, UITextViewDelegate>
{
    int instanceId;
    UIView *editView;
    int characterLimit;
    UITapGestureRecognizer *tapper;
}
@end

@implementation CEditBoxPlugin

-(id)initWithInstanceId:(int)instanceId_ multiline:(BOOL)multiline
{
    self = [super init];
    
    instanceId = instanceId_;
    
    characterLimit = 0;
    
    if(!multiline)
        [self initTextField];
    else
        [self initTextView];
    
    UIView *view = UnityGetGLViewController().view;
    [view addSubview:editView];
    
    tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = YES;
    
    return self;
}

-(void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    if(![editView isFirstResponder])
        return;

    UIView *view = UnityGetGLViewController().view;
    [view endEditing:YES];
    
    if(delegateTapOutside != NULL)
        delegateTapOutside(instanceId);
}

-(void)initTextField
{
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    textField.tag = 0;
    textField.delegate = self;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.backgroundColor = [UIColor clearColor];
    
    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    editView = textField;
}

-(void)initTextView
{
    UITextView *textView = [[UITextView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    textView.tag = 0;
    textView.delegate = self;
    textView.editable = true;
    textView.scrollEnabled = true;
    textView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    textView.backgroundColor = [UIColor clearColor];
    
    editView = textView;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [editView resignFirstResponder];
    [editView removeFromSuperview];

    UIView *view = UnityGetGLViewController().view;
    [view removeGestureRecognizer:tapper];
}

// UITextField

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    UIView *view = UnityGetGLViewController().view;
    [view addGestureRecognizer:tapper];
    
    if(delegateGotFocus != NULL)
        delegateGotFocus(instanceId);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // http://stackoverflow.com/a/8913595
    
    if(characterLimit == 0)
        return YES;
    
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    
    return newLength <= characterLimit || returnKey;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self onTextDidEnd:textField.text];
    
    UIView *view = UnityGetGLViewController().view;
    [view removeGestureRecognizer:tapper];
}

-(void)textFieldDidChange:(UITextField *)textField
{
    [self onTextChange:textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if(delegateSubmitPressed != NULL)
        delegateSubmitPressed(instanceId, MakeStringCopy([[textField text] UTF8String]));

    return YES;
}

// UITextView (No return on textview)

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    UIView *view = UnityGetGLViewController().view;
    [view addGestureRecognizer:tapper];
    
    if(delegateGotFocus != NULL)
        delegateGotFocus(instanceId);
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    // http://stackoverflow.com/a/8913595
    // Removed Return test.
    
    if(characterLimit == 0)
        return YES;
    
    NSUInteger oldLength = [textView.text length];
    NSUInteger replacementLength = [text length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    return newLength <= characterLimit;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    [self onTextDidEnd:textView.text];
    
    UIView *view = UnityGetGLViewController().view;
    [view removeGestureRecognizer:tapper];
}

-(void)textViewDidChange:(UITextView *)textView
{
    [self onTextChange:textView.text];
}

// General

-(void)onTextDidEnd:(NSString *)text
{
    if(delegateDidEnd != NULL)
        delegateDidEnd(instanceId, MakeStringCopy([text UTF8String]));
}

-(void)onTextChange:(NSString *)text
{
    if(delegateTextChanged != NULL)
        delegateTextChanged(instanceId, MakeStringCopy([text UTF8String]));
}

-(void)setFocus:(BOOL)doFocus
{
    if(doFocus)
        [editView becomeFirstResponder];
    else
        [editView resignFirstResponder];
}

-(void)setPlacement:(int)left top:(int)top right:(int)right bottom:(int)bottom
{
    UIView *view = UnityGetGLViewController().view;
    
    CGFloat scale = 1.0f /[self getScale:view];
    
    CGRect frame = editView.frame;
    frame.origin.x = left * scale;
    frame.origin.y = top * scale;
    frame.size.width = (right - left) * scale;
    frame.size.height = (bottom - top) * scale;
    [editView setFrame:frame];
}

-(void)setPlaceholder:(NSString *)text color:(UIColor *)color
{
    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        
        [field setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName:color, NSFontAttributeName:[UIFont italicSystemFontOfSize:field.font.pointSize]}]];
    }
}

-(void)setFontSize:(int)size
{
    UIView *view = UnityGetGLViewController().view;
    CGFloat scale = 1.0f /[self getScale:view];
    
    CGFloat fsize = size;
    fsize *= scale;

    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        
        [field setFont:[UIFont systemFontOfSize:fsize]];
    }
    if([editView isKindOfClass:[UITextView class]])
    {
        UITextView *text = (UITextView *)editView;
        
        [text setFont:[UIFont systemFontOfSize:fsize]];
    }
}

-(void)setFontColor:(UIColor *)color
{
    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        
        [field setTextColor:color];
    }
    if([editView isKindOfClass:[UITextView class]])
    {
        UITextView *text = (UITextView *)editView;
        
        [text setTextColor:color];
    }
}

-(void)setTextAlignment:(TextAnchor)anchor
{
    NSTextAlignment textAlignment;
    UIControlContentVerticalAlignment contentVerticalAlignment;
    
    switch(anchor)
    {
        case TextAnchorUpperLeft:
            textAlignment = NSTextAlignmentLeft;
            contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
            break;
            
        case TextAnchorUpperCenter:
            textAlignment = NSTextAlignmentCenter;
            contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
            break;
            
        case TextAnchorUpperRight:
            textAlignment = NSTextAlignmentRight;
            contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
            break;
            
        case TextAnchorMiddleLeft:
            textAlignment = NSTextAlignmentLeft;
            contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            break;
            
        case TextAnchorMiddleCenter:
            textAlignment = NSTextAlignmentCenter;
            contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            break;
            
        case TextAnchorMiddleRight:
            textAlignment = NSTextAlignmentRight;
            contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            break;
            
        case TextAnchorLowerLeft:
            textAlignment = NSTextAlignmentLeft;
            contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
            break;
            
        case TextAnchorLowerCenter:
            textAlignment = NSTextAlignmentCenter;
            contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
            break;
            
        case TextAnchorLowerRight:
            textAlignment = NSTextAlignmentRight;
            contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
            break;
    }
    
    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        
        field.textAlignment = textAlignment;
        field.contentVerticalAlignment = contentVerticalAlignment;
    }
    if([editView isKindOfClass:[UITextView class]])
    {
        UITextView *text = (UITextView *)editView;
        
        text.textAlignment = textAlignment;
    }
}

-(void)setInputType:(InputType)inputType
{
    UITextAutocorrectionType autocorrectionType;
    BOOL secureTextEntry;
    
    switch(inputType)
    {
        case InputTypeStandard:
            autocorrectionType = UITextAutocorrectionTypeNo;
            secureTextEntry = NO;
            break;
        case InputTypeAutoCorrect:
            autocorrectionType = UITextAutocorrectionTypeYes;
            secureTextEntry = NO;
            break;
        case InputTypePassword:
            autocorrectionType = UITextAutocorrectionTypeNo;
            secureTextEntry = YES;
            break;
    }

    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        field.autocorrectionType = autocorrectionType;
        field.secureTextEntry = secureTextEntry;
    }
    if([editView isKindOfClass:[UITextView class]])
    {
        UITextView *text = (UITextView *)editView;
        text.autocorrectionType = autocorrectionType;
        text.secureTextEntry = secureTextEntry;
    }
}

-(void)setKeyboardType:(TouchScreenKeyboardType)keyboardType
{
    UITextAutocapitalizationType autocapitalizationType;
    UIKeyboardType uikeyboardType;
    
    if(keyboardType == TouchScreenKeyboardTypeEmailAddress)
        autocapitalizationType = UITextAutocapitalizationTypeNone;
    else
        autocapitalizationType = UITextAutocapitalizationTypeSentences;
    
    switch(keyboardType)
    {
        case TouchScreenKeyboardTypeDefault:
            uikeyboardType = UIKeyboardTypeDefault;
            break;
        case TouchScreenKeyboardTypeASCIICapable:
            uikeyboardType = UIKeyboardTypeASCIICapableNumberPad;
            break;
        case TouchScreenKeyboardTypeNumbersAndPunctuation:
            uikeyboardType = UIKeyboardTypeNumbersAndPunctuation;
            break;
        case TouchScreenKeyboardTypeURL:
            uikeyboardType = UIKeyboardTypeURL;
            break;
        case TouchScreenKeyboardTypeNumberPad:
            uikeyboardType = UIKeyboardTypeNumberPad;
            break;
        case TouchScreenKeyboardTypePhonePad:
            uikeyboardType = UIKeyboardTypePhonePad;
            break;
        case TouchScreenKeyboardTypeNamePhonePad:
            uikeyboardType = UIKeyboardTypeNamePhonePad;
            break;
        case TouchScreenKeyboardTypeEmailAddress:
            uikeyboardType = UIKeyboardTypeEmailAddress;
            break;
    }

    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        field.autocapitalizationType = autocapitalizationType;
        field.keyboardType = uikeyboardType;
    }
    if([editView isKindOfClass:[UITextView class]])
    {
        UITextView *text = (UITextView *)editView;
        text.autocapitalizationType = autocapitalizationType;
        text.keyboardType = uikeyboardType;
    }
}

-(void)setReturnButtonType:(ReturnButtonType)returnButtonType
{
    UIReturnKeyType returnKeyType;
    
    switch(returnButtonType)
    {
        case ReturnButtonTypeDefault:
            returnKeyType = UIReturnKeyDefault;
            break;
        case ReturnButtonTypeGo:
            returnKeyType = UIReturnKeyGo;
            break;
        case ReturnButtonTypeNext:
            returnKeyType = UIReturnKeyNext;
            break;
        case ReturnButtonTypeSearch:
            returnKeyType = UIReturnKeySearch;
            break;
        case ReturnButtonTypeSend:
            returnKeyType = UIReturnKeySend;
            break;
        case ReturnButtonTypeDone:
            returnKeyType = UIReturnKeyDone;
            break;
    }

    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        
        field.returnKeyType = returnKeyType;
    }
    if([editView isKindOfClass:[UITextView class]])
    {
        UITextView *text = (UITextView *)editView;
        
        text.returnKeyType = returnKeyType;
    }
}

-(void)setCharacterLimit:(int)characterLimit_
{
    characterLimit = characterLimit_;
}

-(void)setText:(NSString *)newText
{
    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        
        field.text = newText;
    }
    if([editView isKindOfClass:[UITextView class]])
    {
        UITextView *text = (UITextView *)editView;
        
        text.text = newText;
    }
}

-(void)showClearButton:(BOOL)show
{
    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        
        field.clearButtonMode = (show) ? UITextFieldViewModeWhileEditing : UITextFieldViewModeNever;
    }
}

-(void)selectRangeFrom:(int)from rangeTo:(int)to
{
    if([editView isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)editView;
        
        UITextPosition *pfrom = [field positionFromPosition:[field beginningOfDocument] offset:from];
        UITextPosition *pto = [field positionFromPosition:[field beginningOfDocument] offset:to];
        
        if(pfrom == nil || pto == nil)
            return;
        
        UITextRange *prange = [field textRangeFromPosition:pfrom toPosition:pto];
        
        if(prange == nil)
            return;
        
        [field setSelectedTextRange:prange];
    }
    if([editView isKindOfClass:[UITextView class]])
    {
        UITextView *text = (UITextView *)editView;
        
        UITextPosition *pfrom = [text positionFromPosition:[text beginningOfDocument] offset:from];
        UITextPosition *pto = [text positionFromPosition:[text beginningOfDocument] offset:to];
        
        if(pfrom == nil || pto == nil)
            return;
        
        UITextRange *prange = [text textRangeFromPosition:pfrom toPosition:pto];
        
        if(prange == nil)
            return;
        
        [text setSelectedTextRange:prange];
    }
}

- (CGFloat)getScale:(UIView *)view
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        return view.window.screen.nativeScale;
    return view.contentScaleFactor;
}

@end

@interface CEditBoxGlobalPlugin : NSObject
@end

@implementation CEditBoxGlobalPlugin

-(id)init
{
    self = [super init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardDidHideNotification object:nil];
    
    return self;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) keyboardShow:(NSNotification *)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameEnd = [keyboardInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboard = [keyboardFrameEnd CGRectValue];
    
    CGFloat scale = [self getScale:UnityGetGLViewController().view];
    
    keyboard.origin.x *= scale;
    keyboard.origin.y *= scale;
    keyboard.size.width *= scale;
    keyboard.size.height *= scale;
    
    if( delegateKeyboardChanged != NULL)
        delegateKeyboardChanged(keyboard.origin.x, keyboard.origin.y, keyboard.size.width, keyboard.size.height);
}

-(void) keyboardHide:(NSNotification *)notification
{
    if( delegateKeyboardChanged != NULL)
        delegateKeyboardChanged(0, 0, 0, 0);
}

- (CGFloat)getScale:(UIView *)view
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        return view.window.screen.nativeScale;
    return view.contentScaleFactor;
}

@end

static CEditBoxGlobalPlugin *globalPlugin = nil;

extern "C" {
    void *_CNativeEditBox_Init(int instanceId, BOOL multiline);
    void _CNativeEditBox_Destroy(void *instance);
    void _CNativeEditBox_SetFocus(void *instance, BOOL doFocus);
    void _CNativeEditBox_SetPlacement(void *instance, int left, int top, int right, int bottom);
    void _CNativeEditBox_SetPlaceholder(void *instance, const char *text, float r, float g, float b, float a);
    void _CNativeEditBox_SetFontSize(void *instance, int size);
    void _CNativeEditBox_SetFontColor(void *instance, float r, float g, float b, float a);
    void _CNativeEditBox_SetTextAlignment(void *instance, int alignment);
    void _CNativeEditBox_SetInputType(void *instance, int inputType);
    void _CNativeEditBox_SetKeyboardType(void *instance, int keyboardType);
    void _CNativeEditBox_SetReturnButtonType(void *instance, int returnButtonType);
    void _CNativeEditBox_SetCharacterLimit(void *instance, int characterLimit);
    void _CNativeEditBox_SetText(void *instance, const char *newText);
    void _CNativeEditBox_ShowClearButton(void *instance, BOOL show);
    void _CNativeEditBox_SelectRange(void *instance, int from, int to);
    void _CNativeEditBox_RegisterKeyboardChangedCallback(DelegateKeyboardChanged callback);
    void _CNativeEditBox_RegisterTextCallbacks(DelegateWithText textChanged, DelegateWithText didEnd, DelegateWithText submitPressed);
    void _CNativeEditBox_RegisterEmptyCallbacks(DelegateEmpty gotFocus, DelegateEmpty tapOutside);
}

void *_CNativeEditBox_Init(int instanceId, BOOL multiline)
{
    if(globalPlugin == nil)
    {
        globalPlugin = [[CEditBoxGlobalPlugin alloc] init];
    }
    
    id instance = [[CEditBoxPlugin alloc]initWithInstanceId:instanceId multiline:multiline];
    
    return (__bridge_retained void *)instance;
}

void _CNativeEditBox_Destroy(void *instance)
{
    CEditBoxPlugin *plugin = (__bridge_transfer CEditBoxPlugin *)instance;
    plugin = nil;
}

void _CNativeEditBox_SetFocus(void *instance, BOOL doFocus)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setFocus:doFocus];
}

void _CNativeEditBox_SetPlacement(void *instance, int left, int top, int right, int bottom)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setPlacement:left top:top right:right bottom:bottom];
}

void _CNativeEditBox_SetPlaceholder(void *instance, const char *text, float r, float g, float b, float a)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setPlaceholder:[NSString stringWithUTF8String:text] color:[UIColor colorWithRed:r green:g blue:b alpha:a]];
}

void _CNativeEditBox_SetFontSize(void *instance, int size)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setFontSize: size];
}

void _CNativeEditBox_SetFontColor(void *instance, float r, float g, float b, float a)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setFontColor:[UIColor colorWithRed:r green:g blue:b alpha:a]];
}

void _CNativeEditBox_SetTextAlignment(void *instance, int alignment)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setTextAlignment:(TextAnchor)alignment];
}

void _CNativeEditBox_SetInputType(void *instance, int inputType)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setInputType:(InputType)inputType];
}

void _CNativeEditBox_SetKeyboardType(void *instance, int keyboardType)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setKeyboardType:(TouchScreenKeyboardType)keyboardType];
}

void _CNativeEditBox_SetReturnButtonType(void *instance, int returnButtonType)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setReturnButtonType:(ReturnButtonType)returnButtonType];
}

void _CNativeEditBox_SetCharacterLimit(void *instance, int characterLimit)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setCharacterLimit:characterLimit];
}

void _CNativeEditBox_SetText(void *instance, const char *newText)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin setText:[NSString stringWithUTF8String:newText]];
}

void _CNativeEditBox_ShowClearButton(void *instance, BOOL show)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin showClearButton:show];
}

void _CNativeEditBox_SelectRange(void *instance, int from, int to)
{
    CEditBoxPlugin *plugin = (__bridge CEditBoxPlugin *)instance;
    [plugin selectRangeFrom:from rangeTo:to];
}

void _CNativeEditBox_RegisterKeyboardChangedCallback(DelegateKeyboardChanged callback)
{
    delegateKeyboardChanged = callback;
}

void _CNativeEditBox_RegisterTextCallbacks(DelegateWithText textChanged, DelegateWithText didEnd, DelegateWithText submitPressed)
{
    delegateTextChanged = textChanged;
    delegateDidEnd = didEnd;
    delegateSubmitPressed = submitPressed;
}

void _CNativeEditBox_RegisterEmptyCallbacks(DelegateEmpty gotFocus, DelegateEmpty tapOutside)
{
    delegateGotFocus = gotFocus;
    delegateTapOutside = tapOutside;
}
