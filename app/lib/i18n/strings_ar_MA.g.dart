///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsArMa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsArMa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.arMa,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ar-MA>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsArMa _root = this; // ignore: unused_field

	@override 
	TranslationsArMa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsArMa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$changelog$ar_MA changelog = _Translations$changelog$ar_MA._(_root);
	@override late final _Translations$common$ar_MA common = _Translations$common$ar_MA._(_root);
	@override late final _Translations$dashboard$ar_MA dashboard = _Translations$dashboard$ar_MA._(_root);
	@override late final _Translations$git$ar_MA git = _Translations$git$ar_MA._(_root);
	@override late final _Translations$nav$ar_MA nav = _Translations$nav$ar_MA._(_root);
	@override late final _Translations$onboarding$ar_MA onboarding = _Translations$onboarding$ar_MA._(_root);
	@override late final _Translations$settings$ar_MA settings = _Translations$settings$ar_MA._(_root);
	@override late final _Translations$todos$ar_MA todos = _Translations$todos$ar_MA._(_root);
	@override late final _Translations$versions$ar_MA versions = _Translations$versions$ar_MA._(_root);
}

// Path: changelog
class _Translations$changelog$ar_MA extends Translations$changelog$en_US {
	_Translations$changelog$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get changelog_title => 'سجل التغييرات';
	@override String get no_entries => 'لا توجد أي تغييرات حاليا';
	@override String get delete_entry_title => 'هل تريد حذف سجل التغييرات؟';
	@override String get delete_entry_desc => 'هذا سيحذف المدخل كليا. لا يمكن التراجع عن هذا الخيار.';
	@override String get changelog_subtitle => 'تاريخ التغييرات في GodotHub.';
	@override String get edit_entry_aria => 'عدل {{version}}';
	@override String get delete_entry_aria => 'احذف {{version}}';
	@override String get added => 'مُضاف';
	@override String get fixed => 'مُصلّح';
	@override String get improved => 'مُحسّن';
}

// Path: common
class _Translations$common$ar_MA extends Translations$common$en_US {
	_Translations$common$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get new_project => 'مشروع جديد';
	@override String get import_project => 'استورد مشروع';
	@override String get search => 'البحث';
	@override String get cancel => 'إلغاء';
	@override String get save => 'احفظ';
	@override String get delete => 'احذف';
	@override String get close => 'أغلق';
	@override String get loading => 'تحميل...';
	@override String get retry => 'أعد المحاولة';
	@override String get stop => 'توقف';
	@override String get refresh => 'أعد التحميل';
	@override String get scroll_to_top => 'عُد للأعلى';
	@override String get quick_commands => 'الأوامر السريعة';
	@override String get minimize => 'أخفي';
	@override String get close_sidebar => 'أغلق الشريط الجانبي';
	@override String get star_on_github => 'نجمة في Github';
	@override String get support_dev => 'ادعم المطور على Patreon. يمكنك إغلاق هذا الخيار في الإعدادات';
	@override String get support => 'الدعم';
	@override String get restore => 'صغِّر';
	@override String get maximize => 'كبِّر';
	@override String get importing_project => 'جاري إستوراد المشروع…';
	@override String get importing_version => 'جاري إستوراد النسخة…';
	@override String get scanning_projects => 'جاري البحث عن المشاريع…';
	@override String get scanning_versions => 'جاري البحث عن الإصدارات…';
	@override String get queued => 'مُنتظر';
	@override String get download_queue_move_up => 'التقديم في قائمة الإنتظار';
	@override String get download_queue_move_down => 'التأخير في قائمة الإنتظار';
	@override String get running => 'قيد التشغيل';
	@override String running_projects_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} projects running',
		one: '${count} مشروعا شغالا',
		two: '${count} projects running',
		few: '${count} projects running',
		many: '${count} projects running',
		other: '${count} مشاريع شغالة',
	);
	@override String get active => 'مفعّل';
	@override String get done => 'تم';
	@override String get paused => 'موقوف مؤقتا';
	@override String get no_tasks_running => 'لا توجد مهام قيد التقدم';
	@override String get checking_changes => 'تحقق من التغييرات…';
	@override String get cloning => 'استنساخ';
	@override String get clone_import => 'النسخ و الإستوراد';
	@override String get import => 'استورد';
	@override String get syncing => 'جاري المزامنة…';
	@override String get edit_entry => 'عدل نقطة تغييرات';
	@override String get new_entry => 'نقطة تغييرات جديدة';
	@override String get checking_updates => 'جاري التحقق من التحديثات…';
	@override String get up_to_date => 'محدث بالفعل';
	@override String get downloading_update => 'جاري التنزيل…';
	@override String get install_update => 'ثبت';
	@override String get restart_now => 'أعد التشغيل الآن';
	@override String get update_downloaded => 'تم تنزيل التحديث!';
	@override String get restart_to_apply => 'أعد تشغيل البرنامج لتطبيق التحديث.';
	@override String get update_applied_desc => 'تم تنزيل التحديث و سيتم تثبيته في المرة القادمة التي تفتح فيها البرنامج. المرجوا إغلاق البرنامج و فتحه مجددا لإنهاء التحديث.';
	@override String get is_latest => 'v{{version}} هي أخر نسخة.';
	@override String get percent_complete => '{{percent}}% مكتملة';
	@override String get expand_sidebar => 'وسع الشريط الجانبي';
	@override String get collapse_sidebar => 'أغلق الشريط الجانبي';
	@override String get saving => 'جاري الحفظ…';
	@override String get save_changes => 'احفظ التغييرات';
	@override String get add_entry => 'أضف مدخل';
	@override String get scan_for_projects => 'ابحث عن المشاريع';
	@override String get create_workspace => 'أنشئ بيئة عمل';
	@override String get report_a_bug => 'أبلغ عن مشكلة';
	@override String get report_bug => 'أبلغ عن مشكلة';
	@override String get app_error_title => 'حدث خطأ ما';
	@override String get app_error_desc => 'قد حصل خطأ غير متوقع و لا يمكن العرض. التفاصيل في الأسفل, تأكد من الطرفية (right-click → Inspect) من أجل المتابعة الكاملة للمشكلة.';
	@override String get reload => 'إعادة التحميل';
	@override String get view_error_title => 'This view couldn\'t load';
	@override String get view_error_desc => 'The rest of GodotHub still works. Try loading this view again, or switch to another one.';
	@override String get error_details => 'Technical details';
	@override String get remove_folder => 'أزل المجلد';
	@override String get make_this_default => 'اجعل هذا {{label}}';
	@override String get suggested_from_workspaces => 'مقترح من بيئة عمل أخرى';
	@override String get from_workspace => 'من {{name}}';
	@override String get add_folder => 'أضف مجلدا جديدا';
	@override String get default_folder => 'الإفتراضي';
	@override String get default_downloads_go_to => 'التنزيلات الإفتراضية سوف تكون في "{{path}}"';
	@override String get open_terminal => 'افتح الطرفية';
	@override String get downloading_version => 'جاري تحميل {{version}}';
	@override String get downloading_asset => 'جاري تحميل {{title}}';
	@override String get asset_download_failed => 'فشل تنزيل القالب';
	@override String get scan_for_engines => 'البحث عن المحركات';
	@override String get import_version => 'استورد إصدارا';
	@override String get sync_templates_from_directory => 'زامن القوالب من المجلدات';
	@override String get section_navigation => 'التصفح';
	@override String get section_projects => 'المشاريع';
	@override String get section_views => 'Views';
	@override String get section_workspaces => 'بيئات العمل';
	@override String get section_help => 'المساعدة';
	@override String get section_engines => 'المحركات';
	@override String get section_templates => 'القوالب';
	@override String get section_versions => 'الإصدارات';
	@override String get section_news => 'الأخبار';
	@override String get skip_setup => 'تخطي واجهة الإعداد';
	@override String get back => 'العودة';
	@override String get finishing => 'جاري الإنهاء…';
	@override String get get_started => 'ابدأ';
	@override String get scanning => 'جاري البحث…';
	@override String get scan_now => 'ابحث الآن';
	@override String get scan_complete => 'البحث اكتمل';
	@override String get scan_failed => 'فشل البحث';
	@override String get uncategorized => 'غير مصنف';
	@override String get all => 'الكل';
	@override String get no_filter => 'لا يوجد مرشح';
	@override String get cannot_undo => 'لا يمكن التراجع عن هذا.';
	@override String get deleting => 'جاري الحذف…';
	@override String get open_project => 'افتح المشروع';
	@override String get play_project => 'شغّل مباشرة';
	@override String get play_project_tooltip => 'شغل اللعبة/التطبيق مباشرة هنا دون فتح المشروع.';
	@override String get no_version_selected => 'لا يوجد إصدار محدد';
	@override String get open_with_console => 'افتح مع الطرفية';
	@override String get open_folder => 'افتح المجلد';
	@override String get open_in_ide => 'إفتح في بيئة تطوير (IDE)';
	@override String get category => 'الصنف';
	@override String get none => 'لا أحد';
	@override String get project_size => 'حجم المشروع';
	@override String get project_size_scanning => 'Scanning project files…';
	@override String get project_size_empty => 'No files found';
	@override String get launch_arguments => 'خيارات الإقلاع';
	@override String get save_as_template => 'إحفظ كقالب';
	@override String get git => 'Git';
	@override String get add => 'أضف';
	@override String get color_label => 'اللون';
	@override String get icon_label => 'الأيقونة';
	@override String get expand => 'توسيع';
	@override String get collapse => 'تقليص';
	@override String file_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} ملف',
		one: '${count} ملف',
		two: '${count} ملف',
		few: '${count} ملف',
		many: '${count} ملف',
		other: '${count} ملفات',
	);
	@override String folder_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} مجلد',
		one: '${count} مجلد',
		two: '${count} مجلد',
		few: '${count} مجلد',
		many: '${count} مجلد',
		other: '${count} مجلدات',
	);
	@override String get template_empty => 'هذا القالب فارغ.';
	@override String get categories => 'التصنيفات';
	@override String get category_folders_hint => 'المشاريع الموجودة داخل مجلدات الفئة تُنسب إليها تلقائيًا.';
	@override String get assign_folder => 'إسناد مجلد';
	@override String get assign_folder_to_category => 'إسناد مجلد إلى {{name}}';
	@override String get unassign_folder_aria => 'إزالة المجلد {{folder}} من هذه الفئة';
	@override String get new_category_placeholder => 'إسم تصنيف جديد…';
	@override String get no_categories_yet => 'لا توجد تصنيفات بعد, أضف واحدا في الأعلى.';
	@override String get edit_category => 'عدل {{name}}';
	@override String get delete_category => 'احذف {{name}}';
	@override String get delete_category_title => 'احذف التصنيف?';
	@override String get delete_category_desc => '"{{name}}" سيُزال. و ستصبح ملفاته بلا تصنيف, لا شيء على جهازك سيُلمس.';
	@override String get project_name_label => 'الإسم';
	@override String get folder_name_preview => 'Dir. Convention: {{name}}';
	@override String get folder_name_hint => 'يُشتق اسم المجلد من اسم المشروع باستخدام اصطلاح التسمية الخاص بك.';
	@override String get template_preview_aria => 'معاينة {{name}}';
	@override String get project_location_label => 'الموقع';
	@override String get choose_folder_placeholder => 'اختر موقعا';
	@override String get browse => 'تصفح';
	@override String get blank_template => 'الإفتراضي';
	@override String get template_optional => 'قالب (اختياري)';
	@override String get category_optional => 'التصينف (اختياري)';
	@override String get no_category_label => 'لا يوجد تصنيف';
	@override String get godot_version_label => 'إصدار Godot';
	@override String get no_engine_warning => 'لا يوجد إصدار محرك مثبت بعد, اختر واحد من قائمة الإصدارات أولا.';
	@override String get change_icon => 'غيير';
	@override String get choose_icon => 'اختر';
	@override String get icon_format_desc => 'SVG, PNG, أو JPG. هي الصيغ الإفتراضية المسموحة للمحرك.';
	@override String get other_settings_label => 'إعدادات أخرى';
	@override String get init_git_label => 'جهِّز مستودع Git';
	@override String get init_git_desc => 'أضف .gitignore و .gitattributes للمشروع, ثم قد بتنفيذ البرنامج الأول على Main.';
	@override String get init_git_unavailable => 'قم بتثبيت Git ثم أعد تشغيل GodotHub لاستخدام هذا.';
	@override String get initializing_git => 'جاري تجهيز Git…';
	@override String get git_init_warning_title => 'تم إنشاء المشروع, Git يحتاج انتباهك';
	@override String get git_option_gitignore => 'Godot .gitignore';
	@override String get git_option_gitattributes => '.gitattributes';
	@override String get git_option_readme => 'README.md';
	@override String get git_option_license => 'الرخصة';
	@override String get git_option_no_license => 'بدون رخصة';
	@override String get create_remote_label => 'أنشئ مستودعا على GitHub/GitLab';
	@override String get create_remote_desc => 'أنشئ مستودعا على حسابك المتصل و ادفع تنفيذ التهيئة.';
	@override String get remote_private => 'خاص';
	@override String get remote_public => 'عام';
	@override String get creating_remote_repo => 'أنشئ مستودعا عن بعد…';
	@override String get remote_repo_created_title => 'تم إنشاء المستودع';
	@override String get create_project_done => 'تم';
	@override String get create_project_btn => 'أنشئ مشروعا';
	@override String get creating => 'جاري الإنشاء…';
	@override String get create_project_error => 'أعط المشروع إسما و مجلد ليوضع فيه.';
	@override String get create_workspace_title => 'بيئة عمل جديدة';
	@override String get workspace_name_label => 'الإسم';
	@override String get workspace_name_placeholder => 'العمل, شخصي, Game Jam…';
	@override String get workspace_name_required_error => 'أعطي بيئة العمل إسما.';
	@override String get edit_workspace_title => 'عدل بيئة العمل';
	@override String get cant_delete_only_workspace => 'لا يمكنك حذف بيئة عملك الوحيدة';
	@override String get delete_workspace_title => 'هل تريد حذف بيئة العمل?';
	@override String get delete_workspace_desc => '"{{name}}" و كل شيء في تابع لها (إعداداتها, مشاريعها, و تصنيفاتها) ستُحذف. الملفات الموجودة على جهاز فعلا لا تلمس أبدا. إصدارات Godot تكون مُشتركة و لا تحذف هي الأخرى.';
	@override String get other => 'أخرى';
	@override String get args_label => 'الخيارات';
	@override String get args_placeholder => 'e.g. --debug --single-window';
	@override String get args_suggestions => 'الإقتراحات';
	@override String get args_desc_separate_prefix => 'افصل بين الخيارات بمساحة. أوامر بقيم مثل';
	@override String get args_desc_separate_suffix => 'استخدم رمزين.';
	@override String get args_debug => '--debug';
	@override String get args_debug_desc => 'شغل مع مصحح أخطاء ملحق';
	@override String get args_single_window => '--single-window';
	@override String get args_single_window_desc => 'أرغم وضع النافذة الواحدة';
	@override String get args_opengl3 => '--rendering-driver opengl3';
	@override String get args_opengl3_desc => 'استعمل مشغل الرسوميات OpenGL 3';
	@override String get args_vulkan => '--rendering-driver vulkan';
	@override String get args_vulkan_desc => 'استعمل مشغل الرسوميات Vulkan';
	@override String get args_headless => '--headless';
	@override String get args_headless_desc => 'شغل بدون نافذة';
	@override String get args_verbose => '--verbose';
	@override String get args_verbose_desc => 'سجل مخرجات تصحيح الأخطاء التفصيلية';
	@override String get args_editor => '--editor';
	@override String get args_editor_desc => 'افتح البرنامج (same as -e)';
	@override String get args_build_solutions => '--build-solutions';
	@override String get args_build_solutions_desc => 'ابني برامج C# عند الفتح';
	@override String get args_gpu_index => '--gpu-index 1';
	@override String get args_gpu_index_desc => 'Use GPU index 1 (بطاقة الرسومات المخصصة)';
	@override String get sort_categories => 'التصنيفات';
	@override String get sort_recent => 'مفتوح مؤخرا';
	@override String get sort_manual => 'يدوي';
	@override String get sort_name_asc => 'الإسم (A–Z)';
	@override String get sort_name_desc => 'الإسم (Z–A)';
	@override String get sort_created_desc => 'التاريخ المضاف (الأحدث)';
	@override String get sort_created_asc => 'التاريخ المضاف (الأقدم)';
	@override String get sort_time_desc => 'الوقت الإجمالي';
	@override String get filter => 'المرشح';
	@override String get no_templates_yet => 'لا توجد قوالب بعد. اضغط بزر الفأرة الأيمن أو افتح قائمة "المزيد" ثم اختر <1 > احفظ القالب </1> لإنشاء واحد.';
	@override String get godot => 'Godot';
	@override String get delete_template => 'احذف قالب {{name}}';
	@override String get news_subtitle => 'المنشورات الأخيرة من مدونة Godot الرسمية.';
	@override String get news_cached => 'لا يمكن الوصول لـ godotengine.org, أظهر المقالات المحفوظة من أخر مرة.';
	@override String get news_error => 'لا يمكن تحميل أخبار Godot.';
	@override String get news_empty => 'لا يوجد أخبار لعرضها حاليا.';
	@override String get show_more => 'أظهر المزيد';
	@override String get try_again => 'أعد المحاولة مرة أخرى';
	@override String get asset_store_title => 'متجر الأصول';
	@override String get news_count => 'منشور(منشورات)';
	@override String asset_store_count_plural({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'لا توجد أصول',
		one: 'أصل',
		two: 'أصل(أصول)',
		few: 'أصل(أصول)',
		many: 'أصل(أصول)',
		other: 'أصول',
	);
	@override String get asset_store_count => 'أصل(أصول)';
	@override String get settings_title => 'الإعدادات';
	@override String get no_templates_match => 'لم يتم العثور على قالب';
	@override String get no_projects_match => 'لم يتم العثور على المشروع';
	@override String get more_import_options => 'المزيد من خيارات الإستوراد';
	@override String get clone_import_repo => 'استنسخ و استورد من المستودع';
	@override String get manage_categories => 'أدر التصنيفات';
	@override String get hide_category => 'Hide Category';
	@override String get category_hidden_toast => '"{{name}}" hidden. Restore it from Hidden Categories.';
	@override String get hidden_categories => 'Hidden Categories';
	@override String get hidden_categories_hint => 'Those categories and their projects stay out of the way. Unhide one to bring it back.';
	@override String get hidden_category_projects => '{{count}} project(s)';
	@override String get unhide => 'Unhide';
	@override String get unhide_category_aria => 'Unhide {{name}}';
	@override String get search_projects_placeholder => 'ابحث عن المشاريع بالإسم أو المسار…';
	@override String get clear_search => 'امسح البحث';
	@override String get search_filter_title => 'Filter projects by';
	@override String get search_slash_hint => 'Type / to filter by name, tags, categories and more';
	@override String get search_filter_name => 'Name';
	@override String get search_filter_tag => 'Tag';
	@override String get search_filter_version => 'Engine version';
	@override String get search_filter_path => 'Path';
	@override String get search_filter_pinned_yes => 'Pinned only';
	@override String get search_filter_pinned_no => 'Not pinned';
	@override String get search_filter_no_matches => 'No matching filters';
	@override String get search_filter_no_values => 'No matching values';
	@override String get sort => 'رتب…';
	@override String get view_list => 'List';
	@override String get view_grid => 'Grid';
	@override String get view_kanban => 'Kanban';
	@override String get no_projects_yet => 'لا شيء هنا بعد. أنشئ مشروعا جديدا أو استورد واحدا لديك بالفعل.';
	@override String get pinned_section => 'مثبت';
	@override String get set_category => 'عيين تصنيفا…';
	@override String get clear_selection => 'ألغي الإختيار';
	@override String get starting => 'جاري البدأ…';
	@override String get app_loading => 'جاري التحميل…';
	@override String get changelog_version_label => 'الإصدار';
	@override String get changelog_version_placeholder => 'v1.0.0';
	@override String get changelog_date_label => 'التاريخ';
	@override String get changelog_date_placeholder => '2026-07-13';
	@override String get changelog_what_changed => 'ماذا تغيير';
	@override String get changelog_add_line => 'أضف سطرا';
	@override String get changelog_remove_line_aria => 'أزل سطرا';
	@override String get changelog_placeholder_note => 'تمت إضافة القدرة على إعادة ترتيب المشاريع عن طريق السحب و الإفلات';
	@override String get changelog_error_no_version => 'عيين إصدارا للمدخل.';
	@override String get changelog_known_issues => 'المشاكل المعروقة';
	@override String get changelog_known_issues_none => 'لا توجد مشاكل معروفة لهذه الإصدارة.';
	@override String get changelog_known_issue_placeholder => 'اشرح المشكلة المعروفة...';
	@override String get changelog_remove_known_issue_aria => 'أزل المشكلة المعروفة';
	@override String get changelog_add_known_issue => 'أضف مشكلة معروفة';
	@override String get changelog_generate_from_git => 'ولّد من Git';
	@override String get changelog_draft_title => 'ملاحظات الإصدار من Git';
	@override String get changelog_draft_from => 'من';
	@override String get changelog_draft_to => 'إلى';
	@override String get changelog_draft_generate => 'Generate draft';
	@override String get changelog_draft_use => 'Use Draft';
	@override String get changelog_draft_commits => '{{count}} commit(s)';
	@override String get changelog_draft_include => 'Include in draft';
	@override String get changelog_draft_none => 'No commits found in this range.';
	@override String get template_search_placeholder => 'جاري البحث عن القوالب…';
	@override String get template_delete_title => 'هل تريد القالب?';
	@override String get template_delete_desc => '"{{name}}" will be permanently removed.';
	@override String get templates_tab_local => 'القوالب المحلية';
	@override String get templates_tab_asset => 'مكتبة الأصول';
	@override String get asset_search_placeholder => 'جاري البحث عن أصول…';
	@override String get asset_all_versions => 'كل الإصدارات';
	@override String get asset_result_count => '{{count}} نتيجة';
	@override String get asset_load_error => 'Couldn\'t load the Asset Library. Check your connection and try again.';
	@override String get asset_no_results => 'No assets found. Try a different search.';
	@override String get asset_by_author => 'بواسطة {{author}}';
	@override String get asset_open_page => 'افتح في المتصف';
	@override String get asset_install => 'ثبت';
	@override String get asset_install_inside => 'ثبت';
	@override String get asset_installing => 'جاري التثبيت…';
	@override String get asset_installed => 'مُثبت';
	@override String get asset_prev_page => 'الصفحة السابقة';
	@override String get asset_next_page => 'الصفحة التالية';
	@override String get asset_page_x_of_y => 'الصفحة {{page}} من إجمالي {{total}}';
	@override String template_your_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'قالب(قوالب)',
		one: 'قالب',
		two: 'قالب(قوالب)',
		few: 'قالب(قوالب)',
		many: 'قالب(قوالب)',
		other: 'قوالب',
	);
	@override String get template_imported_count => 'مستوردة {{count}}';
	@override String get template_updated_count => 'محدثة {{count}}';
	@override String get template_removed_count => 'مزالة {{count}}';
	@override String get asset_source_all => 'كل المصادر';
	@override String get asset_source_library => 'مكتبة أصول قديمة';
	@override String get asset_source_store => 'مكتبة أصول حديثة';
	@override String get asset_store_relevance => 'Relevance';
	@override String get asset_store_updated_new => 'Newest updated';
	@override String get asset_store_updated_old => 'Oldest updated';
	@override String get asset_store_rating_high => 'Top rated';
	@override String get asset_store_rating_low => 'Lowest rated';
	@override String get asset_download_outside => 'حمل خارجا';
	@override String get asset_downloaded => 'محمل';
	@override String get asset_downloaded_to => 'محمل في';
	@override String get asset_download_error => 'Couldn\'t download the asset. Check your connection and try again.';
	@override String get asset_install_modal_title => 'ثبت {{title}}';
	@override String get asset_install_tab_project => 'داخل مشروع';
	@override String get asset_install_tab_template => 'داخل قالب';
	@override String get asset_install_search_projects => 'جاري البحث عن المشاريع…';
	@override String get asset_install_no_projects => 'لا يوجد أي مشروع بعد. أنشئ أو استورد واحدا أولا.';
	@override String get asset_install_no_templates => 'لا توجد قوالب محفوظة بعد.';
	@override String get asset_install_into => 'ثبت في {{name}}';
	@override String get asset_install_success_project => 'تم التثبيت في {{target}}';
	@override String get asset_install_success_template => 'تمت إضافته للقالب {{target}}';
	@override String get asset_new_template_btn => 'احفظ كقالب جديد';
	@override String get asset_new_template_hint => 'Creates a new template from this project asset';
	@override String get onboarding_keep_organized => 'Keep every project organized in one place.';
	@override String get onboarding_download_manage => 'Download and manage Godot engine builds.';
	@override String get onboarding_stay_current => 'Stay current with what\'s new in Godot.';
	@override String get onboarding_projects_title => 'Where are your projects?';
	@override String get onboarding_projects_desc => 'Add folders GodotHub should scan for existing Godot projects at startup. Star one to make it the default save location when you create a new project. You can skip this and add folders later in Settings.';
	@override String get onboarding_versions_title => 'Where do Godot versions live?';
	@override String get onboarding_versions_desc => 'Add folders GodotHub should scan for installed Godot engine executables. Star one to set it as the download location for new versions you install through the Versions tab.';
	@override String get onboarding_templates_title => 'Template projects directory';
	@override String get onboarding_templates_desc => 'Optionally set a folder where you keep reusable project templates. Any subfolder inside it will be imported as templates on finish, so they show up when you create new projects. You can also save individual projects as templates anytime from the Projects view, or import more later from the Templates tab.';
	@override String get onboarding_categories_title => 'Organize with categories';
	@override String get onboarding_categories_desc_full => 'Categories are folders for your project list, file projects under them however makes sense to you. Add a few starters or make your own; you can rename, reorder, or delete these anytime from Settings.';
	@override String get onboarding_custom_category_placeholder => 'إسم تصنيف مخصص…';
	@override String get onboarding_your_categories => 'تصنيفاتك';
	@override String get onboarding_customize_title => 'اجعله مِلكك';
	@override String get onboarding_customize_desc => 'Pick an accent and background color to start. Corner roundness, density, text size, and light/dark mode are all in Settings whenever you want to fine-tune further.';
	@override String get onboarding_finish_title => 'You\'re all set';
	@override String get onboarding_finish_desc => 'GodotHub is ready to go. You can revisit any of this, folders, categories, and appearance, from the Settings tab at any time.';
	@override String get onboarding_setting_up_title => 'تجهيز بعض الأمور';
	@override String get onboarding_setting_up_desc => 'Setting up your library… scanning folders for projects and Godot versions. This only happens once, and it won\'t take long.';
	@override String get skipped => 'متخطى';
	@override String get onboarding_continue => 'استمرار';
	@override String get onboarding_accent_color => 'اللون الأساسي';
	@override String get onboarding_bg_color => 'لون الخلفية';
	@override String get onboarding_corner_radius => 'دوران الزوايا';
	@override String get onboarding_discord_rpc => 'ميزة \'Rich Presence\' في Discord';
	@override String get onboarding_discord_rpc_desc => 'Show what you\'re doing in GodotHub on your Discord profile.';
	@override String get version_search_placeholder => 'بحث عن الإصدارات…';
	@override String get version_no_installed => 'لا توجد إصدارات مثبتة. Download a version from below or drag and drop your existing version folder here.';
	@override String get version_save_name_aria => 'احفظ الإسم';
	@override String get version_rename_aria => 'أعد تسمية الإصدار';
	@override String get version_mono_badge => 'Mono';
	@override String get version_uninstall_title => 'هل تريد إلغاء تثبيت هذا الإصدار';
	@override String get version_uninstall_desc => '"{{tag}}" and its files will be moved to your system\'s Trash / Recycle Bin. You can reinstall it later if needed.';
	@override String get version_uninstall_confirm => 'إلغاء التثبيت';
	@override String get project_remove_title => 'هل تريد إزالته من المكتبة?';
	@override String get project_remove_desc => '"{{name}}" will be removed from GodotHub\'s list. Its files stay on disk untouched, you can import it again anytime.';
	@override String get project_delete_title => 'هل تريد النقل لسلة المهملات؟';
	@override String get project_delete_desc => '"{{name}}" and everything inside it will be moved to your system\'s Trash / Recycle Bin. You can restore it later if needed.';
	@override String get project_delete_confirm => 'انقل لسلة المهملات';
	@override String get project_template_name_label => 'إسم القالب';
	@override String get project_template_desc_label => 'الوصف';
	@override String get project_template_desc_placeholder => 'ماذا يتضمن هذا القالب؟';
	@override String get project_save_template_btn => 'احفظ القالب';
	@override String get template_saved_toast => 'Template saved.';
	@override String get project_select_aria => 'اختر المشروع';
	@override String get project_deselect_aria => 'ألغي حفظ المشروع';
	@override String get select_all_visible => 'Select all visible';
	@override String get selected_count => '{{count}} selected';
	@override String get bulk_launch => 'Launch';
	@override String get bulk_pin => 'Pin';
	@override String get bulk_remove => 'أزل';
	@override String get bulk_remove_title => 'Remove {{count}} projects from library?';
	@override String get bulk_remove_desc => 'The selected projects will be removed from your library. Their files will stay on disk.';
	@override String get bulk_delete_title => 'Delete {{count}} projects?';
	@override String get bulk_delete_desc => 'The selected project files will be permanently moved to the Trash. This cannot be undone.';
	@override String get project_pin_aria => 'ثبت المشروع';
	@override String get project_unpin_aria => 'ألغي تثبيت المشروع';
	@override String get time_today => 'اليوم';
	@override String get time_this_week => 'هذا الأسبوع';
	@override String get time_all_time => 'الوقت الإجمالي';
	@override String get time_tracked_title => 'الوقت المتتبع';
	@override String get time_weekly_chart => 'أخر 7 أيام';
	@override String get time_week_total => '{{total}} هذا الأسبوع';
	@override String get time_weekly_empty => 'لا يوجد وقت متتبع في أخر 7 أيام.';
	@override String get project_more_aria => 'المزيد';
	@override String get customize_card_section => 'Project Card';
	@override String get customize_card_show_size => 'أظهر حجم المشروع';
	@override String get customize_card_show_time => 'أظهر الوقت متتبع';
	@override String get customize_card_show_session_timer => 'Show Session Timer';
	@override String get customize_card_blur_path => 'أخفي مجلد المشروع';
	@override String get customize_card_show_path => 'أظهر مجلد المشروع';
	@override String get customize_card_show_tags => 'أظهر الوسوم';
	@override String get customize_card_show_last_opened => 'أظهر أخر مشروع فتح';
	@override String get customize_card_show_play => 'أظهر زر التشغيل المباشر';
	@override String get customize_card_show_console => 'أظهر زر التشغيل مع الطرفية';
	@override String get project_card_remove_library => 'أزل من المكتبة';
	@override String get project_card_delete_files => 'احذف الملفات';
	@override String get manage_tags => 'أدر الوسوم';
	@override String get tag_input_placeholder => 'وسم جديد…';
	@override String get tag_already_exists => 'يوجد وسم بهذا الإسم فعلا.';
	@override String get tag_rename_hint => 'اضغط لإعادة التسمية';
	@override String get tag_rename_aria => 'أعد تسمية الوسم';
	@override String get show_more_tags => 'أظهر وسوم أكثر';
	@override String get show_fewer_tags => 'أظهر وسوم أقل';
	@override String get clear_tag_filter => 'Clear tag filter';
	@override String get saving_tags => 'جاري حفظ الوسوم…';
	@override String tag_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} وسم(وسوم)',
		one: '${count} وسم',
		two: '${count} وسم(وسوم)',
		few: '${count} وسم(وسوم)',
		many: '${count} وسم(وسوم)',
		other: '${count} وسوم',
	);
	@override String get no_tags => 'لا توجد وسوم بعد';
	@override String get bug_report_describe_label => 'ماذا حدث?';
	@override String get bug_report_describe_placeholder => 'What were you doing when the bug appeared? Add steps to reproduce and what you expected vs. what actually happened.';
	@override String get bug_report_diagnostics_label => 'Diagnostic info';
	@override String get bug_report_diagnostics_hint => 'Auto-collected · included in the report';
	@override String get bug_report_copied => 'منسوخ!';
	@override String get bug_report_copy_log => 'انسخ السجل';
	@override String get bug_report_download_log => 'حمل السجل';
	@override String get bug_report_open_github => 'افتح قائمة المشاكل في Github';
	@override String get check_updates_title_modal => 'تحقق من التحديثات';
	@override String get check_updates_version_available => 'الإصدار {{version}} متوفر';
	@override String get check_updates_ask_download => 'هل تريد أن تحمله و تثبته الآن؟';
	@override String get check_updates_release_notes => 'ملاحظات الإصدار';
	@override String get check_updates_failed => 'فشل التحقق من التحديثات';
	@override String get check_updates_rate_limited => 'GitHub rate limit reached';
	@override String get check_updates_token_rejected => 'GitHub token rejected';
	@override String get check_updates_rate_limited_hint => 'GitHub only allows 60 anonymous requests per hour, shared with everyone on your network. Adding a personal access token in Settings raises this to 5,000 per hour and is also used for fetching Godot versions.';
	@override String get check_updates_rate_limited_token_hint => 'Your saved GitHub token was rejected. It may have expired or been revoked. Test it in Settings and replace it if needed.';
	@override String get check_updates_add_token => 'أضف رمز GitHub';
	@override String get check_updates_open_token_settings => 'افتح إعدادات الرمز (Token)';
	@override String get check_updates_preview_badge => 'معاينة';
	@override String get check_updates_portable_title => 'يتطلب التحديث اليدوي';
	@override String get check_updates_portable_desc => 'Portable installs cannot auto-update. Download the latest version from GitHub and replace the existing files.';
	@override String get check_updates_download_from_github => 'حمل من GitHub';
	@override String get preview_state_checking => 'التحقق';
	@override String get preview_state_available => 'المتوفر';
	@override String get preview_state_downloading => 'التحميل';
	@override String get preview_state_done => 'تم';
	@override String get preview_state_uptodate => 'مُحدث';
	@override String get preview_state_error => 'خطأ';
	@override String get preview_state_portable => 'Portable';
	@override String get preview_update_modal => 'Preview Update Modal';
	@override String get clone_repo_title => 'استنسخ المستودع';
	@override String get clone_repo_url_label => 'انسخ رابط المستودع';
	@override String get clone_repo_url_placeholder => 'https://github.com/user/my-game.git';
	@override String get clone_repo_error_url => 'Please enter a repository URL.';
	@override String get clone_repo_error_location => 'Please choose where to clone the repository.';
	@override String get clone_repo_open_after => 'Open it right after importing';
	@override String get clone_repo_browse_repos => 'تصفح مستودعاتك';
	@override String get clone_repo_url_manual => 'الصق الرابط يدويا';
	@override String get clone_repo_search_repos => 'ابحث في مستودعاتك...';
	@override String get clone_repo_no_repos_found => 'No repositories match your search.';
	@override String get clone_repo_loading_repos => 'جاري تحميل المستودعات...';
	@override String get clone_repo_load_error => 'Failed to load repositories.';
	@override String get clone_repo_select => 'اختر';
	@override String get clone_repo_no_account => 'No GitHub or GitLab account connected. Use a URL to clone instead.';
	@override String get clone_repo_repos_loaded => 'تم تحميل المستودعات';
	@override String get load_more => 'حمل المزيد';
	@override String get git_uncommitted => 'غير منفذ';
	@override String get git_clean => 'امسح';
	@override String get task_tray_title => 'المهام';
	@override String get task_tray_empty => 'لا مهام مشغلة حاليا';
	@override String get task_tray_active_count => '{{active}} مشغلة, {{recent}} الأخيرة';
	@override String task_tray_only_recent({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} مهمة أخيرة',
		one: '${count} المهمة الأخيرة',
		two: '${count} مهمة أخيرة',
		few: '${count} مهمة أخيرة',
		many: '${count} مهمة أخيرة',
		other: '${count} المهام الأخيرة',
	);
	@override String get task_tray_aria => 'المهام';
	@override String get task_tray_auto_dismiss => 'Completed auto-dismiss';
	@override String get task_tray_dismiss => 'متجاهلة {{count}}';
	@override String get task_error_status => 'خطأ';
	@override String get command_palette_title => 'Command Palette';
	@override String get command_palette_placeholder => 'Search commands, projects, engines, settings…';
	@override String get command_palette_no_results => 'لا توجد نتائج متوافقة';
	@override String get command_palette_navigate => 'تصفح';
	@override String get command_palette_escape => 'Esc';
	@override String get setting_token_placeholder => 'ghp_xxxxxxxxxxxxxxxxxxxx';
	@override String get setting_project_scan_dirs => 'Scan Project Folders';
	@override String get setting_version_scan_dirs => 'Scan Version Folders';
	@override String get setting_default_project_location => 'Default Project Location Setting';
	@override String get setting_download_dir => 'Download Versions Location Setting';
	@override String get setting_scan_depth => 'Scan Depth';
	@override String get setting_icon_scan_depth => 'Project Icon Search Depth';
	@override String get setting_download_concurrency => 'التنزيلات المتتالية';
	@override String get setting_close_on_project_open => 'أغلق عن فتح المشروع';
	@override String get setting_minimize_to_tray => 'أخفي لشريط المهام';
	@override String get setting_reopen_after_godot_closes => 'أعد الفتح عند إغلاق Godot';
	@override String get setting_auto_scan_on_startup => 'البحث عند التلقائي عند تشغيل التطبيق';
	@override String get setting_workspaces_enabled => 'Use Workspaces';
	@override String get setting_directory_naming_convention => 'Directory Naming Convention';
	@override String get setting_git_init_new_projects => 'Initialize Git for New Projects';
	@override String get setting_tooltip_delay => 'Tooltip Delay';
	@override String get setting_command_palette_keybind => 'Command Palette Shortcut';
	@override String get setting_tray_recent_projects_count => 'Tray Recent Projects';
	@override String get setting_last_opened_time_format => 'Time Format';
	@override String get setting_last_opened_date_format => 'Date Format';
	@override String get setting_theme_mode => 'السمة';
	@override String get setting_accent_color => 'ألوان الهوية';
	@override String get setting_background_color => 'لون الخلفية';
	@override String get setting_corner_radius => 'انحناء الزوايا';
	@override String get setting_ui_density => 'UI Density';
	@override String get setting_font_scale => 'حجم الخط';
	@override String get setting_animation_intensity => 'Animation Intensity';
	@override String get setting_view_entrance => 'View Entrance Animation';
	@override String get setting_custom_css => 'Custom CSS';
	@override String get setting_project_icon_opacity => 'Project Icon Opacity';
	@override String get setting_show_scrollbars => 'Show Scrollbar';
	@override String get setting_setup_wizard => 'Setup Wizard';
	@override String get setting_reset_settings => 'Reset Settings';
	@override String get setting_delete_app_data => 'Delete App Data';
	@override String get setting_check_updates => 'Check for Updates';
	@override String get setting_show_support_button => 'Show Support Button';
	@override String get setting_show_star_button => 'Show Star Button';
	@override String get setting_discord_rpc_enabled => 'Discord Rich Presence';
	@override String get setting_discord_app_id => 'Discord Application ID';
	@override String get setting_discord_rpc_show_projects => 'Discord Show Project Names';
	@override String get setting_discord_rpc_excluded_projects => 'Discord Excluded Projects';
	@override String get setting_discord_rpc_project_presences => 'Discord Custom Presence';
	@override String get active_workspace => '{{name}} (مفعّل)';
	@override String get current_workspace => 'بيئة العمل الحالية';
	@override String get switch_workspace => 'بدل بيئة العمل';
	@override String get opened_recently => 'مفتوحة {{label}}';
	@override String get recent_section => 'الأخيرة';
	@override String get installed_versions_section => 'الإصدارات المثبتة';
	@override String get settings_label => 'الإعدادات → {{tab}}';
	@override String get remove_category_aria => 'أزل {{name}}';
	@override String get git_remove_remote => 'Remove remote';
	@override String get git_commit_placeholder => 'رسالة التنفيذ…';
	@override String get restart_required_title => 'Restart required';
	@override String get restart_required_desc => 'This change requires GodotHub to restart to take full effect. The setting has been saved and will apply when you relaunch the app.';
	@override String found_dismissed_title({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} previously removed projects found',
		one: 'Previously removed project found',
		two: '${count} previously removed projects found',
		few: '${count} previously removed projects found',
		many: '${count} previously removed projects found',
		other: '${count} previously removed projects found',
	);
	@override String found_dismissed_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
		one: 'Scanner found 1 project that you previously removed from the library. Would you like to re-add it?',
		two: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
		few: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
		many: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
		other: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
	);
	@override String get readd_all => 'Re-add All';
	@override String get skip_all => 'تخطي الكل';
	@override String get project_already_open_title => 'المشروع مفتوح بالفعل';
	@override String get project_already_open_desc => '{{name}} is already running. Opening it again launches a second editor instance. Open anyway?';
	@override String get project_open_anyway => 'افتح على أي حال';
	@override String get git_sidebar => 'Git sidebar';
	@override String get asset_duplicate_title => 'هذا القالب مثبت بالفعل';
	@override String get asset_duplicate_desc => '"{{name}}" is already in your templates. Install a duplicate anyway?';
	@override String get empty_category => 'تصنيف فارغ';
	@override String get release_to_drop => 'أفلت للإسقاط';
	@override String get preview_release_notes => '## What\'s new in v1.0.0 - The Preview Update\\n\\n## New\\n\\n- Revamped the Check for Updates modal with structured release notes\\n- Added screen reader announcements with an Accessibility settings tab\\n\\n## Fixes\\n\\n- Fixed a crash when switching workspaces with pinned projects\\n- Fixed update checks failing silently when GitHub rate limits are hit\\n\\n## Improvements\\n\\n- Faster startup times across all platforms\\n- Reworked workspace modals with compact style pickers\\n\\n## Known Issues\\n\\n- Linux OS: AppImage won\'t work on some distros, use the .rpm or .deb package instead\\n- Windows: the taskbar may briefly show a duplicate icon until the app restarts';
	@override String get preview_error => 'Preview error: GitHub API rate limit reached (HTTP 403). Add a token in Settings to keep checking.';
	@override String get bug_report_system => 'النظام';
	@override String get bug_report_version => 'الإصدار';
	@override String get bug_report_date => 'التاريخ';
	@override String get bug_report_os => 'نظام التشغيل';
	@override String get bug_report_platform => 'المنصة';
	@override String get bug_report_language => 'اللغة';
	@override String get bug_report_cpu_cores => 'أنوية المعالج';
	@override String get bug_report_ram => 'ذاكرة الوصول العشوائي (RAM)';
	@override String get bug_report_screen => 'الشاشة';
	@override String get bug_report_gpu => 'المعالج الرسومي (GPU)';
	@override String get bug_report_user_agent => 'وكيل المستخدم';
	@override String get bug_report_recent_errors => 'الأخطاء الأخيرة';
	@override String get bug_report_none_captured => 'غير مُلتقطة';
	@override String get bug_report_description => 'الوصف';
	@override String get bug_report_no_description => 'لا يوجد وصف مرفق';
	@override String get unknown => 'غير معروف';
	@override String get gpu_webgl_unavailable => 'WebGL غير متوفر';
	@override String get gpu_info_unavailable => 'معلومات البطاقة الرسومية غير متوفرة';
	@override String get update_available => 'تحديث جديد';
	@override String get dismiss => 'تجاهل';
	@override String get system_language => 'لغة النظام';
	@override String get category_empty_hint => 'أنشئ واحدا في الأعلى لترتيب مشاريعك';
	@override String get contributor_pr_merged => 'مُدمج';
	@override String get contributor_pr_open => 'مفتوح';
	@override String get contributor_pr_closed => 'مُغلق';
	@override String get contributor_pr_loading => 'جاري تحميل طلبات السحب (PRs)...';
	@override String contributor_pr_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} pull requests',
		one: '${count} طلب سحب',
		two: '${count} pull requests',
		few: '${count} pull requests',
		many: '${count} pull requests',
		other: '${count} طلبات سحب',
	);
	@override String get contributor_pr_load_failed => 'فشل تحميل طلبات السحب.';
	@override String get contributor_pr_network_hint => 'تحقق من إتصالك.';
	@override String get contributor_pr_empty => 'لا يوجد أي طلبات سحب.';
	@override String get theme_presets_section => 'Theme presets';
	@override String get all_categories => 'كل التصنيفات';
	@override String get clear_category_filter => 'امسح تصنيفات الترشيح';
	@override String get filter_by_category => 'مرشح بالتصنيفات';
	@override String get theme_dark => 'مظلم';
	@override String get theme_light => 'مضيء';
	@override String get bulk_tags => 'الوسوم';
	@override String get bulk_tags_title => 'عدل الوسوم';
	@override String get add_tag => 'أضف وسما';
	@override String get remove_tag => 'أزل وسما';
	@override String get no_common_tags => 'لا توجد وسوم على المشاريع المختارة بعد.';
	@override String get tags_added_to_selection => 'تمت إضافة {{count}} وسم من المشاريع.';
	@override String get tags_removed_from_selection => 'تمت إزالة {{count}} وسم من المشاريع.';
	@override String get removed_from_library => 'تمت إزالة {{count}} مشروعا من المكتبة.';
	@override String get undo => 'تراجع';
	@override String get duplicate_project_title => 'انسخ المشروع';
	@override String get copy_suffix => 'نسخة';
	@override String get duplicate => 'انسخ';
	@override String get destination_folder => 'مسار المجلد';
	@override String get new_project_name => 'إسم المشروع';
	@override String get project_duplicated => 'تم نسخ المشروع.';
	@override String get notification_version_installed => 'Godot {{tag}} مثبت';
	@override String get notification_asset_installed => '{{title}} مثبت';
	@override String get notification_clone_done => 'تم استنساخ و استوراد المستودع';
	@override String get console_title => 'الطرفية';
	@override String get console_finished => 'Finished';
	@override String get console_exit_ok => 'Exited cleanly';
	@override String get console_exit_code => 'Exit code {{code}}';
	@override String get console_clear => 'Clear output';
	@override String get console_copy => 'Copy output';
	@override String get console_minimize => 'Minimize to a pill';
	@override String get console_waiting => 'Waiting for output…';
	@override String get console_empty => 'No output was captured.';
	@override String get console_trimmed => '{{count}} older line(s) are hidden, copy or clear to manage the buffer.';
	@override String get console_crash_hint => 'Godot exited with code {{code}}. The output above is kept so you can read it.';
	@override String get console_filter_errors => 'Errors';
	@override String get console_filter_warnings => 'Warnings';
	@override String get console_filter_info => 'Info';
	@override String get console_no_matches => 'No lines match the filters ({{count}} hidden).';
	@override String get console_pill_hint => 'Click to reopen the console, drag to move it.';
	@override String get console_resumed_hint => 'This project kept running after GodotHub closed, its output is still being captured below.';
	@override String get console_previous_hint => 'Output kept from the previous session.';
	@override String get project_card_version_unavailable => 'Godot {{version}} is not installed. Select an installed version to launch this project.';
	@override String get project_card_total_time => 'Total time: {{time}}';
	@override String get project_card_last_opened => 'Last opened: {{date}}';
	@override String get project_card_more_tags => 'Show {{count}} more tags';
	@override String get downloading_export_templates => 'Downloading export templates for {{tag}}';
	@override String get export_templates_verifying => 'Verifying download…';
	@override String get export_templates_extracting => 'Installing templates…';
	@override late final _Translations$common$project_doctor$ar_MA project_doctor = _Translations$common$project_doctor$ar_MA._(_root);
	@override late final _Translations$common$build_export$ar_MA build_export = _Translations$common$build_export$ar_MA._(_root);
	@override String get projects_corrupt_title => 'Project list couldn\'t be read';
	@override String get projects_corrupt_desc => 'Your projects.json file is corrupt, so your projects can\'t be shown. You can restore the most recent automatic backup, or dismiss this and leave the file untouched.';
	@override String get projects_corrupt_restore => 'Restore backup';
	@override String get projects_corrupt_dismiss => 'Not now';
	@override String get projects_load_error => 'Couldn\'t load your projects. Something went wrong reading them from disk. Try again, and if it keeps failing your project list file may be damaged.';
	@override String get cleanup_title => 'Storage';
	@override String get cleanup_subtitle => 'See what GodotHub keeps on disk and free up space you no longer need.';
	@override String get cleanup_total_label => 'on disk';
	@override String get cleanup_scanning => 'Measuring folders…';
	@override String get cleanup_load_error => 'Couldn\'t measure storage: {{error}}';
	@override String get cleanup_reclaimable_title => 'Reclaimable';
	@override String get cleanup_reclaimable_desc => 'Versions no project, template or alias uses, unfinished downloads, and export templates no installed version needs. Pick what to remove.';
	@override String get cleanup_nothing_to_reclaim => 'Nothing to clean up right now.';
	@override String get cleanup_group_unused_versions => 'Unused versions';
	@override String get cleanup_group_partials => 'Unfinished downloads';
	@override String get cleanup_group_orphan_exports => 'Orphaned export templates';
	@override String get cleanup_orphan_exports_hint => 'No installed version uses these, but a Godot install outside GodotHub might, so they aren\'t selected by default.';
	@override String get cleanup_external_hint => 'Installed outside GodotHub\'s download folder';
	@override String get cleanup_kind_version_download => 'Godot version download';
	@override String get cleanup_kind_export_templates_download => 'Export templates download';
	@override String get cleanup_reclaim_btn => 'Reclaim {{size}}';
	@override String get cleanup_confirm_title => 'Reclaim {{size}}?';
	@override String get cleanup_confirm_desc => 'These items will be removed:';
	@override String get cleanup_confirm_trash_note => 'Versions and export templates are moved to the system trash, so the space is freed once you empty it. Unfinished downloads are deleted permanently.';
	@override String cleanup_confirm_btn({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Remove ${count} items',
		one: 'Remove ${count} item',
		two: 'Remove ${count} items',
		few: 'Remove ${count} items',
		many: 'Remove ${count} items',
		other: 'Remove ${count} items',
	);
	@override String get cleanup_done => 'Freed {{size}}';
	@override String get cleanup_failed => 'Couldn\'t remove {{label}}: {{error}}';
	@override String get cleanup_versions_desc => 'Full size on disk of every installed Godot version.';
	@override String get cleanup_templates_title => 'Project templates';
	@override String get cleanup_export_templates_title => 'Export templates';
	@override String cleanup_used_by_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} templates',
		one: '${count} template',
		two: '${count} templates',
		few: '${count} templates',
		many: '${count} templates',
		other: '${count} templates',
	);
	@override String get cleanup_current_badge => 'Current';
	@override String get cleanup_alias_badge => 'Alias';
	@override String get cleanup_unused_badge => 'Unused';
	@override String get cleanup_mise_badge => 'Managed by mise';
	@override String get cleanup_external_badge => 'External';
	@override String get cleanup_orphan_badge => 'Orphaned';
	@override String get cleanup_empty => 'Nothing here yet.';
	@override String get new_badge => 'New';
	@override String get reset => 'أعد الضبط';
	@override String get git_disconnect => 'ألغي الإتصال';
	@override String get git_sign_in_github => 'سجل الدخول مع GitHub';
	@override String get git_connected_as => 'متصل كـ @{{username}}';
	@override String get optional => '(إختياري)';
	@override String get language_label => 'اللغة';
	@override String n_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} projects',
		one: '${count} امشروع',
		two: '${count} projects',
		few: '${count} projects',
		many: '${count} projects',
		other: '${count} مشاريع',
	);
	@override String vault_item_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Items',
		one: 'Item',
		two: 'Items',
		few: 'Items',
		many: 'Items',
		other: 'Items',
	);
	@override String get vault_search_placeholder => 'Search vault…';
	@override String get vault_empty => 'Your vault is empty. Click <1>Save to Vault</1> to pick files or folders from a project and reuse them anywhere.';
	@override String get vault_no_match => 'No items match your search.';
	@override String get vault_save_btn => 'Save to Vault';
	@override String get vault_save_title => 'Save to Vault';
	@override String get vault_source_project_label => 'Source Project';
	@override String get vault_source_n => 'Source {{index}}';
	@override String get vault_add_source => 'Add another project';
	@override String get vault_remove_source => 'Remove source';
	@override String get vault_select_project => 'Select a project…';
	@override String get vault_select_files_label => 'Files & Folders';
	@override String get vault_selected_count => '{{count}} selected';
	@override String get vault_project_empty => 'This project has no files.';
	@override String get vault_item_name_label => 'Name';
	@override String get vault_item_name_placeholder => 'Item name';
	@override String get vault_item_desc_label => 'Description';
	@override String get vault_item_desc_placeholder => 'What\'s in this item?';
	@override String get vault_item_tags_label => 'Tags';
	@override String get vault_tag_input_placeholder => 'Add a tag…';
	@override String get vault_saved_toast => 'Saved to Vault';
	@override String get vault_edit_action => 'Edit item';
	@override String get vault_edit_title => 'Edit Item';
	@override String get vault_item_updated_toast => 'Item updated';
	@override String get vault_delete_action => 'Delete {{name}}';
	@override String get vault_delete_title => 'Delete Item?';
	@override String get vault_delete_desc => '"{{name}}" will be permanently removed from your vault.';
	@override String get vault_add_btn => 'Add to Project';
	@override String get vault_add_title => 'Add from Vault';
	@override String get vault_target_project_label => 'Target Project';
	@override String get vault_target_projects_label => 'Target Projects';
	@override String get vault_adding => 'Adding…';
	@override String get vault_overwrite_btn => 'Overwrite files';
	@override String vault_conflict_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} files already exist in the project. Overwrite them?',
		one: '${count} file already exists in the project. Overwrite it?',
		two: '${count} files already exist in the project. Overwrite them?',
		few: '${count} files already exist in the project. Overwrite them?',
		many: '${count} files already exist in the project. Overwrite them?',
		other: '${count} files already exist in the project. Overwrite them?',
	);
	@override String vault_conflict_summary_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} files already exist across the selected projects. Overwrite them?',
		one: '${count} file already exists across the selected projects. Overwrite it?',
		two: '${count} files already exist across the selected projects. Overwrite them?',
		few: '${count} files already exist across the selected projects. Overwrite them?',
		many: '${count} files already exist across the selected projects. Overwrite them?',
		other: '${count} files already exist across the selected projects. Overwrite them?',
	);
	@override String vault_added_toast({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Added ${count} files',
		one: 'Added ${count} file',
		two: 'Added ${count} files',
		few: 'Added ${count} files',
		many: 'Added ${count} files',
		other: 'Added ${count} files',
	);
	@override String vault_added_to_projects_toast({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Added to ${count} projects',
		one: 'Added to ${count} project',
		two: 'Added to ${count} projects',
		few: 'Added to ${count} projects',
		many: 'Added to ${count} projects',
		other: 'Added to ${count} projects',
	);
	@override String get vault_item_empty => 'This item has no files.';
	@override String get kNew => 'جديد';
	@override String get announcement_support_title => 'Support GodotHub';
	@override String get announcement_support_body => 'GodotHub is free and made in my spare time. If it helps your workflow, please consider supporting development with a donation.';
	@override String get workspace_name_taken_error => 'Another workspace already uses this name.';
	@override String get workspace_start_label => 'Start with';
	@override String get workspace_start_copy => 'Copy settings from {{name}}';
	@override String get workspace_start_copy_desc => 'Theme, language, features, and version folders carry over. Project folders start empty, and you go straight in.';
	@override String get workspace_start_fresh => 'Start fresh';
	@override String get workspace_start_fresh_desc => 'Walk through setup for this workspace from scratch.';
	@override String get workspace_switched_to => 'Switched to';
	@override late final _Translations$common$project_addons$ar_MA project_addons = _Translations$common$project_addons$ar_MA._(_root);
	@override String get reload_confirm_title => 'Reload GodotHub?';
	@override String get reload_confirm_desc => 'Any unsaved changes in open forms will be lost.';
	@override String get color_presets => 'Presets';
	@override String get date_previous_month => 'Previous month';
	@override String get date_next_month => 'Next month';
	@override String get date_change_due => 'Change due date: {{date}}';
	@override String get date_add_due => 'Add due date';
}

// Path: dashboard
class _Translations$dashboard$ar_MA extends Translations$dashboard$en_US {
	_Translations$dashboard$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get greeting_morning => 'صباح الخير';
	@override String get greeting_afternoon => 'مساء الخير';
	@override String get greeting_evening => 'طاب مساؤك';
	@override String get greeting_night => 'ليلة سعيدة';
	@override String get greeting_name => 'إسم التحية';
	@override String get dashboard_rename_hint => 'عيين إسما مخصصا';
	@override String get dashboard_rename_aria => 'أعد تسمية إسم الترحيب';
	@override String get dashboard_rename_save => 'احفظ الإسم';
	@override String get dashboard_rename_reset => 'استخدم الإسم من النظام';
	@override String get dashboard_name_placeholder => 'إسمك';
	@override String get dashboard_clock_aria => 'الوقت الحالي';
	@override String get dashboard_new_project => 'مشروع جديد';
	@override String get dashboard_import_project => 'استورد مشروعا';
	@override String get dashboard_scan_projects => 'ابحث عن المشاريع';
	@override String get dashboard_stat_projects => 'المشاريع';
	@override String get dashboard_stat_templates => 'القوالب';
	@override String get dashboard_stat_engines => 'المحركات';
	@override String get dashboard_stat_total_time => 'الوقت الكلي';
	@override String get dashboard_stat_total_time_hint => 'الوقت مستغرق في المشاريع';
	@override String get dashboard_recent => 'مفتوح مؤخرا';
	@override String get dashboard_recent_empty => 'لم يفتح أي مشروع بعد. افتح مشروعا لتراه هنا.';
	@override String get dashboard_pinned => 'مُثبت';
	@override String get dashboard_pinned_empty => 'لا توجد مشاريع مثبت بعد. ثبت مشروعا لإبقائه قريبا.';
	@override String get dashboard_engines => 'المحركات المثبتة';
	@override String get dashboard_engines_empty => 'لم يتم تثبيت أي محرك بعد.';
	@override String get dashboard_running => 'مُشغّل حاليا';
	@override String get dashboard_running_empty => 'لا يوجد اي مشروع شغال حاليا.';
	@override String get dashboard_opened_at => 'فُتح {{time}}';
	@override String get dashboard_daily => 'الأنشطة اليومية';
	@override String get dashboard_daily_empty => 'لا توجد أي أنشطة يومية حاليا.';
	@override String get dashboard_weekly => 'الأنشطة الأسبوعية';
	@override String get dashboard_weekly_empty => 'لا توجد أنشطة أسبوعية حاليا.';
	@override String get dashboard_monthly => 'الأنشطة الشهرية';
	@override String get dashboard_monthly_empty => 'لا توجد أنشطة شهرية حاليا.';
	@override String get dashboard_yearly => 'الأنشطة السنوية';
	@override String get dashboard_yearly_empty => 'لا توجد أنشطة سنوية حاليا.';
	@override String get dashboard_activity_cycle => 'بدل لـ {{next}}';
	@override String get dashboard_weekly_aria => '{{label}} من الوقت المتتبع';
	@override String get dashboard_top_time => 'المشاريع الأعلى استغراقا';
	@override String get dashboard_top_time_empty => 'لا يوجد وقت متتبع بعد. افتح مشروعا لبدأ التتبع.';
	@override String get dashboard_insights => 'رؤى';
	@override String get dashboard_insights_empty => 'لا يوجد وقت متتبع بعد. افتح مشروعا لبدء بناء سلسلة إنجازاتك.';
	@override String get dashboard_insights_longest_streak => 'التتبع الأعلى';
	@override String get dashboard_insights_current_streak => 'التتبع الحالي';
	@override String get dashboard_insights_days => '{{count}} يوما';
	@override String get dashboard_insights_productive_day => 'اليوم الأكثر إنتاجية';
	@override String get dashboard_insights_this_month => 'هذا الشهر';
	@override String get dashboard_insights_delta_up => '{{pct}}% أكثر من الشهر الماضي';
	@override String get dashboard_insights_delta_down => '{{pct}}% أقل من الشهر الماضي';
	@override String get dashboard_git => 'Git رؤية عامة';
	@override String get dashboard_git_empty => 'لا يتم كشف أي مستودعات Git.';
	@override String get dashboard_git_clean => 'تم مسح الكل';
	@override String get dashboard_git_dirty => '{{count}} بدون تغيرات منفذة';
	@override String dashboard_git_dirty_plural({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} بدون تغيرات منفذة',
		one: '1 بدون تغيرات منفذة',
		two: '${count} بدون تغيرات منفذة',
		few: '${count} بدون تغيرات منفذة',
		many: '${count} بدون تغيرات منفذة',
		other: '${count} بدون تغيرات منفذة',
	);
	@override String get dashboard_git_branch => 'على {{branch}}';
	@override String get dashboard_storage => 'المساحة المستخدمة';
	@override String get dashboard_storage_empty => 'لا يوجد مشروع حاليا للقياس.';
	@override String get dashboard_storage_loading => 'جاري القياس…';
	@override String get dashboard_storage_total => '{{size}} الكل';
	@override String get dashboard_customize => 'التخصيص';
	@override String get dashboard_done_customizing => 'تم';
	@override String get dashboard_customize_hint => 'استخدم الأسهم لإعادة ترتيب الخانات, أو أخفي الذين لا تحتاجهم.';
	@override String get dashboard_tile_move_up => 'انقل للأعلى';
	@override String get dashboard_tile_move_down => 'انقل للأسفل';
	@override String get dashboard_tile_remove => 'أزل';
	@override String get dashboard_tile_span => 'العرض كاملا';
	@override String get dashboard_tile_span_off => 'نصف العرض';
	@override String get dashboard_tile_tall => 'الأطول';
	@override String get dashboard_tile_tall_off => 'ارتفاع طبيعي';
	@override String get dashboard_presets => 'إعدادات التخطيط المسبقة';
	@override String get dashboard_preset_default => 'الإفتراضية';
	@override String get dashboard_preset_default_desc => 'Everything on, in the default order, standard sizing.';
	@override String get dashboard_preset_overview => 'رؤية عامة';
	@override String get dashboard_preset_overview_desc => 'المشاريع المفتوحة مؤخرا, المشاريع المثتبة, المحركات, و المشاريع الشغالة حاليا.';
	@override String get dashboard_preset_analytics => 'الإحصائات';
	@override String get dashboard_preset_analytics_desc => 'الأنشطة الأسبوعية, المشاريع الأعلى, المساحة التخزينية, و التصنيفات, مع رسوم بيانية أطول.';
	@override String get dashboard_preset_development => 'التطوير';
	@override String get dashboard_preset_development_desc => 'Git status front and center with running projects and engines.';
	@override String get dashboard_preset_save => 'احفظ الإعداد المسبق الحالي';
	@override String get dashboard_preset_save_hint => 'سمّي هذا التخطيط بحيث يمكنك العودة إليه متى شئت.';
	@override String get dashboard_preset_name_placeholder => 'إسم الإعداد المسبق';
	@override String get dashboard_preset_delete => 'احذف الإعدادات المسبقة';
	@override String get dashboard_custom_presets => 'إعداداتك المسبقة';
	@override String get dashboard_hidden_tiles => 'أخفي الخانات';
	@override String get dashboard_todos => 'Due to-dos';
	@override String get dashboard_range_daily => 'يوم';
	@override String get dashboard_range_weekly => 'أسبوع';
	@override String get dashboard_range_monthly => 'شهر';
	@override String get dashboard_range_yearly => 'سنة';
	@override String get dashboard_activity_tracked => 'المُسجّل';
	@override String get dashboard_activity_peak => 'الذروة';
}

// Path: git
class _Translations$git$ar_MA extends Translations$git$en_US {
	_Translations$git$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get remove => 'أزل';
	@override String get changes_title => 'التغييرات';
	@override String get pull => 'اسحب';
	@override String get push => 'ادفع';
	@override String get force_push => 'أرغم';
	@override String get fetch => 'اجلب';
	@override String get change => 'غيير';
	@override String get commit => 'نفذ';
	@override String get committing => 'جاري التنفيذ…';
	@override String get no_remotes => 'No remotes configured';
	@override String get switching => 'جاري التبديل…';
	@override String get no_branches => 'لا توجد أي فروع';
	@override String get new_branch_placeholder => 'إسم الفرع';
	@override String get delete_branch => 'احذف الفرع';
	@override String get publish_branch => 'انشر الفرع';
	@override String get publish_branch_to => 'Publish branch to {{remote}}';
	@override String get branch_published => 'تم نشر الفرع.';
	@override String get use_ours => 'استخدم خاصتنا';
	@override String get use_theirs => 'استخدم خاصتهم';
	@override String get i_resolved => 'حللتها';
	@override String get undo_last_commit => 'تراجع عن أخر تنفيذ';
	@override String get undo_pull => 'تراجع عن السحب';
	@override String get force_push_confirm_title => 'هل تريد إرغام الدفع?';
	@override String get force_push_confirm_desc => 'This rewrites remote history and can lose other people\'s commits. Continue?';
	@override String get undo_commit_done => 'التنفيذ الأخير لم يتم.';
	@override String get undo_pull_done => 'عملية السحب لم تتم.';
	@override String get force_pushed => 'تم إرغام الدفع.';
	@override String get synced_ok => 'تمت المزامنة.';
	@override String get fetched_ok => 'تم جلب البيانات.';
	@override String get pulled_ok => 'تم السحب.';
	@override String get pushed_ok => 'تم الدفع.';
	@override String get branch_created => 'تم إنشاء الفرع.';
	@override String get branch_deleted => 'تم حذف الفرع.';
	@override String get changes_stashed_ok => 'تم إخفاء التغييرات.';
	@override String get stash_applied_ok => 'تم تطبيق الإخفاءات.';
	@override String get stash_popped_ok => 'Stash popped.';
	@override String get stash_dropped_ok => 'Stash dropped.';
	@override String get staged_ok => 'تم التجهيز.';
	@override String get unstaged_ok => 'تم إلغاء التجهيز.';
	@override String get discarded_ok => 'تم التخلص.';
	@override String get stage_all_ok => 'تم تجهيز كل التغييرات.';
	@override String get unstage_all_ok => 'تم إلغاء تجهيز كل التغييرات.';
	@override String get discard_all_ok => 'تم التخلص من كل التغييرات.';
	@override String get resolved_ours => 'Resolved using ours.';
	@override String get resolved_theirs => 'Resolved using theirs.';
	@override String get resolved_manual => 'موسومة كمحلولة.';
	@override String get committed_ok => 'منفذة.';
	@override String get switched_ok => 'بدل لـ {{branch}}.';
	@override String get sync => 'زامن';
	@override String get diff_no_diff => 'No diff available for this file.';
	@override String get fetching => 'جاري جلب البيانات…';
	@override String get stashes_title => 'المخفيات';
	@override String get stash => 'أخفي';
	@override String get stashing => 'جاري الإخفاء…';
	@override String get apply_stash => 'طبق الإخفاء';
	@override String get pop_stash => 'Pop stash';
	@override String get drop_stash => 'Drop stash';
	@override String get merge_aborted => 'ألغي الدمج. تم استعادت مجلد العمل.';
	@override String get new_branch_btn => '+ جديد';
	@override String get abort_merge => 'ألغي الدمج';
	@override String get merge_in_progress => 'الدمج في حالة تقدم';
	@override String get working_tree_clean => 'شجرة العمل نقية.';
	@override String get staged_changes => 'التغييرات المجهزة';
	@override String get unstage_all_changes => 'ألغي تجهيز كل التغييرات';
	@override String get commits_title => 'التنفيذات';
	@override String get stage_file => 'جهز الملف';
	@override String get discard_file => 'تخلص من الملف';
	@override String get unstage_file => 'ألغي تجهيز الملف';
	@override String get no_commits_found => 'لا توجد أي تنفيذات.';
	@override String get stage_all => 'جهز الكل';
	@override String get discard_all => 'تجاهل الكل';
	@override String get auth_connected_accounts => 'الحسابات المتصلة';
	@override String get auth_connect_hint => 'اربط بإستضافة Git التي تفضلها للبدأ، أو استعمل SSH بدون الإتصال بأي إستضافة.';
	@override String get worktrees_title => 'أشجار العمل';
	@override String get worktree_current => 'الحالي';
	@override String get no_worktrees => 'لا توجد أشجال عمل إضافية';
	@override String get switch_worktree => 'بدل لشجرة العمل هذه';
	@override String get switched_worktree_ok => 'تم تبديل شجرة العمل.';
	@override String get add_worktree => 'شجرة عمل جديدة';
	@override String get add_worktree_btn => 'أضف شجرة عمل';
	@override String get worktree_path_placeholder => 'مسار (e.g. ../my-feature)';
	@override String get worktree_branch_placeholder => 'إسم الفرع (إختياري)';
	@override String get worktree_created_ok => 'تم إنشاء شجرة العمل.';
	@override String get worktree_dirty => 'التغييرات الملغى تنفيذها';
	@override String get remove_worktree => 'أزلة شجرة العمل';
	@override String get remove_worktree_confirm_desc => 'إزالة شجرة العمل في {{path}}؟ سيُحذف مجلدها مع الاحتفاظ بالفرع والالتزامات.';
	@override String get worktree_removed_ok => 'تمت إزالة شجرة العمل.';
	@override String get auto_fetch_label => 'Fetch automatically';
	@override String get auto_fetch_hint => 'Runs git fetch every few minutes so the pull bubble always shows how many commits you\'re behind, without merging anything. Leave it off to only fetch when you click Fetch.';
	@override String get commits_to_push => '{{count}} commit(s) to push';
	@override String get commits_to_pull => '{{count}} commit(s) to pull';
	@override String get filter_changes => 'رشح الملفات المتغييرة…';
	@override String get no_matching_changes => 'لا توجد تغييرات متطابقة.';
	@override String get worktree_location_label => 'Directory';
	@override String get worktree_location_hint => 'Use a new directory. Relative paths are resolved from the current repository.';
	@override String get worktree_branch_label => 'New branch (optional)';
	@override String get worktree_branch_hint => 'Leave blank to use the directory name as the new branch name.';
	@override String get worktree_browse_parent => 'Choose parent directory';
	@override String get worktree_removing => 'Removing…';
	@override String get worktree_main => 'Main';
	@override String get worktree_detached => 'Detached HEAD · {{hash}}';
	@override String get worktrees_load_error => 'Could not load worktrees.';
	@override String get switch_worktree_named => 'Switch to {{name}}';
	@override String get worktree_discard_changes => 'Discard uncommitted changes';
	@override String get worktree_discard_warning => 'This worktree has uncommitted changes. Removing it with this option will permanently discard them.';
	@override String get discard_dialog_title => 'Discard changes?';
	@override String get discard_dialog_tracked_desc => 'This reverts all tracked files to the last commit.';
	@override String get discard_dialog_untracked_heading => 'These untracked files would be permanently deleted ({{n}}):';
	@override String get discard_dialog_no_untracked => 'No untracked files will be affected.';
	@override String get discard_opt_tracked => 'Discard tracked changes';
	@override String get discard_opt_tracked_hint => 'Reverts tracked files. Leaves untracked files untouched.';
	@override String get discard_opt_untracked => 'Also remove untracked files';
	@override String get discard_opt_untracked_hint => 'Permanently deletes the files listed above. This cannot be undone.';
	@override String get discard_opt_stash => 'Stash everything instead';
	@override String get discard_opt_stash_hint => 'Saves tracked and untracked changes to a stash you can restore later.';
	@override String get protected_branch_tooltip => '{{branch}} is protected on the remote';
	@override String get protected_branch_title => 'Protected branch';
	@override String get protected_branch_desc => '{{branch}} is protected on the remote, so pushing commits to it directly may be rejected. Commit anyway, or move these changes to a new branch and open a pull request.';
	@override String get protected_branch_new_label => 'New branch name';
	@override String get protected_branch_commit_anyway => 'Commit anyway';
	@override String get protected_branch_create_pr => 'Create branch & open PR';
	@override String get protected_branch_creating_pr => 'Opening pull request…';
	@override String get pr_opened_ok => 'Pushed {{branch}} and opened a pull request.';
}

// Path: nav
class _Translations$nav$ar_MA extends Translations$nav$en_US {
	_Translations$nav$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get dashboard => 'لوحة التحكم';
	@override String get projects => 'المشاريع';
	@override String projects_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'مشروعا(مشاريع)',
		one: 'مشروع',
		two: 'مشروعا(مشاريع)',
		few: 'مشروعا(مشاريع)',
		many: 'مشروعا(مشاريع)',
		other: 'مشاريع',
	);
	@override String get versions => 'الإصدارات';
	@override String get templates => 'القوالب';
	@override String get vault => 'Vault';
	@override String get asset_store => 'متجر الأصول';
	@override String get news => 'الأخبار';
	@override String get storage_view => 'Storage';
	@override String get settings => 'الإعدادات';
	@override String get changelog => 'سجل التغييرات';
	@override String get group_workspace => 'مساحة العمل';
	@override String get group_resources => 'الموارد';
	@override String get group_explore => 'استكشاف';
	@override String get you => 'You';
	@override String get account_manage => 'Manage accounts';
	@override String get workspace_tip_title => 'انتقل مُبدّل مساحات العمل';
	@override String get workspace_tip_body => 'بدّل مساحات العمل وأدِرها من قائمة الحساب بالأسفل.';
	@override String get workspace_tip_dismiss => 'فهمت';
}

// Path: onboarding
class _Translations$onboarding$ar_MA extends Translations$onboarding$en_US {
	_Translations$onboarding$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'أهلا و سهلا';
	@override String get finish => 'تم';
	@override String get in_progress => 'قيد التقدم';
	@override String get prototypes => 'نسخة تجريبية';
	@override String get finished => 'تم';
	@override String get game_jams => 'جيم جام';
	@override String get project_folders => 'مجلدات المشاريع';
	@override String get version_folders => 'مجلدات الإصدارات';
	@override String get welcome_title => 'أهلا في GodotHub';
	@override String get welcome_desc => 'مأوى لكل مشروع و كل إصدارة جودوت. دعنا نخصص بعض الأمور أولا لكي تعمل بالطريقة التي تناسبك, سيأخذ الأمر دقيقة, كل شيء هنا يمكن تغييره من الإعدادات.';
	@override String get onboard_empty_projects => 'لم تضف أي مجلدات, جودوت هاب لا يمكنه تحديد أي مشروع إلى أن تضيف مجلد مشاريعك, أو يمكنك إستوراد المشاريع يدويا لاحقا.';
	@override String get onboard_empty_versions => 'لم تضف أي مجلدات, إصدارات جودوت المختلفة ستذهب لمجلد بيانات جودوت هاب إلا إذا عيينة واحد أخر بنفسك.';
	@override String get onboard_no_template_folder => 'لم يعين أي مجلد, يمكنك دائما تخصيص هذا في الإعدادات, أو احفظ القوالب يدويا.';
	@override String get onboard_cloud_heading => 'النسخة الإحتياطية السحابية';
	@override String get onboard_cloud_desc => 'هل لديك نسخة احتياطية بالفعل؟ سجل الدخول مع GitHub و استرجع بيئات عملك، مشاريعك، و إعداداتك باختصار.';
	@override String get discovery_recent_heading => 'Recent projects from Godot';
	@override String get discovery_installs_heading => 'Godot found on this computer';
	@override String get discovery_scanning_projects => 'Reading Godot\'s project manager list…';
	@override String get discovery_scanning_installs => 'Looking for Godot on your PATH and in Steam…';
	@override String get discovery_engine => 'Godot {{version}}';
	@override String get discovery_favorite => 'Favorite';
	@override String get discovery_add_selected => 'Add selected';
	@override String get discovery_add_selected_count => 'Add selected ({{count}})';
	@override String discovery_added_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Added ${count} projects.',
		one: 'Added ${count} project.',
		two: 'Added ${count} projects.',
		few: 'Added ${count} projects.',
		many: 'Added ${count} projects.',
		other: 'Added ${count} projects.',
	);
	@override String discovery_added_versions({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Added ${count} versions.',
		one: 'Added ${count} version.',
		two: 'Added ${count} versions.',
		few: 'Added ${count} versions.',
		many: 'Added ${count} versions.',
		other: 'Added ${count} versions.',
	);
	@override String get discovery_link_hint => 'Projects are linked to a matching Godot version automatically, including versions you add in the next step.';
	@override String get setup => 'Setup';
	@override String get setup_title => 'How do you want to use GodotHub?';
	@override String get setup_desc => 'Pick a starting point. Anything you leave out is hidden and never loads, so GodotHub stays quick. You can change this anytime in Settings, under Behavior.';
	@override String get preview_heading => 'Preview';
	@override String get step_of => 'Step {{current}} of {{total}}';
	@override String get dive_in => 'Dive In';
	@override String get workspace_step => 'Workspace';
	@override String get first_workspace_title => 'Create your first workspace';
	@override String get first_workspace_desc => 'A workspace holds your projects, categories, and settings. Give this one a name and a look that feels like yours, you can add more later.';
	@override String get basics => 'Basics';
	@override String get basics_title => 'A few basics';
	@override String get basics_desc => 'Pick your language, bring back a cloud backup if you have one, and choose whether Discord shows what you\'re working on.';
	@override String get welcome_to => 'Welcome to';
	@override String get welcome_to_name => 'Hey {{name}}, welcome to';
	@override String get found_title => 'Your library is ready';
	@override String get found_desc => 'Here\'s everything GodotHub found on this machine. Taking you in now.';
}

// Path: settings
class _Translations$settings$ar_MA extends Translations$settings$en_US {
	_Translations$settings$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get storage => 'التخزين';
	@override String get behavior => 'الوظائف';
	@override String get display => 'الشاشة';
	@override String get appearance => 'المظهر';
	@override String get accessibility => 'إمكانية الوصول';
	@override String get accessibility_desc => 'Screen reader announcements and assistive technology options.';
	@override String get app_version_label => 'GodotHub v{{version}}';
	@override String get landing_dashboard => 'لوحة التحكم';
	@override String get landing_projects => 'المشاريع';
	@override String get landing_versions => 'الإصدارات';
	@override String get landing_news => 'أخبار Godot';
	@override String get screen_reader_label => 'إشعارات قارئ الشاشة';
	@override String get advanced => 'متقدمة';
	@override String get integrations => 'التطبيقات المتصلة';
	@override String get motion => 'Motion';
	@override String get data => 'Data & Backup';
	@override String get git_auth_title => 'سجل الدخول مع {{provider}}';
	@override String get git_auth_copy_code => 'انسخ الرمز';
	@override String get git_auth_copy_link => 'Copy link';
	@override String get git_auth_waiting => 'Waiting for you to authorize…';
	@override String get git_sign_in_gitlab => 'سجل الدخول مع GitLab';
	@override String get git_connected_to => 'متصل كـ {{host}} as @{{username}}';
	@override String get git_self_hosted_title => 'استضافة ذاتية GitLab';
	@override String get git_self_hosted_desc => 'Connect to your own GitLab instance. Create an OAuth application on your instance (scopes: read_repository, write_repository, read_user) and paste its base URL and Application ID.';
	@override String get git_self_hosted_url_placeholder => 'https://gitlab.example.com';
	@override String get git_self_hosted_client_id => 'رمز تعريف التطبيق (ID)';
	@override String get git_sign_in_self_hosted => 'سجل الدخول مع instance';
	@override String get git_pat_title => 'اسضافات أخرى (رموز وصول شخصية)';
	@override String get git_pat_add => 'أضف رمزا (Token)';
	@override String get git_pat_host_placeholder => 'e.g. codeberg.org';
	@override String get git_pat_username => 'إسم المستخدم';
	@override String get git_pat_token => 'الرمز (Token)';
	@override String get git_pat_save => 'احفظ الرمز';
	@override String get git_pat_empty => 'لم يتم إضافة أي رمز بعد.';
	@override String get git_pat_remove => 'أزل الرمز (Token)';
	@override String get storage_title => 'التخزين و البحث التلقائي';
	@override String get behavior_projects_title => 'المشاريع';
	@override String get file_watchers_title => 'مراقب التغييرات';
	@override String get last_opened_title => 'اعرض أخر مشروع فُتح';
	@override String get github_token_title => 'رمز GitHub API';
	@override String get titlebar_buttons => 'أزرار شريط العنوان';
	@override String get setup_wizard => 'قائمة الإعداد';
	@override String get setup_wizard_again => 'أظهر قائمة الإعداد مجددا';
	@override String get restart_app => 'أعد تشغيل التطبيق';
	@override String get restart_app_confirm_title => 'هل تريد إعادة تشغيل GodotHub';
	@override String get restart_app_confirm_desc => 'سيتم إغلاق التطبيق و إعادة فتحه تلقائيا. العملية التي في طور التشغيل أو الغير محفوظة ستتم مقاطعتها.';
	@override String get reset_settings => 'أعد ضبط كل الإعدادات';
	@override String get delete_app_data => 'احذف ملفات التطبيق';
	@override String get new_project_default => 'مجلد البحث الإفتراضي';
	@override String get download_folder => 'مجلد التنزيل الإفتراضي';
	@override String get system => 'النظام';
	@override String get k12h => '12-ساعة (2:30 PM)';
	@override String get k24h => '24-ساعة (14:30)';
	@override String get dd_mm_yyyy => 'DD-MM-YYYY';
	@override String get mm_dd_yyyy => 'MM-DD-YYYY';
	@override String get yyyy_mm_dd => 'YYYY-MM-DD';
	@override String get reset_all_title => 'هل تريد إعادة ضبط كل الإعدادات؟';
	@override String get reset_all_desc => 'هذا يعيد كل إعداد في هذه الصفحة, مجلدات التحميل, مجلدات المسح, المظهر, و الوظائف, إلى حالتهم الإفتراضية. لا يمكن التراجع عن هذا الخيار.';
	@override String get delete_all_title => 'هل تريد حذف كل بيانات التطبيق?';
	@override String get delete_all_desc => 'هذا سيحذف بشكل كامل كل بيئة عمل, مشروع, تصنيف, إصدارات مثبتة, و كل إعدادات GodotHub, و يعيدك إلى قائمة الإعداد الأولى. مجلدات مشاريعك و نسخ Godot المثبتة لن تُلمس, إلا إذا كانت في مجلد التحميل الإفتراضي, في هذه الحالة سيتم حذفهم فعلا (إصدارات Godot). هذا الخيار لا يمكن التراجع عنه.';
	@override String get empty_hint_projects => 'لم تُضف أي مجلدات, لن يتم مسح أي مجلد أثناء الإقلاع, المشاريع الجديدة ستسألك أين تحفظ في كل مرة.';
	@override String get empty_hint_versions => 'لم تُضف أي مجلدات, , لن يتم مسح أي مجلد أثناء الإقلاع, التنزيلات الجديدة ستستخدم مجلد بيانات التطبيق.';
	@override String get naming_convention_label => 'مجلد تمسية المصطلحات';
	@override String get naming_keep => 'أبقه كما هو مكتوب (My Game)';
	@override String get naming_kebab => 'kebab-case (my-game)';
	@override String get naming_snake => 'snake_case (my_game)';
	@override String get naming_camel => 'camelCase (myGame)';
	@override String get naming_pascal => 'PascalCase (MyGame)';
	@override String get naming_title => 'Title Case (My Game)';
	@override String get theme => 'المظهر';
	@override String get theme_preset_label => 'إعداد المظهر';
	@override String get theme_preset_custom => 'مُخصص';
	@override String get preset_light_group => 'المظاهر الفَاتحة';
	@override String get preset_dark_group => 'المظاهر المُظلمة';
	@override String get test => 'اختبار';
	@override String get testing => 'جاري الإختبار…';
	@override String get token_valid => 'الرمز صالح! الحد: {{status}}';
	@override String get token_resets_in => '(resets ~{{minutes}} min)';
	@override String get test_failed => 'الإختبار فشل: {{error}}';
	@override String get key_space => 'مساحة';
	@override String get no_settings_match => 'لا يوجد أي إعداد';
	@override String get scan_result => 'عُثر على {{projects}} مشروعا جديد و {{versions}} إصدارا جديد.';
	@override String get palette_shortcut => 'إختصار لوحة الأوامر';
	@override String get keybind_instruction => 'انقر على الزر أدناه، ثم اضغط على أي مفتاح لإعادة التعيين.';
	@override String get press => 'اضغط';
	@override String get to_cancel => 'للإلغاء';
	@override String get press_key => 'اضغط زرا…';
	@override String get click_to_rebind => 'اضغط لإعادة التعيين';
	@override String get close_on_open_label => 'أغلق التطبيق عند فتح مشروع ما';
	@override String get launch_console_label => 'افتح Godot مع الطرفية';
	@override String get builtin_console_label => 'Use the built-in console';
	@override String get minimize_tray_label => 'صغّر التطبيق لشريط المهام عن الإغلاق';
	@override String get reopen_label => 'أعد فتحه عند إغلاق Godot';
	@override String get no_folder_set => 'لم ستم تحديد أي مجلد. يمكنك مع هذا الإستوراد يدويا أو استعمال \'إحفظ كقالب\'.';
	@override String get ui_density_label => 'كثافة واجهة المستخدم';
	@override String get text_size_label => 'حجم الخط';
	@override String get section_godot_versions => 'إصدارات Godot';
	@override String get scan_depth_label => 'امسح المسار';
	@override String get icon_scan_depth_label => 'Project icon search depth';
	@override String get download_concurrency_label => 'التنزيلات المتتالية';
	@override String get tray_recent_label => 'المشاريع الأخير في أيقونة شريط المهام';
	@override String get tooltip_delay_label => 'تأخير التلميح';
	@override String get project_icon_opacity_label => 'شفافية أيقونات المشاريع';
	@override String get time_format_label => 'صيغة الوقت';
	@override String get date_format_label => 'صيغة التاريخ';
	@override String get auto_scan_label => 'المسح التلقائي عن الإقلاع';
	@override String get use_workspaces_label => 'استخدم بيئات العمل';
	@override String get watch_projects_label => 'راقب مجلدات المشاريع';
	@override String get watch_versions_label => 'راقب مجلدات الإصدارات';
	@override String get watch_template_label => 'راقب مجلدات القوالب';
	@override String get show_scrollbar_label => 'أظهر شريط التمرير';
	@override String get animated_numbers_label => 'تأثير الأرقام عند تغييرها';
	@override String get show_support_label => 'أظهر زر الدعم';
	@override String get show_star_label => 'أظهر زر النجمة';
	@override String get show_bug_label => 'أظهر زر التبليغ عن المشاكل';
	@override String get show_tray_label => 'أظهر زر الإشعارات';
	@override String get show_language_label => 'أظهر زر اللغة';
	@override String get clear => 'نظف';
	@override String get reset_to_default => 'أعد الضبط للإعداد الإفتراضي';
	@override String get reset_appearance => 'أعد ضبط المظهر للإعداد الإفتراضي';
	@override String get delete_all => 'احذف الكل';
	@override String get open_setup => 'افتح واجهة الإعداد';
	@override String get reset_colors => 'أعد ضبط الألوان للإعداد الإفتراضي';
	@override String folders_deep({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} folders deep',
		one: '${count} مجلد عميق',
		two: '${count} folders deep',
		few: '${count} folders deep',
		many: '${count} folders deep',
		other: '${count} مجلدات عميقة',
	);
	@override String get at_once => '{{count}} في المرة';
	@override String get animation_speed_label => 'Animation speed';
	@override String get scroll_reveal_label => 'Scroll reveal';
	@override String get card_tilt_label => 'Card tilt on hover';
	@override String get click_ripple_label => 'Click ripple';
	@override String get press_bounce_label => 'Press bounce';
	@override String get animation_intensity_label => 'كثافة الحركة';
	@override String get animation_full => 'كامل';
	@override String get animation_subtle => 'جزئي';
	@override String get animation_none => 'بلا';
	@override String get view_entrance_label => 'تأثير الإنتقال';
	@override String get entrance_fade => 'التلاشي';
	@override String get entrance_slide => 'الإنزلاق';
	@override String get entrance_scale => 'التقليص';
	@override String get entrance_none => 'بلا';
	@override String get custom_css_label => 'CSS مخصص';
	@override String get custom_css_placeholder => '/* Your custom styles, e.g. */\n.card { border-radius: 4px !important; }';
	@override String get custom_css_apply => 'طبق CSS';
	@override String get custom_css_applied => 'تم تطبيق CSS';
	@override String get animation_threshold_label => 'عتبة الرسوم المتحركة للقائمة';
	@override String get time_tracking_title => 'النسخة الإحتياطة للتتبع الوقت';
	@override String get export_stats_btn => 'صدر الإحصائيات…';
	@override String get import_stats_btn => 'استورد الإحصائيات…';
	@override String get stats_exported => 'تم تصدير إحصائيات الوقت.';
	@override String get clear_stats_confirm_title => 'هل تريد مسح كل بيانات الوقت';
	@override String get clear_stats_confirm_desc => 'This permanently deletes all time tracking history, session records, and per-project totals. This cannot be undone.';
	@override String get clear_stats_confirm_btn => 'امسح الكل';
	@override String get stats_cleared => 'تم مسح بيانات الوقت.';
	@override String get settings_backup_title => 'إعدادات النسخة الإحتياطية';
	@override String get export_settings_btn => 'صدر الإعدادات';
	@override String get import_settings_btn => 'استورد الإعدادات';
	@override String get workspace_backup_title => 'أنشئ نسخة إحتياطية لبيئة العمل';
	@override String get workspace_backup_export_btn => 'صدر بيئة العمل';
	@override String get workspace_backup_restore_btn => 'استرجع بيئة العمل';
	@override String get workspace_backup_exported => 'تم تصدير النسخة الإحتياطية لبيئة العمل.';
	@override String get workspace_backup_imported => 'تم إسترجاع النسخة الإحتياطية لبيئة العمل.';
	@override String get app_backup_title => 'أنشئ نسخة إحتياطية لكل شيئ (كل بيئات العمل)';
	@override String get app_backup_export_btn => 'صدر كل شيئ';
	@override String get app_backup_restore_btn => 'استرجع كل شيء';
	@override String get app_backup_exported => 'تم تصدير النسخة الإحتياطية الشاملة.';
	@override String get app_backup_imported => 'تم استرجاع النسخة الإحتياطية الشاملة.';
	@override String get sync_title => 'المزامنة السحابية (GitHub gist)';
	@override String get sync_push_btn => 'ادفع';
	@override String get sync_pull_btn => 'اسحب';
	@override String get sync_push_done => 'تم دفع بيئة العمل لـ \'gist\' خاصتك.';
	@override String get sync_open_gist => 'افتح \'gist\'';
	@override String get sync_last_pushed => 'أخر عملية دفع: {{time}}';
	@override String get sync_manual_hint => 'Lost your local data? Enter your gist URL or ID to restore from any machine.';
	@override String get sync_manual_placeholder => 'https://gist.github.com/... or gist ID';
	@override String get sync_manual_pull_btn => 'إسترجع';
	@override String get restore_modal_title => 'إسترجع من السحابة';
	@override String get restore_modal_fetching => 'جاري جلب النسخة الإحتياطية من Github…';
	@override String get restore_modal_applying => 'جاري تطبيق النسخة الإحتياطية و إعادة التشغيل…';
	@override String get restore_modal_preview_desc => 'نسختك الإحتياطية تحتوي على:';
	@override String restore_modal_workspaces({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'workspaces',
		one: 'بيئة عمل',
		two: 'workspaces',
		few: 'workspaces',
		many: 'workspaces',
		other: 'بيئات العمل',
	);
	@override String restore_modal_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'projects',
		one: 'المشروع',
		two: 'projects',
		few: 'projects',
		many: 'projects',
		other: 'المشاريع',
	);
	@override String restore_modal_categories({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'categories',
		one: 'التصنيف',
		two: 'categories',
		few: 'categories',
		many: 'categories',
		other: 'التصنيفات',
	);
	@override String restore_modal_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'templates',
		one: 'القالب',
		two: 'templates',
		few: 'templates',
		many: 'templates',
		other: 'القوالب',
	);
	@override String get restore_modal_time_stats => 'Includes time tracking data';
	@override String restore_modal_todos({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Includes ${count} to-dos',
		one: 'Includes ${count} to-do',
		two: 'Includes ${count} to-dos',
		few: 'Includes ${count} to-dos',
		many: 'Includes ${count} to-dos',
		other: 'Includes ${count} to-dos',
	);
	@override String get restore_modal_project_scan_dirs => '{{count}} project scan folder(s) will be restored';
	@override String get restore_modal_version_scan_dirs => '{{count}} Godot version folder(s) will be restored';
	@override String get restore_modal_workspace_list => 'بيئات العمل';
	@override String get restore_modal_warning => 'This will overwrite your current settings and workspace data. You\'ll need to restart the app to apply changes.';
	@override String get restore_modal_apply_btn => 'طبّق و أعد التشغيل';
	@override String get restore_modal_done_title => 'تمت إستعادة النسخة الإحتياطية';
	@override String get restore_modal_done_hint => 'اضغط على الزر أسفله لإعادة التشغيل و تطبيق كل التغييرات.';
	@override String get settings_exported => 'تم تصدير الإعدادات.';
	@override String get settings_imported => 'تم استوراد الإعدادات.';
	@override String stats_imported({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Imported stats for ${count} projects.',
		one: 'تم إستوراد إحصائيات ${count} مشروعا.',
		two: 'Imported stats for ${count} projects.',
		few: 'Imported stats for ${count} projects.',
		many: 'Imported stats for ${count} projects.',
		other: 'تم إستوراد إحصائيات ${count} مشروعا.',
	);
	@override String get raised_contrast_label => 'Raised surface contrast';
	@override String get raised_contrast_value => '{{value}}%';
	@override String get token_help_desc => 'أنشئ رمزًا مميزًا على github.com/settings/tokens. ما عليك سوى تحديد نطاق repo إذا كنت ترغب في الوصول إلى المستودع الخاص، وإلا فاترك جميع النطاقات غير محددة. لا توجد أذونات حساسة مطلوبة.';
	@override String get discord_app_id_label => 'Discord Application ID';
	@override String get discord_app_id_placeholder => 'Leave empty to use the built-in default';
	@override String get discord_app_id_desc => 'Create an application in the Discord Developer Portal and paste its Application ID here to use your own instead of GodotHub\'s built-in one. The activity shows under that application\'s name.';
	@override String get discord_developer_portal => 'Discord Developer Portal';
	@override String get discord_builtin_hint => 'Using the built-in GodotHub application.';
	@override String get discord_show_projects_label => 'أظهر إسم المشروع';
	@override String get discord_excluded_label => 'المشاريع المعزولة';
	@override String get discord_exclude_project => 'أضف مشروعا';
	@override String get discord_excluded_empty => 'No excluded projects.';
	@override String get discord_excluded_remove => 'Remove from excluded projects';
	@override String get discord_custom_label => 'تخصيص الحالة';
	@override String get discord_custom_add => 'أضف مشروعا';
	@override String get discord_custom_details_placeholder => 'سطر التفاصيل';
	@override String get discord_custom_state_placeholder => 'سطر الحالة';
	@override String get discord_custom_remove => 'Remove custom presence';
	@override String get search_placeholder => 'ابحث في الإعدادات…';
	@override String get interface_label => 'واجهة المستخدم';
	@override String get card_layout_label => 'تخطيط البطاقة';
	@override String get landing_tab_label => 'الصفحة الأساسية الإفتراضية';
	@override String get language_complete => 'مكتملة';
	@override String get language_beta => 'تجريبية';
	@override String get language_incomplete => 'غير مكتملة';
	@override String get use_os_decorations => 'استخدم مظهر نافذة نظام التشغيل';
	@override String get credits => 'المطورون';
	@override String get credits_developer => 'تم الإنشاء بواسطة';
	@override String get credits_built_with => 'تم البناء بواسطة';
	@override String get credits_contributors => 'المساهمون';
	@override String get experimental => 'تجريبية';
	@override String get customize_view_label => 'زر تخصيص الواجهة';
	@override String get fixed_sidebar_resize_knob_label => 'ثبت مقبض تغيير حجم الشريط الجانبي';
	@override String get desktop_notifications_label => 'إشعار سطح المكتب';
	@override String get colored_titlebar_buttons_label => 'إستعمل أزرار نافذة ملونة';
	@override String get project_todos_label => 'Project Next Steps';
	@override String get mise_label => 'Use mise for Godot versions';
	@override String get mise_detected => 'Detected mise {{version}}';
	@override String get mise_not_found => 'mise was not found on your PATH, so this stays off until you install it.';
	@override String get cli_tool_title => 'Command-line tool';
	@override String get cli_tool_install => 'Install';
	@override String get cli_tool_installing => 'Installing...';
	@override String get cli_tool_installed_msg => 'Installed. Open a new terminal, then run: godothub';
	@override String get cli_tool_uninstalled_msg => 'Removed. The godothub command is no longer on your PATH.';
	@override String get git_auth_step_copy => 'Copy your code';
	@override String get git_auth_step_paste => 'Paste it on {{provider}}';
	@override String get git_auth_step_approve => 'Approve GodotHub';
	@override String get git_auth_copy_and_open => 'Copy code & open {{provider}}';
	@override String get git_auth_copied => 'Copied';
	@override String get git_auth_expires_in => 'Expires in {{time}}';
	@override String get git_auth_expired => 'This code has expired';
	@override String get git_auth_failed => 'Couldn’t connect';
	@override String get git_auth_try_again => 'Try again';
	@override String get git_auth_success_hint => 'You can close this window.';
	@override String get show_changelog_label => 'Show changelog button';
	@override String get features_title => 'Features';
	@override String get features_desc => 'Choose which parts of GodotHub you use. Hidden features leave the sidebar and stop loading or running in the background.';
	@override String get features_always_on => 'Always on';
	@override String get features_optional => 'Optional';
	@override String features_enabled_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} features on',
		one: '${count} feature on',
		two: '${count} features on',
		few: '${count} features on',
		many: '${count} features on',
		other: '${count} features on',
	);
	@override String get setup_profile_minimal => 'Minimal';
	@override String get setup_profile_minimal_desc => 'Just projects and Godot versions. The lightest, fastest setup.';
	@override String get setup_profile_essentials => 'Essentials';
	@override String get setup_profile_essentials_desc => 'Adds the Asset Store, templates, and categories.';
	@override String get setup_profile_studio => 'Studio';
	@override String get setup_profile_studio_desc => 'Essentials plus the dashboard, vault, storage, and workspaces.';
	@override String get setup_profile_complete => 'Everything';
	@override String get setup_profile_complete_desc => 'Every feature GodotHub has, including Godot news.';
	@override String get setup_profile_custom => 'Custom';
	@override String get setup_profile_custom_desc => 'Turn individual features on or off.';
	@override String get feature_desc_dashboard => 'An overview of your activity, playtime, and recent projects.';
	@override String get feature_desc_templates => 'Start new projects from your own reusable templates.';
	@override String get feature_desc_vault => 'Keep reusable scripts, scenes, and assets in one library.';
	@override String get feature_desc_storage => 'See how much disk space projects and engines use.';
	@override String get feature_desc_asset_store => 'Browse and install addons and demos from the Godot Asset Library.';
	@override String get feature_desc_categories => 'Group your project list into folders.';
	@override String get feature_desc_workspaces => 'Switch between separate sets of projects and settings.';
}

// Path: todos
class _Translations$todos$ar_MA extends Translations$todos$en_US {
	_Translations$todos$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get next_steps => 'Next steps';
	@override String get saving_tasks => 'Saving tasks';
	@override String pending_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} pending',
		one: '${count} pending',
		two: '${count} pending',
		few: '${count} pending',
		many: '${count} pending',
		other: '${count} pending',
	);
	@override String completed_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} completed',
		one: '${count} completed',
		two: '${count} completed',
		few: '${count} completed',
		many: '${count} completed',
		other: '${count} completed',
	);
	@override String get new_task => 'New task';
	@override String get hide_next_steps => 'Hide next steps';
	@override String get save_changes_failed => 'Could not save the changes.';
	@override String get loading_tasks => 'Loading tasks...';
	@override String get load_tasks_failed => 'Could not load tasks';
	@override String get data_unchanged => 'Your data was not modified.';
	@override String get empty_title => 'No tasks yet';
	@override String get empty_description => 'Add the first next step for this project.';
	@override String get create_task => 'Create task';
	@override String get all_completed_title => 'All done';
	@override String get all_completed_description => 'You completed all the next steps for this project.';
	@override String get footer_hint => 'Use the list to keep track of the project\'s next steps.';
	@override String get view_all => 'View all';
	@override String get delete_task_title => 'Delete task?';
	@override String get delete_task_description => 'The task <strong>“{{title}}”</strong> will be deleted. This action cannot be undone.';
	@override String get task => 'Task';
	@override String get area => 'Discipline';
	@override String get status => 'Status';
	@override String get due_date => 'Due date';
	@override String get sort_by_status => 'Sort by status';
	@override String get sort_by_due_date => 'Sort by due date';
	@override String get change_status => 'Change status: {{status}}';
	@override String get overdue => 'Overdue';
	@override String get mark_completed => 'Mark task as completed';
	@override String get mark_not_completed => 'Mark task as not completed';
	@override String get view_task_details => 'View task details: {{title}}';
	@override String get task_actions => 'Task actions';
	@override String get edit => 'Edit';
	@override String get status_todo => 'To do';
	@override String get status_paused => 'Paused';
	@override String get status_in_progress => 'In progress';
	@override String get status_done => 'Completed';
	@override String get area_programming => 'Programming';
	@override String get area_art => 'Art';
	@override String get area_audio => 'Audio';
	@override String get area_design => 'Design';
	@override String get area_narrative => 'Narrative';
	@override String get area_other => 'Other';
	@override String get edit_task => 'Edit task';
	@override String get title => 'Title';
	@override String get title_placeholder => 'E.g.: Create main menu';
	@override String get description_placeholder => 'Add more details about what needs to be done...';
	@override String get no_due_date => 'No due date';
	@override String get remove_due_date => 'Remove due date';
	@override String get past_due_date => 'This due date has passed';
	@override String get save_task_failed => 'Could not save the task. Try again.';
	@override String get add_task => 'Add task';
	@override String get no_description => 'No description';
	@override String get tomorrow => 'Tomorrow';
	@override String due_in_days({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Due in ${count} days',
		one: 'Due in ${count} day',
		two: 'Due in ${count} days',
		few: 'Due in ${count} days',
		many: 'Due in ${count} days',
		other: 'Due in ${count} days',
	);
	@override String get overdue_yesterday => 'Was due yesterday';
	@override String overdue_days({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Overdue by ${count} days',
		one: 'Overdue by ${count} day',
		two: 'Overdue by ${count} days',
		few: 'Overdue by ${count} days',
		many: 'Overdue by ${count} days',
		other: 'Overdue by ${count} days',
	);
	@override String get scan_code => 'Scan code';
	@override String get scan_code_hint => 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed';
	@override String get comment_scan_summary => 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened';
	@override String get comment_scan_none => 'Code scan found no changes';
	@override String commit_closed({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Completed ${count} to-dos from commit messages',
		one: 'Completed ${count} to-do from a commit message',
		two: 'Completed ${count} to-dos from commit messages',
		few: 'Completed ${count} to-dos from commit messages',
		many: 'Completed ${count} to-dos from commit messages',
		other: 'Completed ${count} to-dos from commit messages',
	);
	@override String get linked_file => 'Linked file';
	@override String get linked_file_placeholder => 'res://scenes/player.tscn';
	@override String get linked_file_hint => 'Link a scene, script or resource from this project.';
	@override String get linked_file_invalid => 'Use a res:// path from this project.';
	@override String get open_linked_file => 'Open {{path}}';
	@override String get open_file => 'Open';
	@override String get source_comment => 'Imported from a {{tag}} comment';
	@override String get closed_by_commit => 'Completed by commit {{hash}}: {{subject}}';
	@override String get closed_by_comment_removed => 'Completed because its comment was removed from the code';
	@override String get todo_reference => 'Reference';
	@override String get todo_reference_hint => 'Write "Fixes {{ref}}" in a commit message to complete it automatically.';
	@override String get git_activity_loading => 'Looking through Git history…';
	@override String get git_activity_empty => 'No commits or branches mention {{ref}} yet.';
	@override String get git_branches => 'Branches';
	@override String get git_commit_closes => 'Closes';
	@override String get quick_add_placeholder => 'Add a to-do and press Enter';
	@override String get priority => 'Priority';
	@override String get priority_none => 'None';
	@override String get priority_low => 'Low';
	@override String get priority_medium => 'Medium';
	@override String get priority_high => 'High';
	@override String get priority_label => '{{priority}} priority';
	@override String get checklist => 'Checklist';
	@override String get checklist_add_placeholder => 'Add a checklist item and press Enter';
	@override String get checklist_remove => 'Remove item';
	@override String get checklist_progress => '{{done}} of {{total}} done';
	@override String get completed_on => 'Done {{date}}';
	@override String get completed_on_full => 'Completed {{date}}';
	@override String get search_tasks_placeholder => 'Search to-dos…';
	@override String get all_areas => 'All areas';
	@override String get no_matching_tasks => 'No to-dos match your search.';
	@override String open_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} to-dos',
		one: '${count} to-do',
		two: '${count} to-dos',
		few: '${count} to-dos',
		many: '${count} to-dos',
		other: '${count} to-dos',
	);
	@override String overdue_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} overdue',
		one: '${count} overdue',
		two: '${count} overdue',
		few: '${count} overdue',
		many: '${count} overdue',
		other: '${count} overdue',
	);
	@override String get tile_summary => '{{overdue}} overdue · {{soon}} due this week';
	@override String get tile_empty => 'Nothing overdue or due this week.';
	@override String due_notification_title({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} to-dos are due',
		one: 'To-do due: {{title}}',
		two: '${count} to-dos are due',
		few: '${count} to-dos are due',
		many: '${count} to-dos are due',
		other: '${count} to-dos are due',
	);
	@override String get due_notification_more => 'and {{count}} more';
}

// Path: versions
class _Translations$versions$ar_MA extends Translations$versions$en_US {
	_Translations$versions$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get standard => 'القياسية';
	@override String get unbound => 'unbound';
	@override String get mono => 'Mono';
	@override String get both => 'معا';
	@override String get stable => 'مستقرة';
	@override String get unstable => 'غير مستقرة';
	@override String get rename => 'أعد التسمية';
	@override String get open_editor => 'افتح المحرر';
	@override String get open_editor_with_console => 'افتح المحرر مع الطرفية';
	@override String get more_editor_launch_options => 'إعدادات أخرى';
	@override String get open_install_folder => 'افتح مجلد التنزيلات';
	@override String get type => 'النوع';
	@override String get channel => 'القناة';
	@override String get fetch_error => 'لم يكن بالمستطاع جلب الإصدارات المتاحة.';
	@override String get paused_dot => 'متوقف · ';
	@override String get available_title => 'الإصدارات المتوفرة';
	@override String get no_versions_match => 'لا توجد إصدارات مثبتة متوافقة';
	@override String get no_available_versions_match => 'لا توجد إصدارات متوافقة';
	@override String get open => 'افتح';
	@override String get install => 'ثبت';
	@override String get mb => 'MB';
	@override String get resume_download => 'استئنف التنزيل';
	@override String get pause_download => 'أوقف التنزيل مؤقتا';
	@override String get cancel_download => 'ألغي التنزيل';
	@override String installed_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'لا توجد تثبيتات',
		one: 'مثبت',
		two: 'مثبت',
		few: 'مثبت',
		many: 'مثبت',
		other: 'مثبت',
	);
	@override String get installed_label => 'مثبت';
	@override String get original_name => 'الأصلي';
	@override String get source => 'المصدر';
	@override String get source_github => 'GitHub';
	@override String get source_archive => 'Godot أرشيف';
	@override String get source_mise => 'mise';
	@override String get switch_to_archive => 'بدل لأرشيف Godot';
	@override String get sort_version_latest => 'الأحدث';
	@override String get sort_version_oldest => 'الأقدم';
	@override String get sort_version_recently_installed => 'المثبت مؤخرا';
	@override String get sort_version_oldest_installed => 'المثبت قديما';
	@override String get set_as_current => 'Set as Current';
	@override String get unset_current => 'Unset Current';
	@override String get current_set_title => 'Version Set as Current';
	@override String get current_dir_label => 'Folder';
	@override String get current_copy => 'Copy';
	@override String get current_copied => 'Copied';
	@override String get current_copy_alias => 'Copy alias path';
	@override String get current_copy_dir => 'Copy folder path';
	@override String get current_open_folder => 'Open Alias Folder';
	@override String get current_path_hint => 'Add the folder above to your PATH to run "Godot" from any terminal, script, or tool. The alias always follows the current version, so pinning another version or uninstalling this one updates it automatically.';
	@override String get current_shim_note => 'Windows symlinks need Developer Mode or admin rights, so a launcher script was created instead. It behaves the same from the command line.';
	@override String get mono_short => 'mono';
	@override String get aliases_manage => 'Aliases';
	@override String get aliases_title => 'Version Aliases';
	@override String get aliases_empty => 'No aliases yet. Pick a version above, give the command a name, and it will appear in the aliases folder.';
	@override String get aliases_no_versions => 'Install a Godot version first to create an alias.';
	@override String get aliases_path_hint => 'Add the aliases folder to your PATH to run these names from any terminal or tool. The "Godot" command from the current version pin lives in the same folder.';
	@override String get alias_create => 'Create Alias';
	@override String get alias_add => 'Add Alias';
	@override String get alias_name_label => 'Alias name';
	@override String get alias_name_placeholder => 'godot-mono';
	@override String get alias_copy_path => 'Copy alias path';
	@override String get alias_shim_badge => 'script';
	@override String get alias_mono_script_note => 'Mono builds load GodotSharp from the folder next to the executable, so on Windows the alias is created as a launcher script instead of a link.';
	@override String alias_create_all({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: 'Create ${count} Aliases',
		one: 'Create Alias',
		two: 'Create ${count} Aliases',
		few: 'Create ${count} Aliases',
		many: 'Create ${count} Aliases',
		other: 'Create ${count} Aliases',
	);
	@override String aliases_batch_created({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} aliases created',
		one: '1 alias created',
		two: '${count} aliases created',
		few: '${count} aliases created',
		many: '${count} aliases created',
		other: '${count} aliases created',
	);
	@override String aliases_batch_skipped({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} aliases skipped',
		one: '1 alias skipped',
		two: '${count} aliases skipped',
		few: '${count} aliases skipped',
		many: '${count} aliases skipped',
		other: '${count} aliases skipped',
	);
	@override String get alias_queue_duplicate => '"{{name}}" is already in the list';
	@override String get alias_remove => 'Remove alias';
	@override String get alias_remove_title => 'Remove this alias?';
	@override String get alias_remove_desc => 'The command "{{name}}" will stop working. The Godot version itself stays installed.';
	@override String get managed_by_mise => 'mise';
	@override String get mise_installing => 'Installing with mise…';
	@override String get mise_sync => 'Sync';
	@override String get mise_sync_title => 'Import the Godot versions mise has installed so they show up here.';
	@override String get mise_missing => 'mise not found';
	@override String get mise_uninstall_desc => 'mise will uninstall {{tag}} from its own store. Projects that pin it in mise.toml will need it installed again.';
	@override String get export_templates_installed => 'Templates';
	@override String get export_templates_missing => 'No templates';
	@override String get export_templates_install => 'Install export templates';
	@override String get export_templates_remove => 'Remove export templates';
	@override String get export_templates_remove_title => 'Remove export templates?';
	@override String get export_templates_remove_desc => 'The export templates for {{tag}} will be deleted from disk. You can download them again later.';
	@override String get export_templates_remove_confirm => 'Remove';
	@override String get export_templates_open_folder => 'Open templates folder';
	@override String get templates_folder => 'مجلد القوالب';
	@override String get versions_folder => 'مجلد الإصدارات';
	@override String get export_templates_installed_toast => 'Export templates installed for {{tag}}';
	@override String get export_templates_install_failed => 'Couldn\'t install export templates: {{error}}';
	@override String get export_templates_removed_toast => 'Export templates removed';
	@override String get export_templates_orphans_title => 'Unused template folders';
	@override String get export_templates_orphans_desc => 'These folders don\'t match a Godot version managed by GodotHub.';
	@override String get export_templates_orphan_delete => 'Delete folder';
	@override String get export_templates_orphan_delete_title => 'Delete this template folder?';
	@override String get export_templates_orphan_delete_desc => '"{{folder}}" will be deleted from disk.';
	@override String get export_templates_orphan_deleted => 'Template folder deleted';
	@override String get export_templates_choose => 'Choose export templates';
	@override String export_templates_selected({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} templates selected',
		one: '1 template selected',
		two: '${count} templates selected',
		few: '${count} templates selected',
		many: '${count} templates selected',
		other: '${count} templates selected',
	);
	@override String get export_templates_size_summary => '~{{download}} download · {{installed}} on disk';
	@override String get export_templates_download_selected => 'Download selected';
	@override String get export_templates_loading_options => 'Checking this release\'s available templates…';
	@override String get export_templates_options_failed => 'Couldn\'t load the templates for this release.';
	@override String export_templates_available({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} available template groups',
		one: '1 available template group',
		two: '${count} available template groups',
		few: '${count} available template groups',
		many: '${count} available template groups',
		other: '${count} available template groups',
	);
	@override String get export_templates_select_all => 'Select all';
	@override String export_templates_files({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} template files',
		one: '1 template file',
		two: '${count} template files',
		few: '${count} template files',
		many: '${count} template files',
		other: '${count} template files',
	);
	@override String get export_templates_option_installed => 'Installed';
	@override String get export_templates_keep_existing => 'Expand a platform to choose architectures or individual files. Only selected files are downloaded. Your existing templates are kept.';
	@override String get export_templates_uninstall_named => 'Uninstall {{name}}';
	@override String get export_templates_uninstall_failed => 'Couldn\'t uninstall templates: {{error}}';
	@override String get export_templates_category_desktop => 'Desktop';
	@override String get export_templates_category_mobile => 'Mobile';
	@override String get export_templates_category_web => 'Web';
	@override String get export_templates_category_common => 'Common';
	@override String get export_templates_category_other => 'Other';
	@override String get export_templates_web_standard => 'Web';
	@override String get export_templates_web_extensions => 'Web with Extensions';
	@override String get export_templates_web_single_threaded => 'Web Single-Threaded';
	@override String get export_templates_web_extensions_single_threaded => 'Web with Extensions Single-Threaded';
	@override String get export_templates_refresh => 'Refresh available templates';
	@override String get download_failed_title => 'فشل التنزيل';
	@override String get download_failed_asset_label => 'الملف';
	@override String get download_failed_error_label => 'تفاصيل الخطأ';
	@override String get download_failed_copy => 'نسخ التفاصيل';
	@override String get download_failed_hint => 'الأسباب الشائعة: شبكة أو وكيل محجوب، برنامج مكافحة فيروسات يحجب التنزيل، مجلد تنزيل غير موجود أو للقراءة فقط، أو مساحة قرص منخفضة.';
	@override String get custom_build_badge => 'Custom build';
	@override String get add_custom_build => 'Add custom build…';
	@override String get adding_custom_build => 'Adding custom build…';
}

// Path: common.project_doctor
class _Translations$common$project_doctor$ar_MA extends Translations$common$project_doctor$en_US {
	_Translations$common$project_doctor$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Project Doctor';
	@override String get scanning => 'Checking this project…';
	@override String get scan_failed => 'Could not check this project';
	@override String get run_again => 'Run checks again';
	@override String summary_errors({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} issues need attention',
		one: '${count} issue needs attention',
		two: '${count} issues need attention',
		few: '${count} issues need attention',
		many: '${count} issues need attention',
		other: '${count} issues need attention',
	);
	@override String summary_warnings({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} warnings to review',
		one: '${count} warning to review',
		two: '${count} warnings to review',
		few: '${count} warnings to review',
		many: '${count} warnings to review',
		other: '${count} warnings to review',
	);
	@override String get summary_ready => 'No blocking issues found';
	@override String get summary_counts => '{{passed}} checks passed · {{findings}} findings';
	@override String passed_checks({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} passed checks',
		one: '${count} passed check',
		two: '${count} passed checks',
		few: '${count} passed checks',
		many: '${count} passed checks',
		other: '${count} passed checks',
	);
	@override String get local_checks => 'Checks run locally. Fixes to settings save a backup first.';
	@override String get fix_complete => 'Fix applied. Project checks updated.';
	@override String get templates_downloading => 'Downloading selected templates. Progress and cancellation are also available in Tasks.';
	@override String get version_queued => 'Engine download queued. Follow its progress in Tasks.';
	@override String get version_queued_short => 'Download queued';
	@override String get version_asset_unavailable => 'No matching download was found for this version and platform. Open Versions to install or locate the engine.';
	@override String get severity_ok => 'Passed';
	@override String get severity_info => 'Note';
	@override String get severity_warning => 'Warning';
	@override String get severity_error => 'Needs attention';
	@override String get category_engine => 'Engine and compatibility';
	@override String get category_templates => 'Export templates';
	@override String get category_cache => 'Import cache';
	@override String get category_scenes => 'Main scene';
	@override String get category_addons => 'Editor addons';
	@override String get category_git => 'Version control';
	@override String get category_exports => 'Export presets';
	@override String get category_registrations => 'Project registration';
	@override String get action_choose_version => 'Choose installed version';
	@override String get action_install_version => 'Install bound version';
	@override String get action_manage_versions => 'Manage engine versions';
	@override String get action_templates => 'Choose export templates';
	@override String get action_clear_cache => 'Move cache to Trash';
	@override String get action_disable_addon => 'Remove missing addon entry';
	@override String get action_enable_addon => 'Enable addon';
	@override String get action_add_ignores => 'Add ignore rules';
	@override String get action_untrack_metadata => 'Stop tracking local metadata';
	@override String get action_track_lfs => 'Track file with Git LFS';
	@override String get action_remove_registration => 'Remove registration';
	@override String get action_open_editor => 'Open in Godot';
	@override String get action_open_presets => 'Review export presets in IDE';
	@override String get action_open_addons => 'Review addons in IDE';
	@override String get confirm_clear_cache => 'Move this project\'s .godot folder to the system Trash? Close the project in Godot first. Godot will reimport assets and rebuild editor state the next time it opens.';
	@override String get confirm_enable_addon => 'Enable this editor addon? Its script will run the next time you open the project in Godot. A backup of project.godot is saved first.';
	@override String get confirm_untrack_metadata => 'Remove .godothub.json from Git\'s index while keeping your local file? This stages its removal for your next commit. Existing commits and history stay unchanged.';
	@override String get confirm_track_lfs => 'Add a Git LFS rule for this file? Git LFS must be installed. This changes .gitattributes; re-add the file in Git to convert its next revision. Existing history stays unchanged.';
	@override String get confirm_remove_registration => 'Remove this library registration? Project files stay on disk. The registry is backed up first, and you can import the folder again.';
	@override String get version_unbound_title => 'No engine version is bound';
	@override String get version_unbound_description => 'Choose an installed engine to open and run this project.';
	@override String get version_missing_title => 'The bound engine is not installed';
	@override String get version_missing_description => 'This project is bound to {{version}}, but that version is absent from the installed engine registry.';
	@override String get version_executable_missing_title => 'The engine executable is missing';
	@override String get version_executable_missing_description => '{{version}} is registered, but its executable is no longer on disk. Locate or reinstall it in Versions.';
	@override String get version_ready_title => 'The bound engine is available';
	@override String get version_ready_description => '{{version}} is installed and its executable exists.';
	@override String get format_incompatible_title => 'The project format is incompatible';
	@override String get format_incompatible_description => 'config_version={{format}} cannot be opened by the bound {{version}} engine. Choose a compatible engine and use Godot\'s migration tools if needed.';
	@override String get major_mismatch_title => 'The project and engine use different Godot generations';
	@override String get major_mismatch_description => 'This project records a Godot {{major}} format but is bound to {{version}}. Choose a matching engine or migrate the project in Godot.';
	@override String get feature_mismatch_title => 'The recorded project version differs from its engine';
	@override String get feature_mismatch_description => 'The project records Godot {{recorded}} features but is bound to {{version}}. Match the binding or open it in the intended engine and review its upgrade changes.';
	@override String get format_unknown_title => 'The project version could not be confirmed';
	@override String get format_unknown_description => 'The project format or engine version is missing or unrecognized. Review project.godot before changing engine generations.';
	@override String get format_ready_title => 'The recorded format matches the bound engine';
	@override String get format_ready_description => 'The project format and recorded Godot feature version are compatible with this binding.';
	@override String get templates_missing_title => 'Export templates are missing';
	@override String get templates_platforms_missing_title => 'Some export targets have no installed templates';
	@override String get templates_platforms_missing_description => 'These platforms appear in your export presets but have no templates installed for the bound engine. Choose the template files you need.';
	@override String get templates_missing_description => 'No installed export-template platform was found for {{version}}. Choose the platforms and files you need.';
	@override String get templates_ready_title => 'Export templates are available';
	@override String get templates_ready_description => 'These platforms have installed templates for the bound engine. Open the chooser to review individual files.';
	@override String get templates_unknown_title => 'Install or bind the engine before checking templates';
	@override String get templates_unknown_description => 'Export templates must match the exact engine version, including standard or .NET builds.';
	@override String get main_scene_ready_title => 'A main scene is configured';
	@override String get main_scene_ready_description => 'The project has an application/run/main_scene setting.';
	@override String get main_scene_missing_title => 'No main scene is configured';
	@override String get main_scene_missing_description => 'Open the project in Godot and choose a main scene in Project Settings before running the game.';
	@override String get main_scene_missing_file_title => 'The main scene file is missing';
	@override String get main_scene_missing_file_description => 'The configured scene path does not exist. Choose an existing main scene in Godot.';
	@override String get cache_ready_title => 'The import cache is within normal limits';
	@override String get cache_ready_description => '{{size}} across {{files}} files. Last cache write: {{days}} days ago.';
	@override String get cache_large_title => 'The import cache uses significant disk space';
	@override String get cache_large_description => '{{size}} across {{files}} files. Large projects can need a large cache; clearing it causes a full reimport.';
	@override String get cache_stale_title => 'The import cache has not changed recently';
	@override String get cache_stale_description => '{{size}} across {{files}} files; last write was {{days}} days ago. Age alone does not mean the cache is broken.';
	@override String get cache_version_title => 'The cache records a different engine executable';
	@override String get cache_version_description => 'The editor cache was last associated with a different engine path. If imports misbehave, rebuild its {{size}} cache.';
	@override String get cache_partial_title => 'The cache scan was incomplete';
	@override String get cache_partial_description => 'At least {{size}} across {{files}} files. Some entries were unreadable or the scan reached its time or file limit.';
	@override String get cache_absent_title => 'No local .godot import cache';
	@override String get cache_absent_description => 'Godot 4 creates this folder when the project opens. Godot 3 uses a different cache layout.';
	@override String get addon_missing_title => 'An enabled editor addon is missing';
	@override String get addon_missing_description => 'This editor_plugins entry has no plugin.cfg on disk. Restore the addon or remove the stale enabled entry.';
	@override String get addon_disabled_title => 'An editor addon is present but disabled';
	@override String get addon_disabled_description => 'Its plugin.cfg is on disk but not listed in editor_plugins. This can be intentional. Enable it only if you want its editor functionality.';
	@override String get addon_orphan_title => 'An addon folder has no editor plugin configuration';
	@override String get addon_orphan_description => 'This folder is not an enabled editor addon. It may be a runtime library or leftover files; review it before removing anything.';
	@override String get addons_ready_title => 'Enabled editor addons exist on disk';
	@override String get addons_ready_description => 'No missing or disabled editor-plugin folders were found.';
	@override String get no_presets_title => 'No export presets configured';
	@override String get no_presets_description => 'Create export presets in Godot when you are ready to package the project.';
	@override String get presets_unreadable_title => 'Export presets could not be read';
	@override String get presets_unreadable_description => 'Review export_presets.cfg and run the checks again.';
	@override String get exports_ready_title => 'Export resource paths exist';
	@override String get exports_ready_description => 'Explicit res:// references in the export presets exist on disk. Wildcard filters and output paths are excluded from this check.';
	@override String get export_resources_missing_title => 'Export presets reference missing resources';
	@override String get export_resources_missing_description => 'Restore these files or update the references in Godot\'s export settings or export_presets.cfg.';
	@override String get git_unavailable_title => 'Git checks were skipped';
	@override String get git_unavailable_description => 'This folder is not in a Git repository, Git is unavailable, or the repository could not be inspected.';
	@override String get ignore_missing_title => 'Generated or local files are not ignored';
	@override String get ignore_missing_description => 'The effective Git ignore rules do not cover all of .godot/, .godothub/, and .godothub.json. Add project-local rules to keep them out of future commits.';
	@override String get ignores_ready_title => 'Generated and local files are ignored';
	@override String get ignores_ready_description => 'Git ignores the import cache and local GodotHub metadata.';
	@override String get metadata_tracked_title => 'Local GodotHub metadata is tracked by Git';
	@override String get metadata_tracked_description => '.godothub.json is in Git\'s index, so ignore rules alone will not keep it out of commits. Remove it from tracking while keeping the local file.';
	@override String get metadata_private_title => 'Legacy local metadata is not tracked';
	@override String get metadata_private_description => '.godothub.json is absent from Git\'s tracked-file index.';
	@override String get lfs_ready_title => 'No large binaries need a Git LFS rule';
	@override String get lfs_ready_description => 'Scanned binary files of 50 MiB or more are ignored by Git or covered by an LFS filter rule. Existing commit history is not inspected.';
	@override String get lfs_unknown_title => 'Git LFS attributes could not be checked';
	@override String get lfs_unknown_description => 'Review the Git error below, then run the checks again.';
	@override String get binary_without_lfs_title => 'A large binary has no Git LFS rule';
	@override String get binary_without_lfs_description => 'This binary is at least 50 MiB and is not ignored or covered by filter=lfs. Track it with LFS to keep future revisions out of regular Git blobs.';
	@override String get scan_partial_title => 'The project file scan was incomplete';
	@override String get scan_partial_description => 'Some paths were unreadable or the scan reached its 50,000-entry or five-second limit. Large-binary results may be incomplete.';
	@override String get registration_stale_title => 'This registration no longer points to a project';
	@override String get registration_stale_description => 'No project.godot was found at this path. Reconnect moved or offline storage, or remove the stale library entry.';
	@override String get registration_duplicate_title => 'Another registration points to this project';
	@override String get registration_duplicate_description => 'This additional library entry resolves to the same project folder or a stale copy of its identity. Remove it to keep the current registration.';
	@override String get registration_ready_title => 'No duplicate registrations found';
	@override String get registration_ready_description => 'This project has one valid folder registration in the active workspace.';
	@override String get category_android => 'Android';
	@override String get android_targeted_title => 'This project exports to Android';
	@override String get android_targeted_description => 'An Android export preset or Gradle build template was found, so the Android toolchain is checked below.';
	@override String get android_possible_title => 'This project may target mobile devices';
	@override String get android_possible_description => 'No Android export preset was found, but some settings suggest mobile use. Many desktop games also use the Mobile renderer, so the toolchain checks below are informational only.';
	@override String get hint_mobile_renderer => 'Uses the Mobile renderer';
	@override String get hint_mobile_renderer_override => 'Sets a renderer override for mobile platforms';
	@override String get hint_etc2_astc => 'Imports ETC2/ASTC textures, which Android requires';
	@override String get hint_orientation => 'Sets a handheld screen orientation';
	@override String get hint_touch_emulation => 'Emulates touch input from the mouse';
	@override String get hint_android_plugins => 'Has an android/plugins folder';
	@override String get android_sdk_missing_title => 'Android SDK not found';
	@override String get android_sdk_missing_description => 'Set the Android SDK path in Godot under Editor Settings → Export → Android, or set ANDROID_HOME. Android exports need it.';
	@override String get android_sdk_incomplete_title => 'The Android SDK is missing components';
	@override String get android_sdk_incomplete_description => 'The SDK at {{path}} is missing the parts listed below. Install them with Android Studio\'s SDK Manager or sdkmanager.';
	@override String get sdk_part_sdk_folder => 'The SDK folder does not exist';
	@override String get sdk_part_platform_tools => 'Platform Tools (adb)';
	@override String get sdk_part_build_tools => 'Build Tools';
	@override String get sdk_part_cmdline_tools => 'Command-line Tools';
	@override String get android_sdk_ready_title => 'Android SDK found';
	@override String get android_sdk_ready_description => 'Using the SDK at {{path}}.';
	@override String get android_jdk_missing_title => 'Java JDK not found';
	@override String get android_jdk_missing_description => 'Android exports need JDK {{required}} or newer. Set it in Godot under Editor Settings → Export → Android, or set JAVA_HOME.';
	@override String get android_jdk_invalid_title => 'The Java JDK path is invalid';
	@override String get android_jdk_invalid_description => 'No java executable was found in {{path}}. Point Godot to a JDK {{required}} installation.';
	@override String get android_jdk_old_title => 'The Java JDK is too old';
	@override String get android_jdk_old_description => 'JDK {{version}} is installed at {{path}}, but this Godot version needs JDK {{required}} or newer for Android exports.';
	@override String get android_jdk_ready_title => 'Java JDK found';
	@override String get android_jdk_ready_description => 'JDK {{version}} at {{path}}.';
	@override String get android_debug_keystore_missing_title => 'The debug keystore file is missing';
	@override String get android_debug_keystore_missing_description => 'Godot\'s editor settings point to a debug keystore that no longer exists. Clear the setting so Godot can create a new one, or pick another file.';
	@override String get android_gradle_template_missing_title => 'The Android build template is not installed';
	@override String get android_gradle_template_missing_description => 'These presets use a Gradle build, but the project has no android/build folder. In Godot, choose Project → Install Android Build Template.';
	@override String get android_release_keystore_missing_title => 'A release keystore file is missing';
	@override String get android_release_keystore_missing_description => 'These presets point to a release keystore that does not exist. Release exports will fail until the path is fixed.';
	@override String get android_release_keystore_unset_title => 'No release keystore is set';
	@override String get android_release_keystore_unset_description => 'These presets can only make debug builds until a release keystore is set. You need one to publish on Google Play.';
}

// Path: common.build_export
class _Translations$common$build_export$ar_MA extends Translations$common$build_export$en_US {
	_Translations$common$build_export$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Build & Export';
	@override String get description => 'Ship a release build of {{name}} using its bound Godot version.';
	@override String get loading => 'Reading export presets and checking release templates…';
	@override String get refresh => 'Refresh presets';
	@override String get preset => 'Export preset';
	@override String get choose_preset => 'Choose an export preset';
	@override String get output => 'Output file';
	@override String get browse => 'Choose output file';
	@override String get output_hint => 'Relative paths start at the project folder. Parent folders are created automatically. export_presets.cfg is kept unchanged.';
	@override String get release => 'Release build';
	@override String get engine => 'Godot {{version}}';
	@override String get start => 'Export release';
	@override String get starting => 'Starting export…';
	@override String get install_templates => 'Install export templates';
	@override String get missing_templates => 'Templates are missing for this preset. Godot validates debug and release templates before exporting.';
	@override String get downloading_templates => 'Installing templates… Follow progress in Tasks.';
	@override String get no_presets => 'No export presets yet';
	@override String get no_presets_hint => 'Open Project → Export in Godot, add a preset, and save it. Refresh this list when it is ready.';
	@override String get open_editor => 'Open in Godot';
	@override String get open_console => 'Open export console';
	@override String get cancel_export => 'Cancel export';
	@override String get running => 'Exporting {{preset}}…';
	@override String get succeeded => 'Export complete';
	@override String get failed => 'Export failed';
	@override String get cancelled => 'Export cancelled';
	@override String get cancel_hint => 'Partial output files may remain in the output folder.';
	@override String get open_folder => 'Open output folder';
	@override String get overwrite_title => 'Replace existing export?';
	@override String get overwrite_description => 'An output file already exists at {{path}}. Replace it with this export?';
	@override String get overwrite => 'Replace and export';
	@override String get run_hint => 'Output streams to its own console tab. Exporting does not change the project\'s play-time statistics.';
	@override String get platform_tools => 'Godot also requires the SDKs, signing settings and export options configured for your target platform.';
	@override String get scan_failed => 'Could not read export presets';
	@override String get start_failed => 'Could not start export: {{error}}';
	@override String get tools_title => 'Tests and lint';
	@override String get tools_no_tests => 'No test framework found. Install GUT or gdUnit4 from the Asset Library to run tests here.';
	@override String get tool_run => 'Run';
	@override String get tool_gut => 'GUT tests';
	@override String get tool_gut_hint => 'Runs your GUT tests headless with the bound Godot version.';
	@override String get tool_gdunit => 'gdUnit4 tests';
	@override String get tool_gdunit_hint => 'Runs the gdUnit4 tests in {{target}} headless.';
	@override String get tool_gdlint => 'gdlint';
	@override String get tool_gdlint_hint => 'Lints GDScript outside addons: {{target}}';
	@override String get tool_gdformat => 'gdformat check';
	@override String get tool_gdformat_hint => 'Checks formatting without changing files: {{target}}';
	@override String get tool_reason_engine_missing => 'Install this project\'s Godot version to run tests.';
	@override String get tool_reason_no_test_folder => 'Add a test or tests folder for gdUnit4.';
	@override String get tool_reason_not_installed => 'Not found on PATH. Install it with: pip install gdtoolkit';
}

// Path: common.project_addons
class _Translations$common$project_addons$ar_MA extends Translations$common$project_addons$en_US {
	_Translations$common$project_addons$ar_MA._(TranslationsArMa root) : this._root = root, super.internal(root);

	final TranslationsArMa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Addons';
	@override String get loading => 'Reading addons…';
	@override String count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} addons installed',
		one: '${count} addon installed',
		two: '${count} addons installed',
		few: '${count} addons installed',
		many: '${count} addons installed',
		other: '${count} addons installed',
	);
	@override String get empty => 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.';
	@override String get check_updates => 'Check for updates';
	@override String get checking => 'Checking…';
	@override String updates_available({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count,
		zero: '${count} updates available',
		one: '${count} update available',
		two: '${count} updates available',
		few: '${count} updates available',
		many: '${count} updates available',
		other: '${count} updates available',
	);
	@override String get all_current => 'No updates found in the Asset Library';
	@override String get enabled => 'Enabled';
	@override String get disabled => 'Disabled';
	@override String get library => 'Library';
	@override String get from_library => 'Asset Library';
	@override String get not_found => 'Not found in the Asset Library';
	@override String get update_to => 'Version {{version}} is available';
	@override String get current => 'Up to date ({{version}})';
	@override String get matched_by_name => 'matched by name to “{{title}}”';
	@override String get update => 'Update';
	@override String get updating => 'Updating…';
	@override String get updated => '{{name}} was updated';
	@override String get confirm_title => 'Update {{name}}?';
	@override String get confirm_description => 'This replaces res://addons/{{folder}} with version {{version}} from the Asset Library. The old folder is moved to the Trash, so any changes you made to the addon are kept there. Close the project in Godot first.';
	@override String get footer_hint => 'Addons installed through GodotHub are matched exactly. Others are matched by name, so check the result before updating.';
}

/// The flat map containing all translations for locale <ar-MA>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsArMa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'changelog.changelog_title' => 'سجل التغييرات',
			'changelog.no_entries' => 'لا توجد أي تغييرات حاليا',
			'changelog.delete_entry_title' => 'هل تريد حذف سجل التغييرات؟',
			'changelog.delete_entry_desc' => 'هذا سيحذف المدخل كليا. لا يمكن التراجع عن هذا الخيار.',
			'changelog.changelog_subtitle' => 'تاريخ التغييرات في GodotHub.',
			'changelog.edit_entry_aria' => 'عدل {{version}}',
			'changelog.delete_entry_aria' => 'احذف {{version}}',
			'changelog.added' => 'مُضاف',
			'changelog.fixed' => 'مُصلّح',
			'changelog.improved' => 'مُحسّن',
			'common.new_project' => 'مشروع جديد',
			'common.import_project' => 'استورد مشروع',
			'common.search' => 'البحث',
			'common.cancel' => 'إلغاء',
			'common.save' => 'احفظ',
			'common.delete' => 'احذف',
			'common.close' => 'أغلق',
			'common.loading' => 'تحميل...',
			'common.retry' => 'أعد المحاولة',
			'common.stop' => 'توقف',
			'common.refresh' => 'أعد التحميل',
			'common.scroll_to_top' => 'عُد للأعلى',
			'common.quick_commands' => 'الأوامر السريعة',
			'common.minimize' => 'أخفي',
			'common.close_sidebar' => 'أغلق الشريط الجانبي',
			'common.star_on_github' => 'نجمة في Github',
			'common.support_dev' => 'ادعم المطور على Patreon. يمكنك إغلاق هذا الخيار في الإعدادات',
			'common.support' => 'الدعم',
			'common.restore' => 'صغِّر',
			'common.maximize' => 'كبِّر',
			'common.importing_project' => 'جاري إستوراد المشروع…',
			'common.importing_version' => 'جاري إستوراد النسخة…',
			'common.scanning_projects' => 'جاري البحث عن المشاريع…',
			'common.scanning_versions' => 'جاري البحث عن الإصدارات…',
			'common.queued' => 'مُنتظر',
			'common.download_queue_move_up' => 'التقديم في قائمة الإنتظار',
			'common.download_queue_move_down' => 'التأخير في قائمة الإنتظار',
			'common.running' => 'قيد التشغيل',
			'common.running_projects_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} projects running', one: '${count} مشروعا شغالا', two: '${count} projects running', few: '${count} projects running', many: '${count} projects running', other: '${count} مشاريع شغالة', ), 
			'common.active' => 'مفعّل',
			'common.done' => 'تم',
			'common.paused' => 'موقوف مؤقتا',
			'common.no_tasks_running' => 'لا توجد مهام قيد التقدم',
			'common.checking_changes' => 'تحقق من التغييرات…',
			'common.cloning' => 'استنساخ',
			'common.clone_import' => 'النسخ و الإستوراد',
			'common.import' => 'استورد',
			'common.syncing' => 'جاري المزامنة…',
			'common.edit_entry' => 'عدل نقطة تغييرات',
			'common.new_entry' => 'نقطة تغييرات جديدة',
			'common.checking_updates' => 'جاري التحقق من التحديثات…',
			'common.up_to_date' => 'محدث بالفعل',
			'common.downloading_update' => 'جاري التنزيل…',
			'common.install_update' => 'ثبت',
			'common.restart_now' => 'أعد التشغيل الآن',
			'common.update_downloaded' => 'تم تنزيل التحديث!',
			'common.restart_to_apply' => 'أعد تشغيل البرنامج لتطبيق التحديث.',
			'common.update_applied_desc' => 'تم تنزيل التحديث و سيتم تثبيته في المرة القادمة التي تفتح فيها البرنامج. المرجوا إغلاق البرنامج و فتحه مجددا لإنهاء التحديث.',
			'common.is_latest' => 'v{{version}} هي أخر نسخة.',
			'common.percent_complete' => '{{percent}}% مكتملة',
			'common.expand_sidebar' => 'وسع الشريط الجانبي',
			'common.collapse_sidebar' => 'أغلق الشريط الجانبي',
			'common.saving' => 'جاري الحفظ…',
			'common.save_changes' => 'احفظ التغييرات',
			'common.add_entry' => 'أضف مدخل',
			'common.scan_for_projects' => 'ابحث عن المشاريع',
			'common.create_workspace' => 'أنشئ بيئة عمل',
			'common.report_a_bug' => 'أبلغ عن مشكلة',
			'common.report_bug' => 'أبلغ عن مشكلة',
			'common.app_error_title' => 'حدث خطأ ما',
			'common.app_error_desc' => 'قد حصل خطأ غير متوقع و لا يمكن العرض. التفاصيل في الأسفل, تأكد من الطرفية (right-click → Inspect) من أجل المتابعة الكاملة للمشكلة.',
			'common.reload' => 'إعادة التحميل',
			'common.view_error_title' => 'This view couldn\'t load',
			'common.view_error_desc' => 'The rest of GodotHub still works. Try loading this view again, or switch to another one.',
			'common.error_details' => 'Technical details',
			'common.remove_folder' => 'أزل المجلد',
			'common.make_this_default' => 'اجعل هذا {{label}}',
			'common.suggested_from_workspaces' => 'مقترح من بيئة عمل أخرى',
			'common.from_workspace' => 'من {{name}}',
			'common.add_folder' => 'أضف مجلدا جديدا',
			'common.default_folder' => 'الإفتراضي',
			'common.default_downloads_go_to' => 'التنزيلات الإفتراضية سوف تكون في "{{path}}"',
			'common.open_terminal' => 'افتح الطرفية',
			'common.downloading_version' => 'جاري تحميل {{version}}',
			'common.downloading_asset' => 'جاري تحميل {{title}}',
			'common.asset_download_failed' => 'فشل تنزيل القالب',
			'common.scan_for_engines' => 'البحث عن المحركات',
			'common.import_version' => 'استورد إصدارا',
			'common.sync_templates_from_directory' => 'زامن القوالب من المجلدات',
			'common.section_navigation' => 'التصفح',
			'common.section_projects' => 'المشاريع',
			'common.section_views' => 'Views',
			'common.section_workspaces' => 'بيئات العمل',
			'common.section_help' => 'المساعدة',
			'common.section_engines' => 'المحركات',
			'common.section_templates' => 'القوالب',
			'common.section_versions' => 'الإصدارات',
			'common.section_news' => 'الأخبار',
			'common.skip_setup' => 'تخطي واجهة الإعداد',
			'common.back' => 'العودة',
			'common.finishing' => 'جاري الإنهاء…',
			'common.get_started' => 'ابدأ',
			'common.scanning' => 'جاري البحث…',
			'common.scan_now' => 'ابحث الآن',
			'common.scan_complete' => 'البحث اكتمل',
			'common.scan_failed' => 'فشل البحث',
			'common.uncategorized' => 'غير مصنف',
			'common.all' => 'الكل',
			'common.no_filter' => 'لا يوجد مرشح',
			'common.cannot_undo' => 'لا يمكن التراجع عن هذا.',
			'common.deleting' => 'جاري الحذف…',
			'common.open_project' => 'افتح المشروع',
			'common.play_project' => 'شغّل مباشرة',
			'common.play_project_tooltip' => 'شغل اللعبة/التطبيق مباشرة هنا دون فتح المشروع.',
			'common.no_version_selected' => 'لا يوجد إصدار محدد',
			'common.open_with_console' => 'افتح مع الطرفية',
			'common.open_folder' => 'افتح المجلد',
			'common.open_in_ide' => 'إفتح في بيئة تطوير (IDE)',
			'common.category' => 'الصنف',
			'common.none' => 'لا أحد',
			'common.project_size' => 'حجم المشروع',
			'common.project_size_scanning' => 'Scanning project files…',
			'common.project_size_empty' => 'No files found',
			'common.launch_arguments' => 'خيارات الإقلاع',
			'common.save_as_template' => 'إحفظ كقالب',
			'common.git' => 'Git',
			'common.add' => 'أضف',
			'common.color_label' => 'اللون',
			'common.icon_label' => 'الأيقونة',
			'common.expand' => 'توسيع',
			'common.collapse' => 'تقليص',
			'common.file_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} ملف', one: '${count} ملف', two: '${count} ملف', few: '${count} ملف', many: '${count} ملف', other: '${count} ملفات', ), 
			'common.folder_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} مجلد', one: '${count} مجلد', two: '${count} مجلد', few: '${count} مجلد', many: '${count} مجلد', other: '${count} مجلدات', ), 
			'common.template_empty' => 'هذا القالب فارغ.',
			'common.categories' => 'التصنيفات',
			'common.category_folders_hint' => 'المشاريع الموجودة داخل مجلدات الفئة تُنسب إليها تلقائيًا.',
			'common.assign_folder' => 'إسناد مجلد',
			'common.assign_folder_to_category' => 'إسناد مجلد إلى {{name}}',
			'common.unassign_folder_aria' => 'إزالة المجلد {{folder}} من هذه الفئة',
			'common.new_category_placeholder' => 'إسم تصنيف جديد…',
			'common.no_categories_yet' => 'لا توجد تصنيفات بعد, أضف واحدا في الأعلى.',
			'common.edit_category' => 'عدل {{name}}',
			'common.delete_category' => 'احذف {{name}}',
			'common.delete_category_title' => 'احذف التصنيف?',
			'common.delete_category_desc' => '"{{name}}" سيُزال. و ستصبح ملفاته بلا تصنيف, لا شيء على جهازك سيُلمس.',
			'common.project_name_label' => 'الإسم',
			'common.folder_name_preview' => 'Dir. Convention: {{name}}',
			'common.folder_name_hint' => 'يُشتق اسم المجلد من اسم المشروع باستخدام اصطلاح التسمية الخاص بك.',
			'common.template_preview_aria' => 'معاينة {{name}}',
			'common.project_location_label' => 'الموقع',
			'common.choose_folder_placeholder' => 'اختر موقعا',
			'common.browse' => 'تصفح',
			'common.blank_template' => 'الإفتراضي',
			'common.template_optional' => 'قالب (اختياري)',
			'common.category_optional' => 'التصينف (اختياري)',
			'common.no_category_label' => 'لا يوجد تصنيف',
			'common.godot_version_label' => 'إصدار Godot',
			'common.no_engine_warning' => 'لا يوجد إصدار محرك مثبت بعد, اختر واحد من قائمة الإصدارات أولا.',
			'common.change_icon' => 'غيير',
			'common.choose_icon' => 'اختر',
			'common.icon_format_desc' => 'SVG, PNG, أو JPG. هي الصيغ الإفتراضية المسموحة للمحرك.',
			'common.other_settings_label' => 'إعدادات أخرى',
			'common.init_git_label' => 'جهِّز مستودع Git',
			'common.init_git_desc' => 'أضف .gitignore و .gitattributes للمشروع, ثم قد بتنفيذ البرنامج الأول على Main.',
			'common.init_git_unavailable' => 'قم بتثبيت Git ثم أعد تشغيل GodotHub لاستخدام هذا.',
			'common.initializing_git' => 'جاري تجهيز Git…',
			'common.git_init_warning_title' => 'تم إنشاء المشروع, Git يحتاج انتباهك',
			'common.git_option_gitignore' => 'Godot .gitignore',
			'common.git_option_gitattributes' => '.gitattributes',
			'common.git_option_readme' => 'README.md',
			'common.git_option_license' => 'الرخصة',
			'common.git_option_no_license' => 'بدون رخصة',
			'common.create_remote_label' => 'أنشئ مستودعا على GitHub/GitLab',
			'common.create_remote_desc' => 'أنشئ مستودعا على حسابك المتصل و ادفع تنفيذ التهيئة.',
			'common.remote_private' => 'خاص',
			'common.remote_public' => 'عام',
			'common.creating_remote_repo' => 'أنشئ مستودعا عن بعد…',
			'common.remote_repo_created_title' => 'تم إنشاء المستودع',
			'common.create_project_done' => 'تم',
			'common.create_project_btn' => 'أنشئ مشروعا',
			'common.creating' => 'جاري الإنشاء…',
			'common.create_project_error' => 'أعط المشروع إسما و مجلد ليوضع فيه.',
			'common.create_workspace_title' => 'بيئة عمل جديدة',
			'common.workspace_name_label' => 'الإسم',
			'common.workspace_name_placeholder' => 'العمل, شخصي, Game Jam…',
			'common.workspace_name_required_error' => 'أعطي بيئة العمل إسما.',
			'common.edit_workspace_title' => 'عدل بيئة العمل',
			'common.cant_delete_only_workspace' => 'لا يمكنك حذف بيئة عملك الوحيدة',
			'common.delete_workspace_title' => 'هل تريد حذف بيئة العمل?',
			'common.delete_workspace_desc' => '"{{name}}" و كل شيء في تابع لها (إعداداتها, مشاريعها, و تصنيفاتها) ستُحذف. الملفات الموجودة على جهاز فعلا لا تلمس أبدا. إصدارات Godot تكون مُشتركة و لا تحذف هي الأخرى.',
			'common.other' => 'أخرى',
			'common.args_label' => 'الخيارات',
			'common.args_placeholder' => 'e.g. --debug --single-window',
			'common.args_suggestions' => 'الإقتراحات',
			'common.args_desc_separate_prefix' => 'افصل بين الخيارات بمساحة. أوامر بقيم مثل',
			'common.args_desc_separate_suffix' => 'استخدم رمزين.',
			'common.args_debug' => '--debug',
			'common.args_debug_desc' => 'شغل مع مصحح أخطاء ملحق',
			'common.args_single_window' => '--single-window',
			'common.args_single_window_desc' => 'أرغم وضع النافذة الواحدة',
			'common.args_opengl3' => '--rendering-driver opengl3',
			'common.args_opengl3_desc' => 'استعمل مشغل الرسوميات OpenGL 3',
			'common.args_vulkan' => '--rendering-driver vulkan',
			'common.args_vulkan_desc' => 'استعمل مشغل الرسوميات Vulkan',
			'common.args_headless' => '--headless',
			'common.args_headless_desc' => 'شغل بدون نافذة',
			'common.args_verbose' => '--verbose',
			'common.args_verbose_desc' => 'سجل مخرجات تصحيح الأخطاء التفصيلية',
			'common.args_editor' => '--editor',
			'common.args_editor_desc' => 'افتح البرنامج (same as -e)',
			'common.args_build_solutions' => '--build-solutions',
			'common.args_build_solutions_desc' => 'ابني برامج C# عند الفتح',
			'common.args_gpu_index' => '--gpu-index 1',
			'common.args_gpu_index_desc' => 'Use GPU index 1 (بطاقة الرسومات المخصصة)',
			'common.sort_categories' => 'التصنيفات',
			'common.sort_recent' => 'مفتوح مؤخرا',
			'common.sort_manual' => 'يدوي',
			'common.sort_name_asc' => 'الإسم (A–Z)',
			'common.sort_name_desc' => 'الإسم (Z–A)',
			'common.sort_created_desc' => 'التاريخ المضاف (الأحدث)',
			'common.sort_created_asc' => 'التاريخ المضاف (الأقدم)',
			'common.sort_time_desc' => 'الوقت الإجمالي',
			'common.filter' => 'المرشح',
			'common.no_templates_yet' => 'لا توجد قوالب بعد. اضغط بزر الفأرة الأيمن أو افتح قائمة "المزيد" ثم اختر <1 > احفظ القالب </1> لإنشاء واحد.',
			'common.godot' => 'Godot',
			'common.delete_template' => 'احذف قالب {{name}}',
			'common.news_subtitle' => 'المنشورات الأخيرة من مدونة Godot الرسمية.',
			'common.news_cached' => 'لا يمكن الوصول لـ godotengine.org, أظهر المقالات المحفوظة من أخر مرة.',
			'common.news_error' => 'لا يمكن تحميل أخبار Godot.',
			'common.news_empty' => 'لا يوجد أخبار لعرضها حاليا.',
			'common.show_more' => 'أظهر المزيد',
			'common.try_again' => 'أعد المحاولة مرة أخرى',
			'common.asset_store_title' => 'متجر الأصول',
			'common.news_count' => 'منشور(منشورات)',
			'common.asset_store_count_plural' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'لا توجد أصول', one: 'أصل', two: 'أصل(أصول)', few: 'أصل(أصول)', many: 'أصل(أصول)', other: 'أصول', ), 
			'common.asset_store_count' => 'أصل(أصول)',
			'common.settings_title' => 'الإعدادات',
			'common.no_templates_match' => 'لم يتم العثور على قالب',
			'common.no_projects_match' => 'لم يتم العثور على المشروع',
			'common.more_import_options' => 'المزيد من خيارات الإستوراد',
			'common.clone_import_repo' => 'استنسخ و استورد من المستودع',
			'common.manage_categories' => 'أدر التصنيفات',
			'common.hide_category' => 'Hide Category',
			'common.category_hidden_toast' => '"{{name}}" hidden. Restore it from Hidden Categories.',
			'common.hidden_categories' => 'Hidden Categories',
			'common.hidden_categories_hint' => 'Those categories and their projects stay out of the way. Unhide one to bring it back.',
			'common.hidden_category_projects' => '{{count}} project(s)',
			'common.unhide' => 'Unhide',
			'common.unhide_category_aria' => 'Unhide {{name}}',
			'common.search_projects_placeholder' => 'ابحث عن المشاريع بالإسم أو المسار…',
			'common.clear_search' => 'امسح البحث',
			'common.search_filter_title' => 'Filter projects by',
			'common.search_slash_hint' => 'Type / to filter by name, tags, categories and more',
			'common.search_filter_name' => 'Name',
			'common.search_filter_tag' => 'Tag',
			'common.search_filter_version' => 'Engine version',
			'common.search_filter_path' => 'Path',
			'common.search_filter_pinned_yes' => 'Pinned only',
			'common.search_filter_pinned_no' => 'Not pinned',
			'common.search_filter_no_matches' => 'No matching filters',
			'common.search_filter_no_values' => 'No matching values',
			'common.sort' => 'رتب…',
			'common.view_list' => 'List',
			'common.view_grid' => 'Grid',
			'common.view_kanban' => 'Kanban',
			'common.no_projects_yet' => 'لا شيء هنا بعد. أنشئ مشروعا جديدا أو استورد واحدا لديك بالفعل.',
			'common.pinned_section' => 'مثبت',
			'common.set_category' => 'عيين تصنيفا…',
			'common.clear_selection' => 'ألغي الإختيار',
			'common.starting' => 'جاري البدأ…',
			'common.app_loading' => 'جاري التحميل…',
			'common.changelog_version_label' => 'الإصدار',
			'common.changelog_version_placeholder' => 'v1.0.0',
			'common.changelog_date_label' => 'التاريخ',
			'common.changelog_date_placeholder' => '2026-07-13',
			'common.changelog_what_changed' => 'ماذا تغيير',
			'common.changelog_add_line' => 'أضف سطرا',
			'common.changelog_remove_line_aria' => 'أزل سطرا',
			'common.changelog_placeholder_note' => 'تمت إضافة القدرة على إعادة ترتيب المشاريع عن طريق السحب و الإفلات',
			'common.changelog_error_no_version' => 'عيين إصدارا للمدخل.',
			'common.changelog_known_issues' => 'المشاكل المعروقة',
			'common.changelog_known_issues_none' => 'لا توجد مشاكل معروفة لهذه الإصدارة.',
			'common.changelog_known_issue_placeholder' => 'اشرح المشكلة المعروفة...',
			'common.changelog_remove_known_issue_aria' => 'أزل المشكلة المعروفة',
			'common.changelog_add_known_issue' => 'أضف مشكلة معروفة',
			'common.changelog_generate_from_git' => 'ولّد من Git',
			'common.changelog_draft_title' => 'ملاحظات الإصدار من Git',
			'common.changelog_draft_from' => 'من',
			'common.changelog_draft_to' => 'إلى',
			'common.changelog_draft_generate' => 'Generate draft',
			'common.changelog_draft_use' => 'Use Draft',
			'common.changelog_draft_commits' => '{{count}} commit(s)',
			'common.changelog_draft_include' => 'Include in draft',
			'common.changelog_draft_none' => 'No commits found in this range.',
			'common.template_search_placeholder' => 'جاري البحث عن القوالب…',
			'common.template_delete_title' => 'هل تريد القالب?',
			'common.template_delete_desc' => '"{{name}}" will be permanently removed.',
			'common.templates_tab_local' => 'القوالب المحلية',
			'common.templates_tab_asset' => 'مكتبة الأصول',
			'common.asset_search_placeholder' => 'جاري البحث عن أصول…',
			'common.asset_all_versions' => 'كل الإصدارات',
			'common.asset_result_count' => '{{count}} نتيجة',
			'common.asset_load_error' => 'Couldn\'t load the Asset Library. Check your connection and try again.',
			'common.asset_no_results' => 'No assets found. Try a different search.',
			'common.asset_by_author' => 'بواسطة {{author}}',
			'common.asset_open_page' => 'افتح في المتصف',
			'common.asset_install' => 'ثبت',
			'common.asset_install_inside' => 'ثبت',
			'common.asset_installing' => 'جاري التثبيت…',
			'common.asset_installed' => 'مُثبت',
			'common.asset_prev_page' => 'الصفحة السابقة',
			'common.asset_next_page' => 'الصفحة التالية',
			'common.asset_page_x_of_y' => 'الصفحة {{page}} من إجمالي {{total}}',
			'common.template_your_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'قالب(قوالب)', one: 'قالب', two: 'قالب(قوالب)', few: 'قالب(قوالب)', many: 'قالب(قوالب)', other: 'قوالب', ), 
			'common.template_imported_count' => 'مستوردة {{count}}',
			'common.template_updated_count' => 'محدثة {{count}}',
			'common.template_removed_count' => 'مزالة {{count}}',
			'common.asset_source_all' => 'كل المصادر',
			'common.asset_source_library' => 'مكتبة أصول قديمة',
			'common.asset_source_store' => 'مكتبة أصول حديثة',
			'common.asset_store_relevance' => 'Relevance',
			'common.asset_store_updated_new' => 'Newest updated',
			'common.asset_store_updated_old' => 'Oldest updated',
			'common.asset_store_rating_high' => 'Top rated',
			'common.asset_store_rating_low' => 'Lowest rated',
			'common.asset_download_outside' => 'حمل خارجا',
			'common.asset_downloaded' => 'محمل',
			'common.asset_downloaded_to' => 'محمل في',
			'common.asset_download_error' => 'Couldn\'t download the asset. Check your connection and try again.',
			'common.asset_install_modal_title' => 'ثبت {{title}}',
			'common.asset_install_tab_project' => 'داخل مشروع',
			'common.asset_install_tab_template' => 'داخل قالب',
			'common.asset_install_search_projects' => 'جاري البحث عن المشاريع…',
			'common.asset_install_no_projects' => 'لا يوجد أي مشروع بعد. أنشئ أو استورد واحدا أولا.',
			'common.asset_install_no_templates' => 'لا توجد قوالب محفوظة بعد.',
			'common.asset_install_into' => 'ثبت في {{name}}',
			'common.asset_install_success_project' => 'تم التثبيت في {{target}}',
			'common.asset_install_success_template' => 'تمت إضافته للقالب {{target}}',
			'common.asset_new_template_btn' => 'احفظ كقالب جديد',
			'common.asset_new_template_hint' => 'Creates a new template from this project asset',
			'common.onboarding_keep_organized' => 'Keep every project organized in one place.',
			'common.onboarding_download_manage' => 'Download and manage Godot engine builds.',
			'common.onboarding_stay_current' => 'Stay current with what\'s new in Godot.',
			'common.onboarding_projects_title' => 'Where are your projects?',
			'common.onboarding_projects_desc' => 'Add folders GodotHub should scan for existing Godot projects at startup. Star one to make it the default save location when you create a new project. You can skip this and add folders later in Settings.',
			'common.onboarding_versions_title' => 'Where do Godot versions live?',
			'common.onboarding_versions_desc' => 'Add folders GodotHub should scan for installed Godot engine executables. Star one to set it as the download location for new versions you install through the Versions tab.',
			'common.onboarding_templates_title' => 'Template projects directory',
			'common.onboarding_templates_desc' => 'Optionally set a folder where you keep reusable project templates. Any subfolder inside it will be imported as templates on finish, so they show up when you create new projects. You can also save individual projects as templates anytime from the Projects view, or import more later from the Templates tab.',
			'common.onboarding_categories_title' => 'Organize with categories',
			'common.onboarding_categories_desc_full' => 'Categories are folders for your project list, file projects under them however makes sense to you. Add a few starters or make your own; you can rename, reorder, or delete these anytime from Settings.',
			'common.onboarding_custom_category_placeholder' => 'إسم تصنيف مخصص…',
			'common.onboarding_your_categories' => 'تصنيفاتك',
			'common.onboarding_customize_title' => 'اجعله مِلكك',
			'common.onboarding_customize_desc' => 'Pick an accent and background color to start. Corner roundness, density, text size, and light/dark mode are all in Settings whenever you want to fine-tune further.',
			'common.onboarding_finish_title' => 'You\'re all set',
			'common.onboarding_finish_desc' => 'GodotHub is ready to go. You can revisit any of this, folders, categories, and appearance, from the Settings tab at any time.',
			'common.onboarding_setting_up_title' => 'تجهيز بعض الأمور',
			'common.onboarding_setting_up_desc' => 'Setting up your library… scanning folders for projects and Godot versions. This only happens once, and it won\'t take long.',
			'common.skipped' => 'متخطى',
			'common.onboarding_continue' => 'استمرار',
			'common.onboarding_accent_color' => 'اللون الأساسي',
			'common.onboarding_bg_color' => 'لون الخلفية',
			'common.onboarding_corner_radius' => 'دوران الزوايا',
			'common.onboarding_discord_rpc' => 'ميزة \'Rich Presence\' في Discord',
			'common.onboarding_discord_rpc_desc' => 'Show what you\'re doing in GodotHub on your Discord profile.',
			'common.version_search_placeholder' => 'بحث عن الإصدارات…',
			'common.version_no_installed' => 'لا توجد إصدارات مثبتة. Download a version from below or drag and drop your existing version folder here.',
			'common.version_save_name_aria' => 'احفظ الإسم',
			'common.version_rename_aria' => 'أعد تسمية الإصدار',
			'common.version_mono_badge' => 'Mono',
			'common.version_uninstall_title' => 'هل تريد إلغاء تثبيت هذا الإصدار',
			'common.version_uninstall_desc' => '"{{tag}}" and its files will be moved to your system\'s Trash / Recycle Bin. You can reinstall it later if needed.',
			'common.version_uninstall_confirm' => 'إلغاء التثبيت',
			'common.project_remove_title' => 'هل تريد إزالته من المكتبة?',
			'common.project_remove_desc' => '"{{name}}" will be removed from GodotHub\'s list. Its files stay on disk untouched, you can import it again anytime.',
			'common.project_delete_title' => 'هل تريد النقل لسلة المهملات؟',
			'common.project_delete_desc' => '"{{name}}" and everything inside it will be moved to your system\'s Trash / Recycle Bin. You can restore it later if needed.',
			'common.project_delete_confirm' => 'انقل لسلة المهملات',
			'common.project_template_name_label' => 'إسم القالب',
			'common.project_template_desc_label' => 'الوصف',
			'common.project_template_desc_placeholder' => 'ماذا يتضمن هذا القالب؟',
			'common.project_save_template_btn' => 'احفظ القالب',
			'common.template_saved_toast' => 'Template saved.',
			'common.project_select_aria' => 'اختر المشروع',
			'common.project_deselect_aria' => 'ألغي حفظ المشروع',
			'common.select_all_visible' => 'Select all visible',
			'common.selected_count' => '{{count}} selected',
			'common.bulk_launch' => 'Launch',
			'common.bulk_pin' => 'Pin',
			'common.bulk_remove' => 'أزل',
			'common.bulk_remove_title' => 'Remove {{count}} projects from library?',
			'common.bulk_remove_desc' => 'The selected projects will be removed from your library. Their files will stay on disk.',
			'common.bulk_delete_title' => 'Delete {{count}} projects?',
			'common.bulk_delete_desc' => 'The selected project files will be permanently moved to the Trash. This cannot be undone.',
			'common.project_pin_aria' => 'ثبت المشروع',
			'common.project_unpin_aria' => 'ألغي تثبيت المشروع',
			'common.time_today' => 'اليوم',
			'common.time_this_week' => 'هذا الأسبوع',
			'common.time_all_time' => 'الوقت الإجمالي',
			'common.time_tracked_title' => 'الوقت المتتبع',
			'common.time_weekly_chart' => 'أخر 7 أيام',
			'common.time_week_total' => '{{total}} هذا الأسبوع',
			'common.time_weekly_empty' => 'لا يوجد وقت متتبع في أخر 7 أيام.',
			'common.project_more_aria' => 'المزيد',
			'common.customize_card_section' => 'Project Card',
			'common.customize_card_show_size' => 'أظهر حجم المشروع',
			'common.customize_card_show_time' => 'أظهر الوقت متتبع',
			'common.customize_card_show_session_timer' => 'Show Session Timer',
			'common.customize_card_blur_path' => 'أخفي مجلد المشروع',
			'common.customize_card_show_path' => 'أظهر مجلد المشروع',
			'common.customize_card_show_tags' => 'أظهر الوسوم',
			'common.customize_card_show_last_opened' => 'أظهر أخر مشروع فتح',
			'common.customize_card_show_play' => 'أظهر زر التشغيل المباشر',
			'common.customize_card_show_console' => 'أظهر زر التشغيل مع الطرفية',
			'common.project_card_remove_library' => 'أزل من المكتبة',
			'common.project_card_delete_files' => 'احذف الملفات',
			'common.manage_tags' => 'أدر الوسوم',
			'common.tag_input_placeholder' => 'وسم جديد…',
			'common.tag_already_exists' => 'يوجد وسم بهذا الإسم فعلا.',
			'common.tag_rename_hint' => 'اضغط لإعادة التسمية',
			'common.tag_rename_aria' => 'أعد تسمية الوسم',
			'common.show_more_tags' => 'أظهر وسوم أكثر',
			'common.show_fewer_tags' => 'أظهر وسوم أقل',
			'common.clear_tag_filter' => 'Clear tag filter',
			'common.saving_tags' => 'جاري حفظ الوسوم…',
			'common.tag_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} وسم(وسوم)', one: '${count} وسم', two: '${count} وسم(وسوم)', few: '${count} وسم(وسوم)', many: '${count} وسم(وسوم)', other: '${count} وسوم', ), 
			'common.no_tags' => 'لا توجد وسوم بعد',
			'common.bug_report_describe_label' => 'ماذا حدث?',
			'common.bug_report_describe_placeholder' => 'What were you doing when the bug appeared? Add steps to reproduce and what you expected vs. what actually happened.',
			'common.bug_report_diagnostics_label' => 'Diagnostic info',
			'common.bug_report_diagnostics_hint' => 'Auto-collected · included in the report',
			'common.bug_report_copied' => 'منسوخ!',
			'common.bug_report_copy_log' => 'انسخ السجل',
			'common.bug_report_download_log' => 'حمل السجل',
			'common.bug_report_open_github' => 'افتح قائمة المشاكل في Github',
			'common.check_updates_title_modal' => 'تحقق من التحديثات',
			'common.check_updates_version_available' => 'الإصدار {{version}} متوفر',
			'common.check_updates_ask_download' => 'هل تريد أن تحمله و تثبته الآن؟',
			'common.check_updates_release_notes' => 'ملاحظات الإصدار',
			'common.check_updates_failed' => 'فشل التحقق من التحديثات',
			'common.check_updates_rate_limited' => 'GitHub rate limit reached',
			'common.check_updates_token_rejected' => 'GitHub token rejected',
			'common.check_updates_rate_limited_hint' => 'GitHub only allows 60 anonymous requests per hour, shared with everyone on your network. Adding a personal access token in Settings raises this to 5,000 per hour and is also used for fetching Godot versions.',
			'common.check_updates_rate_limited_token_hint' => 'Your saved GitHub token was rejected. It may have expired or been revoked. Test it in Settings and replace it if needed.',
			'common.check_updates_add_token' => 'أضف رمز GitHub',
			'common.check_updates_open_token_settings' => 'افتح إعدادات الرمز (Token)',
			'common.check_updates_preview_badge' => 'معاينة',
			'common.check_updates_portable_title' => 'يتطلب التحديث اليدوي',
			'common.check_updates_portable_desc' => 'Portable installs cannot auto-update. Download the latest version from GitHub and replace the existing files.',
			'common.check_updates_download_from_github' => 'حمل من GitHub',
			'common.preview_state_checking' => 'التحقق',
			'common.preview_state_available' => 'المتوفر',
			'common.preview_state_downloading' => 'التحميل',
			'common.preview_state_done' => 'تم',
			'common.preview_state_uptodate' => 'مُحدث',
			'common.preview_state_error' => 'خطأ',
			'common.preview_state_portable' => 'Portable',
			'common.preview_update_modal' => 'Preview Update Modal',
			'common.clone_repo_title' => 'استنسخ المستودع',
			'common.clone_repo_url_label' => 'انسخ رابط المستودع',
			'common.clone_repo_url_placeholder' => 'https://github.com/user/my-game.git',
			'common.clone_repo_error_url' => 'Please enter a repository URL.',
			'common.clone_repo_error_location' => 'Please choose where to clone the repository.',
			'common.clone_repo_open_after' => 'Open it right after importing',
			'common.clone_repo_browse_repos' => 'تصفح مستودعاتك',
			'common.clone_repo_url_manual' => 'الصق الرابط يدويا',
			'common.clone_repo_search_repos' => 'ابحث في مستودعاتك...',
			'common.clone_repo_no_repos_found' => 'No repositories match your search.',
			'common.clone_repo_loading_repos' => 'جاري تحميل المستودعات...',
			'common.clone_repo_load_error' => 'Failed to load repositories.',
			'common.clone_repo_select' => 'اختر',
			'common.clone_repo_no_account' => 'No GitHub or GitLab account connected. Use a URL to clone instead.',
			'common.clone_repo_repos_loaded' => 'تم تحميل المستودعات',
			'common.load_more' => 'حمل المزيد',
			'common.git_uncommitted' => 'غير منفذ',
			'common.git_clean' => 'امسح',
			'common.task_tray_title' => 'المهام',
			'common.task_tray_empty' => 'لا مهام مشغلة حاليا',
			'common.task_tray_active_count' => '{{active}} مشغلة, {{recent}} الأخيرة',
			'common.task_tray_only_recent' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} مهمة أخيرة', one: '${count} المهمة الأخيرة', two: '${count} مهمة أخيرة', few: '${count} مهمة أخيرة', many: '${count} مهمة أخيرة', other: '${count} المهام الأخيرة', ), 
			'common.task_tray_aria' => 'المهام',
			'common.task_tray_auto_dismiss' => 'Completed auto-dismiss',
			'common.task_tray_dismiss' => 'متجاهلة {{count}}',
			'common.task_error_status' => 'خطأ',
			'common.command_palette_title' => 'Command Palette',
			'common.command_palette_placeholder' => 'Search commands, projects, engines, settings…',
			'common.command_palette_no_results' => 'لا توجد نتائج متوافقة',
			'common.command_palette_navigate' => 'تصفح',
			'common.command_palette_escape' => 'Esc',
			'common.setting_token_placeholder' => 'ghp_xxxxxxxxxxxxxxxxxxxx',
			'common.setting_project_scan_dirs' => 'Scan Project Folders',
			'common.setting_version_scan_dirs' => 'Scan Version Folders',
			'common.setting_default_project_location' => 'Default Project Location Setting',
			'common.setting_download_dir' => 'Download Versions Location Setting',
			'common.setting_scan_depth' => 'Scan Depth',
			'common.setting_icon_scan_depth' => 'Project Icon Search Depth',
			'common.setting_download_concurrency' => 'التنزيلات المتتالية',
			'common.setting_close_on_project_open' => 'أغلق عن فتح المشروع',
			'common.setting_minimize_to_tray' => 'أخفي لشريط المهام',
			'common.setting_reopen_after_godot_closes' => 'أعد الفتح عند إغلاق Godot',
			'common.setting_auto_scan_on_startup' => 'البحث عند التلقائي عند تشغيل التطبيق',
			'common.setting_workspaces_enabled' => 'Use Workspaces',
			'common.setting_directory_naming_convention' => 'Directory Naming Convention',
			'common.setting_git_init_new_projects' => 'Initialize Git for New Projects',
			'common.setting_tooltip_delay' => 'Tooltip Delay',
			'common.setting_command_palette_keybind' => 'Command Palette Shortcut',
			'common.setting_tray_recent_projects_count' => 'Tray Recent Projects',
			'common.setting_last_opened_time_format' => 'Time Format',
			'common.setting_last_opened_date_format' => 'Date Format',
			'common.setting_theme_mode' => 'السمة',
			'common.setting_accent_color' => 'ألوان الهوية',
			_ => null,
		} ?? switch (path) {
			'common.setting_background_color' => 'لون الخلفية',
			'common.setting_corner_radius' => 'انحناء الزوايا',
			'common.setting_ui_density' => 'UI Density',
			'common.setting_font_scale' => 'حجم الخط',
			'common.setting_animation_intensity' => 'Animation Intensity',
			'common.setting_view_entrance' => 'View Entrance Animation',
			'common.setting_custom_css' => 'Custom CSS',
			'common.setting_project_icon_opacity' => 'Project Icon Opacity',
			'common.setting_show_scrollbars' => 'Show Scrollbar',
			'common.setting_setup_wizard' => 'Setup Wizard',
			'common.setting_reset_settings' => 'Reset Settings',
			'common.setting_delete_app_data' => 'Delete App Data',
			'common.setting_check_updates' => 'Check for Updates',
			'common.setting_show_support_button' => 'Show Support Button',
			'common.setting_show_star_button' => 'Show Star Button',
			'common.setting_discord_rpc_enabled' => 'Discord Rich Presence',
			'common.setting_discord_app_id' => 'Discord Application ID',
			'common.setting_discord_rpc_show_projects' => 'Discord Show Project Names',
			'common.setting_discord_rpc_excluded_projects' => 'Discord Excluded Projects',
			'common.setting_discord_rpc_project_presences' => 'Discord Custom Presence',
			'common.active_workspace' => '{{name}} (مفعّل)',
			'common.current_workspace' => 'بيئة العمل الحالية',
			'common.switch_workspace' => 'بدل بيئة العمل',
			'common.opened_recently' => 'مفتوحة {{label}}',
			'common.recent_section' => 'الأخيرة',
			'common.installed_versions_section' => 'الإصدارات المثبتة',
			'common.settings_label' => 'الإعدادات → {{tab}}',
			'common.remove_category_aria' => 'أزل {{name}}',
			'common.git_remove_remote' => 'Remove remote',
			'common.git_commit_placeholder' => 'رسالة التنفيذ…',
			'common.restart_required_title' => 'Restart required',
			'common.restart_required_desc' => 'This change requires GodotHub to restart to take full effect. The setting has been saved and will apply when you relaunch the app.',
			'common.found_dismissed_title' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} previously removed projects found', one: 'Previously removed project found', two: '${count} previously removed projects found', few: '${count} previously removed projects found', many: '${count} previously removed projects found', other: '${count} previously removed projects found', ), 
			'common.found_dismissed_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', one: 'Scanner found 1 project that you previously removed from the library. Would you like to re-add it?', two: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', few: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', many: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', other: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', ), 
			'common.readd_all' => 'Re-add All',
			'common.skip_all' => 'تخطي الكل',
			'common.project_already_open_title' => 'المشروع مفتوح بالفعل',
			'common.project_already_open_desc' => '{{name}} is already running. Opening it again launches a second editor instance. Open anyway?',
			'common.project_open_anyway' => 'افتح على أي حال',
			'common.git_sidebar' => 'Git sidebar',
			'common.asset_duplicate_title' => 'هذا القالب مثبت بالفعل',
			'common.asset_duplicate_desc' => '"{{name}}" is already in your templates. Install a duplicate anyway?',
			'common.empty_category' => 'تصنيف فارغ',
			'common.release_to_drop' => 'أفلت للإسقاط',
			'common.preview_release_notes' => '## What\'s new in v1.0.0 - The Preview Update\\n\\n## New\\n\\n- Revamped the Check for Updates modal with structured release notes\\n- Added screen reader announcements with an Accessibility settings tab\\n\\n## Fixes\\n\\n- Fixed a crash when switching workspaces with pinned projects\\n- Fixed update checks failing silently when GitHub rate limits are hit\\n\\n## Improvements\\n\\n- Faster startup times across all platforms\\n- Reworked workspace modals with compact style pickers\\n\\n## Known Issues\\n\\n- Linux OS: AppImage won\'t work on some distros, use the .rpm or .deb package instead\\n- Windows: the taskbar may briefly show a duplicate icon until the app restarts',
			'common.preview_error' => 'Preview error: GitHub API rate limit reached (HTTP 403). Add a token in Settings to keep checking.',
			'common.bug_report_system' => 'النظام',
			'common.bug_report_version' => 'الإصدار',
			'common.bug_report_date' => 'التاريخ',
			'common.bug_report_os' => 'نظام التشغيل',
			'common.bug_report_platform' => 'المنصة',
			'common.bug_report_language' => 'اللغة',
			'common.bug_report_cpu_cores' => 'أنوية المعالج',
			'common.bug_report_ram' => 'ذاكرة الوصول العشوائي (RAM)',
			'common.bug_report_screen' => 'الشاشة',
			'common.bug_report_gpu' => 'المعالج الرسومي (GPU)',
			'common.bug_report_user_agent' => 'وكيل المستخدم',
			'common.bug_report_recent_errors' => 'الأخطاء الأخيرة',
			'common.bug_report_none_captured' => 'غير مُلتقطة',
			'common.bug_report_description' => 'الوصف',
			'common.bug_report_no_description' => 'لا يوجد وصف مرفق',
			'common.unknown' => 'غير معروف',
			'common.gpu_webgl_unavailable' => 'WebGL غير متوفر',
			'common.gpu_info_unavailable' => 'معلومات البطاقة الرسومية غير متوفرة',
			'common.update_available' => 'تحديث جديد',
			'common.dismiss' => 'تجاهل',
			'common.system_language' => 'لغة النظام',
			'common.category_empty_hint' => 'أنشئ واحدا في الأعلى لترتيب مشاريعك',
			'common.contributor_pr_merged' => 'مُدمج',
			'common.contributor_pr_open' => 'مفتوح',
			'common.contributor_pr_closed' => 'مُغلق',
			'common.contributor_pr_loading' => 'جاري تحميل طلبات السحب (PRs)...',
			'common.contributor_pr_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} pull requests', one: '${count} طلب سحب', two: '${count} pull requests', few: '${count} pull requests', many: '${count} pull requests', other: '${count} طلبات سحب', ), 
			'common.contributor_pr_load_failed' => 'فشل تحميل طلبات السحب.',
			'common.contributor_pr_network_hint' => 'تحقق من إتصالك.',
			'common.contributor_pr_empty' => 'لا يوجد أي طلبات سحب.',
			'common.theme_presets_section' => 'Theme presets',
			'common.all_categories' => 'كل التصنيفات',
			'common.clear_category_filter' => 'امسح تصنيفات الترشيح',
			'common.filter_by_category' => 'مرشح بالتصنيفات',
			'common.theme_dark' => 'مظلم',
			'common.theme_light' => 'مضيء',
			'common.bulk_tags' => 'الوسوم',
			'common.bulk_tags_title' => 'عدل الوسوم',
			'common.add_tag' => 'أضف وسما',
			'common.remove_tag' => 'أزل وسما',
			'common.no_common_tags' => 'لا توجد وسوم على المشاريع المختارة بعد.',
			'common.tags_added_to_selection' => 'تمت إضافة {{count}} وسم من المشاريع.',
			'common.tags_removed_from_selection' => 'تمت إزالة {{count}} وسم من المشاريع.',
			'common.removed_from_library' => 'تمت إزالة {{count}} مشروعا من المكتبة.',
			'common.undo' => 'تراجع',
			'common.duplicate_project_title' => 'انسخ المشروع',
			'common.copy_suffix' => 'نسخة',
			'common.duplicate' => 'انسخ',
			'common.destination_folder' => 'مسار المجلد',
			'common.new_project_name' => 'إسم المشروع',
			'common.project_duplicated' => 'تم نسخ المشروع.',
			'common.notification_version_installed' => 'Godot {{tag}} مثبت',
			'common.notification_asset_installed' => '{{title}} مثبت',
			'common.notification_clone_done' => 'تم استنساخ و استوراد المستودع',
			'common.console_title' => 'الطرفية',
			'common.console_finished' => 'Finished',
			'common.console_exit_ok' => 'Exited cleanly',
			'common.console_exit_code' => 'Exit code {{code}}',
			'common.console_clear' => 'Clear output',
			'common.console_copy' => 'Copy output',
			'common.console_minimize' => 'Minimize to a pill',
			'common.console_waiting' => 'Waiting for output…',
			'common.console_empty' => 'No output was captured.',
			'common.console_trimmed' => '{{count}} older line(s) are hidden, copy or clear to manage the buffer.',
			'common.console_crash_hint' => 'Godot exited with code {{code}}. The output above is kept so you can read it.',
			'common.console_filter_errors' => 'Errors',
			'common.console_filter_warnings' => 'Warnings',
			'common.console_filter_info' => 'Info',
			'common.console_no_matches' => 'No lines match the filters ({{count}} hidden).',
			'common.console_pill_hint' => 'Click to reopen the console, drag to move it.',
			'common.console_resumed_hint' => 'This project kept running after GodotHub closed, its output is still being captured below.',
			'common.console_previous_hint' => 'Output kept from the previous session.',
			'common.project_card_version_unavailable' => 'Godot {{version}} is not installed. Select an installed version to launch this project.',
			'common.project_card_total_time' => 'Total time: {{time}}',
			'common.project_card_last_opened' => 'Last opened: {{date}}',
			'common.project_card_more_tags' => 'Show {{count}} more tags',
			'common.downloading_export_templates' => 'Downloading export templates for {{tag}}',
			'common.export_templates_verifying' => 'Verifying download…',
			'common.export_templates_extracting' => 'Installing templates…',
			'common.project_doctor.title' => 'Project Doctor',
			'common.project_doctor.scanning' => 'Checking this project…',
			'common.project_doctor.scan_failed' => 'Could not check this project',
			'common.project_doctor.run_again' => 'Run checks again',
			'common.project_doctor.summary_errors' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} issues need attention', one: '${count} issue needs attention', two: '${count} issues need attention', few: '${count} issues need attention', many: '${count} issues need attention', other: '${count} issues need attention', ), 
			'common.project_doctor.summary_warnings' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} warnings to review', one: '${count} warning to review', two: '${count} warnings to review', few: '${count} warnings to review', many: '${count} warnings to review', other: '${count} warnings to review', ), 
			'common.project_doctor.summary_ready' => 'No blocking issues found',
			'common.project_doctor.summary_counts' => '{{passed}} checks passed · {{findings}} findings',
			'common.project_doctor.passed_checks' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} passed checks', one: '${count} passed check', two: '${count} passed checks', few: '${count} passed checks', many: '${count} passed checks', other: '${count} passed checks', ), 
			'common.project_doctor.local_checks' => 'Checks run locally. Fixes to settings save a backup first.',
			'common.project_doctor.fix_complete' => 'Fix applied. Project checks updated.',
			'common.project_doctor.templates_downloading' => 'Downloading selected templates. Progress and cancellation are also available in Tasks.',
			'common.project_doctor.version_queued' => 'Engine download queued. Follow its progress in Tasks.',
			'common.project_doctor.version_queued_short' => 'Download queued',
			'common.project_doctor.version_asset_unavailable' => 'No matching download was found for this version and platform. Open Versions to install or locate the engine.',
			'common.project_doctor.severity_ok' => 'Passed',
			'common.project_doctor.severity_info' => 'Note',
			'common.project_doctor.severity_warning' => 'Warning',
			'common.project_doctor.severity_error' => 'Needs attention',
			'common.project_doctor.category_engine' => 'Engine and compatibility',
			'common.project_doctor.category_templates' => 'Export templates',
			'common.project_doctor.category_cache' => 'Import cache',
			'common.project_doctor.category_scenes' => 'Main scene',
			'common.project_doctor.category_addons' => 'Editor addons',
			'common.project_doctor.category_git' => 'Version control',
			'common.project_doctor.category_exports' => 'Export presets',
			'common.project_doctor.category_registrations' => 'Project registration',
			'common.project_doctor.action_choose_version' => 'Choose installed version',
			'common.project_doctor.action_install_version' => 'Install bound version',
			'common.project_doctor.action_manage_versions' => 'Manage engine versions',
			'common.project_doctor.action_templates' => 'Choose export templates',
			'common.project_doctor.action_clear_cache' => 'Move cache to Trash',
			'common.project_doctor.action_disable_addon' => 'Remove missing addon entry',
			'common.project_doctor.action_enable_addon' => 'Enable addon',
			'common.project_doctor.action_add_ignores' => 'Add ignore rules',
			'common.project_doctor.action_untrack_metadata' => 'Stop tracking local metadata',
			'common.project_doctor.action_track_lfs' => 'Track file with Git LFS',
			'common.project_doctor.action_remove_registration' => 'Remove registration',
			'common.project_doctor.action_open_editor' => 'Open in Godot',
			'common.project_doctor.action_open_presets' => 'Review export presets in IDE',
			'common.project_doctor.action_open_addons' => 'Review addons in IDE',
			'common.project_doctor.confirm_clear_cache' => 'Move this project\'s .godot folder to the system Trash? Close the project in Godot first. Godot will reimport assets and rebuild editor state the next time it opens.',
			'common.project_doctor.confirm_enable_addon' => 'Enable this editor addon? Its script will run the next time you open the project in Godot. A backup of project.godot is saved first.',
			'common.project_doctor.confirm_untrack_metadata' => 'Remove .godothub.json from Git\'s index while keeping your local file? This stages its removal for your next commit. Existing commits and history stay unchanged.',
			'common.project_doctor.confirm_track_lfs' => 'Add a Git LFS rule for this file? Git LFS must be installed. This changes .gitattributes; re-add the file in Git to convert its next revision. Existing history stays unchanged.',
			'common.project_doctor.confirm_remove_registration' => 'Remove this library registration? Project files stay on disk. The registry is backed up first, and you can import the folder again.',
			'common.project_doctor.version_unbound_title' => 'No engine version is bound',
			'common.project_doctor.version_unbound_description' => 'Choose an installed engine to open and run this project.',
			'common.project_doctor.version_missing_title' => 'The bound engine is not installed',
			'common.project_doctor.version_missing_description' => 'This project is bound to {{version}}, but that version is absent from the installed engine registry.',
			'common.project_doctor.version_executable_missing_title' => 'The engine executable is missing',
			'common.project_doctor.version_executable_missing_description' => '{{version}} is registered, but its executable is no longer on disk. Locate or reinstall it in Versions.',
			'common.project_doctor.version_ready_title' => 'The bound engine is available',
			'common.project_doctor.version_ready_description' => '{{version}} is installed and its executable exists.',
			'common.project_doctor.format_incompatible_title' => 'The project format is incompatible',
			'common.project_doctor.format_incompatible_description' => 'config_version={{format}} cannot be opened by the bound {{version}} engine. Choose a compatible engine and use Godot\'s migration tools if needed.',
			'common.project_doctor.major_mismatch_title' => 'The project and engine use different Godot generations',
			'common.project_doctor.major_mismatch_description' => 'This project records a Godot {{major}} format but is bound to {{version}}. Choose a matching engine or migrate the project in Godot.',
			'common.project_doctor.feature_mismatch_title' => 'The recorded project version differs from its engine',
			'common.project_doctor.feature_mismatch_description' => 'The project records Godot {{recorded}} features but is bound to {{version}}. Match the binding or open it in the intended engine and review its upgrade changes.',
			'common.project_doctor.format_unknown_title' => 'The project version could not be confirmed',
			'common.project_doctor.format_unknown_description' => 'The project format or engine version is missing or unrecognized. Review project.godot before changing engine generations.',
			'common.project_doctor.format_ready_title' => 'The recorded format matches the bound engine',
			'common.project_doctor.format_ready_description' => 'The project format and recorded Godot feature version are compatible with this binding.',
			'common.project_doctor.templates_missing_title' => 'Export templates are missing',
			'common.project_doctor.templates_platforms_missing_title' => 'Some export targets have no installed templates',
			'common.project_doctor.templates_platforms_missing_description' => 'These platforms appear in your export presets but have no templates installed for the bound engine. Choose the template files you need.',
			'common.project_doctor.templates_missing_description' => 'No installed export-template platform was found for {{version}}. Choose the platforms and files you need.',
			'common.project_doctor.templates_ready_title' => 'Export templates are available',
			'common.project_doctor.templates_ready_description' => 'These platforms have installed templates for the bound engine. Open the chooser to review individual files.',
			'common.project_doctor.templates_unknown_title' => 'Install or bind the engine before checking templates',
			'common.project_doctor.templates_unknown_description' => 'Export templates must match the exact engine version, including standard or .NET builds.',
			'common.project_doctor.main_scene_ready_title' => 'A main scene is configured',
			'common.project_doctor.main_scene_ready_description' => 'The project has an application/run/main_scene setting.',
			'common.project_doctor.main_scene_missing_title' => 'No main scene is configured',
			'common.project_doctor.main_scene_missing_description' => 'Open the project in Godot and choose a main scene in Project Settings before running the game.',
			'common.project_doctor.main_scene_missing_file_title' => 'The main scene file is missing',
			'common.project_doctor.main_scene_missing_file_description' => 'The configured scene path does not exist. Choose an existing main scene in Godot.',
			'common.project_doctor.cache_ready_title' => 'The import cache is within normal limits',
			'common.project_doctor.cache_ready_description' => '{{size}} across {{files}} files. Last cache write: {{days}} days ago.',
			'common.project_doctor.cache_large_title' => 'The import cache uses significant disk space',
			'common.project_doctor.cache_large_description' => '{{size}} across {{files}} files. Large projects can need a large cache; clearing it causes a full reimport.',
			'common.project_doctor.cache_stale_title' => 'The import cache has not changed recently',
			'common.project_doctor.cache_stale_description' => '{{size}} across {{files}} files; last write was {{days}} days ago. Age alone does not mean the cache is broken.',
			'common.project_doctor.cache_version_title' => 'The cache records a different engine executable',
			'common.project_doctor.cache_version_description' => 'The editor cache was last associated with a different engine path. If imports misbehave, rebuild its {{size}} cache.',
			'common.project_doctor.cache_partial_title' => 'The cache scan was incomplete',
			'common.project_doctor.cache_partial_description' => 'At least {{size}} across {{files}} files. Some entries were unreadable or the scan reached its time or file limit.',
			'common.project_doctor.cache_absent_title' => 'No local .godot import cache',
			'common.project_doctor.cache_absent_description' => 'Godot 4 creates this folder when the project opens. Godot 3 uses a different cache layout.',
			'common.project_doctor.addon_missing_title' => 'An enabled editor addon is missing',
			'common.project_doctor.addon_missing_description' => 'This editor_plugins entry has no plugin.cfg on disk. Restore the addon or remove the stale enabled entry.',
			'common.project_doctor.addon_disabled_title' => 'An editor addon is present but disabled',
			'common.project_doctor.addon_disabled_description' => 'Its plugin.cfg is on disk but not listed in editor_plugins. This can be intentional. Enable it only if you want its editor functionality.',
			'common.project_doctor.addon_orphan_title' => 'An addon folder has no editor plugin configuration',
			'common.project_doctor.addon_orphan_description' => 'This folder is not an enabled editor addon. It may be a runtime library or leftover files; review it before removing anything.',
			'common.project_doctor.addons_ready_title' => 'Enabled editor addons exist on disk',
			'common.project_doctor.addons_ready_description' => 'No missing or disabled editor-plugin folders were found.',
			'common.project_doctor.no_presets_title' => 'No export presets configured',
			'common.project_doctor.no_presets_description' => 'Create export presets in Godot when you are ready to package the project.',
			'common.project_doctor.presets_unreadable_title' => 'Export presets could not be read',
			'common.project_doctor.presets_unreadable_description' => 'Review export_presets.cfg and run the checks again.',
			'common.project_doctor.exports_ready_title' => 'Export resource paths exist',
			'common.project_doctor.exports_ready_description' => 'Explicit res:// references in the export presets exist on disk. Wildcard filters and output paths are excluded from this check.',
			'common.project_doctor.export_resources_missing_title' => 'Export presets reference missing resources',
			'common.project_doctor.export_resources_missing_description' => 'Restore these files or update the references in Godot\'s export settings or export_presets.cfg.',
			'common.project_doctor.git_unavailable_title' => 'Git checks were skipped',
			'common.project_doctor.git_unavailable_description' => 'This folder is not in a Git repository, Git is unavailable, or the repository could not be inspected.',
			'common.project_doctor.ignore_missing_title' => 'Generated or local files are not ignored',
			'common.project_doctor.ignore_missing_description' => 'The effective Git ignore rules do not cover all of .godot/, .godothub/, and .godothub.json. Add project-local rules to keep them out of future commits.',
			'common.project_doctor.ignores_ready_title' => 'Generated and local files are ignored',
			'common.project_doctor.ignores_ready_description' => 'Git ignores the import cache and local GodotHub metadata.',
			'common.project_doctor.metadata_tracked_title' => 'Local GodotHub metadata is tracked by Git',
			'common.project_doctor.metadata_tracked_description' => '.godothub.json is in Git\'s index, so ignore rules alone will not keep it out of commits. Remove it from tracking while keeping the local file.',
			'common.project_doctor.metadata_private_title' => 'Legacy local metadata is not tracked',
			'common.project_doctor.metadata_private_description' => '.godothub.json is absent from Git\'s tracked-file index.',
			'common.project_doctor.lfs_ready_title' => 'No large binaries need a Git LFS rule',
			'common.project_doctor.lfs_ready_description' => 'Scanned binary files of 50 MiB or more are ignored by Git or covered by an LFS filter rule. Existing commit history is not inspected.',
			'common.project_doctor.lfs_unknown_title' => 'Git LFS attributes could not be checked',
			'common.project_doctor.lfs_unknown_description' => 'Review the Git error below, then run the checks again.',
			'common.project_doctor.binary_without_lfs_title' => 'A large binary has no Git LFS rule',
			'common.project_doctor.binary_without_lfs_description' => 'This binary is at least 50 MiB and is not ignored or covered by filter=lfs. Track it with LFS to keep future revisions out of regular Git blobs.',
			'common.project_doctor.scan_partial_title' => 'The project file scan was incomplete',
			'common.project_doctor.scan_partial_description' => 'Some paths were unreadable or the scan reached its 50,000-entry or five-second limit. Large-binary results may be incomplete.',
			'common.project_doctor.registration_stale_title' => 'This registration no longer points to a project',
			'common.project_doctor.registration_stale_description' => 'No project.godot was found at this path. Reconnect moved or offline storage, or remove the stale library entry.',
			'common.project_doctor.registration_duplicate_title' => 'Another registration points to this project',
			'common.project_doctor.registration_duplicate_description' => 'This additional library entry resolves to the same project folder or a stale copy of its identity. Remove it to keep the current registration.',
			'common.project_doctor.registration_ready_title' => 'No duplicate registrations found',
			'common.project_doctor.registration_ready_description' => 'This project has one valid folder registration in the active workspace.',
			'common.project_doctor.category_android' => 'Android',
			'common.project_doctor.android_targeted_title' => 'This project exports to Android',
			'common.project_doctor.android_targeted_description' => 'An Android export preset or Gradle build template was found, so the Android toolchain is checked below.',
			'common.project_doctor.android_possible_title' => 'This project may target mobile devices',
			'common.project_doctor.android_possible_description' => 'No Android export preset was found, but some settings suggest mobile use. Many desktop games also use the Mobile renderer, so the toolchain checks below are informational only.',
			'common.project_doctor.hint_mobile_renderer' => 'Uses the Mobile renderer',
			'common.project_doctor.hint_mobile_renderer_override' => 'Sets a renderer override for mobile platforms',
			'common.project_doctor.hint_etc2_astc' => 'Imports ETC2/ASTC textures, which Android requires',
			'common.project_doctor.hint_orientation' => 'Sets a handheld screen orientation',
			'common.project_doctor.hint_touch_emulation' => 'Emulates touch input from the mouse',
			'common.project_doctor.hint_android_plugins' => 'Has an android/plugins folder',
			'common.project_doctor.android_sdk_missing_title' => 'Android SDK not found',
			'common.project_doctor.android_sdk_missing_description' => 'Set the Android SDK path in Godot under Editor Settings → Export → Android, or set ANDROID_HOME. Android exports need it.',
			'common.project_doctor.android_sdk_incomplete_title' => 'The Android SDK is missing components',
			'common.project_doctor.android_sdk_incomplete_description' => 'The SDK at {{path}} is missing the parts listed below. Install them with Android Studio\'s SDK Manager or sdkmanager.',
			'common.project_doctor.sdk_part_sdk_folder' => 'The SDK folder does not exist',
			'common.project_doctor.sdk_part_platform_tools' => 'Platform Tools (adb)',
			'common.project_doctor.sdk_part_build_tools' => 'Build Tools',
			'common.project_doctor.sdk_part_cmdline_tools' => 'Command-line Tools',
			'common.project_doctor.android_sdk_ready_title' => 'Android SDK found',
			'common.project_doctor.android_sdk_ready_description' => 'Using the SDK at {{path}}.',
			'common.project_doctor.android_jdk_missing_title' => 'Java JDK not found',
			'common.project_doctor.android_jdk_missing_description' => 'Android exports need JDK {{required}} or newer. Set it in Godot under Editor Settings → Export → Android, or set JAVA_HOME.',
			'common.project_doctor.android_jdk_invalid_title' => 'The Java JDK path is invalid',
			'common.project_doctor.android_jdk_invalid_description' => 'No java executable was found in {{path}}. Point Godot to a JDK {{required}} installation.',
			'common.project_doctor.android_jdk_old_title' => 'The Java JDK is too old',
			'common.project_doctor.android_jdk_old_description' => 'JDK {{version}} is installed at {{path}}, but this Godot version needs JDK {{required}} or newer for Android exports.',
			'common.project_doctor.android_jdk_ready_title' => 'Java JDK found',
			'common.project_doctor.android_jdk_ready_description' => 'JDK {{version}} at {{path}}.',
			'common.project_doctor.android_debug_keystore_missing_title' => 'The debug keystore file is missing',
			'common.project_doctor.android_debug_keystore_missing_description' => 'Godot\'s editor settings point to a debug keystore that no longer exists. Clear the setting so Godot can create a new one, or pick another file.',
			'common.project_doctor.android_gradle_template_missing_title' => 'The Android build template is not installed',
			'common.project_doctor.android_gradle_template_missing_description' => 'These presets use a Gradle build, but the project has no android/build folder. In Godot, choose Project → Install Android Build Template.',
			'common.project_doctor.android_release_keystore_missing_title' => 'A release keystore file is missing',
			'common.project_doctor.android_release_keystore_missing_description' => 'These presets point to a release keystore that does not exist. Release exports will fail until the path is fixed.',
			'common.project_doctor.android_release_keystore_unset_title' => 'No release keystore is set',
			'common.project_doctor.android_release_keystore_unset_description' => 'These presets can only make debug builds until a release keystore is set. You need one to publish on Google Play.',
			'common.build_export.title' => 'Build & Export',
			'common.build_export.description' => 'Ship a release build of {{name}} using its bound Godot version.',
			'common.build_export.loading' => 'Reading export presets and checking release templates…',
			'common.build_export.refresh' => 'Refresh presets',
			'common.build_export.preset' => 'Export preset',
			'common.build_export.choose_preset' => 'Choose an export preset',
			'common.build_export.output' => 'Output file',
			'common.build_export.browse' => 'Choose output file',
			'common.build_export.output_hint' => 'Relative paths start at the project folder. Parent folders are created automatically. export_presets.cfg is kept unchanged.',
			'common.build_export.release' => 'Release build',
			'common.build_export.engine' => 'Godot {{version}}',
			'common.build_export.start' => 'Export release',
			'common.build_export.starting' => 'Starting export…',
			'common.build_export.install_templates' => 'Install export templates',
			'common.build_export.missing_templates' => 'Templates are missing for this preset. Godot validates debug and release templates before exporting.',
			'common.build_export.downloading_templates' => 'Installing templates… Follow progress in Tasks.',
			'common.build_export.no_presets' => 'No export presets yet',
			'common.build_export.no_presets_hint' => 'Open Project → Export in Godot, add a preset, and save it. Refresh this list when it is ready.',
			'common.build_export.open_editor' => 'Open in Godot',
			'common.build_export.open_console' => 'Open export console',
			'common.build_export.cancel_export' => 'Cancel export',
			'common.build_export.running' => 'Exporting {{preset}}…',
			'common.build_export.succeeded' => 'Export complete',
			'common.build_export.failed' => 'Export failed',
			'common.build_export.cancelled' => 'Export cancelled',
			'common.build_export.cancel_hint' => 'Partial output files may remain in the output folder.',
			'common.build_export.open_folder' => 'Open output folder',
			'common.build_export.overwrite_title' => 'Replace existing export?',
			'common.build_export.overwrite_description' => 'An output file already exists at {{path}}. Replace it with this export?',
			'common.build_export.overwrite' => 'Replace and export',
			'common.build_export.run_hint' => 'Output streams to its own console tab. Exporting does not change the project\'s play-time statistics.',
			'common.build_export.platform_tools' => 'Godot also requires the SDKs, signing settings and export options configured for your target platform.',
			'common.build_export.scan_failed' => 'Could not read export presets',
			'common.build_export.start_failed' => 'Could not start export: {{error}}',
			'common.build_export.tools_title' => 'Tests and lint',
			'common.build_export.tools_no_tests' => 'No test framework found. Install GUT or gdUnit4 from the Asset Library to run tests here.',
			'common.build_export.tool_run' => 'Run',
			'common.build_export.tool_gut' => 'GUT tests',
			'common.build_export.tool_gut_hint' => 'Runs your GUT tests headless with the bound Godot version.',
			'common.build_export.tool_gdunit' => 'gdUnit4 tests',
			'common.build_export.tool_gdunit_hint' => 'Runs the gdUnit4 tests in {{target}} headless.',
			'common.build_export.tool_gdlint' => 'gdlint',
			'common.build_export.tool_gdlint_hint' => 'Lints GDScript outside addons: {{target}}',
			'common.build_export.tool_gdformat' => 'gdformat check',
			'common.build_export.tool_gdformat_hint' => 'Checks formatting without changing files: {{target}}',
			'common.build_export.tool_reason_engine_missing' => 'Install this project\'s Godot version to run tests.',
			'common.build_export.tool_reason_no_test_folder' => 'Add a test or tests folder for gdUnit4.',
			'common.build_export.tool_reason_not_installed' => 'Not found on PATH. Install it with: pip install gdtoolkit',
			'common.projects_corrupt_title' => 'Project list couldn\'t be read',
			'common.projects_corrupt_desc' => 'Your projects.json file is corrupt, so your projects can\'t be shown. You can restore the most recent automatic backup, or dismiss this and leave the file untouched.',
			'common.projects_corrupt_restore' => 'Restore backup',
			'common.projects_corrupt_dismiss' => 'Not now',
			'common.projects_load_error' => 'Couldn\'t load your projects. Something went wrong reading them from disk. Try again, and if it keeps failing your project list file may be damaged.',
			'common.cleanup_title' => 'Storage',
			'common.cleanup_subtitle' => 'See what GodotHub keeps on disk and free up space you no longer need.',
			'common.cleanup_total_label' => 'on disk',
			'common.cleanup_scanning' => 'Measuring folders…',
			'common.cleanup_load_error' => 'Couldn\'t measure storage: {{error}}',
			'common.cleanup_reclaimable_title' => 'Reclaimable',
			'common.cleanup_reclaimable_desc' => 'Versions no project, template or alias uses, unfinished downloads, and export templates no installed version needs. Pick what to remove.',
			'common.cleanup_nothing_to_reclaim' => 'Nothing to clean up right now.',
			'common.cleanup_group_unused_versions' => 'Unused versions',
			'common.cleanup_group_partials' => 'Unfinished downloads',
			'common.cleanup_group_orphan_exports' => 'Orphaned export templates',
			'common.cleanup_orphan_exports_hint' => 'No installed version uses these, but a Godot install outside GodotHub might, so they aren\'t selected by default.',
			'common.cleanup_external_hint' => 'Installed outside GodotHub\'s download folder',
			'common.cleanup_kind_version_download' => 'Godot version download',
			'common.cleanup_kind_export_templates_download' => 'Export templates download',
			'common.cleanup_reclaim_btn' => 'Reclaim {{size}}',
			'common.cleanup_confirm_title' => 'Reclaim {{size}}?',
			'common.cleanup_confirm_desc' => 'These items will be removed:',
			'common.cleanup_confirm_trash_note' => 'Versions and export templates are moved to the system trash, so the space is freed once you empty it. Unfinished downloads are deleted permanently.',
			'common.cleanup_confirm_btn' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Remove ${count} items', one: 'Remove ${count} item', two: 'Remove ${count} items', few: 'Remove ${count} items', many: 'Remove ${count} items', other: 'Remove ${count} items', ), 
			'common.cleanup_done' => 'Freed {{size}}',
			'common.cleanup_failed' => 'Couldn\'t remove {{label}}: {{error}}',
			'common.cleanup_versions_desc' => 'Full size on disk of every installed Godot version.',
			'common.cleanup_templates_title' => 'Project templates',
			'common.cleanup_export_templates_title' => 'Export templates',
			'common.cleanup_used_by_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} templates', one: '${count} template', two: '${count} templates', few: '${count} templates', many: '${count} templates', other: '${count} templates', ), 
			'common.cleanup_current_badge' => 'Current',
			'common.cleanup_alias_badge' => 'Alias',
			'common.cleanup_unused_badge' => 'Unused',
			'common.cleanup_mise_badge' => 'Managed by mise',
			'common.cleanup_external_badge' => 'External',
			'common.cleanup_orphan_badge' => 'Orphaned',
			'common.cleanup_empty' => 'Nothing here yet.',
			'common.new_badge' => 'New',
			'common.reset' => 'أعد الضبط',
			'common.git_disconnect' => 'ألغي الإتصال',
			'common.git_sign_in_github' => 'سجل الدخول مع GitHub',
			'common.git_connected_as' => 'متصل كـ @{{username}}',
			'common.optional' => '(إختياري)',
			'common.language_label' => 'اللغة',
			'common.n_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} projects', one: '${count} امشروع', two: '${count} projects', few: '${count} projects', many: '${count} projects', other: '${count} مشاريع', ), 
			'common.vault_item_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Items', one: 'Item', two: 'Items', few: 'Items', many: 'Items', other: 'Items', ), 
			'common.vault_search_placeholder' => 'Search vault…',
			'common.vault_empty' => 'Your vault is empty. Click <1>Save to Vault</1> to pick files or folders from a project and reuse them anywhere.',
			'common.vault_no_match' => 'No items match your search.',
			'common.vault_save_btn' => 'Save to Vault',
			'common.vault_save_title' => 'Save to Vault',
			'common.vault_source_project_label' => 'Source Project',
			'common.vault_source_n' => 'Source {{index}}',
			'common.vault_add_source' => 'Add another project',
			'common.vault_remove_source' => 'Remove source',
			'common.vault_select_project' => 'Select a project…',
			'common.vault_select_files_label' => 'Files & Folders',
			'common.vault_selected_count' => '{{count}} selected',
			'common.vault_project_empty' => 'This project has no files.',
			'common.vault_item_name_label' => 'Name',
			'common.vault_item_name_placeholder' => 'Item name',
			'common.vault_item_desc_label' => 'Description',
			'common.vault_item_desc_placeholder' => 'What\'s in this item?',
			'common.vault_item_tags_label' => 'Tags',
			'common.vault_tag_input_placeholder' => 'Add a tag…',
			'common.vault_saved_toast' => 'Saved to Vault',
			'common.vault_edit_action' => 'Edit item',
			'common.vault_edit_title' => 'Edit Item',
			'common.vault_item_updated_toast' => 'Item updated',
			'common.vault_delete_action' => 'Delete {{name}}',
			'common.vault_delete_title' => 'Delete Item?',
			'common.vault_delete_desc' => '"{{name}}" will be permanently removed from your vault.',
			'common.vault_add_btn' => 'Add to Project',
			'common.vault_add_title' => 'Add from Vault',
			'common.vault_target_project_label' => 'Target Project',
			'common.vault_target_projects_label' => 'Target Projects',
			'common.vault_adding' => 'Adding…',
			'common.vault_overwrite_btn' => 'Overwrite files',
			'common.vault_conflict_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} files already exist in the project. Overwrite them?', one: '${count} file already exists in the project. Overwrite it?', two: '${count} files already exist in the project. Overwrite them?', few: '${count} files already exist in the project. Overwrite them?', many: '${count} files already exist in the project. Overwrite them?', other: '${count} files already exist in the project. Overwrite them?', ), 
			'common.vault_conflict_summary_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} files already exist across the selected projects. Overwrite them?', one: '${count} file already exists across the selected projects. Overwrite it?', two: '${count} files already exist across the selected projects. Overwrite them?', few: '${count} files already exist across the selected projects. Overwrite them?', many: '${count} files already exist across the selected projects. Overwrite them?', other: '${count} files already exist across the selected projects. Overwrite them?', ), 
			'common.vault_added_toast' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Added ${count} files', one: 'Added ${count} file', two: 'Added ${count} files', few: 'Added ${count} files', many: 'Added ${count} files', other: 'Added ${count} files', ), 
			'common.vault_added_to_projects_toast' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Added to ${count} projects', one: 'Added to ${count} project', two: 'Added to ${count} projects', few: 'Added to ${count} projects', many: 'Added to ${count} projects', other: 'Added to ${count} projects', ), 
			'common.vault_item_empty' => 'This item has no files.',
			'common.kNew' => 'جديد',
			'common.announcement_support_title' => 'Support GodotHub',
			'common.announcement_support_body' => 'GodotHub is free and made in my spare time. If it helps your workflow, please consider supporting development with a donation.',
			'common.workspace_name_taken_error' => 'Another workspace already uses this name.',
			'common.workspace_start_label' => 'Start with',
			'common.workspace_start_copy' => 'Copy settings from {{name}}',
			'common.workspace_start_copy_desc' => 'Theme, language, features, and version folders carry over. Project folders start empty, and you go straight in.',
			'common.workspace_start_fresh' => 'Start fresh',
			'common.workspace_start_fresh_desc' => 'Walk through setup for this workspace from scratch.',
			'common.workspace_switched_to' => 'Switched to',
			'common.project_addons.title' => 'Addons',
			'common.project_addons.loading' => 'Reading addons…',
			'common.project_addons.count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} addons installed', one: '${count} addon installed', two: '${count} addons installed', few: '${count} addons installed', many: '${count} addons installed', other: '${count} addons installed', ), 
			'common.project_addons.empty' => 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.',
			'common.project_addons.check_updates' => 'Check for updates',
			'common.project_addons.checking' => 'Checking…',
			'common.project_addons.updates_available' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} updates available', one: '${count} update available', two: '${count} updates available', few: '${count} updates available', many: '${count} updates available', other: '${count} updates available', ), 
			'common.project_addons.all_current' => 'No updates found in the Asset Library',
			'common.project_addons.enabled' => 'Enabled',
			'common.project_addons.disabled' => 'Disabled',
			'common.project_addons.library' => 'Library',
			'common.project_addons.from_library' => 'Asset Library',
			'common.project_addons.not_found' => 'Not found in the Asset Library',
			'common.project_addons.update_to' => 'Version {{version}} is available',
			'common.project_addons.current' => 'Up to date ({{version}})',
			'common.project_addons.matched_by_name' => 'matched by name to “{{title}}”',
			'common.project_addons.update' => 'Update',
			'common.project_addons.updating' => 'Updating…',
			'common.project_addons.updated' => '{{name}} was updated',
			'common.project_addons.confirm_title' => 'Update {{name}}?',
			'common.project_addons.confirm_description' => 'This replaces res://addons/{{folder}} with version {{version}} from the Asset Library. The old folder is moved to the Trash, so any changes you made to the addon are kept there. Close the project in Godot first.',
			'common.project_addons.footer_hint' => 'Addons installed through GodotHub are matched exactly. Others are matched by name, so check the result before updating.',
			'common.reload_confirm_title' => 'Reload GodotHub?',
			'common.reload_confirm_desc' => 'Any unsaved changes in open forms will be lost.',
			'common.color_presets' => 'Presets',
			'common.date_previous_month' => 'Previous month',
			'common.date_next_month' => 'Next month',
			'common.date_change_due' => 'Change due date: {{date}}',
			'common.date_add_due' => 'Add due date',
			'dashboard.greeting_morning' => 'صباح الخير',
			'dashboard.greeting_afternoon' => 'مساء الخير',
			'dashboard.greeting_evening' => 'طاب مساؤك',
			'dashboard.greeting_night' => 'ليلة سعيدة',
			'dashboard.greeting_name' => 'إسم التحية',
			'dashboard.dashboard_rename_hint' => 'عيين إسما مخصصا',
			'dashboard.dashboard_rename_aria' => 'أعد تسمية إسم الترحيب',
			'dashboard.dashboard_rename_save' => 'احفظ الإسم',
			'dashboard.dashboard_rename_reset' => 'استخدم الإسم من النظام',
			'dashboard.dashboard_name_placeholder' => 'إسمك',
			'dashboard.dashboard_clock_aria' => 'الوقت الحالي',
			'dashboard.dashboard_new_project' => 'مشروع جديد',
			'dashboard.dashboard_import_project' => 'استورد مشروعا',
			'dashboard.dashboard_scan_projects' => 'ابحث عن المشاريع',
			'dashboard.dashboard_stat_projects' => 'المشاريع',
			'dashboard.dashboard_stat_templates' => 'القوالب',
			'dashboard.dashboard_stat_engines' => 'المحركات',
			'dashboard.dashboard_stat_total_time' => 'الوقت الكلي',
			'dashboard.dashboard_stat_total_time_hint' => 'الوقت مستغرق في المشاريع',
			'dashboard.dashboard_recent' => 'مفتوح مؤخرا',
			'dashboard.dashboard_recent_empty' => 'لم يفتح أي مشروع بعد. افتح مشروعا لتراه هنا.',
			'dashboard.dashboard_pinned' => 'مُثبت',
			'dashboard.dashboard_pinned_empty' => 'لا توجد مشاريع مثبت بعد. ثبت مشروعا لإبقائه قريبا.',
			'dashboard.dashboard_engines' => 'المحركات المثبتة',
			'dashboard.dashboard_engines_empty' => 'لم يتم تثبيت أي محرك بعد.',
			'dashboard.dashboard_running' => 'مُشغّل حاليا',
			'dashboard.dashboard_running_empty' => 'لا يوجد اي مشروع شغال حاليا.',
			'dashboard.dashboard_opened_at' => 'فُتح {{time}}',
			'dashboard.dashboard_daily' => 'الأنشطة اليومية',
			'dashboard.dashboard_daily_empty' => 'لا توجد أي أنشطة يومية حاليا.',
			'dashboard.dashboard_weekly' => 'الأنشطة الأسبوعية',
			'dashboard.dashboard_weekly_empty' => 'لا توجد أنشطة أسبوعية حاليا.',
			'dashboard.dashboard_monthly' => 'الأنشطة الشهرية',
			'dashboard.dashboard_monthly_empty' => 'لا توجد أنشطة شهرية حاليا.',
			'dashboard.dashboard_yearly' => 'الأنشطة السنوية',
			'dashboard.dashboard_yearly_empty' => 'لا توجد أنشطة سنوية حاليا.',
			'dashboard.dashboard_activity_cycle' => 'بدل لـ {{next}}',
			'dashboard.dashboard_weekly_aria' => '{{label}} من الوقت المتتبع',
			'dashboard.dashboard_top_time' => 'المشاريع الأعلى استغراقا',
			'dashboard.dashboard_top_time_empty' => 'لا يوجد وقت متتبع بعد. افتح مشروعا لبدأ التتبع.',
			'dashboard.dashboard_insights' => 'رؤى',
			'dashboard.dashboard_insights_empty' => 'لا يوجد وقت متتبع بعد. افتح مشروعا لبدء بناء سلسلة إنجازاتك.',
			'dashboard.dashboard_insights_longest_streak' => 'التتبع الأعلى',
			'dashboard.dashboard_insights_current_streak' => 'التتبع الحالي',
			'dashboard.dashboard_insights_days' => '{{count}} يوما',
			'dashboard.dashboard_insights_productive_day' => 'اليوم الأكثر إنتاجية',
			'dashboard.dashboard_insights_this_month' => 'هذا الشهر',
			'dashboard.dashboard_insights_delta_up' => '{{pct}}% أكثر من الشهر الماضي',
			'dashboard.dashboard_insights_delta_down' => '{{pct}}% أقل من الشهر الماضي',
			_ => null,
		} ?? switch (path) {
			'dashboard.dashboard_git' => 'Git رؤية عامة',
			'dashboard.dashboard_git_empty' => 'لا يتم كشف أي مستودعات Git.',
			'dashboard.dashboard_git_clean' => 'تم مسح الكل',
			'dashboard.dashboard_git_dirty' => '{{count}} بدون تغيرات منفذة',
			'dashboard.dashboard_git_dirty_plural' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} بدون تغيرات منفذة', one: '1 بدون تغيرات منفذة', two: '${count} بدون تغيرات منفذة', few: '${count} بدون تغيرات منفذة', many: '${count} بدون تغيرات منفذة', other: '${count} بدون تغيرات منفذة', ), 
			'dashboard.dashboard_git_branch' => 'على {{branch}}',
			'dashboard.dashboard_storage' => 'المساحة المستخدمة',
			'dashboard.dashboard_storage_empty' => 'لا يوجد مشروع حاليا للقياس.',
			'dashboard.dashboard_storage_loading' => 'جاري القياس…',
			'dashboard.dashboard_storage_total' => '{{size}} الكل',
			'dashboard.dashboard_customize' => 'التخصيص',
			'dashboard.dashboard_done_customizing' => 'تم',
			'dashboard.dashboard_customize_hint' => 'استخدم الأسهم لإعادة ترتيب الخانات, أو أخفي الذين لا تحتاجهم.',
			'dashboard.dashboard_tile_move_up' => 'انقل للأعلى',
			'dashboard.dashboard_tile_move_down' => 'انقل للأسفل',
			'dashboard.dashboard_tile_remove' => 'أزل',
			'dashboard.dashboard_tile_span' => 'العرض كاملا',
			'dashboard.dashboard_tile_span_off' => 'نصف العرض',
			'dashboard.dashboard_tile_tall' => 'الأطول',
			'dashboard.dashboard_tile_tall_off' => 'ارتفاع طبيعي',
			'dashboard.dashboard_presets' => 'إعدادات التخطيط المسبقة',
			'dashboard.dashboard_preset_default' => 'الإفتراضية',
			'dashboard.dashboard_preset_default_desc' => 'Everything on, in the default order, standard sizing.',
			'dashboard.dashboard_preset_overview' => 'رؤية عامة',
			'dashboard.dashboard_preset_overview_desc' => 'المشاريع المفتوحة مؤخرا, المشاريع المثتبة, المحركات, و المشاريع الشغالة حاليا.',
			'dashboard.dashboard_preset_analytics' => 'الإحصائات',
			'dashboard.dashboard_preset_analytics_desc' => 'الأنشطة الأسبوعية, المشاريع الأعلى, المساحة التخزينية, و التصنيفات, مع رسوم بيانية أطول.',
			'dashboard.dashboard_preset_development' => 'التطوير',
			'dashboard.dashboard_preset_development_desc' => 'Git status front and center with running projects and engines.',
			'dashboard.dashboard_preset_save' => 'احفظ الإعداد المسبق الحالي',
			'dashboard.dashboard_preset_save_hint' => 'سمّي هذا التخطيط بحيث يمكنك العودة إليه متى شئت.',
			'dashboard.dashboard_preset_name_placeholder' => 'إسم الإعداد المسبق',
			'dashboard.dashboard_preset_delete' => 'احذف الإعدادات المسبقة',
			'dashboard.dashboard_custom_presets' => 'إعداداتك المسبقة',
			'dashboard.dashboard_hidden_tiles' => 'أخفي الخانات',
			'dashboard.dashboard_todos' => 'Due to-dos',
			'dashboard.dashboard_range_daily' => 'يوم',
			'dashboard.dashboard_range_weekly' => 'أسبوع',
			'dashboard.dashboard_range_monthly' => 'شهر',
			'dashboard.dashboard_range_yearly' => 'سنة',
			'dashboard.dashboard_activity_tracked' => 'المُسجّل',
			'dashboard.dashboard_activity_peak' => 'الذروة',
			'git.remove' => 'أزل',
			'git.changes_title' => 'التغييرات',
			'git.pull' => 'اسحب',
			'git.push' => 'ادفع',
			'git.force_push' => 'أرغم',
			'git.fetch' => 'اجلب',
			'git.change' => 'غيير',
			'git.commit' => 'نفذ',
			'git.committing' => 'جاري التنفيذ…',
			'git.no_remotes' => 'No remotes configured',
			'git.switching' => 'جاري التبديل…',
			'git.no_branches' => 'لا توجد أي فروع',
			'git.new_branch_placeholder' => 'إسم الفرع',
			'git.delete_branch' => 'احذف الفرع',
			'git.publish_branch' => 'انشر الفرع',
			'git.publish_branch_to' => 'Publish branch to {{remote}}',
			'git.branch_published' => 'تم نشر الفرع.',
			'git.use_ours' => 'استخدم خاصتنا',
			'git.use_theirs' => 'استخدم خاصتهم',
			'git.i_resolved' => 'حللتها',
			'git.undo_last_commit' => 'تراجع عن أخر تنفيذ',
			'git.undo_pull' => 'تراجع عن السحب',
			'git.force_push_confirm_title' => 'هل تريد إرغام الدفع?',
			'git.force_push_confirm_desc' => 'This rewrites remote history and can lose other people\'s commits. Continue?',
			'git.undo_commit_done' => 'التنفيذ الأخير لم يتم.',
			'git.undo_pull_done' => 'عملية السحب لم تتم.',
			'git.force_pushed' => 'تم إرغام الدفع.',
			'git.synced_ok' => 'تمت المزامنة.',
			'git.fetched_ok' => 'تم جلب البيانات.',
			'git.pulled_ok' => 'تم السحب.',
			'git.pushed_ok' => 'تم الدفع.',
			'git.branch_created' => 'تم إنشاء الفرع.',
			'git.branch_deleted' => 'تم حذف الفرع.',
			'git.changes_stashed_ok' => 'تم إخفاء التغييرات.',
			'git.stash_applied_ok' => 'تم تطبيق الإخفاءات.',
			'git.stash_popped_ok' => 'Stash popped.',
			'git.stash_dropped_ok' => 'Stash dropped.',
			'git.staged_ok' => 'تم التجهيز.',
			'git.unstaged_ok' => 'تم إلغاء التجهيز.',
			'git.discarded_ok' => 'تم التخلص.',
			'git.stage_all_ok' => 'تم تجهيز كل التغييرات.',
			'git.unstage_all_ok' => 'تم إلغاء تجهيز كل التغييرات.',
			'git.discard_all_ok' => 'تم التخلص من كل التغييرات.',
			'git.resolved_ours' => 'Resolved using ours.',
			'git.resolved_theirs' => 'Resolved using theirs.',
			'git.resolved_manual' => 'موسومة كمحلولة.',
			'git.committed_ok' => 'منفذة.',
			'git.switched_ok' => 'بدل لـ {{branch}}.',
			'git.sync' => 'زامن',
			'git.diff_no_diff' => 'No diff available for this file.',
			'git.fetching' => 'جاري جلب البيانات…',
			'git.stashes_title' => 'المخفيات',
			'git.stash' => 'أخفي',
			'git.stashing' => 'جاري الإخفاء…',
			'git.apply_stash' => 'طبق الإخفاء',
			'git.pop_stash' => 'Pop stash',
			'git.drop_stash' => 'Drop stash',
			'git.merge_aborted' => 'ألغي الدمج. تم استعادت مجلد العمل.',
			'git.new_branch_btn' => '+ جديد',
			'git.abort_merge' => 'ألغي الدمج',
			'git.merge_in_progress' => 'الدمج في حالة تقدم',
			'git.working_tree_clean' => 'شجرة العمل نقية.',
			'git.staged_changes' => 'التغييرات المجهزة',
			'git.unstage_all_changes' => 'ألغي تجهيز كل التغييرات',
			'git.commits_title' => 'التنفيذات',
			'git.stage_file' => 'جهز الملف',
			'git.discard_file' => 'تخلص من الملف',
			'git.unstage_file' => 'ألغي تجهيز الملف',
			'git.no_commits_found' => 'لا توجد أي تنفيذات.',
			'git.stage_all' => 'جهز الكل',
			'git.discard_all' => 'تجاهل الكل',
			'git.auth_connected_accounts' => 'الحسابات المتصلة',
			'git.auth_connect_hint' => 'اربط بإستضافة Git التي تفضلها للبدأ، أو استعمل SSH بدون الإتصال بأي إستضافة.',
			'git.worktrees_title' => 'أشجار العمل',
			'git.worktree_current' => 'الحالي',
			'git.no_worktrees' => 'لا توجد أشجال عمل إضافية',
			'git.switch_worktree' => 'بدل لشجرة العمل هذه',
			'git.switched_worktree_ok' => 'تم تبديل شجرة العمل.',
			'git.add_worktree' => 'شجرة عمل جديدة',
			'git.add_worktree_btn' => 'أضف شجرة عمل',
			'git.worktree_path_placeholder' => 'مسار (e.g. ../my-feature)',
			'git.worktree_branch_placeholder' => 'إسم الفرع (إختياري)',
			'git.worktree_created_ok' => 'تم إنشاء شجرة العمل.',
			'git.worktree_dirty' => 'التغييرات الملغى تنفيذها',
			'git.remove_worktree' => 'أزلة شجرة العمل',
			'git.remove_worktree_confirm_desc' => 'إزالة شجرة العمل في {{path}}؟ سيُحذف مجلدها مع الاحتفاظ بالفرع والالتزامات.',
			'git.worktree_removed_ok' => 'تمت إزالة شجرة العمل.',
			'git.auto_fetch_label' => 'Fetch automatically',
			'git.auto_fetch_hint' => 'Runs git fetch every few minutes so the pull bubble always shows how many commits you\'re behind, without merging anything. Leave it off to only fetch when you click Fetch.',
			'git.commits_to_push' => '{{count}} commit(s) to push',
			'git.commits_to_pull' => '{{count}} commit(s) to pull',
			'git.filter_changes' => 'رشح الملفات المتغييرة…',
			'git.no_matching_changes' => 'لا توجد تغييرات متطابقة.',
			'git.worktree_location_label' => 'Directory',
			'git.worktree_location_hint' => 'Use a new directory. Relative paths are resolved from the current repository.',
			'git.worktree_branch_label' => 'New branch (optional)',
			'git.worktree_branch_hint' => 'Leave blank to use the directory name as the new branch name.',
			'git.worktree_browse_parent' => 'Choose parent directory',
			'git.worktree_removing' => 'Removing…',
			'git.worktree_main' => 'Main',
			'git.worktree_detached' => 'Detached HEAD · {{hash}}',
			'git.worktrees_load_error' => 'Could not load worktrees.',
			'git.switch_worktree_named' => 'Switch to {{name}}',
			'git.worktree_discard_changes' => 'Discard uncommitted changes',
			'git.worktree_discard_warning' => 'This worktree has uncommitted changes. Removing it with this option will permanently discard them.',
			'git.discard_dialog_title' => 'Discard changes?',
			'git.discard_dialog_tracked_desc' => 'This reverts all tracked files to the last commit.',
			'git.discard_dialog_untracked_heading' => 'These untracked files would be permanently deleted ({{n}}):',
			'git.discard_dialog_no_untracked' => 'No untracked files will be affected.',
			'git.discard_opt_tracked' => 'Discard tracked changes',
			'git.discard_opt_tracked_hint' => 'Reverts tracked files. Leaves untracked files untouched.',
			'git.discard_opt_untracked' => 'Also remove untracked files',
			'git.discard_opt_untracked_hint' => 'Permanently deletes the files listed above. This cannot be undone.',
			'git.discard_opt_stash' => 'Stash everything instead',
			'git.discard_opt_stash_hint' => 'Saves tracked and untracked changes to a stash you can restore later.',
			'git.protected_branch_tooltip' => '{{branch}} is protected on the remote',
			'git.protected_branch_title' => 'Protected branch',
			'git.protected_branch_desc' => '{{branch}} is protected on the remote, so pushing commits to it directly may be rejected. Commit anyway, or move these changes to a new branch and open a pull request.',
			'git.protected_branch_new_label' => 'New branch name',
			'git.protected_branch_commit_anyway' => 'Commit anyway',
			'git.protected_branch_create_pr' => 'Create branch & open PR',
			'git.protected_branch_creating_pr' => 'Opening pull request…',
			'git.pr_opened_ok' => 'Pushed {{branch}} and opened a pull request.',
			'nav.dashboard' => 'لوحة التحكم',
			'nav.projects' => 'المشاريع',
			'nav.projects_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'مشروعا(مشاريع)', one: 'مشروع', two: 'مشروعا(مشاريع)', few: 'مشروعا(مشاريع)', many: 'مشروعا(مشاريع)', other: 'مشاريع', ), 
			'nav.versions' => 'الإصدارات',
			'nav.templates' => 'القوالب',
			'nav.vault' => 'Vault',
			'nav.asset_store' => 'متجر الأصول',
			'nav.news' => 'الأخبار',
			'nav.storage_view' => 'Storage',
			'nav.settings' => 'الإعدادات',
			'nav.changelog' => 'سجل التغييرات',
			'nav.group_workspace' => 'مساحة العمل',
			'nav.group_resources' => 'الموارد',
			'nav.group_explore' => 'استكشاف',
			'nav.you' => 'You',
			'nav.account_manage' => 'Manage accounts',
			'nav.workspace_tip_title' => 'انتقل مُبدّل مساحات العمل',
			'nav.workspace_tip_body' => 'بدّل مساحات العمل وأدِرها من قائمة الحساب بالأسفل.',
			'nav.workspace_tip_dismiss' => 'فهمت',
			'onboarding.welcome' => 'أهلا و سهلا',
			'onboarding.finish' => 'تم',
			'onboarding.in_progress' => 'قيد التقدم',
			'onboarding.prototypes' => 'نسخة تجريبية',
			'onboarding.finished' => 'تم',
			'onboarding.game_jams' => 'جيم جام',
			'onboarding.project_folders' => 'مجلدات المشاريع',
			'onboarding.version_folders' => 'مجلدات الإصدارات',
			'onboarding.welcome_title' => 'أهلا في GodotHub',
			'onboarding.welcome_desc' => 'مأوى لكل مشروع و كل إصدارة جودوت. دعنا نخصص بعض الأمور أولا لكي تعمل بالطريقة التي تناسبك, سيأخذ الأمر دقيقة, كل شيء هنا يمكن تغييره من الإعدادات.',
			'onboarding.onboard_empty_projects' => 'لم تضف أي مجلدات, جودوت هاب لا يمكنه تحديد أي مشروع إلى أن تضيف مجلد مشاريعك, أو يمكنك إستوراد المشاريع يدويا لاحقا.',
			'onboarding.onboard_empty_versions' => 'لم تضف أي مجلدات, إصدارات جودوت المختلفة ستذهب لمجلد بيانات جودوت هاب إلا إذا عيينة واحد أخر بنفسك.',
			'onboarding.onboard_no_template_folder' => 'لم يعين أي مجلد, يمكنك دائما تخصيص هذا في الإعدادات, أو احفظ القوالب يدويا.',
			'onboarding.onboard_cloud_heading' => 'النسخة الإحتياطية السحابية',
			'onboarding.onboard_cloud_desc' => 'هل لديك نسخة احتياطية بالفعل؟ سجل الدخول مع GitHub و استرجع بيئات عملك، مشاريعك، و إعداداتك باختصار.',
			'onboarding.discovery_recent_heading' => 'Recent projects from Godot',
			'onboarding.discovery_installs_heading' => 'Godot found on this computer',
			'onboarding.discovery_scanning_projects' => 'Reading Godot\'s project manager list…',
			'onboarding.discovery_scanning_installs' => 'Looking for Godot on your PATH and in Steam…',
			'onboarding.discovery_engine' => 'Godot {{version}}',
			'onboarding.discovery_favorite' => 'Favorite',
			'onboarding.discovery_add_selected' => 'Add selected',
			'onboarding.discovery_add_selected_count' => 'Add selected ({{count}})',
			'onboarding.discovery_added_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Added ${count} projects.', one: 'Added ${count} project.', two: 'Added ${count} projects.', few: 'Added ${count} projects.', many: 'Added ${count} projects.', other: 'Added ${count} projects.', ), 
			'onboarding.discovery_added_versions' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Added ${count} versions.', one: 'Added ${count} version.', two: 'Added ${count} versions.', few: 'Added ${count} versions.', many: 'Added ${count} versions.', other: 'Added ${count} versions.', ), 
			'onboarding.discovery_link_hint' => 'Projects are linked to a matching Godot version automatically, including versions you add in the next step.',
			'onboarding.setup' => 'Setup',
			'onboarding.setup_title' => 'How do you want to use GodotHub?',
			'onboarding.setup_desc' => 'Pick a starting point. Anything you leave out is hidden and never loads, so GodotHub stays quick. You can change this anytime in Settings, under Behavior.',
			'onboarding.preview_heading' => 'Preview',
			'onboarding.step_of' => 'Step {{current}} of {{total}}',
			'onboarding.dive_in' => 'Dive In',
			'onboarding.workspace_step' => 'Workspace',
			'onboarding.first_workspace_title' => 'Create your first workspace',
			'onboarding.first_workspace_desc' => 'A workspace holds your projects, categories, and settings. Give this one a name and a look that feels like yours, you can add more later.',
			'onboarding.basics' => 'Basics',
			'onboarding.basics_title' => 'A few basics',
			'onboarding.basics_desc' => 'Pick your language, bring back a cloud backup if you have one, and choose whether Discord shows what you\'re working on.',
			'onboarding.welcome_to' => 'Welcome to',
			'onboarding.welcome_to_name' => 'Hey {{name}}, welcome to',
			'onboarding.found_title' => 'Your library is ready',
			'onboarding.found_desc' => 'Here\'s everything GodotHub found on this machine. Taking you in now.',
			'settings.storage' => 'التخزين',
			'settings.behavior' => 'الوظائف',
			'settings.display' => 'الشاشة',
			'settings.appearance' => 'المظهر',
			'settings.accessibility' => 'إمكانية الوصول',
			'settings.accessibility_desc' => 'Screen reader announcements and assistive technology options.',
			'settings.app_version_label' => 'GodotHub v{{version}}',
			'settings.landing_dashboard' => 'لوحة التحكم',
			'settings.landing_projects' => 'المشاريع',
			'settings.landing_versions' => 'الإصدارات',
			'settings.landing_news' => 'أخبار Godot',
			'settings.screen_reader_label' => 'إشعارات قارئ الشاشة',
			'settings.advanced' => 'متقدمة',
			'settings.integrations' => 'التطبيقات المتصلة',
			'settings.motion' => 'Motion',
			'settings.data' => 'Data & Backup',
			'settings.git_auth_title' => 'سجل الدخول مع {{provider}}',
			'settings.git_auth_copy_code' => 'انسخ الرمز',
			'settings.git_auth_copy_link' => 'Copy link',
			'settings.git_auth_waiting' => 'Waiting for you to authorize…',
			'settings.git_sign_in_gitlab' => 'سجل الدخول مع GitLab',
			'settings.git_connected_to' => 'متصل كـ {{host}} as @{{username}}',
			'settings.git_self_hosted_title' => 'استضافة ذاتية GitLab',
			'settings.git_self_hosted_desc' => 'Connect to your own GitLab instance. Create an OAuth application on your instance (scopes: read_repository, write_repository, read_user) and paste its base URL and Application ID.',
			'settings.git_self_hosted_url_placeholder' => 'https://gitlab.example.com',
			'settings.git_self_hosted_client_id' => 'رمز تعريف التطبيق (ID)',
			'settings.git_sign_in_self_hosted' => 'سجل الدخول مع instance',
			'settings.git_pat_title' => 'اسضافات أخرى (رموز وصول شخصية)',
			'settings.git_pat_add' => 'أضف رمزا (Token)',
			'settings.git_pat_host_placeholder' => 'e.g. codeberg.org',
			'settings.git_pat_username' => 'إسم المستخدم',
			'settings.git_pat_token' => 'الرمز (Token)',
			'settings.git_pat_save' => 'احفظ الرمز',
			'settings.git_pat_empty' => 'لم يتم إضافة أي رمز بعد.',
			'settings.git_pat_remove' => 'أزل الرمز (Token)',
			'settings.storage_title' => 'التخزين و البحث التلقائي',
			'settings.behavior_projects_title' => 'المشاريع',
			'settings.file_watchers_title' => 'مراقب التغييرات',
			'settings.last_opened_title' => 'اعرض أخر مشروع فُتح',
			'settings.github_token_title' => 'رمز GitHub API',
			'settings.titlebar_buttons' => 'أزرار شريط العنوان',
			'settings.setup_wizard' => 'قائمة الإعداد',
			'settings.setup_wizard_again' => 'أظهر قائمة الإعداد مجددا',
			'settings.restart_app' => 'أعد تشغيل التطبيق',
			'settings.restart_app_confirm_title' => 'هل تريد إعادة تشغيل GodotHub',
			'settings.restart_app_confirm_desc' => 'سيتم إغلاق التطبيق و إعادة فتحه تلقائيا. العملية التي في طور التشغيل أو الغير محفوظة ستتم مقاطعتها.',
			'settings.reset_settings' => 'أعد ضبط كل الإعدادات',
			'settings.delete_app_data' => 'احذف ملفات التطبيق',
			'settings.new_project_default' => 'مجلد البحث الإفتراضي',
			'settings.download_folder' => 'مجلد التنزيل الإفتراضي',
			'settings.system' => 'النظام',
			'settings.k12h' => '12-ساعة (2:30 PM)',
			'settings.k24h' => '24-ساعة (14:30)',
			'settings.dd_mm_yyyy' => 'DD-MM-YYYY',
			'settings.mm_dd_yyyy' => 'MM-DD-YYYY',
			'settings.yyyy_mm_dd' => 'YYYY-MM-DD',
			'settings.reset_all_title' => 'هل تريد إعادة ضبط كل الإعدادات؟',
			'settings.reset_all_desc' => 'هذا يعيد كل إعداد في هذه الصفحة, مجلدات التحميل, مجلدات المسح, المظهر, و الوظائف, إلى حالتهم الإفتراضية. لا يمكن التراجع عن هذا الخيار.',
			'settings.delete_all_title' => 'هل تريد حذف كل بيانات التطبيق?',
			'settings.delete_all_desc' => 'هذا سيحذف بشكل كامل كل بيئة عمل, مشروع, تصنيف, إصدارات مثبتة, و كل إعدادات GodotHub, و يعيدك إلى قائمة الإعداد الأولى. مجلدات مشاريعك و نسخ Godot المثبتة لن تُلمس, إلا إذا كانت في مجلد التحميل الإفتراضي, في هذه الحالة سيتم حذفهم فعلا (إصدارات Godot). هذا الخيار لا يمكن التراجع عنه.',
			'settings.empty_hint_projects' => 'لم تُضف أي مجلدات, لن يتم مسح أي مجلد أثناء الإقلاع, المشاريع الجديدة ستسألك أين تحفظ في كل مرة.',
			'settings.empty_hint_versions' => 'لم تُضف أي مجلدات, , لن يتم مسح أي مجلد أثناء الإقلاع, التنزيلات الجديدة ستستخدم مجلد بيانات التطبيق.',
			'settings.naming_convention_label' => 'مجلد تمسية المصطلحات',
			'settings.naming_keep' => 'أبقه كما هو مكتوب (My Game)',
			'settings.naming_kebab' => 'kebab-case (my-game)',
			'settings.naming_snake' => 'snake_case (my_game)',
			'settings.naming_camel' => 'camelCase (myGame)',
			'settings.naming_pascal' => 'PascalCase (MyGame)',
			'settings.naming_title' => 'Title Case (My Game)',
			'settings.theme' => 'المظهر',
			'settings.theme_preset_label' => 'إعداد المظهر',
			'settings.theme_preset_custom' => 'مُخصص',
			'settings.preset_light_group' => 'المظاهر الفَاتحة',
			'settings.preset_dark_group' => 'المظاهر المُظلمة',
			'settings.test' => 'اختبار',
			'settings.testing' => 'جاري الإختبار…',
			'settings.token_valid' => 'الرمز صالح! الحد: {{status}}',
			'settings.token_resets_in' => '(resets ~{{minutes}} min)',
			'settings.test_failed' => 'الإختبار فشل: {{error}}',
			'settings.key_space' => 'مساحة',
			'settings.no_settings_match' => 'لا يوجد أي إعداد',
			'settings.scan_result' => 'عُثر على {{projects}} مشروعا جديد و {{versions}} إصدارا جديد.',
			'settings.palette_shortcut' => 'إختصار لوحة الأوامر',
			'settings.keybind_instruction' => 'انقر على الزر أدناه، ثم اضغط على أي مفتاح لإعادة التعيين.',
			'settings.press' => 'اضغط',
			'settings.to_cancel' => 'للإلغاء',
			'settings.press_key' => 'اضغط زرا…',
			'settings.click_to_rebind' => 'اضغط لإعادة التعيين',
			'settings.close_on_open_label' => 'أغلق التطبيق عند فتح مشروع ما',
			'settings.launch_console_label' => 'افتح Godot مع الطرفية',
			'settings.builtin_console_label' => 'Use the built-in console',
			'settings.minimize_tray_label' => 'صغّر التطبيق لشريط المهام عن الإغلاق',
			'settings.reopen_label' => 'أعد فتحه عند إغلاق Godot',
			'settings.no_folder_set' => 'لم ستم تحديد أي مجلد. يمكنك مع هذا الإستوراد يدويا أو استعمال \'إحفظ كقالب\'.',
			'settings.ui_density_label' => 'كثافة واجهة المستخدم',
			'settings.text_size_label' => 'حجم الخط',
			'settings.section_godot_versions' => 'إصدارات Godot',
			'settings.scan_depth_label' => 'امسح المسار',
			'settings.icon_scan_depth_label' => 'Project icon search depth',
			'settings.download_concurrency_label' => 'التنزيلات المتتالية',
			'settings.tray_recent_label' => 'المشاريع الأخير في أيقونة شريط المهام',
			'settings.tooltip_delay_label' => 'تأخير التلميح',
			'settings.project_icon_opacity_label' => 'شفافية أيقونات المشاريع',
			'settings.time_format_label' => 'صيغة الوقت',
			'settings.date_format_label' => 'صيغة التاريخ',
			'settings.auto_scan_label' => 'المسح التلقائي عن الإقلاع',
			'settings.use_workspaces_label' => 'استخدم بيئات العمل',
			'settings.watch_projects_label' => 'راقب مجلدات المشاريع',
			'settings.watch_versions_label' => 'راقب مجلدات الإصدارات',
			'settings.watch_template_label' => 'راقب مجلدات القوالب',
			'settings.show_scrollbar_label' => 'أظهر شريط التمرير',
			'settings.animated_numbers_label' => 'تأثير الأرقام عند تغييرها',
			'settings.show_support_label' => 'أظهر زر الدعم',
			'settings.show_star_label' => 'أظهر زر النجمة',
			'settings.show_bug_label' => 'أظهر زر التبليغ عن المشاكل',
			'settings.show_tray_label' => 'أظهر زر الإشعارات',
			'settings.show_language_label' => 'أظهر زر اللغة',
			'settings.clear' => 'نظف',
			'settings.reset_to_default' => 'أعد الضبط للإعداد الإفتراضي',
			'settings.reset_appearance' => 'أعد ضبط المظهر للإعداد الإفتراضي',
			'settings.delete_all' => 'احذف الكل',
			'settings.open_setup' => 'افتح واجهة الإعداد',
			'settings.reset_colors' => 'أعد ضبط الألوان للإعداد الإفتراضي',
			'settings.folders_deep' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} folders deep', one: '${count} مجلد عميق', two: '${count} folders deep', few: '${count} folders deep', many: '${count} folders deep', other: '${count} مجلدات عميقة', ), 
			'settings.at_once' => '{{count}} في المرة',
			'settings.animation_speed_label' => 'Animation speed',
			'settings.scroll_reveal_label' => 'Scroll reveal',
			'settings.card_tilt_label' => 'Card tilt on hover',
			'settings.click_ripple_label' => 'Click ripple',
			'settings.press_bounce_label' => 'Press bounce',
			'settings.animation_intensity_label' => 'كثافة الحركة',
			'settings.animation_full' => 'كامل',
			'settings.animation_subtle' => 'جزئي',
			'settings.animation_none' => 'بلا',
			'settings.view_entrance_label' => 'تأثير الإنتقال',
			'settings.entrance_fade' => 'التلاشي',
			'settings.entrance_slide' => 'الإنزلاق',
			'settings.entrance_scale' => 'التقليص',
			'settings.entrance_none' => 'بلا',
			'settings.custom_css_label' => 'CSS مخصص',
			'settings.custom_css_placeholder' => '/* Your custom styles, e.g. */\n.card { border-radius: 4px !important; }',
			'settings.custom_css_apply' => 'طبق CSS',
			'settings.custom_css_applied' => 'تم تطبيق CSS',
			'settings.animation_threshold_label' => 'عتبة الرسوم المتحركة للقائمة',
			'settings.time_tracking_title' => 'النسخة الإحتياطة للتتبع الوقت',
			'settings.export_stats_btn' => 'صدر الإحصائيات…',
			'settings.import_stats_btn' => 'استورد الإحصائيات…',
			'settings.stats_exported' => 'تم تصدير إحصائيات الوقت.',
			'settings.clear_stats_confirm_title' => 'هل تريد مسح كل بيانات الوقت',
			'settings.clear_stats_confirm_desc' => 'This permanently deletes all time tracking history, session records, and per-project totals. This cannot be undone.',
			'settings.clear_stats_confirm_btn' => 'امسح الكل',
			'settings.stats_cleared' => 'تم مسح بيانات الوقت.',
			'settings.settings_backup_title' => 'إعدادات النسخة الإحتياطية',
			'settings.export_settings_btn' => 'صدر الإعدادات',
			'settings.import_settings_btn' => 'استورد الإعدادات',
			'settings.workspace_backup_title' => 'أنشئ نسخة إحتياطية لبيئة العمل',
			'settings.workspace_backup_export_btn' => 'صدر بيئة العمل',
			'settings.workspace_backup_restore_btn' => 'استرجع بيئة العمل',
			'settings.workspace_backup_exported' => 'تم تصدير النسخة الإحتياطية لبيئة العمل.',
			'settings.workspace_backup_imported' => 'تم إسترجاع النسخة الإحتياطية لبيئة العمل.',
			'settings.app_backup_title' => 'أنشئ نسخة إحتياطية لكل شيئ (كل بيئات العمل)',
			'settings.app_backup_export_btn' => 'صدر كل شيئ',
			'settings.app_backup_restore_btn' => 'استرجع كل شيء',
			'settings.app_backup_exported' => 'تم تصدير النسخة الإحتياطية الشاملة.',
			'settings.app_backup_imported' => 'تم استرجاع النسخة الإحتياطية الشاملة.',
			'settings.sync_title' => 'المزامنة السحابية (GitHub gist)',
			'settings.sync_push_btn' => 'ادفع',
			'settings.sync_pull_btn' => 'اسحب',
			'settings.sync_push_done' => 'تم دفع بيئة العمل لـ \'gist\' خاصتك.',
			'settings.sync_open_gist' => 'افتح \'gist\'',
			'settings.sync_last_pushed' => 'أخر عملية دفع: {{time}}',
			'settings.sync_manual_hint' => 'Lost your local data? Enter your gist URL or ID to restore from any machine.',
			'settings.sync_manual_placeholder' => 'https://gist.github.com/... or gist ID',
			'settings.sync_manual_pull_btn' => 'إسترجع',
			'settings.restore_modal_title' => 'إسترجع من السحابة',
			'settings.restore_modal_fetching' => 'جاري جلب النسخة الإحتياطية من Github…',
			'settings.restore_modal_applying' => 'جاري تطبيق النسخة الإحتياطية و إعادة التشغيل…',
			'settings.restore_modal_preview_desc' => 'نسختك الإحتياطية تحتوي على:',
			'settings.restore_modal_workspaces' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'workspaces', one: 'بيئة عمل', two: 'workspaces', few: 'workspaces', many: 'workspaces', other: 'بيئات العمل', ), 
			'settings.restore_modal_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'projects', one: 'المشروع', two: 'projects', few: 'projects', many: 'projects', other: 'المشاريع', ), 
			'settings.restore_modal_categories' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'categories', one: 'التصنيف', two: 'categories', few: 'categories', many: 'categories', other: 'التصنيفات', ), 
			'settings.restore_modal_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'templates', one: 'القالب', two: 'templates', few: 'templates', many: 'templates', other: 'القوالب', ), 
			'settings.restore_modal_time_stats' => 'Includes time tracking data',
			'settings.restore_modal_todos' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Includes ${count} to-dos', one: 'Includes ${count} to-do', two: 'Includes ${count} to-dos', few: 'Includes ${count} to-dos', many: 'Includes ${count} to-dos', other: 'Includes ${count} to-dos', ), 
			'settings.restore_modal_project_scan_dirs' => '{{count}} project scan folder(s) will be restored',
			'settings.restore_modal_version_scan_dirs' => '{{count}} Godot version folder(s) will be restored',
			'settings.restore_modal_workspace_list' => 'بيئات العمل',
			'settings.restore_modal_warning' => 'This will overwrite your current settings and workspace data. You\'ll need to restart the app to apply changes.',
			'settings.restore_modal_apply_btn' => 'طبّق و أعد التشغيل',
			'settings.restore_modal_done_title' => 'تمت إستعادة النسخة الإحتياطية',
			'settings.restore_modal_done_hint' => 'اضغط على الزر أسفله لإعادة التشغيل و تطبيق كل التغييرات.',
			'settings.settings_exported' => 'تم تصدير الإعدادات.',
			'settings.settings_imported' => 'تم استوراد الإعدادات.',
			'settings.stats_imported' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Imported stats for ${count} projects.', one: 'تم إستوراد إحصائيات ${count} مشروعا.', two: 'Imported stats for ${count} projects.', few: 'Imported stats for ${count} projects.', many: 'Imported stats for ${count} projects.', other: 'تم إستوراد إحصائيات ${count} مشروعا.', ), 
			'settings.raised_contrast_label' => 'Raised surface contrast',
			'settings.raised_contrast_value' => '{{value}}%',
			'settings.token_help_desc' => 'أنشئ رمزًا مميزًا على github.com/settings/tokens. ما عليك سوى تحديد نطاق repo إذا كنت ترغب في الوصول إلى المستودع الخاص، وإلا فاترك جميع النطاقات غير محددة. لا توجد أذونات حساسة مطلوبة.',
			'settings.discord_app_id_label' => 'Discord Application ID',
			'settings.discord_app_id_placeholder' => 'Leave empty to use the built-in default',
			'settings.discord_app_id_desc' => 'Create an application in the Discord Developer Portal and paste its Application ID here to use your own instead of GodotHub\'s built-in one. The activity shows under that application\'s name.',
			'settings.discord_developer_portal' => 'Discord Developer Portal',
			'settings.discord_builtin_hint' => 'Using the built-in GodotHub application.',
			'settings.discord_show_projects_label' => 'أظهر إسم المشروع',
			'settings.discord_excluded_label' => 'المشاريع المعزولة',
			'settings.discord_exclude_project' => 'أضف مشروعا',
			'settings.discord_excluded_empty' => 'No excluded projects.',
			'settings.discord_excluded_remove' => 'Remove from excluded projects',
			'settings.discord_custom_label' => 'تخصيص الحالة',
			'settings.discord_custom_add' => 'أضف مشروعا',
			'settings.discord_custom_details_placeholder' => 'سطر التفاصيل',
			'settings.discord_custom_state_placeholder' => 'سطر الحالة',
			'settings.discord_custom_remove' => 'Remove custom presence',
			'settings.search_placeholder' => 'ابحث في الإعدادات…',
			'settings.interface_label' => 'واجهة المستخدم',
			'settings.card_layout_label' => 'تخطيط البطاقة',
			'settings.landing_tab_label' => 'الصفحة الأساسية الإفتراضية',
			'settings.language_complete' => 'مكتملة',
			'settings.language_beta' => 'تجريبية',
			'settings.language_incomplete' => 'غير مكتملة',
			'settings.use_os_decorations' => 'استخدم مظهر نافذة نظام التشغيل',
			'settings.credits' => 'المطورون',
			'settings.credits_developer' => 'تم الإنشاء بواسطة',
			'settings.credits_built_with' => 'تم البناء بواسطة',
			'settings.credits_contributors' => 'المساهمون',
			'settings.experimental' => 'تجريبية',
			'settings.customize_view_label' => 'زر تخصيص الواجهة',
			'settings.fixed_sidebar_resize_knob_label' => 'ثبت مقبض تغيير حجم الشريط الجانبي',
			'settings.desktop_notifications_label' => 'إشعار سطح المكتب',
			'settings.colored_titlebar_buttons_label' => 'إستعمل أزرار نافذة ملونة',
			'settings.project_todos_label' => 'Project Next Steps',
			'settings.mise_label' => 'Use mise for Godot versions',
			'settings.mise_detected' => 'Detected mise {{version}}',
			'settings.mise_not_found' => 'mise was not found on your PATH, so this stays off until you install it.',
			'settings.cli_tool_title' => 'Command-line tool',
			'settings.cli_tool_install' => 'Install',
			'settings.cli_tool_installing' => 'Installing...',
			'settings.cli_tool_installed_msg' => 'Installed. Open a new terminal, then run: godothub',
			'settings.cli_tool_uninstalled_msg' => 'Removed. The godothub command is no longer on your PATH.',
			'settings.git_auth_step_copy' => 'Copy your code',
			'settings.git_auth_step_paste' => 'Paste it on {{provider}}',
			'settings.git_auth_step_approve' => 'Approve GodotHub',
			'settings.git_auth_copy_and_open' => 'Copy code & open {{provider}}',
			'settings.git_auth_copied' => 'Copied',
			'settings.git_auth_expires_in' => 'Expires in {{time}}',
			'settings.git_auth_expired' => 'This code has expired',
			'settings.git_auth_failed' => 'Couldn’t connect',
			'settings.git_auth_try_again' => 'Try again',
			'settings.git_auth_success_hint' => 'You can close this window.',
			'settings.show_changelog_label' => 'Show changelog button',
			'settings.features_title' => 'Features',
			'settings.features_desc' => 'Choose which parts of GodotHub you use. Hidden features leave the sidebar and stop loading or running in the background.',
			'settings.features_always_on' => 'Always on',
			'settings.features_optional' => 'Optional',
			'settings.features_enabled_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} features on', one: '${count} feature on', two: '${count} features on', few: '${count} features on', many: '${count} features on', other: '${count} features on', ), 
			'settings.setup_profile_minimal' => 'Minimal',
			'settings.setup_profile_minimal_desc' => 'Just projects and Godot versions. The lightest, fastest setup.',
			'settings.setup_profile_essentials' => 'Essentials',
			'settings.setup_profile_essentials_desc' => 'Adds the Asset Store, templates, and categories.',
			'settings.setup_profile_studio' => 'Studio',
			'settings.setup_profile_studio_desc' => 'Essentials plus the dashboard, vault, storage, and workspaces.',
			'settings.setup_profile_complete' => 'Everything',
			'settings.setup_profile_complete_desc' => 'Every feature GodotHub has, including Godot news.',
			'settings.setup_profile_custom' => 'Custom',
			'settings.setup_profile_custom_desc' => 'Turn individual features on or off.',
			'settings.feature_desc_dashboard' => 'An overview of your activity, playtime, and recent projects.',
			'settings.feature_desc_templates' => 'Start new projects from your own reusable templates.',
			'settings.feature_desc_vault' => 'Keep reusable scripts, scenes, and assets in one library.',
			'settings.feature_desc_storage' => 'See how much disk space projects and engines use.',
			'settings.feature_desc_asset_store' => 'Browse and install addons and demos from the Godot Asset Library.',
			'settings.feature_desc_categories' => 'Group your project list into folders.',
			'settings.feature_desc_workspaces' => 'Switch between separate sets of projects and settings.',
			'todos.next_steps' => 'Next steps',
			'todos.saving_tasks' => 'Saving tasks',
			'todos.pending_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} pending', one: '${count} pending', two: '${count} pending', few: '${count} pending', many: '${count} pending', other: '${count} pending', ), 
			'todos.completed_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} completed', one: '${count} completed', two: '${count} completed', few: '${count} completed', many: '${count} completed', other: '${count} completed', ), 
			'todos.new_task' => 'New task',
			'todos.hide_next_steps' => 'Hide next steps',
			'todos.save_changes_failed' => 'Could not save the changes.',
			'todos.loading_tasks' => 'Loading tasks...',
			'todos.load_tasks_failed' => 'Could not load tasks',
			'todos.data_unchanged' => 'Your data was not modified.',
			'todos.empty_title' => 'No tasks yet',
			'todos.empty_description' => 'Add the first next step for this project.',
			'todos.create_task' => 'Create task',
			'todos.all_completed_title' => 'All done',
			'todos.all_completed_description' => 'You completed all the next steps for this project.',
			_ => null,
		} ?? switch (path) {
			'todos.footer_hint' => 'Use the list to keep track of the project\'s next steps.',
			'todos.view_all' => 'View all',
			'todos.delete_task_title' => 'Delete task?',
			'todos.delete_task_description' => 'The task <strong>“{{title}}”</strong> will be deleted. This action cannot be undone.',
			'todos.task' => 'Task',
			'todos.area' => 'Discipline',
			'todos.status' => 'Status',
			'todos.due_date' => 'Due date',
			'todos.sort_by_status' => 'Sort by status',
			'todos.sort_by_due_date' => 'Sort by due date',
			'todos.change_status' => 'Change status: {{status}}',
			'todos.overdue' => 'Overdue',
			'todos.mark_completed' => 'Mark task as completed',
			'todos.mark_not_completed' => 'Mark task as not completed',
			'todos.view_task_details' => 'View task details: {{title}}',
			'todos.task_actions' => 'Task actions',
			'todos.edit' => 'Edit',
			'todos.status_todo' => 'To do',
			'todos.status_paused' => 'Paused',
			'todos.status_in_progress' => 'In progress',
			'todos.status_done' => 'Completed',
			'todos.area_programming' => 'Programming',
			'todos.area_art' => 'Art',
			'todos.area_audio' => 'Audio',
			'todos.area_design' => 'Design',
			'todos.area_narrative' => 'Narrative',
			'todos.area_other' => 'Other',
			'todos.edit_task' => 'Edit task',
			'todos.title' => 'Title',
			'todos.title_placeholder' => 'E.g.: Create main menu',
			'todos.description_placeholder' => 'Add more details about what needs to be done...',
			'todos.no_due_date' => 'No due date',
			'todos.remove_due_date' => 'Remove due date',
			'todos.past_due_date' => 'This due date has passed',
			'todos.save_task_failed' => 'Could not save the task. Try again.',
			'todos.add_task' => 'Add task',
			'todos.no_description' => 'No description',
			'todos.tomorrow' => 'Tomorrow',
			'todos.due_in_days' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Due in ${count} days', one: 'Due in ${count} day', two: 'Due in ${count} days', few: 'Due in ${count} days', many: 'Due in ${count} days', other: 'Due in ${count} days', ), 
			'todos.overdue_yesterday' => 'Was due yesterday',
			'todos.overdue_days' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Overdue by ${count} days', one: 'Overdue by ${count} day', two: 'Overdue by ${count} days', few: 'Overdue by ${count} days', many: 'Overdue by ${count} days', other: 'Overdue by ${count} days', ), 
			'todos.scan_code' => 'Scan code',
			'todos.scan_code_hint' => 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed',
			'todos.comment_scan_summary' => 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened',
			'todos.comment_scan_none' => 'Code scan found no changes',
			'todos.commit_closed' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Completed ${count} to-dos from commit messages', one: 'Completed ${count} to-do from a commit message', two: 'Completed ${count} to-dos from commit messages', few: 'Completed ${count} to-dos from commit messages', many: 'Completed ${count} to-dos from commit messages', other: 'Completed ${count} to-dos from commit messages', ), 
			'todos.linked_file' => 'Linked file',
			'todos.linked_file_placeholder' => 'res://scenes/player.tscn',
			'todos.linked_file_hint' => 'Link a scene, script or resource from this project.',
			'todos.linked_file_invalid' => 'Use a res:// path from this project.',
			'todos.open_linked_file' => 'Open {{path}}',
			'todos.open_file' => 'Open',
			'todos.source_comment' => 'Imported from a {{tag}} comment',
			'todos.closed_by_commit' => 'Completed by commit {{hash}}: {{subject}}',
			'todos.closed_by_comment_removed' => 'Completed because its comment was removed from the code',
			'todos.todo_reference' => 'Reference',
			'todos.todo_reference_hint' => 'Write "Fixes {{ref}}" in a commit message to complete it automatically.',
			'todos.git_activity_loading' => 'Looking through Git history…',
			'todos.git_activity_empty' => 'No commits or branches mention {{ref}} yet.',
			'todos.git_branches' => 'Branches',
			'todos.git_commit_closes' => 'Closes',
			'todos.quick_add_placeholder' => 'Add a to-do and press Enter',
			'todos.priority' => 'Priority',
			'todos.priority_none' => 'None',
			'todos.priority_low' => 'Low',
			'todos.priority_medium' => 'Medium',
			'todos.priority_high' => 'High',
			'todos.priority_label' => '{{priority}} priority',
			'todos.checklist' => 'Checklist',
			'todos.checklist_add_placeholder' => 'Add a checklist item and press Enter',
			'todos.checklist_remove' => 'Remove item',
			'todos.checklist_progress' => '{{done}} of {{total}} done',
			'todos.completed_on' => 'Done {{date}}',
			'todos.completed_on_full' => 'Completed {{date}}',
			'todos.search_tasks_placeholder' => 'Search to-dos…',
			'todos.all_areas' => 'All areas',
			'todos.no_matching_tasks' => 'No to-dos match your search.',
			'todos.open_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} to-dos', one: '${count} to-do', two: '${count} to-dos', few: '${count} to-dos', many: '${count} to-dos', other: '${count} to-dos', ), 
			'todos.overdue_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} overdue', one: '${count} overdue', two: '${count} overdue', few: '${count} overdue', many: '${count} overdue', other: '${count} overdue', ), 
			'todos.tile_summary' => '{{overdue}} overdue · {{soon}} due this week',
			'todos.tile_empty' => 'Nothing overdue or due this week.',
			'todos.due_notification_title' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} to-dos are due', one: 'To-do due: {{title}}', two: '${count} to-dos are due', few: '${count} to-dos are due', many: '${count} to-dos are due', other: '${count} to-dos are due', ), 
			'todos.due_notification_more' => 'and {{count}} more',
			'versions.standard' => 'القياسية',
			'versions.unbound' => 'unbound',
			'versions.mono' => 'Mono',
			'versions.both' => 'معا',
			'versions.stable' => 'مستقرة',
			'versions.unstable' => 'غير مستقرة',
			'versions.rename' => 'أعد التسمية',
			'versions.open_editor' => 'افتح المحرر',
			'versions.open_editor_with_console' => 'افتح المحرر مع الطرفية',
			'versions.more_editor_launch_options' => 'إعدادات أخرى',
			'versions.open_install_folder' => 'افتح مجلد التنزيلات',
			'versions.type' => 'النوع',
			'versions.channel' => 'القناة',
			'versions.fetch_error' => 'لم يكن بالمستطاع جلب الإصدارات المتاحة.',
			'versions.paused_dot' => 'متوقف · ',
			'versions.available_title' => 'الإصدارات المتوفرة',
			'versions.no_versions_match' => 'لا توجد إصدارات مثبتة متوافقة',
			'versions.no_available_versions_match' => 'لا توجد إصدارات متوافقة',
			'versions.open' => 'افتح',
			'versions.install' => 'ثبت',
			'versions.mb' => 'MB',
			'versions.resume_download' => 'استئنف التنزيل',
			'versions.pause_download' => 'أوقف التنزيل مؤقتا',
			'versions.cancel_download' => 'ألغي التنزيل',
			'versions.installed_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'لا توجد تثبيتات', one: 'مثبت', two: 'مثبت', few: 'مثبت', many: 'مثبت', other: 'مثبت', ), 
			'versions.installed_label' => 'مثبت',
			'versions.original_name' => 'الأصلي',
			'versions.source' => 'المصدر',
			'versions.source_github' => 'GitHub',
			'versions.source_archive' => 'Godot أرشيف',
			'versions.source_mise' => 'mise',
			'versions.switch_to_archive' => 'بدل لأرشيف Godot',
			'versions.sort_version_latest' => 'الأحدث',
			'versions.sort_version_oldest' => 'الأقدم',
			'versions.sort_version_recently_installed' => 'المثبت مؤخرا',
			'versions.sort_version_oldest_installed' => 'المثبت قديما',
			'versions.set_as_current' => 'Set as Current',
			'versions.unset_current' => 'Unset Current',
			'versions.current_set_title' => 'Version Set as Current',
			'versions.current_dir_label' => 'Folder',
			'versions.current_copy' => 'Copy',
			'versions.current_copied' => 'Copied',
			'versions.current_copy_alias' => 'Copy alias path',
			'versions.current_copy_dir' => 'Copy folder path',
			'versions.current_open_folder' => 'Open Alias Folder',
			'versions.current_path_hint' => 'Add the folder above to your PATH to run "Godot" from any terminal, script, or tool. The alias always follows the current version, so pinning another version or uninstalling this one updates it automatically.',
			'versions.current_shim_note' => 'Windows symlinks need Developer Mode or admin rights, so a launcher script was created instead. It behaves the same from the command line.',
			'versions.mono_short' => 'mono',
			'versions.aliases_manage' => 'Aliases',
			'versions.aliases_title' => 'Version Aliases',
			'versions.aliases_empty' => 'No aliases yet. Pick a version above, give the command a name, and it will appear in the aliases folder.',
			'versions.aliases_no_versions' => 'Install a Godot version first to create an alias.',
			'versions.aliases_path_hint' => 'Add the aliases folder to your PATH to run these names from any terminal or tool. The "Godot" command from the current version pin lives in the same folder.',
			'versions.alias_create' => 'Create Alias',
			'versions.alias_add' => 'Add Alias',
			'versions.alias_name_label' => 'Alias name',
			'versions.alias_name_placeholder' => 'godot-mono',
			'versions.alias_copy_path' => 'Copy alias path',
			'versions.alias_shim_badge' => 'script',
			'versions.alias_mono_script_note' => 'Mono builds load GodotSharp from the folder next to the executable, so on Windows the alias is created as a launcher script instead of a link.',
			'versions.alias_create_all' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: 'Create ${count} Aliases', one: 'Create Alias', two: 'Create ${count} Aliases', few: 'Create ${count} Aliases', many: 'Create ${count} Aliases', other: 'Create ${count} Aliases', ), 
			'versions.aliases_batch_created' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} aliases created', one: '1 alias created', two: '${count} aliases created', few: '${count} aliases created', many: '${count} aliases created', other: '${count} aliases created', ), 
			'versions.aliases_batch_skipped' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} aliases skipped', one: '1 alias skipped', two: '${count} aliases skipped', few: '${count} aliases skipped', many: '${count} aliases skipped', other: '${count} aliases skipped', ), 
			'versions.alias_queue_duplicate' => '"{{name}}" is already in the list',
			'versions.alias_remove' => 'Remove alias',
			'versions.alias_remove_title' => 'Remove this alias?',
			'versions.alias_remove_desc' => 'The command "{{name}}" will stop working. The Godot version itself stays installed.',
			'versions.managed_by_mise' => 'mise',
			'versions.mise_installing' => 'Installing with mise…',
			'versions.mise_sync' => 'Sync',
			'versions.mise_sync_title' => 'Import the Godot versions mise has installed so they show up here.',
			'versions.mise_missing' => 'mise not found',
			'versions.mise_uninstall_desc' => 'mise will uninstall {{tag}} from its own store. Projects that pin it in mise.toml will need it installed again.',
			'versions.export_templates_installed' => 'Templates',
			'versions.export_templates_missing' => 'No templates',
			'versions.export_templates_install' => 'Install export templates',
			'versions.export_templates_remove' => 'Remove export templates',
			'versions.export_templates_remove_title' => 'Remove export templates?',
			'versions.export_templates_remove_desc' => 'The export templates for {{tag}} will be deleted from disk. You can download them again later.',
			'versions.export_templates_remove_confirm' => 'Remove',
			'versions.export_templates_open_folder' => 'Open templates folder',
			'versions.templates_folder' => 'مجلد القوالب',
			'versions.versions_folder' => 'مجلد الإصدارات',
			'versions.export_templates_installed_toast' => 'Export templates installed for {{tag}}',
			'versions.export_templates_install_failed' => 'Couldn\'t install export templates: {{error}}',
			'versions.export_templates_removed_toast' => 'Export templates removed',
			'versions.export_templates_orphans_title' => 'Unused template folders',
			'versions.export_templates_orphans_desc' => 'These folders don\'t match a Godot version managed by GodotHub.',
			'versions.export_templates_orphan_delete' => 'Delete folder',
			'versions.export_templates_orphan_delete_title' => 'Delete this template folder?',
			'versions.export_templates_orphan_delete_desc' => '"{{folder}}" will be deleted from disk.',
			'versions.export_templates_orphan_deleted' => 'Template folder deleted',
			'versions.export_templates_choose' => 'Choose export templates',
			'versions.export_templates_selected' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} templates selected', one: '1 template selected', two: '${count} templates selected', few: '${count} templates selected', many: '${count} templates selected', other: '${count} templates selected', ), 
			'versions.export_templates_size_summary' => '~{{download}} download · {{installed}} on disk',
			'versions.export_templates_download_selected' => 'Download selected',
			'versions.export_templates_loading_options' => 'Checking this release\'s available templates…',
			'versions.export_templates_options_failed' => 'Couldn\'t load the templates for this release.',
			'versions.export_templates_available' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} available template groups', one: '1 available template group', two: '${count} available template groups', few: '${count} available template groups', many: '${count} available template groups', other: '${count} available template groups', ), 
			'versions.export_templates_select_all' => 'Select all',
			'versions.export_templates_files' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ar'))(count, zero: '${count} template files', one: '1 template file', two: '${count} template files', few: '${count} template files', many: '${count} template files', other: '${count} template files', ), 
			'versions.export_templates_option_installed' => 'Installed',
			'versions.export_templates_keep_existing' => 'Expand a platform to choose architectures or individual files. Only selected files are downloaded. Your existing templates are kept.',
			'versions.export_templates_uninstall_named' => 'Uninstall {{name}}',
			'versions.export_templates_uninstall_failed' => 'Couldn\'t uninstall templates: {{error}}',
			'versions.export_templates_category_desktop' => 'Desktop',
			'versions.export_templates_category_mobile' => 'Mobile',
			'versions.export_templates_category_web' => 'Web',
			'versions.export_templates_category_common' => 'Common',
			'versions.export_templates_category_other' => 'Other',
			'versions.export_templates_web_standard' => 'Web',
			'versions.export_templates_web_extensions' => 'Web with Extensions',
			'versions.export_templates_web_single_threaded' => 'Web Single-Threaded',
			'versions.export_templates_web_extensions_single_threaded' => 'Web with Extensions Single-Threaded',
			'versions.export_templates_refresh' => 'Refresh available templates',
			'versions.download_failed_title' => 'فشل التنزيل',
			'versions.download_failed_asset_label' => 'الملف',
			'versions.download_failed_error_label' => 'تفاصيل الخطأ',
			'versions.download_failed_copy' => 'نسخ التفاصيل',
			'versions.download_failed_hint' => 'الأسباب الشائعة: شبكة أو وكيل محجوب، برنامج مكافحة فيروسات يحجب التنزيل، مجلد تنزيل غير موجود أو للقراءة فقط، أو مساحة قرص منخفضة.',
			'versions.custom_build_badge' => 'Custom build',
			'versions.add_custom_build' => 'Add custom build…',
			'versions.adding_custom_build' => 'Adding custom build…',
			_ => null,
		};
	}
}
