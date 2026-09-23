# google_mlkit_text_recognition references the Chinese, Devanagari, Japanese,
# and Korean recognizers. The app bundles only the Latin recognizer, so R8
# must not fail on the missing script classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
