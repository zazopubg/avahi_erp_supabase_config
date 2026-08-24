.PHONY: run gen test analyze clean get build-web watch format

DART_DEFINE_FILE := dart_define.json

# تشغيل التطبيق على Chrome حصراً — يستخدم dart_define.json تلقائياً إن وُجد
# (انسخ dart_define.example.json إلى dart_define.json وعدّل القيم أولاً)
run:
ifneq (,$(wildcard $(DART_DEFINE_FILE)))
	flutter run -d chrome --dart-define-from-file=$(DART_DEFINE_FILE)
else
	@echo "⚠️  $(DART_DEFINE_FILE) غير موجود — انسخ dart_define.example.json إليه أولاً وعدّل القيم."
	flutter run -d chrome
endif

# توليد الأكواد (freezed / json_serializable / injectable / drift)
gen:
	dart run build_runner build --delete-conflicting-outputs

# مراقبة الملفات وإعادة التوليد تلقائياً عند التعديل
watch:
	dart run build_runner watch --delete-conflicting-outputs

# تشغيل جميع الاختبارات
test:
	flutter test

# تحليل الكود بحسب قواعد analysis_options.yaml
analyze:
	flutter analyze

# تثبيت الحزم
get:
	flutter pub get

# تنسيق الكود
format:
	dart format lib/ test/

# بناء نسخة الإنتاج للويب — يستخدم dart_define.json تلقائياً إن وُجد
build-web:
ifneq (,$(wildcard $(DART_DEFINE_FILE)))
	flutter build web --release --dart-define-from-file=$(DART_DEFINE_FILE)
else
	@echo "⚠️  $(DART_DEFINE_FILE) غير موجود — انسخ dart_define.example.json إليه أولاً وعدّل القيم."
	flutter build web --release
endif

# تنظيف مخرجات البناء
clean:
	flutter clean
