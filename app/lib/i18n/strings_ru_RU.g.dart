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
class TranslationsRuRu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRuRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ruRu,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ru-RU>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsRuRu _root = this; // ignore: unused_field

	@override 
	TranslationsRuRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRuRu(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$changelog$ru_RU changelog = _Translations$changelog$ru_RU._(_root);
	@override late final _Translations$common$ru_RU common = _Translations$common$ru_RU._(_root);
	@override late final _Translations$dashboard$ru_RU dashboard = _Translations$dashboard$ru_RU._(_root);
	@override late final _Translations$git$ru_RU git = _Translations$git$ru_RU._(_root);
	@override late final _Translations$nav$ru_RU nav = _Translations$nav$ru_RU._(_root);
	@override late final _Translations$onboarding$ru_RU onboarding = _Translations$onboarding$ru_RU._(_root);
	@override late final _Translations$settings$ru_RU settings = _Translations$settings$ru_RU._(_root);
	@override late final _Translations$todos$ru_RU todos = _Translations$todos$ru_RU._(_root);
	@override late final _Translations$versions$ru_RU versions = _Translations$versions$ru_RU._(_root);
}

// Path: changelog
class _Translations$changelog$ru_RU extends Translations$changelog$en_US {
	_Translations$changelog$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get changelog_title => 'Журнал изменений';
	@override String get no_entries => 'Нет записей в журнале изменений';
	@override String get delete_entry_title => 'Удалить запись из журнала изменений?';
	@override String get delete_entry_desc => 'Это приведет к постоянному удалению этой записи, операция необратима.';
	@override String get changelog_subtitle => 'История обновлений GodotHub.';
	@override String get edit_entry_aria => 'Edit {{version}}';
	@override String get delete_entry_aria => 'Delete {{version}}';
	@override String get added => 'Добавлено';
	@override String get fixed => 'Исправлено';
	@override String get improved => 'Улучшено';
}

// Path: common
class _Translations$common$ru_RU extends Translations$common$en_US {
	_Translations$common$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get new_project => 'Новый проект';
	@override String get import_project => 'Импортировать проект';
	@override String get search => 'Поиск';
	@override String get cancel => 'Отмена';
	@override String get save => 'Сохранить';
	@override String get delete => 'Удалить';
	@override String get close => 'Закрыть';
	@override String get loading => 'Загрузка...';
	@override String get retry => 'Повторить';
	@override String get stop => 'Остановить';
	@override String get refresh => 'Обновить';
	@override String get scroll_to_top => 'Прокрутить к началу';
	@override String get quick_commands => 'Быстрые команды';
	@override String get minimize => 'Свернуть';
	@override String get close_sidebar => 'Закрыть боковую панель';
	@override String get star_on_github => 'Поставить звезду на GitHub';
	@override String get support_dev => 'Поддержите разработку на Patreon. Вы можете отключить эту кнопку в Настройках';
	@override String get support => 'Поддержать';
	@override String get restore => 'Восстановить';
	@override String get maximize => 'Развернуть на полный экран';
	@override String get importing_project => 'Импортирование проектов...';
	@override String get importing_version => 'Импортирование версий Godot…';
	@override String get scanning_projects => 'Сканирование проектов…';
	@override String get scanning_versions => 'Сканирование версий Godot…';
	@override String get queued => 'В очереди';
	@override String get download_queue_move_up => 'Move earlier in queue';
	@override String get download_queue_move_down => 'Move later in queue';
	@override String get running => 'Выполняется';
	@override String running_projects_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} project running',
		few: '${count} projects running',
		many: '${count} projects running',
		other: '${count} projects running',
	);
	@override String get active => 'Активные';
	@override String get done => 'Готово';
	@override String get paused => 'Пауза';
	@override String get no_tasks_running => 'Нет задач в работе';
	@override String get checking_changes => 'Проверка изменений…';
	@override String get cloning => 'Клонирование…';
	@override String get clone_import => 'Клонировать и импортировать';
	@override String get import => 'Импорт';
	@override String get syncing => 'Синхронизация…';
	@override String get edit_entry => 'Изменить запись в changelog';
	@override String get new_entry => 'Новая запись в changelog';
	@override String get checking_updates => 'Проверка обновлений…';
	@override String get up_to_date => 'Актуально';
	@override String get downloading_update => 'Загрузка…';
	@override String get install_update => 'Установить';
	@override String get restart_now => 'Перезапустить сейчас';
	@override String get update_downloaded => 'Обновление загружено!';
	@override String get restart_to_apply => 'Перезапустите GodotHub, чтобы применить обновление.';
	@override String get update_applied_desc => 'Обновление загружено и будет применено при следующем перезапуске GodotHub. Пожалуйста, закройте и снова откройте приложение, чтобы завершить обновление.';
	@override String get is_latest => 'v{{version}}, последняя версия.';
	@override String get percent_complete => 'Готово: {{percent}}%';
	@override String get expand_sidebar => 'Развернуть боковую панель';
	@override String get collapse_sidebar => 'Свернуть боковую панель';
	@override String get saving => 'Сохранение…';
	@override String get save_changes => 'Сохранить изменения';
	@override String get add_entry => 'Добавить запись';
	@override String get scan_for_projects => 'Сканировать проекты';
	@override String get create_workspace => 'Создать рабочее пространство';
	@override String get report_a_bug => 'Сообщить об ошибке';
	@override String get report_bug => 'Сообщить об ошибке';
	@override String get app_error_title => 'Что то пошло не так';
	@override String get app_error_desc => 'GodotHub столкнулся с непредвиденной ошибкой и не смог отрисовать интерфейс. Подробности ниже: проверьте консоль (правый клик → Inspect) чтобы увидеть полный stack trace.';
	@override String get reload => 'Перезагрузить';
	@override String get view_error_title => 'This view couldn\'t load';
	@override String get view_error_desc => 'The rest of GodotHub still works. Try loading this view again, or switch to another one.';
	@override String get error_details => 'Technical details';
	@override String get remove_folder => 'Удалить папку';
	@override String get make_this_default => 'Сделать это {{label}}';
	@override String get suggested_from_workspaces => 'Предложено из других рабочих пространств';
	@override String get from_workspace => 'из {{name}}';
	@override String get add_folder => 'Добавить папку';
	@override String get default_folder => 'По умолчанию';
	@override String get default_downloads_go_to => 'Загрузки по умолчанию будут сохраняться в «{{path}}»';
	@override String get open_terminal => 'Открыть терминал';
	@override String get downloading_version => 'Загрузка {{version}}';
	@override String get downloading_asset => 'Загрузка {{title}}';
	@override String get asset_download_failed => 'Не удалось скачать шаблон';
	@override String get scan_for_engines => 'Сканировать движки';
	@override String get import_version => 'Импортировать версию';
	@override String get sync_templates_from_directory => 'Синхронизировать шаблоны из каталога';
	@override String get section_navigation => 'Навигация';
	@override String get section_projects => 'Проекты';
	@override String get section_views => 'Views';
	@override String get section_workspaces => 'Рабочие области';
	@override String get section_help => 'Помощь';
	@override String get section_engines => 'Движки';
	@override String get section_templates => 'Шаблоны';
	@override String get section_versions => 'Версии';
	@override String get section_news => 'Новости';
	@override String get skip_setup => 'Пропустить настройку';
	@override String get back => 'Назад';
	@override String get finishing => 'Завершение…';
	@override String get get_started => 'Приступить';
	@override String get scanning => 'Сканирование…';
	@override String get scan_now => 'Сканировать сейчас';
	@override String get scan_complete => 'Scan complete';
	@override String get scan_failed => 'Scan failed';
	@override String get uncategorized => 'Без категории';
	@override String get all => 'All';
	@override String get no_filter => 'No Filter';
	@override String get cannot_undo => 'Это нельзя отменить.';
	@override String get deleting => 'Удаление…';
	@override String get open_project => 'Открыть проект';
	@override String get play_project => 'Play';
	@override String get play_project_tooltip => 'Play the game without opening editor';
	@override String get no_version_selected => 'Не выбрана версия';
	@override String get open_with_console => 'Открыть в консоли';
	@override String get open_folder => 'Открыть папку';
	@override String get open_in_ide => 'Открыть в IDE';
	@override String get category => 'Категория';
	@override String get none => 'Нет';
	@override String get project_size => 'Размер проекта';
	@override String get project_size_scanning => 'Scanning project files…';
	@override String get project_size_empty => 'No files found';
	@override String get launch_arguments => 'Аргументы запуска';
	@override String get save_as_template => 'Сохранить как шаблон';
	@override String get git => 'Git';
	@override String get add => 'Добавить';
	@override String get color_label => 'Цвет';
	@override String get icon_label => 'Иконка';
	@override String get expand => 'Развернуть';
	@override String get collapse => 'Свернуть';
	@override String file_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} file',
		few: '${count} файл',
		many: '${count} файл',
		other: '${count} files',
	);
	@override String folder_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} folder',
		few: '${count} папка',
		many: '${count} папка',
		other: '${count} folders',
	);
	@override String get template_empty => 'Этот шаблон пустой.';
	@override String get categories => 'Категории';
	@override String get category_folders_hint => 'Проекты, найденные в папках категории, автоматически назначаются ей.';
	@override String get assign_folder => 'Назначить папку';
	@override String get assign_folder_to_category => 'Назначить папку категории {{name}}';
	@override String get unassign_folder_aria => 'Убрать папку {{folder}} из этой категории';
	@override String get new_category_placeholder => 'Новая категория…';
	@override String get no_categories_yet => 'Без категории, добавьте из списка выше.';
	@override String get edit_category => 'Редактировать {{name}}';
	@override String get delete_category => 'Удалить {{name}}';
	@override String get delete_category_title => 'Удалить категорию?';
	@override String get delete_category_desc => '"{{name}}" будет удален. Проекты, перемещённые в эту категорию, будут перенесены в «Без категории». При этом ничего на диске не затрагивается.';
	@override String get project_name_label => 'Название';
	@override String get folder_name_preview => 'Папка. Конвенция: {{name}}';
	@override String get folder_name_hint => 'Имя папки определяется из названия проекта с использованием вашей схемы именования.';
	@override String get template_preview_aria => 'Предпросмотр {{name}}';
	@override String get project_location_label => 'Местоположение';
	@override String get choose_folder_placeholder => 'Выберите папку';
	@override String get browse => 'Обзор';
	@override String get blank_template => 'По умолчанию';
	@override String get template_optional => 'Шаблон (необязательно)';
	@override String get category_optional => 'Категория (необязательно)';
	@override String get no_category_label => 'Без категории';
	@override String get godot_version_label => 'Версия Godot';
	@override String get no_engine_warning => 'Движок ещё не установлен, сначала возьмите его на вкладке «Версии».';
	@override String get change_icon => 'Изменить';
	@override String get choose_icon => 'Выбрать';
	@override String get icon_format_desc => 'SVG, PNG или JPG. По умолчанию, логотип Godot.';
	@override String get other_settings_label => 'Другие настройки';
	@override String get init_git_label => 'Инициализировать репозиторий Git';
	@override String get init_git_desc => 'Добавляет Godot .gitignore и .gitattributes, а затем создаёт начальный коммит в main.';
	@override String get init_git_unavailable => 'Установите Git и перезапустите GodotHub, чтобы использовать это.';
	@override String get initializing_git => 'Настройка Git…';
	@override String get git_init_warning_title => 'Проект создан, проверьте Git init';
	@override String get git_option_gitignore => 'Godot .gitignore';
	@override String get git_option_gitattributes => '.gitattributes';
	@override String get git_option_readme => 'README.md';
	@override String get git_option_license => 'License';
	@override String get git_option_no_license => 'No license';
	@override String get create_remote_label => 'Create repository on GitHub/GitLab';
	@override String get create_remote_desc => 'Creates a repository on your connected account and pushes the initial commit.';
	@override String get remote_private => 'Приватный';
	@override String get remote_public => 'Публичный';
	@override String get creating_remote_repo => 'Creating remote repository…';
	@override String get remote_repo_created_title => 'Remote repository created';
	@override String get create_project_done => 'Готово';
	@override String get create_project_btn => 'Создать проект';
	@override String get creating => 'Создание…';
	@override String get create_project_error => 'Укажите название проекта и папку, в которой он будет создан.';
	@override String get create_workspace_title => 'Новое рабочее пространство';
	@override String get workspace_name_label => 'Имя';
	@override String get workspace_name_placeholder => 'Работа, Личное, Игровой джем…';
	@override String get workspace_name_required_error => 'Укажите имя рабочего пространства.';
	@override String get edit_workspace_title => 'Изменить рабочее пространство';
	@override String get cant_delete_only_workspace => 'Вы не можете удалить единственное рабочее пространство';
	@override String get delete_workspace_title => 'Удалить рабочее пространство?';
	@override String get delete_workspace_desc => '"{{name}}" и все что с ним связано (настройки, проекты, категории) будут удалены. Файлы на диске не будут затронуты. Установленные версии Godot так же не будут затронуты, так как распространяются на все рабочие пространства.';
	@override String get other => 'Другое';
	@override String get args_label => 'Аргументы';
	@override String get args_placeholder => 'например, --debug --single-window';
	@override String get args_suggestions => 'Предложения';
	@override String get args_desc_separate_prefix => 'Разделяйте аргументы пробелами. Флаги со значениями, например';
	@override String get args_desc_separate_suffix => 'используйте два токена.';
	@override String get args_debug => '--debug';
	@override String get args_debug_desc => 'Запуск с откладкой';
	@override String get args_single_window => '--single-window';
	@override String get args_single_window_desc => 'Принудительно включить режим одного окна';
	@override String get args_opengl3 => '--rendering-driver opengl3';
	@override String get args_opengl3_desc => 'Использовать рендер-драйвер OpenGL 3';
	@override String get args_vulkan => '--rendering-driver vulkan';
	@override String get args_vulkan_desc => 'Использовать рендер-драйвер Vulkan';
	@override String get args_headless => '--headless';
	@override String get args_headless_desc => 'Запуск без окна';
	@override String get args_verbose => '--verbose';
	@override String get args_verbose_desc => 'Подробный вывод отладки в лог';
	@override String get args_editor => '--editor';
	@override String get args_editor_desc => 'Открыть редактор (можно использовать -e)';
	@override String get args_build_solutions => '--build-solutions';
	@override String get args_build_solutions_desc => 'Собирать C#-решения при открытии';
	@override String get args_gpu_index => '--gpu-index 1';
	@override String get args_gpu_index_desc => 'Использовать GPU с индексом 1 (дискретная видеокарта)';
	@override String get sort_categories => 'Категории';
	@override String get sort_recent => 'Недавно открытые';
	@override String get sort_manual => 'Вручную';
	@override String get sort_name_asc => 'Имя (A–Z)';
	@override String get sort_name_desc => 'Имя (Z–A)';
	@override String get sort_created_desc => 'Дата добавления (новые)';
	@override String get sort_created_asc => 'Дата добавления (старые)';
	@override String get sort_time_desc => 'Total time';
	@override String get filter => 'Filter';
	@override String get no_templates_yet => 'Пока нет шаблонов. Щёлкните правой кнопкой по проекту или откройте меню «Ещё» и выберите <1>Сохранить как шаблон</1>, чтобы создать его.';
	@override String get godot => 'Godot';
	@override String get delete_template => 'Удалить шаблон {{name}}';
	@override String get news_subtitle => 'Последние публикации с официального блога Godot Engine.';
	@override String get news_cached => 'Не удалось обратиться к godotengine.org, показываются статьи, сохранённые с прошлого раза.';
	@override String get news_error => 'Не удалось загрузить новости Godot.';
	@override String get news_empty => 'Пока никаких новостей.';
	@override String get show_more => 'Показать больше';
	@override String get try_again => 'Попробуйте еще раз';
	@override String get asset_store_title => 'МАГАЗИН АССЕТОВ';
	@override String get news_count => 'Posts';
	@override String asset_store_count_plural({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		zero: 'No assets',
		one: 'Asset',
		few: 'Assets',
		many: 'Assets',
		other: 'Assets',
	);
	@override String get asset_store_count => 'Assets';
	@override String get settings_title => 'НАСТРОЙКИ';
	@override String get no_templates_match => 'Шаблоны не найдены';
	@override String get no_projects_match => 'Проекты не найдены';
	@override String get more_import_options => 'Другие параметры импорта';
	@override String get clone_import_repo => 'Клонировать и импортировать из репозитория';
	@override String get manage_categories => 'Управление категориями';
	@override String get hide_category => 'Hide Category';
	@override String get category_hidden_toast => '"{{name}}" hidden. Restore it from Hidden Categories.';
	@override String get hidden_categories => 'Hidden Categories';
	@override String get hidden_categories_hint => 'Those categories and their projects stay out of the way. Unhide one to bring it back.';
	@override String get hidden_category_projects => '{{count}} project(s)';
	@override String get unhide => 'Unhide';
	@override String get unhide_category_aria => 'Unhide {{name}}';
	@override String get search_projects_placeholder => 'Поиск проектов по имени или пути…';
	@override String get clear_search => 'Очистить поиск';
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
	@override String get sort => 'Сортировка…';
	@override String get view_list => 'List';
	@override String get view_grid => 'Grid';
	@override String get view_kanban => 'Kanban';
	@override String get no_projects_yet => 'Пока здесь ничего нет. Создайте новый проект или импортируйте тот, который уже есть на диске.';
	@override String get pinned_section => 'Закреплённые';
	@override String get set_category => 'Указать категорию…';
	@override String get clear_selection => 'Сбросить выбор';
	@override String get starting => 'Запуск…';
	@override String get app_loading => 'Загрузка…';
	@override String get changelog_version_label => 'Версия';
	@override String get changelog_version_placeholder => 'v1.0.0';
	@override String get changelog_date_label => 'Дата';
	@override String get changelog_date_placeholder => '2026-07-13';
	@override String get changelog_what_changed => 'Что изменилось';
	@override String get changelog_add_line => 'Добавить строку';
	@override String get changelog_remove_line_aria => 'Удалить строку';
	@override String get changelog_placeholder_note => 'Добавлено перетаскивание для изменения порядка проектов';
	@override String get changelog_error_no_version => 'Укажите версию для записи.';
	@override String get changelog_known_issues => 'Известные проблемы';
	@override String get changelog_known_issues_none => 'Для этой версии известных проблем нет.';
	@override String get changelog_known_issue_placeholder => 'Опишите известную проблему…';
	@override String get changelog_remove_known_issue_aria => 'Удалить известную проблему';
	@override String get changelog_add_known_issue => 'Добавить известную проблему';
	@override String get changelog_generate_from_git => 'Generate from Git';
	@override String get changelog_draft_title => 'Release notes from Git';
	@override String get changelog_draft_from => 'From';
	@override String get changelog_draft_to => 'To';
	@override String get changelog_draft_generate => 'Generate draft';
	@override String get changelog_draft_use => 'Use Draft';
	@override String get changelog_draft_commits => '{{count}} commit(s)';
	@override String get changelog_draft_include => 'Include in draft';
	@override String get changelog_draft_none => 'No commits found in this range.';
	@override String get template_search_placeholder => 'Поиск шаблонов…';
	@override String get template_delete_title => 'Удалить шаблон?';
	@override String get template_delete_desc => '"{{name}}" будет удалён окончательно.';
	@override String get templates_tab_local => 'Локальные шаблоны';
	@override String get templates_tab_asset => 'Библиотека ассетов';
	@override String get asset_search_placeholder => 'Поиск ассетов…';
	@override String get asset_all_versions => 'Все версии';
	@override String get asset_result_count => '{{count}} результатов';
	@override String get asset_load_error => 'Не удалось загрузить библиотеку ассетов. Проверьте подключение и попробуйте ещё раз.';
	@override String get asset_no_results => 'Ассетов не найдено. Попробуйте другой запрос.';
	@override String get asset_by_author => 'от {{author}}';
	@override String get asset_open_page => 'Открыть в браузере';
	@override String get asset_install => 'Установить';
	@override String get asset_install_inside => 'Install Inside';
	@override String get asset_installing => 'Установка…';
	@override String get asset_installed => 'Установлено';
	@override String get asset_prev_page => 'Previous page';
	@override String get asset_next_page => 'Next page';
	@override String get asset_page_x_of_y => 'Page {{page}} of {{total}}';
	@override String template_your_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Template',
		few: 'Ваши шаблоны',
		many: 'Ваши шаблоны',
		other: 'Templates',
	);
	@override String get template_imported_count => 'Импортировано {{count}}';
	@override String get template_updated_count => 'Обновлено {{count}}';
	@override String get template_removed_count => 'Удалено {{count}}';
	@override String get asset_source_all => 'Все источники';
	@override String get asset_source_library => 'Старая Asset Library';
	@override String get asset_source_store => 'Новый магазин (Asset Store)';
	@override String get asset_store_relevance => 'Relevance';
	@override String get asset_store_updated_new => 'Newest updated';
	@override String get asset_store_updated_old => 'Oldest updated';
	@override String get asset_store_rating_high => 'Top rated';
	@override String get asset_store_rating_low => 'Lowest rated';
	@override String get asset_download_outside => 'Download Outside';
	@override String get asset_downloaded => 'Скачано';
	@override String get asset_downloaded_to => 'Скачано в';
	@override String get asset_download_error => 'Не удалось скачать ассет. Проверьте подключение и попробуйте ещё раз.';
	@override String get asset_install_modal_title => 'Установить {{title}}';
	@override String get asset_install_tab_project => 'В проект';
	@override String get asset_install_tab_template => 'В шаблон';
	@override String get asset_install_search_projects => 'Поиск проектов…';
	@override String get asset_install_no_projects => 'Пока нет проектов. Сначала создайте или импортируйте один.';
	@override String get asset_install_no_templates => 'Пока не сохранено ни одного шаблона.';
	@override String get asset_install_into => 'Установить в {{name}}';
	@override String get asset_install_success_project => 'Установлено в {{target}}';
	@override String get asset_install_success_template => 'Добавлено в шаблон {{target}}';
	@override String get asset_new_template_btn => 'Сохранить как новый шаблон';
	@override String get asset_new_template_hint => 'Создаёт новый шаблон из этого ассета проекта';
	@override String get onboarding_keep_organized => 'Храните проекты в организованном порядке, в одном месте.';
	@override String get onboarding_download_manage => 'Скачивайте и управляйте сборками движка Godot.';
	@override String get onboarding_stay_current => 'Следите за тем, что нового в Godot.';
	@override String get onboarding_projects_title => 'Где находятся ваши проекты?';
	@override String get onboarding_projects_desc => 'Добавьте папки, которые GodotHub должен сканировать на старте в поисках уже существующих проектов Godot. Поставьте звёздочку у одной из них, чтобы сделать её местом сохранения по умолчанию при создании нового проекта. Можно пропустить это и добавить папки позже в Настройках.';
	@override String get onboarding_versions_title => 'Где хранятся версии Godot?';
	@override String get onboarding_versions_desc => 'Добавьте папки, которые GodotHub должен сканировать для поиска установленных исполняемых файлов движка Godot. Поставьте звёздочку у одной из них, чтобы установить её как место загрузки новых версий, которые вы устанавливаете через вкладку Версии.';
	@override String get onboarding_templates_title => 'Папка шаблонов проектов';
	@override String get onboarding_templates_desc => 'При желании укажите папку, где вы храните повторно используемые шаблоны проектов. Любая подпапка внутри будет импортирована как шаблоны по завершении, чтобы они появлялись при создании новых проектов. Также вы можете сохранять отдельные проекты как шаблоны в любой момент из раздела Проекты или импортировать дополнительные позже на вкладке Шаблоны.';
	@override String get onboarding_categories_title => 'Организуйте с помощью категорий';
	@override String get onboarding_categories_desc_full => 'Категории, это папки для списка ваших проектов; складывайте проекты в них так, как вам удобно. Добавьте несколько заготовок или создайте свои; вы можете переименовывать, менять порядок или удалять их в любой момент в Настройках.';
	@override String get onboarding_custom_category_placeholder => 'Название категории…';
	@override String get onboarding_your_categories => 'Ваши категории';
	@override String get onboarding_customize_title => 'Сделайте по-своему';
	@override String get onboarding_customize_desc => 'Выберите акцент и цвет фона, чтобы начать. Скругление углов, плотность, размер текста и светлая/тёмная тема, всё это можно настроить в Настройках, когда захотите.';
	@override String get onboarding_finish_title => 'Готово';
	@override String get onboarding_finish_desc => 'GodotHub готов к работе. При желании вы можете вернуться к любому из этих параметров, папкам, категориям и внешнему виду, в любое время на вкладке Настройки.';
	@override String get onboarding_setting_up_title => 'Настройка';
	@override String get onboarding_setting_up_desc => 'Настройка вашей библиотеки… сканирование папок для проектов и версий Godot. Это происходит только один раз и займёт немного времени.';
	@override String get skipped => 'Пропущено';
	@override String get onboarding_continue => 'Продолжить';
	@override String get onboarding_accent_color => 'Акцентный цвет';
	@override String get onboarding_bg_color => 'Цвет фона';
	@override String get onboarding_corner_radius => 'Радиус углов';
	@override String get onboarding_discord_rpc => 'Discord Rich Presence';
	@override String get onboarding_discord_rpc_desc => 'Show what you\'re doing in GodotHub on your Discord profile.';
	@override String get version_search_placeholder => 'Найти версию...';
	@override String get version_no_installed => 'Пока нет установленных версий. Загрузите версию ниже или перетащите сюда папку с вашей существующей версией.';
	@override String get version_save_name_aria => 'Сохранить имя';
	@override String get version_rename_aria => 'Переименовать версию';
	@override String get version_mono_badge => 'Mono';
	@override String get version_uninstall_title => 'Удалить версию?';
	@override String get version_uninstall_desc => '«{{tag}}» и все его файлы будут перемещены в системную корзину / «Корзину» вашего компьютера. При необходимости вы сможете установить её заново.';
	@override String get version_uninstall_confirm => 'Удалить';
	@override String get project_remove_title => 'Удалить из библиотеки?';
	@override String get project_remove_desc => '«{{name}}» будет удалён из списка проектов GodotHub. Его файлы останутся на диске без изменений; вы сможете импортировать проект снова в любой момент.';
	@override String get project_delete_title => 'Переместить в корзину?';
	@override String get project_delete_desc => '«{{name}}» и всё, что внутри него, будет перемещено в системную корзину / «Корзину» вашего компьютера. При необходимости вы сможете восстановить это позже.';
	@override String get project_delete_confirm => 'Переместить в корзину';
	@override String get project_template_name_label => 'Название шаблона';
	@override String get project_template_desc_label => 'Описание';
	@override String get project_template_desc_placeholder => 'Что входит в этот шаблон?';
	@override String get project_save_template_btn => 'Сохранить шаблон';
	@override String get template_saved_toast => 'Template saved.';
	@override String get project_select_aria => 'Выбрать проект';
	@override String get project_deselect_aria => 'Снять выделение с проекта';
	@override String get select_all_visible => 'Select all visible';
	@override String get selected_count => '{{count}} selected';
	@override String get bulk_launch => 'Launch';
	@override String get bulk_pin => 'Pin';
	@override String get bulk_remove => 'Удалить';
	@override String get bulk_remove_title => 'Remove {{count}} projects from library?';
	@override String get bulk_remove_desc => 'The selected projects will be removed from your library. Their files will stay on disk.';
	@override String get bulk_delete_title => 'Delete {{count}} projects?';
	@override String get bulk_delete_desc => 'The selected project files will be permanently moved to the Trash. This cannot be undone.';
	@override String get project_pin_aria => 'Закрепить проект';
	@override String get project_unpin_aria => 'Открепить проект';
	@override String get time_today => 'Today';
	@override String get time_this_week => 'This week';
	@override String get time_all_time => 'All time';
	@override String get time_tracked_title => 'Time tracked';
	@override String get time_weekly_chart => 'Last 7 days';
	@override String get time_week_total => '{{total}} this week';
	@override String get time_weekly_empty => 'No tracked time in the last 7 days.';
	@override String get project_more_aria => 'Дополнительные действия';
	@override String get customize_card_section => 'Project Card';
	@override String get customize_card_show_size => 'Show Project Size';
	@override String get customize_card_show_time => 'Show Time Tracked';
	@override String get customize_card_show_session_timer => 'Show Session Timer';
	@override String get customize_card_blur_path => 'Blur Project Directory';
	@override String get customize_card_show_path => 'Show Project Directory';
	@override String get customize_card_show_tags => 'Show Tags';
	@override String get customize_card_show_last_opened => 'Show Last Opened';
	@override String get customize_card_show_play => 'Show Play Button';
	@override String get customize_card_show_console => 'Show Open with Console';
	@override String get project_card_remove_library => 'Удалить из библиотеки';
	@override String get project_card_delete_files => 'Удалить файлы';
	@override String get manage_tags => 'Управление тегами';
	@override String get tag_input_placeholder => 'Имя нового тега…';
	@override String get tag_already_exists => 'Тег с таким именем уже существует.';
	@override String get tag_rename_hint => 'Нажмите, чтобы переименовать';
	@override String get tag_rename_aria => 'Переименовать тег';
	@override String get show_more_tags => 'Show more tags';
	@override String get show_fewer_tags => 'Show fewer tags';
	@override String get clear_tag_filter => 'Clear tag filter';
	@override String get saving_tags => 'Saving tags…';
	@override String tag_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} tag',
		few: '${count} тег(ов)',
		many: '${count} тег(ов)',
		other: '${count} tags',
	);
	@override String get no_tags => 'Пока нет тегов';
	@override String get bug_report_describe_label => 'What happened?';
	@override String get bug_report_describe_placeholder => 'What were you doing when the bug appeared? Add steps to reproduce and what you expected vs. what actually happened.';
	@override String get bug_report_diagnostics_label => 'Diagnostic info';
	@override String get bug_report_diagnostics_hint => 'Auto-collected · included in the report';
	@override String get bug_report_copied => 'Copied!';
	@override String get bug_report_copy_log => 'Скопировать лог';
	@override String get bug_report_download_log => 'Скачать лог';
	@override String get bug_report_open_github => 'Открыть GitHub Issues';
	@override String get check_updates_title_modal => 'Проверить обновления';
	@override String get check_updates_version_available => 'Доступна версия {{version}}';
	@override String get check_updates_ask_download => 'Скачать и установить сейчас?';
	@override String get check_updates_release_notes => 'Примечания к выпуску';
	@override String get check_updates_failed => 'Не удалось проверить обновления';
	@override String get check_updates_rate_limited => 'Достигнут лимит запросов GitHub';
	@override String get check_updates_token_rejected => 'Токен GitHub отклонён';
	@override String get check_updates_rate_limited_hint => 'GitHub разрешает только 60 анонимных запросов в час, общий лимит для всех пользователей вашей сети. Добавление персонального токена в Настройках увеличивает лимит до 5 000 запросов в час и также используется для получения доступных версий Godot.';
	@override String get check_updates_rate_limited_token_hint => 'Сохранённый токен GitHub отклонён. Возможно, срок его действия истёк или он был отозван. Проверьте его в Настройках и замените при необходимости.';
	@override String get check_updates_add_token => 'Добавить токен GitHub';
	@override String get check_updates_open_token_settings => 'Открыть настройки токена';
	@override String get check_updates_preview_badge => 'Превью';
	@override String get check_updates_portable_title => 'Manual update required';
	@override String get check_updates_portable_desc => 'Portable installs cannot auto-update. Download the latest version from GitHub and replace the existing files.';
	@override String get check_updates_download_from_github => 'Скачать с GitHub';
	@override String get preview_state_checking => 'Проверка';
	@override String get preview_state_available => 'Доступно';
	@override String get preview_state_downloading => 'Загрузка';
	@override String get preview_state_done => 'Готово';
	@override String get preview_state_uptodate => 'Актуально';
	@override String get preview_state_error => 'Ошибка';
	@override String get preview_state_portable => 'Portable';
	@override String get preview_update_modal => 'Модальное окно превью обновления';
	@override String get clone_repo_title => 'Клонировать репозиторий';
	@override String get clone_repo_url_label => 'URL репозитория';
	@override String get clone_repo_url_placeholder => 'https://github.com/user/my-game.git';
	@override String get clone_repo_error_url => 'Пожалуйста, укажите URL репозитория.';
	@override String get clone_repo_error_location => 'Пожалуйста, выберите место для клонирования репозитория.';
	@override String get clone_repo_open_after => 'Open it right after importing';
	@override String get clone_repo_browse_repos => 'Просмотреть ваши репозитории';
	@override String get clone_repo_url_manual => 'Вставить URL вручную';
	@override String get clone_repo_search_repos => 'Поиск по вашим репозиториям...';
	@override String get clone_repo_no_repos_found => 'Репозитории не найдены.';
	@override String get clone_repo_loading_repos => 'Загрузка репозиториев...';
	@override String get clone_repo_load_error => 'Не удалось загрузить репозитории.';
	@override String get clone_repo_select => 'Выбрать';
	@override String get clone_repo_no_account => 'Аккаунт GitHub или GitLab не подключен. Используйте URL для клонирования.';
	@override String get clone_repo_repos_loaded => 'репозиториев загружено';
	@override String get load_more => 'Загрузить ещё';
	@override String get git_uncommitted => 'незакоммиченные';
	@override String get git_clean => 'Clean';
	@override String get task_tray_title => 'Задачи';
	@override String get task_tray_empty => 'Нет активных задач';
	@override String get task_tray_active_count => '{{active}} активных, {{recent}} недавних';
	@override String task_tray_only_recent({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} recent task',
		few: '${count} недавняя задача',
		many: '${count} недавняя задача',
		other: '${count} recent tasks',
	);
	@override String get task_tray_aria => 'Панель задач';
	@override String get task_tray_auto_dismiss => 'Завершённые задачи автоматически скрываются';
	@override String get task_tray_dismiss => 'Скрыть {{count}}';
	@override String get task_error_status => 'Ошибка';
	@override String get command_palette_title => 'Command Palette';
	@override String get command_palette_placeholder => 'Найти команду, проект, версию, настройки...';
	@override String get command_palette_no_results => 'Ничего не найдено';
	@override String get command_palette_navigate => 'Перейти';
	@override String get command_palette_escape => 'Esc';
	@override String get setting_token_placeholder => 'ghp_xxxxxxxxxxxxxxxxxxxx';
	@override String get setting_project_scan_dirs => 'Scan Project Folders';
	@override String get setting_version_scan_dirs => 'Scan Version Folders';
	@override String get setting_default_project_location => 'Default Project Location Setting';
	@override String get setting_download_dir => 'Download Versions Location Setting';
	@override String get setting_scan_depth => 'Scan Depth';
	@override String get setting_icon_scan_depth => 'Project Icon Search Depth';
	@override String get setting_download_concurrency => 'Simultaneous Downloads';
	@override String get setting_close_on_project_open => 'Close on Project Open';
	@override String get setting_minimize_to_tray => 'Minimize to System Tray';
	@override String get setting_reopen_after_godot_closes => 'Reopen After Godot Closes';
	@override String get setting_auto_scan_on_startup => 'Auto-scan on Startup';
	@override String get setting_workspaces_enabled => 'Use Workspaces';
	@override String get setting_directory_naming_convention => 'Directory Naming Convention';
	@override String get setting_git_init_new_projects => 'Initialize Git for New Projects';
	@override String get setting_tooltip_delay => 'Tooltip Delay';
	@override String get setting_command_palette_keybind => 'Command Palette Shortcut';
	@override String get setting_tray_recent_projects_count => 'Tray Recent Projects';
	@override String get setting_last_opened_time_format => 'Time Format';
	@override String get setting_last_opened_date_format => 'Date Format';
	@override String get setting_theme_mode => 'Theme Mode';
	@override String get setting_accent_color => 'Акцентный цвет';
	@override String get setting_background_color => 'Цвет фона';
	@override String get setting_corner_radius => 'Corner Radius';
	@override String get setting_ui_density => 'UI Density';
	@override String get setting_font_scale => 'Text Size';
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
	@override String get active_workspace => '{{name}} (active)';
	@override String get current_workspace => 'Текущее рабочее пространство';
	@override String get switch_workspace => 'Переключить рабочее пространство';
	@override String get opened_recently => 'Открыт(а) {{label}}';
	@override String get recent_section => 'Недавние';
	@override String get installed_versions_section => 'Установленные версии';
	@override String get settings_label => 'Настройки → {{tab}}';
	@override String get remove_category_aria => 'Удалить {{name}}';
	@override String get git_remove_remote => 'Удалить удалённый репозиторий';
	@override String get git_commit_placeholder => 'Сообщение коммита…';
	@override String get restart_required_title => 'Требуется перезапуск';
	@override String get restart_required_desc => 'Чтобы изменение полностью вступило в силу, GodotHub нужно перезапустить. Настройка сохранена и применится при повторном запуске приложения.';
	@override String found_dismissed_title({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Найдён ранее удалённый проект',
		few: '${count} previously removed projects found',
		many: '${count} previously removed projects found',
		other: 'Найдены ${count} ранее удалённых проектов',
	);
	@override String found_dismissed_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Сканер обнаружил 1 проект, который вы ранее удаляли из библиотеки. Добавить обратно?',
		few: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
		many: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
		other: 'Сканер обнаружил ${count} проектов, которые вы ранее удаляли из библиотеки. Добавить обратно?',
	);
	@override String get readd_all => 'Добавить все обратно';
	@override String get skip_all => 'Пропустить всё';
	@override String get project_already_open_title => 'Project already open';
	@override String get project_already_open_desc => '{{name}} is already running. Opening it again launches a second editor instance. Open anyway?';
	@override String get project_open_anyway => 'Open anyway';
	@override String get git_sidebar => 'Git sidebar';
	@override String get asset_duplicate_title => 'Template already installed';
	@override String get asset_duplicate_desc => '"{{name}}" is already in your templates. Install a duplicate anyway?';
	@override String get empty_category => 'Empty Category';
	@override String get release_to_drop => 'Release to drop';
	@override String get preview_release_notes => '## What\'s new in v1.0.0 - The Preview Update\\n\\n## New\\n\\n- Revamped the Check for Updates modal with structured release notes\\n- Added screen reader announcements with an Accessibility settings tab\\n\\n## Fixes\\n\\n- Fixed a crash when switching workspaces with pinned projects\\n- Fixed update checks failing silently when GitHub rate limits are hit\\n\\n## Improvements\\n\\n- Faster startup times across all platforms\\n- Reworked workspace modals with compact style pickers\\n\\n## Known Issues\\n\\n- Linux OS: AppImage won\'t work on some distros, use the .rpm or .deb package instead\\n- Windows: the taskbar may briefly show a duplicate icon until the app restarts';
	@override String get preview_error => 'Preview error: GitHub API rate limit reached (HTTP 403). Add a token in Settings to keep checking.';
	@override String get bug_report_system => 'System';
	@override String get bug_report_version => 'Version';
	@override String get bug_report_date => 'Date';
	@override String get bug_report_os => 'OS';
	@override String get bug_report_platform => 'Platform';
	@override String get bug_report_language => 'Language';
	@override String get bug_report_cpu_cores => 'CPU Cores';
	@override String get bug_report_ram => 'RAM';
	@override String get bug_report_screen => 'Screen';
	@override String get bug_report_gpu => 'GPU';
	@override String get bug_report_user_agent => 'User Agent';
	@override String get bug_report_recent_errors => 'Recent Errors';
	@override String get bug_report_none_captured => 'none captured';
	@override String get bug_report_description => 'Description';
	@override String get bug_report_no_description => 'No description provided';
	@override String get unknown => 'неизвестно';
	@override String get gpu_webgl_unavailable => 'WebGL not available';
	@override String get gpu_info_unavailable => 'GPU info unavailable';
	@override String get update_available => 'Update available';
	@override String get dismiss => 'Dismiss';
	@override String get system_language => 'Язык системы';
	@override String get category_empty_hint => 'Create one above to organize your projects';
	@override String get contributor_pr_merged => 'Merged';
	@override String get contributor_pr_open => 'Open';
	@override String get contributor_pr_closed => 'Closed';
	@override String get contributor_pr_loading => 'Loading PRs...';
	@override String contributor_pr_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} pull request',
		few: '${count} pull requests',
		many: '${count} pull requests',
		other: '${count} pull requests',
	);
	@override String get contributor_pr_load_failed => 'Failed to load pull requests.';
	@override String get contributor_pr_network_hint => 'Check your internet connection.';
	@override String get contributor_pr_empty => 'No pull requests found.';
	@override String get theme_presets_section => 'Theme presets';
	@override String get all_categories => 'Все категории';
	@override String get clear_category_filter => 'Clear category filter';
	@override String get filter_by_category => 'Filter by category';
	@override String get theme_dark => 'Темная тема';
	@override String get theme_light => 'Светлая тема';
	@override String get bulk_tags => 'Tags';
	@override String get bulk_tags_title => 'Edit tags';
	@override String get add_tag => 'Добавить тег';
	@override String get remove_tag => 'Удалить тег';
	@override String get no_common_tags => 'No tags on the selected projects yet.';
	@override String get tags_added_to_selection => 'Added tag to {{count}} projects.';
	@override String get tags_removed_from_selection => 'Removed tag from {{count}} projects.';
	@override String get removed_from_library => 'Removed {{count}} project(s) from library.';
	@override String get undo => 'Undo';
	@override String get duplicate_project_title => 'Duplicate project';
	@override String get copy_suffix => 'copy';
	@override String get duplicate => 'Duplicate';
	@override String get destination_folder => 'Папка назначения';
	@override String get new_project_name => 'Project name';
	@override String get project_duplicated => 'Project duplicated.';
	@override String get notification_version_installed => 'Godot {{tag}} installed';
	@override String get notification_asset_installed => '{{title}} installed';
	@override String get notification_clone_done => 'Repository cloned and imported';
	@override String get console_title => 'Console';
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
	@override late final _Translations$common$project_doctor$ru_RU project_doctor = _Translations$common$project_doctor$ru_RU._(_root);
	@override late final _Translations$common$build_export$ru_RU build_export = _Translations$common$build_export$ru_RU._(_root);
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
	@override String cleanup_confirm_btn({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Remove ${count} item',
		few: 'Remove ${count} items',
		many: 'Remove ${count} items',
		other: 'Remove ${count} items',
	);
	@override String get cleanup_done => 'Freed {{size}}';
	@override String get cleanup_failed => 'Couldn\'t remove {{label}}: {{error}}';
	@override String get cleanup_versions_desc => 'Full size on disk of every installed Godot version.';
	@override String get cleanup_templates_title => 'Project templates';
	@override String get cleanup_export_templates_title => 'Export templates';
	@override String cleanup_used_by_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} template',
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
	@override String get reset => 'Восставновить по умолчанию';
	@override String get git_disconnect => 'Disconnect';
	@override String get git_sign_in_github => 'Sign in with GitHub';
	@override String get git_connected_as => 'Connected as @{{username}}';
	@override String get optional => '(optional)';
	@override String get language_label => 'Язык';
	@override String n_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} проект',
		few: '${count} projects',
		many: '${count} projects',
		other: '${count} проектов',
	);
	@override String vault_item_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Item',
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
	@override String vault_conflict_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} file already exists in the project. Overwrite it?',
		few: '${count} files already exist in the project. Overwrite them?',
		many: '${count} files already exist in the project. Overwrite them?',
		other: '${count} files already exist in the project. Overwrite them?',
	);
	@override String vault_conflict_summary_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} file already exists across the selected projects. Overwrite it?',
		few: '${count} files already exist across the selected projects. Overwrite them?',
		many: '${count} files already exist across the selected projects. Overwrite them?',
		other: '${count} files already exist across the selected projects. Overwrite them?',
	);
	@override String vault_added_toast({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Added ${count} file',
		few: 'Added ${count} files',
		many: 'Added ${count} files',
		other: 'Added ${count} files',
	);
	@override String vault_added_to_projects_toast({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Added to ${count} project',
		few: 'Added to ${count} projects',
		many: 'Added to ${count} projects',
		other: 'Added to ${count} projects',
	);
	@override String get vault_item_empty => 'This item has no files.';
	@override String get kNew => 'Новый';
	@override String get announcement_support_title => 'Support GodotHub';
	@override String get announcement_support_body => 'GodotHub is free and made in my spare time. If it helps your workflow, please consider supporting development with a donation.';
	@override String get workspace_name_taken_error => 'Another workspace already uses this name.';
	@override String get workspace_start_label => 'Start with';
	@override String get workspace_start_copy => 'Copy settings from {{name}}';
	@override String get workspace_start_copy_desc => 'Theme, language, features, and version folders carry over. Project folders start empty, and you go straight in.';
	@override String get workspace_start_fresh => 'Start fresh';
	@override String get workspace_start_fresh_desc => 'Walk through setup for this workspace from scratch.';
	@override String get workspace_switched_to => 'Switched to';
	@override late final _Translations$common$project_addons$ru_RU project_addons = _Translations$common$project_addons$ru_RU._(_root);
	@override String get reload_confirm_title => 'Reload GodotHub?';
	@override String get reload_confirm_desc => 'Any unsaved changes in open forms will be lost.';
	@override String get color_presets => 'Presets';
	@override String get date_previous_month => 'Previous month';
	@override String get date_next_month => 'Next month';
	@override String get date_change_due => 'Change due date: {{date}}';
	@override String get date_add_due => 'Add due date';
}

// Path: dashboard
class _Translations$dashboard$ru_RU extends Translations$dashboard$en_US {
	_Translations$dashboard$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get greeting_morning => 'Good morning';
	@override String get greeting_afternoon => 'Good afternoon';
	@override String get greeting_evening => 'Good evening';
	@override String get greeting_night => 'Good night';
	@override String get greeting_name => '{{greeting}}, {{name}}';
	@override String get dashboard_rename_hint => 'Set a custom name';
	@override String get dashboard_rename_aria => 'Rename your greeting name';
	@override String get dashboard_rename_save => 'Save name';
	@override String get dashboard_rename_reset => 'Use system name';
	@override String get dashboard_name_placeholder => 'Your name';
	@override String get dashboard_clock_aria => 'Current time';
	@override String get dashboard_new_project => 'New Project';
	@override String get dashboard_import_project => 'Import Project';
	@override String get dashboard_scan_projects => 'Scan for Projects';
	@override String get dashboard_stat_projects => 'Projects';
	@override String get dashboard_stat_templates => 'Templates';
	@override String get dashboard_stat_engines => 'Engines';
	@override String get dashboard_stat_total_time => 'Total Time';
	@override String get dashboard_stat_total_time_hint => 'Time spent on projects';
	@override String get dashboard_recent => 'Recently Opened';
	@override String get dashboard_recent_empty => 'Nothing opened yet. Open a project to see it here.';
	@override String get dashboard_pinned => 'Pinned';
	@override String get dashboard_pinned_empty => 'No pinned projects yet. Pin a project to keep it handy.';
	@override String get dashboard_engines => 'Installed Engines';
	@override String get dashboard_engines_empty => 'No engines installed yet.';
	@override String get dashboard_running => 'Running Now';
	@override String get dashboard_running_empty => 'Nothing is running right now.';
	@override String get dashboard_opened_at => 'Opened {{time}}';
	@override String get dashboard_daily => 'Daily Activity';
	@override String get dashboard_daily_empty => 'No daily activity yet.';
	@override String get dashboard_weekly => 'Weekly Activity';
	@override String get dashboard_weekly_empty => 'No weekly activity yet.';
	@override String get dashboard_monthly => 'Monthly Activity';
	@override String get dashboard_monthly_empty => 'No monthly activity yet.';
	@override String get dashboard_yearly => 'Yearly Activity';
	@override String get dashboard_yearly_empty => 'No yearly activity yet.';
	@override String get dashboard_activity_cycle => 'Switch to {{next}}';
	@override String get dashboard_weekly_aria => '{{label}} of tracked time';
	@override String get dashboard_top_time => 'Top Projects by Time';
	@override String get dashboard_top_time_empty => 'No tracked time yet. Open a project to start tracking.';
	@override String get dashboard_insights => 'Insights';
	@override String get dashboard_insights_empty => 'No tracked time yet. Open a project to start building your streaks.';
	@override String get dashboard_insights_longest_streak => 'Longest streak';
	@override String get dashboard_insights_current_streak => 'Current streak';
	@override String get dashboard_insights_days => '{{count}} days';
	@override String get dashboard_insights_productive_day => 'Most productive day';
	@override String get dashboard_insights_this_month => 'This month';
	@override String get dashboard_insights_delta_up => '{{pct}}% more than last month';
	@override String get dashboard_insights_delta_down => '{{pct}}% less than last month';
	@override String get dashboard_git => 'Git Overview';
	@override String get dashboard_git_empty => 'No git repositories detected.';
	@override String get dashboard_git_clean => 'All clean';
	@override String get dashboard_git_dirty => '{{count}} with uncommitted changes';
	@override String dashboard_git_dirty_plural({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '1 with uncommitted changes',
		few: '${count} with uncommitted changes',
		many: '${count} with uncommitted changes',
		other: '${count} with uncommitted changes',
	);
	@override String get dashboard_git_branch => 'On {{branch}}';
	@override String get dashboard_storage => 'Storage Usage';
	@override String get dashboard_storage_empty => 'No projects to measure.';
	@override String get dashboard_storage_loading => 'Measuring…';
	@override String get dashboard_storage_total => '{{size}} total';
	@override String get dashboard_customize => 'Customize';
	@override String get dashboard_done_customizing => 'Done';
	@override String get dashboard_customize_hint => 'Use the arrows to rearrange tiles, or hide the ones you don\'t need.';
	@override String get dashboard_tile_move_up => 'Move up';
	@override String get dashboard_tile_move_down => 'Move down';
	@override String get dashboard_tile_remove => 'Remove';
	@override String get dashboard_tile_span => 'Full width';
	@override String get dashboard_tile_span_off => 'Half width';
	@override String get dashboard_tile_tall => 'Taller';
	@override String get dashboard_tile_tall_off => 'Normal height';
	@override String get dashboard_presets => 'Layout presets';
	@override String get dashboard_preset_default => 'Default';
	@override String get dashboard_preset_default_desc => 'Everything on, in the default order, standard sizing.';
	@override String get dashboard_preset_overview => 'Overview';
	@override String get dashboard_preset_overview_desc => 'Recently opened, pinned, engines, and running projects.';
	@override String get dashboard_preset_analytics => 'Analytics';
	@override String get dashboard_preset_analytics_desc => 'Weekly activity, top projects, storage, and categories, with taller charts.';
	@override String get dashboard_preset_development => 'Development';
	@override String get dashboard_preset_development_desc => 'Git status front and center with running projects and engines.';
	@override String get dashboard_preset_save => 'Save current as preset';
	@override String get dashboard_preset_save_hint => 'Name this layout so you can switch back to it anytime.';
	@override String get dashboard_preset_name_placeholder => 'Preset name';
	@override String get dashboard_preset_delete => 'Delete preset';
	@override String get dashboard_custom_presets => 'Your presets';
	@override String get dashboard_hidden_tiles => 'Hidden tiles';
	@override String get dashboard_todos => 'Due to-dos';
	@override String get dashboard_range_daily => 'День';
	@override String get dashboard_range_weekly => 'Неделя';
	@override String get dashboard_range_monthly => 'Месяц';
	@override String get dashboard_range_yearly => 'Год';
	@override String get dashboard_activity_tracked => 'Записано';
	@override String get dashboard_activity_peak => 'Пик';
}

// Path: git
class _Translations$git$ru_RU extends Translations$git$en_US {
	_Translations$git$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get remove => 'Удалить';
	@override String get changes_title => 'Изменения';
	@override String get pull => 'Обновить';
	@override String get push => 'Отправить';
	@override String get force_push => 'Принудительно';
	@override String get fetch => 'Загрузить';
	@override String get change => 'Изменить';
	@override String get commit => 'Коммит';
	@override String get committing => 'Выполняется коммит…';
	@override String get no_remotes => 'No remotes configured';
	@override String get switching => 'Switching…';
	@override String get no_branches => 'No branches found';
	@override String get new_branch_placeholder => 'Branch name';
	@override String get delete_branch => 'Delete branch';
	@override String get publish_branch => 'Publish branch';
	@override String get publish_branch_to => 'Publish branch to {{remote}}';
	@override String get branch_published => 'Branch published.';
	@override String get use_ours => 'Use ours';
	@override String get use_theirs => 'Use theirs';
	@override String get i_resolved => 'I resolved it';
	@override String get undo_last_commit => 'Undo last commit';
	@override String get undo_pull => 'Undo pull';
	@override String get force_push_confirm_title => 'Force push?';
	@override String get force_push_confirm_desc => 'This rewrites remote history and can lose other people\'s commits. Continue?';
	@override String get undo_commit_done => 'Last commit undone.';
	@override String get undo_pull_done => 'Pull undone.';
	@override String get force_pushed => 'Force pushed.';
	@override String get synced_ok => 'Synced.';
	@override String get fetched_ok => 'Fetched.';
	@override String get pulled_ok => 'Pulled.';
	@override String get pushed_ok => 'Pushed.';
	@override String get branch_created => 'Branch created.';
	@override String get branch_deleted => 'Branch deleted.';
	@override String get changes_stashed_ok => 'Changes stashed.';
	@override String get stash_applied_ok => 'Stash applied.';
	@override String get stash_popped_ok => 'Stash popped.';
	@override String get stash_dropped_ok => 'Stash dropped.';
	@override String get staged_ok => 'Staged.';
	@override String get unstaged_ok => 'Unstaged.';
	@override String get discarded_ok => 'Discarded.';
	@override String get stage_all_ok => 'Staged all changes.';
	@override String get unstage_all_ok => 'Unstaged all changes.';
	@override String get discard_all_ok => 'Discarded all changes.';
	@override String get resolved_ours => 'Resolved using ours.';
	@override String get resolved_theirs => 'Resolved using theirs.';
	@override String get resolved_manual => 'Marked as resolved.';
	@override String get committed_ok => 'Committed.';
	@override String get switched_ok => 'Switched to {{branch}}.';
	@override String get sync => 'Sync';
	@override String get diff_no_diff => 'No diff available for this file.';
	@override String get fetching => 'Fetching…';
	@override String get stashes_title => 'Stashes';
	@override String get stash => 'Stash';
	@override String get stashing => 'Stashing…';
	@override String get apply_stash => 'Apply stash';
	@override String get pop_stash => 'Pop stash';
	@override String get drop_stash => 'Drop stash';
	@override String get merge_aborted => 'Слияние отменено. Рабочая директория восстановлена.';
	@override String get new_branch_btn => '+ Новая';
	@override String get abort_merge => 'Отменить merge';
	@override String get merge_in_progress => 'Выполняется merge';
	@override String get working_tree_clean => 'Рабочее дерево чистое.';
	@override String get staged_changes => 'Добавленные в индекс изменения';
	@override String get unstage_all_changes => 'Убрать из индекса все изменения';
	@override String get commits_title => 'Коммиты';
	@override String get stage_file => 'Добавить файл в индекс';
	@override String get discard_file => 'Discard file';
	@override String get unstage_file => 'Убрать файл из индекса';
	@override String get no_commits_found => 'Коммиты не найдены.';
	@override String get stage_all => 'Добавить все';
	@override String get discard_all => 'Discard All';
	@override String get auth_connected_accounts => 'Connected accounts';
	@override String get auth_connect_hint => 'Connect to your desired git host to begin, or use SSH without connecting anything.';
	@override String get worktrees_title => 'Worktrees';
	@override String get worktree_current => 'Current';
	@override String get no_worktrees => 'No additional worktrees';
	@override String get switch_worktree => 'Switch to this worktree';
	@override String get switched_worktree_ok => 'Switched to worktree.';
	@override String get add_worktree => 'Новое рабочее дерево';
	@override String get add_worktree_btn => 'Add worktree';
	@override String get worktree_path_placeholder => 'Path (e.g. ../my-feature)';
	@override String get worktree_branch_placeholder => 'Branch name (optional)';
	@override String get worktree_created_ok => 'Worktree created.';
	@override String get worktree_dirty => 'Uncommitted changes';
	@override String get remove_worktree => 'Remove worktree';
	@override String get remove_worktree_confirm_desc => 'Удалить рабочее дерево в {{path}}? Его каталог будет удалён. Ветка и коммиты будут сохранены.';
	@override String get worktree_removed_ok => 'Worktree removed.';
	@override String get auto_fetch_label => 'Fetch automatically';
	@override String get auto_fetch_hint => 'Runs git fetch every few minutes so the pull bubble always shows how many commits you\'re behind, without merging anything. Leave it off to only fetch when you click Fetch.';
	@override String get commits_to_push => '{{count}} commit(s) to push';
	@override String get commits_to_pull => '{{count}} commit(s) to pull';
	@override String get filter_changes => 'Filter changed files…';
	@override String get no_matching_changes => 'No matching changes.';
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
class _Translations$nav$ru_RU extends Translations$nav$en_US {
	_Translations$nav$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get dashboard => 'Панель управления';
	@override String get projects => 'Проекты';
	@override String projects_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Project',
		few: 'Проекты',
		many: 'Проекты',
		other: 'Projects',
	);
	@override String get versions => 'Версии';
	@override String get templates => 'Шаблоны';
	@override String get vault => 'Vault';
	@override String get asset_store => 'Магазин ассетов';
	@override String get news => 'Новости';
	@override String get storage_view => 'Storage';
	@override String get settings => 'Настройки';
	@override String get changelog => 'Журнал изменений';
	@override String get group_workspace => 'Рабочая область';
	@override String get group_resources => 'Ресурсы';
	@override String get group_explore => 'Обзор';
	@override String get you => 'You';
	@override String get account_manage => 'Manage accounts';
	@override String get workspace_tip_title => 'Переключатель рабочих областей переехал';
	@override String get workspace_tip_body => 'Переключайте и настраивайте рабочие области в меню аккаунта ниже.';
	@override String get workspace_tip_dismiss => 'Понятно';
}

// Path: onboarding
class _Translations$onboarding$ru_RU extends Translations$onboarding$en_US {
	_Translations$onboarding$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'Добро пожаловать';
	@override String get finish => 'Завершить';
	@override String get in_progress => 'В процессе';
	@override String get prototypes => 'Прототипы';
	@override String get finished => 'Завершенные';
	@override String get game_jams => 'Геймджемы';
	@override String get project_folders => 'Папки проектов';
	@override String get version_folders => 'Папки версий';
	@override String get welcome_title => 'Добро пожаловать в GodotHub';
	@override String get welcome_desc => 'Место для ваших проектов и версий Godot. Давайте настроим его так, чтобы всё работало так, как вам нужно, это займет всего минуту, и всё можно будет изменить позже в настройках.';
	@override String get onboard_empty_projects => 'Папки с проектами не добавлены. GodotHub не может найти существующие проекты, если вы не добавите папки.';
	@override String get onboard_empty_versions => 'Папки с версиями Godot не добавлены. Новые загрузки Godot будут сохранены в папке данных приложения, если вы не укажете другую папку.';
	@override String get onboard_no_template_folder => 'Папка для шаблонов не выбрана, вы всегда можете настроить это позже в Настройках или сохранять шаблоны вручную.';
	@override String get onboard_cloud_heading => 'Cloud Backup';
	@override String get onboard_cloud_desc => 'Already have a backup? Sign in with GitHub and restore your workspaces, projects, and settings from a gist.';
	@override String get discovery_recent_heading => 'Recent projects from Godot';
	@override String get discovery_installs_heading => 'Godot found on this computer';
	@override String get discovery_scanning_projects => 'Reading Godot\'s project manager list…';
	@override String get discovery_scanning_installs => 'Looking for Godot on your PATH and in Steam…';
	@override String get discovery_engine => 'Godot {{version}}';
	@override String get discovery_favorite => 'Favorite';
	@override String get discovery_add_selected => 'Add selected';
	@override String get discovery_add_selected_count => 'Add selected ({{count}})';
	@override String discovery_added_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Added ${count} project.',
		few: 'Added ${count} projects.',
		many: 'Added ${count} projects.',
		other: 'Added ${count} projects.',
	);
	@override String discovery_added_versions({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Added ${count} version.',
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
class _Translations$settings$ru_RU extends Translations$settings$en_US {
	_Translations$settings$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get storage => 'Хранилище';
	@override String get behavior => 'Поведение';
	@override String get display => 'Отображение';
	@override String get appearance => 'Внешний вид';
	@override String get accessibility => 'Accessibility';
	@override String get accessibility_desc => 'Screen reader announcements and assistive technology options.';
	@override String get app_version_label => 'GodotHub v{{version}}';
	@override String get landing_dashboard => 'Dashboard';
	@override String get landing_projects => 'Projects';
	@override String get landing_versions => 'Versions';
	@override String get landing_news => 'Godot News';
	@override String get screen_reader_label => 'Screen reader announcements';
	@override String get advanced => 'Дополнительно';
	@override String get integrations => 'Integrations';
	@override String get motion => 'Motion';
	@override String get data => 'Data & Backup';
	@override String get git_auth_title => 'Sign in with {{provider}}';
	@override String get git_auth_copy_code => 'Copy code';
	@override String get git_auth_copy_link => 'Copy link';
	@override String get git_auth_waiting => 'Waiting for you to authorize…';
	@override String get git_sign_in_gitlab => 'Sign in with GitLab';
	@override String get git_connected_to => 'Connected to {{host}} as @{{username}}';
	@override String get git_self_hosted_title => 'Self-hosted GitLab';
	@override String get git_self_hosted_desc => 'Connect to your own GitLab instance. Create an OAuth application on your instance (scopes: read_repository, write_repository, read_user) and paste its base URL and Application ID.';
	@override String get git_self_hosted_url_placeholder => 'https://gitlab.example.com';
	@override String get git_self_hosted_client_id => 'Application ID';
	@override String get git_sign_in_self_hosted => 'Sign in with instance';
	@override String get git_pat_title => 'Other hosts (personal access tokens)';
	@override String get git_pat_add => 'Add token';
	@override String get git_pat_host_placeholder => 'e.g. codeberg.org';
	@override String get git_pat_username => 'Username';
	@override String get git_pat_token => 'Token';
	@override String get git_pat_save => 'Save token';
	@override String get git_pat_empty => 'No tokens added yet.';
	@override String get git_pat_remove => 'Remove token';
	@override String get storage_title => 'Хранилище и сканирование';
	@override String get behavior_projects_title => 'Проекты';
	@override String get file_watchers_title => 'Наблюдение за файлами';
	@override String get last_opened_title => 'Отображение "последнего открытия"';
	@override String get github_token_title => 'GitHub API Токен';
	@override String get titlebar_buttons => 'Кнопки в заголовке окна';
	@override String get setup_wizard => 'Setup Wizard';
	@override String get setup_wizard_again => 'Запустить Setup Wizard снова';
	@override String get restart_app => 'Restart App';
	@override String get restart_app_confirm_title => 'Restart GodotHub?';
	@override String get restart_app_confirm_desc => 'The app will close and reopen automatically. Unsaved in-progress operations may be interrupted.';
	@override String get reset_settings => 'Восстановить настройки по умолчанию';
	@override String get delete_app_data => 'Удалить все данные приложения';
	@override String get new_project_default => 'Новый проект по умолчанию';
	@override String get download_folder => 'Папка для загрузок';
	@override String get system => 'System';
	@override String get k12h => '12-часовой (2:30 PM)';
	@override String get k24h => '24-часовой (14:30)';
	@override String get dd_mm_yyyy => 'ДД-ММ-ГГГГ';
	@override String get mm_dd_yyyy => 'ММ-ДД-ГГГГ';
	@override String get yyyy_mm_dd => 'ГГГГ-ММ-ДД';
	@override String get reset_all_title => 'Установить все настройки по умолчанию?';
	@override String get reset_all_desc => 'Это восстанавливает все настройки на этой странице, включая папку загрузок, папки сканирования, внешний вид и поведение, к значениям по умолчанию. Это действие нельзя отменить.';
	@override String get delete_all_title => 'Удалить данные приложения?';
	@override String get delete_all_desc => 'Это навсегда удаляет все рабочие пространства, проекты, категории, записи об установленных версиях и настройки, которые GodotHub сохранил, и перезапускает вас в режиме первичной настройки. Фактические папки проектов и установки Godot на диске не затрагиваются, если только они не находятся в папке загрузок по умолчанию. В этом случае они также будут удалены. Это действие нельзя отменить.';
	@override String get empty_hint_projects => 'Папки не выбраны, при запуске ничего сканироваться не будет, и при добавлении новых проектов каждый раз будет спрашиваться, куда их сохранять.';
	@override String get empty_hint_versions => 'Папки не выбраны, при запуске ничего сканироваться не будет, и новые загрузки будут использовать папку данных приложения.';
	@override String get naming_convention_label => 'Правила наименований для директорий';
	@override String get naming_keep => 'Сохранить как введено (Моя игра)';
	@override String get naming_kebab => 'kebab-case (Моя-игра)';
	@override String get naming_snake => 'snake_case (Моя_игра)';
	@override String get naming_camel => 'camelCase (мояИгра)';
	@override String get naming_pascal => 'PascalCase (МояИгра)';
	@override String get naming_title => 'Title Case (Моя Игра)';
	@override String get theme => 'Тема';
	@override String get theme_preset_label => 'Theme preset';
	@override String get theme_preset_custom => 'Custom';
	@override String get preset_light_group => 'Light themes';
	@override String get preset_dark_group => 'Dark themes';
	@override String get test => 'Тест';
	@override String get testing => 'Тестирование…';
	@override String get token_valid => 'Валидный токен! Лимит вызовов: {{status}}';
	@override String get token_resets_in => '(resets ~{{minutes}} min)';
	@override String get test_failed => 'Тест не удался: {{error}}';
	@override String get key_space => 'Пробел';
	@override String get no_settings_match => 'Настройки не найдены';
	@override String get scan_result => 'Найдено {{projects}} новых проектов и {{versions}} новых версий.';
	@override String get palette_shortcut => 'Горячая клавиша для вызова палитры команд';
	@override String get keybind_instruction => 'Нажмите кнопку ниже, затем нажмите любую клавишу для переназначения.';
	@override String get press => 'Нажмите';
	@override String get to_cancel => 'чтобы отменить';
	@override String get press_key => 'Нажмите клавишу…';
	@override String get click_to_rebind => 'Нажмите чтобы переназначить';
	@override String get close_on_open_label => 'Закрыть GodotHub при открытии проекта';
	@override String get launch_console_label => 'Запустить Godot с терминалом';
	@override String get builtin_console_label => 'Use the built-in console';
	@override String get minimize_tray_label => 'Свернуть в трей при закрытии приложения';
	@override String get reopen_label => 'Открыть снова после закрытия Godot';
	@override String get no_folder_set => 'Папка не выбрана. Вы всё ещё можете импортировать проекты вручную или использовать \'Сохранить как шаблон\'.';
	@override String get ui_density_label => 'Плотность интерфейса';
	@override String get text_size_label => 'Размер текста';
	@override String get section_godot_versions => 'Версии Godot';
	@override String get scan_depth_label => 'Глубина сканирования';
	@override String get icon_scan_depth_label => 'Project icon search depth';
	@override String get download_concurrency_label => 'Одновременные загрузки';
	@override String get tray_recent_label => 'Последние проекты в трее';
	@override String get tooltip_delay_label => 'Задержка подсказки';
	@override String get project_icon_opacity_label => 'Прозрачность иконки проекта';
	@override String get time_format_label => 'Формат времени (показывается при открытии сегодня)';
	@override String get date_format_label => 'Формат даты (показывается для любого другого дня)';
	@override String get auto_scan_label => 'Авто-сканирование при запуске';
	@override String get use_workspaces_label => 'Использовать рабочие пространства';
	@override String get watch_projects_label => 'Отслеживать папки проектов';
	@override String get watch_versions_label => 'Отслеживать папки версий';
	@override String get watch_template_label => 'Отслеживать директорию шаблонов';
	@override String get show_scrollbar_label => 'Показать полосу прокрутки';
	@override String get animated_numbers_label => 'Animated numbers';
	@override String get show_support_label => 'Показать кнопку поддержки';
	@override String get show_star_label => 'Показать кнопку звезды';
	@override String get show_bug_label => 'Show bug report button';
	@override String get show_tray_label => 'Show tray button';
	@override String get show_language_label => 'Show language button';
	@override String get clear => 'Очистить';
	@override String get reset_to_default => 'Восстановить настройки по умолчанию';
	@override String get reset_appearance => 'Восстановить настройки внешнего вида по умолчанию';
	@override String get delete_all => 'Удалить всё';
	@override String get open_setup => 'Открыть Настройки';
	@override String get reset_colors => 'Установить цвета по умолчанию';
	@override String folders_deep({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} папку вглубь',
		few: '${count} folders deep',
		many: '${count} folders deep',
		other: '${count} папок вглубь',
	);
	@override String get at_once => '{{count}} одновременно';
	@override String get animation_speed_label => 'Animation speed';
	@override String get scroll_reveal_label => 'Scroll reveal';
	@override String get card_tilt_label => 'Card tilt on hover';
	@override String get click_ripple_label => 'Click ripple';
	@override String get press_bounce_label => 'Press bounce';
	@override String get animation_intensity_label => 'Animation intensity';
	@override String get animation_full => 'Full';
	@override String get animation_subtle => 'Subtle';
	@override String get animation_none => 'None';
	@override String get view_entrance_label => 'View entrance animation';
	@override String get entrance_fade => 'Fade';
	@override String get entrance_slide => 'Slide';
	@override String get entrance_scale => 'Scale';
	@override String get entrance_none => 'None';
	@override String get custom_css_label => 'Custom CSS';
	@override String get custom_css_placeholder => '/* Your custom styles, e.g. */\n.card { border-radius: 4px !important; }';
	@override String get custom_css_apply => 'Apply CSS';
	@override String get custom_css_applied => 'CSS applied';
	@override String get animation_threshold_label => 'List animation threshold';
	@override String get time_tracking_title => 'Time tracking backup';
	@override String get export_stats_btn => 'Export stats…';
	@override String get import_stats_btn => 'Import stats…';
	@override String get stats_exported => 'Time stats exported.';
	@override String get clear_stats_confirm_title => 'Clear all time data?';
	@override String get clear_stats_confirm_desc => 'This permanently deletes all time tracking history, session records, and per-project totals. This cannot be undone.';
	@override String get clear_stats_confirm_btn => 'Clear All';
	@override String get stats_cleared => 'Time data cleared.';
	@override String get settings_backup_title => 'Backup settings';
	@override String get export_settings_btn => 'Export Settings';
	@override String get import_settings_btn => 'Import Settings';
	@override String get workspace_backup_title => 'Backup workspace';
	@override String get workspace_backup_export_btn => 'Export Workspace';
	@override String get workspace_backup_restore_btn => 'Restore Workspace';
	@override String get workspace_backup_exported => 'Workspace backup exported.';
	@override String get workspace_backup_imported => 'Workspace restored.';
	@override String get app_backup_title => 'Backup everything (all workspaces)';
	@override String get app_backup_export_btn => 'Export Everything';
	@override String get app_backup_restore_btn => 'Restore Everything';
	@override String get app_backup_exported => 'Full app backup exported.';
	@override String get app_backup_imported => 'All workspaces restored.';
	@override String get sync_title => 'Cloud sync (GitHub gist)';
	@override String get sync_push_btn => 'Push';
	@override String get sync_pull_btn => 'Pull';
	@override String get sync_push_done => 'Workspace pushed to your gist.';
	@override String get sync_open_gist => 'Open gist';
	@override String get sync_last_pushed => 'Last pushed: {{time}}';
	@override String get sync_manual_hint => 'Lost your local data? Enter your gist URL or ID to restore from any machine.';
	@override String get sync_manual_placeholder => 'https://gist.github.com/... or gist ID';
	@override String get sync_manual_pull_btn => 'Restore';
	@override String get restore_modal_title => 'Restore from Cloud';
	@override String get restore_modal_fetching => 'Fetching backup from GitHub…';
	@override String get restore_modal_applying => 'Applying backup and restarting…';
	@override String get restore_modal_preview_desc => 'Your gist backup contains:';
	@override String restore_modal_workspaces({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'workspace',
		few: 'workspaces',
		many: 'workspaces',
		other: 'workspaces',
	);
	@override String restore_modal_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'project',
		few: 'projects',
		many: 'projects',
		other: 'projects',
	);
	@override String restore_modal_categories({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'category',
		few: 'categories',
		many: 'categories',
		other: 'categories',
	);
	@override String restore_modal_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'template',
		few: 'templates',
		many: 'templates',
		other: 'templates',
	);
	@override String get restore_modal_time_stats => 'Includes time tracking data';
	@override String restore_modal_todos({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Includes ${count} to-do',
		few: 'Includes ${count} to-dos',
		many: 'Includes ${count} to-dos',
		other: 'Includes ${count} to-dos',
	);
	@override String get restore_modal_project_scan_dirs => '{{count}} project scan folder(s) will be restored';
	@override String get restore_modal_version_scan_dirs => '{{count}} Godot version folder(s) will be restored';
	@override String get restore_modal_workspace_list => 'Workspaces';
	@override String get restore_modal_warning => 'This will overwrite your current settings and workspace data. You\'ll need to restart the app to apply changes.';
	@override String get restore_modal_apply_btn => 'Apply & Restart';
	@override String get restore_modal_done_title => 'Backup Restored';
	@override String get restore_modal_done_hint => 'Click the button below to restart and apply all changes.';
	@override String get settings_exported => 'Settings exported.';
	@override String get settings_imported => 'Settings imported.';
	@override String stats_imported({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Imported stats for ${count} project.',
		few: 'Imported stats for ${count} projects.',
		many: 'Imported stats for ${count} projects.',
		other: 'Imported stats for ${count} projects.',
	);
	@override String get raised_contrast_label => 'Raised surface contrast';
	@override String get raised_contrast_value => '{{value}}%';
	@override String get token_help_desc => 'Создайте токен на github.com/settings/tokens. You only need to check the repo scope if you want private repo access, otherwise leave all scopes unchecked. No sensitive permissions required.';
	@override String get discord_app_id_label => 'Discord Application ID';
	@override String get discord_app_id_placeholder => 'Leave empty to use the built-in default';
	@override String get discord_app_id_desc => 'Create an application in the Discord Developer Portal and paste its Application ID here to use your own instead of GodotHub\'s built-in one. The activity shows under that application\'s name.';
	@override String get discord_developer_portal => 'Discord Developer Portal';
	@override String get discord_builtin_hint => 'Using the built-in GodotHub application.';
	@override String get discord_show_projects_label => 'Show project names';
	@override String get discord_excluded_label => 'Excluded projects';
	@override String get discord_exclude_project => 'Add project';
	@override String get discord_excluded_empty => 'No excluded projects.';
	@override String get discord_excluded_remove => 'Remove from excluded projects';
	@override String get discord_custom_label => 'Custom presence';
	@override String get discord_custom_add => 'Add project';
	@override String get discord_custom_details_placeholder => 'Details line';
	@override String get discord_custom_state_placeholder => 'State line';
	@override String get discord_custom_remove => 'Remove custom presence';
	@override String get search_placeholder => 'Найти настройки…';
	@override String get interface_label => 'Interface';
	@override String get card_layout_label => 'Card layout';
	@override String get landing_tab_label => 'Default landing page';
	@override String get language_complete => 'Complete';
	@override String get language_beta => 'Beta';
	@override String get language_incomplete => 'Incomplete';
	@override String get use_os_decorations => 'Использовать системный вид окна';
	@override String get credits => 'Credits';
	@override String get credits_developer => 'Created by';
	@override String get credits_built_with => 'Built with';
	@override String get credits_contributors => 'Contributors';
	@override String get experimental => 'Experimental';
	@override String get customize_view_label => 'Customize View button';
	@override String get fixed_sidebar_resize_knob_label => 'Fixed sidebar resize knob';
	@override String get desktop_notifications_label => 'Desktop notifications';
	@override String get colored_titlebar_buttons_label => 'Colored window buttons';
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
	@override String features_enabled_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} feature on',
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
class _Translations$todos$ru_RU extends Translations$todos$en_US {
	_Translations$todos$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get next_steps => 'Next steps';
	@override String get saving_tasks => 'Saving tasks';
	@override String pending_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} pending',
		few: '${count} pending',
		many: '${count} pending',
		other: '${count} pending',
	);
	@override String completed_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} completed',
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
	@override String due_in_days({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Due in ${count} day',
		few: 'Due in ${count} days',
		many: 'Due in ${count} days',
		other: 'Due in ${count} days',
	);
	@override String get overdue_yesterday => 'Was due yesterday';
	@override String overdue_days({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Overdue by ${count} day',
		few: 'Overdue by ${count} days',
		many: 'Overdue by ${count} days',
		other: 'Overdue by ${count} days',
	);
	@override String get scan_code => 'Scan code';
	@override String get scan_code_hint => 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed';
	@override String get comment_scan_summary => 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened';
	@override String get comment_scan_none => 'Code scan found no changes';
	@override String commit_closed({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Completed ${count} to-do from a commit message',
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
	@override String open_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} to-do',
		few: '${count} to-dos',
		many: '${count} to-dos',
		other: '${count} to-dos',
	);
	@override String overdue_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} overdue',
		few: '${count} overdue',
		many: '${count} overdue',
		other: '${count} overdue',
	);
	@override String get tile_summary => '{{overdue}} overdue · {{soon}} due this week';
	@override String get tile_empty => 'Nothing overdue or due this week.';
	@override String due_notification_title({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'To-do due: {{title}}',
		few: '${count} to-dos are due',
		many: '${count} to-dos are due',
		other: '${count} to-dos are due',
	);
	@override String get due_notification_more => 'and {{count}} more';
}

// Path: versions
class _Translations$versions$ru_RU extends Translations$versions$en_US {
	_Translations$versions$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get standard => 'Стандартная';
	@override String get unbound => 'unbound';
	@override String get mono => 'Mono';
	@override String get both => 'Стандартная + Mono';
	@override String get stable => 'Стабильная';
	@override String get unstable => 'Нестабильная';
	@override String get rename => 'Переименовать';
	@override String get open_editor => 'Открыть редактор';
	@override String get open_editor_with_console => 'Открыть редактор с консолью';
	@override String get more_editor_launch_options => 'Больше опций запуска редактора';
	@override String get open_install_folder => 'Открыть папку установки';
	@override String get type => 'Тип';
	@override String get channel => 'Канал';
	@override String get fetch_error => 'Не удалось получить доступные версии.';
	@override String get paused_dot => 'Приостановить · ';
	@override String get available_title => 'Доступные версии';
	@override String get no_versions_match => 'Нет соответствующих установленных версий';
	@override String get no_available_versions_match => 'No available versions match';
	@override String get open => 'Открыть';
	@override String get install => 'Установить';
	@override String get mb => 'MB';
	@override String get resume_download => 'Возобновить загрузку';
	@override String get pause_download => 'Приостановить загрузку';
	@override String get cancel_download => 'Отменить загрузку';
	@override String installed_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		zero: 'No installs',
		one: 'Установлено',
		few: 'Installed',
		many: 'Installed',
		other: 'Установлено',
	);
	@override String get installed_label => 'Установлено';
	@override String get original_name => 'Original';
	@override String get source => 'Источник';
	@override String get source_github => 'GitHub';
	@override String get source_archive => 'Godot Archive';
	@override String get source_mise => 'mise';
	@override String get switch_to_archive => 'Switch to Godot Archive';
	@override String get sort_version_latest => 'Latest';
	@override String get sort_version_oldest => 'Oldest';
	@override String get sort_version_recently_installed => 'Recently Installed';
	@override String get sort_version_oldest_installed => 'Oldest Installed';
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
	@override String alias_create_all({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: 'Create Alias',
		few: 'Create ${count} Aliases',
		many: 'Create ${count} Aliases',
		other: 'Create ${count} Aliases',
	);
	@override String aliases_batch_created({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '1 alias created',
		few: '${count} aliases created',
		many: '${count} aliases created',
		other: '${count} aliases created',
	);
	@override String aliases_batch_skipped({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '1 alias skipped',
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
	@override String get templates_folder => 'Папка шаблонов';
	@override String get versions_folder => 'Папка версий';
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
	@override String export_templates_selected({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '1 template selected',
		few: '${count} templates selected',
		many: '${count} templates selected',
		other: '${count} templates selected',
	);
	@override String get export_templates_size_summary => '~{{download}} download · {{installed}} on disk';
	@override String get export_templates_download_selected => 'Download selected';
	@override String get export_templates_loading_options => 'Checking this release\'s available templates…';
	@override String get export_templates_options_failed => 'Couldn\'t load the templates for this release.';
	@override String export_templates_available({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '1 available template group',
		few: '${count} available template groups',
		many: '${count} available template groups',
		other: '${count} available template groups',
	);
	@override String get export_templates_select_all => 'Select all';
	@override String export_templates_files({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '1 template file',
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
	@override String get download_failed_title => 'Не удалось скачать';
	@override String get download_failed_asset_label => 'Файл';
	@override String get download_failed_error_label => 'Подробности ошибки';
	@override String get download_failed_copy => 'Копировать сведения';
	@override String get download_failed_hint => 'Частые причины: заблокированная сеть или прокси, антивирус, блокирующий загрузку, отсутствующая или доступная только для чтения папка загрузки, или нехватка места на диске.';
	@override String get custom_build_badge => 'Custom build';
	@override String get add_custom_build => 'Add custom build…';
	@override String get adding_custom_build => 'Adding custom build…';
}

// Path: common.project_doctor
class _Translations$common$project_doctor$ru_RU extends Translations$common$project_doctor$en_US {
	_Translations$common$project_doctor$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Project Doctor';
	@override String get scanning => 'Checking this project…';
	@override String get scan_failed => 'Could not check this project';
	@override String get run_again => 'Run checks again';
	@override String summary_errors({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} issue needs attention',
		few: '${count} issues need attention',
		many: '${count} issues need attention',
		other: '${count} issues need attention',
	);
	@override String summary_warnings({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} warning to review',
		few: '${count} warnings to review',
		many: '${count} warnings to review',
		other: '${count} warnings to review',
	);
	@override String get summary_ready => 'No blocking issues found';
	@override String get summary_counts => '{{passed}} checks passed · {{findings}} findings';
	@override String passed_checks({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} passed check',
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
class _Translations$common$build_export$ru_RU extends Translations$common$build_export$en_US {
	_Translations$common$build_export$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

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
class _Translations$common$project_addons$ru_RU extends Translations$common$project_addons$en_US {
	_Translations$common$project_addons$ru_RU._(TranslationsRuRu root) : this._root = root, super.internal(root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Addons';
	@override String get loading => 'Reading addons…';
	@override String count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} addon installed',
		few: '${count} addons installed',
		many: '${count} addons installed',
		other: '${count} addons installed',
	);
	@override String get empty => 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.';
	@override String get check_updates => 'Check for updates';
	@override String get checking => 'Checking…';
	@override String updates_available({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count,
		one: '${count} update available',
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

/// The flat map containing all translations for locale <ru-RU>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRuRu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'changelog.changelog_title' => 'Журнал изменений',
			'changelog.no_entries' => 'Нет записей в журнале изменений',
			'changelog.delete_entry_title' => 'Удалить запись из журнала изменений?',
			'changelog.delete_entry_desc' => 'Это приведет к постоянному удалению этой записи, операция необратима.',
			'changelog.changelog_subtitle' => 'История обновлений GodotHub.',
			'changelog.edit_entry_aria' => 'Edit {{version}}',
			'changelog.delete_entry_aria' => 'Delete {{version}}',
			'changelog.added' => 'Добавлено',
			'changelog.fixed' => 'Исправлено',
			'changelog.improved' => 'Улучшено',
			'common.new_project' => 'Новый проект',
			'common.import_project' => 'Импортировать проект',
			'common.search' => 'Поиск',
			'common.cancel' => 'Отмена',
			'common.save' => 'Сохранить',
			'common.delete' => 'Удалить',
			'common.close' => 'Закрыть',
			'common.loading' => 'Загрузка...',
			'common.retry' => 'Повторить',
			'common.stop' => 'Остановить',
			'common.refresh' => 'Обновить',
			'common.scroll_to_top' => 'Прокрутить к началу',
			'common.quick_commands' => 'Быстрые команды',
			'common.minimize' => 'Свернуть',
			'common.close_sidebar' => 'Закрыть боковую панель',
			'common.star_on_github' => 'Поставить звезду на GitHub',
			'common.support_dev' => 'Поддержите разработку на Patreon. Вы можете отключить эту кнопку в Настройках',
			'common.support' => 'Поддержать',
			'common.restore' => 'Восстановить',
			'common.maximize' => 'Развернуть на полный экран',
			'common.importing_project' => 'Импортирование проектов...',
			'common.importing_version' => 'Импортирование версий Godot…',
			'common.scanning_projects' => 'Сканирование проектов…',
			'common.scanning_versions' => 'Сканирование версий Godot…',
			'common.queued' => 'В очереди',
			'common.download_queue_move_up' => 'Move earlier in queue',
			'common.download_queue_move_down' => 'Move later in queue',
			'common.running' => 'Выполняется',
			'common.running_projects_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} project running', few: '${count} projects running', many: '${count} projects running', other: '${count} projects running', ), 
			'common.active' => 'Активные',
			'common.done' => 'Готово',
			'common.paused' => 'Пауза',
			'common.no_tasks_running' => 'Нет задач в работе',
			'common.checking_changes' => 'Проверка изменений…',
			'common.cloning' => 'Клонирование…',
			'common.clone_import' => 'Клонировать и импортировать',
			'common.import' => 'Импорт',
			'common.syncing' => 'Синхронизация…',
			'common.edit_entry' => 'Изменить запись в changelog',
			'common.new_entry' => 'Новая запись в changelog',
			'common.checking_updates' => 'Проверка обновлений…',
			'common.up_to_date' => 'Актуально',
			'common.downloading_update' => 'Загрузка…',
			'common.install_update' => 'Установить',
			'common.restart_now' => 'Перезапустить сейчас',
			'common.update_downloaded' => 'Обновление загружено!',
			'common.restart_to_apply' => 'Перезапустите GodotHub, чтобы применить обновление.',
			'common.update_applied_desc' => 'Обновление загружено и будет применено при следующем перезапуске GodotHub. Пожалуйста, закройте и снова откройте приложение, чтобы завершить обновление.',
			'common.is_latest' => 'v{{version}}, последняя версия.',
			'common.percent_complete' => 'Готово: {{percent}}%',
			'common.expand_sidebar' => 'Развернуть боковую панель',
			'common.collapse_sidebar' => 'Свернуть боковую панель',
			'common.saving' => 'Сохранение…',
			'common.save_changes' => 'Сохранить изменения',
			'common.add_entry' => 'Добавить запись',
			'common.scan_for_projects' => 'Сканировать проекты',
			'common.create_workspace' => 'Создать рабочее пространство',
			'common.report_a_bug' => 'Сообщить об ошибке',
			'common.report_bug' => 'Сообщить об ошибке',
			'common.app_error_title' => 'Что то пошло не так',
			'common.app_error_desc' => 'GodotHub столкнулся с непредвиденной ошибкой и не смог отрисовать интерфейс. Подробности ниже: проверьте консоль (правый клик → Inspect) чтобы увидеть полный stack trace.',
			'common.reload' => 'Перезагрузить',
			'common.view_error_title' => 'This view couldn\'t load',
			'common.view_error_desc' => 'The rest of GodotHub still works. Try loading this view again, or switch to another one.',
			'common.error_details' => 'Technical details',
			'common.remove_folder' => 'Удалить папку',
			'common.make_this_default' => 'Сделать это {{label}}',
			'common.suggested_from_workspaces' => 'Предложено из других рабочих пространств',
			'common.from_workspace' => 'из {{name}}',
			'common.add_folder' => 'Добавить папку',
			'common.default_folder' => 'По умолчанию',
			'common.default_downloads_go_to' => 'Загрузки по умолчанию будут сохраняться в «{{path}}»',
			'common.open_terminal' => 'Открыть терминал',
			'common.downloading_version' => 'Загрузка {{version}}',
			'common.downloading_asset' => 'Загрузка {{title}}',
			'common.asset_download_failed' => 'Не удалось скачать шаблон',
			'common.scan_for_engines' => 'Сканировать движки',
			'common.import_version' => 'Импортировать версию',
			'common.sync_templates_from_directory' => 'Синхронизировать шаблоны из каталога',
			'common.section_navigation' => 'Навигация',
			'common.section_projects' => 'Проекты',
			'common.section_views' => 'Views',
			'common.section_workspaces' => 'Рабочие области',
			'common.section_help' => 'Помощь',
			'common.section_engines' => 'Движки',
			'common.section_templates' => 'Шаблоны',
			'common.section_versions' => 'Версии',
			'common.section_news' => 'Новости',
			'common.skip_setup' => 'Пропустить настройку',
			'common.back' => 'Назад',
			'common.finishing' => 'Завершение…',
			'common.get_started' => 'Приступить',
			'common.scanning' => 'Сканирование…',
			'common.scan_now' => 'Сканировать сейчас',
			'common.scan_complete' => 'Scan complete',
			'common.scan_failed' => 'Scan failed',
			'common.uncategorized' => 'Без категории',
			'common.all' => 'All',
			'common.no_filter' => 'No Filter',
			'common.cannot_undo' => 'Это нельзя отменить.',
			'common.deleting' => 'Удаление…',
			'common.open_project' => 'Открыть проект',
			'common.play_project' => 'Play',
			'common.play_project_tooltip' => 'Play the game without opening editor',
			'common.no_version_selected' => 'Не выбрана версия',
			'common.open_with_console' => 'Открыть в консоли',
			'common.open_folder' => 'Открыть папку',
			'common.open_in_ide' => 'Открыть в IDE',
			'common.category' => 'Категория',
			'common.none' => 'Нет',
			'common.project_size' => 'Размер проекта',
			'common.project_size_scanning' => 'Scanning project files…',
			'common.project_size_empty' => 'No files found',
			'common.launch_arguments' => 'Аргументы запуска',
			'common.save_as_template' => 'Сохранить как шаблон',
			'common.git' => 'Git',
			'common.add' => 'Добавить',
			'common.color_label' => 'Цвет',
			'common.icon_label' => 'Иконка',
			'common.expand' => 'Развернуть',
			'common.collapse' => 'Свернуть',
			'common.file_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} file', few: '${count} файл', many: '${count} файл', other: '${count} files', ), 
			'common.folder_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} folder', few: '${count} папка', many: '${count} папка', other: '${count} folders', ), 
			'common.template_empty' => 'Этот шаблон пустой.',
			'common.categories' => 'Категории',
			'common.category_folders_hint' => 'Проекты, найденные в папках категории, автоматически назначаются ей.',
			'common.assign_folder' => 'Назначить папку',
			'common.assign_folder_to_category' => 'Назначить папку категории {{name}}',
			'common.unassign_folder_aria' => 'Убрать папку {{folder}} из этой категории',
			'common.new_category_placeholder' => 'Новая категория…',
			'common.no_categories_yet' => 'Без категории, добавьте из списка выше.',
			'common.edit_category' => 'Редактировать {{name}}',
			'common.delete_category' => 'Удалить {{name}}',
			'common.delete_category_title' => 'Удалить категорию?',
			'common.delete_category_desc' => '"{{name}}" будет удален. Проекты, перемещённые в эту категорию, будут перенесены в «Без категории». При этом ничего на диске не затрагивается.',
			'common.project_name_label' => 'Название',
			'common.folder_name_preview' => 'Папка. Конвенция: {{name}}',
			'common.folder_name_hint' => 'Имя папки определяется из названия проекта с использованием вашей схемы именования.',
			'common.template_preview_aria' => 'Предпросмотр {{name}}',
			'common.project_location_label' => 'Местоположение',
			'common.choose_folder_placeholder' => 'Выберите папку',
			'common.browse' => 'Обзор',
			'common.blank_template' => 'По умолчанию',
			'common.template_optional' => 'Шаблон (необязательно)',
			'common.category_optional' => 'Категория (необязательно)',
			'common.no_category_label' => 'Без категории',
			'common.godot_version_label' => 'Версия Godot',
			'common.no_engine_warning' => 'Движок ещё не установлен, сначала возьмите его на вкладке «Версии».',
			'common.change_icon' => 'Изменить',
			'common.choose_icon' => 'Выбрать',
			'common.icon_format_desc' => 'SVG, PNG или JPG. По умолчанию, логотип Godot.',
			'common.other_settings_label' => 'Другие настройки',
			'common.init_git_label' => 'Инициализировать репозиторий Git',
			'common.init_git_desc' => 'Добавляет Godot .gitignore и .gitattributes, а затем создаёт начальный коммит в main.',
			'common.init_git_unavailable' => 'Установите Git и перезапустите GodotHub, чтобы использовать это.',
			'common.initializing_git' => 'Настройка Git…',
			'common.git_init_warning_title' => 'Проект создан, проверьте Git init',
			'common.git_option_gitignore' => 'Godot .gitignore',
			'common.git_option_gitattributes' => '.gitattributes',
			'common.git_option_readme' => 'README.md',
			'common.git_option_license' => 'License',
			'common.git_option_no_license' => 'No license',
			'common.create_remote_label' => 'Create repository on GitHub/GitLab',
			'common.create_remote_desc' => 'Creates a repository on your connected account and pushes the initial commit.',
			'common.remote_private' => 'Приватный',
			'common.remote_public' => 'Публичный',
			'common.creating_remote_repo' => 'Creating remote repository…',
			'common.remote_repo_created_title' => 'Remote repository created',
			'common.create_project_done' => 'Готово',
			'common.create_project_btn' => 'Создать проект',
			'common.creating' => 'Создание…',
			'common.create_project_error' => 'Укажите название проекта и папку, в которой он будет создан.',
			'common.create_workspace_title' => 'Новое рабочее пространство',
			'common.workspace_name_label' => 'Имя',
			'common.workspace_name_placeholder' => 'Работа, Личное, Игровой джем…',
			'common.workspace_name_required_error' => 'Укажите имя рабочего пространства.',
			'common.edit_workspace_title' => 'Изменить рабочее пространство',
			'common.cant_delete_only_workspace' => 'Вы не можете удалить единственное рабочее пространство',
			'common.delete_workspace_title' => 'Удалить рабочее пространство?',
			'common.delete_workspace_desc' => '"{{name}}" и все что с ним связано (настройки, проекты, категории) будут удалены. Файлы на диске не будут затронуты. Установленные версии Godot так же не будут затронуты, так как распространяются на все рабочие пространства.',
			'common.other' => 'Другое',
			'common.args_label' => 'Аргументы',
			'common.args_placeholder' => 'например, --debug --single-window',
			'common.args_suggestions' => 'Предложения',
			'common.args_desc_separate_prefix' => 'Разделяйте аргументы пробелами. Флаги со значениями, например',
			'common.args_desc_separate_suffix' => 'используйте два токена.',
			'common.args_debug' => '--debug',
			'common.args_debug_desc' => 'Запуск с откладкой',
			'common.args_single_window' => '--single-window',
			'common.args_single_window_desc' => 'Принудительно включить режим одного окна',
			'common.args_opengl3' => '--rendering-driver opengl3',
			'common.args_opengl3_desc' => 'Использовать рендер-драйвер OpenGL 3',
			'common.args_vulkan' => '--rendering-driver vulkan',
			'common.args_vulkan_desc' => 'Использовать рендер-драйвер Vulkan',
			'common.args_headless' => '--headless',
			'common.args_headless_desc' => 'Запуск без окна',
			'common.args_verbose' => '--verbose',
			'common.args_verbose_desc' => 'Подробный вывод отладки в лог',
			'common.args_editor' => '--editor',
			'common.args_editor_desc' => 'Открыть редактор (можно использовать -e)',
			'common.args_build_solutions' => '--build-solutions',
			'common.args_build_solutions_desc' => 'Собирать C#-решения при открытии',
			'common.args_gpu_index' => '--gpu-index 1',
			'common.args_gpu_index_desc' => 'Использовать GPU с индексом 1 (дискретная видеокарта)',
			'common.sort_categories' => 'Категории',
			'common.sort_recent' => 'Недавно открытые',
			'common.sort_manual' => 'Вручную',
			'common.sort_name_asc' => 'Имя (A–Z)',
			'common.sort_name_desc' => 'Имя (Z–A)',
			'common.sort_created_desc' => 'Дата добавления (новые)',
			'common.sort_created_asc' => 'Дата добавления (старые)',
			'common.sort_time_desc' => 'Total time',
			'common.filter' => 'Filter',
			'common.no_templates_yet' => 'Пока нет шаблонов. Щёлкните правой кнопкой по проекту или откройте меню «Ещё» и выберите <1>Сохранить как шаблон</1>, чтобы создать его.',
			'common.godot' => 'Godot',
			'common.delete_template' => 'Удалить шаблон {{name}}',
			'common.news_subtitle' => 'Последние публикации с официального блога Godot Engine.',
			'common.news_cached' => 'Не удалось обратиться к godotengine.org, показываются статьи, сохранённые с прошлого раза.',
			'common.news_error' => 'Не удалось загрузить новости Godot.',
			'common.news_empty' => 'Пока никаких новостей.',
			'common.show_more' => 'Показать больше',
			'common.try_again' => 'Попробуйте еще раз',
			'common.asset_store_title' => 'МАГАЗИН АССЕТОВ',
			'common.news_count' => 'Posts',
			'common.asset_store_count_plural' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, zero: 'No assets', one: 'Asset', few: 'Assets', many: 'Assets', other: 'Assets', ), 
			'common.asset_store_count' => 'Assets',
			'common.settings_title' => 'НАСТРОЙКИ',
			'common.no_templates_match' => 'Шаблоны не найдены',
			'common.no_projects_match' => 'Проекты не найдены',
			'common.more_import_options' => 'Другие параметры импорта',
			'common.clone_import_repo' => 'Клонировать и импортировать из репозитория',
			'common.manage_categories' => 'Управление категориями',
			'common.hide_category' => 'Hide Category',
			'common.category_hidden_toast' => '"{{name}}" hidden. Restore it from Hidden Categories.',
			'common.hidden_categories' => 'Hidden Categories',
			'common.hidden_categories_hint' => 'Those categories and their projects stay out of the way. Unhide one to bring it back.',
			'common.hidden_category_projects' => '{{count}} project(s)',
			'common.unhide' => 'Unhide',
			'common.unhide_category_aria' => 'Unhide {{name}}',
			'common.search_projects_placeholder' => 'Поиск проектов по имени или пути…',
			'common.clear_search' => 'Очистить поиск',
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
			'common.sort' => 'Сортировка…',
			'common.view_list' => 'List',
			'common.view_grid' => 'Grid',
			'common.view_kanban' => 'Kanban',
			'common.no_projects_yet' => 'Пока здесь ничего нет. Создайте новый проект или импортируйте тот, который уже есть на диске.',
			'common.pinned_section' => 'Закреплённые',
			'common.set_category' => 'Указать категорию…',
			'common.clear_selection' => 'Сбросить выбор',
			'common.starting' => 'Запуск…',
			'common.app_loading' => 'Загрузка…',
			'common.changelog_version_label' => 'Версия',
			'common.changelog_version_placeholder' => 'v1.0.0',
			'common.changelog_date_label' => 'Дата',
			'common.changelog_date_placeholder' => '2026-07-13',
			'common.changelog_what_changed' => 'Что изменилось',
			'common.changelog_add_line' => 'Добавить строку',
			'common.changelog_remove_line_aria' => 'Удалить строку',
			'common.changelog_placeholder_note' => 'Добавлено перетаскивание для изменения порядка проектов',
			'common.changelog_error_no_version' => 'Укажите версию для записи.',
			'common.changelog_known_issues' => 'Известные проблемы',
			'common.changelog_known_issues_none' => 'Для этой версии известных проблем нет.',
			'common.changelog_known_issue_placeholder' => 'Опишите известную проблему…',
			'common.changelog_remove_known_issue_aria' => 'Удалить известную проблему',
			'common.changelog_add_known_issue' => 'Добавить известную проблему',
			'common.changelog_generate_from_git' => 'Generate from Git',
			'common.changelog_draft_title' => 'Release notes from Git',
			'common.changelog_draft_from' => 'From',
			'common.changelog_draft_to' => 'To',
			'common.changelog_draft_generate' => 'Generate draft',
			'common.changelog_draft_use' => 'Use Draft',
			'common.changelog_draft_commits' => '{{count}} commit(s)',
			'common.changelog_draft_include' => 'Include in draft',
			'common.changelog_draft_none' => 'No commits found in this range.',
			'common.template_search_placeholder' => 'Поиск шаблонов…',
			'common.template_delete_title' => 'Удалить шаблон?',
			'common.template_delete_desc' => '"{{name}}" будет удалён окончательно.',
			'common.templates_tab_local' => 'Локальные шаблоны',
			'common.templates_tab_asset' => 'Библиотека ассетов',
			'common.asset_search_placeholder' => 'Поиск ассетов…',
			'common.asset_all_versions' => 'Все версии',
			'common.asset_result_count' => '{{count}} результатов',
			'common.asset_load_error' => 'Не удалось загрузить библиотеку ассетов. Проверьте подключение и попробуйте ещё раз.',
			'common.asset_no_results' => 'Ассетов не найдено. Попробуйте другой запрос.',
			'common.asset_by_author' => 'от {{author}}',
			'common.asset_open_page' => 'Открыть в браузере',
			'common.asset_install' => 'Установить',
			'common.asset_install_inside' => 'Install Inside',
			'common.asset_installing' => 'Установка…',
			'common.asset_installed' => 'Установлено',
			'common.asset_prev_page' => 'Previous page',
			'common.asset_next_page' => 'Next page',
			'common.asset_page_x_of_y' => 'Page {{page}} of {{total}}',
			'common.template_your_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Template', few: 'Ваши шаблоны', many: 'Ваши шаблоны', other: 'Templates', ), 
			'common.template_imported_count' => 'Импортировано {{count}}',
			'common.template_updated_count' => 'Обновлено {{count}}',
			'common.template_removed_count' => 'Удалено {{count}}',
			'common.asset_source_all' => 'Все источники',
			'common.asset_source_library' => 'Старая Asset Library',
			'common.asset_source_store' => 'Новый магазин (Asset Store)',
			'common.asset_store_relevance' => 'Relevance',
			'common.asset_store_updated_new' => 'Newest updated',
			'common.asset_store_updated_old' => 'Oldest updated',
			'common.asset_store_rating_high' => 'Top rated',
			'common.asset_store_rating_low' => 'Lowest rated',
			'common.asset_download_outside' => 'Download Outside',
			'common.asset_downloaded' => 'Скачано',
			'common.asset_downloaded_to' => 'Скачано в',
			'common.asset_download_error' => 'Не удалось скачать ассет. Проверьте подключение и попробуйте ещё раз.',
			'common.asset_install_modal_title' => 'Установить {{title}}',
			'common.asset_install_tab_project' => 'В проект',
			'common.asset_install_tab_template' => 'В шаблон',
			'common.asset_install_search_projects' => 'Поиск проектов…',
			'common.asset_install_no_projects' => 'Пока нет проектов. Сначала создайте или импортируйте один.',
			'common.asset_install_no_templates' => 'Пока не сохранено ни одного шаблона.',
			'common.asset_install_into' => 'Установить в {{name}}',
			'common.asset_install_success_project' => 'Установлено в {{target}}',
			'common.asset_install_success_template' => 'Добавлено в шаблон {{target}}',
			'common.asset_new_template_btn' => 'Сохранить как новый шаблон',
			'common.asset_new_template_hint' => 'Создаёт новый шаблон из этого ассета проекта',
			'common.onboarding_keep_organized' => 'Храните проекты в организованном порядке, в одном месте.',
			'common.onboarding_download_manage' => 'Скачивайте и управляйте сборками движка Godot.',
			'common.onboarding_stay_current' => 'Следите за тем, что нового в Godot.',
			'common.onboarding_projects_title' => 'Где находятся ваши проекты?',
			'common.onboarding_projects_desc' => 'Добавьте папки, которые GodotHub должен сканировать на старте в поисках уже существующих проектов Godot. Поставьте звёздочку у одной из них, чтобы сделать её местом сохранения по умолчанию при создании нового проекта. Можно пропустить это и добавить папки позже в Настройках.',
			'common.onboarding_versions_title' => 'Где хранятся версии Godot?',
			'common.onboarding_versions_desc' => 'Добавьте папки, которые GodotHub должен сканировать для поиска установленных исполняемых файлов движка Godot. Поставьте звёздочку у одной из них, чтобы установить её как место загрузки новых версий, которые вы устанавливаете через вкладку Версии.',
			'common.onboarding_templates_title' => 'Папка шаблонов проектов',
			'common.onboarding_templates_desc' => 'При желании укажите папку, где вы храните повторно используемые шаблоны проектов. Любая подпапка внутри будет импортирована как шаблоны по завершении, чтобы они появлялись при создании новых проектов. Также вы можете сохранять отдельные проекты как шаблоны в любой момент из раздела Проекты или импортировать дополнительные позже на вкладке Шаблоны.',
			'common.onboarding_categories_title' => 'Организуйте с помощью категорий',
			'common.onboarding_categories_desc_full' => 'Категории, это папки для списка ваших проектов; складывайте проекты в них так, как вам удобно. Добавьте несколько заготовок или создайте свои; вы можете переименовывать, менять порядок или удалять их в любой момент в Настройках.',
			'common.onboarding_custom_category_placeholder' => 'Название категории…',
			'common.onboarding_your_categories' => 'Ваши категории',
			'common.onboarding_customize_title' => 'Сделайте по-своему',
			'common.onboarding_customize_desc' => 'Выберите акцент и цвет фона, чтобы начать. Скругление углов, плотность, размер текста и светлая/тёмная тема, всё это можно настроить в Настройках, когда захотите.',
			'common.onboarding_finish_title' => 'Готово',
			'common.onboarding_finish_desc' => 'GodotHub готов к работе. При желании вы можете вернуться к любому из этих параметров, папкам, категориям и внешнему виду, в любое время на вкладке Настройки.',
			'common.onboarding_setting_up_title' => 'Настройка',
			'common.onboarding_setting_up_desc' => 'Настройка вашей библиотеки… сканирование папок для проектов и версий Godot. Это происходит только один раз и займёт немного времени.',
			'common.skipped' => 'Пропущено',
			'common.onboarding_continue' => 'Продолжить',
			'common.onboarding_accent_color' => 'Акцентный цвет',
			'common.onboarding_bg_color' => 'Цвет фона',
			'common.onboarding_corner_radius' => 'Радиус углов',
			'common.onboarding_discord_rpc' => 'Discord Rich Presence',
			'common.onboarding_discord_rpc_desc' => 'Show what you\'re doing in GodotHub on your Discord profile.',
			'common.version_search_placeholder' => 'Найти версию...',
			'common.version_no_installed' => 'Пока нет установленных версий. Загрузите версию ниже или перетащите сюда папку с вашей существующей версией.',
			'common.version_save_name_aria' => 'Сохранить имя',
			'common.version_rename_aria' => 'Переименовать версию',
			'common.version_mono_badge' => 'Mono',
			'common.version_uninstall_title' => 'Удалить версию?',
			'common.version_uninstall_desc' => '«{{tag}}» и все его файлы будут перемещены в системную корзину / «Корзину» вашего компьютера. При необходимости вы сможете установить её заново.',
			'common.version_uninstall_confirm' => 'Удалить',
			'common.project_remove_title' => 'Удалить из библиотеки?',
			'common.project_remove_desc' => '«{{name}}» будет удалён из списка проектов GodotHub. Его файлы останутся на диске без изменений; вы сможете импортировать проект снова в любой момент.',
			'common.project_delete_title' => 'Переместить в корзину?',
			'common.project_delete_desc' => '«{{name}}» и всё, что внутри него, будет перемещено в системную корзину / «Корзину» вашего компьютера. При необходимости вы сможете восстановить это позже.',
			'common.project_delete_confirm' => 'Переместить в корзину',
			'common.project_template_name_label' => 'Название шаблона',
			'common.project_template_desc_label' => 'Описание',
			'common.project_template_desc_placeholder' => 'Что входит в этот шаблон?',
			'common.project_save_template_btn' => 'Сохранить шаблон',
			'common.template_saved_toast' => 'Template saved.',
			'common.project_select_aria' => 'Выбрать проект',
			'common.project_deselect_aria' => 'Снять выделение с проекта',
			'common.select_all_visible' => 'Select all visible',
			'common.selected_count' => '{{count}} selected',
			'common.bulk_launch' => 'Launch',
			'common.bulk_pin' => 'Pin',
			'common.bulk_remove' => 'Удалить',
			'common.bulk_remove_title' => 'Remove {{count}} projects from library?',
			'common.bulk_remove_desc' => 'The selected projects will be removed from your library. Their files will stay on disk.',
			'common.bulk_delete_title' => 'Delete {{count}} projects?',
			'common.bulk_delete_desc' => 'The selected project files will be permanently moved to the Trash. This cannot be undone.',
			'common.project_pin_aria' => 'Закрепить проект',
			'common.project_unpin_aria' => 'Открепить проект',
			'common.time_today' => 'Today',
			'common.time_this_week' => 'This week',
			'common.time_all_time' => 'All time',
			'common.time_tracked_title' => 'Time tracked',
			'common.time_weekly_chart' => 'Last 7 days',
			'common.time_week_total' => '{{total}} this week',
			'common.time_weekly_empty' => 'No tracked time in the last 7 days.',
			'common.project_more_aria' => 'Дополнительные действия',
			'common.customize_card_section' => 'Project Card',
			'common.customize_card_show_size' => 'Show Project Size',
			'common.customize_card_show_time' => 'Show Time Tracked',
			'common.customize_card_show_session_timer' => 'Show Session Timer',
			'common.customize_card_blur_path' => 'Blur Project Directory',
			'common.customize_card_show_path' => 'Show Project Directory',
			'common.customize_card_show_tags' => 'Show Tags',
			'common.customize_card_show_last_opened' => 'Show Last Opened',
			'common.customize_card_show_play' => 'Show Play Button',
			'common.customize_card_show_console' => 'Show Open with Console',
			'common.project_card_remove_library' => 'Удалить из библиотеки',
			'common.project_card_delete_files' => 'Удалить файлы',
			'common.manage_tags' => 'Управление тегами',
			'common.tag_input_placeholder' => 'Имя нового тега…',
			'common.tag_already_exists' => 'Тег с таким именем уже существует.',
			'common.tag_rename_hint' => 'Нажмите, чтобы переименовать',
			'common.tag_rename_aria' => 'Переименовать тег',
			'common.show_more_tags' => 'Show more tags',
			'common.show_fewer_tags' => 'Show fewer tags',
			'common.clear_tag_filter' => 'Clear tag filter',
			'common.saving_tags' => 'Saving tags…',
			'common.tag_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} tag', few: '${count} тег(ов)', many: '${count} тег(ов)', other: '${count} tags', ), 
			'common.no_tags' => 'Пока нет тегов',
			'common.bug_report_describe_label' => 'What happened?',
			'common.bug_report_describe_placeholder' => 'What were you doing when the bug appeared? Add steps to reproduce and what you expected vs. what actually happened.',
			'common.bug_report_diagnostics_label' => 'Diagnostic info',
			'common.bug_report_diagnostics_hint' => 'Auto-collected · included in the report',
			'common.bug_report_copied' => 'Copied!',
			'common.bug_report_copy_log' => 'Скопировать лог',
			'common.bug_report_download_log' => 'Скачать лог',
			'common.bug_report_open_github' => 'Открыть GitHub Issues',
			'common.check_updates_title_modal' => 'Проверить обновления',
			'common.check_updates_version_available' => 'Доступна версия {{version}}',
			'common.check_updates_ask_download' => 'Скачать и установить сейчас?',
			'common.check_updates_release_notes' => 'Примечания к выпуску',
			'common.check_updates_failed' => 'Не удалось проверить обновления',
			'common.check_updates_rate_limited' => 'Достигнут лимит запросов GitHub',
			'common.check_updates_token_rejected' => 'Токен GitHub отклонён',
			'common.check_updates_rate_limited_hint' => 'GitHub разрешает только 60 анонимных запросов в час, общий лимит для всех пользователей вашей сети. Добавление персонального токена в Настройках увеличивает лимит до 5 000 запросов в час и также используется для получения доступных версий Godot.',
			'common.check_updates_rate_limited_token_hint' => 'Сохранённый токен GitHub отклонён. Возможно, срок его действия истёк или он был отозван. Проверьте его в Настройках и замените при необходимости.',
			'common.check_updates_add_token' => 'Добавить токен GitHub',
			'common.check_updates_open_token_settings' => 'Открыть настройки токена',
			'common.check_updates_preview_badge' => 'Превью',
			'common.check_updates_portable_title' => 'Manual update required',
			'common.check_updates_portable_desc' => 'Portable installs cannot auto-update. Download the latest version from GitHub and replace the existing files.',
			'common.check_updates_download_from_github' => 'Скачать с GitHub',
			'common.preview_state_checking' => 'Проверка',
			'common.preview_state_available' => 'Доступно',
			'common.preview_state_downloading' => 'Загрузка',
			'common.preview_state_done' => 'Готово',
			'common.preview_state_uptodate' => 'Актуально',
			'common.preview_state_error' => 'Ошибка',
			'common.preview_state_portable' => 'Portable',
			'common.preview_update_modal' => 'Модальное окно превью обновления',
			'common.clone_repo_title' => 'Клонировать репозиторий',
			'common.clone_repo_url_label' => 'URL репозитория',
			'common.clone_repo_url_placeholder' => 'https://github.com/user/my-game.git',
			'common.clone_repo_error_url' => 'Пожалуйста, укажите URL репозитория.',
			'common.clone_repo_error_location' => 'Пожалуйста, выберите место для клонирования репозитория.',
			'common.clone_repo_open_after' => 'Open it right after importing',
			'common.clone_repo_browse_repos' => 'Просмотреть ваши репозитории',
			'common.clone_repo_url_manual' => 'Вставить URL вручную',
			'common.clone_repo_search_repos' => 'Поиск по вашим репозиториям...',
			'common.clone_repo_no_repos_found' => 'Репозитории не найдены.',
			'common.clone_repo_loading_repos' => 'Загрузка репозиториев...',
			'common.clone_repo_load_error' => 'Не удалось загрузить репозитории.',
			'common.clone_repo_select' => 'Выбрать',
			'common.clone_repo_no_account' => 'Аккаунт GitHub или GitLab не подключен. Используйте URL для клонирования.',
			'common.clone_repo_repos_loaded' => 'репозиториев загружено',
			'common.load_more' => 'Загрузить ещё',
			'common.git_uncommitted' => 'незакоммиченные',
			'common.git_clean' => 'Clean',
			'common.task_tray_title' => 'Задачи',
			'common.task_tray_empty' => 'Нет активных задач',
			'common.task_tray_active_count' => '{{active}} активных, {{recent}} недавних',
			'common.task_tray_only_recent' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} recent task', few: '${count} недавняя задача', many: '${count} недавняя задача', other: '${count} recent tasks', ), 
			'common.task_tray_aria' => 'Панель задач',
			'common.task_tray_auto_dismiss' => 'Завершённые задачи автоматически скрываются',
			'common.task_tray_dismiss' => 'Скрыть {{count}}',
			'common.task_error_status' => 'Ошибка',
			'common.command_palette_title' => 'Command Palette',
			'common.command_palette_placeholder' => 'Найти команду, проект, версию, настройки...',
			'common.command_palette_no_results' => 'Ничего не найдено',
			'common.command_palette_navigate' => 'Перейти',
			'common.command_palette_escape' => 'Esc',
			'common.setting_token_placeholder' => 'ghp_xxxxxxxxxxxxxxxxxxxx',
			'common.setting_project_scan_dirs' => 'Scan Project Folders',
			'common.setting_version_scan_dirs' => 'Scan Version Folders',
			'common.setting_default_project_location' => 'Default Project Location Setting',
			'common.setting_download_dir' => 'Download Versions Location Setting',
			'common.setting_scan_depth' => 'Scan Depth',
			'common.setting_icon_scan_depth' => 'Project Icon Search Depth',
			'common.setting_download_concurrency' => 'Simultaneous Downloads',
			'common.setting_close_on_project_open' => 'Close on Project Open',
			'common.setting_minimize_to_tray' => 'Minimize to System Tray',
			'common.setting_reopen_after_godot_closes' => 'Reopen After Godot Closes',
			'common.setting_auto_scan_on_startup' => 'Auto-scan on Startup',
			'common.setting_workspaces_enabled' => 'Use Workspaces',
			'common.setting_directory_naming_convention' => 'Directory Naming Convention',
			'common.setting_git_init_new_projects' => 'Initialize Git for New Projects',
			'common.setting_tooltip_delay' => 'Tooltip Delay',
			'common.setting_command_palette_keybind' => 'Command Palette Shortcut',
			'common.setting_tray_recent_projects_count' => 'Tray Recent Projects',
			'common.setting_last_opened_time_format' => 'Time Format',
			'common.setting_last_opened_date_format' => 'Date Format',
			'common.setting_theme_mode' => 'Theme Mode',
			'common.setting_accent_color' => 'Акцентный цвет',
			_ => null,
		} ?? switch (path) {
			'common.setting_background_color' => 'Цвет фона',
			'common.setting_corner_radius' => 'Corner Radius',
			'common.setting_ui_density' => 'UI Density',
			'common.setting_font_scale' => 'Text Size',
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
			'common.active_workspace' => '{{name}} (active)',
			'common.current_workspace' => 'Текущее рабочее пространство',
			'common.switch_workspace' => 'Переключить рабочее пространство',
			'common.opened_recently' => 'Открыт(а) {{label}}',
			'common.recent_section' => 'Недавние',
			'common.installed_versions_section' => 'Установленные версии',
			'common.settings_label' => 'Настройки → {{tab}}',
			'common.remove_category_aria' => 'Удалить {{name}}',
			'common.git_remove_remote' => 'Удалить удалённый репозиторий',
			'common.git_commit_placeholder' => 'Сообщение коммита…',
			'common.restart_required_title' => 'Требуется перезапуск',
			'common.restart_required_desc' => 'Чтобы изменение полностью вступило в силу, GodotHub нужно перезапустить. Настройка сохранена и применится при повторном запуске приложения.',
			'common.found_dismissed_title' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Найдён ранее удалённый проект', few: '${count} previously removed projects found', many: '${count} previously removed projects found', other: 'Найдены ${count} ранее удалённых проектов', ), 
			'common.found_dismissed_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Сканер обнаружил 1 проект, который вы ранее удаляли из библиотеки. Добавить обратно?', few: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', many: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', other: 'Сканер обнаружил ${count} проектов, которые вы ранее удаляли из библиотеки. Добавить обратно?', ), 
			'common.readd_all' => 'Добавить все обратно',
			'common.skip_all' => 'Пропустить всё',
			'common.project_already_open_title' => 'Project already open',
			'common.project_already_open_desc' => '{{name}} is already running. Opening it again launches a second editor instance. Open anyway?',
			'common.project_open_anyway' => 'Open anyway',
			'common.git_sidebar' => 'Git sidebar',
			'common.asset_duplicate_title' => 'Template already installed',
			'common.asset_duplicate_desc' => '"{{name}}" is already in your templates. Install a duplicate anyway?',
			'common.empty_category' => 'Empty Category',
			'common.release_to_drop' => 'Release to drop',
			'common.preview_release_notes' => '## What\'s new in v1.0.0 - The Preview Update\\n\\n## New\\n\\n- Revamped the Check for Updates modal with structured release notes\\n- Added screen reader announcements with an Accessibility settings tab\\n\\n## Fixes\\n\\n- Fixed a crash when switching workspaces with pinned projects\\n- Fixed update checks failing silently when GitHub rate limits are hit\\n\\n## Improvements\\n\\n- Faster startup times across all platforms\\n- Reworked workspace modals with compact style pickers\\n\\n## Known Issues\\n\\n- Linux OS: AppImage won\'t work on some distros, use the .rpm or .deb package instead\\n- Windows: the taskbar may briefly show a duplicate icon until the app restarts',
			'common.preview_error' => 'Preview error: GitHub API rate limit reached (HTTP 403). Add a token in Settings to keep checking.',
			'common.bug_report_system' => 'System',
			'common.bug_report_version' => 'Version',
			'common.bug_report_date' => 'Date',
			'common.bug_report_os' => 'OS',
			'common.bug_report_platform' => 'Platform',
			'common.bug_report_language' => 'Language',
			'common.bug_report_cpu_cores' => 'CPU Cores',
			'common.bug_report_ram' => 'RAM',
			'common.bug_report_screen' => 'Screen',
			'common.bug_report_gpu' => 'GPU',
			'common.bug_report_user_agent' => 'User Agent',
			'common.bug_report_recent_errors' => 'Recent Errors',
			'common.bug_report_none_captured' => 'none captured',
			'common.bug_report_description' => 'Description',
			'common.bug_report_no_description' => 'No description provided',
			'common.unknown' => 'неизвестно',
			'common.gpu_webgl_unavailable' => 'WebGL not available',
			'common.gpu_info_unavailable' => 'GPU info unavailable',
			'common.update_available' => 'Update available',
			'common.dismiss' => 'Dismiss',
			'common.system_language' => 'Язык системы',
			'common.category_empty_hint' => 'Create one above to organize your projects',
			'common.contributor_pr_merged' => 'Merged',
			'common.contributor_pr_open' => 'Open',
			'common.contributor_pr_closed' => 'Closed',
			'common.contributor_pr_loading' => 'Loading PRs...',
			'common.contributor_pr_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} pull request', few: '${count} pull requests', many: '${count} pull requests', other: '${count} pull requests', ), 
			'common.contributor_pr_load_failed' => 'Failed to load pull requests.',
			'common.contributor_pr_network_hint' => 'Check your internet connection.',
			'common.contributor_pr_empty' => 'No pull requests found.',
			'common.theme_presets_section' => 'Theme presets',
			'common.all_categories' => 'Все категории',
			'common.clear_category_filter' => 'Clear category filter',
			'common.filter_by_category' => 'Filter by category',
			'common.theme_dark' => 'Темная тема',
			'common.theme_light' => 'Светлая тема',
			'common.bulk_tags' => 'Tags',
			'common.bulk_tags_title' => 'Edit tags',
			'common.add_tag' => 'Добавить тег',
			'common.remove_tag' => 'Удалить тег',
			'common.no_common_tags' => 'No tags on the selected projects yet.',
			'common.tags_added_to_selection' => 'Added tag to {{count}} projects.',
			'common.tags_removed_from_selection' => 'Removed tag from {{count}} projects.',
			'common.removed_from_library' => 'Removed {{count}} project(s) from library.',
			'common.undo' => 'Undo',
			'common.duplicate_project_title' => 'Duplicate project',
			'common.copy_suffix' => 'copy',
			'common.duplicate' => 'Duplicate',
			'common.destination_folder' => 'Папка назначения',
			'common.new_project_name' => 'Project name',
			'common.project_duplicated' => 'Project duplicated.',
			'common.notification_version_installed' => 'Godot {{tag}} installed',
			'common.notification_asset_installed' => '{{title}} installed',
			'common.notification_clone_done' => 'Repository cloned and imported',
			'common.console_title' => 'Console',
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
			'common.project_doctor.summary_errors' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} issue needs attention', few: '${count} issues need attention', many: '${count} issues need attention', other: '${count} issues need attention', ), 
			'common.project_doctor.summary_warnings' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} warning to review', few: '${count} warnings to review', many: '${count} warnings to review', other: '${count} warnings to review', ), 
			'common.project_doctor.summary_ready' => 'No blocking issues found',
			'common.project_doctor.summary_counts' => '{{passed}} checks passed · {{findings}} findings',
			'common.project_doctor.passed_checks' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} passed check', few: '${count} passed checks', many: '${count} passed checks', other: '${count} passed checks', ), 
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
			'common.cleanup_confirm_btn' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Remove ${count} item', few: 'Remove ${count} items', many: 'Remove ${count} items', other: 'Remove ${count} items', ), 
			'common.cleanup_done' => 'Freed {{size}}',
			'common.cleanup_failed' => 'Couldn\'t remove {{label}}: {{error}}',
			'common.cleanup_versions_desc' => 'Full size on disk of every installed Godot version.',
			'common.cleanup_templates_title' => 'Project templates',
			'common.cleanup_export_templates_title' => 'Export templates',
			'common.cleanup_used_by_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} template', few: '${count} templates', many: '${count} templates', other: '${count} templates', ), 
			'common.cleanup_current_badge' => 'Current',
			'common.cleanup_alias_badge' => 'Alias',
			'common.cleanup_unused_badge' => 'Unused',
			'common.cleanup_mise_badge' => 'Managed by mise',
			'common.cleanup_external_badge' => 'External',
			'common.cleanup_orphan_badge' => 'Orphaned',
			'common.cleanup_empty' => 'Nothing here yet.',
			'common.new_badge' => 'New',
			'common.reset' => 'Восставновить по умолчанию',
			'common.git_disconnect' => 'Disconnect',
			'common.git_sign_in_github' => 'Sign in with GitHub',
			'common.git_connected_as' => 'Connected as @{{username}}',
			'common.optional' => '(optional)',
			'common.language_label' => 'Язык',
			'common.n_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} проект', few: '${count} projects', many: '${count} projects', other: '${count} проектов', ), 
			'common.vault_item_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Item', few: 'Items', many: 'Items', other: 'Items', ), 
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
			'common.vault_conflict_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} file already exists in the project. Overwrite it?', few: '${count} files already exist in the project. Overwrite them?', many: '${count} files already exist in the project. Overwrite them?', other: '${count} files already exist in the project. Overwrite them?', ), 
			'common.vault_conflict_summary_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} file already exists across the selected projects. Overwrite it?', few: '${count} files already exist across the selected projects. Overwrite them?', many: '${count} files already exist across the selected projects. Overwrite them?', other: '${count} files already exist across the selected projects. Overwrite them?', ), 
			'common.vault_added_toast' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Added ${count} file', few: 'Added ${count} files', many: 'Added ${count} files', other: 'Added ${count} files', ), 
			'common.vault_added_to_projects_toast' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Added to ${count} project', few: 'Added to ${count} projects', many: 'Added to ${count} projects', other: 'Added to ${count} projects', ), 
			'common.vault_item_empty' => 'This item has no files.',
			'common.kNew' => 'Новый',
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
			'common.project_addons.count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} addon installed', few: '${count} addons installed', many: '${count} addons installed', other: '${count} addons installed', ), 
			'common.project_addons.empty' => 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.',
			'common.project_addons.check_updates' => 'Check for updates',
			'common.project_addons.checking' => 'Checking…',
			'common.project_addons.updates_available' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} update available', few: '${count} updates available', many: '${count} updates available', other: '${count} updates available', ), 
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
			'dashboard.greeting_morning' => 'Good morning',
			'dashboard.greeting_afternoon' => 'Good afternoon',
			'dashboard.greeting_evening' => 'Good evening',
			'dashboard.greeting_night' => 'Good night',
			'dashboard.greeting_name' => '{{greeting}}, {{name}}',
			'dashboard.dashboard_rename_hint' => 'Set a custom name',
			'dashboard.dashboard_rename_aria' => 'Rename your greeting name',
			'dashboard.dashboard_rename_save' => 'Save name',
			'dashboard.dashboard_rename_reset' => 'Use system name',
			'dashboard.dashboard_name_placeholder' => 'Your name',
			'dashboard.dashboard_clock_aria' => 'Current time',
			'dashboard.dashboard_new_project' => 'New Project',
			'dashboard.dashboard_import_project' => 'Import Project',
			'dashboard.dashboard_scan_projects' => 'Scan for Projects',
			'dashboard.dashboard_stat_projects' => 'Projects',
			'dashboard.dashboard_stat_templates' => 'Templates',
			'dashboard.dashboard_stat_engines' => 'Engines',
			'dashboard.dashboard_stat_total_time' => 'Total Time',
			'dashboard.dashboard_stat_total_time_hint' => 'Time spent on projects',
			'dashboard.dashboard_recent' => 'Recently Opened',
			'dashboard.dashboard_recent_empty' => 'Nothing opened yet. Open a project to see it here.',
			'dashboard.dashboard_pinned' => 'Pinned',
			'dashboard.dashboard_pinned_empty' => 'No pinned projects yet. Pin a project to keep it handy.',
			'dashboard.dashboard_engines' => 'Installed Engines',
			'dashboard.dashboard_engines_empty' => 'No engines installed yet.',
			'dashboard.dashboard_running' => 'Running Now',
			'dashboard.dashboard_running_empty' => 'Nothing is running right now.',
			'dashboard.dashboard_opened_at' => 'Opened {{time}}',
			'dashboard.dashboard_daily' => 'Daily Activity',
			'dashboard.dashboard_daily_empty' => 'No daily activity yet.',
			'dashboard.dashboard_weekly' => 'Weekly Activity',
			'dashboard.dashboard_weekly_empty' => 'No weekly activity yet.',
			'dashboard.dashboard_monthly' => 'Monthly Activity',
			'dashboard.dashboard_monthly_empty' => 'No monthly activity yet.',
			'dashboard.dashboard_yearly' => 'Yearly Activity',
			'dashboard.dashboard_yearly_empty' => 'No yearly activity yet.',
			'dashboard.dashboard_activity_cycle' => 'Switch to {{next}}',
			'dashboard.dashboard_weekly_aria' => '{{label}} of tracked time',
			'dashboard.dashboard_top_time' => 'Top Projects by Time',
			'dashboard.dashboard_top_time_empty' => 'No tracked time yet. Open a project to start tracking.',
			'dashboard.dashboard_insights' => 'Insights',
			'dashboard.dashboard_insights_empty' => 'No tracked time yet. Open a project to start building your streaks.',
			'dashboard.dashboard_insights_longest_streak' => 'Longest streak',
			'dashboard.dashboard_insights_current_streak' => 'Current streak',
			'dashboard.dashboard_insights_days' => '{{count}} days',
			'dashboard.dashboard_insights_productive_day' => 'Most productive day',
			'dashboard.dashboard_insights_this_month' => 'This month',
			'dashboard.dashboard_insights_delta_up' => '{{pct}}% more than last month',
			'dashboard.dashboard_insights_delta_down' => '{{pct}}% less than last month',
			_ => null,
		} ?? switch (path) {
			'dashboard.dashboard_git' => 'Git Overview',
			'dashboard.dashboard_git_empty' => 'No git repositories detected.',
			'dashboard.dashboard_git_clean' => 'All clean',
			'dashboard.dashboard_git_dirty' => '{{count}} with uncommitted changes',
			'dashboard.dashboard_git_dirty_plural' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '1 with uncommitted changes', few: '${count} with uncommitted changes', many: '${count} with uncommitted changes', other: '${count} with uncommitted changes', ), 
			'dashboard.dashboard_git_branch' => 'On {{branch}}',
			'dashboard.dashboard_storage' => 'Storage Usage',
			'dashboard.dashboard_storage_empty' => 'No projects to measure.',
			'dashboard.dashboard_storage_loading' => 'Measuring…',
			'dashboard.dashboard_storage_total' => '{{size}} total',
			'dashboard.dashboard_customize' => 'Customize',
			'dashboard.dashboard_done_customizing' => 'Done',
			'dashboard.dashboard_customize_hint' => 'Use the arrows to rearrange tiles, or hide the ones you don\'t need.',
			'dashboard.dashboard_tile_move_up' => 'Move up',
			'dashboard.dashboard_tile_move_down' => 'Move down',
			'dashboard.dashboard_tile_remove' => 'Remove',
			'dashboard.dashboard_tile_span' => 'Full width',
			'dashboard.dashboard_tile_span_off' => 'Half width',
			'dashboard.dashboard_tile_tall' => 'Taller',
			'dashboard.dashboard_tile_tall_off' => 'Normal height',
			'dashboard.dashboard_presets' => 'Layout presets',
			'dashboard.dashboard_preset_default' => 'Default',
			'dashboard.dashboard_preset_default_desc' => 'Everything on, in the default order, standard sizing.',
			'dashboard.dashboard_preset_overview' => 'Overview',
			'dashboard.dashboard_preset_overview_desc' => 'Recently opened, pinned, engines, and running projects.',
			'dashboard.dashboard_preset_analytics' => 'Analytics',
			'dashboard.dashboard_preset_analytics_desc' => 'Weekly activity, top projects, storage, and categories, with taller charts.',
			'dashboard.dashboard_preset_development' => 'Development',
			'dashboard.dashboard_preset_development_desc' => 'Git status front and center with running projects and engines.',
			'dashboard.dashboard_preset_save' => 'Save current as preset',
			'dashboard.dashboard_preset_save_hint' => 'Name this layout so you can switch back to it anytime.',
			'dashboard.dashboard_preset_name_placeholder' => 'Preset name',
			'dashboard.dashboard_preset_delete' => 'Delete preset',
			'dashboard.dashboard_custom_presets' => 'Your presets',
			'dashboard.dashboard_hidden_tiles' => 'Hidden tiles',
			'dashboard.dashboard_todos' => 'Due to-dos',
			'dashboard.dashboard_range_daily' => 'День',
			'dashboard.dashboard_range_weekly' => 'Неделя',
			'dashboard.dashboard_range_monthly' => 'Месяц',
			'dashboard.dashboard_range_yearly' => 'Год',
			'dashboard.dashboard_activity_tracked' => 'Записано',
			'dashboard.dashboard_activity_peak' => 'Пик',
			'git.remove' => 'Удалить',
			'git.changes_title' => 'Изменения',
			'git.pull' => 'Обновить',
			'git.push' => 'Отправить',
			'git.force_push' => 'Принудительно',
			'git.fetch' => 'Загрузить',
			'git.change' => 'Изменить',
			'git.commit' => 'Коммит',
			'git.committing' => 'Выполняется коммит…',
			'git.no_remotes' => 'No remotes configured',
			'git.switching' => 'Switching…',
			'git.no_branches' => 'No branches found',
			'git.new_branch_placeholder' => 'Branch name',
			'git.delete_branch' => 'Delete branch',
			'git.publish_branch' => 'Publish branch',
			'git.publish_branch_to' => 'Publish branch to {{remote}}',
			'git.branch_published' => 'Branch published.',
			'git.use_ours' => 'Use ours',
			'git.use_theirs' => 'Use theirs',
			'git.i_resolved' => 'I resolved it',
			'git.undo_last_commit' => 'Undo last commit',
			'git.undo_pull' => 'Undo pull',
			'git.force_push_confirm_title' => 'Force push?',
			'git.force_push_confirm_desc' => 'This rewrites remote history and can lose other people\'s commits. Continue?',
			'git.undo_commit_done' => 'Last commit undone.',
			'git.undo_pull_done' => 'Pull undone.',
			'git.force_pushed' => 'Force pushed.',
			'git.synced_ok' => 'Synced.',
			'git.fetched_ok' => 'Fetched.',
			'git.pulled_ok' => 'Pulled.',
			'git.pushed_ok' => 'Pushed.',
			'git.branch_created' => 'Branch created.',
			'git.branch_deleted' => 'Branch deleted.',
			'git.changes_stashed_ok' => 'Changes stashed.',
			'git.stash_applied_ok' => 'Stash applied.',
			'git.stash_popped_ok' => 'Stash popped.',
			'git.stash_dropped_ok' => 'Stash dropped.',
			'git.staged_ok' => 'Staged.',
			'git.unstaged_ok' => 'Unstaged.',
			'git.discarded_ok' => 'Discarded.',
			'git.stage_all_ok' => 'Staged all changes.',
			'git.unstage_all_ok' => 'Unstaged all changes.',
			'git.discard_all_ok' => 'Discarded all changes.',
			'git.resolved_ours' => 'Resolved using ours.',
			'git.resolved_theirs' => 'Resolved using theirs.',
			'git.resolved_manual' => 'Marked as resolved.',
			'git.committed_ok' => 'Committed.',
			'git.switched_ok' => 'Switched to {{branch}}.',
			'git.sync' => 'Sync',
			'git.diff_no_diff' => 'No diff available for this file.',
			'git.fetching' => 'Fetching…',
			'git.stashes_title' => 'Stashes',
			'git.stash' => 'Stash',
			'git.stashing' => 'Stashing…',
			'git.apply_stash' => 'Apply stash',
			'git.pop_stash' => 'Pop stash',
			'git.drop_stash' => 'Drop stash',
			'git.merge_aborted' => 'Слияние отменено. Рабочая директория восстановлена.',
			'git.new_branch_btn' => '+ Новая',
			'git.abort_merge' => 'Отменить merge',
			'git.merge_in_progress' => 'Выполняется merge',
			'git.working_tree_clean' => 'Рабочее дерево чистое.',
			'git.staged_changes' => 'Добавленные в индекс изменения',
			'git.unstage_all_changes' => 'Убрать из индекса все изменения',
			'git.commits_title' => 'Коммиты',
			'git.stage_file' => 'Добавить файл в индекс',
			'git.discard_file' => 'Discard file',
			'git.unstage_file' => 'Убрать файл из индекса',
			'git.no_commits_found' => 'Коммиты не найдены.',
			'git.stage_all' => 'Добавить все',
			'git.discard_all' => 'Discard All',
			'git.auth_connected_accounts' => 'Connected accounts',
			'git.auth_connect_hint' => 'Connect to your desired git host to begin, or use SSH without connecting anything.',
			'git.worktrees_title' => 'Worktrees',
			'git.worktree_current' => 'Current',
			'git.no_worktrees' => 'No additional worktrees',
			'git.switch_worktree' => 'Switch to this worktree',
			'git.switched_worktree_ok' => 'Switched to worktree.',
			'git.add_worktree' => 'Новое рабочее дерево',
			'git.add_worktree_btn' => 'Add worktree',
			'git.worktree_path_placeholder' => 'Path (e.g. ../my-feature)',
			'git.worktree_branch_placeholder' => 'Branch name (optional)',
			'git.worktree_created_ok' => 'Worktree created.',
			'git.worktree_dirty' => 'Uncommitted changes',
			'git.remove_worktree' => 'Remove worktree',
			'git.remove_worktree_confirm_desc' => 'Удалить рабочее дерево в {{path}}? Его каталог будет удалён. Ветка и коммиты будут сохранены.',
			'git.worktree_removed_ok' => 'Worktree removed.',
			'git.auto_fetch_label' => 'Fetch automatically',
			'git.auto_fetch_hint' => 'Runs git fetch every few minutes so the pull bubble always shows how many commits you\'re behind, without merging anything. Leave it off to only fetch when you click Fetch.',
			'git.commits_to_push' => '{{count}} commit(s) to push',
			'git.commits_to_pull' => '{{count}} commit(s) to pull',
			'git.filter_changes' => 'Filter changed files…',
			'git.no_matching_changes' => 'No matching changes.',
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
			'nav.dashboard' => 'Панель управления',
			'nav.projects' => 'Проекты',
			'nav.projects_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Project', few: 'Проекты', many: 'Проекты', other: 'Projects', ), 
			'nav.versions' => 'Версии',
			'nav.templates' => 'Шаблоны',
			'nav.vault' => 'Vault',
			'nav.asset_store' => 'Магазин ассетов',
			'nav.news' => 'Новости',
			'nav.storage_view' => 'Storage',
			'nav.settings' => 'Настройки',
			'nav.changelog' => 'Журнал изменений',
			'nav.group_workspace' => 'Рабочая область',
			'nav.group_resources' => 'Ресурсы',
			'nav.group_explore' => 'Обзор',
			'nav.you' => 'You',
			'nav.account_manage' => 'Manage accounts',
			'nav.workspace_tip_title' => 'Переключатель рабочих областей переехал',
			'nav.workspace_tip_body' => 'Переключайте и настраивайте рабочие области в меню аккаунта ниже.',
			'nav.workspace_tip_dismiss' => 'Понятно',
			'onboarding.welcome' => 'Добро пожаловать',
			'onboarding.finish' => 'Завершить',
			'onboarding.in_progress' => 'В процессе',
			'onboarding.prototypes' => 'Прототипы',
			'onboarding.finished' => 'Завершенные',
			'onboarding.game_jams' => 'Геймджемы',
			'onboarding.project_folders' => 'Папки проектов',
			'onboarding.version_folders' => 'Папки версий',
			'onboarding.welcome_title' => 'Добро пожаловать в GodotHub',
			'onboarding.welcome_desc' => 'Место для ваших проектов и версий Godot. Давайте настроим его так, чтобы всё работало так, как вам нужно, это займет всего минуту, и всё можно будет изменить позже в настройках.',
			'onboarding.onboard_empty_projects' => 'Папки с проектами не добавлены. GodotHub не может найти существующие проекты, если вы не добавите папки.',
			'onboarding.onboard_empty_versions' => 'Папки с версиями Godot не добавлены. Новые загрузки Godot будут сохранены в папке данных приложения, если вы не укажете другую папку.',
			'onboarding.onboard_no_template_folder' => 'Папка для шаблонов не выбрана, вы всегда можете настроить это позже в Настройках или сохранять шаблоны вручную.',
			'onboarding.onboard_cloud_heading' => 'Cloud Backup',
			'onboarding.onboard_cloud_desc' => 'Already have a backup? Sign in with GitHub and restore your workspaces, projects, and settings from a gist.',
			'onboarding.discovery_recent_heading' => 'Recent projects from Godot',
			'onboarding.discovery_installs_heading' => 'Godot found on this computer',
			'onboarding.discovery_scanning_projects' => 'Reading Godot\'s project manager list…',
			'onboarding.discovery_scanning_installs' => 'Looking for Godot on your PATH and in Steam…',
			'onboarding.discovery_engine' => 'Godot {{version}}',
			'onboarding.discovery_favorite' => 'Favorite',
			'onboarding.discovery_add_selected' => 'Add selected',
			'onboarding.discovery_add_selected_count' => 'Add selected ({{count}})',
			'onboarding.discovery_added_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Added ${count} project.', few: 'Added ${count} projects.', many: 'Added ${count} projects.', other: 'Added ${count} projects.', ), 
			'onboarding.discovery_added_versions' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Added ${count} version.', few: 'Added ${count} versions.', many: 'Added ${count} versions.', other: 'Added ${count} versions.', ), 
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
			'settings.storage' => 'Хранилище',
			'settings.behavior' => 'Поведение',
			'settings.display' => 'Отображение',
			'settings.appearance' => 'Внешний вид',
			'settings.accessibility' => 'Accessibility',
			'settings.accessibility_desc' => 'Screen reader announcements and assistive technology options.',
			'settings.app_version_label' => 'GodotHub v{{version}}',
			'settings.landing_dashboard' => 'Dashboard',
			'settings.landing_projects' => 'Projects',
			'settings.landing_versions' => 'Versions',
			'settings.landing_news' => 'Godot News',
			'settings.screen_reader_label' => 'Screen reader announcements',
			'settings.advanced' => 'Дополнительно',
			'settings.integrations' => 'Integrations',
			'settings.motion' => 'Motion',
			'settings.data' => 'Data & Backup',
			'settings.git_auth_title' => 'Sign in with {{provider}}',
			'settings.git_auth_copy_code' => 'Copy code',
			'settings.git_auth_copy_link' => 'Copy link',
			'settings.git_auth_waiting' => 'Waiting for you to authorize…',
			'settings.git_sign_in_gitlab' => 'Sign in with GitLab',
			'settings.git_connected_to' => 'Connected to {{host}} as @{{username}}',
			'settings.git_self_hosted_title' => 'Self-hosted GitLab',
			'settings.git_self_hosted_desc' => 'Connect to your own GitLab instance. Create an OAuth application on your instance (scopes: read_repository, write_repository, read_user) and paste its base URL and Application ID.',
			'settings.git_self_hosted_url_placeholder' => 'https://gitlab.example.com',
			'settings.git_self_hosted_client_id' => 'Application ID',
			'settings.git_sign_in_self_hosted' => 'Sign in with instance',
			'settings.git_pat_title' => 'Other hosts (personal access tokens)',
			'settings.git_pat_add' => 'Add token',
			'settings.git_pat_host_placeholder' => 'e.g. codeberg.org',
			'settings.git_pat_username' => 'Username',
			'settings.git_pat_token' => 'Token',
			'settings.git_pat_save' => 'Save token',
			'settings.git_pat_empty' => 'No tokens added yet.',
			'settings.git_pat_remove' => 'Remove token',
			'settings.storage_title' => 'Хранилище и сканирование',
			'settings.behavior_projects_title' => 'Проекты',
			'settings.file_watchers_title' => 'Наблюдение за файлами',
			'settings.last_opened_title' => 'Отображение "последнего открытия"',
			'settings.github_token_title' => 'GitHub API Токен',
			'settings.titlebar_buttons' => 'Кнопки в заголовке окна',
			'settings.setup_wizard' => 'Setup Wizard',
			'settings.setup_wizard_again' => 'Запустить Setup Wizard снова',
			'settings.restart_app' => 'Restart App',
			'settings.restart_app_confirm_title' => 'Restart GodotHub?',
			'settings.restart_app_confirm_desc' => 'The app will close and reopen automatically. Unsaved in-progress operations may be interrupted.',
			'settings.reset_settings' => 'Восстановить настройки по умолчанию',
			'settings.delete_app_data' => 'Удалить все данные приложения',
			'settings.new_project_default' => 'Новый проект по умолчанию',
			'settings.download_folder' => 'Папка для загрузок',
			'settings.system' => 'System',
			'settings.k12h' => '12-часовой (2:30 PM)',
			'settings.k24h' => '24-часовой (14:30)',
			'settings.dd_mm_yyyy' => 'ДД-ММ-ГГГГ',
			'settings.mm_dd_yyyy' => 'ММ-ДД-ГГГГ',
			'settings.yyyy_mm_dd' => 'ГГГГ-ММ-ДД',
			'settings.reset_all_title' => 'Установить все настройки по умолчанию?',
			'settings.reset_all_desc' => 'Это восстанавливает все настройки на этой странице, включая папку загрузок, папки сканирования, внешний вид и поведение, к значениям по умолчанию. Это действие нельзя отменить.',
			'settings.delete_all_title' => 'Удалить данные приложения?',
			'settings.delete_all_desc' => 'Это навсегда удаляет все рабочие пространства, проекты, категории, записи об установленных версиях и настройки, которые GodotHub сохранил, и перезапускает вас в режиме первичной настройки. Фактические папки проектов и установки Godot на диске не затрагиваются, если только они не находятся в папке загрузок по умолчанию. В этом случае они также будут удалены. Это действие нельзя отменить.',
			'settings.empty_hint_projects' => 'Папки не выбраны, при запуске ничего сканироваться не будет, и при добавлении новых проектов каждый раз будет спрашиваться, куда их сохранять.',
			'settings.empty_hint_versions' => 'Папки не выбраны, при запуске ничего сканироваться не будет, и новые загрузки будут использовать папку данных приложения.',
			'settings.naming_convention_label' => 'Правила наименований для директорий',
			'settings.naming_keep' => 'Сохранить как введено (Моя игра)',
			'settings.naming_kebab' => 'kebab-case (Моя-игра)',
			'settings.naming_snake' => 'snake_case (Моя_игра)',
			'settings.naming_camel' => 'camelCase (мояИгра)',
			'settings.naming_pascal' => 'PascalCase (МояИгра)',
			'settings.naming_title' => 'Title Case (Моя Игра)',
			'settings.theme' => 'Тема',
			'settings.theme_preset_label' => 'Theme preset',
			'settings.theme_preset_custom' => 'Custom',
			'settings.preset_light_group' => 'Light themes',
			'settings.preset_dark_group' => 'Dark themes',
			'settings.test' => 'Тест',
			'settings.testing' => 'Тестирование…',
			'settings.token_valid' => 'Валидный токен! Лимит вызовов: {{status}}',
			'settings.token_resets_in' => '(resets ~{{minutes}} min)',
			'settings.test_failed' => 'Тест не удался: {{error}}',
			'settings.key_space' => 'Пробел',
			'settings.no_settings_match' => 'Настройки не найдены',
			'settings.scan_result' => 'Найдено {{projects}} новых проектов и {{versions}} новых версий.',
			'settings.palette_shortcut' => 'Горячая клавиша для вызова палитры команд',
			'settings.keybind_instruction' => 'Нажмите кнопку ниже, затем нажмите любую клавишу для переназначения.',
			'settings.press' => 'Нажмите',
			'settings.to_cancel' => 'чтобы отменить',
			'settings.press_key' => 'Нажмите клавишу…',
			'settings.click_to_rebind' => 'Нажмите чтобы переназначить',
			'settings.close_on_open_label' => 'Закрыть GodotHub при открытии проекта',
			'settings.launch_console_label' => 'Запустить Godot с терминалом',
			'settings.builtin_console_label' => 'Use the built-in console',
			'settings.minimize_tray_label' => 'Свернуть в трей при закрытии приложения',
			'settings.reopen_label' => 'Открыть снова после закрытия Godot',
			'settings.no_folder_set' => 'Папка не выбрана. Вы всё ещё можете импортировать проекты вручную или использовать \'Сохранить как шаблон\'.',
			'settings.ui_density_label' => 'Плотность интерфейса',
			'settings.text_size_label' => 'Размер текста',
			'settings.section_godot_versions' => 'Версии Godot',
			'settings.scan_depth_label' => 'Глубина сканирования',
			'settings.icon_scan_depth_label' => 'Project icon search depth',
			'settings.download_concurrency_label' => 'Одновременные загрузки',
			'settings.tray_recent_label' => 'Последние проекты в трее',
			'settings.tooltip_delay_label' => 'Задержка подсказки',
			'settings.project_icon_opacity_label' => 'Прозрачность иконки проекта',
			'settings.time_format_label' => 'Формат времени (показывается при открытии сегодня)',
			'settings.date_format_label' => 'Формат даты (показывается для любого другого дня)',
			'settings.auto_scan_label' => 'Авто-сканирование при запуске',
			'settings.use_workspaces_label' => 'Использовать рабочие пространства',
			'settings.watch_projects_label' => 'Отслеживать папки проектов',
			'settings.watch_versions_label' => 'Отслеживать папки версий',
			'settings.watch_template_label' => 'Отслеживать директорию шаблонов',
			'settings.show_scrollbar_label' => 'Показать полосу прокрутки',
			'settings.animated_numbers_label' => 'Animated numbers',
			'settings.show_support_label' => 'Показать кнопку поддержки',
			'settings.show_star_label' => 'Показать кнопку звезды',
			'settings.show_bug_label' => 'Show bug report button',
			'settings.show_tray_label' => 'Show tray button',
			'settings.show_language_label' => 'Show language button',
			'settings.clear' => 'Очистить',
			'settings.reset_to_default' => 'Восстановить настройки по умолчанию',
			'settings.reset_appearance' => 'Восстановить настройки внешнего вида по умолчанию',
			'settings.delete_all' => 'Удалить всё',
			'settings.open_setup' => 'Открыть Настройки',
			'settings.reset_colors' => 'Установить цвета по умолчанию',
			'settings.folders_deep' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} папку вглубь', few: '${count} folders deep', many: '${count} folders deep', other: '${count} папок вглубь', ), 
			'settings.at_once' => '{{count}} одновременно',
			'settings.animation_speed_label' => 'Animation speed',
			'settings.scroll_reveal_label' => 'Scroll reveal',
			'settings.card_tilt_label' => 'Card tilt on hover',
			'settings.click_ripple_label' => 'Click ripple',
			'settings.press_bounce_label' => 'Press bounce',
			'settings.animation_intensity_label' => 'Animation intensity',
			'settings.animation_full' => 'Full',
			'settings.animation_subtle' => 'Subtle',
			'settings.animation_none' => 'None',
			'settings.view_entrance_label' => 'View entrance animation',
			'settings.entrance_fade' => 'Fade',
			'settings.entrance_slide' => 'Slide',
			'settings.entrance_scale' => 'Scale',
			'settings.entrance_none' => 'None',
			'settings.custom_css_label' => 'Custom CSS',
			'settings.custom_css_placeholder' => '/* Your custom styles, e.g. */\n.card { border-radius: 4px !important; }',
			'settings.custom_css_apply' => 'Apply CSS',
			'settings.custom_css_applied' => 'CSS applied',
			'settings.animation_threshold_label' => 'List animation threshold',
			'settings.time_tracking_title' => 'Time tracking backup',
			'settings.export_stats_btn' => 'Export stats…',
			'settings.import_stats_btn' => 'Import stats…',
			'settings.stats_exported' => 'Time stats exported.',
			'settings.clear_stats_confirm_title' => 'Clear all time data?',
			'settings.clear_stats_confirm_desc' => 'This permanently deletes all time tracking history, session records, and per-project totals. This cannot be undone.',
			'settings.clear_stats_confirm_btn' => 'Clear All',
			'settings.stats_cleared' => 'Time data cleared.',
			'settings.settings_backup_title' => 'Backup settings',
			'settings.export_settings_btn' => 'Export Settings',
			'settings.import_settings_btn' => 'Import Settings',
			'settings.workspace_backup_title' => 'Backup workspace',
			'settings.workspace_backup_export_btn' => 'Export Workspace',
			'settings.workspace_backup_restore_btn' => 'Restore Workspace',
			'settings.workspace_backup_exported' => 'Workspace backup exported.',
			'settings.workspace_backup_imported' => 'Workspace restored.',
			'settings.app_backup_title' => 'Backup everything (all workspaces)',
			'settings.app_backup_export_btn' => 'Export Everything',
			'settings.app_backup_restore_btn' => 'Restore Everything',
			'settings.app_backup_exported' => 'Full app backup exported.',
			'settings.app_backup_imported' => 'All workspaces restored.',
			'settings.sync_title' => 'Cloud sync (GitHub gist)',
			'settings.sync_push_btn' => 'Push',
			'settings.sync_pull_btn' => 'Pull',
			'settings.sync_push_done' => 'Workspace pushed to your gist.',
			'settings.sync_open_gist' => 'Open gist',
			'settings.sync_last_pushed' => 'Last pushed: {{time}}',
			'settings.sync_manual_hint' => 'Lost your local data? Enter your gist URL or ID to restore from any machine.',
			'settings.sync_manual_placeholder' => 'https://gist.github.com/... or gist ID',
			'settings.sync_manual_pull_btn' => 'Restore',
			'settings.restore_modal_title' => 'Restore from Cloud',
			'settings.restore_modal_fetching' => 'Fetching backup from GitHub…',
			'settings.restore_modal_applying' => 'Applying backup and restarting…',
			'settings.restore_modal_preview_desc' => 'Your gist backup contains:',
			'settings.restore_modal_workspaces' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'workspace', few: 'workspaces', many: 'workspaces', other: 'workspaces', ), 
			'settings.restore_modal_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'project', few: 'projects', many: 'projects', other: 'projects', ), 
			'settings.restore_modal_categories' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'category', few: 'categories', many: 'categories', other: 'categories', ), 
			'settings.restore_modal_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'template', few: 'templates', many: 'templates', other: 'templates', ), 
			'settings.restore_modal_time_stats' => 'Includes time tracking data',
			'settings.restore_modal_todos' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Includes ${count} to-do', few: 'Includes ${count} to-dos', many: 'Includes ${count} to-dos', other: 'Includes ${count} to-dos', ), 
			'settings.restore_modal_project_scan_dirs' => '{{count}} project scan folder(s) will be restored',
			'settings.restore_modal_version_scan_dirs' => '{{count}} Godot version folder(s) will be restored',
			'settings.restore_modal_workspace_list' => 'Workspaces',
			'settings.restore_modal_warning' => 'This will overwrite your current settings and workspace data. You\'ll need to restart the app to apply changes.',
			'settings.restore_modal_apply_btn' => 'Apply & Restart',
			'settings.restore_modal_done_title' => 'Backup Restored',
			'settings.restore_modal_done_hint' => 'Click the button below to restart and apply all changes.',
			'settings.settings_exported' => 'Settings exported.',
			'settings.settings_imported' => 'Settings imported.',
			'settings.stats_imported' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Imported stats for ${count} project.', few: 'Imported stats for ${count} projects.', many: 'Imported stats for ${count} projects.', other: 'Imported stats for ${count} projects.', ), 
			'settings.raised_contrast_label' => 'Raised surface contrast',
			'settings.raised_contrast_value' => '{{value}}%',
			'settings.token_help_desc' => 'Создайте токен на github.com/settings/tokens. You only need to check the repo scope if you want private repo access, otherwise leave all scopes unchecked. No sensitive permissions required.',
			'settings.discord_app_id_label' => 'Discord Application ID',
			'settings.discord_app_id_placeholder' => 'Leave empty to use the built-in default',
			'settings.discord_app_id_desc' => 'Create an application in the Discord Developer Portal and paste its Application ID here to use your own instead of GodotHub\'s built-in one. The activity shows under that application\'s name.',
			'settings.discord_developer_portal' => 'Discord Developer Portal',
			'settings.discord_builtin_hint' => 'Using the built-in GodotHub application.',
			'settings.discord_show_projects_label' => 'Show project names',
			'settings.discord_excluded_label' => 'Excluded projects',
			'settings.discord_exclude_project' => 'Add project',
			'settings.discord_excluded_empty' => 'No excluded projects.',
			'settings.discord_excluded_remove' => 'Remove from excluded projects',
			'settings.discord_custom_label' => 'Custom presence',
			'settings.discord_custom_add' => 'Add project',
			'settings.discord_custom_details_placeholder' => 'Details line',
			'settings.discord_custom_state_placeholder' => 'State line',
			'settings.discord_custom_remove' => 'Remove custom presence',
			'settings.search_placeholder' => 'Найти настройки…',
			'settings.interface_label' => 'Interface',
			'settings.card_layout_label' => 'Card layout',
			'settings.landing_tab_label' => 'Default landing page',
			'settings.language_complete' => 'Complete',
			'settings.language_beta' => 'Beta',
			'settings.language_incomplete' => 'Incomplete',
			'settings.use_os_decorations' => 'Использовать системный вид окна',
			'settings.credits' => 'Credits',
			'settings.credits_developer' => 'Created by',
			'settings.credits_built_with' => 'Built with',
			'settings.credits_contributors' => 'Contributors',
			'settings.experimental' => 'Experimental',
			'settings.customize_view_label' => 'Customize View button',
			'settings.fixed_sidebar_resize_knob_label' => 'Fixed sidebar resize knob',
			'settings.desktop_notifications_label' => 'Desktop notifications',
			'settings.colored_titlebar_buttons_label' => 'Colored window buttons',
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
			'settings.features_enabled_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} feature on', few: '${count} features on', many: '${count} features on', other: '${count} features on', ), 
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
			'todos.pending_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} pending', few: '${count} pending', many: '${count} pending', other: '${count} pending', ), 
			'todos.completed_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} completed', few: '${count} completed', many: '${count} completed', other: '${count} completed', ), 
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
			'todos.due_in_days' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Due in ${count} day', few: 'Due in ${count} days', many: 'Due in ${count} days', other: 'Due in ${count} days', ), 
			'todos.overdue_yesterday' => 'Was due yesterday',
			'todos.overdue_days' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Overdue by ${count} day', few: 'Overdue by ${count} days', many: 'Overdue by ${count} days', other: 'Overdue by ${count} days', ), 
			'todos.scan_code' => 'Scan code',
			'todos.scan_code_hint' => 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed',
			'todos.comment_scan_summary' => 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened',
			'todos.comment_scan_none' => 'Code scan found no changes',
			'todos.commit_closed' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Completed ${count} to-do from a commit message', few: 'Completed ${count} to-dos from commit messages', many: 'Completed ${count} to-dos from commit messages', other: 'Completed ${count} to-dos from commit messages', ), 
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
			'todos.open_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} to-do', few: '${count} to-dos', many: '${count} to-dos', other: '${count} to-dos', ), 
			'todos.overdue_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '${count} overdue', few: '${count} overdue', many: '${count} overdue', other: '${count} overdue', ), 
			'todos.tile_summary' => '{{overdue}} overdue · {{soon}} due this week',
			'todos.tile_empty' => 'Nothing overdue or due this week.',
			'todos.due_notification_title' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'To-do due: {{title}}', few: '${count} to-dos are due', many: '${count} to-dos are due', other: '${count} to-dos are due', ), 
			'todos.due_notification_more' => 'and {{count}} more',
			'versions.standard' => 'Стандартная',
			'versions.unbound' => 'unbound',
			'versions.mono' => 'Mono',
			'versions.both' => 'Стандартная + Mono',
			'versions.stable' => 'Стабильная',
			'versions.unstable' => 'Нестабильная',
			'versions.rename' => 'Переименовать',
			'versions.open_editor' => 'Открыть редактор',
			'versions.open_editor_with_console' => 'Открыть редактор с консолью',
			'versions.more_editor_launch_options' => 'Больше опций запуска редактора',
			'versions.open_install_folder' => 'Открыть папку установки',
			'versions.type' => 'Тип',
			'versions.channel' => 'Канал',
			'versions.fetch_error' => 'Не удалось получить доступные версии.',
			'versions.paused_dot' => 'Приостановить · ',
			'versions.available_title' => 'Доступные версии',
			'versions.no_versions_match' => 'Нет соответствующих установленных версий',
			'versions.no_available_versions_match' => 'No available versions match',
			'versions.open' => 'Открыть',
			'versions.install' => 'Установить',
			'versions.mb' => 'MB',
			'versions.resume_download' => 'Возобновить загрузку',
			'versions.pause_download' => 'Приостановить загрузку',
			'versions.cancel_download' => 'Отменить загрузку',
			'versions.installed_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, zero: 'No installs', one: 'Установлено', few: 'Installed', many: 'Installed', other: 'Установлено', ), 
			'versions.installed_label' => 'Установлено',
			'versions.original_name' => 'Original',
			'versions.source' => 'Источник',
			'versions.source_github' => 'GitHub',
			'versions.source_archive' => 'Godot Archive',
			'versions.source_mise' => 'mise',
			'versions.switch_to_archive' => 'Switch to Godot Archive',
			'versions.sort_version_latest' => 'Latest',
			'versions.sort_version_oldest' => 'Oldest',
			'versions.sort_version_recently_installed' => 'Recently Installed',
			'versions.sort_version_oldest_installed' => 'Oldest Installed',
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
			'versions.alias_create_all' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: 'Create Alias', few: 'Create ${count} Aliases', many: 'Create ${count} Aliases', other: 'Create ${count} Aliases', ), 
			'versions.aliases_batch_created' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '1 alias created', few: '${count} aliases created', many: '${count} aliases created', other: '${count} aliases created', ), 
			'versions.aliases_batch_skipped' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '1 alias skipped', few: '${count} aliases skipped', many: '${count} aliases skipped', other: '${count} aliases skipped', ), 
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
			'versions.templates_folder' => 'Папка шаблонов',
			'versions.versions_folder' => 'Папка версий',
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
			'versions.export_templates_selected' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '1 template selected', few: '${count} templates selected', many: '${count} templates selected', other: '${count} templates selected', ), 
			'versions.export_templates_size_summary' => '~{{download}} download · {{installed}} on disk',
			'versions.export_templates_download_selected' => 'Download selected',
			'versions.export_templates_loading_options' => 'Checking this release\'s available templates…',
			'versions.export_templates_options_failed' => 'Couldn\'t load the templates for this release.',
			'versions.export_templates_available' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '1 available template group', few: '${count} available template groups', many: '${count} available template groups', other: '${count} available template groups', ), 
			'versions.export_templates_select_all' => 'Select all',
			'versions.export_templates_files' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ru'))(count, one: '1 template file', few: '${count} template files', many: '${count} template files', other: '${count} template files', ), 
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
			'versions.download_failed_title' => 'Не удалось скачать',
			'versions.download_failed_asset_label' => 'Файл',
			'versions.download_failed_error_label' => 'Подробности ошибки',
			'versions.download_failed_copy' => 'Копировать сведения',
			'versions.download_failed_hint' => 'Частые причины: заблокированная сеть или прокси, антивирус, блокирующий загрузку, отсутствующая или доступная только для чтения папка загрузки, или нехватка места на диске.',
			'versions.custom_build_badge' => 'Custom build',
			'versions.add_custom_build' => 'Add custom build…',
			'versions.adding_custom_build' => 'Adding custom build…',
			_ => null,
		};
	}
}
