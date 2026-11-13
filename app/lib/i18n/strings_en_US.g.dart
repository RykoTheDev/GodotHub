///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEnUs = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.enUs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en-US>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$changelog$en_US changelog = Translations$changelog$en_US.internal(_root);
	late final Translations$common$en_US common = Translations$common$en_US.internal(_root);
	late final Translations$dashboard$en_US dashboard = Translations$dashboard$en_US.internal(_root);
	late final Translations$git$en_US git = Translations$git$en_US.internal(_root);
	late final Translations$nav$en_US nav = Translations$nav$en_US.internal(_root);
	late final Translations$onboarding$en_US onboarding = Translations$onboarding$en_US.internal(_root);
	late final Translations$settings$en_US settings = Translations$settings$en_US.internal(_root);
	late final Translations$todos$en_US todos = Translations$todos$en_US.internal(_root);
	late final Translations$versions$en_US versions = Translations$versions$en_US.internal(_root);
}

// Path: changelog
class Translations$changelog$en_US {
	Translations$changelog$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'CHANGELOG'
	String get changelog_title => 'CHANGELOG';

	/// en-US: 'No changelog entries yet'
	String get no_entries => 'No changelog entries yet';

	/// en-US: 'Delete changelog entry?'
	String get delete_entry_title => 'Delete changelog entry?';

	/// en-US: 'This removes the entry permanently. This can't be undone.'
	String get delete_entry_desc => 'This removes the entry permanently. This can\'t be undone.';

	/// en-US: 'A history of GodotHub updates.'
	String get changelog_subtitle => 'A history of GodotHub updates.';

	/// en-US: 'Edit {{version}}'
	String get edit_entry_aria => 'Edit {{version}}';

	/// en-US: 'Delete {{version}}'
	String get delete_entry_aria => 'Delete {{version}}';

	/// en-US: 'Added'
	String get added => 'Added';

	/// en-US: 'Fixed'
	String get fixed => 'Fixed';

	/// en-US: 'Improved'
	String get improved => 'Improved';
}

// Path: common
class Translations$common$en_US {
	Translations$common$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'New Project'
	String get new_project => 'New Project';

	/// en-US: 'Import Project'
	String get import_project => 'Import Project';

	/// en-US: 'Search'
	String get search => 'Search';

	/// en-US: 'Cancel'
	String get cancel => 'Cancel';

	/// en-US: 'Save'
	String get save => 'Save';

	/// en-US: 'Delete'
	String get delete => 'Delete';

	/// en-US: 'Close'
	String get close => 'Close';

	/// en-US: 'Loading...'
	String get loading => 'Loading...';

	/// en-US: 'Retry'
	String get retry => 'Retry';

	/// en-US: 'Stop'
	String get stop => 'Stop';

	/// en-US: 'Refresh'
	String get refresh => 'Refresh';

	/// en-US: 'Scroll to top'
	String get scroll_to_top => 'Scroll to top';

	/// en-US: 'Quick Commands'
	String get quick_commands => 'Quick Commands';

	/// en-US: 'Minimize'
	String get minimize => 'Minimize';

	/// en-US: 'Close Sidebar'
	String get close_sidebar => 'Close Sidebar';

	/// en-US: 'Star on GitHub'
	String get star_on_github => 'Star on GitHub';

	/// en-US: 'Support the Development on Patreon. You can toggle this off in Settings'
	String get support_dev => 'Support the Development on Patreon. You can toggle this off in Settings';

	/// en-US: 'Support'
	String get support => 'Support';

	/// en-US: 'Restore'
	String get restore => 'Restore';

	/// en-US: 'Maximize'
	String get maximize => 'Maximize';

	/// en-US: 'Importing project…'
	String get importing_project => 'Importing project…';

	/// en-US: 'Importing version…'
	String get importing_version => 'Importing version…';

	/// en-US: 'Scanning for projects…'
	String get scanning_projects => 'Scanning for projects…';

	/// en-US: 'Scanning for versions…'
	String get scanning_versions => 'Scanning for versions…';

	/// en-US: 'Queued…'
	String get queued => 'Queued…';

	/// en-US: 'Move earlier in queue'
	String get download_queue_move_up => 'Move earlier in queue';

	/// en-US: 'Move later in queue'
	String get download_queue_move_down => 'Move later in queue';

	/// en-US: 'Running'
	String get running => 'Running';

	/// en-US: '(one) {${count} project running} (other) {${count} projects running}'
	String running_projects_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} project running',
		other: '${count} projects running',
	);

	/// en-US: '{{count}} project running'
	String get running_projects_desc_one => '{{count}} project running';

	/// en-US: '{{count}} projects running'
	String get running_projects_desc_other => '{{count}} projects running';

	/// en-US: 'Active'
	String get active => 'Active';

	/// en-US: 'Done'
	String get done => 'Done';

	/// en-US: 'Paused'
	String get paused => 'Paused';

	/// en-US: 'No tasks running'
	String get no_tasks_running => 'No tasks running';

	/// en-US: 'Checking changes…'
	String get checking_changes => 'Checking changes…';

	/// en-US: 'Cloning…'
	String get cloning => 'Cloning…';

	/// en-US: 'Clone & Import'
	String get clone_import => 'Clone & Import';

	/// en-US: 'Import'
	String get import => 'Import';

	/// en-US: 'Syncing…'
	String get syncing => 'Syncing…';

	/// en-US: 'Edit Changelog Entry'
	String get edit_entry => 'Edit Changelog Entry';

	/// en-US: 'New Changelog Entry'
	String get new_entry => 'New Changelog Entry';

	/// en-US: 'Checking for updates…'
	String get checking_updates => 'Checking for updates…';

	/// en-US: 'Up to date'
	String get up_to_date => 'Up to date';

	/// en-US: 'Downloading…'
	String get downloading_update => 'Downloading…';

	/// en-US: 'Install'
	String get install_update => 'Install';

	/// en-US: 'Restart Now'
	String get restart_now => 'Restart Now';

	/// en-US: 'Update downloaded!'
	String get update_downloaded => 'Update downloaded!';

	/// en-US: 'Restart GodotHub to apply the update.'
	String get restart_to_apply => 'Restart GodotHub to apply the update.';

	/// en-US: 'The update has been downloaded and will be applied the next time you restart GodotHub. Please close and reopen the app to finish the update.'
	String get update_applied_desc => 'The update has been downloaded and will be applied the next time you restart GodotHub. Please close and reopen the app to finish the update.';

	/// en-US: 'v{{version}} is the latest version.'
	String get is_latest => 'v{{version}} is the latest version.';

	/// en-US: '{{percent}}% complete'
	String get percent_complete => '{{percent}}% complete';

	/// en-US: 'Expand sidebar'
	String get expand_sidebar => 'Expand sidebar';

	/// en-US: 'Collapse sidebar'
	String get collapse_sidebar => 'Collapse sidebar';

	/// en-US: 'Saving…'
	String get saving => 'Saving…';

	/// en-US: 'Save Changes'
	String get save_changes => 'Save Changes';

	/// en-US: 'Add Entry'
	String get add_entry => 'Add Entry';

	/// en-US: 'Scan'
	String get scan_for_projects => 'Scan';

	/// en-US: 'Create Workspace'
	String get create_workspace => 'Create Workspace';

	/// en-US: 'Report a Bug'
	String get report_a_bug => 'Report a Bug';

	/// en-US: 'Report Bug'
	String get report_bug => 'Report Bug';

	/// en-US: 'Something went wrong'
	String get app_error_title => 'Something went wrong';

	/// en-US: 'GodotHub hit an unexpected error and couldn't render. Details below, check the console (right-click → Inspect) for the full stack trace.'
	String get app_error_desc => 'GodotHub hit an unexpected error and couldn\'t render. Details below, check the console (right-click → Inspect) for the full stack trace.';

	/// en-US: 'Reload'
	String get reload => 'Reload';

	/// en-US: 'This view couldn't load'
	String get view_error_title => 'This view couldn\'t load';

	/// en-US: 'The rest of GodotHub still works. Try loading this view again, or switch to another one.'
	String get view_error_desc => 'The rest of GodotHub still works. Try loading this view again, or switch to another one.';

	/// en-US: 'Technical details'
	String get error_details => 'Technical details';

	/// en-US: 'Remove folder'
	String get remove_folder => 'Remove folder';

	/// en-US: 'Make this the {{label}}'
	String get make_this_default => 'Make this the {{label}}';

	/// en-US: 'Suggested from other workspaces'
	String get suggested_from_workspaces => 'Suggested from other workspaces';

	/// en-US: 'from {{name}}'
	String get from_workspace => 'from {{name}}';

	/// en-US: 'Add folder'
	String get add_folder => 'Add folder';

	/// en-US: 'Default'
	String get default_folder => 'Default';

	/// en-US: 'Default Downloads will go to "{{path}}"'
	String get default_downloads_go_to => 'Default Downloads will go to "{{path}}"';

	/// en-US: 'Open Terminal'
	String get open_terminal => 'Open Terminal';

	/// en-US: 'Downloading {{version}}'
	String get downloading_version => 'Downloading {{version}}';

	/// en-US: 'Downloading {{title}}'
	String get downloading_asset => 'Downloading {{title}}';

	/// en-US: 'Template download failed'
	String get asset_download_failed => 'Template download failed';

	/// en-US: 'Scan for Engines'
	String get scan_for_engines => 'Scan for Engines';

	/// en-US: 'Import Version'
	String get import_version => 'Import Version';

	/// en-US: 'Sync Templates from Directory'
	String get sync_templates_from_directory => 'Sync Templates from Directory';

	/// en-US: 'Navigation'
	String get section_navigation => 'Navigation';

	/// en-US: 'Projects'
	String get section_projects => 'Projects';

	/// en-US: 'Views'
	String get section_views => 'Views';

	/// en-US: 'Workspaces'
	String get section_workspaces => 'Workspaces';

	/// en-US: 'Help'
	String get section_help => 'Help';

	/// en-US: 'Engines'
	String get section_engines => 'Engines';

	/// en-US: 'Templates'
	String get section_templates => 'Templates';

	/// en-US: 'Versions'
	String get section_versions => 'Versions';

	/// en-US: 'News'
	String get section_news => 'News';

	/// en-US: 'Skip setup'
	String get skip_setup => 'Skip setup';

	/// en-US: 'Back'
	String get back => 'Back';

	/// en-US: 'Finishing…'
	String get finishing => 'Finishing…';

	/// en-US: 'Get Started'
	String get get_started => 'Get Started';

	/// en-US: 'Scanning…'
	String get scanning => 'Scanning…';

	/// en-US: 'Scan Now'
	String get scan_now => 'Scan Now';

	/// en-US: 'Scan complete'
	String get scan_complete => 'Scan complete';

	/// en-US: 'Scan failed'
	String get scan_failed => 'Scan failed';

	/// en-US: 'Uncategorized'
	String get uncategorized => 'Uncategorized';

	/// en-US: 'All'
	String get all => 'All';

	/// en-US: 'No Filter'
	String get no_filter => 'No Filter';

	/// en-US: 'This cannot be undone.'
	String get cannot_undo => 'This cannot be undone.';

	/// en-US: 'Deleting…'
	String get deleting => 'Deleting…';

	/// en-US: 'Open'
	String get open_project => 'Open';

	/// en-US: 'Play'
	String get play_project => 'Play';

	/// en-US: 'Play the game without opening editor'
	String get play_project_tooltip => 'Play the game without opening editor';

	/// en-US: 'No Version Selected'
	String get no_version_selected => 'No Version Selected';

	/// en-US: 'Open with Console'
	String get open_with_console => 'Open with Console';

	/// en-US: 'Open Folder'
	String get open_folder => 'Open Folder';

	/// en-US: 'Open in IDE'
	String get open_in_ide => 'Open in IDE';

	/// en-US: 'Category'
	String get category => 'Category';

	/// en-US: 'None'
	String get none => 'None';

	/// en-US: 'Project Size'
	String get project_size => 'Project Size';

	/// en-US: 'Scanning project files…'
	String get project_size_scanning => 'Scanning project files…';

	/// en-US: 'No files found'
	String get project_size_empty => 'No files found';

	/// en-US: 'Launch Arguments'
	String get launch_arguments => 'Launch Arguments';

	/// en-US: 'Save as Template'
	String get save_as_template => 'Save as Template';

	/// en-US: 'Git'
	String get git => 'Git';

	/// en-US: 'Add'
	String get add => 'Add';

	/// en-US: 'Color'
	String get color_label => 'Color';

	/// en-US: 'Icon'
	String get icon_label => 'Icon';

	/// en-US: 'Expand'
	String get expand => 'Expand';

	/// en-US: 'Collapse'
	String get collapse => 'Collapse';

	/// en-US: '(one) {${count} file} (other) {${count} files}'
	String file_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} file',
		other: '${count} files',
	);

	/// en-US: '{{count}} file'
	String get file_count_one => '{{count}} file';

	/// en-US: '{{count}} files'
	String get file_count_other => '{{count}} files';

	/// en-US: '(one) {${count} folder} (other) {${count} folders}'
	String folder_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} folder',
		other: '${count} folders',
	);

	/// en-US: '{{count}} folder'
	String get folder_count_one => '{{count}} folder';

	/// en-US: '{{count}} folders'
	String get folder_count_other => '{{count}} folders';

	/// en-US: 'This template is empty.'
	String get template_empty => 'This template is empty.';

	/// en-US: 'Categories'
	String get categories => 'Categories';

	/// en-US: 'Projects found in a category's folders are assigned to it automatically.'
	String get category_folders_hint => 'Projects found in a category\'s folders are assigned to it automatically.';

	/// en-US: 'Assign folder'
	String get assign_folder => 'Assign folder';

	/// en-US: 'Assign a folder to {{name}}'
	String get assign_folder_to_category => 'Assign a folder to {{name}}';

	/// en-US: 'Remove {{folder}} from this category'
	String get unassign_folder_aria => 'Remove {{folder}} from this category';

	/// en-US: 'New category name…'
	String get new_category_placeholder => 'New category name…';

	/// en-US: 'No categories yet, add one above.'
	String get no_categories_yet => 'No categories yet, add one above.';

	/// en-US: 'Edit {{name}}'
	String get edit_category => 'Edit {{name}}';

	/// en-US: 'Delete {{name}}'
	String get delete_category => 'Delete {{name}}';

	/// en-US: 'Delete category?'
	String get delete_category_title => 'Delete category?';

	/// en-US: '"{{name}}" will be removed. Projects filed under it move to Uncategorized, nothing on disk is touched.'
	String get delete_category_desc => '"{{name}}" will be removed. Projects filed under it move to Uncategorized, nothing on disk is touched.';

	/// en-US: 'Name'
	String get project_name_label => 'Name';

	/// en-US: 'Dir. Convention: {{name}}'
	String get folder_name_preview => 'Dir. Convention: {{name}}';

	/// en-US: 'Folder name is derived from the project name using your naming convention.'
	String get folder_name_hint => 'Folder name is derived from the project name using your naming convention.';

	/// en-US: 'Preview {{name}}'
	String get template_preview_aria => 'Preview {{name}}';

	/// en-US: 'Location'
	String get project_location_label => 'Location';

	/// en-US: 'Choose a folder'
	String get choose_folder_placeholder => 'Choose a folder';

	/// en-US: 'Browse'
	String get browse => 'Browse';

	/// en-US: 'Default'
	String get blank_template => 'Default';

	/// en-US: 'Template (optional)'
	String get template_optional => 'Template (optional)';

	/// en-US: 'Category (optional)'
	String get category_optional => 'Category (optional)';

	/// en-US: 'No category'
	String get no_category_label => 'No category';

	/// en-US: 'Godot Version'
	String get godot_version_label => 'Godot Version';

	/// en-US: 'No engine installed yet, grab one from the Versions tab first.'
	String get no_engine_warning => 'No engine installed yet, grab one from the Versions tab first.';

	/// en-US: 'Change'
	String get change_icon => 'Change';

	/// en-US: 'Choose'
	String get choose_icon => 'Choose';

	/// en-US: 'SVG, PNG, or JPG. Defaults to Godot logo.'
	String get icon_format_desc => 'SVG, PNG, or JPG. Defaults to Godot logo.';

	/// en-US: 'Other settings'
	String get other_settings_label => 'Other settings';

	/// en-US: 'Initialize Git repository'
	String get init_git_label => 'Initialize Git repository';

	/// en-US: 'Adds a Godot .gitignore and .gitattributes, then makes an initial commit on main.'
	String get init_git_desc => 'Adds a Godot .gitignore and .gitattributes, then makes an initial commit on main.';

	/// en-US: 'Install Git and restart GodotHub to use this.'
	String get init_git_unavailable => 'Install Git and restart GodotHub to use this.';

	/// en-US: 'Setting up Git…'
	String get initializing_git => 'Setting up Git…';

	/// en-US: 'Project created, Git needs attention'
	String get git_init_warning_title => 'Project created, Git needs attention';

	/// en-US: 'Godot .gitignore'
	String get git_option_gitignore => 'Godot .gitignore';

	/// en-US: '.gitattributes'
	String get git_option_gitattributes => '.gitattributes';

	/// en-US: 'README.md'
	String get git_option_readme => 'README.md';

	/// en-US: 'License'
	String get git_option_license => 'License';

	/// en-US: 'No license'
	String get git_option_no_license => 'No license';

	/// en-US: 'Create repository on GitHub/GitLab'
	String get create_remote_label => 'Create repository on GitHub/GitLab';

	/// en-US: 'Creates a repository on your connected account and pushes the initial commit.'
	String get create_remote_desc => 'Creates a repository on your connected account and pushes the initial commit.';

	/// en-US: 'Private'
	String get remote_private => 'Private';

	/// en-US: 'Public'
	String get remote_public => 'Public';

	/// en-US: 'Creating remote repository…'
	String get creating_remote_repo => 'Creating remote repository…';

	/// en-US: 'Remote repository created'
	String get remote_repo_created_title => 'Remote repository created';

	/// en-US: 'Done'
	String get create_project_done => 'Done';

	/// en-US: 'Create Project'
	String get create_project_btn => 'Create Project';

	/// en-US: 'Creating…'
	String get creating => 'Creating…';

	/// en-US: 'Give the project a name and a folder to create it in.'
	String get create_project_error => 'Give the project a name and a folder to create it in.';

	/// en-US: 'New Workspace'
	String get create_workspace_title => 'New Workspace';

	/// en-US: 'Name'
	String get workspace_name_label => 'Name';

	/// en-US: 'Work, Personal, Game Jam…'
	String get workspace_name_placeholder => 'Work, Personal, Game Jam…';

	/// en-US: 'Give the workspace a name.'
	String get workspace_name_required_error => 'Give the workspace a name.';

	/// en-US: 'Edit Workspace'
	String get edit_workspace_title => 'Edit Workspace';

	/// en-US: 'You can't delete your only workspace'
	String get cant_delete_only_workspace => 'You can\'t delete your only workspace';

	/// en-US: 'Delete workspace?'
	String get delete_workspace_title => 'Delete workspace?';

	/// en-US: '"{{name}}" and everything scoped to it (its settings, projects, and categories) will be removed. Project files on disk are never touched. Installed Godot versions are shared and stay untouched.'
	String get delete_workspace_desc => '"{{name}}" and everything scoped to it (its settings, projects, and categories) will be removed. Project files on disk are never touched. Installed Godot versions are shared and stay untouched.';

	/// en-US: 'Other'
	String get other => 'Other';

	/// en-US: 'Arguments'
	String get args_label => 'Arguments';

	/// en-US: 'e.g. --debug --single-window'
	String get args_placeholder => 'e.g. --debug --single-window';

	/// en-US: 'Suggestions'
	String get args_suggestions => 'Suggestions';

	/// en-US: 'Separate arguments with spaces. Flags with values like'
	String get args_desc_separate_prefix => 'Separate arguments with spaces. Flags with values like';

	/// en-US: 'use two tokens.'
	String get args_desc_separate_suffix => 'use two tokens.';

	/// en-US: '--debug'
	String get args_debug => '--debug';

	/// en-US: 'Run with debugger attached'
	String get args_debug_desc => 'Run with debugger attached';

	/// en-US: '--single-window'
	String get args_single_window => '--single-window';

	/// en-US: 'Force single window mode'
	String get args_single_window_desc => 'Force single window mode';

	/// en-US: '--rendering-driver opengl3'
	String get args_opengl3 => '--rendering-driver opengl3';

	/// en-US: 'Use OpenGL 3 rendering driver'
	String get args_opengl3_desc => 'Use OpenGL 3 rendering driver';

	/// en-US: '--rendering-driver vulkan'
	String get args_vulkan => '--rendering-driver vulkan';

	/// en-US: 'Use Vulkan rendering driver'
	String get args_vulkan_desc => 'Use Vulkan rendering driver';

	/// en-US: '--headless'
	String get args_headless => '--headless';

	/// en-US: 'Run without a window'
	String get args_headless_desc => 'Run without a window';

	/// en-US: '--verbose'
	String get args_verbose => '--verbose';

	/// en-US: 'Log detailed debug output'
	String get args_verbose_desc => 'Log detailed debug output';

	/// en-US: '--editor'
	String get args_editor => '--editor';

	/// en-US: 'Open the editor (same as -e)'
	String get args_editor_desc => 'Open the editor (same as -e)';

	/// en-US: '--build-solutions'
	String get args_build_solutions => '--build-solutions';

	/// en-US: 'Build C# solutions on open'
	String get args_build_solutions_desc => 'Build C# solutions on open';

	/// en-US: '--gpu-index 1'
	String get args_gpu_index => '--gpu-index 1';

	/// en-US: 'Use GPU index 1 (dedicated GPU)'
	String get args_gpu_index_desc => 'Use GPU index 1 (dedicated GPU)';

	/// en-US: 'Categories'
	String get sort_categories => 'Categories';

	/// en-US: 'Recently opened'
	String get sort_recent => 'Recently opened';

	/// en-US: 'Custom'
	String get sort_manual => 'Custom';

	/// en-US: 'Name (A–Z)'
	String get sort_name_asc => 'Name (A–Z)';

	/// en-US: 'Name (Z–A)'
	String get sort_name_desc => 'Name (Z–A)';

	/// en-US: 'Date added (newest)'
	String get sort_created_desc => 'Date added (newest)';

	/// en-US: 'Date added (oldest)'
	String get sort_created_asc => 'Date added (oldest)';

	/// en-US: 'Total time'
	String get sort_time_desc => 'Total time';

	/// en-US: 'Filter'
	String get filter => 'Filter';

	/// en-US: 'No templates yet. Right-click a project or open its "More" menu and select <1>Save as Template</1> to create one or download them from the Asset Library.'
	String get no_templates_yet => 'No templates yet. Right-click a project or open its "More" menu and select <1>Save as Template</1> to create one or download them from the Asset Library.';

	/// en-US: 'Godot'
	String get godot => 'Godot';

	/// en-US: 'Delete {{name}} template'
	String get delete_template => 'Delete {{name}} template';

	/// en-US: 'Latest posts from the official Godot Engine blog.'
	String get news_subtitle => 'Latest posts from the official Godot Engine blog.';

	/// en-US: 'Couldn't reach godotengine.org, showing the articles saved from last time.'
	String get news_cached => 'Couldn\'t reach godotengine.org, showing the articles saved from last time.';

	/// en-US: 'Couldn't load Godot news.'
	String get news_error => 'Couldn\'t load Godot news.';

	/// en-US: 'No news to show right now.'
	String get news_empty => 'No news to show right now.';

	/// en-US: 'Show more'
	String get show_more => 'Show more';

	/// en-US: 'Try again'
	String get try_again => 'Try again';

	/// en-US: 'ASSET STORE'
	String get asset_store_title => 'ASSET STORE';

	/// en-US: 'Posts'
	String get news_count => 'Posts';

	/// en-US: '(one) {Asset} (other) {Assets}'
	String asset_store_count_plural({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Asset',
		other: 'Assets',
	);

	/// en-US: 'Asset'
	String get asset_store_count_one => 'Asset';

	/// en-US: 'Assets'
	String get asset_store_count_other => 'Assets';

	/// en-US: 'Assets'
	String get asset_store_count => 'Assets';

	/// en-US: 'SETTINGS'
	String get settings_title => 'SETTINGS';

	/// en-US: 'No templates match'
	String get no_templates_match => 'No templates match';

	/// en-US: 'No projects match'
	String get no_projects_match => 'No projects match';

	/// en-US: 'More import options'
	String get more_import_options => 'More import options';

	/// en-US: 'Clone & Import from Repository'
	String get clone_import_repo => 'Clone & Import from Repository';

	/// en-US: 'Manage Categories'
	String get manage_categories => 'Manage Categories';

	/// en-US: 'Hide Category'
	String get hide_category => 'Hide Category';

	/// en-US: '"{{name}}" hidden. Restore it from Hidden Categories.'
	String get category_hidden_toast => '"{{name}}" hidden. Restore it from Hidden Categories.';

	/// en-US: 'Hidden Categories'
	String get hidden_categories => 'Hidden Categories';

	/// en-US: 'Those categories and their projects stay out of the way. Unhide one to bring it back.'
	String get hidden_categories_hint => 'Those categories and their projects stay out of the way. Unhide one to bring it back.';

	/// en-US: '{{count}} project(s)'
	String get hidden_category_projects => '{{count}} project(s)';

	/// en-US: 'Unhide'
	String get unhide => 'Unhide';

	/// en-US: 'Unhide {{name}}'
	String get unhide_category_aria => 'Unhide {{name}}';

	/// en-US: 'Search projects...'
	String get search_projects_placeholder => 'Search projects...';

	/// en-US: 'Clear search'
	String get clear_search => 'Clear search';

	/// en-US: 'Filter projects by'
	String get search_filter_title => 'Filter projects by';

	/// en-US: 'Type / to filter by name, tags, categories and more'
	String get search_slash_hint => 'Type / to filter by name, tags, categories and more';

	/// en-US: 'Name'
	String get search_filter_name => 'Name';

	/// en-US: 'Tag'
	String get search_filter_tag => 'Tag';

	/// en-US: 'Engine version'
	String get search_filter_version => 'Engine version';

	/// en-US: 'Path'
	String get search_filter_path => 'Path';

	/// en-US: 'Pinned only'
	String get search_filter_pinned_yes => 'Pinned only';

	/// en-US: 'Not pinned'
	String get search_filter_pinned_no => 'Not pinned';

	/// en-US: 'No matching filters'
	String get search_filter_no_matches => 'No matching filters';

	/// en-US: 'No matching values'
	String get search_filter_no_values => 'No matching values';

	/// en-US: 'Sort'
	String get sort => 'Sort';

	/// en-US: 'List'
	String get view_list => 'List';

	/// en-US: 'Grid'
	String get view_grid => 'Grid';

	/// en-US: 'Kanban'
	String get view_kanban => 'Kanban';

	/// en-US: 'Nothing here yet. Create a new project or import one you already have on disk.'
	String get no_projects_yet => 'Nothing here yet. Create a new project or import one you already have on disk.';

	/// en-US: 'Pinned'
	String get pinned_section => 'Pinned';

	/// en-US: 'Set category…'
	String get set_category => 'Set category…';

	/// en-US: 'Clear selection'
	String get clear_selection => 'Clear selection';

	/// en-US: 'Starting…'
	String get starting => 'Starting…';

	/// en-US: 'Loading…'
	String get app_loading => 'Loading…';

	/// en-US: 'Version'
	String get changelog_version_label => 'Version';

	/// en-US: 'v1.0.0'
	String get changelog_version_placeholder => 'v1.0.0';

	/// en-US: 'Date'
	String get changelog_date_label => 'Date';

	/// en-US: '2026-07-13'
	String get changelog_date_placeholder => '2026-07-13';

	/// en-US: 'What changed'
	String get changelog_what_changed => 'What changed';

	/// en-US: 'Add line'
	String get changelog_add_line => 'Add line';

	/// en-US: 'Remove line'
	String get changelog_remove_line_aria => 'Remove line';

	/// en-US: 'Added drag-and-drop project reordering'
	String get changelog_placeholder_note => 'Added drag-and-drop project reordering';

	/// en-US: 'Give the entry a version.'
	String get changelog_error_no_version => 'Give the entry a version.';

	/// en-US: 'Known Issues'
	String get changelog_known_issues => 'Known Issues';

	/// en-US: 'No known issues for this version.'
	String get changelog_known_issues_none => 'No known issues for this version.';

	/// en-US: 'Describe the known issue...'
	String get changelog_known_issue_placeholder => 'Describe the known issue...';

	/// en-US: 'Remove known issue'
	String get changelog_remove_known_issue_aria => 'Remove known issue';

	/// en-US: 'Add known issue'
	String get changelog_add_known_issue => 'Add known issue';

	/// en-US: 'Generate from Git'
	String get changelog_generate_from_git => 'Generate from Git';

	/// en-US: 'Release notes from Git'
	String get changelog_draft_title => 'Release notes from Git';

	/// en-US: 'From'
	String get changelog_draft_from => 'From';

	/// en-US: 'To'
	String get changelog_draft_to => 'To';

	/// en-US: 'Generate draft'
	String get changelog_draft_generate => 'Generate draft';

	/// en-US: 'Use Draft'
	String get changelog_draft_use => 'Use Draft';

	/// en-US: '{{count}} commit(s)'
	String get changelog_draft_commits => '{{count}} commit(s)';

	/// en-US: 'Include in draft'
	String get changelog_draft_include => 'Include in draft';

	/// en-US: 'No commits found in this range.'
	String get changelog_draft_none => 'No commits found in this range.';

	/// en-US: 'Search templates…'
	String get template_search_placeholder => 'Search templates…';

	/// en-US: 'Delete Template?'
	String get template_delete_title => 'Delete Template?';

	/// en-US: '"{{name}}" will be permanently removed.'
	String get template_delete_desc => '"{{name}}" will be permanently removed.';

	/// en-US: 'Local Templates'
	String get templates_tab_local => 'Local Templates';

	/// en-US: 'Asset Library'
	String get templates_tab_asset => 'Asset Library';

	/// en-US: 'Search assets…'
	String get asset_search_placeholder => 'Search assets…';

	/// en-US: 'All versions'
	String get asset_all_versions => 'All versions';

	/// en-US: '{{count}} results'
	String get asset_result_count => '{{count}} results';

	/// en-US: 'Couldn't load the Asset Library. Check your connection and try again.'
	String get asset_load_error => 'Couldn\'t load the Asset Library. Check your connection and try again.';

	/// en-US: 'No assets found. Try a different search.'
	String get asset_no_results => 'No assets found. Try a different search.';

	/// en-US: 'by {{author}}'
	String get asset_by_author => 'by {{author}}';

	/// en-US: 'Open in browser'
	String get asset_open_page => 'Open in browser';

	/// en-US: 'Install'
	String get asset_install => 'Install';

	/// en-US: 'Install Inside'
	String get asset_install_inside => 'Install Inside';

	/// en-US: 'Installing…'
	String get asset_installing => 'Installing…';

	/// en-US: 'Installed'
	String get asset_installed => 'Installed';

	/// en-US: 'Previous page'
	String get asset_prev_page => 'Previous page';

	/// en-US: 'Next page'
	String get asset_next_page => 'Next page';

	/// en-US: 'Page {{page}} of {{total}}'
	String get asset_page_x_of_y => 'Page {{page}} of {{total}}';

	/// en-US: '(one) {Template} (other) {Templates}'
	String template_your_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Template',
		other: 'Templates',
	);

	/// en-US: 'Template'
	String get template_your_templates_one => 'Template';

	/// en-US: 'Templates'
	String get template_your_templates_other => 'Templates';

	/// en-US: 'Imported {{count}}'
	String get template_imported_count => 'Imported {{count}}';

	/// en-US: 'Updated {{count}}'
	String get template_updated_count => 'Updated {{count}}';

	/// en-US: 'Removed {{count}}'
	String get template_removed_count => 'Removed {{count}}';

	/// en-US: 'All sources'
	String get asset_source_all => 'All sources';

	/// en-US: 'Old Asset Library'
	String get asset_source_library => 'Old Asset Library';

	/// en-US: 'New Asset Store'
	String get asset_source_store => 'New Asset Store';

	/// en-US: 'Relevance'
	String get asset_store_relevance => 'Relevance';

	/// en-US: 'Newest updated'
	String get asset_store_updated_new => 'Newest updated';

	/// en-US: 'Oldest updated'
	String get asset_store_updated_old => 'Oldest updated';

	/// en-US: 'Top rated'
	String get asset_store_rating_high => 'Top rated';

	/// en-US: 'Lowest rated'
	String get asset_store_rating_low => 'Lowest rated';

	/// en-US: 'Download Outside'
	String get asset_download_outside => 'Download Outside';

	/// en-US: 'Downloaded'
	String get asset_downloaded => 'Downloaded';

	/// en-US: 'Downloaded to'
	String get asset_downloaded_to => 'Downloaded to';

	/// en-US: 'Couldn't download the asset. Check your connection and try again.'
	String get asset_download_error => 'Couldn\'t download the asset. Check your connection and try again.';

	/// en-US: 'Install {{title}}'
	String get asset_install_modal_title => 'Install {{title}}';

	/// en-US: 'Into project'
	String get asset_install_tab_project => 'Into project';

	/// en-US: 'Into template'
	String get asset_install_tab_template => 'Into template';

	/// en-US: 'Search projects…'
	String get asset_install_search_projects => 'Search projects…';

	/// en-US: 'No projects yet. Create or import one first.'
	String get asset_install_no_projects => 'No projects yet. Create or import one first.';

	/// en-US: 'No templates saved yet.'
	String get asset_install_no_templates => 'No templates saved yet.';

	/// en-US: 'Install into {{name}}'
	String get asset_install_into => 'Install into {{name}}';

	/// en-US: 'Installed into {{target}}'
	String get asset_install_success_project => 'Installed into {{target}}';

	/// en-US: 'Added to template {{target}}'
	String get asset_install_success_template => 'Added to template {{target}}';

	/// en-US: 'Save as new template'
	String get asset_new_template_btn => 'Save as new template';

	/// en-US: 'Creates a new template from this project asset'
	String get asset_new_template_hint => 'Creates a new template from this project asset';

	/// en-US: 'Keep every project organized in one place.'
	String get onboarding_keep_organized => 'Keep every project organized in one place.';

	/// en-US: 'Download and manage Godot engine builds.'
	String get onboarding_download_manage => 'Download and manage Godot engine builds.';

	/// en-US: 'Stay current with what's new in Godot.'
	String get onboarding_stay_current => 'Stay current with what\'s new in Godot.';

	/// en-US: 'Where are your projects?'
	String get onboarding_projects_title => 'Where are your projects?';

	/// en-US: 'Add folders GodotHub should scan for existing Godot projects at startup. Star one to make it the default save location when you create a new project. You can skip this and add folders later in Settings.'
	String get onboarding_projects_desc => 'Add folders GodotHub should scan for existing Godot projects at startup. Star one to make it the default save location when you create a new project. You can skip this and add folders later in Settings.';

	/// en-US: 'Where do Godot versions live?'
	String get onboarding_versions_title => 'Where do Godot versions live?';

	/// en-US: 'Add folders GodotHub should scan for installed Godot engine executables. Star one to set it as the download location for new versions you install through the Versions tab.'
	String get onboarding_versions_desc => 'Add folders GodotHub should scan for installed Godot engine executables. Star one to set it as the download location for new versions you install through the Versions tab.';

	/// en-US: 'Template projects directory'
	String get onboarding_templates_title => 'Template projects directory';

	/// en-US: 'Optionally set a folder where you keep reusable project templates. Any subfolder inside it will be imported as templates on finish, so they show up when you create new projects. You can also save individual projects as templates anytime from the Projects view, or import more later from the Templates tab.'
	String get onboarding_templates_desc => 'Optionally set a folder where you keep reusable project templates. Any subfolder inside it will be imported as templates on finish, so they show up when you create new projects. You can also save individual projects as templates anytime from the Projects view, or import more later from the Templates tab.';

	/// en-US: 'Organize with categories'
	String get onboarding_categories_title => 'Organize with categories';

	/// en-US: 'Categories are folders for your project list, file projects under them however makes sense to you. Add a few starters or make your own; you can rename, reorder, or delete these anytime from Settings.'
	String get onboarding_categories_desc_full => 'Categories are folders for your project list, file projects under them however makes sense to you. Add a few starters or make your own; you can rename, reorder, or delete these anytime from Settings.';

	/// en-US: 'Custom category name…'
	String get onboarding_custom_category_placeholder => 'Custom category name…';

	/// en-US: 'Your categories'
	String get onboarding_your_categories => 'Your categories';

	/// en-US: 'Make it yours'
	String get onboarding_customize_title => 'Make it yours';

	/// en-US: 'Pick a full theme preset, or choose Custom and set your own accent and background. Corner roundness, density, text size, and light/dark mode are all in Settings whenever you want to fine-tune further.'
	String get onboarding_customize_desc => 'Pick a full theme preset, or choose Custom and set your own accent and background. Corner roundness, density, text size, and light/dark mode are all in Settings whenever you want to fine-tune further.';

	/// en-US: 'You're all set'
	String get onboarding_finish_title => 'You\'re all set';

	/// en-US: 'GodotHub is ready to go. You can revisit any of this, folders, categories, and appearance, from the Settings tab at any time.'
	String get onboarding_finish_desc => 'GodotHub is ready to go. You can revisit any of this, folders, categories, and appearance, from the Settings tab at any time.';

	/// en-US: 'Setting things up'
	String get onboarding_setting_up_title => 'Setting things up';

	/// en-US: 'Setting up your library… scanning folders for projects and Godot versions. This only happens once, and it won't take long.'
	String get onboarding_setting_up_desc => 'Setting up your library… scanning folders for projects and Godot versions. This only happens once, and it won\'t take long.';

	/// en-US: 'Skipped'
	String get skipped => 'Skipped';

	/// en-US: 'Continue'
	String get onboarding_continue => 'Continue';

	/// en-US: 'Accent color'
	String get onboarding_accent_color => 'Accent color';

	/// en-US: 'Background color'
	String get onboarding_bg_color => 'Background color';

	/// en-US: 'Corner radius'
	String get onboarding_corner_radius => 'Corner radius';

	/// en-US: 'Discord Rich Presence'
	String get onboarding_discord_rpc => 'Discord Rich Presence';

	/// en-US: 'Show what you're doing in GodotHub on your Discord profile.'
	String get onboarding_discord_rpc_desc => 'Show what you\'re doing in GodotHub on your Discord profile.';

	/// en-US: 'Search versions…'
	String get version_search_placeholder => 'Search versions…';

	/// en-US: 'No versions installed. Download a version from below or drag and drop your existing version folder here.'
	String get version_no_installed => 'No versions installed. Download a version from below or drag and drop your existing version folder here.';

	/// en-US: 'Save name'
	String get version_save_name_aria => 'Save name';

	/// en-US: 'Rename version'
	String get version_rename_aria => 'Rename version';

	/// en-US: '.NET'
	String get version_mono_badge => '.NET';

	/// en-US: 'Uninstall version?'
	String get version_uninstall_title => 'Uninstall version?';

	/// en-US: '"{{tag}}" and its files will be moved to your system's Trash / Recycle Bin. You can reinstall it later if needed.'
	String get version_uninstall_desc => '"{{tag}}" and its files will be moved to your system\'s Trash / Recycle Bin. You can reinstall it later if needed.';

	/// en-US: 'Uninstall'
	String get version_uninstall_confirm => 'Uninstall';

	/// en-US: 'Remove from library?'
	String get project_remove_title => 'Remove from library?';

	/// en-US: '"{{name}}" will be removed from GodotHub's list. Its files stay on disk untouched, you can import it again anytime.'
	String get project_remove_desc => '"{{name}}" will be removed from GodotHub\'s list. Its files stay on disk untouched, you can import it again anytime.';

	/// en-US: 'Move to Trash?'
	String get project_delete_title => 'Move to Trash?';

	/// en-US: '"{{name}}" and everything inside it will be moved to your system's Trash / Recycle Bin. You can restore it later if needed.'
	String get project_delete_desc => '"{{name}}" and everything inside it will be moved to your system\'s Trash / Recycle Bin. You can restore it later if needed.';

	/// en-US: 'Move to Trash'
	String get project_delete_confirm => 'Move to Trash';

	/// en-US: 'Template Name'
	String get project_template_name_label => 'Template Name';

	/// en-US: 'Description'
	String get project_template_desc_label => 'Description';

	/// en-US: 'What's in this template?'
	String get project_template_desc_placeholder => 'What\'s in this template?';

	/// en-US: 'Save Template'
	String get project_save_template_btn => 'Save Template';

	/// en-US: 'Template saved.'
	String get template_saved_toast => 'Template saved.';

	/// en-US: 'Select project'
	String get project_select_aria => 'Select project';

	/// en-US: 'Deselect project'
	String get project_deselect_aria => 'Deselect project';

	/// en-US: 'Select all visible'
	String get select_all_visible => 'Select all visible';

	/// en-US: '{{count}} selected'
	String get selected_count => '{{count}} selected';

	/// en-US: 'Launch'
	String get bulk_launch => 'Launch';

	/// en-US: 'Pin'
	String get bulk_pin => 'Pin';

	/// en-US: 'Remove'
	String get bulk_remove => 'Remove';

	/// en-US: 'Remove {{count}} projects from library?'
	String get bulk_remove_title => 'Remove {{count}} projects from library?';

	/// en-US: 'The selected projects will be removed from your library. Their files will stay on disk.'
	String get bulk_remove_desc => 'The selected projects will be removed from your library. Their files will stay on disk.';

	/// en-US: 'Delete {{count}} projects?'
	String get bulk_delete_title => 'Delete {{count}} projects?';

	/// en-US: 'The selected project files will be permanently moved to the Trash. This cannot be undone.'
	String get bulk_delete_desc => 'The selected project files will be permanently moved to the Trash. This cannot be undone.';

	/// en-US: 'Pin project'
	String get project_pin_aria => 'Pin project';

	/// en-US: 'Unpin project'
	String get project_unpin_aria => 'Unpin project';

	/// en-US: 'Today'
	String get time_today => 'Today';

	/// en-US: 'This week'
	String get time_this_week => 'This week';

	/// en-US: 'All time'
	String get time_all_time => 'All time';

	/// en-US: 'Time tracked'
	String get time_tracked_title => 'Time tracked';

	/// en-US: 'Last 7 days'
	String get time_weekly_chart => 'Last 7 days';

	/// en-US: '{{total}} this week'
	String get time_week_total => '{{total}} this week';

	/// en-US: 'No tracked time in the last 7 days.'
	String get time_weekly_empty => 'No tracked time in the last 7 days.';

	/// en-US: 'More actions'
	String get project_more_aria => 'More actions';

	/// en-US: 'Project Card'
	String get customize_card_section => 'Project Card';

	/// en-US: 'Show Project Size'
	String get customize_card_show_size => 'Show Project Size';

	/// en-US: 'Show Time Tracked'
	String get customize_card_show_time => 'Show Time Tracked';

	/// en-US: 'Show Session Timer'
	String get customize_card_show_session_timer => 'Show Session Timer';

	/// en-US: 'Blur Project Directory'
	String get customize_card_blur_path => 'Blur Project Directory';

	/// en-US: 'Show Project Directory'
	String get customize_card_show_path => 'Show Project Directory';

	/// en-US: 'Show Tags'
	String get customize_card_show_tags => 'Show Tags';

	/// en-US: 'Show Last Opened'
	String get customize_card_show_last_opened => 'Show Last Opened';

	/// en-US: 'Show Play Button'
	String get customize_card_show_play => 'Show Play Button';

	/// en-US: 'Show Open with Console'
	String get customize_card_show_console => 'Show Open with Console';

	/// en-US: 'Remove from Library'
	String get project_card_remove_library => 'Remove from Library';

	/// en-US: 'Delete Files'
	String get project_card_delete_files => 'Delete Files';

	/// en-US: 'Manage Tags'
	String get manage_tags => 'Manage Tags';

	/// en-US: 'New tag name…'
	String get tag_input_placeholder => 'New tag name…';

	/// en-US: 'A tag with this name already exists.'
	String get tag_already_exists => 'A tag with this name already exists.';

	/// en-US: 'Click to rename'
	String get tag_rename_hint => 'Click to rename';

	/// en-US: 'Rename tag'
	String get tag_rename_aria => 'Rename tag';

	/// en-US: 'Show more tags'
	String get show_more_tags => 'Show more tags';

	/// en-US: 'Show fewer tags'
	String get show_fewer_tags => 'Show fewer tags';

	/// en-US: 'Clear tag filter'
	String get clear_tag_filter => 'Clear tag filter';

	/// en-US: 'Saving tags…'
	String get saving_tags => 'Saving tags…';

	/// en-US: '(one) {${count} tag} (other) {${count} tags}'
	String tag_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} tag',
		other: '${count} tags',
	);

	/// en-US: '{{count}} tag'
	String get tag_count_one => '{{count}} tag';

	/// en-US: '{{count}} tags'
	String get tag_count_other => '{{count}} tags';

	/// en-US: 'No tags yet'
	String get no_tags => 'No tags yet';

	/// en-US: 'What happened?'
	String get bug_report_describe_label => 'What happened?';

	/// en-US: 'What were you doing when the bug appeared? Add steps to reproduce and what you expected vs. what actually happened.'
	String get bug_report_describe_placeholder => 'What were you doing when the bug appeared? Add steps to reproduce and what you expected vs. what actually happened.';

	/// en-US: 'Diagnostic info'
	String get bug_report_diagnostics_label => 'Diagnostic info';

	/// en-US: 'Auto-collected · included in the report'
	String get bug_report_diagnostics_hint => 'Auto-collected · included in the report';

	/// en-US: 'Copied!'
	String get bug_report_copied => 'Copied!';

	/// en-US: 'Copy Report'
	String get bug_report_copy_log => 'Copy Report';

	/// en-US: 'Download Report'
	String get bug_report_download_log => 'Download Report';

	/// en-US: 'Create GitHub Issue'
	String get bug_report_open_github => 'Create GitHub Issue';

	/// en-US: 'Check for Updates'
	String get check_updates_title_modal => 'Check for Updates';

	/// en-US: 'Version {{version}} available'
	String get check_updates_version_available => 'Version {{version}} available';

	/// en-US: 'Would you like to download and install it now?'
	String get check_updates_ask_download => 'Would you like to download and install it now?';

	/// en-US: 'Release Notes'
	String get check_updates_release_notes => 'Release Notes';

	/// en-US: 'Update check failed'
	String get check_updates_failed => 'Update check failed';

	/// en-US: 'GitHub rate limit reached'
	String get check_updates_rate_limited => 'GitHub rate limit reached';

	/// en-US: 'GitHub token rejected'
	String get check_updates_token_rejected => 'GitHub token rejected';

	/// en-US: 'GitHub only allows 60 anonymous requests per hour, shared with everyone on your network. Adding a personal access token in Settings raises this to 5,000 per hour and is also used for fetching Godot versions.'
	String get check_updates_rate_limited_hint => 'GitHub only allows 60 anonymous requests per hour, shared with everyone on your network. Adding a personal access token in Settings raises this to 5,000 per hour and is also used for fetching Godot versions.';

	/// en-US: 'Your saved GitHub token was rejected. It may have expired or been revoked. Test it in Settings and replace it if needed.'
	String get check_updates_rate_limited_token_hint => 'Your saved GitHub token was rejected. It may have expired or been revoked. Test it in Settings and replace it if needed.';

	/// en-US: 'Add GitHub Token'
	String get check_updates_add_token => 'Add GitHub Token';

	/// en-US: 'Open Token Settings'
	String get check_updates_open_token_settings => 'Open Token Settings';

	/// en-US: 'Manual update required'
	String get check_updates_portable_title => 'Manual update required';

	/// en-US: 'Portable installs cannot auto-update. Download the latest version from GitHub and replace the existing files.'
	String get check_updates_portable_desc => 'Portable installs cannot auto-update. Download the latest version from GitHub and replace the existing files.';

	/// en-US: 'Download from GitHub'
	String get check_updates_download_from_github => 'Download from GitHub';

	/// en-US: 'Update details'
	String get check_updates_details => 'Update details';

	/// en-US: 'Log'
	String get check_updates_log => 'Log';

	/// en-US: 'Released'
	String get check_updates_released => 'Released';

	/// en-US: 'Source'
	String get check_updates_source => 'Source';

	/// en-US: 'File'
	String get check_updates_file => 'File';

	/// en-US: 'Package'
	String get check_updates_package => 'Package';

	/// en-US: 'Signature'
	String get check_updates_signature => 'Signature';

	/// en-US: 'Checked with minisign before installing'
	String get check_updates_signature_checked => 'Checked with minisign before installing';

	/// en-US: 'View release on GitHub'
	String get check_updates_view_release => 'View release on GitHub';

	/// en-US: '{{downloaded}} of {{total}}'
	String get check_updates_progress_size => '{{downloaded}} of {{total}}';

	/// en-US: '{{speed}}/s'
	String get check_updates_speed => '{{speed}}/s';

	/// en-US: 'About {{time}} left'
	String get check_updates_time_left => 'About {{time}} left';

	/// en-US: 'From {{host}}'
	String get check_updates_from_host => 'From {{host}}';

	/// en-US: 'Downloaded {{size}} in {{time}}'
	String get check_updates_download_summary => 'Downloaded {{size}} in {{time}}';

	/// en-US: 'Signature verified'
	String get check_updates_signature_verified => 'Signature verified';

	/// en-US: 'Clone Repository'
	String get clone_repo_title => 'Clone Repository';

	/// en-US: 'Repository URL'
	String get clone_repo_url_label => 'Repository URL';

	/// en-US: 'https://github.com/user/my-game.git'
	String get clone_repo_url_placeholder => 'https://github.com/user/my-game.git';

	/// en-US: 'Please enter a repository URL.'
	String get clone_repo_error_url => 'Please enter a repository URL.';

	/// en-US: 'Please choose where to clone the repository.'
	String get clone_repo_error_location => 'Please choose where to clone the repository.';

	/// en-US: 'Open it right after importing'
	String get clone_repo_open_after => 'Open it right after importing';

	/// en-US: 'Browse Your Repos'
	String get clone_repo_browse_repos => 'Browse Your Repos';

	/// en-US: 'Paste URL Manually'
	String get clone_repo_url_manual => 'Paste URL Manually';

	/// en-US: 'Search your repositories...'
	String get clone_repo_search_repos => 'Search your repositories...';

	/// en-US: 'No repositories match your search.'
	String get clone_repo_no_repos_found => 'No repositories match your search.';

	/// en-US: 'Loading repositories...'
	String get clone_repo_loading_repos => 'Loading repositories...';

	/// en-US: 'Failed to load repositories.'
	String get clone_repo_load_error => 'Failed to load repositories.';

	/// en-US: 'Select'
	String get clone_repo_select => 'Select';

	/// en-US: 'No GitHub or GitLab account connected. Use a URL to clone instead.'
	String get clone_repo_no_account => 'No GitHub or GitLab account connected. Use a URL to clone instead.';

	/// en-US: 'repos loaded'
	String get clone_repo_repos_loaded => 'repos loaded';

	/// en-US: 'Load more'
	String get load_more => 'Load more';

	/// en-US: 'uncommitted'
	String get git_uncommitted => 'uncommitted';

	/// en-US: 'clean'
	String get git_clean => 'clean';

	/// en-US: 'Tasks'
	String get task_tray_title => 'Tasks';

	/// en-US: 'No active tasks'
	String get task_tray_empty => 'No active tasks';

	/// en-US: '{{active}} active, {{recent}} recent'
	String get task_tray_active_count => '{{active}} active, {{recent}} recent';

	/// en-US: '(one) {${count} recent task} (other) {${count} recent tasks}'
	String task_tray_only_recent({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} recent task',
		other: '${count} recent tasks',
	);

	/// en-US: '{{count}} recent task'
	String get task_tray_only_recent_one => '{{count}} recent task';

	/// en-US: '{{count}} recent tasks'
	String get task_tray_only_recent_other => '{{count}} recent tasks';

	/// en-US: 'Task Tray'
	String get task_tray_aria => 'Task Tray';

	/// en-US: 'Completed auto-dismiss'
	String get task_tray_auto_dismiss => 'Completed auto-dismiss';

	/// en-US: 'Dismiss {{count}}'
	String get task_tray_dismiss => 'Dismiss {{count}}';

	/// en-US: 'Error'
	String get task_error_status => 'Error';

	/// en-US: 'Command Palette'
	String get command_palette_title => 'Command Palette';

	/// en-US: 'Search commands, projects, engines, settings…'
	String get command_palette_placeholder => 'Search commands, projects, engines, settings…';

	/// en-US: 'No results match'
	String get command_palette_no_results => 'No results match';

	/// en-US: 'Navigate'
	String get command_palette_navigate => 'Navigate';

	/// en-US: 'Esc'
	String get command_palette_escape => 'Esc';

	/// en-US: 'ghp_xxxxxxxxxxxxxxxxxxxx'
	String get setting_token_placeholder => 'ghp_xxxxxxxxxxxxxxxxxxxx';

	/// en-US: 'Scan Project Folders'
	String get setting_project_scan_dirs => 'Scan Project Folders';

	/// en-US: 'Scan Version Folders'
	String get setting_version_scan_dirs => 'Scan Version Folders';

	/// en-US: 'Default Project Location Setting'
	String get setting_default_project_location => 'Default Project Location Setting';

	/// en-US: 'Download Versions Location Setting'
	String get setting_download_dir => 'Download Versions Location Setting';

	/// en-US: 'Scan Depth'
	String get setting_scan_depth => 'Scan Depth';

	/// en-US: 'Project Icon Search Depth'
	String get setting_icon_scan_depth => 'Project Icon Search Depth';

	/// en-US: 'Simultaneous Downloads'
	String get setting_download_concurrency => 'Simultaneous Downloads';

	/// en-US: 'Close on Project Open'
	String get setting_close_on_project_open => 'Close on Project Open';

	/// en-US: 'Minimize to System Tray'
	String get setting_minimize_to_tray => 'Minimize to System Tray';

	/// en-US: 'Reopen After Godot Closes'
	String get setting_reopen_after_godot_closes => 'Reopen After Godot Closes';

	/// en-US: 'Auto-scan on Startup'
	String get setting_auto_scan_on_startup => 'Auto-scan on Startup';

	/// en-US: 'Use Workspaces'
	String get setting_workspaces_enabled => 'Use Workspaces';

	/// en-US: 'Directory Naming Convention'
	String get setting_directory_naming_convention => 'Directory Naming Convention';

	/// en-US: 'Initialize Git for New Projects'
	String get setting_git_init_new_projects => 'Initialize Git for New Projects';

	/// en-US: 'Tooltip Delay'
	String get setting_tooltip_delay => 'Tooltip Delay';

	/// en-US: 'Command Palette Shortcut'
	String get setting_command_palette_keybind => 'Command Palette Shortcut';

	/// en-US: 'Tray Recent Projects'
	String get setting_tray_recent_projects_count => 'Tray Recent Projects';

	/// en-US: 'Time Format'
	String get setting_last_opened_time_format => 'Time Format';

	/// en-US: 'Date Format'
	String get setting_last_opened_date_format => 'Date Format';

	/// en-US: 'Theme Mode'
	String get setting_theme_mode => 'Theme Mode';

	/// en-US: 'Accent Color'
	String get setting_accent_color => 'Accent Color';

	/// en-US: 'Background Color'
	String get setting_background_color => 'Background Color';

	/// en-US: 'Corner Radius'
	String get setting_corner_radius => 'Corner Radius';

	/// en-US: 'UI Density'
	String get setting_ui_density => 'UI Density';

	/// en-US: 'Text Size'
	String get setting_font_scale => 'Text Size';

	/// en-US: 'Animation Intensity'
	String get setting_animation_intensity => 'Animation Intensity';

	/// en-US: 'View Entrance Animation'
	String get setting_view_entrance => 'View Entrance Animation';

	/// en-US: 'Custom CSS'
	String get setting_custom_css => 'Custom CSS';

	/// en-US: 'Project Icon Opacity'
	String get setting_project_icon_opacity => 'Project Icon Opacity';

	/// en-US: 'Show Scrollbar'
	String get setting_show_scrollbars => 'Show Scrollbar';

	/// en-US: 'Setup Wizard'
	String get setting_setup_wizard => 'Setup Wizard';

	/// en-US: 'Reset Settings'
	String get setting_reset_settings => 'Reset Settings';

	/// en-US: 'Delete App Data'
	String get setting_delete_app_data => 'Delete App Data';

	/// en-US: 'Check for Updates'
	String get setting_check_updates => 'Check for Updates';

	/// en-US: 'Show Support Button'
	String get setting_show_support_button => 'Show Support Button';

	/// en-US: 'Show Star Button'
	String get setting_show_star_button => 'Show Star Button';

	/// en-US: 'Discord Rich Presence'
	String get setting_discord_rpc_enabled => 'Discord Rich Presence';

	/// en-US: 'Discord Application ID'
	String get setting_discord_app_id => 'Discord Application ID';

	/// en-US: 'Discord Show Project Names'
	String get setting_discord_rpc_show_projects => 'Discord Show Project Names';

	/// en-US: 'Discord Excluded Projects'
	String get setting_discord_rpc_excluded_projects => 'Discord Excluded Projects';

	/// en-US: 'Discord Custom Presence'
	String get setting_discord_rpc_project_presences => 'Discord Custom Presence';

	/// en-US: '{{name}} (active)'
	String get active_workspace => '{{name}} (active)';

	/// en-US: 'Current workspace'
	String get current_workspace => 'Current workspace';

	/// en-US: 'Switch workspace'
	String get switch_workspace => 'Switch workspace';

	/// en-US: 'Opened {{label}}'
	String get opened_recently => 'Opened {{label}}';

	/// en-US: 'Recent'
	String get recent_section => 'Recent';

	/// en-US: 'Installed Versions'
	String get installed_versions_section => 'Installed Versions';

	/// en-US: 'Settings → {{tab}}'
	String get settings_label => 'Settings → {{tab}}';

	/// en-US: 'Remove {{name}}'
	String get remove_category_aria => 'Remove {{name}}';

	/// en-US: 'Remove remote'
	String get git_remove_remote => 'Remove remote';

	/// en-US: 'Commit message…'
	String get git_commit_placeholder => 'Commit message…';

	/// en-US: 'Restart required'
	String get restart_required_title => 'Restart required';

	/// en-US: 'This change requires GodotHub to restart to take full effect. The setting has been saved and will apply when you relaunch the app.'
	String get restart_required_desc => 'This change requires GodotHub to restart to take full effect. The setting has been saved and will apply when you relaunch the app.';

	/// en-US: '(one) {Previously removed project found} (other) {${count} previously removed projects found}'
	String found_dismissed_title({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Previously removed project found',
		other: '${count} previously removed projects found',
	);

	/// en-US: 'Previously removed project found'
	String get found_dismissed_title_one => 'Previously removed project found';

	/// en-US: '{{count}} previously removed projects found'
	String get found_dismissed_title_other => '{{count}} previously removed projects found';

	/// en-US: '(one) {Scanner found 1 project that you previously removed from the library. Would you like to re-add it?} (other) {Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?}'
	String found_dismissed_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Scanner found 1 project that you previously removed from the library. Would you like to re-add it?',
		other: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
	);

	/// en-US: 'Scanner found 1 project that you previously removed from the library. Would you like to re-add it?'
	String get found_dismissed_desc_one => 'Scanner found 1 project that you previously removed from the library. Would you like to re-add it?';

	/// en-US: 'Scanner found {{count}} projects that you previously removed from the library. Would you like to re-add them?'
	String get found_dismissed_desc_other => 'Scanner found {{count}} projects that you previously removed from the library. Would you like to re-add them?';

	/// en-US: 'Re-add All'
	String get readd_all => 'Re-add All';

	/// en-US: 'Skip All'
	String get skip_all => 'Skip All';

	/// en-US: 'Project already open'
	String get project_already_open_title => 'Project already open';

	/// en-US: '{{name}} is already running. Opening it again launches a second editor instance. Open anyway?'
	String get project_already_open_desc => '{{name}} is already running. Opening it again launches a second editor instance. Open anyway?';

	/// en-US: 'Open anyway'
	String get project_open_anyway => 'Open anyway';

	/// en-US: 'Git sidebar'
	String get git_sidebar => 'Git sidebar';

	/// en-US: 'Template already installed'
	String get asset_duplicate_title => 'Template already installed';

	/// en-US: '"{{name}}" is already in your templates. Install a duplicate anyway?'
	String get asset_duplicate_desc => '"{{name}}" is already in your templates. Install a duplicate anyway?';

	/// en-US: 'Empty Category'
	String get empty_category => 'Empty Category';

	/// en-US: 'Release to drop'
	String get release_to_drop => 'Release to drop';

	/// en-US: 'System'
	String get bug_report_system => 'System';

	/// en-US: 'Version'
	String get bug_report_version => 'Version';

	/// en-US: 'Date'
	String get bug_report_date => 'Date';

	/// en-US: 'OS'
	String get bug_report_os => 'OS';

	/// en-US: 'Platform'
	String get bug_report_platform => 'Platform';

	/// en-US: 'Language'
	String get bug_report_language => 'Language';

	/// en-US: 'CPU Cores'
	String get bug_report_cpu_cores => 'CPU Cores';

	/// en-US: 'RAM'
	String get bug_report_ram => 'RAM';

	/// en-US: 'Screen'
	String get bug_report_screen => 'Screen';

	/// en-US: 'GPU'
	String get bug_report_gpu => 'GPU';

	/// en-US: 'User Agent'
	String get bug_report_user_agent => 'User Agent';

	/// en-US: 'Recent Errors'
	String get bug_report_recent_errors => 'Recent Errors';

	/// en-US: 'none captured'
	String get bug_report_none_captured => 'none captured';

	/// en-US: 'Description'
	String get bug_report_description => 'Description';

	/// en-US: 'No description provided'
	String get bug_report_no_description => 'No description provided';

	/// en-US: 'unknown'
	String get unknown => 'unknown';

	/// en-US: 'WebGL not available'
	String get gpu_webgl_unavailable => 'WebGL not available';

	/// en-US: 'GPU info unavailable'
	String get gpu_info_unavailable => 'GPU info unavailable';

	/// en-US: 'Update available'
	String get update_available => 'Update available';

	/// en-US: 'Dismiss'
	String get dismiss => 'Dismiss';

	/// en-US: 'System language'
	String get system_language => 'System language';

	/// en-US: 'Create one above to organize your projects'
	String get category_empty_hint => 'Create one above to organize your projects';

	/// en-US: 'Merged'
	String get contributor_pr_merged => 'Merged';

	/// en-US: 'Open'
	String get contributor_pr_open => 'Open';

	/// en-US: 'Closed'
	String get contributor_pr_closed => 'Closed';

	/// en-US: 'Loading PRs...'
	String get contributor_pr_loading => 'Loading PRs...';

	/// en-US: '(one) {${count} pull request} (other) {${count} pull requests}'
	String contributor_pr_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} pull request',
		other: '${count} pull requests',
	);

	/// en-US: '{{count}} pull request'
	String get contributor_pr_count_one => '{{count}} pull request';

	/// en-US: '{{count}} pull requests'
	String get contributor_pr_count_other => '{{count}} pull requests';

	/// en-US: 'Failed to load pull requests.'
	String get contributor_pr_load_failed => 'Failed to load pull requests.';

	/// en-US: 'Check your internet connection.'
	String get contributor_pr_network_hint => 'Check your internet connection.';

	/// en-US: 'No pull requests found.'
	String get contributor_pr_empty => 'No pull requests found.';

	/// en-US: 'Theme presets'
	String get theme_presets_section => 'Theme presets';

	/// en-US: 'All categories'
	String get all_categories => 'All categories';

	/// en-US: 'Clear category filter'
	String get clear_category_filter => 'Clear category filter';

	/// en-US: 'Filter by category'
	String get filter_by_category => 'Filter by category';

	/// en-US: 'Dark'
	String get theme_dark => 'Dark';

	/// en-US: 'Light'
	String get theme_light => 'Light';

	/// en-US: 'Tags'
	String get bulk_tags => 'Tags';

	/// en-US: 'Edit tags'
	String get bulk_tags_title => 'Edit tags';

	/// en-US: 'Add tag'
	String get add_tag => 'Add tag';

	/// en-US: 'Remove tag'
	String get remove_tag => 'Remove tag';

	/// en-US: 'No tags on the selected projects yet.'
	String get no_common_tags => 'No tags on the selected projects yet.';

	/// en-US: 'Added tag to {{count}} projects.'
	String get tags_added_to_selection => 'Added tag to {{count}} projects.';

	/// en-US: 'Removed tag from {{count}} projects.'
	String get tags_removed_from_selection => 'Removed tag from {{count}} projects.';

	/// en-US: 'Removed {{count}} project(s) from library.'
	String get removed_from_library => 'Removed {{count}} project(s) from library.';

	/// en-US: 'Undo'
	String get undo => 'Undo';

	/// en-US: 'Duplicate project'
	String get duplicate_project_title => 'Duplicate project';

	/// en-US: 'copy'
	String get copy_suffix => 'copy';

	/// en-US: 'Duplicate'
	String get duplicate => 'Duplicate';

	/// en-US: 'Destination folder'
	String get destination_folder => 'Destination folder';

	/// en-US: 'Project name'
	String get new_project_name => 'Project name';

	/// en-US: 'Project duplicated.'
	String get project_duplicated => 'Project duplicated.';

	/// en-US: 'Godot {{tag}} installed'
	String get notification_version_installed => 'Godot {{tag}} installed';

	/// en-US: '{{title}} installed'
	String get notification_asset_installed => '{{title}} installed';

	/// en-US: 'Repository cloned and imported'
	String get notification_clone_done => 'Repository cloned and imported';

	/// en-US: 'Console'
	String get console_title => 'Console';

	/// en-US: 'Finished'
	String get console_finished => 'Finished';

	/// en-US: 'Exited cleanly'
	String get console_exit_ok => 'Exited cleanly';

	/// en-US: 'Exit code {{code}}'
	String get console_exit_code => 'Exit code {{code}}';

	/// en-US: 'Clear output'
	String get console_clear => 'Clear output';

	/// en-US: 'Copy output'
	String get console_copy => 'Copy output';

	/// en-US: 'Minimize to a pill'
	String get console_minimize => 'Minimize to a pill';

	/// en-US: 'Waiting for output…'
	String get console_waiting => 'Waiting for output…';

	/// en-US: 'No output was captured.'
	String get console_empty => 'No output was captured.';

	/// en-US: '{{count}} older line(s) are hidden, copy or clear to manage the buffer.'
	String get console_trimmed => '{{count}} older line(s) are hidden, copy or clear to manage the buffer.';

	/// en-US: 'Godot exited with code {{code}}. The output above is kept so you can read it.'
	String get console_crash_hint => 'Godot exited with code {{code}}. The output above is kept so you can read it.';

	/// en-US: 'Errors'
	String get console_filter_errors => 'Errors';

	/// en-US: 'Warnings'
	String get console_filter_warnings => 'Warnings';

	/// en-US: 'Info'
	String get console_filter_info => 'Info';

	/// en-US: 'No lines match the filters ({{count}} hidden).'
	String get console_no_matches => 'No lines match the filters ({{count}} hidden).';

	/// en-US: 'Click to reopen the console, drag to move it.'
	String get console_pill_hint => 'Click to reopen the console, drag to move it.';

	/// en-US: 'This project kept running after GodotHub closed, its output is still being captured below.'
	String get console_resumed_hint => 'This project kept running after GodotHub closed, its output is still being captured below.';

	/// en-US: 'Output kept from the previous session.'
	String get console_previous_hint => 'Output kept from the previous session.';

	/// en-US: 'Godot {{version}} is not installed. Select an installed version to launch this project.'
	String get project_card_version_unavailable => 'Godot {{version}} is not installed. Select an installed version to launch this project.';

	/// en-US: 'Total time: {{time}}'
	String get project_card_total_time => 'Total time: {{time}}';

	/// en-US: 'Last opened: {{date}}'
	String get project_card_last_opened => 'Last opened: {{date}}';

	/// en-US: 'Show {{count}} more tags'
	String get project_card_more_tags => 'Show {{count}} more tags';

	/// en-US: 'Downloading export templates for {{tag}}'
	String get downloading_export_templates => 'Downloading export templates for {{tag}}';

	/// en-US: 'Verifying download…'
	String get export_templates_verifying => 'Verifying download…';

	/// en-US: 'Installing templates…'
	String get export_templates_extracting => 'Installing templates…';

	late final Translations$common$project_doctor$en_US project_doctor = Translations$common$project_doctor$en_US.internal(_root);
	late final Translations$common$build_export$en_US build_export = Translations$common$build_export$en_US.internal(_root);

	/// en-US: 'Project list couldn't be read'
	String get projects_corrupt_title => 'Project list couldn\'t be read';

	/// en-US: 'Your projects.json file is corrupt, so your projects can't be shown. You can restore the most recent automatic backup, or dismiss this and leave the file untouched.'
	String get projects_corrupt_desc => 'Your projects.json file is corrupt, so your projects can\'t be shown. You can restore the most recent automatic backup, or dismiss this and leave the file untouched.';

	/// en-US: 'Restore backup'
	String get projects_corrupt_restore => 'Restore backup';

	/// en-US: 'Not now'
	String get projects_corrupt_dismiss => 'Not now';

	/// en-US: 'Couldn't load your projects. Something went wrong reading them from disk. Try again, and if it keeps failing your project list file may be damaged.'
	String get projects_load_error => 'Couldn\'t load your projects. Something went wrong reading them from disk. Try again, and if it keeps failing your project list file may be damaged.';

	/// en-US: 'Storage'
	String get cleanup_title => 'Storage';

	/// en-US: 'See what GodotHub keeps on disk and free up space you no longer need.'
	String get cleanup_subtitle => 'See what GodotHub keeps on disk and free up space you no longer need.';

	/// en-US: 'on disk'
	String get cleanup_total_label => 'on disk';

	/// en-US: 'Measuring folders…'
	String get cleanup_scanning => 'Measuring folders…';

	/// en-US: 'Couldn't measure storage: {{error}}'
	String get cleanup_load_error => 'Couldn\'t measure storage: {{error}}';

	/// en-US: 'Reclaimable'
	String get cleanup_reclaimable_title => 'Reclaimable';

	/// en-US: 'Versions no project, template or alias uses, unfinished downloads, and export templates no installed version needs. Pick what to remove.'
	String get cleanup_reclaimable_desc => 'Versions no project, template or alias uses, unfinished downloads, and export templates no installed version needs. Pick what to remove.';

	/// en-US: 'Nothing to clean up right now.'
	String get cleanup_nothing_to_reclaim => 'Nothing to clean up right now.';

	/// en-US: 'Unused versions'
	String get cleanup_group_unused_versions => 'Unused versions';

	/// en-US: 'Unfinished downloads'
	String get cleanup_group_partials => 'Unfinished downloads';

	/// en-US: 'Orphaned export templates'
	String get cleanup_group_orphan_exports => 'Orphaned export templates';

	/// en-US: 'No installed version uses these, but a Godot install outside GodotHub might, so they aren't selected by default.'
	String get cleanup_orphan_exports_hint => 'No installed version uses these, but a Godot install outside GodotHub might, so they aren\'t selected by default.';

	/// en-US: 'Installed outside GodotHub's download folder'
	String get cleanup_external_hint => 'Installed outside GodotHub\'s download folder';

	/// en-US: 'Godot version download'
	String get cleanup_kind_version_download => 'Godot version download';

	/// en-US: 'Export templates download'
	String get cleanup_kind_export_templates_download => 'Export templates download';

	/// en-US: 'Reclaim {{size}}'
	String get cleanup_reclaim_btn => 'Reclaim {{size}}';

	/// en-US: 'Reclaim {{size}}?'
	String get cleanup_confirm_title => 'Reclaim {{size}}?';

	/// en-US: 'These items will be removed:'
	String get cleanup_confirm_desc => 'These items will be removed:';

	/// en-US: 'Versions and export templates are moved to the system trash, so the space is freed once you empty it. Unfinished downloads are deleted permanently.'
	String get cleanup_confirm_trash_note => 'Versions and export templates are moved to the system trash, so the space is freed once you empty it. Unfinished downloads are deleted permanently.';

	/// en-US: '(one) {Remove ${count} item} (other) {Remove ${count} items}'
	String cleanup_confirm_btn({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Remove ${count} item',
		other: 'Remove ${count} items',
	);

	/// en-US: 'Remove {{count}} item'
	String get cleanup_confirm_btn_one => 'Remove {{count}} item';

	/// en-US: 'Remove {{count}} items'
	String get cleanup_confirm_btn_other => 'Remove {{count}} items';

	/// en-US: 'Freed {{size}}'
	String get cleanup_done => 'Freed {{size}}';

	/// en-US: 'Couldn't remove {{label}}: {{error}}'
	String get cleanup_failed => 'Couldn\'t remove {{label}}: {{error}}';

	/// en-US: 'Full size on disk of every installed Godot version.'
	String get cleanup_versions_desc => 'Full size on disk of every installed Godot version.';

	/// en-US: 'Project templates'
	String get cleanup_templates_title => 'Project templates';

	/// en-US: 'Export templates'
	String get cleanup_export_templates_title => 'Export templates';

	/// en-US: '(one) {${count} template} (other) {${count} templates}'
	String cleanup_used_by_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} template',
		other: '${count} templates',
	);

	/// en-US: '{{count}} template'
	String get cleanup_used_by_templates_one => '{{count}} template';

	/// en-US: '{{count}} templates'
	String get cleanup_used_by_templates_other => '{{count}} templates';

	/// en-US: 'Current'
	String get cleanup_current_badge => 'Current';

	/// en-US: 'Alias'
	String get cleanup_alias_badge => 'Alias';

	/// en-US: 'Unused'
	String get cleanup_unused_badge => 'Unused';

	/// en-US: 'Managed by mise'
	String get cleanup_mise_badge => 'Managed by mise';

	/// en-US: 'External'
	String get cleanup_external_badge => 'External';

	/// en-US: 'Orphaned'
	String get cleanup_orphan_badge => 'Orphaned';

	/// en-US: 'Nothing here yet.'
	String get cleanup_empty => 'Nothing here yet.';

	/// en-US: 'New'
	String get new_badge => 'New';

	/// en-US: 'Reset'
	String get reset => 'Reset';

	/// en-US: 'Disconnect'
	String get git_disconnect => 'Disconnect';

	/// en-US: 'Sign in with GitHub'
	String get git_sign_in_github => 'Sign in with GitHub';

	/// en-US: 'Connected as @{{username}}'
	String get git_connected_as => 'Connected as @{{username}}';

	/// en-US: '(optional)'
	String get optional => '(optional)';

	/// en-US: 'Language'
	String get language_label => 'Language';

	/// en-US: '(one) {${count} project} (other) {${count} projects}'
	String n_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} project',
		other: '${count} projects',
	);

	/// en-US: '{{count}} project'
	String get n_projects_one => '{{count}} project';

	/// en-US: '{{count}} projects'
	String get n_projects_other => '{{count}} projects';

	/// en-US: '(one) {Item} (other) {Items}'
	String vault_item_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Item',
		other: 'Items',
	);

	/// en-US: 'Item'
	String get vault_item_count_one => 'Item';

	/// en-US: 'Items'
	String get vault_item_count_other => 'Items';

	/// en-US: 'Search vault…'
	String get vault_search_placeholder => 'Search vault…';

	/// en-US: 'Your vault is empty. Click <1>Save to Vault</1> to pick files or folders from a project and reuse them anywhere.'
	String get vault_empty => 'Your vault is empty. Click <1>Save to Vault</1> to pick files or folders from a project and reuse them anywhere.';

	/// en-US: 'No items match your search.'
	String get vault_no_match => 'No items match your search.';

	/// en-US: 'Save to Vault'
	String get vault_save_btn => 'Save to Vault';

	/// en-US: 'Save to Vault'
	String get vault_save_title => 'Save to Vault';

	/// en-US: 'Source Projects'
	String get vault_source_project_label => 'Source Projects';

	/// en-US: 'Source {{index}}'
	String get vault_source_n => 'Source {{index}}';

	/// en-US: 'Add another project'
	String get vault_add_source => 'Add another project';

	/// en-US: 'Remove source'
	String get vault_remove_source => 'Remove source';

	/// en-US: 'Select a project…'
	String get vault_select_project => 'Select a project…';

	/// en-US: 'Files & Folders'
	String get vault_select_files_label => 'Files & Folders';

	/// en-US: '{{count}} selected'
	String get vault_selected_count => '{{count}} selected';

	/// en-US: 'This project has no files.'
	String get vault_project_empty => 'This project has no files.';

	/// en-US: 'Name'
	String get vault_item_name_label => 'Name';

	/// en-US: 'Item name'
	String get vault_item_name_placeholder => 'Item name';

	/// en-US: 'Description'
	String get vault_item_desc_label => 'Description';

	/// en-US: 'What's in this item?'
	String get vault_item_desc_placeholder => 'What\'s in this item?';

	/// en-US: 'Tags'
	String get vault_item_tags_label => 'Tags';

	/// en-US: 'Add a tag…'
	String get vault_tag_input_placeholder => 'Add a tag…';

	/// en-US: 'Saved to Vault'
	String get vault_saved_toast => 'Saved to Vault';

	/// en-US: 'Edit item'
	String get vault_edit_action => 'Edit item';

	/// en-US: 'Edit Item'
	String get vault_edit_title => 'Edit Item';

	/// en-US: 'Item updated'
	String get vault_item_updated_toast => 'Item updated';

	/// en-US: 'Delete {{name}}'
	String get vault_delete_action => 'Delete {{name}}';

	/// en-US: 'Delete Item?'
	String get vault_delete_title => 'Delete Item?';

	/// en-US: '"{{name}}" will be permanently removed from your vault.'
	String get vault_delete_desc => '"{{name}}" will be permanently removed from your vault.';

	/// en-US: 'Add to Project'
	String get vault_add_btn => 'Add to Project';

	/// en-US: 'Add from Vault'
	String get vault_add_title => 'Add from Vault';

	/// en-US: 'Target Project'
	String get vault_target_project_label => 'Target Project';

	/// en-US: 'Target Projects'
	String get vault_target_projects_label => 'Target Projects';

	/// en-US: 'Adding…'
	String get vault_adding => 'Adding…';

	/// en-US: 'Overwrite files'
	String get vault_overwrite_btn => 'Overwrite files';

	/// en-US: '(one) {${count} file already exists in the project. Overwrite it?} (other) {${count} files already exist in the project. Overwrite them?}'
	String vault_conflict_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} file already exists in the project. Overwrite it?',
		other: '${count} files already exist in the project. Overwrite them?',
	);

	/// en-US: '{{count}} file already exists in the project. Overwrite it?'
	String get vault_conflict_desc_one => '{{count}} file already exists in the project. Overwrite it?';

	/// en-US: '{{count}} files already exist in the project. Overwrite them?'
	String get vault_conflict_desc_other => '{{count}} files already exist in the project. Overwrite them?';

	/// en-US: '(one) {${count} file already exists across the selected projects. Overwrite it?} (other) {${count} files already exist across the selected projects. Overwrite them?}'
	String vault_conflict_summary_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} file already exists across the selected projects. Overwrite it?',
		other: '${count} files already exist across the selected projects. Overwrite them?',
	);

	/// en-US: '{{count}} file already exists across the selected projects. Overwrite it?'
	String get vault_conflict_summary_desc_one => '{{count}} file already exists across the selected projects. Overwrite it?';

	/// en-US: '{{count}} files already exist across the selected projects. Overwrite them?'
	String get vault_conflict_summary_desc_other => '{{count}} files already exist across the selected projects. Overwrite them?';

	/// en-US: '(one) {Added ${count} file} (other) {Added ${count} files}'
	String vault_added_toast({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Added ${count} file',
		other: 'Added ${count} files',
	);

	/// en-US: 'Added {{count}} file'
	String get vault_added_toast_one => 'Added {{count}} file';

	/// en-US: 'Added {{count}} files'
	String get vault_added_toast_other => 'Added {{count}} files';

	/// en-US: '(one) {Added to ${count} project} (other) {Added to ${count} projects}'
	String vault_added_to_projects_toast({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Added to ${count} project',
		other: 'Added to ${count} projects',
	);

	/// en-US: 'Added to {{count}} project'
	String get vault_added_to_projects_toast_one => 'Added to {{count}} project';

	/// en-US: 'Added to {{count}} projects'
	String get vault_added_to_projects_toast_other => 'Added to {{count}} projects';

	/// en-US: 'This item has no files.'
	String get vault_item_empty => 'This item has no files.';

	/// en-US: 'New'
	String get kNew => 'New';

	/// en-US: 'Support GodotHub'
	String get announcement_support_title => 'Support GodotHub';

	/// en-US: 'GodotHub is free and made in my spare time. If it helps your workflow, please consider supporting development with a donation.'
	String get announcement_support_body => 'GodotHub is free and made in my spare time. If it helps your workflow, please consider supporting development with a donation.';

	/// en-US: 'Another workspace already uses this name.'
	String get workspace_name_taken_error => 'Another workspace already uses this name.';

	/// en-US: 'Start with'
	String get workspace_start_label => 'Start with';

	/// en-US: 'Copy settings from {{name}}'
	String get workspace_start_copy => 'Copy settings from {{name}}';

	/// en-US: 'Theme, language, features, and version folders carry over. Project folders start empty, and you go straight in.'
	String get workspace_start_copy_desc => 'Theme, language, features, and version folders carry over. Project folders start empty, and you go straight in.';

	/// en-US: 'Start fresh'
	String get workspace_start_fresh => 'Start fresh';

	/// en-US: 'Walk through setup for this workspace from scratch.'
	String get workspace_start_fresh_desc => 'Walk through setup for this workspace from scratch.';

	/// en-US: 'Switched to'
	String get workspace_switched_to => 'Switched to';

	late final Translations$common$project_addons$en_US project_addons = Translations$common$project_addons$en_US.internal(_root);

	/// en-US: 'Reload GodotHub?'
	String get reload_confirm_title => 'Reload GodotHub?';

	/// en-US: 'Any unsaved changes in open forms will be lost.'
	String get reload_confirm_desc => 'Any unsaved changes in open forms will be lost.';

	/// en-US: 'Presets'
	String get color_presets => 'Presets';

	/// en-US: 'Previous month'
	String get date_previous_month => 'Previous month';

	/// en-US: 'Next month'
	String get date_next_month => 'Next month';

	/// en-US: 'Change due date: {{date}}'
	String get date_change_due => 'Change due date: {{date}}';

	/// en-US: 'Add due date'
	String get date_add_due => 'Add due date';
}

// Path: dashboard
class Translations$dashboard$en_US {
	Translations$dashboard$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Good morning'
	String get greeting_morning => 'Good morning';

	/// en-US: 'Good afternoon'
	String get greeting_afternoon => 'Good afternoon';

	/// en-US: 'Good evening'
	String get greeting_evening => 'Good evening';

	/// en-US: 'Good night'
	String get greeting_night => 'Good night';

	/// en-US: '{{greeting}}, {{name}}'
	String get greeting_name => '{{greeting}}, {{name}}';

	/// en-US: 'Set a custom name'
	String get dashboard_rename_hint => 'Set a custom name';

	/// en-US: 'Rename your greeting name'
	String get dashboard_rename_aria => 'Rename your greeting name';

	/// en-US: 'Save name'
	String get dashboard_rename_save => 'Save name';

	/// en-US: 'Use system name'
	String get dashboard_rename_reset => 'Use system name';

	/// en-US: 'Your name'
	String get dashboard_name_placeholder => 'Your name';

	/// en-US: 'Current time'
	String get dashboard_clock_aria => 'Current time';

	/// en-US: 'New Project'
	String get dashboard_new_project => 'New Project';

	/// en-US: 'Import Project'
	String get dashboard_import_project => 'Import Project';

	/// en-US: 'Scan for Projects'
	String get dashboard_scan_projects => 'Scan for Projects';

	/// en-US: 'Projects'
	String get dashboard_stat_projects => 'Projects';

	/// en-US: 'Templates'
	String get dashboard_stat_templates => 'Templates';

	/// en-US: 'Engines'
	String get dashboard_stat_engines => 'Engines';

	/// en-US: 'Total Time'
	String get dashboard_stat_total_time => 'Total Time';

	/// en-US: 'Time spent on projects'
	String get dashboard_stat_total_time_hint => 'Time spent on projects';

	/// en-US: 'Recently Opened'
	String get dashboard_recent => 'Recently Opened';

	/// en-US: 'Nothing opened yet. Open a project to see it here.'
	String get dashboard_recent_empty => 'Nothing opened yet. Open a project to see it here.';

	/// en-US: 'Pinned'
	String get dashboard_pinned => 'Pinned';

	/// en-US: 'No pinned projects yet. Pin a project to keep it handy.'
	String get dashboard_pinned_empty => 'No pinned projects yet. Pin a project to keep it handy.';

	/// en-US: 'Installed Engines'
	String get dashboard_engines => 'Installed Engines';

	/// en-US: 'No engines installed yet.'
	String get dashboard_engines_empty => 'No engines installed yet.';

	/// en-US: 'Running Now'
	String get dashboard_running => 'Running Now';

	/// en-US: 'Nothing is running right now.'
	String get dashboard_running_empty => 'Nothing is running right now.';

	/// en-US: 'Opened {{time}}'
	String get dashboard_opened_at => 'Opened {{time}}';

	/// en-US: 'Daily Activity'
	String get dashboard_daily => 'Daily Activity';

	/// en-US: 'No daily activity yet.'
	String get dashboard_daily_empty => 'No daily activity yet.';

	/// en-US: 'Weekly Activity'
	String get dashboard_weekly => 'Weekly Activity';

	/// en-US: 'No weekly activity yet.'
	String get dashboard_weekly_empty => 'No weekly activity yet.';

	/// en-US: 'Monthly Activity'
	String get dashboard_monthly => 'Monthly Activity';

	/// en-US: 'No monthly activity yet.'
	String get dashboard_monthly_empty => 'No monthly activity yet.';

	/// en-US: 'Yearly Activity'
	String get dashboard_yearly => 'Yearly Activity';

	/// en-US: 'No yearly activity yet.'
	String get dashboard_yearly_empty => 'No yearly activity yet.';

	/// en-US: 'Switch to {{next}}'
	String get dashboard_activity_cycle => 'Switch to {{next}}';

	/// en-US: '{{label}} of tracked time'
	String get dashboard_weekly_aria => '{{label}} of tracked time';

	/// en-US: 'Top Projects by Time'
	String get dashboard_top_time => 'Top Projects by Time';

	/// en-US: 'No tracked time yet. Open a project to start tracking.'
	String get dashboard_top_time_empty => 'No tracked time yet. Open a project to start tracking.';

	/// en-US: 'Insights'
	String get dashboard_insights => 'Insights';

	/// en-US: 'No tracked time yet. Open a project to start building your streaks.'
	String get dashboard_insights_empty => 'No tracked time yet. Open a project to start building your streaks.';

	/// en-US: 'Longest streak'
	String get dashboard_insights_longest_streak => 'Longest streak';

	/// en-US: 'Current streak'
	String get dashboard_insights_current_streak => 'Current streak';

	/// en-US: '{{count}} days'
	String get dashboard_insights_days => '{{count}} days';

	/// en-US: 'Most productive day'
	String get dashboard_insights_productive_day => 'Most productive day';

	/// en-US: 'This month'
	String get dashboard_insights_this_month => 'This month';

	/// en-US: '{{pct}}% more than last month'
	String get dashboard_insights_delta_up => '{{pct}}% more than last month';

	/// en-US: '{{pct}}% less than last month'
	String get dashboard_insights_delta_down => '{{pct}}% less than last month';

	/// en-US: 'Git Overview'
	String get dashboard_git => 'Git Overview';

	/// en-US: 'No git repositories detected.'
	String get dashboard_git_empty => 'No git repositories detected.';

	/// en-US: 'All clean'
	String get dashboard_git_clean => 'All clean';

	/// en-US: '{{count}} with uncommitted changes'
	String get dashboard_git_dirty => '{{count}} with uncommitted changes';

	/// en-US: '(one) {1 with uncommitted changes} (other) {${count} with uncommitted changes}'
	String dashboard_git_dirty_plural({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '1 with uncommitted changes',
		other: '${count} with uncommitted changes',
	);

	/// en-US: '1 with uncommitted changes'
	String get dashboard_git_dirty_one => '1 with uncommitted changes';

	/// en-US: 'On {{branch}}'
	String get dashboard_git_branch => 'On {{branch}}';

	/// en-US: 'Storage Usage'
	String get dashboard_storage => 'Storage Usage';

	/// en-US: 'No projects to measure.'
	String get dashboard_storage_empty => 'No projects to measure.';

	/// en-US: 'Measuring…'
	String get dashboard_storage_loading => 'Measuring…';

	/// en-US: '{{size}} total'
	String get dashboard_storage_total => '{{size}} total';

	/// en-US: 'Customize'
	String get dashboard_customize => 'Customize';

	/// en-US: 'Done'
	String get dashboard_done_customizing => 'Done';

	/// en-US: 'Use the arrows to rearrange tiles, or hide the ones you don't need.'
	String get dashboard_customize_hint => 'Use the arrows to rearrange tiles, or hide the ones you don\'t need.';

	/// en-US: 'Move up'
	String get dashboard_tile_move_up => 'Move up';

	/// en-US: 'Move down'
	String get dashboard_tile_move_down => 'Move down';

	/// en-US: 'Remove'
	String get dashboard_tile_remove => 'Remove';

	/// en-US: 'Full width'
	String get dashboard_tile_span => 'Full width';

	/// en-US: 'Half width'
	String get dashboard_tile_span_off => 'Half width';

	/// en-US: 'Taller'
	String get dashboard_tile_tall => 'Taller';

	/// en-US: 'Normal height'
	String get dashboard_tile_tall_off => 'Normal height';

	/// en-US: 'Layout presets'
	String get dashboard_presets => 'Layout presets';

	/// en-US: 'Default'
	String get dashboard_preset_default => 'Default';

	/// en-US: 'Everything on, in the default order, standard sizing.'
	String get dashboard_preset_default_desc => 'Everything on, in the default order, standard sizing.';

	/// en-US: 'Overview'
	String get dashboard_preset_overview => 'Overview';

	/// en-US: 'Recently opened, pinned, engines, and running projects.'
	String get dashboard_preset_overview_desc => 'Recently opened, pinned, engines, and running projects.';

	/// en-US: 'Analytics'
	String get dashboard_preset_analytics => 'Analytics';

	/// en-US: 'Weekly activity, top projects, storage, and categories, with taller charts.'
	String get dashboard_preset_analytics_desc => 'Weekly activity, top projects, storage, and categories, with taller charts.';

	/// en-US: 'Development'
	String get dashboard_preset_development => 'Development';

	/// en-US: 'Git status front and center with running projects and engines.'
	String get dashboard_preset_development_desc => 'Git status front and center with running projects and engines.';

	/// en-US: 'Save current as preset'
	String get dashboard_preset_save => 'Save current as preset';

	/// en-US: 'Name this layout so you can switch back to it anytime.'
	String get dashboard_preset_save_hint => 'Name this layout so you can switch back to it anytime.';

	/// en-US: 'Preset name'
	String get dashboard_preset_name_placeholder => 'Preset name';

	/// en-US: 'Delete preset'
	String get dashboard_preset_delete => 'Delete preset';

	/// en-US: 'Your presets'
	String get dashboard_custom_presets => 'Your presets';

	/// en-US: 'Hidden tiles'
	String get dashboard_hidden_tiles => 'Hidden tiles';

	/// en-US: 'Due to-dos'
	String get dashboard_todos => 'Due to-dos';

	/// en-US: 'Day'
	String get dashboard_range_daily => 'Day';

	/// en-US: 'Week'
	String get dashboard_range_weekly => 'Week';

	/// en-US: 'Month'
	String get dashboard_range_monthly => 'Month';

	/// en-US: 'Year'
	String get dashboard_range_yearly => 'Year';

	/// en-US: 'Tracked'
	String get dashboard_activity_tracked => 'Tracked';

	/// en-US: 'Peak'
	String get dashboard_activity_peak => 'Peak';
}

// Path: git
class Translations$git$en_US {
	Translations$git$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Remove'
	String get remove => 'Remove';

	/// en-US: 'Changes'
	String get changes_title => 'Changes';

	/// en-US: 'Pull'
	String get pull => 'Pull';

	/// en-US: 'Push'
	String get push => 'Push';

	/// en-US: 'Force'
	String get force_push => 'Force';

	/// en-US: 'Fetch'
	String get fetch => 'Fetch';

	/// en-US: 'Change'
	String get change => 'Change';

	/// en-US: 'Commit'
	String get commit => 'Commit';

	/// en-US: 'Committing…'
	String get committing => 'Committing…';

	/// en-US: 'No remotes configured'
	String get no_remotes => 'No remotes configured';

	/// en-US: 'Switching…'
	String get switching => 'Switching…';

	/// en-US: 'No branches found'
	String get no_branches => 'No branches found';

	/// en-US: 'Branch name'
	String get new_branch_placeholder => 'Branch name';

	/// en-US: 'Delete branch'
	String get delete_branch => 'Delete branch';

	/// en-US: 'Publish branch'
	String get publish_branch => 'Publish branch';

	/// en-US: 'Publish branch to {{remote}}'
	String get publish_branch_to => 'Publish branch to {{remote}}';

	/// en-US: 'Branch published.'
	String get branch_published => 'Branch published.';

	/// en-US: 'Use ours'
	String get use_ours => 'Use ours';

	/// en-US: 'Use theirs'
	String get use_theirs => 'Use theirs';

	/// en-US: 'I resolved it'
	String get i_resolved => 'I resolved it';

	/// en-US: 'Undo last commit'
	String get undo_last_commit => 'Undo last commit';

	/// en-US: 'Undo pull'
	String get undo_pull => 'Undo pull';

	/// en-US: 'Force push?'
	String get force_push_confirm_title => 'Force push?';

	/// en-US: 'This rewrites remote history and can lose other people's commits. Continue?'
	String get force_push_confirm_desc => 'This rewrites remote history and can lose other people\'s commits. Continue?';

	/// en-US: 'Last commit undone.'
	String get undo_commit_done => 'Last commit undone.';

	/// en-US: 'Pull undone.'
	String get undo_pull_done => 'Pull undone.';

	/// en-US: 'Force pushed.'
	String get force_pushed => 'Force pushed.';

	/// en-US: 'Synced.'
	String get synced_ok => 'Synced.';

	/// en-US: 'Fetched.'
	String get fetched_ok => 'Fetched.';

	/// en-US: 'Pulled.'
	String get pulled_ok => 'Pulled.';

	/// en-US: 'Pushed.'
	String get pushed_ok => 'Pushed.';

	/// en-US: 'Branch created.'
	String get branch_created => 'Branch created.';

	/// en-US: 'Branch deleted.'
	String get branch_deleted => 'Branch deleted.';

	/// en-US: 'Changes stashed.'
	String get changes_stashed_ok => 'Changes stashed.';

	/// en-US: 'Stash applied.'
	String get stash_applied_ok => 'Stash applied.';

	/// en-US: 'Stash popped.'
	String get stash_popped_ok => 'Stash popped.';

	/// en-US: 'Stash dropped.'
	String get stash_dropped_ok => 'Stash dropped.';

	/// en-US: 'Staged.'
	String get staged_ok => 'Staged.';

	/// en-US: 'Unstaged.'
	String get unstaged_ok => 'Unstaged.';

	/// en-US: 'Discarded.'
	String get discarded_ok => 'Discarded.';

	/// en-US: 'Staged all changes.'
	String get stage_all_ok => 'Staged all changes.';

	/// en-US: 'Unstaged all changes.'
	String get unstage_all_ok => 'Unstaged all changes.';

	/// en-US: 'Discarded all changes.'
	String get discard_all_ok => 'Discarded all changes.';

	/// en-US: 'Resolved using ours.'
	String get resolved_ours => 'Resolved using ours.';

	/// en-US: 'Resolved using theirs.'
	String get resolved_theirs => 'Resolved using theirs.';

	/// en-US: 'Marked as resolved.'
	String get resolved_manual => 'Marked as resolved.';

	/// en-US: 'Committed.'
	String get committed_ok => 'Committed.';

	/// en-US: 'Switched to {{branch}}.'
	String get switched_ok => 'Switched to {{branch}}.';

	/// en-US: 'Sync'
	String get sync => 'Sync';

	/// en-US: 'No diff available for this file.'
	String get diff_no_diff => 'No diff available for this file.';

	/// en-US: 'Fetching…'
	String get fetching => 'Fetching…';

	/// en-US: 'Stashes'
	String get stashes_title => 'Stashes';

	/// en-US: 'Stash'
	String get stash => 'Stash';

	/// en-US: 'Stashing…'
	String get stashing => 'Stashing…';

	/// en-US: 'Apply stash'
	String get apply_stash => 'Apply stash';

	/// en-US: 'Pop stash'
	String get pop_stash => 'Pop stash';

	/// en-US: 'Drop stash'
	String get drop_stash => 'Drop stash';

	/// en-US: 'Merge aborted. Working directory restored.'
	String get merge_aborted => 'Merge aborted. Working directory restored.';

	/// en-US: '+ New'
	String get new_branch_btn => '+ New';

	/// en-US: 'Abort merge'
	String get abort_merge => 'Abort merge';

	/// en-US: 'Merge in progress'
	String get merge_in_progress => 'Merge in progress';

	/// en-US: 'Working tree clean.'
	String get working_tree_clean => 'Working tree clean.';

	/// en-US: 'Staged Changes'
	String get staged_changes => 'Staged Changes';

	/// en-US: 'Unstage All Changes'
	String get unstage_all_changes => 'Unstage All Changes';

	/// en-US: 'Commits'
	String get commits_title => 'Commits';

	/// en-US: 'Stage file'
	String get stage_file => 'Stage file';

	/// en-US: 'Discard file'
	String get discard_file => 'Discard file';

	/// en-US: 'Unstage file'
	String get unstage_file => 'Unstage file';

	/// en-US: 'No commits found.'
	String get no_commits_found => 'No commits found.';

	/// en-US: 'Stage All'
	String get stage_all => 'Stage All';

	/// en-US: 'Discard All'
	String get discard_all => 'Discard All';

	/// en-US: 'Connected accounts'
	String get auth_connected_accounts => 'Connected accounts';

	/// en-US: 'Connect to your desired git host to begin, or use SSH without connecting anything.'
	String get auth_connect_hint => 'Connect to your desired git host to begin, or use SSH without connecting anything.';

	/// en-US: 'Worktrees'
	String get worktrees_title => 'Worktrees';

	/// en-US: 'Current'
	String get worktree_current => 'Current';

	/// en-US: 'No additional worktrees'
	String get no_worktrees => 'No additional worktrees';

	/// en-US: 'Switch to this worktree'
	String get switch_worktree => 'Switch to this worktree';

	/// en-US: 'Switched to worktree.'
	String get switched_worktree_ok => 'Switched to worktree.';

	/// en-US: 'New worktree'
	String get add_worktree => 'New worktree';

	/// en-US: 'Add worktree'
	String get add_worktree_btn => 'Add worktree';

	/// en-US: 'Path (e.g. ../my-feature)'
	String get worktree_path_placeholder => 'Path (e.g. ../my-feature)';

	/// en-US: 'Branch name (optional)'
	String get worktree_branch_placeholder => 'Branch name (optional)';

	/// en-US: 'Worktree created.'
	String get worktree_created_ok => 'Worktree created.';

	/// en-US: 'Uncommitted changes'
	String get worktree_dirty => 'Uncommitted changes';

	/// en-US: 'Remove worktree'
	String get remove_worktree => 'Remove worktree';

	/// en-US: 'Remove the worktree at {{path}}? Its directory will be deleted. The branch and commits are kept.'
	String get remove_worktree_confirm_desc => 'Remove the worktree at {{path}}? Its directory will be deleted. The branch and commits are kept.';

	/// en-US: 'Worktree removed.'
	String get worktree_removed_ok => 'Worktree removed.';

	/// en-US: 'Fetch automatically'
	String get auto_fetch_label => 'Fetch automatically';

	/// en-US: 'Runs git fetch every few minutes so the pull bubble always shows how many commits you're behind, without merging anything. Leave it off to only fetch when you click Fetch.'
	String get auto_fetch_hint => 'Runs git fetch every few minutes so the pull bubble always shows how many commits you\'re behind, without merging anything. Leave it off to only fetch when you click Fetch.';

	/// en-US: '{{count}} commit(s) to push'
	String get commits_to_push => '{{count}} commit(s) to push';

	/// en-US: '{{count}} commit(s) to pull'
	String get commits_to_pull => '{{count}} commit(s) to pull';

	/// en-US: 'Filter changed files…'
	String get filter_changes => 'Filter changed files…';

	/// en-US: 'No matching changes.'
	String get no_matching_changes => 'No matching changes.';

	/// en-US: 'Directory'
	String get worktree_location_label => 'Directory';

	/// en-US: 'Use a new directory. Relative paths are resolved from the current repository.'
	String get worktree_location_hint => 'Use a new directory. Relative paths are resolved from the current repository.';

	/// en-US: 'New branch (optional)'
	String get worktree_branch_label => 'New branch (optional)';

	/// en-US: 'Leave blank to use the directory name as the new branch name.'
	String get worktree_branch_hint => 'Leave blank to use the directory name as the new branch name.';

	/// en-US: 'Choose parent directory'
	String get worktree_browse_parent => 'Choose parent directory';

	/// en-US: 'Removing…'
	String get worktree_removing => 'Removing…';

	/// en-US: 'Main'
	String get worktree_main => 'Main';

	/// en-US: 'Detached HEAD · {{hash}}'
	String get worktree_detached => 'Detached HEAD · {{hash}}';

	/// en-US: 'Could not load worktrees.'
	String get worktrees_load_error => 'Could not load worktrees.';

	/// en-US: 'Switch to {{name}}'
	String get switch_worktree_named => 'Switch to {{name}}';

	/// en-US: 'Discard uncommitted changes'
	String get worktree_discard_changes => 'Discard uncommitted changes';

	/// en-US: 'This worktree has uncommitted changes. Removing it with this option will permanently discard them.'
	String get worktree_discard_warning => 'This worktree has uncommitted changes. Removing it with this option will permanently discard them.';

	/// en-US: 'Discard changes?'
	String get discard_dialog_title => 'Discard changes?';

	/// en-US: 'This reverts all tracked files to the last commit.'
	String get discard_dialog_tracked_desc => 'This reverts all tracked files to the last commit.';

	/// en-US: 'These untracked files would be permanently deleted ({{n}}):'
	String get discard_dialog_untracked_heading => 'These untracked files would be permanently deleted ({{n}}):';

	/// en-US: 'No untracked files will be affected.'
	String get discard_dialog_no_untracked => 'No untracked files will be affected.';

	/// en-US: 'Discard tracked changes'
	String get discard_opt_tracked => 'Discard tracked changes';

	/// en-US: 'Reverts tracked files. Leaves untracked files untouched.'
	String get discard_opt_tracked_hint => 'Reverts tracked files. Leaves untracked files untouched.';

	/// en-US: 'Also remove untracked files'
	String get discard_opt_untracked => 'Also remove untracked files';

	/// en-US: 'Permanently deletes the files listed above. This cannot be undone.'
	String get discard_opt_untracked_hint => 'Permanently deletes the files listed above. This cannot be undone.';

	/// en-US: 'Stash everything instead'
	String get discard_opt_stash => 'Stash everything instead';

	/// en-US: 'Saves tracked and untracked changes to a stash you can restore later.'
	String get discard_opt_stash_hint => 'Saves tracked and untracked changes to a stash you can restore later.';

	/// en-US: '{{branch}} is protected on the remote'
	String get protected_branch_tooltip => '{{branch}} is protected on the remote';

	/// en-US: 'Protected branch'
	String get protected_branch_title => 'Protected branch';

	/// en-US: '{{branch}} is protected on the remote, so pushing commits to it directly may be rejected. Commit anyway, or move these changes to a new branch and open a pull request.'
	String get protected_branch_desc => '{{branch}} is protected on the remote, so pushing commits to it directly may be rejected. Commit anyway, or move these changes to a new branch and open a pull request.';

	/// en-US: 'New branch name'
	String get protected_branch_new_label => 'New branch name';

	/// en-US: 'Commit anyway'
	String get protected_branch_commit_anyway => 'Commit anyway';

	/// en-US: 'Create branch & open PR'
	String get protected_branch_create_pr => 'Create branch & open PR';

	/// en-US: 'Opening pull request…'
	String get protected_branch_creating_pr => 'Opening pull request…';

	/// en-US: 'Pushed {{branch}} and opened a pull request.'
	String get pr_opened_ok => 'Pushed {{branch}} and opened a pull request.';
}

// Path: nav
class Translations$nav$en_US {
	Translations$nav$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Dashboard'
	String get dashboard => 'Dashboard';

	/// en-US: 'Projects'
	String get projects => 'Projects';

	/// en-US: '(one) {Project} (other) {Projects}'
	String projects_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Project',
		other: 'Projects',
	);

	/// en-US: 'Project'
	String get projects_count_one => 'Project';

	/// en-US: 'Projects'
	String get projects_count_other => 'Projects';

	/// en-US: 'Versions'
	String get versions => 'Versions';

	/// en-US: 'Templates'
	String get templates => 'Templates';

	/// en-US: 'Vault'
	String get vault => 'Vault';

	/// en-US: 'Asset Store'
	String get asset_store => 'Asset Store';

	/// en-US: 'Godot News'
	String get news => 'Godot News';

	/// en-US: 'Storage'
	String get storage_view => 'Storage';

	/// en-US: 'Settings'
	String get settings => 'Settings';

	/// en-US: 'Changelog'
	String get changelog => 'Changelog';

	/// en-US: 'Workspace'
	String get group_workspace => 'Workspace';

	/// en-US: 'Resources'
	String get group_resources => 'Resources';

	/// en-US: 'Explore'
	String get group_explore => 'Explore';

	/// en-US: 'You'
	String get you => 'You';

	/// en-US: 'Manage accounts'
	String get account_manage => 'Manage accounts';

	/// en-US: 'Workspace switcher moved'
	String get workspace_tip_title => 'Workspace switcher moved';

	/// en-US: 'Workspace switcher moved to new section, Click 'You' button down below to access it.'
	String get workspace_tip_body => 'Workspace switcher moved to new section, Click \'You\' button down below to access it.';

	/// en-US: 'Got it'
	String get workspace_tip_dismiss => 'Got it';
}

// Path: onboarding
class Translations$onboarding$en_US {
	Translations$onboarding$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Welcome'
	String get welcome => 'Welcome';

	/// en-US: 'Finish'
	String get finish => 'Finish';

	/// en-US: 'In Progress'
	String get in_progress => 'In Progress';

	/// en-US: 'Prototypes'
	String get prototypes => 'Prototypes';

	/// en-US: 'Finished'
	String get finished => 'Finished';

	/// en-US: 'Game Jams'
	String get game_jams => 'Game Jams';

	/// en-US: 'Project folders'
	String get project_folders => 'Project folders';

	/// en-US: 'Version folders'
	String get version_folders => 'Version folders';

	/// en-US: 'Welcome to GodotHub'
	String get welcome_title => 'Welcome to GodotHub';

	/// en-US: 'Your one stop application for everything Godot.'
	String get welcome_desc => 'Your one stop application for everything Godot.';

	/// en-US: 'No folders added yet, GodotHub won't find any existing projects until you add one, or you can add projects manually later.'
	String get onboard_empty_projects => 'No folders added yet, GodotHub won\'t find any existing projects until you add one, or you can add projects manually later.';

	/// en-US: 'No folders added yet, new Godot downloads will go to the app data folder unless you set one below.'
	String get onboard_empty_versions => 'No folders added yet, new Godot downloads will go to the app data folder unless you set one below.';

	/// en-US: 'No folder set, you can always configure this later in Settings, or save templates manually.'
	String get onboard_no_template_folder => 'No folder set, you can always configure this later in Settings, or save templates manually.';

	/// en-US: 'Cloud Backup'
	String get onboard_cloud_heading => 'Cloud Backup';

	/// en-US: 'Already have a backup? Sign in with GitHub and restore your workspaces, projects, and settings from a gist.'
	String get onboard_cloud_desc => 'Already have a backup? Sign in with GitHub and restore your workspaces, projects, and settings from a gist.';

	/// en-US: 'Recent projects from Godot'
	String get discovery_recent_heading => 'Recent projects from Godot';

	/// en-US: 'Godot found on this computer'
	String get discovery_installs_heading => 'Godot found on this computer';

	/// en-US: 'Reading Godot's project manager list…'
	String get discovery_scanning_projects => 'Reading Godot\'s project manager list…';

	/// en-US: 'Looking for Godot on your PATH and in Steam…'
	String get discovery_scanning_installs => 'Looking for Godot on your PATH and in Steam…';

	/// en-US: 'Godot {{version}}'
	String get discovery_engine => 'Godot {{version}}';

	/// en-US: 'Favorite'
	String get discovery_favorite => 'Favorite';

	/// en-US: 'Add selected'
	String get discovery_add_selected => 'Add selected';

	/// en-US: 'Add selected ({{count}})'
	String get discovery_add_selected_count => 'Add selected ({{count}})';

	/// en-US: '(one) {Added ${count} project.} (other) {Added ${count} projects.}'
	String discovery_added_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Added ${count} project.',
		other: 'Added ${count} projects.',
	);

	/// en-US: 'Added {{count}} project.'
	String get discovery_added_projects_one => 'Added {{count}} project.';

	/// en-US: 'Added {{count}} projects.'
	String get discovery_added_projects_other => 'Added {{count}} projects.';

	/// en-US: '(one) {Added ${count} version.} (other) {Added ${count} versions.}'
	String discovery_added_versions({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Added ${count} version.',
		other: 'Added ${count} versions.',
	);

	/// en-US: 'Added {{count}} version.'
	String get discovery_added_versions_one => 'Added {{count}} version.';

	/// en-US: 'Added {{count}} versions.'
	String get discovery_added_versions_other => 'Added {{count}} versions.';

	/// en-US: 'Projects are linked to a matching Godot version automatically, including versions you add in the next step.'
	String get discovery_link_hint => 'Projects are linked to a matching Godot version automatically, including versions you add in the next step.';

	/// en-US: 'Setup'
	String get setup => 'Setup';

	/// en-US: 'How do you want to use GodotHub?'
	String get setup_title => 'How do you want to use GodotHub?';

	/// en-US: 'Pick a starting point. Anything you leave out is hidden and never loads, so GodotHub stays quick. You can change this anytime in Settings, under Behavior.'
	String get setup_desc => 'Pick a starting point. Anything you leave out is hidden and never loads, so GodotHub stays quick. You can change this anytime in Settings, under Behavior.';

	/// en-US: 'Preview'
	String get preview_heading => 'Preview';

	/// en-US: 'Step {{current}} of {{total}}'
	String get step_of => 'Step {{current}} of {{total}}';

	/// en-US: 'Dive In'
	String get dive_in => 'Dive In';

	/// en-US: 'Workspace'
	String get workspace_step => 'Workspace';

	/// en-US: 'Create your first workspace'
	String get first_workspace_title => 'Create your first workspace';

	/// en-US: 'A workspace holds your projects, categories, and settings. Give this one a name and a look that feels like yours, you can add more later.'
	String get first_workspace_desc => 'A workspace holds your projects, categories, and settings. Give this one a name and a look that feels like yours, you can add more later.';

	/// en-US: 'Basics'
	String get basics => 'Basics';

	/// en-US: 'A few basics'
	String get basics_title => 'A few basics';

	/// en-US: 'Pick your language, bring back a cloud backup if you have one, and choose whether Discord shows what you're working on.'
	String get basics_desc => 'Pick your language, bring back a cloud backup if you have one, and choose whether Discord shows what you\'re working on.';

	/// en-US: 'Welcome to'
	String get welcome_to => 'Welcome to';

	/// en-US: 'Hey {{name}}, welcome to'
	String get welcome_to_name => 'Hey {{name}}, welcome to';

	/// en-US: 'Your library is ready'
	String get found_title => 'Your library is ready';

	/// en-US: 'Here's everything GodotHub found on this machine. Taking you in now.'
	String get found_desc => 'Here\'s everything GodotHub found on this machine. Taking you in now.';
}

// Path: settings
class Translations$settings$en_US {
	Translations$settings$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Storage'
	String get storage => 'Storage';

	/// en-US: 'Behavior'
	String get behavior => 'Behavior';

	/// en-US: 'Display'
	String get display => 'Display';

	/// en-US: 'Appearance'
	String get appearance => 'Appearance';

	/// en-US: 'Accessibility'
	String get accessibility => 'Accessibility';

	/// en-US: 'Screen reader announcements and assistive technology options.'
	String get accessibility_desc => 'Screen reader announcements and assistive technology options.';

	/// en-US: 'GodotHub v{{version}}'
	String get app_version_label => 'GodotHub v{{version}}';

	/// en-US: 'Dashboard'
	String get landing_dashboard => 'Dashboard';

	/// en-US: 'Projects'
	String get landing_projects => 'Projects';

	/// en-US: 'Versions'
	String get landing_versions => 'Versions';

	/// en-US: 'Godot News'
	String get landing_news => 'Godot News';

	/// en-US: 'Screen reader announcements'
	String get screen_reader_label => 'Screen reader announcements';

	/// en-US: 'Advanced'
	String get advanced => 'Advanced';

	/// en-US: 'Integrations'
	String get integrations => 'Integrations';

	/// en-US: 'Motion'
	String get motion => 'Motion';

	/// en-US: 'Data & Backup'
	String get data => 'Data & Backup';

	/// en-US: 'Sign in with {{provider}}'
	String get git_auth_title => 'Sign in with {{provider}}';

	/// en-US: 'Copy code'
	String get git_auth_copy_code => 'Copy code';

	/// en-US: 'Copy link'
	String get git_auth_copy_link => 'Copy link';

	/// en-US: 'Waiting for you to authorize…'
	String get git_auth_waiting => 'Waiting for you to authorize…';

	/// en-US: 'Sign in with GitLab'
	String get git_sign_in_gitlab => 'Sign in with GitLab';

	/// en-US: 'Connected to {{host}} as @{{username}}'
	String get git_connected_to => 'Connected to {{host}} as @{{username}}';

	/// en-US: 'Self-hosted GitLab'
	String get git_self_hosted_title => 'Self-hosted GitLab';

	/// en-US: 'Connect to your own GitLab instance. Create an OAuth application on your instance (scopes: read_repository, write_repository, read_user) and paste its base URL and Application ID.'
	String get git_self_hosted_desc => 'Connect to your own GitLab instance. Create an OAuth application on your instance (scopes: read_repository, write_repository, read_user) and paste its base URL and Application ID.';

	/// en-US: 'https://gitlab.example.com'
	String get git_self_hosted_url_placeholder => 'https://gitlab.example.com';

	/// en-US: 'Application ID'
	String get git_self_hosted_client_id => 'Application ID';

	/// en-US: 'Sign in with instance'
	String get git_sign_in_self_hosted => 'Sign in with instance';

	/// en-US: 'Other hosts (personal access tokens)'
	String get git_pat_title => 'Other hosts (personal access tokens)';

	/// en-US: 'Add token'
	String get git_pat_add => 'Add token';

	/// en-US: 'e.g. codeberg.org'
	String get git_pat_host_placeholder => 'e.g. codeberg.org';

	/// en-US: 'Username'
	String get git_pat_username => 'Username';

	/// en-US: 'Token'
	String get git_pat_token => 'Token';

	/// en-US: 'Save token'
	String get git_pat_save => 'Save token';

	/// en-US: 'No tokens added yet.'
	String get git_pat_empty => 'No tokens added yet.';

	/// en-US: 'Remove token'
	String get git_pat_remove => 'Remove token';

	/// en-US: 'Storage & Auto-scan'
	String get storage_title => 'Storage & Auto-scan';

	/// en-US: 'Projects'
	String get behavior_projects_title => 'Projects';

	/// en-US: 'File Watchers'
	String get file_watchers_title => 'File Watchers';

	/// en-US: 'Last Opened Display'
	String get last_opened_title => 'Last Opened Display';

	/// en-US: 'GitHub API Token'
	String get github_token_title => 'GitHub API Token';

	/// en-US: 'Titlebar Buttons'
	String get titlebar_buttons => 'Titlebar Buttons';

	/// en-US: 'Setup Wizard'
	String get setup_wizard => 'Setup Wizard';

	/// en-US: 'Run Setup Wizard Again'
	String get setup_wizard_again => 'Run Setup Wizard Again';

	/// en-US: 'Restart App'
	String get restart_app => 'Restart App';

	/// en-US: 'Restart GodotHub?'
	String get restart_app_confirm_title => 'Restart GodotHub?';

	/// en-US: 'The app will close and reopen automatically. Unsaved in-progress operations may be interrupted.'
	String get restart_app_confirm_desc => 'The app will close and reopen automatically. Unsaved in-progress operations may be interrupted.';

	/// en-US: 'Reset Settings'
	String get reset_settings => 'Reset Settings';

	/// en-US: 'Delete App Data'
	String get delete_app_data => 'Delete App Data';

	/// en-US: 'New project default'
	String get new_project_default => 'New project default';

	/// en-US: 'Download folder'
	String get download_folder => 'Download folder';

	/// en-US: 'System'
	String get system => 'System';

	/// en-US: '12-hour (2:30 PM)'
	String get k12h => '12-hour (2:30 PM)';

	/// en-US: '24-hour (14:30)'
	String get k24h => '24-hour (14:30)';

	/// en-US: 'DD-MM-YYYY'
	String get dd_mm_yyyy => 'DD-MM-YYYY';

	/// en-US: 'MM-DD-YYYY'
	String get mm_dd_yyyy => 'MM-DD-YYYY';

	/// en-US: 'YYYY-MM-DD'
	String get yyyy_mm_dd => 'YYYY-MM-DD';

	/// en-US: 'Reset all settings?'
	String get reset_all_title => 'Reset all settings?';

	/// en-US: 'This restores every setting on this page, download folder, scan folders, appearance, and behavior, back to their defaults. This can't be undone.'
	String get reset_all_desc => 'This restores every setting on this page, download folder, scan folders, appearance, and behavior, back to their defaults. This can\'t be undone.';

	/// en-US: 'Delete all app data?'
	String get delete_all_title => 'Delete all app data?';

	/// en-US: 'This permanently deletes every workspace, project, category, installed-version record, and setting GodotHub has stored, and restarts you at first-time setup. Your actual project folders and Godot installs on disk are not touched, unless they live in the default download folder, in which case they're deleted too. This can't be undone.'
	String get delete_all_desc => 'This permanently deletes every workspace, project, category, installed-version record, and setting GodotHub has stored, and restarts you at first-time setup. Your actual project folders and Godot installs on disk are not touched, unless they live in the default download folder, in which case they\'re deleted too. This can\'t be undone.';

	/// en-US: 'No folders added, nothing will be scanned at startup, and new projects will ask where to save each time.'
	String get empty_hint_projects => 'No folders added, nothing will be scanned at startup, and new projects will ask where to save each time.';

	/// en-US: 'No folders added, nothing will be scanned at startup, and new downloads will use the app data folder.'
	String get empty_hint_versions => 'No folders added, nothing will be scanned at startup, and new downloads will use the app data folder.';

	/// en-US: 'Directory naming convention'
	String get naming_convention_label => 'Directory naming convention';

	/// en-US: 'Keep as typed (My Game)'
	String get naming_keep => 'Keep as typed (My Game)';

	/// en-US: 'kebab-case (my-game)'
	String get naming_kebab => 'kebab-case (my-game)';

	/// en-US: 'snake_case (my_game)'
	String get naming_snake => 'snake_case (my_game)';

	/// en-US: 'camelCase (myGame)'
	String get naming_camel => 'camelCase (myGame)';

	/// en-US: 'PascalCase (MyGame)'
	String get naming_pascal => 'PascalCase (MyGame)';

	/// en-US: 'Title Case (My Game)'
	String get naming_title => 'Title Case (My Game)';

	/// en-US: 'Theme'
	String get theme => 'Theme';

	/// en-US: 'Theme preset'
	String get theme_preset_label => 'Theme preset';

	/// en-US: 'Custom'
	String get theme_preset_custom => 'Custom';

	/// en-US: 'Light themes'
	String get preset_light_group => 'Light themes';

	/// en-US: 'Dark themes'
	String get preset_dark_group => 'Dark themes';

	/// en-US: 'Test'
	String get test => 'Test';

	/// en-US: 'Testing…'
	String get testing => 'Testing…';

	/// en-US: 'Token valid! Rate limit: {{status}}'
	String get token_valid => 'Token valid! Rate limit: {{status}}';

	/// en-US: '(resets ~{{minutes}} min)'
	String get token_resets_in => '(resets ~{{minutes}} min)';

	/// en-US: 'Test failed: {{error}}'
	String get test_failed => 'Test failed: {{error}}';

	/// en-US: 'Space'
	String get key_space => 'Space';

	/// en-US: 'No settings match'
	String get no_settings_match => 'No settings match';

	/// en-US: 'Found {{projects}} new project(s) and {{versions}} new version(s).'
	String get scan_result => 'Found {{projects}} new project(s) and {{versions}} new version(s).';

	/// en-US: 'Command palette shortcut'
	String get palette_shortcut => 'Command palette shortcut';

	/// en-US: 'Click the button below, then press any key to rebind.'
	String get keybind_instruction => 'Click the button below, then press any key to rebind.';

	/// en-US: 'Press'
	String get press => 'Press';

	/// en-US: 'to cancel'
	String get to_cancel => 'to cancel';

	/// en-US: 'Press a key…'
	String get press_key => 'Press a key…';

	/// en-US: 'Click to rebind'
	String get click_to_rebind => 'Click to rebind';

	/// en-US: 'Close application on project open'
	String get close_on_open_label => 'Close application on project open';

	/// en-US: 'Launch Godot with console'
	String get launch_console_label => 'Launch Godot with console';

	/// en-US: 'Use the built-in console'
	String get builtin_console_label => 'Use the built-in console';

	/// en-US: 'Minimize to system tray on closing app'
	String get minimize_tray_label => 'Minimize to system tray on closing app';

	/// en-US: 'Reopen after closing Godot'
	String get reopen_label => 'Reopen after closing Godot';

	/// en-US: 'No folder set. You can still import manually or use 'Save as Template'.'
	String get no_folder_set => 'No folder set. You can still import manually or use \'Save as Template\'.';

	/// en-US: 'UI density'
	String get ui_density_label => 'UI density';

	/// en-US: 'Text size'
	String get text_size_label => 'Text size';

	/// en-US: 'Godot versions'
	String get section_godot_versions => 'Godot versions';

	/// en-US: 'Scan depth'
	String get scan_depth_label => 'Scan depth';

	/// en-US: 'Project icon search depth'
	String get icon_scan_depth_label => 'Project icon search depth';

	/// en-US: 'Simultaneous downloads'
	String get download_concurrency_label => 'Simultaneous downloads';

	/// en-US: 'Tray recent projects'
	String get tray_recent_label => 'Tray recent projects';

	/// en-US: 'Tooltip delay'
	String get tooltip_delay_label => 'Tooltip delay';

	/// en-US: 'Project icon opacity'
	String get project_icon_opacity_label => 'Project icon opacity';

	/// en-US: 'Project card style'
	String get project_card_style_label => 'Project card style';

	/// en-US: 'Godot Hub'
	String get project_card_style_hub => 'Godot Hub';

	/// en-US: 'Cover'
	String get project_card_style_cover => 'Cover';

	/// en-US: 'Time format (shown when opened today)'
	String get time_format_label => 'Time format (shown when opened today)';

	/// en-US: 'Date format (shown for any other day)'
	String get date_format_label => 'Date format (shown for any other day)';

	/// en-US: 'Auto-scan on startup'
	String get auto_scan_label => 'Auto-scan on startup';

	/// en-US: 'Use workspaces'
	String get use_workspaces_label => 'Use workspaces';

	/// en-US: 'Watch project folders'
	String get watch_projects_label => 'Watch project folders';

	/// en-US: 'Watch version folders'
	String get watch_versions_label => 'Watch version folders';

	/// en-US: 'Watch template directory'
	String get watch_template_label => 'Watch template directory';

	/// en-US: 'Show scrollbar'
	String get show_scrollbar_label => 'Show scrollbar';

	/// en-US: 'Animated numbers'
	String get animated_numbers_label => 'Animated numbers';

	/// en-US: 'Show support button'
	String get show_support_label => 'Show support button';

	/// en-US: 'Show star button'
	String get show_star_label => 'Show star button';

	/// en-US: 'Show bug report button'
	String get show_bug_label => 'Show bug report button';

	/// en-US: 'Show tray button'
	String get show_tray_label => 'Show tray button';

	/// en-US: 'Show language button'
	String get show_language_label => 'Show language button';

	/// en-US: 'Clear'
	String get clear => 'Clear';

	/// en-US: 'Reset to default'
	String get reset_to_default => 'Reset to default';

	/// en-US: 'Reset appearance to default'
	String get reset_appearance => 'Reset appearance to default';

	/// en-US: 'Delete All'
	String get delete_all => 'Delete All';

	/// en-US: 'Open Setup'
	String get open_setup => 'Open Setup';

	/// en-US: 'Reset colors to default'
	String get reset_colors => 'Reset colors to default';

	/// en-US: '(one) {${count} folder deep} (other) {${count} folders deep}'
	String folders_deep({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} folder deep',
		other: '${count} folders deep',
	);

	/// en-US: '{{count}} folder deep'
	String get folders_deep_one => '{{count}} folder deep';

	/// en-US: '{{count}} folders deep'
	String get folders_deep_other => '{{count}} folders deep';

	/// en-US: '{{count}} at once'
	String get at_once => '{{count}} at once';

	/// en-US: 'Animation speed'
	String get animation_speed_label => 'Animation speed';

	/// en-US: 'Scroll reveal'
	String get scroll_reveal_label => 'Scroll reveal';

	/// en-US: 'Card tilt on hover'
	String get card_tilt_label => 'Card tilt on hover';

	/// en-US: 'Click ripple'
	String get click_ripple_label => 'Click ripple';

	/// en-US: 'Press bounce'
	String get press_bounce_label => 'Press bounce';

	/// en-US: 'Animation intensity'
	String get animation_intensity_label => 'Animation intensity';

	/// en-US: 'Full'
	String get animation_full => 'Full';

	/// en-US: 'Subtle'
	String get animation_subtle => 'Subtle';

	/// en-US: 'None'
	String get animation_none => 'None';

	/// en-US: 'View entrance animation'
	String get view_entrance_label => 'View entrance animation';

	/// en-US: 'Fade'
	String get entrance_fade => 'Fade';

	/// en-US: 'Slide'
	String get entrance_slide => 'Slide';

	/// en-US: 'Scale'
	String get entrance_scale => 'Scale';

	/// en-US: 'None'
	String get entrance_none => 'None';

	/// en-US: 'Custom CSS'
	String get custom_css_label => 'Custom CSS';

	/// en-US: '/* Your custom styles, e.g. */ .card { border-radius: 4px !important; }'
	String get custom_css_placeholder => '/* Your custom styles, e.g. */\n.card { border-radius: 4px !important; }';

	/// en-US: 'Apply CSS'
	String get custom_css_apply => 'Apply CSS';

	/// en-US: 'CSS applied'
	String get custom_css_applied => 'CSS applied';

	/// en-US: 'List animation threshold'
	String get animation_threshold_label => 'List animation threshold';

	/// en-US: 'Time tracking backup'
	String get time_tracking_title => 'Time tracking backup';

	/// en-US: 'Export stats…'
	String get export_stats_btn => 'Export stats…';

	/// en-US: 'Import stats…'
	String get import_stats_btn => 'Import stats…';

	/// en-US: 'Time stats exported.'
	String get stats_exported => 'Time stats exported.';

	/// en-US: 'Clear all time data?'
	String get clear_stats_confirm_title => 'Clear all time data?';

	/// en-US: 'This permanently deletes all time tracking history, session records, and per-project totals. This cannot be undone.'
	String get clear_stats_confirm_desc => 'This permanently deletes all time tracking history, session records, and per-project totals. This cannot be undone.';

	/// en-US: 'Clear All'
	String get clear_stats_confirm_btn => 'Clear All';

	/// en-US: 'Time data cleared.'
	String get stats_cleared => 'Time data cleared.';

	/// en-US: 'Backup settings'
	String get settings_backup_title => 'Backup settings';

	/// en-US: 'Export Settings'
	String get export_settings_btn => 'Export Settings';

	/// en-US: 'Import Settings'
	String get import_settings_btn => 'Import Settings';

	/// en-US: 'Backup workspace'
	String get workspace_backup_title => 'Backup workspace';

	/// en-US: 'Export Workspace'
	String get workspace_backup_export_btn => 'Export Workspace';

	/// en-US: 'Restore Workspace'
	String get workspace_backup_restore_btn => 'Restore Workspace';

	/// en-US: 'Workspace backup exported.'
	String get workspace_backup_exported => 'Workspace backup exported.';

	/// en-US: 'Workspace restored.'
	String get workspace_backup_imported => 'Workspace restored.';

	/// en-US: 'Backup everything (all workspaces)'
	String get app_backup_title => 'Backup everything (all workspaces)';

	/// en-US: 'Export Everything'
	String get app_backup_export_btn => 'Export Everything';

	/// en-US: 'Restore Everything'
	String get app_backup_restore_btn => 'Restore Everything';

	/// en-US: 'Full app backup exported.'
	String get app_backup_exported => 'Full app backup exported.';

	/// en-US: 'All workspaces restored.'
	String get app_backup_imported => 'All workspaces restored.';

	/// en-US: 'Cloud sync (GitHub gist)'
	String get sync_title => 'Cloud sync (GitHub gist)';

	/// en-US: 'Push'
	String get sync_push_btn => 'Push';

	/// en-US: 'Pull'
	String get sync_pull_btn => 'Pull';

	/// en-US: 'All workspaces pushed to your gist.'
	String get sync_push_done => 'All workspaces pushed to your gist.';

	/// en-US: 'Open gist'
	String get sync_open_gist => 'Open gist';

	/// en-US: 'Last pushed: {{time}}'
	String get sync_last_pushed => 'Last pushed: {{time}}';

	/// en-US: 'Lost your local data? Enter your gist URL or ID to restore from any machine.'
	String get sync_manual_hint => 'Lost your local data? Enter your gist URL or ID to restore from any machine.';

	/// en-US: 'https://gist.github.com/... or gist ID'
	String get sync_manual_placeholder => 'https://gist.github.com/... or gist ID';

	/// en-US: 'Restore'
	String get sync_manual_pull_btn => 'Restore';

	/// en-US: 'Restore from Cloud'
	String get restore_modal_title => 'Restore from Cloud';

	/// en-US: 'Fetching backup from GitHub…'
	String get restore_modal_fetching => 'Fetching backup from GitHub…';

	/// en-US: 'Applying backup and restarting…'
	String get restore_modal_applying => 'Applying backup and restarting…';

	/// en-US: 'Your gist backup contains:'
	String get restore_modal_preview_desc => 'Your gist backup contains:';

	/// en-US: '(one) {workspace} (other) {workspaces}'
	String restore_modal_workspaces({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'workspace',
		other: 'workspaces',
	);

	/// en-US: 'workspace'
	String get restore_modal_workspaces_one => 'workspace';

	/// en-US: 'workspaces'
	String get restore_modal_workspaces_other => 'workspaces';

	/// en-US: '(one) {project} (other) {projects}'
	String restore_modal_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'project',
		other: 'projects',
	);

	/// en-US: 'project'
	String get restore_modal_projects_one => 'project';

	/// en-US: 'projects'
	String get restore_modal_projects_other => 'projects';

	/// en-US: '(one) {category} (other) {categories}'
	String restore_modal_categories({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'category',
		other: 'categories',
	);

	/// en-US: 'category'
	String get restore_modal_categories_one => 'category';

	/// en-US: 'categories'
	String get restore_modal_categories_other => 'categories';

	/// en-US: '(one) {template} (other) {templates}'
	String restore_modal_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'template',
		other: 'templates',
	);

	/// en-US: 'template'
	String get restore_modal_templates_one => 'template';

	/// en-US: 'templates'
	String get restore_modal_templates_other => 'templates';

	/// en-US: 'Includes time tracking data'
	String get restore_modal_time_stats => 'Includes time tracking data';

	/// en-US: '(one) {Includes ${count} to-do} (other) {Includes ${count} to-dos}'
	String restore_modal_todos({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Includes ${count} to-do',
		other: 'Includes ${count} to-dos',
	);

	/// en-US: 'Includes {{count}} to-do'
	String get restore_modal_todos_one => 'Includes {{count}} to-do';

	/// en-US: 'Includes {{count}} to-dos'
	String get restore_modal_todos_other => 'Includes {{count}} to-dos';

	/// en-US: '{{count}} project scan folder(s) will be restored'
	String get restore_modal_project_scan_dirs => '{{count}} project scan folder(s) will be restored';

	/// en-US: '{{count}} Godot version folder(s) will be restored'
	String get restore_modal_version_scan_dirs => '{{count}} Godot version folder(s) will be restored';

	/// en-US: 'Workspaces'
	String get restore_modal_workspace_list => 'Workspaces';

	/// en-US: 'This will overwrite your current settings and workspace data. You'll need to restart the app to apply changes.'
	String get restore_modal_warning => 'This will overwrite your current settings and workspace data. You\'ll need to restart the app to apply changes.';

	/// en-US: 'Apply & Restart'
	String get restore_modal_apply_btn => 'Apply & Restart';

	/// en-US: 'Backup Restored'
	String get restore_modal_done_title => 'Backup Restored';

	/// en-US: 'Click the button below to restart and apply all changes.'
	String get restore_modal_done_hint => 'Click the button below to restart and apply all changes.';

	/// en-US: 'Settings exported.'
	String get settings_exported => 'Settings exported.';

	/// en-US: 'Settings imported.'
	String get settings_imported => 'Settings imported.';

	/// en-US: '(one) {Imported stats for ${count} project.} (other) {Imported stats for ${count} projects.}'
	String stats_imported({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Imported stats for ${count} project.',
		other: 'Imported stats for ${count} projects.',
	);

	/// en-US: 'Imported stats for {{count}} project.'
	String get stats_imported_one => 'Imported stats for {{count}} project.';

	/// en-US: 'Imported stats for {{count}} projects.'
	String get stats_imported_other => 'Imported stats for {{count}} projects.';

	/// en-US: 'Raised surface contrast'
	String get raised_contrast_label => 'Raised surface contrast';

	/// en-US: '{{value}}%'
	String get raised_contrast_value => '{{value}}%';

	/// en-US: 'Create a token at github.com/settings/tokens. You only need to check the repo scope if you want private repo access, otherwise leave all scopes unchecked. No sensitive permissions required.'
	String get token_help_desc => 'Create a token at github.com/settings/tokens. You only need to check the repo scope if you want private repo access, otherwise leave all scopes unchecked. No sensitive permissions required.';

	/// en-US: 'Discord Application ID'
	String get discord_app_id_label => 'Discord Application ID';

	/// en-US: 'Leave empty to use the built-in default'
	String get discord_app_id_placeholder => 'Leave empty to use the built-in default';

	/// en-US: 'Create an application in the Discord Developer Portal and paste its Application ID here to use your own instead of GodotHub's built-in one. The activity shows under that application's name.'
	String get discord_app_id_desc => 'Create an application in the Discord Developer Portal and paste its Application ID here to use your own instead of GodotHub\'s built-in one. The activity shows under that application\'s name.';

	/// en-US: 'Discord Developer Portal'
	String get discord_developer_portal => 'Discord Developer Portal';

	/// en-US: 'Using the built-in GodotHub application.'
	String get discord_builtin_hint => 'Using the built-in GodotHub application.';

	/// en-US: 'Show project names'
	String get discord_show_projects_label => 'Show project names';

	/// en-US: 'Excluded projects'
	String get discord_excluded_label => 'Excluded projects';

	/// en-US: 'Add project'
	String get discord_exclude_project => 'Add project';

	/// en-US: 'No excluded projects.'
	String get discord_excluded_empty => 'No excluded projects.';

	/// en-US: 'Remove from excluded projects'
	String get discord_excluded_remove => 'Remove from excluded projects';

	/// en-US: 'Custom presence'
	String get discord_custom_label => 'Custom presence';

	/// en-US: 'Add project'
	String get discord_custom_add => 'Add project';

	/// en-US: 'Details line'
	String get discord_custom_details_placeholder => 'Details line';

	/// en-US: 'State line'
	String get discord_custom_state_placeholder => 'State line';

	/// en-US: 'Remove custom presence'
	String get discord_custom_remove => 'Remove custom presence';

	/// en-US: 'Search settings…'
	String get search_placeholder => 'Search settings…';

	/// en-US: 'Interface'
	String get interface_label => 'Interface';

	/// en-US: 'Card layout'
	String get card_layout_label => 'Card layout';

	/// en-US: 'Default landing page'
	String get landing_tab_label => 'Default landing page';

	/// en-US: 'Complete'
	String get language_complete => 'Complete';

	/// en-US: 'Beta'
	String get language_beta => 'Beta';

	/// en-US: 'Incomplete'
	String get language_incomplete => 'Incomplete';

	/// en-US: 'Use OS window decorations'
	String get use_os_decorations => 'Use OS window decorations';

	/// en-US: 'Credits'
	String get credits => 'Credits';

	/// en-US: 'Created by'
	String get credits_developer => 'Created by';

	/// en-US: 'Built with'
	String get credits_built_with => 'Built with';

	/// en-US: 'Contributors'
	String get credits_contributors => 'Contributors';

	/// en-US: 'Experimental'
	String get experimental => 'Experimental';

	/// en-US: 'Customize View button'
	String get customize_view_label => 'Customize View button';

	/// en-US: 'Fixed sidebar resize knob'
	String get fixed_sidebar_resize_knob_label => 'Fixed sidebar resize knob';

	/// en-US: 'Desktop notifications'
	String get desktop_notifications_label => 'Desktop notifications';

	/// en-US: 'Colored window buttons'
	String get colored_titlebar_buttons_label => 'Colored window buttons';

	/// en-US: 'Project Next Steps'
	String get project_todos_label => 'Project Next Steps';

	/// en-US: 'Use mise for Godot versions'
	String get mise_label => 'Use mise for Godot versions';

	/// en-US: 'Detected mise {{version}}'
	String get mise_detected => 'Detected mise {{version}}';

	/// en-US: 'mise was not found on your PATH, so this stays off until you install it.'
	String get mise_not_found => 'mise was not found on your PATH, so this stays off until you install it.';

	/// en-US: 'Command-line tool'
	String get cli_tool_title => 'Command-line tool';

	/// en-US: 'Install'
	String get cli_tool_install => 'Install';

	/// en-US: 'Installing...'
	String get cli_tool_installing => 'Installing...';

	/// en-US: 'Installed. Open a new terminal, then run: godothub'
	String get cli_tool_installed_msg => 'Installed. Open a new terminal, then run: godothub';

	/// en-US: 'Removed. The godothub command is no longer on your PATH.'
	String get cli_tool_uninstalled_msg => 'Removed. The godothub command is no longer on your PATH.';

	/// en-US: 'Copy your code'
	String get git_auth_step_copy => 'Copy your code';

	/// en-US: 'Paste it on {{provider}}'
	String get git_auth_step_paste => 'Paste it on {{provider}}';

	/// en-US: 'Approve GodotHub'
	String get git_auth_step_approve => 'Approve GodotHub';

	/// en-US: 'Copy code & open {{provider}}'
	String get git_auth_copy_and_open => 'Copy code & open {{provider}}';

	/// en-US: 'Copied'
	String get git_auth_copied => 'Copied';

	/// en-US: 'Expires in {{time}}'
	String get git_auth_expires_in => 'Expires in {{time}}';

	/// en-US: 'This code has expired'
	String get git_auth_expired => 'This code has expired';

	/// en-US: 'Couldn’t connect'
	String get git_auth_failed => 'Couldn’t connect';

	/// en-US: 'Try again'
	String get git_auth_try_again => 'Try again';

	/// en-US: 'You can close this window.'
	String get git_auth_success_hint => 'You can close this window.';

	/// en-US: 'Show changelog button'
	String get show_changelog_label => 'Show changelog button';

	/// en-US: 'Features'
	String get features_title => 'Features';

	/// en-US: 'Choose which parts of GodotHub you use. Hidden features leave the sidebar and stop loading or running in the background.'
	String get features_desc => 'Choose which parts of GodotHub you use. Hidden features leave the sidebar and stop loading or running in the background.';

	/// en-US: 'Always on'
	String get features_always_on => 'Always on';

	/// en-US: 'Optional'
	String get features_optional => 'Optional';

	/// en-US: '(one) {${count} feature on} (other) {${count} features on}'
	String features_enabled_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} feature on',
		other: '${count} features on',
	);

	/// en-US: '{{count}} feature on'
	String get features_enabled_count_one => '{{count}} feature on';

	/// en-US: '{{count}} features on'
	String get features_enabled_count_other => '{{count}} features on';

	/// en-US: 'Minimal'
	String get setup_profile_minimal => 'Minimal';

	/// en-US: 'Just projects and Godot versions. The lightest, fastest setup.'
	String get setup_profile_minimal_desc => 'Just projects and Godot versions. The lightest, fastest setup.';

	/// en-US: 'Essentials'
	String get setup_profile_essentials => 'Essentials';

	/// en-US: 'Adds the Asset Store, templates, and categories.'
	String get setup_profile_essentials_desc => 'Adds the Asset Store, templates, and categories.';

	/// en-US: 'Studio'
	String get setup_profile_studio => 'Studio';

	/// en-US: 'Essentials plus the dashboard, vault, storage, and workspaces.'
	String get setup_profile_studio_desc => 'Essentials plus the dashboard, vault, storage, and workspaces.';

	/// en-US: 'Everything'
	String get setup_profile_complete => 'Everything';

	/// en-US: 'Every feature GodotHub has, including Godot news.'
	String get setup_profile_complete_desc => 'Every feature GodotHub has, including Godot news.';

	/// en-US: 'Custom'
	String get setup_profile_custom => 'Custom';

	/// en-US: 'Turn individual features on or off.'
	String get setup_profile_custom_desc => 'Turn individual features on or off.';

	/// en-US: 'An overview of your activity, playtime, and recent projects.'
	String get feature_desc_dashboard => 'An overview of your activity, playtime, and recent projects.';

	/// en-US: 'Start new projects from your own reusable templates.'
	String get feature_desc_templates => 'Start new projects from your own reusable templates.';

	/// en-US: 'Keep reusable scripts, scenes, and assets in one library.'
	String get feature_desc_vault => 'Keep reusable scripts, scenes, and assets in one library.';

	/// en-US: 'See how much disk space projects and engines use.'
	String get feature_desc_storage => 'See how much disk space projects and engines use.';

	/// en-US: 'Browse and install addons and demos from the Godot Asset Library.'
	String get feature_desc_asset_store => 'Browse and install addons and demos from the Godot Asset Library.';

	/// en-US: 'Group your project list into folders.'
	String get feature_desc_categories => 'Group your project list into folders.';

	/// en-US: 'Switch between separate sets of projects and settings.'
	String get feature_desc_workspaces => 'Switch between separate sets of projects and settings.';
}

// Path: todos
class Translations$todos$en_US {
	Translations$todos$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Next steps'
	String get next_steps => 'Next steps';

	/// en-US: 'Saving tasks'
	String get saving_tasks => 'Saving tasks';

	/// en-US: '(one) {${count} pending} (other) {${count} pending}'
	String pending_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} pending',
		other: '${count} pending',
	);

	/// en-US: '{{count}} pending'
	String get pending_count_one => '{{count}} pending';

	/// en-US: '{{count}} pending'
	String get pending_count_other => '{{count}} pending';

	/// en-US: '(one) {${count} completed} (other) {${count} completed}'
	String completed_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} completed',
		other: '${count} completed',
	);

	/// en-US: '{{count}} completed'
	String get completed_count_one => '{{count}} completed';

	/// en-US: '{{count}} completed'
	String get completed_count_other => '{{count}} completed';

	/// en-US: 'New task'
	String get new_task => 'New task';

	/// en-US: 'Hide next steps'
	String get hide_next_steps => 'Hide next steps';

	/// en-US: 'Could not save the changes.'
	String get save_changes_failed => 'Could not save the changes.';

	/// en-US: 'Loading tasks...'
	String get loading_tasks => 'Loading tasks...';

	/// en-US: 'Could not load tasks'
	String get load_tasks_failed => 'Could not load tasks';

	/// en-US: 'Your data was not modified.'
	String get data_unchanged => 'Your data was not modified.';

	/// en-US: 'No tasks yet'
	String get empty_title => 'No tasks yet';

	/// en-US: 'Add the first next step for this project.'
	String get empty_description => 'Add the first next step for this project.';

	/// en-US: 'Create task'
	String get create_task => 'Create task';

	/// en-US: 'All done'
	String get all_completed_title => 'All done';

	/// en-US: 'You completed all the next steps for this project.'
	String get all_completed_description => 'You completed all the next steps for this project.';

	/// en-US: 'Use the list to keep track of the project's next steps.'
	String get footer_hint => 'Use the list to keep track of the project\'s next steps.';

	/// en-US: 'View all'
	String get view_all => 'View all';

	/// en-US: 'Delete task?'
	String get delete_task_title => 'Delete task?';

	/// en-US: 'The task <strong>“{{title}}”</strong> will be deleted. This action cannot be undone.'
	String get delete_task_description => 'The task <strong>“{{title}}”</strong> will be deleted. This action cannot be undone.';

	/// en-US: 'Task'
	String get task => 'Task';

	/// en-US: 'Discipline'
	String get area => 'Discipline';

	/// en-US: 'Status'
	String get status => 'Status';

	/// en-US: 'Due date'
	String get due_date => 'Due date';

	/// en-US: 'Sort by status'
	String get sort_by_status => 'Sort by status';

	/// en-US: 'Sort by due date'
	String get sort_by_due_date => 'Sort by due date';

	/// en-US: 'Change status: {{status}}'
	String get change_status => 'Change status: {{status}}';

	/// en-US: 'Overdue'
	String get overdue => 'Overdue';

	/// en-US: 'Mark task as completed'
	String get mark_completed => 'Mark task as completed';

	/// en-US: 'Mark task as not completed'
	String get mark_not_completed => 'Mark task as not completed';

	/// en-US: 'View task details: {{title}}'
	String get view_task_details => 'View task details: {{title}}';

	/// en-US: 'Task actions'
	String get task_actions => 'Task actions';

	/// en-US: 'Edit'
	String get edit => 'Edit';

	/// en-US: 'To do'
	String get status_todo => 'To do';

	/// en-US: 'Paused'
	String get status_paused => 'Paused';

	/// en-US: 'In progress'
	String get status_in_progress => 'In progress';

	/// en-US: 'Completed'
	String get status_done => 'Completed';

	/// en-US: 'Programming'
	String get area_programming => 'Programming';

	/// en-US: 'Art'
	String get area_art => 'Art';

	/// en-US: 'Audio'
	String get area_audio => 'Audio';

	/// en-US: 'Design'
	String get area_design => 'Design';

	/// en-US: 'Narrative'
	String get area_narrative => 'Narrative';

	/// en-US: 'Other'
	String get area_other => 'Other';

	/// en-US: 'Edit task'
	String get edit_task => 'Edit task';

	/// en-US: 'Title'
	String get title => 'Title';

	/// en-US: 'E.g.: Create main menu'
	String get title_placeholder => 'E.g.: Create main menu';

	/// en-US: 'Add more details about what needs to be done...'
	String get description_placeholder => 'Add more details about what needs to be done...';

	/// en-US: 'No due date'
	String get no_due_date => 'No due date';

	/// en-US: 'Remove due date'
	String get remove_due_date => 'Remove due date';

	/// en-US: 'This due date has passed'
	String get past_due_date => 'This due date has passed';

	/// en-US: 'Could not save the task. Try again.'
	String get save_task_failed => 'Could not save the task. Try again.';

	/// en-US: 'Add task'
	String get add_task => 'Add task';

	/// en-US: 'No description'
	String get no_description => 'No description';

	/// en-US: 'Tomorrow'
	String get tomorrow => 'Tomorrow';

	/// en-US: '(one) {Due in ${count} day} (other) {Due in ${count} days}'
	String due_in_days({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Due in ${count} day',
		other: 'Due in ${count} days',
	);

	/// en-US: 'Due in {{count}} day'
	String get due_in_days_one => 'Due in {{count}} day';

	/// en-US: 'Due in {{count}} days'
	String get due_in_days_other => 'Due in {{count}} days';

	/// en-US: 'Was due yesterday'
	String get overdue_yesterday => 'Was due yesterday';

	/// en-US: '(one) {Overdue by ${count} day} (other) {Overdue by ${count} days}'
	String overdue_days({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Overdue by ${count} day',
		other: 'Overdue by ${count} days',
	);

	/// en-US: 'Overdue by {{count}} day'
	String get overdue_days_one => 'Overdue by {{count}} day';

	/// en-US: 'Overdue by {{count}} days'
	String get overdue_days_other => 'Overdue by {{count}} days';

	/// en-US: 'Scan code'
	String get scan_code => 'Scan code';

	/// en-US: 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed'
	String get scan_code_hint => 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed';

	/// en-US: 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened'
	String get comment_scan_summary => 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened';

	/// en-US: 'Code scan found no changes'
	String get comment_scan_none => 'Code scan found no changes';

	/// en-US: '(one) {Completed ${count} to-do from a commit message} (other) {Completed ${count} to-dos from commit messages}'
	String commit_closed({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Completed ${count} to-do from a commit message',
		other: 'Completed ${count} to-dos from commit messages',
	);

	/// en-US: 'Completed {{count}} to-do from a commit message'
	String get commit_closed_one => 'Completed {{count}} to-do from a commit message';

	/// en-US: 'Completed {{count}} to-dos from commit messages'
	String get commit_closed_other => 'Completed {{count}} to-dos from commit messages';

	/// en-US: 'Linked file'
	String get linked_file => 'Linked file';

	/// en-US: 'res://scenes/player.tscn'
	String get linked_file_placeholder => 'res://scenes/player.tscn';

	/// en-US: 'Link a scene, script or resource from this project.'
	String get linked_file_hint => 'Link a scene, script or resource from this project.';

	/// en-US: 'Use a res:// path from this project.'
	String get linked_file_invalid => 'Use a res:// path from this project.';

	/// en-US: 'Open {{path}}'
	String get open_linked_file => 'Open {{path}}';

	/// en-US: 'Open'
	String get open_file => 'Open';

	/// en-US: 'Imported from a {{tag}} comment'
	String get source_comment => 'Imported from a {{tag}} comment';

	/// en-US: 'Completed by commit {{hash}}: {{subject}}'
	String get closed_by_commit => 'Completed by commit {{hash}}: {{subject}}';

	/// en-US: 'Completed because its comment was removed from the code'
	String get closed_by_comment_removed => 'Completed because its comment was removed from the code';

	/// en-US: 'Reference'
	String get todo_reference => 'Reference';

	/// en-US: 'Write "Fixes {{ref}}" in a commit message to complete it automatically.'
	String get todo_reference_hint => 'Write "Fixes {{ref}}" in a commit message to complete it automatically.';

	/// en-US: 'Looking through Git history…'
	String get git_activity_loading => 'Looking through Git history…';

	/// en-US: 'No commits or branches mention {{ref}} yet.'
	String get git_activity_empty => 'No commits or branches mention {{ref}} yet.';

	/// en-US: 'Branches'
	String get git_branches => 'Branches';

	/// en-US: 'Closes'
	String get git_commit_closes => 'Closes';

	/// en-US: 'Add a to-do and press Enter'
	String get quick_add_placeholder => 'Add a to-do and press Enter';

	/// en-US: 'Priority'
	String get priority => 'Priority';

	/// en-US: 'None'
	String get priority_none => 'None';

	/// en-US: 'Low'
	String get priority_low => 'Low';

	/// en-US: 'Medium'
	String get priority_medium => 'Medium';

	/// en-US: 'High'
	String get priority_high => 'High';

	/// en-US: '{{priority}} priority'
	String get priority_label => '{{priority}} priority';

	/// en-US: 'Checklist'
	String get checklist => 'Checklist';

	/// en-US: 'Add a checklist item and press Enter'
	String get checklist_add_placeholder => 'Add a checklist item and press Enter';

	/// en-US: 'Remove item'
	String get checklist_remove => 'Remove item';

	/// en-US: '{{done}} of {{total}} done'
	String get checklist_progress => '{{done}} of {{total}} done';

	/// en-US: 'Done {{date}}'
	String get completed_on => 'Done {{date}}';

	/// en-US: 'Completed {{date}}'
	String get completed_on_full => 'Completed {{date}}';

	/// en-US: 'Search to-dos…'
	String get search_tasks_placeholder => 'Search to-dos…';

	/// en-US: 'All areas'
	String get all_areas => 'All areas';

	/// en-US: 'No to-dos match your search.'
	String get no_matching_tasks => 'No to-dos match your search.';

	/// en-US: '(one) {${count} to-do} (other) {${count} to-dos}'
	String open_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} to-do',
		other: '${count} to-dos',
	);

	/// en-US: '{{count}} to-do'
	String get open_count_one => '{{count}} to-do';

	/// en-US: '{{count}} to-dos'
	String get open_count_other => '{{count}} to-dos';

	/// en-US: '(one) {${count} overdue} (other) {${count} overdue}'
	String overdue_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} overdue',
		other: '${count} overdue',
	);

	/// en-US: '{{count}} overdue'
	String get overdue_count_one => '{{count}} overdue';

	/// en-US: '{{count}} overdue'
	String get overdue_count_other => '{{count}} overdue';

	/// en-US: '{{overdue}} overdue · {{soon}} due this week'
	String get tile_summary => '{{overdue}} overdue · {{soon}} due this week';

	/// en-US: 'Nothing overdue or due this week.'
	String get tile_empty => 'Nothing overdue or due this week.';

	/// en-US: '(one) {To-do due: {{title}}} (other) {${count} to-dos are due}'
	String due_notification_title({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'To-do due: {{title}}',
		other: '${count} to-dos are due',
	);

	/// en-US: 'To-do due: {{title}}'
	String get due_notification_title_one => 'To-do due: {{title}}';

	/// en-US: '{{count}} to-dos are due'
	String get due_notification_title_other => '{{count}} to-dos are due';

	/// en-US: 'and {{count}} more'
	String get due_notification_more => 'and {{count}} more';
}

// Path: versions
class Translations$versions$en_US {
	Translations$versions$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Standard (GDScript)'
	String get standard => 'Standard (GDScript)';

	/// en-US: 'unbound'
	String get unbound => 'unbound';

	/// en-US: 'Mono (C#/.NET)'
	String get mono => 'Mono (C#/.NET)';

	/// en-US: 'Both'
	String get both => 'Both';

	/// en-US: 'Stable'
	String get stable => 'Stable';

	/// en-US: 'Unstable'
	String get unstable => 'Unstable';

	/// en-US: 'Rename'
	String get rename => 'Rename';

	/// en-US: 'Open Editor'
	String get open_editor => 'Open Editor';

	/// en-US: 'Open Editor with Console'
	String get open_editor_with_console => 'Open Editor with Console';

	/// en-US: 'More editor launch options'
	String get more_editor_launch_options => 'More editor launch options';

	/// en-US: 'Open Install Folder'
	String get open_install_folder => 'Open Install Folder';

	/// en-US: 'Type'
	String get type => 'Type';

	/// en-US: 'Channel'
	String get channel => 'Channel';

	/// en-US: 'Couldn't fetch available versions.'
	String get fetch_error => 'Couldn\'t fetch available versions.';

	/// en-US: 'Paused · '
	String get paused_dot => 'Paused · ';

	/// en-US: 'AVAILABLE VERSIONS'
	String get available_title => 'AVAILABLE VERSIONS';

	/// en-US: 'No installed versions match'
	String get no_versions_match => 'No installed versions match';

	/// en-US: 'No available versions match'
	String get no_available_versions_match => 'No available versions match';

	/// en-US: 'Open'
	String get open => 'Open';

	/// en-US: 'Install'
	String get install => 'Install';

	/// en-US: 'MB'
	String get mb => 'MB';

	/// en-US: 'Resume download'
	String get resume_download => 'Resume download';

	/// en-US: 'Pause download'
	String get pause_download => 'Pause download';

	/// en-US: 'Cancel download'
	String get cancel_download => 'Cancel download';

	/// en-US: '(one) {Installed} (other) {Installed}'
	String installed_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Installed',
		other: 'Installed',
	);

	/// en-US: 'Installed'
	String get installed_count_one => 'Installed';

	/// en-US: 'Installed'
	String get installed_count_other => 'Installed';

	/// en-US: 'Installed'
	String get installed_label => 'Installed';

	/// en-US: 'Original'
	String get original_name => 'Original';

	/// en-US: 'Source'
	String get source => 'Source';

	/// en-US: 'GitHub'
	String get source_github => 'GitHub';

	/// en-US: 'Godot Archive'
	String get source_archive => 'Godot Archive';

	/// en-US: 'mise'
	String get source_mise => 'mise';

	/// en-US: 'Switch to Godot Archive'
	String get switch_to_archive => 'Switch to Godot Archive';

	/// en-US: 'Latest'
	String get sort_version_latest => 'Latest';

	/// en-US: 'Oldest'
	String get sort_version_oldest => 'Oldest';

	/// en-US: 'Recently Installed'
	String get sort_version_recently_installed => 'Recently Installed';

	/// en-US: 'Oldest Installed'
	String get sort_version_oldest_installed => 'Oldest Installed';

	/// en-US: 'Set as Current'
	String get set_as_current => 'Set as Current';

	/// en-US: 'Unset Current'
	String get unset_current => 'Unset Current';

	/// en-US: 'Version Set as Current'
	String get current_set_title => 'Version Set as Current';

	/// en-US: 'Folder'
	String get current_dir_label => 'Folder';

	/// en-US: 'Copy'
	String get current_copy => 'Copy';

	/// en-US: 'Copied'
	String get current_copied => 'Copied';

	/// en-US: 'Copy alias path'
	String get current_copy_alias => 'Copy alias path';

	/// en-US: 'Copy folder path'
	String get current_copy_dir => 'Copy folder path';

	/// en-US: 'Open Alias Folder'
	String get current_open_folder => 'Open Alias Folder';

	/// en-US: 'Add the folder above to your PATH to run "Godot" from any terminal, script, or tool. The alias always follows the current version, so pinning another version or uninstalling this one updates it automatically.'
	String get current_path_hint => 'Add the folder above to your PATH to run "Godot" from any terminal, script, or tool. The alias always follows the current version, so pinning another version or uninstalling this one updates it automatically.';

	/// en-US: 'Windows symlinks need Developer Mode or admin rights, so a launcher script was created instead. It behaves the same from the command line.'
	String get current_shim_note => 'Windows symlinks need Developer Mode or admin rights, so a launcher script was created instead. It behaves the same from the command line.';

	/// en-US: 'mono'
	String get mono_short => 'mono';

	/// en-US: 'Aliases'
	String get aliases_manage => 'Aliases';

	/// en-US: 'Version Aliases'
	String get aliases_title => 'Version Aliases';

	/// en-US: 'No aliases yet. Pick a version above, give the command a name, and it will appear in the aliases folder.'
	String get aliases_empty => 'No aliases yet. Pick a version above, give the command a name, and it will appear in the aliases folder.';

	/// en-US: 'Install a Godot version first to create an alias.'
	String get aliases_no_versions => 'Install a Godot version first to create an alias.';

	/// en-US: 'Add the aliases folder to your PATH to run these names from any terminal or tool. The "Godot" command from the current version pin lives in the same folder.'
	String get aliases_path_hint => 'Add the aliases folder to your PATH to run these names from any terminal or tool. The "Godot" command from the current version pin lives in the same folder.';

	/// en-US: 'Create Alias'
	String get alias_create => 'Create Alias';

	/// en-US: 'Add Alias'
	String get alias_add => 'Add Alias';

	/// en-US: 'Alias name'
	String get alias_name_label => 'Alias name';

	/// en-US: 'godot-mono'
	String get alias_name_placeholder => 'godot-mono';

	/// en-US: 'Copy alias path'
	String get alias_copy_path => 'Copy alias path';

	/// en-US: 'script'
	String get alias_shim_badge => 'script';

	/// en-US: 'Mono builds load GodotSharp from the folder next to the executable, so on Windows the alias is created as a launcher script instead of a link.'
	String get alias_mono_script_note => 'Mono builds load GodotSharp from the folder next to the executable, so on Windows the alias is created as a launcher script instead of a link.';

	/// en-US: '(one) {Create Alias} (other) {Create ${count} Aliases}'
	String alias_create_all({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: 'Create Alias',
		other: 'Create ${count} Aliases',
	);

	/// en-US: 'Create Alias'
	String get alias_create_all_one => 'Create Alias';

	/// en-US: 'Create {{count}} Aliases'
	String get alias_create_all_other => 'Create {{count}} Aliases';

	/// en-US: '(one) {1 alias created} (other) {${count} aliases created}'
	String aliases_batch_created({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '1 alias created',
		other: '${count} aliases created',
	);

	/// en-US: '1 alias created'
	String get aliases_batch_created_one => '1 alias created';

	/// en-US: '{{count}} aliases created'
	String get aliases_batch_created_other => '{{count}} aliases created';

	/// en-US: '(one) {1 alias skipped} (other) {${count} aliases skipped}'
	String aliases_batch_skipped({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '1 alias skipped',
		other: '${count} aliases skipped',
	);

	/// en-US: '1 alias skipped'
	String get aliases_batch_skipped_one => '1 alias skipped';

	/// en-US: '{{count}} aliases skipped'
	String get aliases_batch_skipped_other => '{{count}} aliases skipped';

	/// en-US: '"{{name}}" is already in the list'
	String get alias_queue_duplicate => '"{{name}}" is already in the list';

	/// en-US: 'Remove alias'
	String get alias_remove => 'Remove alias';

	/// en-US: 'Remove this alias?'
	String get alias_remove_title => 'Remove this alias?';

	/// en-US: 'The command "{{name}}" will stop working. The Godot version itself stays installed.'
	String get alias_remove_desc => 'The command "{{name}}" will stop working. The Godot version itself stays installed.';

	/// en-US: 'mise'
	String get managed_by_mise => 'mise';

	/// en-US: 'Installing with mise…'
	String get mise_installing => 'Installing with mise…';

	/// en-US: 'Sync'
	String get mise_sync => 'Sync';

	/// en-US: 'Import the Godot versions mise has installed so they show up here.'
	String get mise_sync_title => 'Import the Godot versions mise has installed so they show up here.';

	/// en-US: 'mise not found'
	String get mise_missing => 'mise not found';

	/// en-US: 'mise will uninstall {{tag}} from its own store. Projects that pin it in mise.toml will need it installed again.'
	String get mise_uninstall_desc => 'mise will uninstall {{tag}} from its own store. Projects that pin it in mise.toml will need it installed again.';

	/// en-US: 'Templates'
	String get export_templates_installed => 'Templates';

	/// en-US: 'No templates'
	String get export_templates_missing => 'No templates';

	/// en-US: 'Install export templates'
	String get export_templates_install => 'Install export templates';

	/// en-US: 'Remove export templates'
	String get export_templates_remove => 'Remove export templates';

	/// en-US: 'Remove export templates?'
	String get export_templates_remove_title => 'Remove export templates?';

	/// en-US: 'The export templates for {{tag}} will be deleted from disk. You can download them again later.'
	String get export_templates_remove_desc => 'The export templates for {{tag}} will be deleted from disk. You can download them again later.';

	/// en-US: 'Remove'
	String get export_templates_remove_confirm => 'Remove';

	/// en-US: 'Open templates folder'
	String get export_templates_open_folder => 'Open templates folder';

	/// en-US: 'Templates folder'
	String get templates_folder => 'Templates folder';

	/// en-US: 'Versions folder'
	String get versions_folder => 'Versions folder';

	/// en-US: 'Export templates installed for {{tag}}'
	String get export_templates_installed_toast => 'Export templates installed for {{tag}}';

	/// en-US: 'Couldn't install export templates: {{error}}'
	String get export_templates_install_failed => 'Couldn\'t install export templates: {{error}}';

	/// en-US: 'Export templates removed'
	String get export_templates_removed_toast => 'Export templates removed';

	/// en-US: 'Unused template folders'
	String get export_templates_orphans_title => 'Unused template folders';

	/// en-US: 'These folders don't match a Godot version managed by GodotHub.'
	String get export_templates_orphans_desc => 'These folders don\'t match a Godot version managed by GodotHub.';

	/// en-US: 'Delete folder'
	String get export_templates_orphan_delete => 'Delete folder';

	/// en-US: 'Delete this template folder?'
	String get export_templates_orphan_delete_title => 'Delete this template folder?';

	/// en-US: '"{{folder}}" will be deleted from disk.'
	String get export_templates_orphan_delete_desc => '"{{folder}}" will be deleted from disk.';

	/// en-US: 'Template folder deleted'
	String get export_templates_orphan_deleted => 'Template folder deleted';

	/// en-US: 'Choose export templates'
	String get export_templates_choose => 'Choose export templates';

	/// en-US: '(one) {1 template selected} (other) {${count} templates selected}'
	String export_templates_selected({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '1 template selected',
		other: '${count} templates selected',
	);

	/// en-US: '1 template selected'
	String get export_templates_selected_one => '1 template selected';

	/// en-US: '{{count}} templates selected'
	String get export_templates_selected_other => '{{count}} templates selected';

	/// en-US: '~{{download}} download · {{installed}} on disk'
	String get export_templates_size_summary => '~{{download}} download · {{installed}} on disk';

	/// en-US: 'Download selected'
	String get export_templates_download_selected => 'Download selected';

	/// en-US: 'Checking this release's available templates…'
	String get export_templates_loading_options => 'Checking this release\'s available templates…';

	/// en-US: 'Couldn't load the templates for this release.'
	String get export_templates_options_failed => 'Couldn\'t load the templates for this release.';

	/// en-US: '(one) {1 available template group} (other) {${count} available template groups}'
	String export_templates_available({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '1 available template group',
		other: '${count} available template groups',
	);

	/// en-US: '1 available template group'
	String get export_templates_available_one => '1 available template group';

	/// en-US: '{{count}} available template groups'
	String get export_templates_available_other => '{{count}} available template groups';

	/// en-US: 'Select all'
	String get export_templates_select_all => 'Select all';

	/// en-US: '(one) {1 template file} (other) {${count} template files}'
	String export_templates_files({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '1 template file',
		other: '${count} template files',
	);

	/// en-US: '1 template file'
	String get export_templates_files_one => '1 template file';

	/// en-US: '{{count}} template files'
	String get export_templates_files_other => '{{count}} template files';

	/// en-US: 'Installed'
	String get export_templates_option_installed => 'Installed';

	/// en-US: 'Expand a platform to choose architectures or individual files. Only selected files are downloaded. Your existing templates are kept.'
	String get export_templates_keep_existing => 'Expand a platform to choose architectures or individual files. Only selected files are downloaded. Your existing templates are kept.';

	/// en-US: 'Uninstall {{name}}'
	String get export_templates_uninstall_named => 'Uninstall {{name}}';

	/// en-US: 'Couldn't uninstall templates: {{error}}'
	String get export_templates_uninstall_failed => 'Couldn\'t uninstall templates: {{error}}';

	/// en-US: 'Desktop'
	String get export_templates_category_desktop => 'Desktop';

	/// en-US: 'Mobile'
	String get export_templates_category_mobile => 'Mobile';

	/// en-US: 'Web'
	String get export_templates_category_web => 'Web';

	/// en-US: 'Common'
	String get export_templates_category_common => 'Common';

	/// en-US: 'Other'
	String get export_templates_category_other => 'Other';

	/// en-US: 'Web'
	String get export_templates_web_standard => 'Web';

	/// en-US: 'Web with Extensions'
	String get export_templates_web_extensions => 'Web with Extensions';

	/// en-US: 'Web Single-Threaded'
	String get export_templates_web_single_threaded => 'Web Single-Threaded';

	/// en-US: 'Web with Extensions Single-Threaded'
	String get export_templates_web_extensions_single_threaded => 'Web with Extensions Single-Threaded';

	/// en-US: 'Refresh available templates'
	String get export_templates_refresh => 'Refresh available templates';

	/// en-US: 'Download failed'
	String get download_failed_title => 'Download failed';

	/// en-US: 'File'
	String get download_failed_asset_label => 'File';

	/// en-US: 'Error details'
	String get download_failed_error_label => 'Error details';

	/// en-US: 'Copy details'
	String get download_failed_copy => 'Copy details';

	/// en-US: 'Common causes: a blocked network or proxy, antivirus blocking the download, a missing or read-only download folder, or low disk space.'
	String get download_failed_hint => 'Common causes: a blocked network or proxy, antivirus blocking the download, a missing or read-only download folder, or low disk space.';

	/// en-US: 'Custom build'
	String get custom_build_badge => 'Custom build';

	/// en-US: 'Add custom build…'
	String get add_custom_build => 'Add custom build…';

	/// en-US: 'Adding custom build…'
	String get adding_custom_build => 'Adding custom build…';
}

// Path: common.project_doctor
class Translations$common$project_doctor$en_US {
	Translations$common$project_doctor$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Project Doctor'
	String get title => 'Project Doctor';

	/// en-US: 'Checking this project…'
	String get scanning => 'Checking this project…';

	/// en-US: 'Could not check this project'
	String get scan_failed => 'Could not check this project';

	/// en-US: 'Run checks again'
	String get run_again => 'Run checks again';

	/// en-US: '(one) {${count} issue needs attention} (other) {${count} issues need attention}'
	String summary_errors({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} issue needs attention',
		other: '${count} issues need attention',
	);

	/// en-US: '{{count}} issue needs attention'
	String get summary_errors_one => '{{count}} issue needs attention';

	/// en-US: '{{count}} issues need attention'
	String get summary_errors_other => '{{count}} issues need attention';

	/// en-US: '(one) {${count} warning to review} (other) {${count} warnings to review}'
	String summary_warnings({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} warning to review',
		other: '${count} warnings to review',
	);

	/// en-US: '{{count}} warning to review'
	String get summary_warnings_one => '{{count}} warning to review';

	/// en-US: '{{count}} warnings to review'
	String get summary_warnings_other => '{{count}} warnings to review';

	/// en-US: 'No blocking issues found'
	String get summary_ready => 'No blocking issues found';

	/// en-US: '{{passed}} checks passed · {{findings}} findings'
	String get summary_counts => '{{passed}} checks passed · {{findings}} findings';

	/// en-US: '(one) {${count} passed check} (other) {${count} passed checks}'
	String passed_checks({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} passed check',
		other: '${count} passed checks',
	);

	/// en-US: '{{count}} passed check'
	String get passed_checks_one => '{{count}} passed check';

	/// en-US: '{{count}} passed checks'
	String get passed_checks_other => '{{count}} passed checks';

	/// en-US: 'Checks run locally. Fixes to settings save a backup first.'
	String get local_checks => 'Checks run locally. Fixes to settings save a backup first.';

	/// en-US: 'Fix applied. Project checks updated.'
	String get fix_complete => 'Fix applied. Project checks updated.';

	/// en-US: 'Downloading selected templates. Progress and cancellation are also available in Tasks.'
	String get templates_downloading => 'Downloading selected templates. Progress and cancellation are also available in Tasks.';

	/// en-US: 'Engine download queued. Follow its progress in Tasks.'
	String get version_queued => 'Engine download queued. Follow its progress in Tasks.';

	/// en-US: 'Download queued'
	String get version_queued_short => 'Download queued';

	/// en-US: 'No matching download was found for this version and platform. Open Versions to install or locate the engine.'
	String get version_asset_unavailable => 'No matching download was found for this version and platform. Open Versions to install or locate the engine.';

	/// en-US: 'Passed'
	String get severity_ok => 'Passed';

	/// en-US: 'Note'
	String get severity_info => 'Note';

	/// en-US: 'Warning'
	String get severity_warning => 'Warning';

	/// en-US: 'Needs attention'
	String get severity_error => 'Needs attention';

	/// en-US: 'Engine and compatibility'
	String get category_engine => 'Engine and compatibility';

	/// en-US: 'Export templates'
	String get category_templates => 'Export templates';

	/// en-US: 'Import cache'
	String get category_cache => 'Import cache';

	/// en-US: 'Main scene'
	String get category_scenes => 'Main scene';

	/// en-US: 'Editor addons'
	String get category_addons => 'Editor addons';

	/// en-US: 'Version control'
	String get category_git => 'Version control';

	/// en-US: 'Export presets'
	String get category_exports => 'Export presets';

	/// en-US: 'Project registration'
	String get category_registrations => 'Project registration';

	/// en-US: 'Choose installed version'
	String get action_choose_version => 'Choose installed version';

	/// en-US: 'Install bound version'
	String get action_install_version => 'Install bound version';

	/// en-US: 'Manage engine versions'
	String get action_manage_versions => 'Manage engine versions';

	/// en-US: 'Choose export templates'
	String get action_templates => 'Choose export templates';

	/// en-US: 'Move cache to Trash'
	String get action_clear_cache => 'Move cache to Trash';

	/// en-US: 'Remove missing addon entry'
	String get action_disable_addon => 'Remove missing addon entry';

	/// en-US: 'Enable addon'
	String get action_enable_addon => 'Enable addon';

	/// en-US: 'Add ignore rules'
	String get action_add_ignores => 'Add ignore rules';

	/// en-US: 'Stop tracking local metadata'
	String get action_untrack_metadata => 'Stop tracking local metadata';

	/// en-US: 'Track file with Git LFS'
	String get action_track_lfs => 'Track file with Git LFS';

	/// en-US: 'Remove registration'
	String get action_remove_registration => 'Remove registration';

	/// en-US: 'Open in Godot'
	String get action_open_editor => 'Open in Godot';

	/// en-US: 'Review export presets in IDE'
	String get action_open_presets => 'Review export presets in IDE';

	/// en-US: 'Review addons in IDE'
	String get action_open_addons => 'Review addons in IDE';

	/// en-US: 'Move this project's .godot folder to the system Trash? Close the project in Godot first. Godot will reimport assets and rebuild editor state the next time it opens.'
	String get confirm_clear_cache => 'Move this project\'s .godot folder to the system Trash? Close the project in Godot first. Godot will reimport assets and rebuild editor state the next time it opens.';

	/// en-US: 'Enable this editor addon? Its script will run the next time you open the project in Godot. A backup of project.godot is saved first.'
	String get confirm_enable_addon => 'Enable this editor addon? Its script will run the next time you open the project in Godot. A backup of project.godot is saved first.';

	/// en-US: 'Remove .godothub.json from Git's index while keeping your local file? This stages its removal for your next commit. Existing commits and history stay unchanged.'
	String get confirm_untrack_metadata => 'Remove .godothub.json from Git\'s index while keeping your local file? This stages its removal for your next commit. Existing commits and history stay unchanged.';

	/// en-US: 'Add a Git LFS rule for this file? Git LFS must be installed. This changes .gitattributes; re-add the file in Git to convert its next revision. Existing history stays unchanged.'
	String get confirm_track_lfs => 'Add a Git LFS rule for this file? Git LFS must be installed. This changes .gitattributes; re-add the file in Git to convert its next revision. Existing history stays unchanged.';

	/// en-US: 'Remove this library registration? Project files stay on disk. The registry is backed up first, and you can import the folder again.'
	String get confirm_remove_registration => 'Remove this library registration? Project files stay on disk. The registry is backed up first, and you can import the folder again.';

	/// en-US: 'No engine version is bound'
	String get version_unbound_title => 'No engine version is bound';

	/// en-US: 'Choose an installed engine to open and run this project.'
	String get version_unbound_description => 'Choose an installed engine to open and run this project.';

	/// en-US: 'The bound engine is not installed'
	String get version_missing_title => 'The bound engine is not installed';

	/// en-US: 'This project is bound to {{version}}, but that version is absent from the installed engine registry.'
	String get version_missing_description => 'This project is bound to {{version}}, but that version is absent from the installed engine registry.';

	/// en-US: 'The engine executable is missing'
	String get version_executable_missing_title => 'The engine executable is missing';

	/// en-US: '{{version}} is registered, but its executable is no longer on disk. Locate or reinstall it in Versions.'
	String get version_executable_missing_description => '{{version}} is registered, but its executable is no longer on disk. Locate or reinstall it in Versions.';

	/// en-US: 'The bound engine is available'
	String get version_ready_title => 'The bound engine is available';

	/// en-US: '{{version}} is installed and its executable exists.'
	String get version_ready_description => '{{version}} is installed and its executable exists.';

	/// en-US: 'The project format is incompatible'
	String get format_incompatible_title => 'The project format is incompatible';

	/// en-US: 'config_version={{format}} cannot be opened by the bound {{version}} engine. Choose a compatible engine and use Godot's migration tools if needed.'
	String get format_incompatible_description => 'config_version={{format}} cannot be opened by the bound {{version}} engine. Choose a compatible engine and use Godot\'s migration tools if needed.';

	/// en-US: 'The project and engine use different Godot generations'
	String get major_mismatch_title => 'The project and engine use different Godot generations';

	/// en-US: 'This project records a Godot {{major}} format but is bound to {{version}}. Choose a matching engine or migrate the project in Godot.'
	String get major_mismatch_description => 'This project records a Godot {{major}} format but is bound to {{version}}. Choose a matching engine or migrate the project in Godot.';

	/// en-US: 'The recorded project version differs from its engine'
	String get feature_mismatch_title => 'The recorded project version differs from its engine';

	/// en-US: 'The project records Godot {{recorded}} features but is bound to {{version}}. Match the binding or open it in the intended engine and review its upgrade changes.'
	String get feature_mismatch_description => 'The project records Godot {{recorded}} features but is bound to {{version}}. Match the binding or open it in the intended engine and review its upgrade changes.';

	/// en-US: 'The project version could not be confirmed'
	String get format_unknown_title => 'The project version could not be confirmed';

	/// en-US: 'The project format or engine version is missing or unrecognized. Review project.godot before changing engine generations.'
	String get format_unknown_description => 'The project format or engine version is missing or unrecognized. Review project.godot before changing engine generations.';

	/// en-US: 'The recorded format matches the bound engine'
	String get format_ready_title => 'The recorded format matches the bound engine';

	/// en-US: 'The project format and recorded Godot feature version are compatible with this binding.'
	String get format_ready_description => 'The project format and recorded Godot feature version are compatible with this binding.';

	/// en-US: 'Export templates are missing'
	String get templates_missing_title => 'Export templates are missing';

	/// en-US: 'Some export targets have no installed templates'
	String get templates_platforms_missing_title => 'Some export targets have no installed templates';

	/// en-US: 'These platforms appear in your export presets but have no templates installed for the bound engine. Choose the template files you need.'
	String get templates_platforms_missing_description => 'These platforms appear in your export presets but have no templates installed for the bound engine. Choose the template files you need.';

	/// en-US: 'No installed export-template platform was found for {{version}}. Choose the platforms and files you need.'
	String get templates_missing_description => 'No installed export-template platform was found for {{version}}. Choose the platforms and files you need.';

	/// en-US: 'Export templates are available'
	String get templates_ready_title => 'Export templates are available';

	/// en-US: 'These platforms have installed templates for the bound engine. Open the chooser to review individual files.'
	String get templates_ready_description => 'These platforms have installed templates for the bound engine. Open the chooser to review individual files.';

	/// en-US: 'Install or bind the engine before checking templates'
	String get templates_unknown_title => 'Install or bind the engine before checking templates';

	/// en-US: 'Export templates must match the exact engine version, including standard or .NET builds.'
	String get templates_unknown_description => 'Export templates must match the exact engine version, including standard or .NET builds.';

	/// en-US: 'A main scene is configured'
	String get main_scene_ready_title => 'A main scene is configured';

	/// en-US: 'The project has an application/run/main_scene setting.'
	String get main_scene_ready_description => 'The project has an application/run/main_scene setting.';

	/// en-US: 'No main scene is configured'
	String get main_scene_missing_title => 'No main scene is configured';

	/// en-US: 'Open the project in Godot and choose a main scene in Project Settings before running the game.'
	String get main_scene_missing_description => 'Open the project in Godot and choose a main scene in Project Settings before running the game.';

	/// en-US: 'The main scene file is missing'
	String get main_scene_missing_file_title => 'The main scene file is missing';

	/// en-US: 'The configured scene path does not exist. Choose an existing main scene in Godot.'
	String get main_scene_missing_file_description => 'The configured scene path does not exist. Choose an existing main scene in Godot.';

	/// en-US: 'The import cache is within normal limits'
	String get cache_ready_title => 'The import cache is within normal limits';

	/// en-US: '{{size}} across {{files}} files. Last cache write: {{days}} days ago.'
	String get cache_ready_description => '{{size}} across {{files}} files. Last cache write: {{days}} days ago.';

	/// en-US: 'The import cache uses significant disk space'
	String get cache_large_title => 'The import cache uses significant disk space';

	/// en-US: '{{size}} across {{files}} files. Large projects can need a large cache; clearing it causes a full reimport.'
	String get cache_large_description => '{{size}} across {{files}} files. Large projects can need a large cache; clearing it causes a full reimport.';

	/// en-US: 'The import cache has not changed recently'
	String get cache_stale_title => 'The import cache has not changed recently';

	/// en-US: '{{size}} across {{files}} files; last write was {{days}} days ago. Age alone does not mean the cache is broken.'
	String get cache_stale_description => '{{size}} across {{files}} files; last write was {{days}} days ago. Age alone does not mean the cache is broken.';

	/// en-US: 'The cache records a different engine executable'
	String get cache_version_title => 'The cache records a different engine executable';

	/// en-US: 'The editor cache was last associated with a different engine path. If imports misbehave, rebuild its {{size}} cache.'
	String get cache_version_description => 'The editor cache was last associated with a different engine path. If imports misbehave, rebuild its {{size}} cache.';

	/// en-US: 'The cache scan was incomplete'
	String get cache_partial_title => 'The cache scan was incomplete';

	/// en-US: 'At least {{size}} across {{files}} files. Some entries were unreadable or the scan reached its time or file limit.'
	String get cache_partial_description => 'At least {{size}} across {{files}} files. Some entries were unreadable or the scan reached its time or file limit.';

	/// en-US: 'No local .godot import cache'
	String get cache_absent_title => 'No local .godot import cache';

	/// en-US: 'Godot 4 creates this folder when the project opens. Godot 3 uses a different cache layout.'
	String get cache_absent_description => 'Godot 4 creates this folder when the project opens. Godot 3 uses a different cache layout.';

	/// en-US: 'An enabled editor addon is missing'
	String get addon_missing_title => 'An enabled editor addon is missing';

	/// en-US: 'This editor_plugins entry has no plugin.cfg on disk. Restore the addon or remove the stale enabled entry.'
	String get addon_missing_description => 'This editor_plugins entry has no plugin.cfg on disk. Restore the addon or remove the stale enabled entry.';

	/// en-US: 'An editor addon is present but disabled'
	String get addon_disabled_title => 'An editor addon is present but disabled';

	/// en-US: 'Its plugin.cfg is on disk but not listed in editor_plugins. This can be intentional. Enable it only if you want its editor functionality.'
	String get addon_disabled_description => 'Its plugin.cfg is on disk but not listed in editor_plugins. This can be intentional. Enable it only if you want its editor functionality.';

	/// en-US: 'An addon folder has no editor plugin configuration'
	String get addon_orphan_title => 'An addon folder has no editor plugin configuration';

	/// en-US: 'This folder is not an enabled editor addon. It may be a runtime library or leftover files; review it before removing anything.'
	String get addon_orphan_description => 'This folder is not an enabled editor addon. It may be a runtime library or leftover files; review it before removing anything.';

	/// en-US: 'Enabled editor addons exist on disk'
	String get addons_ready_title => 'Enabled editor addons exist on disk';

	/// en-US: 'No missing or disabled editor-plugin folders were found.'
	String get addons_ready_description => 'No missing or disabled editor-plugin folders were found.';

	/// en-US: 'No export presets configured'
	String get no_presets_title => 'No export presets configured';

	/// en-US: 'Create export presets in Godot when you are ready to package the project.'
	String get no_presets_description => 'Create export presets in Godot when you are ready to package the project.';

	/// en-US: 'Export presets could not be read'
	String get presets_unreadable_title => 'Export presets could not be read';

	/// en-US: 'Review export_presets.cfg and run the checks again.'
	String get presets_unreadable_description => 'Review export_presets.cfg and run the checks again.';

	/// en-US: 'Export resource paths exist'
	String get exports_ready_title => 'Export resource paths exist';

	/// en-US: 'Explicit res:// references in the export presets exist on disk. Wildcard filters and output paths are excluded from this check.'
	String get exports_ready_description => 'Explicit res:// references in the export presets exist on disk. Wildcard filters and output paths are excluded from this check.';

	/// en-US: 'Export presets reference missing resources'
	String get export_resources_missing_title => 'Export presets reference missing resources';

	/// en-US: 'Restore these files or update the references in Godot's export settings or export_presets.cfg.'
	String get export_resources_missing_description => 'Restore these files or update the references in Godot\'s export settings or export_presets.cfg.';

	/// en-US: 'Git checks were skipped'
	String get git_unavailable_title => 'Git checks were skipped';

	/// en-US: 'This folder is not in a Git repository, Git is unavailable, or the repository could not be inspected.'
	String get git_unavailable_description => 'This folder is not in a Git repository, Git is unavailable, or the repository could not be inspected.';

	/// en-US: 'Generated or local files are not ignored'
	String get ignore_missing_title => 'Generated or local files are not ignored';

	/// en-US: 'The effective Git ignore rules do not cover all of .godot/, .godothub/, and .godothub.json. Add project-local rules to keep them out of future commits.'
	String get ignore_missing_description => 'The effective Git ignore rules do not cover all of .godot/, .godothub/, and .godothub.json. Add project-local rules to keep them out of future commits.';

	/// en-US: 'Generated and local files are ignored'
	String get ignores_ready_title => 'Generated and local files are ignored';

	/// en-US: 'Git ignores the import cache and local GodotHub metadata.'
	String get ignores_ready_description => 'Git ignores the import cache and local GodotHub metadata.';

	/// en-US: 'Local GodotHub metadata is tracked by Git'
	String get metadata_tracked_title => 'Local GodotHub metadata is tracked by Git';

	/// en-US: '.godothub.json is in Git's index, so ignore rules alone will not keep it out of commits. Remove it from tracking while keeping the local file.'
	String get metadata_tracked_description => '.godothub.json is in Git\'s index, so ignore rules alone will not keep it out of commits. Remove it from tracking while keeping the local file.';

	/// en-US: 'Legacy local metadata is not tracked'
	String get metadata_private_title => 'Legacy local metadata is not tracked';

	/// en-US: '.godothub.json is absent from Git's tracked-file index.'
	String get metadata_private_description => '.godothub.json is absent from Git\'s tracked-file index.';

	/// en-US: 'No large binaries need a Git LFS rule'
	String get lfs_ready_title => 'No large binaries need a Git LFS rule';

	/// en-US: 'Scanned binary files of 50 MiB or more are ignored by Git or covered by an LFS filter rule. Existing commit history is not inspected.'
	String get lfs_ready_description => 'Scanned binary files of 50 MiB or more are ignored by Git or covered by an LFS filter rule. Existing commit history is not inspected.';

	/// en-US: 'Git LFS attributes could not be checked'
	String get lfs_unknown_title => 'Git LFS attributes could not be checked';

	/// en-US: 'Review the Git error below, then run the checks again.'
	String get lfs_unknown_description => 'Review the Git error below, then run the checks again.';

	/// en-US: 'A large binary has no Git LFS rule'
	String get binary_without_lfs_title => 'A large binary has no Git LFS rule';

	/// en-US: 'This binary is at least 50 MiB and is not ignored or covered by filter=lfs. Track it with LFS to keep future revisions out of regular Git blobs.'
	String get binary_without_lfs_description => 'This binary is at least 50 MiB and is not ignored or covered by filter=lfs. Track it with LFS to keep future revisions out of regular Git blobs.';

	/// en-US: 'The project file scan was incomplete'
	String get scan_partial_title => 'The project file scan was incomplete';

	/// en-US: 'Some paths were unreadable or the scan reached its 50,000-entry or five-second limit. Large-binary results may be incomplete.'
	String get scan_partial_description => 'Some paths were unreadable or the scan reached its 50,000-entry or five-second limit. Large-binary results may be incomplete.';

	/// en-US: 'This registration no longer points to a project'
	String get registration_stale_title => 'This registration no longer points to a project';

	/// en-US: 'No project.godot was found at this path. Reconnect moved or offline storage, or remove the stale library entry.'
	String get registration_stale_description => 'No project.godot was found at this path. Reconnect moved or offline storage, or remove the stale library entry.';

	/// en-US: 'Another registration points to this project'
	String get registration_duplicate_title => 'Another registration points to this project';

	/// en-US: 'This additional library entry resolves to the same project folder or a stale copy of its identity. Remove it to keep the current registration.'
	String get registration_duplicate_description => 'This additional library entry resolves to the same project folder or a stale copy of its identity. Remove it to keep the current registration.';

	/// en-US: 'No duplicate registrations found'
	String get registration_ready_title => 'No duplicate registrations found';

	/// en-US: 'This project has one valid folder registration in the active workspace.'
	String get registration_ready_description => 'This project has one valid folder registration in the active workspace.';

	/// en-US: 'Android'
	String get category_android => 'Android';

	/// en-US: 'This project exports to Android'
	String get android_targeted_title => 'This project exports to Android';

	/// en-US: 'An Android export preset or Gradle build template was found, so the Android toolchain is checked below.'
	String get android_targeted_description => 'An Android export preset or Gradle build template was found, so the Android toolchain is checked below.';

	/// en-US: 'This project may target mobile devices'
	String get android_possible_title => 'This project may target mobile devices';

	/// en-US: 'No Android export preset was found, but some settings suggest mobile use. Many desktop games also use the Mobile renderer, so the toolchain checks below are informational only.'
	String get android_possible_description => 'No Android export preset was found, but some settings suggest mobile use. Many desktop games also use the Mobile renderer, so the toolchain checks below are informational only.';

	/// en-US: 'Uses the Mobile renderer'
	String get hint_mobile_renderer => 'Uses the Mobile renderer';

	/// en-US: 'Sets a renderer override for mobile platforms'
	String get hint_mobile_renderer_override => 'Sets a renderer override for mobile platforms';

	/// en-US: 'Imports ETC2/ASTC textures, which Android requires'
	String get hint_etc2_astc => 'Imports ETC2/ASTC textures, which Android requires';

	/// en-US: 'Sets a handheld screen orientation'
	String get hint_orientation => 'Sets a handheld screen orientation';

	/// en-US: 'Emulates touch input from the mouse'
	String get hint_touch_emulation => 'Emulates touch input from the mouse';

	/// en-US: 'Has an android/plugins folder'
	String get hint_android_plugins => 'Has an android/plugins folder';

	/// en-US: 'Android SDK not found'
	String get android_sdk_missing_title => 'Android SDK not found';

	/// en-US: 'Set the Android SDK path in Godot under Editor Settings → Export → Android, or set ANDROID_HOME. Android exports need it.'
	String get android_sdk_missing_description => 'Set the Android SDK path in Godot under Editor Settings → Export → Android, or set ANDROID_HOME. Android exports need it.';

	/// en-US: 'The Android SDK is missing components'
	String get android_sdk_incomplete_title => 'The Android SDK is missing components';

	/// en-US: 'The SDK at {{path}} is missing the parts listed below. Install them with Android Studio's SDK Manager or sdkmanager.'
	String get android_sdk_incomplete_description => 'The SDK at {{path}} is missing the parts listed below. Install them with Android Studio\'s SDK Manager or sdkmanager.';

	/// en-US: 'The SDK folder does not exist'
	String get sdk_part_sdk_folder => 'The SDK folder does not exist';

	/// en-US: 'Platform Tools (adb)'
	String get sdk_part_platform_tools => 'Platform Tools (adb)';

	/// en-US: 'Build Tools'
	String get sdk_part_build_tools => 'Build Tools';

	/// en-US: 'Command-line Tools'
	String get sdk_part_cmdline_tools => 'Command-line Tools';

	/// en-US: 'Android SDK found'
	String get android_sdk_ready_title => 'Android SDK found';

	/// en-US: 'Using the SDK at {{path}}.'
	String get android_sdk_ready_description => 'Using the SDK at {{path}}.';

	/// en-US: 'Java JDK not found'
	String get android_jdk_missing_title => 'Java JDK not found';

	/// en-US: 'Android exports need JDK {{required}} or newer. Set it in Godot under Editor Settings → Export → Android, or set JAVA_HOME.'
	String get android_jdk_missing_description => 'Android exports need JDK {{required}} or newer. Set it in Godot under Editor Settings → Export → Android, or set JAVA_HOME.';

	/// en-US: 'The Java JDK path is invalid'
	String get android_jdk_invalid_title => 'The Java JDK path is invalid';

	/// en-US: 'No java executable was found in {{path}}. Point Godot to a JDK {{required}} installation.'
	String get android_jdk_invalid_description => 'No java executable was found in {{path}}. Point Godot to a JDK {{required}} installation.';

	/// en-US: 'The Java JDK is too old'
	String get android_jdk_old_title => 'The Java JDK is too old';

	/// en-US: 'JDK {{version}} is installed at {{path}}, but this Godot version needs JDK {{required}} or newer for Android exports.'
	String get android_jdk_old_description => 'JDK {{version}} is installed at {{path}}, but this Godot version needs JDK {{required}} or newer for Android exports.';

	/// en-US: 'Java JDK found'
	String get android_jdk_ready_title => 'Java JDK found';

	/// en-US: 'JDK {{version}} at {{path}}.'
	String get android_jdk_ready_description => 'JDK {{version}} at {{path}}.';

	/// en-US: 'The debug keystore file is missing'
	String get android_debug_keystore_missing_title => 'The debug keystore file is missing';

	/// en-US: 'Godot's editor settings point to a debug keystore that no longer exists. Clear the setting so Godot can create a new one, or pick another file.'
	String get android_debug_keystore_missing_description => 'Godot\'s editor settings point to a debug keystore that no longer exists. Clear the setting so Godot can create a new one, or pick another file.';

	/// en-US: 'The Android build template is not installed'
	String get android_gradle_template_missing_title => 'The Android build template is not installed';

	/// en-US: 'These presets use a Gradle build, but the project has no android/build folder. In Godot, choose Project → Install Android Build Template.'
	String get android_gradle_template_missing_description => 'These presets use a Gradle build, but the project has no android/build folder. In Godot, choose Project → Install Android Build Template.';

	/// en-US: 'A release keystore file is missing'
	String get android_release_keystore_missing_title => 'A release keystore file is missing';

	/// en-US: 'These presets point to a release keystore that does not exist. Release exports will fail until the path is fixed.'
	String get android_release_keystore_missing_description => 'These presets point to a release keystore that does not exist. Release exports will fail until the path is fixed.';

	/// en-US: 'No release keystore is set'
	String get android_release_keystore_unset_title => 'No release keystore is set';

	/// en-US: 'These presets can only make debug builds until a release keystore is set. You need one to publish on Google Play.'
	String get android_release_keystore_unset_description => 'These presets can only make debug builds until a release keystore is set. You need one to publish on Google Play.';
}

// Path: common.build_export
class Translations$common$build_export$en_US {
	Translations$common$build_export$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Build & Export'
	String get title => 'Build & Export';

	/// en-US: 'Ship a release build of {{name}} using its bound Godot version.'
	String get description => 'Ship a release build of {{name}} using its bound Godot version.';

	/// en-US: 'Reading export presets and checking release templates…'
	String get loading => 'Reading export presets and checking release templates…';

	/// en-US: 'Refresh presets'
	String get refresh => 'Refresh presets';

	/// en-US: 'Export preset'
	String get preset => 'Export preset';

	/// en-US: 'Choose an export preset'
	String get choose_preset => 'Choose an export preset';

	/// en-US: 'Output file'
	String get output => 'Output file';

	/// en-US: 'Choose output file'
	String get browse => 'Choose output file';

	/// en-US: 'Relative paths start at the project folder. Parent folders are created automatically. export_presets.cfg is kept unchanged.'
	String get output_hint => 'Relative paths start at the project folder. Parent folders are created automatically. export_presets.cfg is kept unchanged.';

	/// en-US: 'Release build'
	String get release => 'Release build';

	/// en-US: 'Godot {{version}}'
	String get engine => 'Godot {{version}}';

	/// en-US: 'Export release'
	String get start => 'Export release';

	/// en-US: 'Starting export…'
	String get starting => 'Starting export…';

	/// en-US: 'Install export templates'
	String get install_templates => 'Install export templates';

	/// en-US: 'Templates are missing for this preset. Godot validates debug and release templates before exporting.'
	String get missing_templates => 'Templates are missing for this preset. Godot validates debug and release templates before exporting.';

	/// en-US: 'Installing templates… Follow progress in Tasks.'
	String get downloading_templates => 'Installing templates… Follow progress in Tasks.';

	/// en-US: 'No export presets yet'
	String get no_presets => 'No export presets yet';

	/// en-US: 'Open Project → Export in Godot, add a preset, and save it. Refresh this list when it is ready.'
	String get no_presets_hint => 'Open Project → Export in Godot, add a preset, and save it. Refresh this list when it is ready.';

	/// en-US: 'Open in Godot'
	String get open_editor => 'Open in Godot';

	/// en-US: 'Open export console'
	String get open_console => 'Open export console';

	/// en-US: 'Cancel export'
	String get cancel_export => 'Cancel export';

	/// en-US: 'Exporting {{preset}}…'
	String get running => 'Exporting {{preset}}…';

	/// en-US: 'Export complete'
	String get succeeded => 'Export complete';

	/// en-US: 'Export failed'
	String get failed => 'Export failed';

	/// en-US: 'Export cancelled'
	String get cancelled => 'Export cancelled';

	/// en-US: 'Partial output files may remain in the output folder.'
	String get cancel_hint => 'Partial output files may remain in the output folder.';

	/// en-US: 'Open output folder'
	String get open_folder => 'Open output folder';

	/// en-US: 'Replace existing export?'
	String get overwrite_title => 'Replace existing export?';

	/// en-US: 'An output file already exists at {{path}}. Replace it with this export?'
	String get overwrite_description => 'An output file already exists at {{path}}. Replace it with this export?';

	/// en-US: 'Replace and export'
	String get overwrite => 'Replace and export';

	/// en-US: 'Output streams to its own console tab. Exporting does not change the project's play-time statistics.'
	String get run_hint => 'Output streams to its own console tab. Exporting does not change the project\'s play-time statistics.';

	/// en-US: 'Godot also requires the SDKs, signing settings and export options configured for your target platform.'
	String get platform_tools => 'Godot also requires the SDKs, signing settings and export options configured for your target platform.';

	/// en-US: 'Could not read export presets'
	String get scan_failed => 'Could not read export presets';

	/// en-US: 'Could not start export: {{error}}'
	String get start_failed => 'Could not start export: {{error}}';

	/// en-US: 'Tests and lint'
	String get tools_title => 'Tests and lint';

	/// en-US: 'No test framework found. Install GUT or gdUnit4 from the Asset Library to run tests here.'
	String get tools_no_tests => 'No test framework found. Install GUT or gdUnit4 from the Asset Library to run tests here.';

	/// en-US: 'Run'
	String get tool_run => 'Run';

	/// en-US: 'GUT tests'
	String get tool_gut => 'GUT tests';

	/// en-US: 'Runs your GUT tests headless with the bound Godot version.'
	String get tool_gut_hint => 'Runs your GUT tests headless with the bound Godot version.';

	/// en-US: 'gdUnit4 tests'
	String get tool_gdunit => 'gdUnit4 tests';

	/// en-US: 'Runs the gdUnit4 tests in {{target}} headless.'
	String get tool_gdunit_hint => 'Runs the gdUnit4 tests in {{target}} headless.';

	/// en-US: 'gdlint'
	String get tool_gdlint => 'gdlint';

	/// en-US: 'Lints GDScript outside addons: {{target}}'
	String get tool_gdlint_hint => 'Lints GDScript outside addons: {{target}}';

	/// en-US: 'gdformat check'
	String get tool_gdformat => 'gdformat check';

	/// en-US: 'Checks formatting without changing files: {{target}}'
	String get tool_gdformat_hint => 'Checks formatting without changing files: {{target}}';

	/// en-US: 'Install this project's Godot version to run tests.'
	String get tool_reason_engine_missing => 'Install this project\'s Godot version to run tests.';

	/// en-US: 'Add a test or tests folder for gdUnit4.'
	String get tool_reason_no_test_folder => 'Add a test or tests folder for gdUnit4.';

	/// en-US: 'Not found on PATH. Install it with: pip install gdtoolkit'
	String get tool_reason_not_installed => 'Not found on PATH. Install it with: pip install gdtoolkit';
}

// Path: common.project_addons
class Translations$common$project_addons$en_US {
	Translations$common$project_addons$en_US.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Addons'
	String get title => 'Addons';

	/// en-US: 'Reading addons…'
	String get loading => 'Reading addons…';

	/// en-US: '(one) {${count} addon installed} (other) {${count} addons installed}'
	String count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} addon installed',
		other: '${count} addons installed',
	);

	/// en-US: '{{count}} addon installed'
	String get count_one => '{{count}} addon installed';

	/// en-US: '{{count}} addons installed'
	String get count_other => '{{count}} addons installed';

	/// en-US: 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.'
	String get empty => 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.';

	/// en-US: 'Check for updates'
	String get check_updates => 'Check for updates';

	/// en-US: 'Checking…'
	String get checking => 'Checking…';

	/// en-US: '(one) {${count} update available} (other) {${count} updates available}'
	String updates_available({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count,
		one: '${count} update available',
		other: '${count} updates available',
	);

	/// en-US: '{{count}} update available'
	String get updates_available_one => '{{count}} update available';

	/// en-US: '{{count}} updates available'
	String get updates_available_other => '{{count}} updates available';

	/// en-US: 'No updates found in the Asset Library'
	String get all_current => 'No updates found in the Asset Library';

	/// en-US: 'Enabled'
	String get enabled => 'Enabled';

	/// en-US: 'Disabled'
	String get disabled => 'Disabled';

	/// en-US: 'Library'
	String get library => 'Library';

	/// en-US: 'Asset Library'
	String get from_library => 'Asset Library';

	/// en-US: 'Not found in the Asset Library'
	String get not_found => 'Not found in the Asset Library';

	/// en-US: 'Version {{version}} is available'
	String get update_to => 'Version {{version}} is available';

	/// en-US: 'Up to date ({{version}})'
	String get current => 'Up to date ({{version}})';

	/// en-US: 'matched by name to “{{title}}”'
	String get matched_by_name => 'matched by name to “{{title}}”';

	/// en-US: 'Update'
	String get update => 'Update';

	/// en-US: 'Updating…'
	String get updating => 'Updating…';

	/// en-US: '{{name}} was updated'
	String get updated => '{{name}} was updated';

	/// en-US: 'Update {{name}}?'
	String get confirm_title => 'Update {{name}}?';

	/// en-US: 'This replaces res://addons/{{folder}} with version {{version}} from the Asset Library. The old folder is moved to the Trash, so any changes you made to the addon are kept there. Close the project in Godot first.'
	String get confirm_description => 'This replaces res://addons/{{folder}} with version {{version}} from the Asset Library. The old folder is moved to the Trash, so any changes you made to the addon are kept there. Close the project in Godot first.';

	/// en-US: 'Addons installed through GodotHub are matched exactly. Others are matched by name, so check the result before updating.'
	String get footer_hint => 'Addons installed through GodotHub are matched exactly. Others are matched by name, so check the result before updating.';
}

/// The flat map containing all translations for locale <en-US>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'changelog.changelog_title' => 'CHANGELOG',
			'changelog.no_entries' => 'No changelog entries yet',
			'changelog.delete_entry_title' => 'Delete changelog entry?',
			'changelog.delete_entry_desc' => 'This removes the entry permanently. This can\'t be undone.',
			'changelog.changelog_subtitle' => 'A history of GodotHub updates.',
			'changelog.edit_entry_aria' => 'Edit {{version}}',
			'changelog.delete_entry_aria' => 'Delete {{version}}',
			'changelog.added' => 'Added',
			'changelog.fixed' => 'Fixed',
			'changelog.improved' => 'Improved',
			'common.new_project' => 'New Project',
			'common.import_project' => 'Import Project',
			'common.search' => 'Search',
			'common.cancel' => 'Cancel',
			'common.save' => 'Save',
			'common.delete' => 'Delete',
			'common.close' => 'Close',
			'common.loading' => 'Loading...',
			'common.retry' => 'Retry',
			'common.stop' => 'Stop',
			'common.refresh' => 'Refresh',
			'common.scroll_to_top' => 'Scroll to top',
			'common.quick_commands' => 'Quick Commands',
			'common.minimize' => 'Minimize',
			'common.close_sidebar' => 'Close Sidebar',
			'common.star_on_github' => 'Star on GitHub',
			'common.support_dev' => 'Support the Development on Patreon. You can toggle this off in Settings',
			'common.support' => 'Support',
			'common.restore' => 'Restore',
			'common.maximize' => 'Maximize',
			'common.importing_project' => 'Importing project…',
			'common.importing_version' => 'Importing version…',
			'common.scanning_projects' => 'Scanning for projects…',
			'common.scanning_versions' => 'Scanning for versions…',
			'common.queued' => 'Queued…',
			'common.download_queue_move_up' => 'Move earlier in queue',
			'common.download_queue_move_down' => 'Move later in queue',
			'common.running' => 'Running',
			'common.running_projects_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} project running', other: '${count} projects running', ), 
			'common.running_projects_desc_one' => '{{count}} project running',
			'common.running_projects_desc_other' => '{{count}} projects running',
			'common.active' => 'Active',
			'common.done' => 'Done',
			'common.paused' => 'Paused',
			'common.no_tasks_running' => 'No tasks running',
			'common.checking_changes' => 'Checking changes…',
			'common.cloning' => 'Cloning…',
			'common.clone_import' => 'Clone & Import',
			'common.import' => 'Import',
			'common.syncing' => 'Syncing…',
			'common.edit_entry' => 'Edit Changelog Entry',
			'common.new_entry' => 'New Changelog Entry',
			'common.checking_updates' => 'Checking for updates…',
			'common.up_to_date' => 'Up to date',
			'common.downloading_update' => 'Downloading…',
			'common.install_update' => 'Install',
			'common.restart_now' => 'Restart Now',
			'common.update_downloaded' => 'Update downloaded!',
			'common.restart_to_apply' => 'Restart GodotHub to apply the update.',
			'common.update_applied_desc' => 'The update has been downloaded and will be applied the next time you restart GodotHub. Please close and reopen the app to finish the update.',
			'common.is_latest' => 'v{{version}} is the latest version.',
			'common.percent_complete' => '{{percent}}% complete',
			'common.expand_sidebar' => 'Expand sidebar',
			'common.collapse_sidebar' => 'Collapse sidebar',
			'common.saving' => 'Saving…',
			'common.save_changes' => 'Save Changes',
			'common.add_entry' => 'Add Entry',
			'common.scan_for_projects' => 'Scan',
			'common.create_workspace' => 'Create Workspace',
			'common.report_a_bug' => 'Report a Bug',
			'common.report_bug' => 'Report Bug',
			'common.app_error_title' => 'Something went wrong',
			'common.app_error_desc' => 'GodotHub hit an unexpected error and couldn\'t render. Details below, check the console (right-click → Inspect) for the full stack trace.',
			'common.reload' => 'Reload',
			'common.view_error_title' => 'This view couldn\'t load',
			'common.view_error_desc' => 'The rest of GodotHub still works. Try loading this view again, or switch to another one.',
			'common.error_details' => 'Technical details',
			'common.remove_folder' => 'Remove folder',
			'common.make_this_default' => 'Make this the {{label}}',
			'common.suggested_from_workspaces' => 'Suggested from other workspaces',
			'common.from_workspace' => 'from {{name}}',
			'common.add_folder' => 'Add folder',
			'common.default_folder' => 'Default',
			'common.default_downloads_go_to' => 'Default Downloads will go to "{{path}}"',
			'common.open_terminal' => 'Open Terminal',
			'common.downloading_version' => 'Downloading {{version}}',
			'common.downloading_asset' => 'Downloading {{title}}',
			'common.asset_download_failed' => 'Template download failed',
			'common.scan_for_engines' => 'Scan for Engines',
			'common.import_version' => 'Import Version',
			'common.sync_templates_from_directory' => 'Sync Templates from Directory',
			'common.section_navigation' => 'Navigation',
			'common.section_projects' => 'Projects',
			'common.section_views' => 'Views',
			'common.section_workspaces' => 'Workspaces',
			'common.section_help' => 'Help',
			'common.section_engines' => 'Engines',
			'common.section_templates' => 'Templates',
			'common.section_versions' => 'Versions',
			'common.section_news' => 'News',
			'common.skip_setup' => 'Skip setup',
			'common.back' => 'Back',
			'common.finishing' => 'Finishing…',
			'common.get_started' => 'Get Started',
			'common.scanning' => 'Scanning…',
			'common.scan_now' => 'Scan Now',
			'common.scan_complete' => 'Scan complete',
			'common.scan_failed' => 'Scan failed',
			'common.uncategorized' => 'Uncategorized',
			'common.all' => 'All',
			'common.no_filter' => 'No Filter',
			'common.cannot_undo' => 'This cannot be undone.',
			'common.deleting' => 'Deleting…',
			'common.open_project' => 'Open',
			'common.play_project' => 'Play',
			'common.play_project_tooltip' => 'Play the game without opening editor',
			'common.no_version_selected' => 'No Version Selected',
			'common.open_with_console' => 'Open with Console',
			'common.open_folder' => 'Open Folder',
			'common.open_in_ide' => 'Open in IDE',
			'common.category' => 'Category',
			'common.none' => 'None',
			'common.project_size' => 'Project Size',
			'common.project_size_scanning' => 'Scanning project files…',
			'common.project_size_empty' => 'No files found',
			'common.launch_arguments' => 'Launch Arguments',
			'common.save_as_template' => 'Save as Template',
			'common.git' => 'Git',
			'common.add' => 'Add',
			'common.color_label' => 'Color',
			'common.icon_label' => 'Icon',
			'common.expand' => 'Expand',
			'common.collapse' => 'Collapse',
			'common.file_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} file', other: '${count} files', ), 
			'common.file_count_one' => '{{count}} file',
			'common.file_count_other' => '{{count}} files',
			'common.folder_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} folder', other: '${count} folders', ), 
			'common.folder_count_one' => '{{count}} folder',
			'common.folder_count_other' => '{{count}} folders',
			'common.template_empty' => 'This template is empty.',
			'common.categories' => 'Categories',
			'common.category_folders_hint' => 'Projects found in a category\'s folders are assigned to it automatically.',
			'common.assign_folder' => 'Assign folder',
			'common.assign_folder_to_category' => 'Assign a folder to {{name}}',
			'common.unassign_folder_aria' => 'Remove {{folder}} from this category',
			'common.new_category_placeholder' => 'New category name…',
			'common.no_categories_yet' => 'No categories yet, add one above.',
			'common.edit_category' => 'Edit {{name}}',
			'common.delete_category' => 'Delete {{name}}',
			'common.delete_category_title' => 'Delete category?',
			'common.delete_category_desc' => '"{{name}}" will be removed. Projects filed under it move to Uncategorized, nothing on disk is touched.',
			'common.project_name_label' => 'Name',
			'common.folder_name_preview' => 'Dir. Convention: {{name}}',
			'common.folder_name_hint' => 'Folder name is derived from the project name using your naming convention.',
			'common.template_preview_aria' => 'Preview {{name}}',
			'common.project_location_label' => 'Location',
			'common.choose_folder_placeholder' => 'Choose a folder',
			'common.browse' => 'Browse',
			'common.blank_template' => 'Default',
			'common.template_optional' => 'Template (optional)',
			'common.category_optional' => 'Category (optional)',
			'common.no_category_label' => 'No category',
			'common.godot_version_label' => 'Godot Version',
			'common.no_engine_warning' => 'No engine installed yet, grab one from the Versions tab first.',
			'common.change_icon' => 'Change',
			'common.choose_icon' => 'Choose',
			'common.icon_format_desc' => 'SVG, PNG, or JPG. Defaults to Godot logo.',
			'common.other_settings_label' => 'Other settings',
			'common.init_git_label' => 'Initialize Git repository',
			'common.init_git_desc' => 'Adds a Godot .gitignore and .gitattributes, then makes an initial commit on main.',
			'common.init_git_unavailable' => 'Install Git and restart GodotHub to use this.',
			'common.initializing_git' => 'Setting up Git…',
			'common.git_init_warning_title' => 'Project created, Git needs attention',
			'common.git_option_gitignore' => 'Godot .gitignore',
			'common.git_option_gitattributes' => '.gitattributes',
			'common.git_option_readme' => 'README.md',
			'common.git_option_license' => 'License',
			'common.git_option_no_license' => 'No license',
			'common.create_remote_label' => 'Create repository on GitHub/GitLab',
			'common.create_remote_desc' => 'Creates a repository on your connected account and pushes the initial commit.',
			'common.remote_private' => 'Private',
			'common.remote_public' => 'Public',
			'common.creating_remote_repo' => 'Creating remote repository…',
			'common.remote_repo_created_title' => 'Remote repository created',
			'common.create_project_done' => 'Done',
			'common.create_project_btn' => 'Create Project',
			'common.creating' => 'Creating…',
			'common.create_project_error' => 'Give the project a name and a folder to create it in.',
			'common.create_workspace_title' => 'New Workspace',
			'common.workspace_name_label' => 'Name',
			'common.workspace_name_placeholder' => 'Work, Personal, Game Jam…',
			'common.workspace_name_required_error' => 'Give the workspace a name.',
			'common.edit_workspace_title' => 'Edit Workspace',
			'common.cant_delete_only_workspace' => 'You can\'t delete your only workspace',
			'common.delete_workspace_title' => 'Delete workspace?',
			'common.delete_workspace_desc' => '"{{name}}" and everything scoped to it (its settings, projects, and categories) will be removed. Project files on disk are never touched. Installed Godot versions are shared and stay untouched.',
			'common.other' => 'Other',
			'common.args_label' => 'Arguments',
			'common.args_placeholder' => 'e.g. --debug --single-window',
			'common.args_suggestions' => 'Suggestions',
			'common.args_desc_separate_prefix' => 'Separate arguments with spaces. Flags with values like',
			'common.args_desc_separate_suffix' => 'use two tokens.',
			'common.args_debug' => '--debug',
			'common.args_debug_desc' => 'Run with debugger attached',
			'common.args_single_window' => '--single-window',
			'common.args_single_window_desc' => 'Force single window mode',
			'common.args_opengl3' => '--rendering-driver opengl3',
			'common.args_opengl3_desc' => 'Use OpenGL 3 rendering driver',
			'common.args_vulkan' => '--rendering-driver vulkan',
			'common.args_vulkan_desc' => 'Use Vulkan rendering driver',
			'common.args_headless' => '--headless',
			'common.args_headless_desc' => 'Run without a window',
			'common.args_verbose' => '--verbose',
			'common.args_verbose_desc' => 'Log detailed debug output',
			'common.args_editor' => '--editor',
			'common.args_editor_desc' => 'Open the editor (same as -e)',
			'common.args_build_solutions' => '--build-solutions',
			'common.args_build_solutions_desc' => 'Build C# solutions on open',
			'common.args_gpu_index' => '--gpu-index 1',
			'common.args_gpu_index_desc' => 'Use GPU index 1 (dedicated GPU)',
			'common.sort_categories' => 'Categories',
			'common.sort_recent' => 'Recently opened',
			'common.sort_manual' => 'Custom',
			'common.sort_name_asc' => 'Name (A–Z)',
			'common.sort_name_desc' => 'Name (Z–A)',
			'common.sort_created_desc' => 'Date added (newest)',
			'common.sort_created_asc' => 'Date added (oldest)',
			'common.sort_time_desc' => 'Total time',
			'common.filter' => 'Filter',
			'common.no_templates_yet' => 'No templates yet. Right-click a project or open its "More" menu and select <1>Save as Template</1> to create one or download them from the Asset Library.',
			'common.godot' => 'Godot',
			'common.delete_template' => 'Delete {{name}} template',
			'common.news_subtitle' => 'Latest posts from the official Godot Engine blog.',
			'common.news_cached' => 'Couldn\'t reach godotengine.org, showing the articles saved from last time.',
			'common.news_error' => 'Couldn\'t load Godot news.',
			'common.news_empty' => 'No news to show right now.',
			'common.show_more' => 'Show more',
			'common.try_again' => 'Try again',
			'common.asset_store_title' => 'ASSET STORE',
			'common.news_count' => 'Posts',
			'common.asset_store_count_plural' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Asset', other: 'Assets', ), 
			'common.asset_store_count_one' => 'Asset',
			'common.asset_store_count_other' => 'Assets',
			'common.asset_store_count' => 'Assets',
			'common.settings_title' => 'SETTINGS',
			'common.no_templates_match' => 'No templates match',
			'common.no_projects_match' => 'No projects match',
			'common.more_import_options' => 'More import options',
			'common.clone_import_repo' => 'Clone & Import from Repository',
			'common.manage_categories' => 'Manage Categories',
			'common.hide_category' => 'Hide Category',
			'common.category_hidden_toast' => '"{{name}}" hidden. Restore it from Hidden Categories.',
			'common.hidden_categories' => 'Hidden Categories',
			'common.hidden_categories_hint' => 'Those categories and their projects stay out of the way. Unhide one to bring it back.',
			'common.hidden_category_projects' => '{{count}} project(s)',
			'common.unhide' => 'Unhide',
			'common.unhide_category_aria' => 'Unhide {{name}}',
			'common.search_projects_placeholder' => 'Search projects...',
			'common.clear_search' => 'Clear search',
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
			'common.sort' => 'Sort',
			'common.view_list' => 'List',
			'common.view_grid' => 'Grid',
			'common.view_kanban' => 'Kanban',
			'common.no_projects_yet' => 'Nothing here yet. Create a new project or import one you already have on disk.',
			'common.pinned_section' => 'Pinned',
			'common.set_category' => 'Set category…',
			'common.clear_selection' => 'Clear selection',
			'common.starting' => 'Starting…',
			'common.app_loading' => 'Loading…',
			'common.changelog_version_label' => 'Version',
			'common.changelog_version_placeholder' => 'v1.0.0',
			'common.changelog_date_label' => 'Date',
			'common.changelog_date_placeholder' => '2026-07-13',
			'common.changelog_what_changed' => 'What changed',
			'common.changelog_add_line' => 'Add line',
			'common.changelog_remove_line_aria' => 'Remove line',
			'common.changelog_placeholder_note' => 'Added drag-and-drop project reordering',
			'common.changelog_error_no_version' => 'Give the entry a version.',
			'common.changelog_known_issues' => 'Known Issues',
			'common.changelog_known_issues_none' => 'No known issues for this version.',
			'common.changelog_known_issue_placeholder' => 'Describe the known issue...',
			'common.changelog_remove_known_issue_aria' => 'Remove known issue',
			'common.changelog_add_known_issue' => 'Add known issue',
			'common.changelog_generate_from_git' => 'Generate from Git',
			'common.changelog_draft_title' => 'Release notes from Git',
			'common.changelog_draft_from' => 'From',
			'common.changelog_draft_to' => 'To',
			'common.changelog_draft_generate' => 'Generate draft',
			'common.changelog_draft_use' => 'Use Draft',
			'common.changelog_draft_commits' => '{{count}} commit(s)',
			'common.changelog_draft_include' => 'Include in draft',
			'common.changelog_draft_none' => 'No commits found in this range.',
			'common.template_search_placeholder' => 'Search templates…',
			'common.template_delete_title' => 'Delete Template?',
			'common.template_delete_desc' => '"{{name}}" will be permanently removed.',
			'common.templates_tab_local' => 'Local Templates',
			'common.templates_tab_asset' => 'Asset Library',
			'common.asset_search_placeholder' => 'Search assets…',
			'common.asset_all_versions' => 'All versions',
			'common.asset_result_count' => '{{count}} results',
			'common.asset_load_error' => 'Couldn\'t load the Asset Library. Check your connection and try again.',
			'common.asset_no_results' => 'No assets found. Try a different search.',
			'common.asset_by_author' => 'by {{author}}',
			'common.asset_open_page' => 'Open in browser',
			'common.asset_install' => 'Install',
			'common.asset_install_inside' => 'Install Inside',
			'common.asset_installing' => 'Installing…',
			'common.asset_installed' => 'Installed',
			'common.asset_prev_page' => 'Previous page',
			'common.asset_next_page' => 'Next page',
			'common.asset_page_x_of_y' => 'Page {{page}} of {{total}}',
			'common.template_your_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Template', other: 'Templates', ), 
			'common.template_your_templates_one' => 'Template',
			'common.template_your_templates_other' => 'Templates',
			'common.template_imported_count' => 'Imported {{count}}',
			'common.template_updated_count' => 'Updated {{count}}',
			'common.template_removed_count' => 'Removed {{count}}',
			'common.asset_source_all' => 'All sources',
			'common.asset_source_library' => 'Old Asset Library',
			'common.asset_source_store' => 'New Asset Store',
			'common.asset_store_relevance' => 'Relevance',
			'common.asset_store_updated_new' => 'Newest updated',
			'common.asset_store_updated_old' => 'Oldest updated',
			'common.asset_store_rating_high' => 'Top rated',
			'common.asset_store_rating_low' => 'Lowest rated',
			'common.asset_download_outside' => 'Download Outside',
			'common.asset_downloaded' => 'Downloaded',
			'common.asset_downloaded_to' => 'Downloaded to',
			'common.asset_download_error' => 'Couldn\'t download the asset. Check your connection and try again.',
			'common.asset_install_modal_title' => 'Install {{title}}',
			'common.asset_install_tab_project' => 'Into project',
			'common.asset_install_tab_template' => 'Into template',
			'common.asset_install_search_projects' => 'Search projects…',
			'common.asset_install_no_projects' => 'No projects yet. Create or import one first.',
			'common.asset_install_no_templates' => 'No templates saved yet.',
			'common.asset_install_into' => 'Install into {{name}}',
			'common.asset_install_success_project' => 'Installed into {{target}}',
			'common.asset_install_success_template' => 'Added to template {{target}}',
			'common.asset_new_template_btn' => 'Save as new template',
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
			'common.onboarding_custom_category_placeholder' => 'Custom category name…',
			'common.onboarding_your_categories' => 'Your categories',
			'common.onboarding_customize_title' => 'Make it yours',
			'common.onboarding_customize_desc' => 'Pick a full theme preset, or choose Custom and set your own accent and background. Corner roundness, density, text size, and light/dark mode are all in Settings whenever you want to fine-tune further.',
			'common.onboarding_finish_title' => 'You\'re all set',
			'common.onboarding_finish_desc' => 'GodotHub is ready to go. You can revisit any of this, folders, categories, and appearance, from the Settings tab at any time.',
			'common.onboarding_setting_up_title' => 'Setting things up',
			'common.onboarding_setting_up_desc' => 'Setting up your library… scanning folders for projects and Godot versions. This only happens once, and it won\'t take long.',
			'common.skipped' => 'Skipped',
			'common.onboarding_continue' => 'Continue',
			'common.onboarding_accent_color' => 'Accent color',
			'common.onboarding_bg_color' => 'Background color',
			'common.onboarding_corner_radius' => 'Corner radius',
			'common.onboarding_discord_rpc' => 'Discord Rich Presence',
			'common.onboarding_discord_rpc_desc' => 'Show what you\'re doing in GodotHub on your Discord profile.',
			'common.version_search_placeholder' => 'Search versions…',
			'common.version_no_installed' => 'No versions installed. Download a version from below or drag and drop your existing version folder here.',
			'common.version_save_name_aria' => 'Save name',
			'common.version_rename_aria' => 'Rename version',
			'common.version_mono_badge' => '.NET',
			'common.version_uninstall_title' => 'Uninstall version?',
			'common.version_uninstall_desc' => '"{{tag}}" and its files will be moved to your system\'s Trash / Recycle Bin. You can reinstall it later if needed.',
			'common.version_uninstall_confirm' => 'Uninstall',
			'common.project_remove_title' => 'Remove from library?',
			'common.project_remove_desc' => '"{{name}}" will be removed from GodotHub\'s list. Its files stay on disk untouched, you can import it again anytime.',
			'common.project_delete_title' => 'Move to Trash?',
			'common.project_delete_desc' => '"{{name}}" and everything inside it will be moved to your system\'s Trash / Recycle Bin. You can restore it later if needed.',
			'common.project_delete_confirm' => 'Move to Trash',
			'common.project_template_name_label' => 'Template Name',
			'common.project_template_desc_label' => 'Description',
			'common.project_template_desc_placeholder' => 'What\'s in this template?',
			'common.project_save_template_btn' => 'Save Template',
			'common.template_saved_toast' => 'Template saved.',
			'common.project_select_aria' => 'Select project',
			'common.project_deselect_aria' => 'Deselect project',
			'common.select_all_visible' => 'Select all visible',
			'common.selected_count' => '{{count}} selected',
			'common.bulk_launch' => 'Launch',
			'common.bulk_pin' => 'Pin',
			'common.bulk_remove' => 'Remove',
			'common.bulk_remove_title' => 'Remove {{count}} projects from library?',
			'common.bulk_remove_desc' => 'The selected projects will be removed from your library. Their files will stay on disk.',
			'common.bulk_delete_title' => 'Delete {{count}} projects?',
			'common.bulk_delete_desc' => 'The selected project files will be permanently moved to the Trash. This cannot be undone.',
			'common.project_pin_aria' => 'Pin project',
			'common.project_unpin_aria' => 'Unpin project',
			'common.time_today' => 'Today',
			'common.time_this_week' => 'This week',
			'common.time_all_time' => 'All time',
			'common.time_tracked_title' => 'Time tracked',
			'common.time_weekly_chart' => 'Last 7 days',
			'common.time_week_total' => '{{total}} this week',
			'common.time_weekly_empty' => 'No tracked time in the last 7 days.',
			'common.project_more_aria' => 'More actions',
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
			'common.project_card_remove_library' => 'Remove from Library',
			'common.project_card_delete_files' => 'Delete Files',
			'common.manage_tags' => 'Manage Tags',
			'common.tag_input_placeholder' => 'New tag name…',
			'common.tag_already_exists' => 'A tag with this name already exists.',
			'common.tag_rename_hint' => 'Click to rename',
			'common.tag_rename_aria' => 'Rename tag',
			'common.show_more_tags' => 'Show more tags',
			'common.show_fewer_tags' => 'Show fewer tags',
			'common.clear_tag_filter' => 'Clear tag filter',
			'common.saving_tags' => 'Saving tags…',
			'common.tag_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} tag', other: '${count} tags', ), 
			'common.tag_count_one' => '{{count}} tag',
			'common.tag_count_other' => '{{count}} tags',
			'common.no_tags' => 'No tags yet',
			'common.bug_report_describe_label' => 'What happened?',
			'common.bug_report_describe_placeholder' => 'What were you doing when the bug appeared? Add steps to reproduce and what you expected vs. what actually happened.',
			'common.bug_report_diagnostics_label' => 'Diagnostic info',
			'common.bug_report_diagnostics_hint' => 'Auto-collected · included in the report',
			'common.bug_report_copied' => 'Copied!',
			'common.bug_report_copy_log' => 'Copy Report',
			'common.bug_report_download_log' => 'Download Report',
			'common.bug_report_open_github' => 'Create GitHub Issue',
			'common.check_updates_title_modal' => 'Check for Updates',
			'common.check_updates_version_available' => 'Version {{version}} available',
			'common.check_updates_ask_download' => 'Would you like to download and install it now?',
			'common.check_updates_release_notes' => 'Release Notes',
			'common.check_updates_failed' => 'Update check failed',
			'common.check_updates_rate_limited' => 'GitHub rate limit reached',
			'common.check_updates_token_rejected' => 'GitHub token rejected',
			'common.check_updates_rate_limited_hint' => 'GitHub only allows 60 anonymous requests per hour, shared with everyone on your network. Adding a personal access token in Settings raises this to 5,000 per hour and is also used for fetching Godot versions.',
			'common.check_updates_rate_limited_token_hint' => 'Your saved GitHub token was rejected. It may have expired or been revoked. Test it in Settings and replace it if needed.',
			'common.check_updates_add_token' => 'Add GitHub Token',
			'common.check_updates_open_token_settings' => 'Open Token Settings',
			'common.check_updates_portable_title' => 'Manual update required',
			'common.check_updates_portable_desc' => 'Portable installs cannot auto-update. Download the latest version from GitHub and replace the existing files.',
			'common.check_updates_download_from_github' => 'Download from GitHub',
			'common.check_updates_details' => 'Update details',
			'common.check_updates_log' => 'Log',
			'common.check_updates_released' => 'Released',
			'common.check_updates_source' => 'Source',
			'common.check_updates_file' => 'File',
			'common.check_updates_package' => 'Package',
			'common.check_updates_signature' => 'Signature',
			'common.check_updates_signature_checked' => 'Checked with minisign before installing',
			'common.check_updates_view_release' => 'View release on GitHub',
			'common.check_updates_progress_size' => '{{downloaded}} of {{total}}',
			'common.check_updates_speed' => '{{speed}}/s',
			'common.check_updates_time_left' => 'About {{time}} left',
			'common.check_updates_from_host' => 'From {{host}}',
			'common.check_updates_download_summary' => 'Downloaded {{size}} in {{time}}',
			'common.check_updates_signature_verified' => 'Signature verified',
			'common.clone_repo_title' => 'Clone Repository',
			'common.clone_repo_url_label' => 'Repository URL',
			'common.clone_repo_url_placeholder' => 'https://github.com/user/my-game.git',
			'common.clone_repo_error_url' => 'Please enter a repository URL.',
			'common.clone_repo_error_location' => 'Please choose where to clone the repository.',
			'common.clone_repo_open_after' => 'Open it right after importing',
			'common.clone_repo_browse_repos' => 'Browse Your Repos',
			'common.clone_repo_url_manual' => 'Paste URL Manually',
			'common.clone_repo_search_repos' => 'Search your repositories...',
			'common.clone_repo_no_repos_found' => 'No repositories match your search.',
			'common.clone_repo_loading_repos' => 'Loading repositories...',
			'common.clone_repo_load_error' => 'Failed to load repositories.',
			'common.clone_repo_select' => 'Select',
			'common.clone_repo_no_account' => 'No GitHub or GitLab account connected. Use a URL to clone instead.',
			'common.clone_repo_repos_loaded' => 'repos loaded',
			'common.load_more' => 'Load more',
			'common.git_uncommitted' => 'uncommitted',
			'common.git_clean' => 'clean',
			'common.task_tray_title' => 'Tasks',
			'common.task_tray_empty' => 'No active tasks',
			'common.task_tray_active_count' => '{{active}} active, {{recent}} recent',
			'common.task_tray_only_recent' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} recent task', other: '${count} recent tasks', ), 
			'common.task_tray_only_recent_one' => '{{count}} recent task',
			'common.task_tray_only_recent_other' => '{{count}} recent tasks',
			'common.task_tray_aria' => 'Task Tray',
			'common.task_tray_auto_dismiss' => 'Completed auto-dismiss',
			'common.task_tray_dismiss' => 'Dismiss {{count}}',
			'common.task_error_status' => 'Error',
			'common.command_palette_title' => 'Command Palette',
			'common.command_palette_placeholder' => 'Search commands, projects, engines, settings…',
			'common.command_palette_no_results' => 'No results match',
			'common.command_palette_navigate' => 'Navigate',
			'common.command_palette_escape' => 'Esc',
			'common.setting_token_placeholder' => 'ghp_xxxxxxxxxxxxxxxxxxxx',
			'common.setting_project_scan_dirs' => 'Scan Project Folders',
			_ => null,
		} ?? switch (path) {
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
			'common.setting_accent_color' => 'Accent Color',
			'common.setting_background_color' => 'Background Color',
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
			'common.current_workspace' => 'Current workspace',
			'common.switch_workspace' => 'Switch workspace',
			'common.opened_recently' => 'Opened {{label}}',
			'common.recent_section' => 'Recent',
			'common.installed_versions_section' => 'Installed Versions',
			'common.settings_label' => 'Settings → {{tab}}',
			'common.remove_category_aria' => 'Remove {{name}}',
			'common.git_remove_remote' => 'Remove remote',
			'common.git_commit_placeholder' => 'Commit message…',
			'common.restart_required_title' => 'Restart required',
			'common.restart_required_desc' => 'This change requires GodotHub to restart to take full effect. The setting has been saved and will apply when you relaunch the app.',
			'common.found_dismissed_title' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Previously removed project found', other: '${count} previously removed projects found', ), 
			'common.found_dismissed_title_one' => 'Previously removed project found',
			'common.found_dismissed_title_other' => '{{count}} previously removed projects found',
			'common.found_dismissed_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Scanner found 1 project that you previously removed from the library. Would you like to re-add it?', other: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', ), 
			'common.found_dismissed_desc_one' => 'Scanner found 1 project that you previously removed from the library. Would you like to re-add it?',
			'common.found_dismissed_desc_other' => 'Scanner found {{count}} projects that you previously removed from the library. Would you like to re-add them?',
			'common.readd_all' => 'Re-add All',
			'common.skip_all' => 'Skip All',
			'common.project_already_open_title' => 'Project already open',
			'common.project_already_open_desc' => '{{name}} is already running. Opening it again launches a second editor instance. Open anyway?',
			'common.project_open_anyway' => 'Open anyway',
			'common.git_sidebar' => 'Git sidebar',
			'common.asset_duplicate_title' => 'Template already installed',
			'common.asset_duplicate_desc' => '"{{name}}" is already in your templates. Install a duplicate anyway?',
			'common.empty_category' => 'Empty Category',
			'common.release_to_drop' => 'Release to drop',
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
			'common.unknown' => 'unknown',
			'common.gpu_webgl_unavailable' => 'WebGL not available',
			'common.gpu_info_unavailable' => 'GPU info unavailable',
			'common.update_available' => 'Update available',
			'common.dismiss' => 'Dismiss',
			'common.system_language' => 'System language',
			'common.category_empty_hint' => 'Create one above to organize your projects',
			'common.contributor_pr_merged' => 'Merged',
			'common.contributor_pr_open' => 'Open',
			'common.contributor_pr_closed' => 'Closed',
			'common.contributor_pr_loading' => 'Loading PRs...',
			'common.contributor_pr_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} pull request', other: '${count} pull requests', ), 
			'common.contributor_pr_count_one' => '{{count}} pull request',
			'common.contributor_pr_count_other' => '{{count}} pull requests',
			'common.contributor_pr_load_failed' => 'Failed to load pull requests.',
			'common.contributor_pr_network_hint' => 'Check your internet connection.',
			'common.contributor_pr_empty' => 'No pull requests found.',
			'common.theme_presets_section' => 'Theme presets',
			'common.all_categories' => 'All categories',
			'common.clear_category_filter' => 'Clear category filter',
			'common.filter_by_category' => 'Filter by category',
			'common.theme_dark' => 'Dark',
			'common.theme_light' => 'Light',
			'common.bulk_tags' => 'Tags',
			'common.bulk_tags_title' => 'Edit tags',
			'common.add_tag' => 'Add tag',
			'common.remove_tag' => 'Remove tag',
			'common.no_common_tags' => 'No tags on the selected projects yet.',
			'common.tags_added_to_selection' => 'Added tag to {{count}} projects.',
			'common.tags_removed_from_selection' => 'Removed tag from {{count}} projects.',
			'common.removed_from_library' => 'Removed {{count}} project(s) from library.',
			'common.undo' => 'Undo',
			'common.duplicate_project_title' => 'Duplicate project',
			'common.copy_suffix' => 'copy',
			'common.duplicate' => 'Duplicate',
			'common.destination_folder' => 'Destination folder',
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
			'common.project_doctor.summary_errors' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} issue needs attention', other: '${count} issues need attention', ), 
			'common.project_doctor.summary_errors_one' => '{{count}} issue needs attention',
			'common.project_doctor.summary_errors_other' => '{{count}} issues need attention',
			'common.project_doctor.summary_warnings' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} warning to review', other: '${count} warnings to review', ), 
			'common.project_doctor.summary_warnings_one' => '{{count}} warning to review',
			'common.project_doctor.summary_warnings_other' => '{{count}} warnings to review',
			'common.project_doctor.summary_ready' => 'No blocking issues found',
			'common.project_doctor.summary_counts' => '{{passed}} checks passed · {{findings}} findings',
			'common.project_doctor.passed_checks' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} passed check', other: '${count} passed checks', ), 
			'common.project_doctor.passed_checks_one' => '{{count}} passed check',
			'common.project_doctor.passed_checks_other' => '{{count}} passed checks',
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
			'common.cleanup_confirm_btn' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Remove ${count} item', other: 'Remove ${count} items', ), 
			'common.cleanup_confirm_btn_one' => 'Remove {{count}} item',
			'common.cleanup_confirm_btn_other' => 'Remove {{count}} items',
			'common.cleanup_done' => 'Freed {{size}}',
			'common.cleanup_failed' => 'Couldn\'t remove {{label}}: {{error}}',
			'common.cleanup_versions_desc' => 'Full size on disk of every installed Godot version.',
			'common.cleanup_templates_title' => 'Project templates',
			'common.cleanup_export_templates_title' => 'Export templates',
			'common.cleanup_used_by_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} template', other: '${count} templates', ), 
			'common.cleanup_used_by_templates_one' => '{{count}} template',
			'common.cleanup_used_by_templates_other' => '{{count}} templates',
			'common.cleanup_current_badge' => 'Current',
			'common.cleanup_alias_badge' => 'Alias',
			'common.cleanup_unused_badge' => 'Unused',
			'common.cleanup_mise_badge' => 'Managed by mise',
			'common.cleanup_external_badge' => 'External',
			'common.cleanup_orphan_badge' => 'Orphaned',
			'common.cleanup_empty' => 'Nothing here yet.',
			'common.new_badge' => 'New',
			'common.reset' => 'Reset',
			'common.git_disconnect' => 'Disconnect',
			'common.git_sign_in_github' => 'Sign in with GitHub',
			'common.git_connected_as' => 'Connected as @{{username}}',
			'common.optional' => '(optional)',
			'common.language_label' => 'Language',
			'common.n_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} project', other: '${count} projects', ), 
			'common.n_projects_one' => '{{count}} project',
			'common.n_projects_other' => '{{count}} projects',
			'common.vault_item_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Item', other: 'Items', ), 
			'common.vault_item_count_one' => 'Item',
			'common.vault_item_count_other' => 'Items',
			'common.vault_search_placeholder' => 'Search vault…',
			'common.vault_empty' => 'Your vault is empty. Click <1>Save to Vault</1> to pick files or folders from a project and reuse them anywhere.',
			'common.vault_no_match' => 'No items match your search.',
			'common.vault_save_btn' => 'Save to Vault',
			'common.vault_save_title' => 'Save to Vault',
			'common.vault_source_project_label' => 'Source Projects',
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
			'common.vault_conflict_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} file already exists in the project. Overwrite it?', other: '${count} files already exist in the project. Overwrite them?', ), 
			'common.vault_conflict_desc_one' => '{{count}} file already exists in the project. Overwrite it?',
			'common.vault_conflict_desc_other' => '{{count}} files already exist in the project. Overwrite them?',
			'common.vault_conflict_summary_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} file already exists across the selected projects. Overwrite it?', other: '${count} files already exist across the selected projects. Overwrite them?', ), 
			'common.vault_conflict_summary_desc_one' => '{{count}} file already exists across the selected projects. Overwrite it?',
			'common.vault_conflict_summary_desc_other' => '{{count}} files already exist across the selected projects. Overwrite them?',
			'common.vault_added_toast' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Added ${count} file', other: 'Added ${count} files', ), 
			'common.vault_added_toast_one' => 'Added {{count}} file',
			'common.vault_added_toast_other' => 'Added {{count}} files',
			'common.vault_added_to_projects_toast' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Added to ${count} project', other: 'Added to ${count} projects', ), 
			'common.vault_added_to_projects_toast_one' => 'Added to {{count}} project',
			'common.vault_added_to_projects_toast_other' => 'Added to {{count}} projects',
			'common.vault_item_empty' => 'This item has no files.',
			'common.kNew' => 'New',
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
			'common.project_addons.count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} addon installed', other: '${count} addons installed', ), 
			'common.project_addons.count_one' => '{{count}} addon installed',
			'common.project_addons.count_other' => '{{count}} addons installed',
			'common.project_addons.empty' => 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.',
			'common.project_addons.check_updates' => 'Check for updates',
			'common.project_addons.checking' => 'Checking…',
			'common.project_addons.updates_available' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} update available', other: '${count} updates available', ), 
			'common.project_addons.updates_available_one' => '{{count}} update available',
			'common.project_addons.updates_available_other' => '{{count}} updates available',
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
			_ => null,
		} ?? switch (path) {
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
			'dashboard.dashboard_git' => 'Git Overview',
			'dashboard.dashboard_git_empty' => 'No git repositories detected.',
			'dashboard.dashboard_git_clean' => 'All clean',
			'dashboard.dashboard_git_dirty' => '{{count}} with uncommitted changes',
			'dashboard.dashboard_git_dirty_plural' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '1 with uncommitted changes', other: '${count} with uncommitted changes', ), 
			'dashboard.dashboard_git_dirty_one' => '1 with uncommitted changes',
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
			'dashboard.dashboard_range_daily' => 'Day',
			'dashboard.dashboard_range_weekly' => 'Week',
			'dashboard.dashboard_range_monthly' => 'Month',
			'dashboard.dashboard_range_yearly' => 'Year',
			'dashboard.dashboard_activity_tracked' => 'Tracked',
			'dashboard.dashboard_activity_peak' => 'Peak',
			'git.remove' => 'Remove',
			'git.changes_title' => 'Changes',
			'git.pull' => 'Pull',
			'git.push' => 'Push',
			'git.force_push' => 'Force',
			'git.fetch' => 'Fetch',
			'git.change' => 'Change',
			'git.commit' => 'Commit',
			'git.committing' => 'Committing…',
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
			'git.merge_aborted' => 'Merge aborted. Working directory restored.',
			'git.new_branch_btn' => '+ New',
			'git.abort_merge' => 'Abort merge',
			'git.merge_in_progress' => 'Merge in progress',
			'git.working_tree_clean' => 'Working tree clean.',
			'git.staged_changes' => 'Staged Changes',
			'git.unstage_all_changes' => 'Unstage All Changes',
			'git.commits_title' => 'Commits',
			'git.stage_file' => 'Stage file',
			'git.discard_file' => 'Discard file',
			'git.unstage_file' => 'Unstage file',
			'git.no_commits_found' => 'No commits found.',
			'git.stage_all' => 'Stage All',
			'git.discard_all' => 'Discard All',
			'git.auth_connected_accounts' => 'Connected accounts',
			'git.auth_connect_hint' => 'Connect to your desired git host to begin, or use SSH without connecting anything.',
			'git.worktrees_title' => 'Worktrees',
			'git.worktree_current' => 'Current',
			'git.no_worktrees' => 'No additional worktrees',
			'git.switch_worktree' => 'Switch to this worktree',
			'git.switched_worktree_ok' => 'Switched to worktree.',
			'git.add_worktree' => 'New worktree',
			'git.add_worktree_btn' => 'Add worktree',
			'git.worktree_path_placeholder' => 'Path (e.g. ../my-feature)',
			'git.worktree_branch_placeholder' => 'Branch name (optional)',
			'git.worktree_created_ok' => 'Worktree created.',
			'git.worktree_dirty' => 'Uncommitted changes',
			'git.remove_worktree' => 'Remove worktree',
			'git.remove_worktree_confirm_desc' => 'Remove the worktree at {{path}}? Its directory will be deleted. The branch and commits are kept.',
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
			'nav.dashboard' => 'Dashboard',
			'nav.projects' => 'Projects',
			'nav.projects_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Project', other: 'Projects', ), 
			'nav.projects_count_one' => 'Project',
			'nav.projects_count_other' => 'Projects',
			'nav.versions' => 'Versions',
			'nav.templates' => 'Templates',
			'nav.vault' => 'Vault',
			'nav.asset_store' => 'Asset Store',
			'nav.news' => 'Godot News',
			'nav.storage_view' => 'Storage',
			'nav.settings' => 'Settings',
			'nav.changelog' => 'Changelog',
			'nav.group_workspace' => 'Workspace',
			'nav.group_resources' => 'Resources',
			'nav.group_explore' => 'Explore',
			'nav.you' => 'You',
			'nav.account_manage' => 'Manage accounts',
			'nav.workspace_tip_title' => 'Workspace switcher moved',
			'nav.workspace_tip_body' => 'Workspace switcher moved to new section, Click \'You\' button down below to access it.',
			'nav.workspace_tip_dismiss' => 'Got it',
			'onboarding.welcome' => 'Welcome',
			'onboarding.finish' => 'Finish',
			'onboarding.in_progress' => 'In Progress',
			'onboarding.prototypes' => 'Prototypes',
			'onboarding.finished' => 'Finished',
			'onboarding.game_jams' => 'Game Jams',
			'onboarding.project_folders' => 'Project folders',
			'onboarding.version_folders' => 'Version folders',
			'onboarding.welcome_title' => 'Welcome to GodotHub',
			'onboarding.welcome_desc' => 'Your one stop application for everything Godot.',
			'onboarding.onboard_empty_projects' => 'No folders added yet, GodotHub won\'t find any existing projects until you add one, or you can add projects manually later.',
			'onboarding.onboard_empty_versions' => 'No folders added yet, new Godot downloads will go to the app data folder unless you set one below.',
			'onboarding.onboard_no_template_folder' => 'No folder set, you can always configure this later in Settings, or save templates manually.',
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
			'onboarding.discovery_added_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Added ${count} project.', other: 'Added ${count} projects.', ), 
			'onboarding.discovery_added_projects_one' => 'Added {{count}} project.',
			'onboarding.discovery_added_projects_other' => 'Added {{count}} projects.',
			'onboarding.discovery_added_versions' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Added ${count} version.', other: 'Added ${count} versions.', ), 
			'onboarding.discovery_added_versions_one' => 'Added {{count}} version.',
			'onboarding.discovery_added_versions_other' => 'Added {{count}} versions.',
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
			'settings.storage' => 'Storage',
			'settings.behavior' => 'Behavior',
			'settings.display' => 'Display',
			'settings.appearance' => 'Appearance',
			'settings.accessibility' => 'Accessibility',
			'settings.accessibility_desc' => 'Screen reader announcements and assistive technology options.',
			'settings.app_version_label' => 'GodotHub v{{version}}',
			'settings.landing_dashboard' => 'Dashboard',
			'settings.landing_projects' => 'Projects',
			'settings.landing_versions' => 'Versions',
			'settings.landing_news' => 'Godot News',
			'settings.screen_reader_label' => 'Screen reader announcements',
			'settings.advanced' => 'Advanced',
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
			'settings.storage_title' => 'Storage & Auto-scan',
			'settings.behavior_projects_title' => 'Projects',
			'settings.file_watchers_title' => 'File Watchers',
			'settings.last_opened_title' => 'Last Opened Display',
			'settings.github_token_title' => 'GitHub API Token',
			'settings.titlebar_buttons' => 'Titlebar Buttons',
			'settings.setup_wizard' => 'Setup Wizard',
			'settings.setup_wizard_again' => 'Run Setup Wizard Again',
			'settings.restart_app' => 'Restart App',
			'settings.restart_app_confirm_title' => 'Restart GodotHub?',
			'settings.restart_app_confirm_desc' => 'The app will close and reopen automatically. Unsaved in-progress operations may be interrupted.',
			'settings.reset_settings' => 'Reset Settings',
			'settings.delete_app_data' => 'Delete App Data',
			'settings.new_project_default' => 'New project default',
			'settings.download_folder' => 'Download folder',
			'settings.system' => 'System',
			'settings.k12h' => '12-hour (2:30 PM)',
			'settings.k24h' => '24-hour (14:30)',
			'settings.dd_mm_yyyy' => 'DD-MM-YYYY',
			'settings.mm_dd_yyyy' => 'MM-DD-YYYY',
			'settings.yyyy_mm_dd' => 'YYYY-MM-DD',
			'settings.reset_all_title' => 'Reset all settings?',
			'settings.reset_all_desc' => 'This restores every setting on this page, download folder, scan folders, appearance, and behavior, back to their defaults. This can\'t be undone.',
			'settings.delete_all_title' => 'Delete all app data?',
			'settings.delete_all_desc' => 'This permanently deletes every workspace, project, category, installed-version record, and setting GodotHub has stored, and restarts you at first-time setup. Your actual project folders and Godot installs on disk are not touched, unless they live in the default download folder, in which case they\'re deleted too. This can\'t be undone.',
			'settings.empty_hint_projects' => 'No folders added, nothing will be scanned at startup, and new projects will ask where to save each time.',
			'settings.empty_hint_versions' => 'No folders added, nothing will be scanned at startup, and new downloads will use the app data folder.',
			'settings.naming_convention_label' => 'Directory naming convention',
			'settings.naming_keep' => 'Keep as typed (My Game)',
			'settings.naming_kebab' => 'kebab-case (my-game)',
			'settings.naming_snake' => 'snake_case (my_game)',
			'settings.naming_camel' => 'camelCase (myGame)',
			'settings.naming_pascal' => 'PascalCase (MyGame)',
			'settings.naming_title' => 'Title Case (My Game)',
			'settings.theme' => 'Theme',
			'settings.theme_preset_label' => 'Theme preset',
			'settings.theme_preset_custom' => 'Custom',
			'settings.preset_light_group' => 'Light themes',
			'settings.preset_dark_group' => 'Dark themes',
			'settings.test' => 'Test',
			'settings.testing' => 'Testing…',
			'settings.token_valid' => 'Token valid! Rate limit: {{status}}',
			'settings.token_resets_in' => '(resets ~{{minutes}} min)',
			'settings.test_failed' => 'Test failed: {{error}}',
			'settings.key_space' => 'Space',
			'settings.no_settings_match' => 'No settings match',
			'settings.scan_result' => 'Found {{projects}} new project(s) and {{versions}} new version(s).',
			'settings.palette_shortcut' => 'Command palette shortcut',
			'settings.keybind_instruction' => 'Click the button below, then press any key to rebind.',
			'settings.press' => 'Press',
			'settings.to_cancel' => 'to cancel',
			'settings.press_key' => 'Press a key…',
			'settings.click_to_rebind' => 'Click to rebind',
			'settings.close_on_open_label' => 'Close application on project open',
			'settings.launch_console_label' => 'Launch Godot with console',
			'settings.builtin_console_label' => 'Use the built-in console',
			'settings.minimize_tray_label' => 'Minimize to system tray on closing app',
			'settings.reopen_label' => 'Reopen after closing Godot',
			'settings.no_folder_set' => 'No folder set. You can still import manually or use \'Save as Template\'.',
			'settings.ui_density_label' => 'UI density',
			'settings.text_size_label' => 'Text size',
			'settings.section_godot_versions' => 'Godot versions',
			'settings.scan_depth_label' => 'Scan depth',
			'settings.icon_scan_depth_label' => 'Project icon search depth',
			'settings.download_concurrency_label' => 'Simultaneous downloads',
			'settings.tray_recent_label' => 'Tray recent projects',
			'settings.tooltip_delay_label' => 'Tooltip delay',
			'settings.project_icon_opacity_label' => 'Project icon opacity',
			'settings.project_card_style_label' => 'Project card style',
			'settings.project_card_style_hub' => 'Godot Hub',
			'settings.project_card_style_cover' => 'Cover',
			'settings.time_format_label' => 'Time format (shown when opened today)',
			'settings.date_format_label' => 'Date format (shown for any other day)',
			'settings.auto_scan_label' => 'Auto-scan on startup',
			'settings.use_workspaces_label' => 'Use workspaces',
			'settings.watch_projects_label' => 'Watch project folders',
			'settings.watch_versions_label' => 'Watch version folders',
			'settings.watch_template_label' => 'Watch template directory',
			'settings.show_scrollbar_label' => 'Show scrollbar',
			'settings.animated_numbers_label' => 'Animated numbers',
			'settings.show_support_label' => 'Show support button',
			'settings.show_star_label' => 'Show star button',
			'settings.show_bug_label' => 'Show bug report button',
			'settings.show_tray_label' => 'Show tray button',
			'settings.show_language_label' => 'Show language button',
			'settings.clear' => 'Clear',
			'settings.reset_to_default' => 'Reset to default',
			'settings.reset_appearance' => 'Reset appearance to default',
			'settings.delete_all' => 'Delete All',
			'settings.open_setup' => 'Open Setup',
			'settings.reset_colors' => 'Reset colors to default',
			'settings.folders_deep' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} folder deep', other: '${count} folders deep', ), 
			'settings.folders_deep_one' => '{{count}} folder deep',
			'settings.folders_deep_other' => '{{count}} folders deep',
			'settings.at_once' => '{{count}} at once',
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
			'settings.sync_push_done' => 'All workspaces pushed to your gist.',
			'settings.sync_open_gist' => 'Open gist',
			'settings.sync_last_pushed' => 'Last pushed: {{time}}',
			'settings.sync_manual_hint' => 'Lost your local data? Enter your gist URL or ID to restore from any machine.',
			'settings.sync_manual_placeholder' => 'https://gist.github.com/... or gist ID',
			'settings.sync_manual_pull_btn' => 'Restore',
			'settings.restore_modal_title' => 'Restore from Cloud',
			'settings.restore_modal_fetching' => 'Fetching backup from GitHub…',
			'settings.restore_modal_applying' => 'Applying backup and restarting…',
			'settings.restore_modal_preview_desc' => 'Your gist backup contains:',
			'settings.restore_modal_workspaces' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'workspace', other: 'workspaces', ), 
			'settings.restore_modal_workspaces_one' => 'workspace',
			'settings.restore_modal_workspaces_other' => 'workspaces',
			'settings.restore_modal_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'project', other: 'projects', ), 
			'settings.restore_modal_projects_one' => 'project',
			'settings.restore_modal_projects_other' => 'projects',
			'settings.restore_modal_categories' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'category', other: 'categories', ), 
			'settings.restore_modal_categories_one' => 'category',
			'settings.restore_modal_categories_other' => 'categories',
			'settings.restore_modal_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'template', other: 'templates', ), 
			'settings.restore_modal_templates_one' => 'template',
			'settings.restore_modal_templates_other' => 'templates',
			'settings.restore_modal_time_stats' => 'Includes time tracking data',
			'settings.restore_modal_todos' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Includes ${count} to-do', other: 'Includes ${count} to-dos', ), 
			'settings.restore_modal_todos_one' => 'Includes {{count}} to-do',
			'settings.restore_modal_todos_other' => 'Includes {{count}} to-dos',
			'settings.restore_modal_project_scan_dirs' => '{{count}} project scan folder(s) will be restored',
			'settings.restore_modal_version_scan_dirs' => '{{count}} Godot version folder(s) will be restored',
			'settings.restore_modal_workspace_list' => 'Workspaces',
			'settings.restore_modal_warning' => 'This will overwrite your current settings and workspace data. You\'ll need to restart the app to apply changes.',
			'settings.restore_modal_apply_btn' => 'Apply & Restart',
			'settings.restore_modal_done_title' => 'Backup Restored',
			'settings.restore_modal_done_hint' => 'Click the button below to restart and apply all changes.',
			'settings.settings_exported' => 'Settings exported.',
			'settings.settings_imported' => 'Settings imported.',
			'settings.stats_imported' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Imported stats for ${count} project.', other: 'Imported stats for ${count} projects.', ), 
			'settings.stats_imported_one' => 'Imported stats for {{count}} project.',
			'settings.stats_imported_other' => 'Imported stats for {{count}} projects.',
			'settings.raised_contrast_label' => 'Raised surface contrast',
			'settings.raised_contrast_value' => '{{value}}%',
			'settings.token_help_desc' => 'Create a token at github.com/settings/tokens. You only need to check the repo scope if you want private repo access, otherwise leave all scopes unchecked. No sensitive permissions required.',
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
			_ => null,
		} ?? switch (path) {
			'settings.search_placeholder' => 'Search settings…',
			'settings.interface_label' => 'Interface',
			'settings.card_layout_label' => 'Card layout',
			'settings.landing_tab_label' => 'Default landing page',
			'settings.language_complete' => 'Complete',
			'settings.language_beta' => 'Beta',
			'settings.language_incomplete' => 'Incomplete',
			'settings.use_os_decorations' => 'Use OS window decorations',
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
			'settings.features_enabled_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} feature on', other: '${count} features on', ), 
			'settings.features_enabled_count_one' => '{{count}} feature on',
			'settings.features_enabled_count_other' => '{{count}} features on',
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
			'todos.pending_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} pending', other: '${count} pending', ), 
			'todos.pending_count_one' => '{{count}} pending',
			'todos.pending_count_other' => '{{count}} pending',
			'todos.completed_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} completed', other: '${count} completed', ), 
			'todos.completed_count_one' => '{{count}} completed',
			'todos.completed_count_other' => '{{count}} completed',
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
			'todos.due_in_days' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Due in ${count} day', other: 'Due in ${count} days', ), 
			'todos.due_in_days_one' => 'Due in {{count}} day',
			'todos.due_in_days_other' => 'Due in {{count}} days',
			'todos.overdue_yesterday' => 'Was due yesterday',
			'todos.overdue_days' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Overdue by ${count} day', other: 'Overdue by ${count} days', ), 
			'todos.overdue_days_one' => 'Overdue by {{count}} day',
			'todos.overdue_days_other' => 'Overdue by {{count}} days',
			'todos.scan_code' => 'Scan code',
			'todos.scan_code_hint' => 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed',
			'todos.comment_scan_summary' => 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened',
			'todos.comment_scan_none' => 'Code scan found no changes',
			'todos.commit_closed' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Completed ${count} to-do from a commit message', other: 'Completed ${count} to-dos from commit messages', ), 
			'todos.commit_closed_one' => 'Completed {{count}} to-do from a commit message',
			'todos.commit_closed_other' => 'Completed {{count}} to-dos from commit messages',
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
			'todos.open_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} to-do', other: '${count} to-dos', ), 
			'todos.open_count_one' => '{{count}} to-do',
			'todos.open_count_other' => '{{count}} to-dos',
			'todos.overdue_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '${count} overdue', other: '${count} overdue', ), 
			'todos.overdue_count_one' => '{{count}} overdue',
			'todos.overdue_count_other' => '{{count}} overdue',
			'todos.tile_summary' => '{{overdue}} overdue · {{soon}} due this week',
			'todos.tile_empty' => 'Nothing overdue or due this week.',
			'todos.due_notification_title' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'To-do due: {{title}}', other: '${count} to-dos are due', ), 
			'todos.due_notification_title_one' => 'To-do due: {{title}}',
			'todos.due_notification_title_other' => '{{count}} to-dos are due',
			'todos.due_notification_more' => 'and {{count}} more',
			'versions.standard' => 'Standard (GDScript)',
			'versions.unbound' => 'unbound',
			'versions.mono' => 'Mono (C#/.NET)',
			'versions.both' => 'Both',
			'versions.stable' => 'Stable',
			'versions.unstable' => 'Unstable',
			'versions.rename' => 'Rename',
			'versions.open_editor' => 'Open Editor',
			'versions.open_editor_with_console' => 'Open Editor with Console',
			'versions.more_editor_launch_options' => 'More editor launch options',
			'versions.open_install_folder' => 'Open Install Folder',
			'versions.type' => 'Type',
			'versions.channel' => 'Channel',
			'versions.fetch_error' => 'Couldn\'t fetch available versions.',
			'versions.paused_dot' => 'Paused · ',
			'versions.available_title' => 'AVAILABLE VERSIONS',
			'versions.no_versions_match' => 'No installed versions match',
			'versions.no_available_versions_match' => 'No available versions match',
			'versions.open' => 'Open',
			'versions.install' => 'Install',
			'versions.mb' => 'MB',
			'versions.resume_download' => 'Resume download',
			'versions.pause_download' => 'Pause download',
			'versions.cancel_download' => 'Cancel download',
			'versions.installed_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Installed', other: 'Installed', ), 
			'versions.installed_count_one' => 'Installed',
			'versions.installed_count_other' => 'Installed',
			'versions.installed_label' => 'Installed',
			'versions.original_name' => 'Original',
			'versions.source' => 'Source',
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
			'versions.alias_create_all' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: 'Create Alias', other: 'Create ${count} Aliases', ), 
			'versions.alias_create_all_one' => 'Create Alias',
			'versions.alias_create_all_other' => 'Create {{count}} Aliases',
			'versions.aliases_batch_created' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '1 alias created', other: '${count} aliases created', ), 
			'versions.aliases_batch_created_one' => '1 alias created',
			'versions.aliases_batch_created_other' => '{{count}} aliases created',
			'versions.aliases_batch_skipped' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '1 alias skipped', other: '${count} aliases skipped', ), 
			'versions.aliases_batch_skipped_one' => '1 alias skipped',
			'versions.aliases_batch_skipped_other' => '{{count}} aliases skipped',
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
			'versions.templates_folder' => 'Templates folder',
			'versions.versions_folder' => 'Versions folder',
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
			'versions.export_templates_selected' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '1 template selected', other: '${count} templates selected', ), 
			'versions.export_templates_selected_one' => '1 template selected',
			'versions.export_templates_selected_other' => '{{count}} templates selected',
			'versions.export_templates_size_summary' => '~{{download}} download · {{installed}} on disk',
			'versions.export_templates_download_selected' => 'Download selected',
			'versions.export_templates_loading_options' => 'Checking this release\'s available templates…',
			'versions.export_templates_options_failed' => 'Couldn\'t load the templates for this release.',
			'versions.export_templates_available' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '1 available template group', other: '${count} available template groups', ), 
			'versions.export_templates_available_one' => '1 available template group',
			'versions.export_templates_available_other' => '{{count}} available template groups',
			'versions.export_templates_select_all' => 'Select all',
			'versions.export_templates_files' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(count, one: '1 template file', other: '${count} template files', ), 
			'versions.export_templates_files_one' => '1 template file',
			'versions.export_templates_files_other' => '{{count}} template files',
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
			'versions.download_failed_title' => 'Download failed',
			'versions.download_failed_asset_label' => 'File',
			'versions.download_failed_error_label' => 'Error details',
			'versions.download_failed_copy' => 'Copy details',
			'versions.download_failed_hint' => 'Common causes: a blocked network or proxy, antivirus blocking the download, a missing or read-only download folder, or low disk space.',
			'versions.custom_build_badge' => 'Custom build',
			'versions.add_custom_build' => 'Add custom build…',
			'versions.adding_custom_build' => 'Adding custom build…',
			_ => null,
		};
	}
}
