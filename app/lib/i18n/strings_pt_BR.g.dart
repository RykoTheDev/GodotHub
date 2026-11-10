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
class TranslationsPtBr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPtBr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ptBr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <pt-BR>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsPtBr _root = this; // ignore: unused_field

	@override 
	TranslationsPtBr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPtBr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$changelog$pt_BR changelog = _Translations$changelog$pt_BR._(_root);
	@override late final _Translations$common$pt_BR common = _Translations$common$pt_BR._(_root);
	@override late final _Translations$dashboard$pt_BR dashboard = _Translations$dashboard$pt_BR._(_root);
	@override late final _Translations$git$pt_BR git = _Translations$git$pt_BR._(_root);
	@override late final _Translations$nav$pt_BR nav = _Translations$nav$pt_BR._(_root);
	@override late final _Translations$onboarding$pt_BR onboarding = _Translations$onboarding$pt_BR._(_root);
	@override late final _Translations$settings$pt_BR settings = _Translations$settings$pt_BR._(_root);
	@override late final _Translations$todos$pt_BR todos = _Translations$todos$pt_BR._(_root);
	@override late final _Translations$versions$pt_BR versions = _Translations$versions$pt_BR._(_root);
}

// Path: changelog
class _Translations$changelog$pt_BR extends Translations$changelog$en_US {
	_Translations$changelog$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get changelog_title => 'REGISTRO DE ALTERAÇÕES';
	@override String get no_entries => 'Ainda não há entradas no registro de alterações';
	@override String get delete_entry_title => 'Excluir entrada do registro de alterações?';
	@override String get delete_entry_desc => 'Isso removerá a entrada permanentemente. Esta ação não pode ser desfeita.';
	@override String get changelog_subtitle => 'Um histórico das atualizações do GodotHub.';
	@override String get edit_entry_aria => 'Edit {{version}}';
	@override String get delete_entry_aria => 'Delete {{version}}';
	@override String get added => 'Adicionado';
	@override String get fixed => 'Corrigido';
	@override String get improved => 'Melhorado';
}

// Path: common
class _Translations$common$pt_BR extends Translations$common$en_US {
	_Translations$common$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get new_project => 'Novo projeto';
	@override String get import_project => 'Importar projeto';
	@override String get search => 'Pesquisar';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Salvar';
	@override String get delete => 'Excluir';
	@override String get close => 'Fechar';
	@override String get loading => 'Carregando...';
	@override String get retry => 'Tentar novamente';
	@override String get stop => 'Parar';
	@override String get refresh => 'Atualizar';
	@override String get scroll_to_top => 'Voltar ao topo';
	@override String get quick_commands => 'Comandos rápidos';
	@override String get minimize => 'Minimizar';
	@override String get close_sidebar => 'Fechar barra lateral';
	@override String get star_on_github => 'Dar estrela no GitHub';
	@override String get support_dev => 'Apoie o desenvolvimento no Patreon. Você pode desativar isso nas Configurações';
	@override String get support => 'Apoiar';
	@override String get restore => 'Restaurar';
	@override String get maximize => 'Maximizar';
	@override String get importing_project => 'Importando projeto…';
	@override String get importing_version => 'Importando versão…';
	@override String get scanning_projects => 'Procurando projetos…';
	@override String get scanning_versions => 'Procurando versões…';
	@override String get queued => 'Queued…';
	@override String get download_queue_move_up => 'Mover para mais cedo na fila';
	@override String get download_queue_move_down => 'Mover para mais tarde na fila';
	@override String get running => 'Em execução';
	@override String running_projects_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} projeto em execução',
		many: '${count} projects running',
		other: '${count} projetos em execução',
	);
	@override String get active => 'Ativo';
	@override String get done => 'Concluído';
	@override String get paused => 'Pausado';
	@override String get no_tasks_running => 'Nenhuma tarefa em execução';
	@override String get checking_changes => 'Verificando alterações…';
	@override String get cloning => 'Clonando…';
	@override String get clone_import => 'Clonar e importar';
	@override String get import => 'Importar';
	@override String get syncing => 'Sincronizando…';
	@override String get edit_entry => 'Editar entrada do registro de alterações';
	@override String get new_entry => 'Nova entrada do registro de alterações';
	@override String get checking_updates => 'Verificando atualizações…';
	@override String get up_to_date => 'Atualizado';
	@override String get downloading_update => 'Baixando…';
	@override String get install_update => 'Instalar';
	@override String get restart_now => 'Reiniciar agora';
	@override String get update_downloaded => 'Atualização baixada!';
	@override String get restart_to_apply => 'Reinicie o GodotHub para aplicar a atualização.';
	@override String get update_applied_desc => 'A atualização foi baixada e será aplicada na próxima vez que você reiniciar o GodotHub. Feche e abra o aplicativo novamente para concluir a atualização.';
	@override String get is_latest => 'v{{version}} é a versão mais recente.';
	@override String get percent_complete => '{{percent}}% concluído';
	@override String get expand_sidebar => 'Expandir barra lateral';
	@override String get collapse_sidebar => 'Recolher barra lateral';
	@override String get saving => 'Salvando…';
	@override String get save_changes => 'Salvar alterações';
	@override String get add_entry => 'Adicionar entrada';
	@override String get scan_for_projects => 'Procurar projetos';
	@override String get create_workspace => 'Criar espaço de trabalho';
	@override String get report_a_bug => 'Reportar um bug';
	@override String get report_bug => 'Reportar bug';
	@override String get app_error_title => 'Algo deu errado';
	@override String get app_error_desc => 'O GodotHub encontrou um erro inesperado e não conseguiu renderizar. Veja os detalhes abaixo e consulte o console (clique com o botão direito → Inspecionar) para ver o stack trace completo.';
	@override String get reload => 'Recarregar';
	@override String get view_error_title => 'This view couldn\'t load';
	@override String get view_error_desc => 'The rest of GodotHub still works. Try loading this view again, or switch to another one.';
	@override String get error_details => 'Technical details';
	@override String get remove_folder => 'Remover pasta';
	@override String get make_this_default => 'Definir como {{label}}';
	@override String get suggested_from_workspaces => 'Sugerido a partir de outros espaços de trabalho';
	@override String get from_workspace => 'de {{name}}';
	@override String get add_folder => 'Adicionar pasta';
	@override String get default_folder => 'Padrão';
	@override String get default_downloads_go_to => 'Sem uma pasta padrão, novas versões do Godot serão salvas em "{{path}}".';
	@override String get open_terminal => 'Abrir terminal';
	@override String get downloading_version => 'Baixando {{version}}';
	@override String get downloading_asset => 'Baixando {{title}}';
	@override String get asset_download_failed => 'Falha ao baixar o template';
	@override String get scan_for_engines => 'Procurar versões da Godot';
	@override String get import_version => 'Importar versão';
	@override String get sync_templates_from_directory => 'Sincronizar templates a partir de uma pasta';
	@override String get section_navigation => 'Navegação';
	@override String get section_projects => 'Projetos';
	@override String get section_views => 'Modos de exibição';
	@override String get section_workspaces => 'Espaços de trabalho';
	@override String get section_help => 'Ajuda';
	@override String get section_engines => 'Versões da Godot';
	@override String get section_templates => 'Templates';
	@override String get section_versions => 'Versões';
	@override String get section_news => 'Notícias';
	@override String get skip_setup => 'Pular configuração';
	@override String get back => 'Voltar';
	@override String get finishing => 'Finalizando…';
	@override String get get_started => 'Começar';
	@override String get scanning => 'Procurando…';
	@override String get scan_now => 'Procurar agora';
	@override String get scan_complete => 'Busca concluída';
	@override String get scan_failed => 'Falha na busca';
	@override String get uncategorized => 'Sem categoria';
	@override String get all => 'Todos';
	@override String get no_filter => 'Sem filtro';
	@override String get cannot_undo => 'Esta ação não pode ser desfeita.';
	@override String get deleting => 'Excluindo…';
	@override String get open_project => 'Abrir';
	@override String get play_project => 'Jogar';
	@override String get play_project_tooltip => 'Jogue sem abrir o editor';
	@override String get no_version_selected => 'Nenhuma versão selecionada';
	@override String get open_with_console => 'Abrir com console';
	@override String get open_folder => 'Abrir pasta';
	@override String get open_in_ide => 'Abrir na IDE';
	@override String get category => 'Categoria';
	@override String get none => 'Nenhum';
	@override String get project_size => 'Tamanho do projeto';
	@override String get project_size_scanning => 'Scanning project files…';
	@override String get project_size_empty => 'No files found';
	@override String get launch_arguments => 'Parâmetros de inicialização';
	@override String get save_as_template => 'Salvar como template';
	@override String get git => 'Git';
	@override String get add => 'Adicionar';
	@override String get color_label => 'Cor';
	@override String get icon_label => 'Ícone';
	@override String get expand => 'Expandir';
	@override String get collapse => 'Recolher';
	@override String file_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} arquivo',
		many: '${count} arquivo',
		other: '${count} arquivos',
	);
	@override String folder_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} pasta',
		many: '${count} pasta',
		other: '${count} pastas',
	);
	@override String get template_empty => 'Este template está vazio.';
	@override String get categories => 'Categorias';
	@override String get category_folders_hint => 'Projetos encontrados nas pastas de uma categoria são atribuídos a ela automaticamente.';
	@override String get assign_folder => 'Atribuir pasta';
	@override String get assign_folder_to_category => 'Atribuir uma pasta a {{name}}';
	@override String get unassign_folder_aria => 'Remover {{folder}} desta categoria';
	@override String get new_category_placeholder => 'Nome da nova categoria…';
	@override String get no_categories_yet => 'Ainda não há categorias. Adicione uma acima.';
	@override String get edit_category => 'Editar {{name}}';
	@override String get delete_category => 'Excluir {{name}}';
	@override String get delete_category_title => 'Excluir categoria?';
	@override String get delete_category_desc => '"{{name}}" será removida. Os projetos dentro dela irão para Sem categoria; nada no disco será alterado.';
	@override String get project_name_label => 'Nome';
	@override String get folder_name_preview => 'Convenção da pasta: {{name}}';
	@override String get folder_name_hint => 'O nome da pasta é derivado do nome do projeto usando sua convenção de nomenclatura.';
	@override String get template_preview_aria => 'Prévia de {{name}}';
	@override String get project_location_label => 'Local';
	@override String get choose_folder_placeholder => 'Escolha uma pasta';
	@override String get browse => 'Procurar';
	@override String get blank_template => 'Padrão';
	@override String get template_optional => 'Template (opcional)';
	@override String get category_optional => 'Categoria (opcional)';
	@override String get no_category_label => 'Sem categoria';
	@override String get godot_version_label => 'Versão do Godot';
	@override String get no_engine_warning => 'Nenhuma versão da Godot instalada ainda. Baixe uma primeiro na aba Versões.';
	@override String get change_icon => 'Alterar';
	@override String get choose_icon => 'Escolher';
	@override String get icon_format_desc => 'SVG, PNG ou JPG. O padrão é o logo do Godot.';
	@override String get other_settings_label => 'Outras configurações';
	@override String get init_git_label => 'Inicializar repositório Git';
	@override String get init_git_desc => 'Adiciona um .gitignore e .gitattributes do Godot e então faz um commit inicial na main.';
	@override String get init_git_unavailable => 'Instale o Git e reinicie o GodotHub para usar isto.';
	@override String get initializing_git => 'Configurando Git…';
	@override String get git_init_warning_title => 'Projeto criado, o Git precisa de atenção';
	@override String get git_option_gitignore => '.gitignore do Godot';
	@override String get git_option_gitattributes => '.gitattributes';
	@override String get git_option_readme => 'README.md';
	@override String get git_option_license => 'Licença';
	@override String get git_option_no_license => 'Sem licença';
	@override String get create_remote_label => 'Criar repositório no GitHub/GitLab';
	@override String get create_remote_desc => 'Cria um repositório na sua conta conectada e envia o commit inicial.';
	@override String get remote_private => 'Privado';
	@override String get remote_public => 'Público';
	@override String get creating_remote_repo => 'Criando repositório remoto…';
	@override String get remote_repo_created_title => 'Repositório remoto criado';
	@override String get create_project_done => 'Concluído';
	@override String get create_project_btn => 'Criar projeto';
	@override String get creating => 'Criando…';
	@override String get create_project_error => 'Dê um nome ao projeto e escolha uma pasta para criá-lo.';
	@override String get create_workspace_title => 'Novo espaço de trabalho';
	@override String get workspace_name_label => 'Nome';
	@override String get workspace_name_placeholder => 'Trabalho, Pessoal, Game Jam…';
	@override String get workspace_name_required_error => 'Dê um nome ao espaço de trabalho.';
	@override String get edit_workspace_title => 'Editar espaço de trabalho';
	@override String get cant_delete_only_workspace => 'Você não pode excluir seu único espaço de trabalho';
	@override String get delete_workspace_title => 'Excluir espaço de trabalho?';
	@override String get delete_workspace_desc => '"{{name}}" e tudo o que pertence a ele (configurações, projetos e categorias) serão removidos. Os arquivos dos projetos no disco nunca são alterados. As versões instaladas do Godot são compartilhadas e permanecerão intactas.';
	@override String get other => 'Outro';
	@override String get args_label => 'Parâmetros';
	@override String get args_placeholder => 'ex.: --debug --single-window';
	@override String get args_suggestions => 'Sugestões';
	@override String get args_desc_separate_prefix => 'Separe os parâmetros com espaços. Flags com valores, como';
	@override String get args_desc_separate_suffix => 'usam dois tokens.';
	@override String get args_debug => '--debug';
	@override String get args_debug_desc => 'Executar com o depurador anexado';
	@override String get args_single_window => '--single-window';
	@override String get args_single_window_desc => 'Forçar modo de janela única';
	@override String get args_opengl3 => '--rendering-driver opengl3';
	@override String get args_opengl3_desc => 'Usar o driver de renderização OpenGL 3';
	@override String get args_vulkan => '--rendering-driver vulkan';
	@override String get args_vulkan_desc => 'Usar o driver de renderização Vulkan';
	@override String get args_headless => '--headless';
	@override String get args_headless_desc => 'Executar sem uma janela';
	@override String get args_verbose => '--verbose';
	@override String get args_verbose_desc => 'Registrar saída detalhada de depuração';
	@override String get args_editor => '--editor';
	@override String get args_editor_desc => 'Abrir o editor (igual a -e)';
	@override String get args_build_solutions => '--build-solutions';
	@override String get args_build_solutions_desc => 'Compilar soluções C# ao abrir';
	@override String get args_gpu_index => '--gpu-index 1';
	@override String get args_gpu_index_desc => 'Usar a GPU de índice 1 (GPU dedicada)';
	@override String get sort_categories => 'Categorias';
	@override String get sort_recent => 'Abertos recentemente';
	@override String get sort_manual => 'Manual';
	@override String get sort_name_asc => 'Nome (A–Z)';
	@override String get sort_name_desc => 'Nome (Z–A)';
	@override String get sort_created_desc => 'Data de adição (mais recente)';
	@override String get sort_created_asc => 'Data de adição (mais antiga)';
	@override String get sort_time_desc => 'Tempo total';
	@override String get filter => 'Filtrar';
	@override String get no_templates_yet => 'Ainda não há templates. Clique com o botão direito em um projeto ou abra o menu "Mais" e selecione <1>Salvar como template</1> para criar um, ou baixe templates da Biblioteca de Assets.';
	@override String get godot => 'Godot';
	@override String get delete_template => 'Excluir template {{name}}';
	@override String get news_subtitle => 'Publicações mais recentes do blog oficial do Godot Engine.';
	@override String get news_cached => 'Não foi possível acessar godotengine.org; exibindo os artigos salvos da última vez.';
	@override String get news_error => 'Não foi possível carregar as notícias do Godot.';
	@override String get news_empty => 'Nenhuma notícia para mostrar no momento.';
	@override String get show_more => 'Mostrar mais';
	@override String get try_again => 'Tentar novamente';
	@override String get asset_store_title => 'LOJA DE ASSETS';
	@override String get news_count => 'Publicações';
	@override String asset_store_count_plural({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		zero: 'Nenhum asset',
		one: 'Asset',
		many: 'Assets',
		other: 'Assets',
	);
	@override String get asset_store_count => 'Assets';
	@override String get settings_title => 'CONFIGURAÇÕES';
	@override String get no_templates_match => 'Nenhum template corresponde à busca';
	@override String get no_projects_match => 'Nenhum projeto corresponde à busca';
	@override String get more_import_options => 'Mais opções de importação';
	@override String get clone_import_repo => 'Clonar e importar de um repositório';
	@override String get manage_categories => 'Gerenciar categorias';
	@override String get hide_category => 'Hide Category';
	@override String get category_hidden_toast => '"{{name}}" hidden. Restore it from Hidden Categories.';
	@override String get hidden_categories => 'Hidden Categories';
	@override String get hidden_categories_hint => 'Those categories and their projects stay out of the way. Unhide one to bring it back.';
	@override String get hidden_category_projects => '{{count}} project(s)';
	@override String get unhide => 'Unhide';
	@override String get unhide_category_aria => 'Unhide {{name}}';
	@override String get search_projects_placeholder => 'Pesquisar projetos...';
	@override String get clear_search => 'Limpar pesquisa';
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
	@override String get sort => 'Ordenar';
	@override String get view_list => 'Lista';
	@override String get view_grid => 'Grade';
	@override String get view_kanban => 'Kanban';
	@override String get no_projects_yet => 'Ainda não há nada aqui. Crie um novo projeto ou importe um que já esteja no disco.';
	@override String get pinned_section => 'Fixados';
	@override String get set_category => 'Definir categoria…';
	@override String get clear_selection => 'Limpar seleção';
	@override String get starting => 'Iniciando…';
	@override String get app_loading => 'Carregando…';
	@override String get changelog_version_label => 'Versão';
	@override String get changelog_version_placeholder => 'v1.0.0';
	@override String get changelog_date_label => 'Data';
	@override String get changelog_date_placeholder => '2026-07-13';
	@override String get changelog_what_changed => 'O que mudou';
	@override String get changelog_add_line => 'Adicionar linha';
	@override String get changelog_remove_line_aria => 'Remover linha';
	@override String get changelog_placeholder_note => 'Adicionado reordenamento de projetos por arrastar e soltar';
	@override String get changelog_error_no_version => 'Informe uma versão para a entrada.';
	@override String get changelog_known_issues => 'Problemas conhecidos';
	@override String get changelog_known_issues_none => 'Nenhum problema conhecido nesta versão.';
	@override String get changelog_known_issue_placeholder => 'Descreva o problema conhecido...';
	@override String get changelog_remove_known_issue_aria => 'Remover problema conhecido';
	@override String get changelog_add_known_issue => 'Adicionar problema conhecido';
	@override String get changelog_generate_from_git => 'Gerar a partir do Git';
	@override String get changelog_draft_title => 'Notas da versão a partir do Git';
	@override String get changelog_draft_from => 'De';
	@override String get changelog_draft_to => 'Até';
	@override String get changelog_draft_generate => 'Gerar rascunho';
	@override String get changelog_draft_use => 'Usar rascunho';
	@override String get changelog_draft_commits => '{{count}} commit(s)';
	@override String get changelog_draft_include => 'Incluir no rascunho';
	@override String get changelog_draft_none => 'Nenhum commit encontrado neste intervalo.';
	@override String get template_search_placeholder => 'Pesquisar templates…';
	@override String get template_delete_title => 'Excluir template?';
	@override String get template_delete_desc => '"{{name}}" será removido permanentemente.';
	@override String get templates_tab_local => 'Templates locais';
	@override String get templates_tab_asset => 'Biblioteca de Assets';
	@override String get asset_search_placeholder => 'Pesquisar assets…';
	@override String get asset_all_versions => 'Todas as versões';
	@override String get asset_result_count => '{{count}} resultados';
	@override String get asset_load_error => 'Não foi possível carregar a Biblioteca de Assets. Verifique sua conexão e tente novamente.';
	@override String get asset_no_results => 'Nenhum asset encontrado. Tente outra pesquisa.';
	@override String get asset_by_author => 'por {{author}}';
	@override String get asset_open_page => 'Abrir no navegador';
	@override String get asset_install => 'Instalar';
	@override String get asset_install_inside => 'Instalar dentro';
	@override String get asset_installing => 'Instalando…';
	@override String get asset_installed => 'Instalado';
	@override String get asset_prev_page => 'Página anterior';
	@override String get asset_next_page => 'Próxima página';
	@override String get asset_page_x_of_y => 'Página {{page}} de {{total}}';
	@override String template_your_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Template',
		many: 'Templates',
		other: 'Templates',
	);
	@override String get template_imported_count => 'Importados: {{count}}';
	@override String get template_updated_count => 'Atualizados: {{count}}';
	@override String get template_removed_count => 'Removidos: {{count}}';
	@override String get asset_source_all => 'Todas as fontes';
	@override String get asset_source_library => 'Biblioteca de Assets antiga';
	@override String get asset_source_store => 'Nova loja de assets';
	@override String get asset_store_relevance => 'Relevância';
	@override String get asset_store_updated_new => 'Atualizados mais recentemente';
	@override String get asset_store_updated_old => 'Atualizados há mais tempo';
	@override String get asset_store_rating_high => 'Melhor avaliados';
	@override String get asset_store_rating_low => 'Pior avaliados';
	@override String get asset_download_outside => 'Baixar fora';
	@override String get asset_downloaded => 'Baixado';
	@override String get asset_downloaded_to => 'Baixado em';
	@override String get asset_download_error => 'Não foi possível baixar o asset. Verifique sua conexão e tente novamente.';
	@override String get asset_install_modal_title => 'Instalar {{title}}';
	@override String get asset_install_tab_project => 'Em um projeto';
	@override String get asset_install_tab_template => 'Em um template';
	@override String get asset_install_search_projects => 'Pesquisar projetos…';
	@override String get asset_install_no_projects => 'Ainda não há projetos. Crie ou importe um primeiro.';
	@override String get asset_install_no_templates => 'Nenhum template salvo ainda.';
	@override String get asset_install_into => 'Instalar em {{name}}';
	@override String get asset_install_success_project => 'Instalado em {{target}}';
	@override String get asset_install_success_template => 'Adicionado ao template {{target}}';
	@override String get asset_new_template_btn => 'Salvar como novo template';
	@override String get asset_new_template_hint => 'Cria um novo template a partir deste asset de projeto';
	@override String get onboarding_keep_organized => 'Mantenha todos os projetos organizados em um só lugar.';
	@override String get onboarding_download_manage => 'Baixe e gerencie builds da Godot.';
	@override String get onboarding_stay_current => 'Fique por dentro das novidades do Godot.';
	@override String get onboarding_projects_title => 'Onde estão seus projetos?';
	@override String get onboarding_projects_desc => 'Adicione pastas que o GodotHub deve verificar em busca de projetos existentes do Godot ao iniciar. Marque uma com estrela para torná-la o local padrão ao criar um novo projeto. Você pode pular esta etapa e adicionar pastas depois nas Configurações.';
	@override String get onboarding_versions_title => 'Onde ficam as versões do Godot?';
	@override String get onboarding_versions_desc => 'Adicione pastas que o GodotHub deve verificar em busca de executáveis instalados da Godot. Marque uma com estrela para defini-la como local de download das novas versões instaladas pela aba Versões.';
	@override String get onboarding_templates_title => 'Pasta de templates de projeto';
	@override String get onboarding_templates_desc => 'Opcionalmente, defina uma pasta onde você guarda templates de projeto reutilizáveis. Qualquer subpasta dentro dela será importada como template ao concluir, para aparecer ao criar novos projetos. Você também pode salvar projetos individuais como templates a qualquer momento pela visualização Projetos ou importar mais depois pela aba Templates.';
	@override String get onboarding_categories_title => 'Organize com categorias';
	@override String get onboarding_categories_desc_full => 'Categorias são pastas para sua lista de projetos; organize os projetos nelas da maneira que fizer sentido para você. Adicione algumas categorias iniciais ou crie as suas; você pode renomeá-las, reordená-las ou excluí-las a qualquer momento nas Configurações.';
	@override String get onboarding_custom_category_placeholder => 'Nome da categoria personalizada…';
	@override String get onboarding_your_categories => 'Suas categorias';
	@override String get onboarding_customize_title => 'Deixe com a sua cara';
	@override String get onboarding_customize_desc => 'Escolha um tema completo predefinido ou selecione Personalizado e defina suas próprias cores de destaque e fundo. Arredondamento dos cantos, densidade, tamanho do texto e modo claro/escuro ficam disponíveis nas Configurações sempre que você quiser ajustar mais.';
	@override String get onboarding_finish_title => 'Tudo pronto';
	@override String get onboarding_finish_desc => 'O GodotHub está pronto para uso. Você pode revisar tudo isso, pastas, categorias e aparência, pela aba Configurações a qualquer momento.';
	@override String get onboarding_setting_up_title => 'Configurando tudo';
	@override String get onboarding_setting_up_desc => 'Configurando sua biblioteca… procurando projetos e versões do Godot nas pastas. Isso acontece apenas uma vez e não deve demorar.';
	@override String get skipped => 'Ignorado';
	@override String get onboarding_continue => 'Continuar';
	@override String get onboarding_accent_color => 'Cor de destaque';
	@override String get onboarding_bg_color => 'Cor de fundo';
	@override String get onboarding_corner_radius => 'Arredondamento dos cantos';
	@override String get onboarding_discord_rpc => 'Discord Rich Presence';
	@override String get onboarding_discord_rpc_desc => 'Mostre o que você está fazendo no GodotHub no seu perfil do Discord.';
	@override String get version_search_placeholder => 'Pesquisar versões…';
	@override String get version_no_installed => 'Nenhuma versão instalada. Baixe uma versão abaixo ou arraste e solte aqui a pasta de uma versão existente.';
	@override String get version_save_name_aria => 'Salvar nome';
	@override String get version_rename_aria => 'Renomear versão';
	@override String get version_mono_badge => 'Mono';
	@override String get version_uninstall_title => 'Desinstalar versão?';
	@override String get version_uninstall_desc => '"{{tag}}" e seus arquivos serão movidos para a Lixeira do sistema. Você poderá reinstalá-la depois, se necessário.';
	@override String get version_uninstall_confirm => 'Desinstalar';
	@override String get project_remove_title => 'Remover da biblioteca?';
	@override String get project_remove_desc => '"{{name}}" será removido da lista do GodotHub. Seus arquivos permanecerão intactos no disco; você poderá importá-lo novamente a qualquer momento.';
	@override String get project_delete_title => 'Mover para a Lixeira?';
	@override String get project_delete_desc => '"{{name}}" e tudo dentro dele serão movidos para a Lixeira do sistema. Você poderá restaurá-lo depois, se necessário.';
	@override String get project_delete_confirm => 'Mover para a Lixeira';
	@override String get project_template_name_label => 'Nome do template';
	@override String get project_template_desc_label => 'Descrição';
	@override String get project_template_desc_placeholder => 'O que há neste template?';
	@override String get project_save_template_btn => 'Salvar template';
	@override String get template_saved_toast => 'Template salvo.';
	@override String get project_select_aria => 'Selecionar projeto';
	@override String get project_deselect_aria => 'Desmarcar projeto';
	@override String get select_all_visible => 'Selecionar todos os visíveis';
	@override String get selected_count => '{{count}} selecionados';
	@override String get bulk_launch => 'Abrir';
	@override String get bulk_pin => 'Fixar';
	@override String get bulk_remove => 'Remover';
	@override String get bulk_remove_title => 'Remover {{count}} projetos da biblioteca?';
	@override String get bulk_remove_desc => 'Os projetos selecionados serão removidos da sua biblioteca. Os arquivos permanecerão no disco.';
	@override String get bulk_delete_title => 'Excluir {{count}} projetos?';
	@override String get bulk_delete_desc => 'Os arquivos dos projetos selecionados serão movidos permanentemente para a Lixeira. Esta ação não pode ser desfeita.';
	@override String get project_pin_aria => 'Fixar projeto';
	@override String get project_unpin_aria => 'Desafixar projeto';
	@override String get time_today => 'Hoje';
	@override String get time_this_week => 'Esta semana';
	@override String get time_all_time => 'Todo o período';
	@override String get time_tracked_title => 'Tempo registrado';
	@override String get time_weekly_chart => 'Últimos 7 dias';
	@override String get time_week_total => '{{total}} nesta semana';
	@override String get time_weekly_empty => 'Nenhum tempo registrado nos últimos 7 dias.';
	@override String get project_more_aria => 'Mais ações';
	@override String get customize_card_section => 'Cartão do projeto';
	@override String get customize_card_show_size => 'Tamanho do projeto';
	@override String get customize_card_show_time => 'Tempo registrado';
	@override String get customize_card_show_session_timer => 'Show Session Timer';
	@override String get customize_card_blur_path => 'Desfocar diretório do projeto';
	@override String get customize_card_show_path => 'Diretório do projeto';
	@override String get customize_card_show_tags => 'Tags';
	@override String get customize_card_show_last_opened => 'Última abertura';
	@override String get customize_card_show_play => 'Jogar';
	@override String get customize_card_show_console => 'Abrir com console';
	@override String get project_card_remove_library => 'Remover da biblioteca';
	@override String get project_card_delete_files => 'Excluir arquivos';
	@override String get manage_tags => 'Gerenciar tags';
	@override String get tag_input_placeholder => 'Nome da nova tag…';
	@override String get tag_already_exists => 'Já existe uma tag com este nome.';
	@override String get tag_rename_hint => 'Clique para renomear';
	@override String get tag_rename_aria => 'Renomear tag';
	@override String get show_more_tags => 'Mostrar mais tags';
	@override String get show_fewer_tags => 'Mostrar menos tags';
	@override String get clear_tag_filter => 'Limpar filtro de tag';
	@override String get saving_tags => 'Salvando tags…';
	@override String tag_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} tag',
		many: '${count} tag(s)',
		other: '${count} tags',
	);
	@override String get no_tags => 'Ainda não há tags';
	@override String get bug_report_describe_label => 'O que aconteceu?';
	@override String get bug_report_describe_placeholder => 'O que você estava fazendo quando o bug apareceu? Adicione os passos para reproduzir e o que você esperava que acontecesse em comparação com o que realmente aconteceu.';
	@override String get bug_report_diagnostics_label => 'Informações de diagnóstico';
	@override String get bug_report_diagnostics_hint => 'Coletadas automaticamente · incluídas no relatório';
	@override String get bug_report_copied => 'Copiado!';
	@override String get bug_report_copy_log => 'Copiar relatório';
	@override String get bug_report_download_log => 'Baixar relatório';
	@override String get bug_report_open_github => 'Criar issue no GitHub';
	@override String get check_updates_title_modal => 'Verificar atualizações';
	@override String get check_updates_version_available => 'Versão {{version}} disponível';
	@override String get check_updates_ask_download => 'Deseja baixar e instalar agora?';
	@override String get check_updates_release_notes => 'Notas da versão';
	@override String get check_updates_failed => 'Falha ao verificar atualizações';
	@override String get check_updates_rate_limited => 'Limite de requisições do GitHub atingido';
	@override String get check_updates_token_rejected => 'Token do GitHub rejeitado';
	@override String get check_updates_rate_limited_hint => 'O GitHub permite apenas 60 requisições anônimas por hora, compartilhadas com todos na sua rede. Adicionar um token de acesso pessoal nas Configurações aumenta esse limite para 5.000 por hora e ele também é usado para buscar versões do Godot.';
	@override String get check_updates_rate_limited_token_hint => 'Seu token salvo do GitHub foi rejeitado. Ele pode ter expirado ou sido revogado. Teste-o nas Configurações e substitua-o, se necessário.';
	@override String get check_updates_add_token => 'Adicionar token do GitHub';
	@override String get check_updates_open_token_settings => 'Abrir configurações do token';
	@override String get check_updates_preview_badge => 'Prévia';
	@override String get check_updates_portable_title => 'Atualização manual necessária';
	@override String get check_updates_portable_desc => 'Instalações portáteis não podem ser atualizadas automaticamente. Baixe a versão mais recente no GitHub e substitua os arquivos existentes.';
	@override String get check_updates_download_from_github => 'Baixar do GitHub';
	@override String get preview_state_checking => 'Verificando';
	@override String get preview_state_available => 'Disponível';
	@override String get preview_state_downloading => 'Baixando';
	@override String get preview_state_done => 'Concluído';
	@override String get preview_state_uptodate => 'Atualizado';
	@override String get preview_state_error => 'Erro';
	@override String get preview_state_portable => 'Portátil';
	@override String get preview_update_modal => 'Prévia da janela de atualização';
	@override String get clone_repo_title => 'Clonar repositório';
	@override String get clone_repo_url_label => 'URL do repositório';
	@override String get clone_repo_url_placeholder => 'https://github.com/user/my-game.git';
	@override String get clone_repo_error_url => 'Digite a URL de um repositório.';
	@override String get clone_repo_error_location => 'Escolha onde clonar o repositório.';
	@override String get clone_repo_open_after => 'Abrir logo após importar';
	@override String get clone_repo_browse_repos => 'Explorar seus repositórios';
	@override String get clone_repo_url_manual => 'Colar URL manualmente';
	@override String get clone_repo_search_repos => 'Pesquisar seus repositórios...';
	@override String get clone_repo_no_repos_found => 'Nenhum repositório corresponde à sua pesquisa.';
	@override String get clone_repo_loading_repos => 'Carregando repositórios...';
	@override String get clone_repo_load_error => 'Falha ao carregar os repositórios.';
	@override String get clone_repo_select => 'Selecionar';
	@override String get clone_repo_no_account => 'Nenhuma conta do GitHub ou GitLab conectada. Use uma URL para clonar.';
	@override String get clone_repo_repos_loaded => 'repositórios carregados';
	@override String get load_more => 'Carregar mais';
	@override String get git_uncommitted => 'não commitadas';
	@override String get git_clean => 'Sem alterações';
	@override String get task_tray_title => 'Tarefas';
	@override String get task_tray_empty => 'Nenhuma tarefa ativa';
	@override String get task_tray_active_count => '{{active}} ativas, {{recent}} recentes';
	@override String task_tray_only_recent({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} tarefa recente',
		many: '${count} tarefa recente',
		other: '${count} tarefas recentes',
	);
	@override String get task_tray_aria => 'Bandeja do sistema';
	@override String get task_tray_auto_dismiss => 'Concluídas são dispensadas automaticamente';
	@override String get task_tray_dismiss => 'Dispensar {{count}}';
	@override String get task_error_status => 'Erro';
	@override String get command_palette_title => 'Menu de comandos';
	@override String get command_palette_placeholder => 'Pesquisar comandos, projetos, versões da Godot e configurações…';
	@override String get command_palette_no_results => 'Nenhum resultado corresponde';
	@override String get command_palette_navigate => 'Navegar';
	@override String get command_palette_escape => 'Esc';
	@override String get setting_token_placeholder => 'ghp_xxxxxxxxxxxxxxxxxxxx';
	@override String get setting_project_scan_dirs => 'Pastas de busca de projetos';
	@override String get setting_version_scan_dirs => 'Pastas de busca de versões';
	@override String get setting_default_project_location => 'Configuração do local padrão dos projetos';
	@override String get setting_download_dir => 'Configuração do local de download das versões';
	@override String get setting_scan_depth => 'Profundidade da busca';
	@override String get setting_icon_scan_depth => 'Profundidade da busca de ícones do projeto';
	@override String get setting_download_concurrency => 'Downloads simultâneos';
	@override String get setting_close_on_project_open => 'Fechar ao abrir projeto';
	@override String get setting_minimize_to_tray => 'Minimizar para a bandeja do sistema';
	@override String get setting_reopen_after_godot_closes => 'Reabrir após fechar o Godot';
	@override String get setting_auto_scan_on_startup => 'Busca automática ao iniciar';
	@override String get setting_workspaces_enabled => 'Usar espaços de trabalho';
	@override String get setting_directory_naming_convention => 'Convenção de nomes de pastas';
	@override String get setting_git_init_new_projects => 'Inicializar Git em novos projetos';
	@override String get setting_tooltip_delay => 'Atraso das dicas';
	@override String get setting_command_palette_keybind => 'Atalho do menu de comandos';
	@override String get setting_tray_recent_projects_count => 'Projetos recentes na bandeja';
	@override String get setting_last_opened_time_format => 'Formato de hora';
	@override String get setting_last_opened_date_format => 'Formato de data';
	@override String get setting_theme_mode => 'Modo do tema';
	@override String get setting_accent_color => 'Cor de destaque';
	@override String get setting_background_color => 'Cor de fundo';
	@override String get setting_corner_radius => 'Arredondamento dos cantos';
	@override String get setting_ui_density => 'Densidade da interface';
	@override String get setting_font_scale => 'Tamanho do texto';
	@override String get setting_animation_intensity => 'Intensidade das animações';
	@override String get setting_view_entrance => 'Animação de entrada da visualização';
	@override String get setting_custom_css => 'CSS personalizado';
	@override String get setting_project_icon_opacity => 'Opacidade do ícone do projeto';
	@override String get setting_show_scrollbars => 'Mostrar barra de rolagem';
	@override String get setting_setup_wizard => 'Assistente de configuração';
	@override String get setting_reset_settings => 'Redefinir configurações';
	@override String get setting_delete_app_data => 'Excluir dados do aplicativo';
	@override String get setting_check_updates => 'Verificar atualizações';
	@override String get setting_show_support_button => 'Mostrar botão de apoio';
	@override String get setting_show_star_button => 'Mostrar botão de estrela';
	@override String get setting_discord_rpc_enabled => 'Discord Rich Presence';
	@override String get setting_discord_app_id => 'ID do aplicativo do Discord';
	@override String get setting_discord_rpc_show_projects => 'Mostrar nomes de projetos no Discord';
	@override String get setting_discord_rpc_excluded_projects => 'Projetos excluídos do Discord';
	@override String get setting_discord_rpc_project_presences => 'Presença personalizada do Discord';
	@override String get active_workspace => '{{name}} (ativo)';
	@override String get current_workspace => 'Espaço de trabalho atual';
	@override String get switch_workspace => 'Mudar espaço de trabalho';
	@override String get opened_recently => 'Aberto {{label}}';
	@override String get recent_section => 'Recentes';
	@override String get installed_versions_section => 'Versões instaladas';
	@override String get settings_label => 'Configurações → {{tab}}';
	@override String get remove_category_aria => 'Remover {{name}}';
	@override String get git_remove_remote => 'Remover remoto';
	@override String get git_commit_placeholder => 'Mensagem do commit…';
	@override String get restart_required_title => 'Reinicialização necessária';
	@override String get restart_required_desc => 'Esta alteração exige que o GodotHub seja reiniciado para ter efeito completo. A configuração foi salva e será aplicada quando você abrir o aplicativo novamente.';
	@override String found_dismissed_title({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Projeto removido anteriormente encontrado',
		many: '${count} previously removed projects found',
		other: '${count} projetos removidos anteriormente encontrados',
	);
	@override String found_dismissed_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'O scanner encontrou 1 projeto que você havia removido da biblioteca. Deseja adicioná-lo novamente?',
		many: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?',
		other: 'O scanner encontrou ${count} projetos que você havia removido da biblioteca. Deseja adicioná-los novamente?',
	);
	@override String get readd_all => 'Readicionar todos';
	@override String get skip_all => 'Ignorar todos';
	@override String get project_already_open_title => 'Projeto já aberto';
	@override String get project_already_open_desc => '{{name}} já está em execução. Abri-lo novamente inicia uma segunda instância do editor. Abrir mesmo assim?';
	@override String get project_open_anyway => 'Abrir mesmo assim';
	@override String get git_sidebar => 'Barra lateral do Git';
	@override String get asset_duplicate_title => 'Template já instalado';
	@override String get asset_duplicate_desc => '"{{name}}" já está nos seus templates. Deseja instalar uma cópia mesmo assim?';
	@override String get empty_category => 'Categoria vazia';
	@override String get release_to_drop => 'Solte para mover';
	@override String get preview_release_notes => '## Novidades da v1.0.0 - Atualização de prévia\\n\\n## Novidades\\n\\n- Reformulação da janela Verificar atualizações com notas da versão estruturadas\\n- Adicionados anúncios para leitores de tela e uma seção de Acessibilidade nas configurações\\n\\n## Correções\\n\\n- Corrigida uma falha ao trocar de espaço de trabalho com projetos fixados\\n- Corrigidas verificações de atualização que falhavam silenciosamente ao atingir o limite de requisições da API do GitHub\\n\\n## Melhorias\\n\\n- Inicialização mais rápida em todas as plataformas\\n- Reformulação das janelas de espaço de trabalho com seletores de estilo compactos\\n\\n## Problemas conhecidos\\n\\n- Linux: o AppImage pode não funcionar em algumas distribuições; use o pacote .rpm ou .deb\\n- Windows: a barra de tarefas pode exibir brevemente um ícone duplicado até que o aplicativo seja reiniciado';
	@override String get preview_error => 'Erro de prévia: o limite de requisições da API do GitHub foi atingido (HTTP 403). Adicione um token nas Configurações para continuar verificando.';
	@override String get bug_report_system => 'Sistema';
	@override String get bug_report_version => 'Versão';
	@override String get bug_report_date => 'Data';
	@override String get bug_report_os => 'Sistema operacional';
	@override String get bug_report_platform => 'Plataforma';
	@override String get bug_report_language => 'Idioma';
	@override String get bug_report_cpu_cores => 'Núcleos da CPU';
	@override String get bug_report_ram => 'RAM';
	@override String get bug_report_screen => 'Tela';
	@override String get bug_report_gpu => 'GPU';
	@override String get bug_report_user_agent => 'Agente do usuário';
	@override String get bug_report_recent_errors => 'Erros recentes';
	@override String get bug_report_none_captured => 'nenhum capturado';
	@override String get bug_report_description => 'Descrição';
	@override String get bug_report_no_description => 'Nenhuma descrição fornecida';
	@override String get unknown => 'desconhecido';
	@override String get gpu_webgl_unavailable => 'WebGL indisponível';
	@override String get gpu_info_unavailable => 'Informações da GPU indisponíveis';
	@override String get update_available => 'Atualização disponível';
	@override String get dismiss => 'Dispensar';
	@override String get system_language => 'Idioma do sistema';
	@override String get category_empty_hint => 'Crie uma acima para organizar seus projetos';
	@override String get contributor_pr_merged => 'Mesclado';
	@override String get contributor_pr_open => 'Aberto';
	@override String get contributor_pr_closed => 'Fechado';
	@override String get contributor_pr_loading => 'Carregando PRs...';
	@override String contributor_pr_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} pull request',
		many: '${count} pull requests',
		other: '${count} pull requests',
	);
	@override String get contributor_pr_load_failed => 'Não foi possível carregar os pull requests.';
	@override String get contributor_pr_network_hint => 'Verifique sua conexão com a internet.';
	@override String get contributor_pr_empty => 'Nenhum pull request encontrado.';
	@override String get theme_presets_section => 'Theme presets';
	@override String get all_categories => 'Todas as categorias';
	@override String get clear_category_filter => 'Clear category filter';
	@override String get filter_by_category => 'Filter by category';
	@override String get theme_dark => 'Escuro';
	@override String get theme_light => 'Claro';
	@override String get bulk_tags => 'Tags';
	@override String get bulk_tags_title => 'Edit tags';
	@override String get add_tag => 'Adicionar tag';
	@override String get remove_tag => 'Remover tag';
	@override String get no_common_tags => 'No tags on the selected projects yet.';
	@override String get tags_added_to_selection => 'Added tag to {{count}} projects.';
	@override String get tags_removed_from_selection => 'Removed tag from {{count}} projects.';
	@override String get removed_from_library => 'Removed {{count}} project(s) from library.';
	@override String get undo => 'Undo';
	@override String get duplicate_project_title => 'Duplicate project';
	@override String get copy_suffix => 'copy';
	@override String get duplicate => 'Duplicate';
	@override String get destination_folder => 'Pasta de destino';
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
	@override late final _Translations$common$project_doctor$pt_BR project_doctor = _Translations$common$project_doctor$pt_BR._(_root);
	@override late final _Translations$common$build_export$pt_BR build_export = _Translations$common$build_export$pt_BR._(_root);
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
	@override String cleanup_confirm_btn({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Remove ${count} item',
		many: 'Remove ${count} items',
		other: 'Remove ${count} items',
	);
	@override String get cleanup_done => 'Freed {{size}}';
	@override String get cleanup_failed => 'Couldn\'t remove {{label}}: {{error}}';
	@override String get cleanup_versions_desc => 'Full size on disk of every installed Godot version.';
	@override String get cleanup_templates_title => 'Project templates';
	@override String get cleanup_export_templates_title => 'Export templates';
	@override String cleanup_used_by_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} template',
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
	@override String get reset => 'Redefinir';
	@override String get git_disconnect => 'Desconectar';
	@override String get git_sign_in_github => 'Entrar com o GitHub';
	@override String get git_connected_as => 'Conectado como @{{username}}';
	@override String get optional => '(opcional)';
	@override String get language_label => 'Idioma';
	@override String n_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} projeto',
		many: '${count} projects',
		other: '${count} projetos',
	);
	@override String vault_item_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Item',
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
	@override String vault_conflict_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} file already exists in the project. Overwrite it?',
		many: '${count} files already exist in the project. Overwrite them?',
		other: '${count} files already exist in the project. Overwrite them?',
	);
	@override String vault_conflict_summary_desc({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} file already exists across the selected projects. Overwrite it?',
		many: '${count} files already exist across the selected projects. Overwrite them?',
		other: '${count} files already exist across the selected projects. Overwrite them?',
	);
	@override String vault_added_toast({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Added ${count} file',
		many: 'Added ${count} files',
		other: 'Added ${count} files',
	);
	@override String vault_added_to_projects_toast({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Added to ${count} project',
		many: 'Added to ${count} projects',
		other: 'Added to ${count} projects',
	);
	@override String get vault_item_empty => 'This item has no files.';
	@override String get kNew => 'Novo';
	@override String get announcement_support_title => 'Support GodotHub';
	@override String get announcement_support_body => 'GodotHub is free and made in my spare time. If it helps your workflow, please consider supporting development with a donation.';
	@override String get workspace_name_taken_error => 'Another workspace already uses this name.';
	@override String get workspace_start_label => 'Start with';
	@override String get workspace_start_copy => 'Copy settings from {{name}}';
	@override String get workspace_start_copy_desc => 'Theme, language, features, and version folders carry over. Project folders start empty, and you go straight in.';
	@override String get workspace_start_fresh => 'Start fresh';
	@override String get workspace_start_fresh_desc => 'Walk through setup for this workspace from scratch.';
	@override String get workspace_switched_to => 'Switched to';
	@override late final _Translations$common$project_addons$pt_BR project_addons = _Translations$common$project_addons$pt_BR._(_root);
	@override String get reload_confirm_title => 'Reload GodotHub?';
	@override String get reload_confirm_desc => 'Any unsaved changes in open forms will be lost.';
	@override String get color_presets => 'Presets';
	@override String get date_previous_month => 'Previous month';
	@override String get date_next_month => 'Next month';
	@override String get date_change_due => 'Change due date: {{date}}';
	@override String get date_add_due => 'Add due date';
}

// Path: dashboard
class _Translations$dashboard$pt_BR extends Translations$dashboard$en_US {
	_Translations$dashboard$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get greeting_morning => 'Bom dia';
	@override String get greeting_afternoon => 'Boa tarde';
	@override String get greeting_evening => 'Boa noite';
	@override String get greeting_night => 'Boa noite';
	@override String get greeting_name => '{{greeting}}, {{name}}';
	@override String get dashboard_rename_hint => 'Definir um nome personalizado';
	@override String get dashboard_rename_aria => 'Editar nome na saudação';
	@override String get dashboard_rename_save => 'Salvar nome';
	@override String get dashboard_rename_reset => 'Usar nome do sistema';
	@override String get dashboard_name_placeholder => 'Seu nome';
	@override String get dashboard_clock_aria => 'Hora atual';
	@override String get dashboard_new_project => 'Novo projeto';
	@override String get dashboard_import_project => 'Importar projeto';
	@override String get dashboard_scan_projects => 'Procurar projetos';
	@override String get dashboard_stat_projects => 'Projetos';
	@override String get dashboard_stat_templates => 'Templates';
	@override String get dashboard_stat_engines => 'Versões do Godot';
	@override String get dashboard_stat_total_time => 'Tempo total';
	@override String get dashboard_stat_total_time_hint => 'Tempo gasto em projetos';
	@override String get dashboard_recent => 'Abertos recentemente';
	@override String get dashboard_recent_empty => 'Nada foi aberto ainda. Abra um projeto para vê-lo aqui.';
	@override String get dashboard_pinned => 'Fixados';
	@override String get dashboard_pinned_empty => 'Nenhum projeto fixado ainda. Fixe um projeto para mantê-lo à mão.';
	@override String get dashboard_engines => 'Versões do Godot instaladas';
	@override String get dashboard_engines_empty => 'Nenhuma versão do Godot instalada ainda.';
	@override String get dashboard_running => 'Em execução agora';
	@override String get dashboard_running_empty => 'Nada está em execução no momento.';
	@override String get dashboard_opened_at => 'Aberto às {{time}}';
	@override String get dashboard_daily => 'Atividade diária';
	@override String get dashboard_daily_empty => 'Ainda não há atividade diária.';
	@override String get dashboard_weekly => 'Atividade semanal';
	@override String get dashboard_weekly_empty => 'Ainda não há atividade semanal.';
	@override String get dashboard_monthly => 'Atividade mensal';
	@override String get dashboard_monthly_empty => 'Ainda não há atividade mensal.';
	@override String get dashboard_yearly => 'Atividade anual';
	@override String get dashboard_yearly_empty => 'Ainda não há atividade anual.';
	@override String get dashboard_activity_cycle => 'Mudar para {{next}}';
	@override String get dashboard_weekly_aria => 'Tempo registrado: {{label}}';
	@override String get dashboard_top_time => 'Projetos com mais tempo registrado';
	@override String get dashboard_top_time_empty => 'Ainda não há tempo registrado. Abra um projeto para começar a registrar.';
	@override String get dashboard_insights => 'Insights';
	@override String get dashboard_insights_empty => 'Ainda não há tempo registrado. Abra um projeto para começar uma sequência de dias.';
	@override String get dashboard_insights_longest_streak => 'Maior sequência de dias';
	@override String get dashboard_insights_current_streak => 'Sequência atual de dias';
	@override String get dashboard_insights_days => '{{count}} dias';
	@override String get dashboard_insights_productive_day => 'Dia mais produtivo';
	@override String get dashboard_insights_this_month => 'Este mês';
	@override String get dashboard_insights_delta_up => '{{pct}}% a mais que no mês passado';
	@override String get dashboard_insights_delta_down => '{{pct}}% a menos que no mês passado';
	@override String get dashboard_git => 'Visão geral do Git';
	@override String get dashboard_git_empty => 'Nenhum repositório Git detectado.';
	@override String get dashboard_git_clean => 'Sem alterações';
	@override String get dashboard_git_dirty => '{{count}} projetos com alterações ainda sem commit';
	@override String dashboard_git_dirty_plural({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '1 projeto com alterações ainda sem commit',
		many: '${count} projetos com alterações ainda sem commit',
		other: '${count} projetos com alterações ainda sem commit',
	);
	@override String get dashboard_git_branch => 'Em {{branch}}';
	@override String get dashboard_storage => 'Uso do armazenamento';
	@override String get dashboard_storage_empty => 'Nenhum projeto para analisar.';
	@override String get dashboard_storage_loading => 'Medindo…';
	@override String get dashboard_storage_total => '{{size}} no total';
	@override String get dashboard_customize => 'Personalizar';
	@override String get dashboard_done_customizing => 'Concluir';
	@override String get dashboard_customize_hint => 'Use as setas para reorganizar os blocos ou oculte os que você não precisa.';
	@override String get dashboard_tile_move_up => 'Mover para cima';
	@override String get dashboard_tile_move_down => 'Mover para baixo';
	@override String get dashboard_tile_remove => 'Remover';
	@override String get dashboard_tile_span => 'Largura total';
	@override String get dashboard_tile_span_off => 'Meia largura';
	@override String get dashboard_tile_tall => 'Mais alto';
	@override String get dashboard_tile_tall_off => 'Altura normal';
	@override String get dashboard_presets => 'Predefinições de layout';
	@override String get dashboard_preset_default => 'Padrão';
	@override String get dashboard_preset_default_desc => 'Tudo ativado, na ordem padrão e com tamanho padrão.';
	@override String get dashboard_preset_overview => 'Visão geral';
	@override String get dashboard_preset_overview_desc => 'Projetos abertos recentemente, fixados, versões do Godot e projetos em execução.';
	@override String get dashboard_preset_analytics => 'Análises';
	@override String get dashboard_preset_analytics_desc => 'Atividade semanal, principais projetos, armazenamento e categorias, com gráficos mais altos.';
	@override String get dashboard_preset_development => 'Desenvolvimento';
	@override String get dashboard_preset_development_desc => 'Status do Git em destaque, com projetos em execução e versões do Godot.';
	@override String get dashboard_preset_save => 'Salvar layout atual como predefinição';
	@override String get dashboard_preset_save_hint => 'Dê um nome a este layout para poder voltar a ele quando quiser.';
	@override String get dashboard_preset_name_placeholder => 'Nome da predefinição';
	@override String get dashboard_preset_delete => 'Excluir predefinição';
	@override String get dashboard_custom_presets => 'Suas predefinições';
	@override String get dashboard_hidden_tiles => 'Blocos ocultos';
	@override String get dashboard_todos => 'Due to-dos';
	@override String get dashboard_range_daily => 'Dia';
	@override String get dashboard_range_weekly => 'Semana';
	@override String get dashboard_range_monthly => 'Mês';
	@override String get dashboard_range_yearly => 'Ano';
	@override String get dashboard_activity_tracked => 'Registrado';
	@override String get dashboard_activity_peak => 'Pico';
}

// Path: git
class _Translations$git$pt_BR extends Translations$git$en_US {
	_Translations$git$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get remove => 'Remover';
	@override String get changes_title => 'Alterações';
	@override String get pull => 'Pull';
	@override String get push => 'Push';
	@override String get force_push => 'Forçar push';
	@override String get fetch => 'Fetch';
	@override String get change => 'Alteração';
	@override String get commit => 'Commit';
	@override String get committing => 'Fazendo commit…';
	@override String get no_remotes => 'Nenhum repositório remoto configurado';
	@override String get switching => 'Trocando de branch…';
	@override String get no_branches => 'Nenhuma branch encontrada';
	@override String get new_branch_placeholder => 'Nome da branch';
	@override String get delete_branch => 'Excluir branch';
	@override String get publish_branch => 'Publicar branch';
	@override String get publish_branch_to => 'Publish branch to {{remote}}';
	@override String get branch_published => 'Branch publicada.';
	@override String get use_ours => 'Manter versão atual';
	@override String get use_theirs => 'Aceitar versão recebida';
	@override String get i_resolved => 'Marcar como resolvido';
	@override String get undo_last_commit => 'Desfazer último commit';
	@override String get undo_pull => 'Desfazer pull';
	@override String get force_push_confirm_title => 'Forçar push?';
	@override String get force_push_confirm_desc => 'Isso pode sobrescrever commits de outras pessoas no repositório remoto. Deseja continuar?';
	@override String get undo_commit_done => 'Último commit desfeito.';
	@override String get undo_pull_done => 'Pull desfeito.';
	@override String get force_pushed => 'Push forçado concluído.';
	@override String get synced_ok => 'Sincronizado.';
	@override String get fetched_ok => 'Fetch concluído.';
	@override String get pulled_ok => 'Pull concluído.';
	@override String get pushed_ok => 'Push concluído.';
	@override String get branch_created => 'Branch criada.';
	@override String get branch_deleted => 'Branch excluída.';
	@override String get changes_stashed_ok => 'Alterações salvas no stash.';
	@override String get stash_applied_ok => 'Stash aplicado.';
	@override String get stash_popped_ok => 'Stash aplicado e removido.';
	@override String get stash_dropped_ok => 'Stash descartado.';
	@override String get staged_ok => 'Adicionado ao stage.';
	@override String get unstaged_ok => 'Removido do stage.';
	@override String get discarded_ok => 'Descartado.';
	@override String get stage_all_ok => 'Todas as alterações foram adicionadas ao stage.';
	@override String get unstage_all_ok => 'Todas as alterações foram removidas do stage.';
	@override String get discard_all_ok => 'Todas as alterações foram descartadas.';
	@override String get resolved_ours => 'Resolvido mantendo a versão atual.';
	@override String get resolved_theirs => 'Resolvido aceitando a versão recebida.';
	@override String get resolved_manual => 'Conflito marcado como resolvido.';
	@override String get committed_ok => 'Commit realizado.';
	@override String get switched_ok => 'Agora em {{branch}}.';
	@override String get sync => 'Sincronizar';
	@override String get diff_no_diff => 'Nenhum diff disponível para este arquivo.';
	@override String get fetching => 'Buscando…';
	@override String get stashes_title => 'Stashes';
	@override String get stash => 'Stash';
	@override String get stashing => 'Criando stash…';
	@override String get apply_stash => 'Aplicar stash';
	@override String get pop_stash => 'Aplicar e remover stash';
	@override String get drop_stash => 'Descartar stash';
	@override String get merge_aborted => 'Merge cancelado. As alterações do merge foram desfeitas.';
	@override String get new_branch_btn => '+ Nova';
	@override String get abort_merge => 'Cancelar merge';
	@override String get merge_in_progress => 'Merge em andamento';
	@override String get working_tree_clean => 'Sem alterações locais.';
	@override String get staged_changes => 'Alterações no stage';
	@override String get unstage_all_changes => 'Remover tudo do stage';
	@override String get commits_title => 'Commits';
	@override String get stage_file => 'Adicionar arquivo ao stage';
	@override String get discard_file => 'Descartar arquivo';
	@override String get unstage_file => 'Remover arquivo do stage';
	@override String get no_commits_found => 'Nenhum commit encontrado.';
	@override String get stage_all => 'Adicionar tudo ao stage';
	@override String get discard_all => 'Descartar tudo';
	@override String get auth_connected_accounts => 'Contas conectadas';
	@override String get auth_connect_hint => 'Conecte uma conta do serviço Git desejado para começar. Repositórios configurados com SSH podem ser usados sem uma conta conectada.';
	@override String get worktrees_title => 'Worktrees';
	@override String get worktree_current => 'Atual';
	@override String get no_worktrees => 'Nenhuma worktree adicional';
	@override String get switch_worktree => 'Alternar para esta worktree';
	@override String get switched_worktree_ok => 'Worktree alterada.';
	@override String get add_worktree => 'Nova worktree';
	@override String get add_worktree_btn => 'Adicionar worktree';
	@override String get worktree_path_placeholder => 'Caminho (ex.: ../minha-feature)';
	@override String get worktree_branch_placeholder => 'Nome da branch (opcional)';
	@override String get worktree_created_ok => 'Worktree criada.';
	@override String get worktree_dirty => 'Alterações sem commit';
	@override String get remove_worktree => 'Remover worktree';
	@override String get remove_worktree_confirm_desc => 'Remover a worktree em {{path}}? O diretório será excluído. A branch e os commits serão mantidos.';
	@override String get worktree_removed_ok => 'Worktree removida.';
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
class _Translations$nav$pt_BR extends Translations$nav$en_US {
	_Translations$nav$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get dashboard => 'Painel';
	@override String get projects => 'Projetos';
	@override String projects_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Projeto',
		many: 'Projetos',
		other: 'Projetos',
	);
	@override String get versions => 'Versões';
	@override String get templates => 'Templates';
	@override String get vault => 'Vault';
	@override String get asset_store => 'Loja de assets';
	@override String get news => 'Notícias do Godot';
	@override String get storage_view => 'Storage';
	@override String get settings => 'Configurações';
	@override String get changelog => 'Histórico de alterações';
	@override String get group_workspace => 'Espaço de trabalho';
	@override String get group_resources => 'Recursos';
	@override String get group_explore => 'Explorar';
	@override String get you => 'You';
	@override String get account_manage => 'Manage accounts';
	@override String get workspace_tip_title => 'O seletor de espaços foi movido';
	@override String get workspace_tip_body => 'Troque e gerencie espaços de trabalho pelo menu da conta abaixo.';
	@override String get workspace_tip_dismiss => 'Entendi';
}

// Path: onboarding
class _Translations$onboarding$pt_BR extends Translations$onboarding$en_US {
	_Translations$onboarding$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get welcome => 'Boas-vindas';
	@override String get finish => 'Concluir';
	@override String get in_progress => 'Em andamento';
	@override String get prototypes => 'Protótipos';
	@override String get finished => 'Concluídos';
	@override String get game_jams => 'Game Jams';
	@override String get project_folders => 'Pastas de projetos';
	@override String get version_folders => 'Pastas de versões';
	@override String get welcome_title => 'Boas-vindas ao GodotHub';
	@override String get welcome_desc => 'Um só lugar para organizar todos os seus projetos e versões do Godot nesta máquina. Vamos ajustar algumas coisas para deixar tudo do seu jeito. Leva só um minuto. Depois, você também pode ajustar tudo nas Configurações.';
	@override String get onboard_empty_projects => 'Nenhuma pasta adicionada ainda. O GodotHub não encontrará projetos existentes até você adicionar uma. Você também pode adicionar projetos manualmente depois.';
	@override String get onboard_empty_versions => 'Nenhuma pasta adicionada ainda. Novos downloads do Godot serão salvos na pasta de dados do aplicativo até você definir uma pasta abaixo.';
	@override String get onboard_no_template_folder => 'Nenhuma pasta definida. Você também pode configurar isso depois nas Configurações ou salvar templates manualmente.';
	@override String get onboard_cloud_heading => 'Backup na nuvem';
	@override String get onboard_cloud_desc => 'Já tem um backup? Entre com o GitHub e restaure seus espaços de trabalho, projetos e configurações a partir de um gist.';
	@override String get discovery_recent_heading => 'Recent projects from Godot';
	@override String get discovery_installs_heading => 'Godot found on this computer';
	@override String get discovery_scanning_projects => 'Reading Godot\'s project manager list…';
	@override String get discovery_scanning_installs => 'Looking for Godot on your PATH and in Steam…';
	@override String get discovery_engine => 'Godot {{version}}';
	@override String get discovery_favorite => 'Favorite';
	@override String get discovery_add_selected => 'Add selected';
	@override String get discovery_add_selected_count => 'Add selected ({{count}})';
	@override String discovery_added_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Added ${count} project.',
		many: 'Added ${count} projects.',
		other: 'Added ${count} projects.',
	);
	@override String discovery_added_versions({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Added ${count} version.',
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
class _Translations$settings$pt_BR extends Translations$settings$en_US {
	_Translations$settings$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get storage => 'Armazenamento';
	@override String get behavior => 'Comportamento';
	@override String get display => 'Exibição';
	@override String get appearance => 'Aparência';
	@override String get accessibility => 'Acessibilidade';
	@override String get accessibility_desc => 'Avisos do leitor de tela e opções de tecnologias assistivas.';
	@override String get app_version_label => 'GodotHub v{{version}}';
	@override String get landing_dashboard => 'Painel';
	@override String get landing_projects => 'Projetos';
	@override String get landing_versions => 'Versões';
	@override String get landing_news => 'Notícias do Godot';
	@override String get screen_reader_label => 'Avisos do leitor de tela';
	@override String get advanced => 'Avançado';
	@override String get integrations => 'Integrações';
	@override String get motion => 'Motion';
	@override String get data => 'Data & Backup';
	@override String get git_auth_title => 'Entrar com {{provider}}';
	@override String get git_auth_copy_code => 'Copiar código';
	@override String get git_auth_copy_link => 'Copy link';
	@override String get git_auth_waiting => 'Aguardando sua autorização…';
	@override String get git_sign_in_gitlab => 'Entrar com o GitLab';
	@override String get git_connected_to => 'Conectado a {{host}} como @{{username}}';
	@override String get git_self_hosted_title => 'GitLab em servidor próprio';
	@override String get git_self_hosted_desc => 'Conecte-se à sua própria instância do GitLab. Crie um aplicativo OAuth na sua instância (escopos: read_repository, write_repository, read_user) e cole a URL base e o ID do aplicativo.';
	@override String get git_self_hosted_url_placeholder => 'https://gitlab.example.com';
	@override String get git_self_hosted_client_id => 'ID do aplicativo';
	@override String get git_sign_in_self_hosted => 'Entrar com esta instância';
	@override String get git_pat_title => 'Outros hosts (tokens de acesso pessoal)';
	@override String get git_pat_add => 'Adicionar token';
	@override String get git_pat_host_placeholder => 'ex.: codeberg.org';
	@override String get git_pat_username => 'Nome de usuário';
	@override String get git_pat_token => 'Token';
	@override String get git_pat_save => 'Salvar token';
	@override String get git_pat_empty => 'Nenhum token adicionado ainda.';
	@override String get git_pat_remove => 'Remover token';
	@override String get storage_title => 'Armazenamento e busca automática';
	@override String get behavior_projects_title => 'Projetos';
	@override String get file_watchers_title => 'Monitores de arquivos';
	@override String get last_opened_title => 'Última abertura';
	@override String get github_token_title => 'Token da API do GitHub';
	@override String get titlebar_buttons => 'Botões da barra de título';
	@override String get setup_wizard => 'Assistente de configuração';
	@override String get setup_wizard_again => 'Executar assistente de configuração novamente';
	@override String get restart_app => 'Reiniciar aplicativo';
	@override String get restart_app_confirm_title => 'Reiniciar o GodotHub?';
	@override String get restart_app_confirm_desc => 'O aplicativo será fechado e reaberto automaticamente. Operações em andamento e não salvas podem ser interrompidas.';
	@override String get reset_settings => 'Redefinir configurações';
	@override String get delete_app_data => 'Excluir dados do aplicativo';
	@override String get new_project_default => 'padrão';
	@override String get download_folder => 'padrão';
	@override String get system => 'Sistema';
	@override String get k12h => '12 horas (2:30 PM)';
	@override String get k24h => '24 horas (14:30)';
	@override String get dd_mm_yyyy => 'DD-MM-AAAA';
	@override String get mm_dd_yyyy => 'MM-DD-AAAA';
	@override String get yyyy_mm_dd => 'AAAA-MM-DD';
	@override String get reset_all_title => 'Redefinir todas as configurações?';
	@override String get reset_all_desc => 'Isso restaura todas as configurações desta página, pasta de download, pastas configuradas, aparência e comportamento, aos padrões. Esta ação não pode ser desfeita.';
	@override String get delete_all_title => 'Excluir todos os dados do aplicativo?';
	@override String get delete_all_desc => 'Isso exclui permanentemente todos os espaços de trabalho, projetos, categorias, registros de versões instaladas e configurações armazenados pelo GodotHub e reinicia o aplicativo na configuração inicial. As pastas dos projetos e instalações do Godot no disco não serão alteradas, a menos que estejam na pasta de download padrão; nesse caso, também serão excluídas. Esta ação não pode ser desfeita.';
	@override String get empty_hint_projects => 'Nenhuma pasta adicionada. O GodotHub não procurará projetos automaticamente ao iniciar, e você precisará escolher onde salvar cada novo projeto.';
	@override String get empty_hint_versions => 'Nenhuma pasta adicionada. O GodotHub não procurará versões automaticamente ao iniciar, e novos downloads usarão a pasta de dados do aplicativo.';
	@override String get naming_convention_label => 'Convenção de nomes de pastas';
	@override String get naming_keep => 'Manter como digitado (Meu Jogo)';
	@override String get naming_kebab => 'kebab-case (meu-jogo)';
	@override String get naming_snake => 'snake_case (meu_jogo)';
	@override String get naming_camel => 'camelCase (meuJogo)';
	@override String get naming_pascal => 'PascalCase (MeuJogo)';
	@override String get naming_title => 'Title Case (Meu Jogo)';
	@override String get theme => 'Tema';
	@override String get theme_preset_label => 'Tema predefinido';
	@override String get theme_preset_custom => 'Personalizado';
	@override String get preset_light_group => 'Temas claros';
	@override String get preset_dark_group => 'Temas escuros';
	@override String get test => 'Testar';
	@override String get testing => 'Testando…';
	@override String get token_valid => 'Token válido! Limite de requisições: {{status}}';
	@override String get token_resets_in => '(resets ~{{minutes}} min)';
	@override String get test_failed => 'Falha no teste: {{error}}';
	@override String get key_space => 'Espaço';
	@override String get no_settings_match => 'Nenhuma configuração corresponde à busca';
	@override String get scan_result => 'Resultado da busca, Projetos: {{projects}}; versões: {{versions}}.';
	@override String get palette_shortcut => 'Atalho do menu de comandos';
	@override String get keybind_instruction => 'Clique no botão abaixo e pressione qualquer tecla para alterar o atalho.';
	@override String get press => 'Pressione';
	@override String get to_cancel => 'para cancelar';
	@override String get press_key => 'Pressione uma tecla…';
	@override String get click_to_rebind => 'Clique para alterar';
	@override String get close_on_open_label => 'Fechar aplicativo ao abrir projeto';
	@override String get launch_console_label => 'Abrir Godot com o console';
	@override String get builtin_console_label => 'Use the built-in console';
	@override String get minimize_tray_label => 'Minimizar para a bandeja do sistema ao fechar a janela';
	@override String get reopen_label => 'Reabrir após fechar o Godot';
	@override String get no_folder_set => 'Nenhuma pasta definida. Você ainda pode importar manualmente ou usar “Salvar como template”.';
	@override String get ui_density_label => 'Densidade da interface';
	@override String get text_size_label => 'Tamanho do texto';
	@override String get section_godot_versions => 'Versões do Godot';
	@override String get scan_depth_label => 'Profundidade da busca';
	@override String get icon_scan_depth_label => 'Profundidade da busca pelo ícone do projeto';
	@override String get download_concurrency_label => 'Downloads simultâneos';
	@override String get tray_recent_label => 'Projetos recentes na bandeja';
	@override String get tooltip_delay_label => 'Tempo para exibir dicas';
	@override String get project_icon_opacity_label => 'Opacidade do ícone do projeto';
	@override String get time_format_label => 'Formato de hora (para projetos abertos hoje)';
	@override String get date_format_label => 'Formato de data (para projetos abertos em outro dia)';
	@override String get auto_scan_label => 'Busca automática ao iniciar';
	@override String get use_workspaces_label => 'Usar espaços de trabalho';
	@override String get watch_projects_label => 'Monitorar pastas de projetos';
	@override String get watch_versions_label => 'Monitorar pastas de versões';
	@override String get watch_template_label => 'Monitorar pasta de templates';
	@override String get show_scrollbar_label => 'Mostrar barra de rolagem';
	@override String get animated_numbers_label => 'Contadores animados';
	@override String get show_support_label => 'Apoiar';
	@override String get show_star_label => 'Estrela no Github';
	@override String get show_bug_label => 'Reportar bug';
	@override String get show_tray_label => 'Bandeja do sistema';
	@override String get show_language_label => 'Idioma';
	@override String get clear => 'Limpar';
	@override String get reset_to_default => 'Redefinir para o padrão';
	@override String get reset_appearance => 'Restaurar aparência padrão';
	@override String get delete_all => 'Excluir tudo';
	@override String get open_setup => 'Abrir configuração';
	@override String get reset_colors => 'Redefinir cores para o padrão';
	@override String folders_deep({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} nível',
		many: '${count} folders deep',
		other: '${count} níveis',
	);
	@override String get at_once => '{{count}} ao mesmo tempo';
	@override String get animation_speed_label => 'Animation speed';
	@override String get scroll_reveal_label => 'Scroll reveal';
	@override String get card_tilt_label => 'Card tilt on hover';
	@override String get click_ripple_label => 'Click ripple';
	@override String get press_bounce_label => 'Press bounce';
	@override String get animation_intensity_label => 'Intensidade das animações';
	@override String get animation_full => 'Completa';
	@override String get animation_subtle => 'Sutil';
	@override String get animation_none => 'Nenhuma';
	@override String get view_entrance_label => 'Efeito de transição';
	@override String get entrance_fade => 'Esmaecer';
	@override String get entrance_slide => 'Deslizar';
	@override String get entrance_scale => 'Escala';
	@override String get entrance_none => 'Nenhuma';
	@override String get custom_css_label => 'CSS personalizado';
	@override String get custom_css_placeholder => '/* Seus estilos personalizados, por exemplo: */\n.card { border-radius: 4px !important; }';
	@override String get custom_css_apply => 'Aplicar CSS';
	@override String get custom_css_applied => 'CSS aplicado';
	@override String get animation_threshold_label => 'Limite de animação das listas';
	@override String get time_tracking_title => 'Backup do acompanhamento de tempo';
	@override String get export_stats_btn => 'Exportar estatísticas…';
	@override String get import_stats_btn => 'Importar estatísticas…';
	@override String get stats_exported => 'Estatísticas de tempo exportadas.';
	@override String get clear_stats_confirm_title => 'Limpar todos os dados de tempo?';
	@override String get clear_stats_confirm_desc => 'Isso exclui permanentemente todo o histórico de acompanhamento de tempo, os registros de sessão e os totais por projeto. Esta ação não pode ser desfeita.';
	@override String get clear_stats_confirm_btn => 'Limpar tudo';
	@override String get stats_cleared => 'Dados de tempo apagados.';
	@override String get settings_backup_title => 'Backup das configurações';
	@override String get export_settings_btn => 'Exportar configurações';
	@override String get import_settings_btn => 'Importar configurações';
	@override String get workspace_backup_title => 'Backup do espaço de trabalho';
	@override String get workspace_backup_export_btn => 'Exportar espaço de trabalho';
	@override String get workspace_backup_restore_btn => 'Restaurar espaço de trabalho';
	@override String get workspace_backup_exported => 'Backup do espaço de trabalho exportado.';
	@override String get workspace_backup_imported => 'Espaço de trabalho restaurado.';
	@override String get app_backup_title => 'Fazer backup de tudo (todos os espaços de trabalho)';
	@override String get app_backup_export_btn => 'Exportar tudo';
	@override String get app_backup_restore_btn => 'Restaurar tudo';
	@override String get app_backup_exported => 'Backup completo do aplicativo exportado.';
	@override String get app_backup_imported => 'Todos os espaços de trabalho restaurados.';
	@override String get sync_title => 'Sincronização na nuvem (GitHub Gist)';
	@override String get sync_push_btn => 'Enviar backup';
	@override String get sync_pull_btn => 'Restaurar backup';
	@override String get sync_push_done => 'Backup enviado para seu GitHub Gist.';
	@override String get sync_open_gist => 'Abrir Gist';
	@override String get sync_last_pushed => 'Último backup: {{time}}';
	@override String get sync_manual_hint => 'Perdeu seus dados locais? Informe a URL ou o ID do Gist para restaurar a partir de qualquer máquina.';
	@override String get sync_manual_placeholder => 'https://gist.github.com/... ou ID do Gist';
	@override String get sync_manual_pull_btn => 'Restaurar';
	@override String get restore_modal_title => 'Restaurar da nuvem';
	@override String get restore_modal_fetching => 'Buscando backup no GitHub…';
	@override String get restore_modal_applying => 'Aplicando backup e reiniciando…';
	@override String get restore_modal_preview_desc => 'Seu backup no Gist contém:';
	@override String restore_modal_workspaces({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'espaço de trabalho',
		many: 'workspaces',
		other: 'espaços de trabalho',
	);
	@override String restore_modal_projects({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'projeto',
		many: 'projects',
		other: 'projetos',
	);
	@override String restore_modal_categories({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'categoria',
		many: 'categories',
		other: 'categorias',
	);
	@override String restore_modal_templates({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'template',
		many: 'templates',
		other: 'templates',
	);
	@override String get restore_modal_time_stats => 'Inclui dados de acompanhamento de tempo';
	@override String restore_modal_todos({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Includes ${count} to-do',
		many: 'Includes ${count} to-dos',
		other: 'Includes ${count} to-dos',
	);
	@override String get restore_modal_project_scan_dirs => 'Pastas configuradas para projetos: {{count}}';
	@override String get restore_modal_version_scan_dirs => 'Pastas configuradas para versões: {{count}}';
	@override String get restore_modal_workspace_list => 'Espaços de trabalho';
	@override String get restore_modal_warning => 'Isso substituirá suas configurações atuais e os dados dos espaços de trabalho. Você precisará reiniciar o aplicativo para aplicar as alterações.';
	@override String get restore_modal_apply_btn => 'Aplicar e reiniciar';
	@override String get restore_modal_done_title => 'Backup restaurado';
	@override String get restore_modal_done_hint => 'Clique no botão abaixo para reiniciar e aplicar todas as alterações.';
	@override String get settings_exported => 'Configurações exportadas.';
	@override String get settings_imported => 'Configurações importadas.';
	@override String stats_imported({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Estatísticas importadas para ${count} projeto.',
		many: 'Imported stats for ${count} projects.',
		other: 'Estatísticas importadas para ${count} projetos.',
	);
	@override String get raised_contrast_label => 'Contraste dos componentes';
	@override String get raised_contrast_value => '{{value}}%';
	@override String get token_help_desc => 'Crie um token em github.com/settings/tokens. Você só precisa marcar o escopo repo se quiser acesso a repositórios privados; caso contrário, deixe todos os escopos desmarcados. Nenhuma permissão sensível é necessária.';
	@override String get discord_app_id_label => 'ID do aplicativo do Discord';
	@override String get discord_app_id_placeholder => 'Deixe vazio para usar o padrão integrado';
	@override String get discord_app_id_desc => 'Crie um aplicativo no Discord Developer Portal e cole aqui o ID do aplicativo para usar o seu em vez do padrão integrado do GodotHub. A atividade será exibida com o nome desse aplicativo.';
	@override String get discord_developer_portal => 'Discord Developer Portal';
	@override String get discord_builtin_hint => 'Usando o aplicativo integrado do GodotHub.';
	@override String get discord_show_projects_label => 'Mostrar nomes dos projetos';
	@override String get discord_excluded_label => 'Projetos excluídos';
	@override String get discord_exclude_project => 'Adicionar projeto';
	@override String get discord_excluded_empty => 'Nenhum projeto excluído.';
	@override String get discord_excluded_remove => 'Remover dos projetos excluídos';
	@override String get discord_custom_label => 'Discord Rich Presence personalizada';
	@override String get discord_custom_add => 'Adicionar projeto';
	@override String get discord_custom_details_placeholder => 'Linha de detalhes';
	@override String get discord_custom_state_placeholder => 'Linha de estado';
	@override String get discord_custom_remove => 'Remover Discord Rich Presence personalizada';
	@override String get search_placeholder => 'Pesquisar configurações…';
	@override String get interface_label => 'Interface';
	@override String get card_layout_label => 'Layout em cartões';
	@override String get landing_tab_label => 'Página inicial padrão';
	@override String get language_complete => 'Completo';
	@override String get language_beta => 'Beta';
	@override String get language_incomplete => 'Incompleto';
	@override String get use_os_decorations => 'Usar decorações de janela do sistema';
	@override String get credits => 'Créditos';
	@override String get credits_developer => 'Criado por';
	@override String get credits_built_with => 'Desenvolvido com';
	@override String get credits_contributors => 'Colaboradores';
	@override String get experimental => 'Experimental';
	@override String get customize_view_label => 'Botão Personalizar modo de exibição';
	@override String get fixed_sidebar_resize_knob_label => 'Fixed sidebar resize knob';
	@override String get desktop_notifications_label => 'Desktop notifications';
	@override String get colored_titlebar_buttons_label => 'Colored window buttons';
	@override String get project_todos_label => 'Próximos passos dos projetos';
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
	@override String features_enabled_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} feature on',
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
class _Translations$todos$pt_BR extends Translations$todos$en_US {
	_Translations$todos$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get next_steps => 'Próximos passos';
	@override String get saving_tasks => 'Salvando tarefas';
	@override String pending_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} pendente',
		many: '${count} pending',
		other: '${count} pendentes',
	);
	@override String completed_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} concluída',
		many: '${count} completed',
		other: '${count} concluídas',
	);
	@override String get new_task => 'Nova tarefa';
	@override String get hide_next_steps => 'Ocultar próximos passos';
	@override String get save_changes_failed => 'Não foi possível salvar as alterações.';
	@override String get loading_tasks => 'Carregando tarefas...';
	@override String get load_tasks_failed => 'Não foi possível carregar as tarefas';
	@override String get data_unchanged => 'Seus dados não foram modificados.';
	@override String get empty_title => 'Nenhuma tarefa ainda';
	@override String get empty_description => 'Adicione o primeiro próximo passo deste projeto.';
	@override String get create_task => 'Criar tarefa';
	@override String get all_completed_title => 'Tudo concluído';
	@override String get all_completed_description => 'Você concluiu todos os próximos passos deste projeto.';
	@override String get footer_hint => 'Use a lista para acompanhar os próximos passos do projeto.';
	@override String get view_all => 'Ver todas';
	@override String get delete_task_title => 'Excluir tarefa?';
	@override String get delete_task_description => 'A tarefa <strong>“{{title}}”</strong> será excluída. Esta ação não pode ser desfeita.';
	@override String get task => 'Tarefa';
	@override String get area => 'Área';
	@override String get status => 'Status';
	@override String get due_date => 'Prazo';
	@override String get sort_by_status => 'Ordenar por status';
	@override String get sort_by_due_date => 'Ordenar por prazo';
	@override String get change_status => 'Alterar status: {{status}}';
	@override String get overdue => 'Prazo vencido';
	@override String get mark_completed => 'Marcar tarefa como concluída';
	@override String get mark_not_completed => 'Marcar tarefa como não concluída';
	@override String get view_task_details => 'Ver detalhes da tarefa: {{title}}';
	@override String get task_actions => 'Ações da tarefa';
	@override String get edit => 'Editar';
	@override String get status_todo => 'A fazer';
	@override String get status_paused => 'Em pausa';
	@override String get status_in_progress => 'Em andamento';
	@override String get status_done => 'Concluída';
	@override String get area_programming => 'Programação';
	@override String get area_art => 'Arte';
	@override String get area_audio => 'Áudio';
	@override String get area_design => 'Design';
	@override String get area_narrative => 'Narrativa';
	@override String get area_other => 'Outro';
	@override String get edit_task => 'Editar tarefa';
	@override String get title => 'Título';
	@override String get title_placeholder => 'Ex.: Criar menu principal';
	@override String get description_placeholder => 'Adicione mais detalhes sobre o que precisa ser feito...';
	@override String get no_due_date => 'Sem prazo';
	@override String get remove_due_date => 'Remover prazo';
	@override String get past_due_date => 'Este prazo já venceu';
	@override String get save_task_failed => 'Não foi possível salvar a tarefa. Tente novamente.';
	@override String get add_task => 'Adicionar tarefa';
	@override String get no_description => 'Sem descrição';
	@override String get tomorrow => 'Amanhã';
	@override String due_in_days({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Vence em ${count} dia',
		many: 'Due in ${count} days',
		other: 'Vence em ${count} dias',
	);
	@override String get overdue_yesterday => 'Venceu ontem';
	@override String overdue_days({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Venceu há ${count} dia',
		many: 'Overdue by ${count} days',
		other: 'Venceu há ${count} dias',
	);
	@override String get scan_code => 'Scan code';
	@override String get scan_code_hint => 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed';
	@override String get comment_scan_summary => 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened';
	@override String get comment_scan_none => 'Code scan found no changes';
	@override String commit_closed({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Completed ${count} to-do from a commit message',
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
	@override String open_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} to-do',
		many: '${count} to-dos',
		other: '${count} to-dos',
	);
	@override String overdue_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} overdue',
		many: '${count} overdue',
		other: '${count} overdue',
	);
	@override String get tile_summary => '{{overdue}} overdue · {{soon}} due this week';
	@override String get tile_empty => 'Nothing overdue or due this week.';
	@override String due_notification_title({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'To-do due: {{title}}',
		many: '${count} to-dos are due',
		other: '${count} to-dos are due',
	);
	@override String get due_notification_more => 'and {{count}} more';
}

// Path: versions
class _Translations$versions$pt_BR extends Translations$versions$en_US {
	_Translations$versions$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get standard => 'Standard (GDScript)';
	@override String get unbound => 'Não atribuído';
	@override String get mono => 'Mono (.NET)';
	@override String get both => 'Ambos';
	@override String get stable => 'Estável';
	@override String get unstable => 'Instável';
	@override String get rename => 'Renomear';
	@override String get open_editor => 'Abrir Editor';
	@override String get open_editor_with_console => 'Abrir Editor com Console';
	@override String get more_editor_launch_options => 'Mais opções para abrir o editor';
	@override String get open_install_folder => 'Abrir pasta de instalação';
	@override String get type => 'Tipo';
	@override String get channel => 'Canal';
	@override String get fetch_error => 'Não foi possível buscar as versões disponíveis.';
	@override String get paused_dot => 'Pausado · ';
	@override String get available_title => 'VERSÕES DISPONÍVEIS';
	@override String get no_versions_match => 'Nenhuma versão instalada corresponde à busca';
	@override String get no_available_versions_match => 'Nenhuma versão disponível corresponde à busca';
	@override String get open => 'Abrir';
	@override String get install => 'Instalar';
	@override String get mb => 'MB';
	@override String get resume_download => 'Retomar download';
	@override String get pause_download => 'Pausar download';
	@override String get cancel_download => 'Cancelar download';
	@override String installed_count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		zero: 'Nenhuma instalada',
		one: 'Instalada',
		many: 'Installed',
		other: 'Instaladas',
	);
	@override String get installed_label => 'Instalado';
	@override String get original_name => 'Original';
	@override String get source => 'Origem';
	@override String get source_github => 'GitHub';
	@override String get source_archive => 'Godot Archive';
	@override String get source_mise => 'mise';
	@override String get switch_to_archive => 'Mudar para Godot Archive';
	@override String get sort_version_latest => 'Mais recente';
	@override String get sort_version_oldest => 'Mais antiga';
	@override String get sort_version_recently_installed => 'Instalada recentemente';
	@override String get sort_version_oldest_installed => 'Instalada há mais tempo';
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
	@override String alias_create_all({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: 'Create Alias',
		many: 'Create ${count} Aliases',
		other: 'Create ${count} Aliases',
	);
	@override String aliases_batch_created({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '1 alias created',
		many: '${count} aliases created',
		other: '${count} aliases created',
	);
	@override String aliases_batch_skipped({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '1 alias skipped',
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
	@override String get templates_folder => 'Pasta de modelos';
	@override String get versions_folder => 'Pasta de versões';
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
	@override String export_templates_selected({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '1 template selected',
		many: '${count} templates selected',
		other: '${count} templates selected',
	);
	@override String get export_templates_size_summary => '~{{download}} download · {{installed}} on disk';
	@override String get export_templates_download_selected => 'Download selected';
	@override String get export_templates_loading_options => 'Checking this release\'s available templates…';
	@override String get export_templates_options_failed => 'Couldn\'t load the templates for this release.';
	@override String export_templates_available({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '1 available template group',
		many: '${count} available template groups',
		other: '${count} available template groups',
	);
	@override String get export_templates_select_all => 'Select all';
	@override String export_templates_files({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '1 template file',
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
	@override String get download_failed_title => 'Falha no download';
	@override String get download_failed_asset_label => 'Arquivo';
	@override String get download_failed_error_label => 'Detalhes do erro';
	@override String get download_failed_copy => 'Copiar detalhes';
	@override String get download_failed_hint => 'Causas comuns: uma rede ou proxy bloqueado, um antivírus bloqueando o download, uma pasta de download inexistente ou somente leitura, ou pouco espaço em disco.';
	@override String get custom_build_badge => 'Custom build';
	@override String get add_custom_build => 'Add custom build…';
	@override String get adding_custom_build => 'Adding custom build…';
}

// Path: common.project_doctor
class _Translations$common$project_doctor$pt_BR extends Translations$common$project_doctor$en_US {
	_Translations$common$project_doctor$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Project Doctor';
	@override String get scanning => 'Checking this project…';
	@override String get scan_failed => 'Could not check this project';
	@override String get run_again => 'Run checks again';
	@override String summary_errors({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} issue needs attention',
		many: '${count} issues need attention',
		other: '${count} issues need attention',
	);
	@override String summary_warnings({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} warning to review',
		many: '${count} warnings to review',
		other: '${count} warnings to review',
	);
	@override String get summary_ready => 'No blocking issues found';
	@override String get summary_counts => '{{passed}} checks passed · {{findings}} findings';
	@override String passed_checks({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} passed check',
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
class _Translations$common$build_export$pt_BR extends Translations$common$build_export$en_US {
	_Translations$common$build_export$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

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
class _Translations$common$project_addons$pt_BR extends Translations$common$project_addons$en_US {
	_Translations$common$project_addons$pt_BR._(TranslationsPtBr root) : this._root = root, super.internal(root);

	final TranslationsPtBr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Addons';
	@override String get loading => 'Reading addons…';
	@override String count({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} addon installed',
		many: '${count} addons installed',
		other: '${count} addons installed',
	);
	@override String get empty => 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.';
	@override String get check_updates => 'Check for updates';
	@override String get checking => 'Checking…';
	@override String updates_available({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count,
		one: '${count} update available',
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

/// The flat map containing all translations for locale <pt-BR>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsPtBr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'changelog.changelog_title' => 'REGISTRO DE ALTERAÇÕES',
			'changelog.no_entries' => 'Ainda não há entradas no registro de alterações',
			'changelog.delete_entry_title' => 'Excluir entrada do registro de alterações?',
			'changelog.delete_entry_desc' => 'Isso removerá a entrada permanentemente. Esta ação não pode ser desfeita.',
			'changelog.changelog_subtitle' => 'Um histórico das atualizações do GodotHub.',
			'changelog.edit_entry_aria' => 'Edit {{version}}',
			'changelog.delete_entry_aria' => 'Delete {{version}}',
			'changelog.added' => 'Adicionado',
			'changelog.fixed' => 'Corrigido',
			'changelog.improved' => 'Melhorado',
			'common.new_project' => 'Novo projeto',
			'common.import_project' => 'Importar projeto',
			'common.search' => 'Pesquisar',
			'common.cancel' => 'Cancelar',
			'common.save' => 'Salvar',
			'common.delete' => 'Excluir',
			'common.close' => 'Fechar',
			'common.loading' => 'Carregando...',
			'common.retry' => 'Tentar novamente',
			'common.stop' => 'Parar',
			'common.refresh' => 'Atualizar',
			'common.scroll_to_top' => 'Voltar ao topo',
			'common.quick_commands' => 'Comandos rápidos',
			'common.minimize' => 'Minimizar',
			'common.close_sidebar' => 'Fechar barra lateral',
			'common.star_on_github' => 'Dar estrela no GitHub',
			'common.support_dev' => 'Apoie o desenvolvimento no Patreon. Você pode desativar isso nas Configurações',
			'common.support' => 'Apoiar',
			'common.restore' => 'Restaurar',
			'common.maximize' => 'Maximizar',
			'common.importing_project' => 'Importando projeto…',
			'common.importing_version' => 'Importando versão…',
			'common.scanning_projects' => 'Procurando projetos…',
			'common.scanning_versions' => 'Procurando versões…',
			'common.queued' => 'Queued…',
			'common.download_queue_move_up' => 'Mover para mais cedo na fila',
			'common.download_queue_move_down' => 'Mover para mais tarde na fila',
			'common.running' => 'Em execução',
			'common.running_projects_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} projeto em execução', many: '${count} projects running', other: '${count} projetos em execução', ), 
			'common.active' => 'Ativo',
			'common.done' => 'Concluído',
			'common.paused' => 'Pausado',
			'common.no_tasks_running' => 'Nenhuma tarefa em execução',
			'common.checking_changes' => 'Verificando alterações…',
			'common.cloning' => 'Clonando…',
			'common.clone_import' => 'Clonar e importar',
			'common.import' => 'Importar',
			'common.syncing' => 'Sincronizando…',
			'common.edit_entry' => 'Editar entrada do registro de alterações',
			'common.new_entry' => 'Nova entrada do registro de alterações',
			'common.checking_updates' => 'Verificando atualizações…',
			'common.up_to_date' => 'Atualizado',
			'common.downloading_update' => 'Baixando…',
			'common.install_update' => 'Instalar',
			'common.restart_now' => 'Reiniciar agora',
			'common.update_downloaded' => 'Atualização baixada!',
			'common.restart_to_apply' => 'Reinicie o GodotHub para aplicar a atualização.',
			'common.update_applied_desc' => 'A atualização foi baixada e será aplicada na próxima vez que você reiniciar o GodotHub. Feche e abra o aplicativo novamente para concluir a atualização.',
			'common.is_latest' => 'v{{version}} é a versão mais recente.',
			'common.percent_complete' => '{{percent}}% concluído',
			'common.expand_sidebar' => 'Expandir barra lateral',
			'common.collapse_sidebar' => 'Recolher barra lateral',
			'common.saving' => 'Salvando…',
			'common.save_changes' => 'Salvar alterações',
			'common.add_entry' => 'Adicionar entrada',
			'common.scan_for_projects' => 'Procurar projetos',
			'common.create_workspace' => 'Criar espaço de trabalho',
			'common.report_a_bug' => 'Reportar um bug',
			'common.report_bug' => 'Reportar bug',
			'common.app_error_title' => 'Algo deu errado',
			'common.app_error_desc' => 'O GodotHub encontrou um erro inesperado e não conseguiu renderizar. Veja os detalhes abaixo e consulte o console (clique com o botão direito → Inspecionar) para ver o stack trace completo.',
			'common.reload' => 'Recarregar',
			'common.view_error_title' => 'This view couldn\'t load',
			'common.view_error_desc' => 'The rest of GodotHub still works. Try loading this view again, or switch to another one.',
			'common.error_details' => 'Technical details',
			'common.remove_folder' => 'Remover pasta',
			'common.make_this_default' => 'Definir como {{label}}',
			'common.suggested_from_workspaces' => 'Sugerido a partir de outros espaços de trabalho',
			'common.from_workspace' => 'de {{name}}',
			'common.add_folder' => 'Adicionar pasta',
			'common.default_folder' => 'Padrão',
			'common.default_downloads_go_to' => 'Sem uma pasta padrão, novas versões do Godot serão salvas em "{{path}}".',
			'common.open_terminal' => 'Abrir terminal',
			'common.downloading_version' => 'Baixando {{version}}',
			'common.downloading_asset' => 'Baixando {{title}}',
			'common.asset_download_failed' => 'Falha ao baixar o template',
			'common.scan_for_engines' => 'Procurar versões da Godot',
			'common.import_version' => 'Importar versão',
			'common.sync_templates_from_directory' => 'Sincronizar templates a partir de uma pasta',
			'common.section_navigation' => 'Navegação',
			'common.section_projects' => 'Projetos',
			'common.section_views' => 'Modos de exibição',
			'common.section_workspaces' => 'Espaços de trabalho',
			'common.section_help' => 'Ajuda',
			'common.section_engines' => 'Versões da Godot',
			'common.section_templates' => 'Templates',
			'common.section_versions' => 'Versões',
			'common.section_news' => 'Notícias',
			'common.skip_setup' => 'Pular configuração',
			'common.back' => 'Voltar',
			'common.finishing' => 'Finalizando…',
			'common.get_started' => 'Começar',
			'common.scanning' => 'Procurando…',
			'common.scan_now' => 'Procurar agora',
			'common.scan_complete' => 'Busca concluída',
			'common.scan_failed' => 'Falha na busca',
			'common.uncategorized' => 'Sem categoria',
			'common.all' => 'Todos',
			'common.no_filter' => 'Sem filtro',
			'common.cannot_undo' => 'Esta ação não pode ser desfeita.',
			'common.deleting' => 'Excluindo…',
			'common.open_project' => 'Abrir',
			'common.play_project' => 'Jogar',
			'common.play_project_tooltip' => 'Jogue sem abrir o editor',
			'common.no_version_selected' => 'Nenhuma versão selecionada',
			'common.open_with_console' => 'Abrir com console',
			'common.open_folder' => 'Abrir pasta',
			'common.open_in_ide' => 'Abrir na IDE',
			'common.category' => 'Categoria',
			'common.none' => 'Nenhum',
			'common.project_size' => 'Tamanho do projeto',
			'common.project_size_scanning' => 'Scanning project files…',
			'common.project_size_empty' => 'No files found',
			'common.launch_arguments' => 'Parâmetros de inicialização',
			'common.save_as_template' => 'Salvar como template',
			'common.git' => 'Git',
			'common.add' => 'Adicionar',
			'common.color_label' => 'Cor',
			'common.icon_label' => 'Ícone',
			'common.expand' => 'Expandir',
			'common.collapse' => 'Recolher',
			'common.file_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} arquivo', many: '${count} arquivo', other: '${count} arquivos', ), 
			'common.folder_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} pasta', many: '${count} pasta', other: '${count} pastas', ), 
			'common.template_empty' => 'Este template está vazio.',
			'common.categories' => 'Categorias',
			'common.category_folders_hint' => 'Projetos encontrados nas pastas de uma categoria são atribuídos a ela automaticamente.',
			'common.assign_folder' => 'Atribuir pasta',
			'common.assign_folder_to_category' => 'Atribuir uma pasta a {{name}}',
			'common.unassign_folder_aria' => 'Remover {{folder}} desta categoria',
			'common.new_category_placeholder' => 'Nome da nova categoria…',
			'common.no_categories_yet' => 'Ainda não há categorias. Adicione uma acima.',
			'common.edit_category' => 'Editar {{name}}',
			'common.delete_category' => 'Excluir {{name}}',
			'common.delete_category_title' => 'Excluir categoria?',
			'common.delete_category_desc' => '"{{name}}" será removida. Os projetos dentro dela irão para Sem categoria; nada no disco será alterado.',
			'common.project_name_label' => 'Nome',
			'common.folder_name_preview' => 'Convenção da pasta: {{name}}',
			'common.folder_name_hint' => 'O nome da pasta é derivado do nome do projeto usando sua convenção de nomenclatura.',
			'common.template_preview_aria' => 'Prévia de {{name}}',
			'common.project_location_label' => 'Local',
			'common.choose_folder_placeholder' => 'Escolha uma pasta',
			'common.browse' => 'Procurar',
			'common.blank_template' => 'Padrão',
			'common.template_optional' => 'Template (opcional)',
			'common.category_optional' => 'Categoria (opcional)',
			'common.no_category_label' => 'Sem categoria',
			'common.godot_version_label' => 'Versão do Godot',
			'common.no_engine_warning' => 'Nenhuma versão da Godot instalada ainda. Baixe uma primeiro na aba Versões.',
			'common.change_icon' => 'Alterar',
			'common.choose_icon' => 'Escolher',
			'common.icon_format_desc' => 'SVG, PNG ou JPG. O padrão é o logo do Godot.',
			'common.other_settings_label' => 'Outras configurações',
			'common.init_git_label' => 'Inicializar repositório Git',
			'common.init_git_desc' => 'Adiciona um .gitignore e .gitattributes do Godot e então faz um commit inicial na main.',
			'common.init_git_unavailable' => 'Instale o Git e reinicie o GodotHub para usar isto.',
			'common.initializing_git' => 'Configurando Git…',
			'common.git_init_warning_title' => 'Projeto criado, o Git precisa de atenção',
			'common.git_option_gitignore' => '.gitignore do Godot',
			'common.git_option_gitattributes' => '.gitattributes',
			'common.git_option_readme' => 'README.md',
			'common.git_option_license' => 'Licença',
			'common.git_option_no_license' => 'Sem licença',
			'common.create_remote_label' => 'Criar repositório no GitHub/GitLab',
			'common.create_remote_desc' => 'Cria um repositório na sua conta conectada e envia o commit inicial.',
			'common.remote_private' => 'Privado',
			'common.remote_public' => 'Público',
			'common.creating_remote_repo' => 'Criando repositório remoto…',
			'common.remote_repo_created_title' => 'Repositório remoto criado',
			'common.create_project_done' => 'Concluído',
			'common.create_project_btn' => 'Criar projeto',
			'common.creating' => 'Criando…',
			'common.create_project_error' => 'Dê um nome ao projeto e escolha uma pasta para criá-lo.',
			'common.create_workspace_title' => 'Novo espaço de trabalho',
			'common.workspace_name_label' => 'Nome',
			'common.workspace_name_placeholder' => 'Trabalho, Pessoal, Game Jam…',
			'common.workspace_name_required_error' => 'Dê um nome ao espaço de trabalho.',
			'common.edit_workspace_title' => 'Editar espaço de trabalho',
			'common.cant_delete_only_workspace' => 'Você não pode excluir seu único espaço de trabalho',
			'common.delete_workspace_title' => 'Excluir espaço de trabalho?',
			'common.delete_workspace_desc' => '"{{name}}" e tudo o que pertence a ele (configurações, projetos e categorias) serão removidos. Os arquivos dos projetos no disco nunca são alterados. As versões instaladas do Godot são compartilhadas e permanecerão intactas.',
			'common.other' => 'Outro',
			'common.args_label' => 'Parâmetros',
			'common.args_placeholder' => 'ex.: --debug --single-window',
			'common.args_suggestions' => 'Sugestões',
			'common.args_desc_separate_prefix' => 'Separe os parâmetros com espaços. Flags com valores, como',
			'common.args_desc_separate_suffix' => 'usam dois tokens.',
			'common.args_debug' => '--debug',
			'common.args_debug_desc' => 'Executar com o depurador anexado',
			'common.args_single_window' => '--single-window',
			'common.args_single_window_desc' => 'Forçar modo de janela única',
			'common.args_opengl3' => '--rendering-driver opengl3',
			'common.args_opengl3_desc' => 'Usar o driver de renderização OpenGL 3',
			'common.args_vulkan' => '--rendering-driver vulkan',
			'common.args_vulkan_desc' => 'Usar o driver de renderização Vulkan',
			'common.args_headless' => '--headless',
			'common.args_headless_desc' => 'Executar sem uma janela',
			'common.args_verbose' => '--verbose',
			'common.args_verbose_desc' => 'Registrar saída detalhada de depuração',
			'common.args_editor' => '--editor',
			'common.args_editor_desc' => 'Abrir o editor (igual a -e)',
			'common.args_build_solutions' => '--build-solutions',
			'common.args_build_solutions_desc' => 'Compilar soluções C# ao abrir',
			'common.args_gpu_index' => '--gpu-index 1',
			'common.args_gpu_index_desc' => 'Usar a GPU de índice 1 (GPU dedicada)',
			'common.sort_categories' => 'Categorias',
			'common.sort_recent' => 'Abertos recentemente',
			'common.sort_manual' => 'Manual',
			'common.sort_name_asc' => 'Nome (A–Z)',
			'common.sort_name_desc' => 'Nome (Z–A)',
			'common.sort_created_desc' => 'Data de adição (mais recente)',
			'common.sort_created_asc' => 'Data de adição (mais antiga)',
			'common.sort_time_desc' => 'Tempo total',
			'common.filter' => 'Filtrar',
			'common.no_templates_yet' => 'Ainda não há templates. Clique com o botão direito em um projeto ou abra o menu "Mais" e selecione <1>Salvar como template</1> para criar um, ou baixe templates da Biblioteca de Assets.',
			'common.godot' => 'Godot',
			'common.delete_template' => 'Excluir template {{name}}',
			'common.news_subtitle' => 'Publicações mais recentes do blog oficial do Godot Engine.',
			'common.news_cached' => 'Não foi possível acessar godotengine.org; exibindo os artigos salvos da última vez.',
			'common.news_error' => 'Não foi possível carregar as notícias do Godot.',
			'common.news_empty' => 'Nenhuma notícia para mostrar no momento.',
			'common.show_more' => 'Mostrar mais',
			'common.try_again' => 'Tentar novamente',
			'common.asset_store_title' => 'LOJA DE ASSETS',
			'common.news_count' => 'Publicações',
			'common.asset_store_count_plural' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, zero: 'Nenhum asset', one: 'Asset', many: 'Assets', other: 'Assets', ), 
			'common.asset_store_count' => 'Assets',
			'common.settings_title' => 'CONFIGURAÇÕES',
			'common.no_templates_match' => 'Nenhum template corresponde à busca',
			'common.no_projects_match' => 'Nenhum projeto corresponde à busca',
			'common.more_import_options' => 'Mais opções de importação',
			'common.clone_import_repo' => 'Clonar e importar de um repositório',
			'common.manage_categories' => 'Gerenciar categorias',
			'common.hide_category' => 'Hide Category',
			'common.category_hidden_toast' => '"{{name}}" hidden. Restore it from Hidden Categories.',
			'common.hidden_categories' => 'Hidden Categories',
			'common.hidden_categories_hint' => 'Those categories and their projects stay out of the way. Unhide one to bring it back.',
			'common.hidden_category_projects' => '{{count}} project(s)',
			'common.unhide' => 'Unhide',
			'common.unhide_category_aria' => 'Unhide {{name}}',
			'common.search_projects_placeholder' => 'Pesquisar projetos...',
			'common.clear_search' => 'Limpar pesquisa',
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
			'common.sort' => 'Ordenar',
			'common.view_list' => 'Lista',
			'common.view_grid' => 'Grade',
			'common.view_kanban' => 'Kanban',
			'common.no_projects_yet' => 'Ainda não há nada aqui. Crie um novo projeto ou importe um que já esteja no disco.',
			'common.pinned_section' => 'Fixados',
			'common.set_category' => 'Definir categoria…',
			'common.clear_selection' => 'Limpar seleção',
			'common.starting' => 'Iniciando…',
			'common.app_loading' => 'Carregando…',
			'common.changelog_version_label' => 'Versão',
			'common.changelog_version_placeholder' => 'v1.0.0',
			'common.changelog_date_label' => 'Data',
			'common.changelog_date_placeholder' => '2026-07-13',
			'common.changelog_what_changed' => 'O que mudou',
			'common.changelog_add_line' => 'Adicionar linha',
			'common.changelog_remove_line_aria' => 'Remover linha',
			'common.changelog_placeholder_note' => 'Adicionado reordenamento de projetos por arrastar e soltar',
			'common.changelog_error_no_version' => 'Informe uma versão para a entrada.',
			'common.changelog_known_issues' => 'Problemas conhecidos',
			'common.changelog_known_issues_none' => 'Nenhum problema conhecido nesta versão.',
			'common.changelog_known_issue_placeholder' => 'Descreva o problema conhecido...',
			'common.changelog_remove_known_issue_aria' => 'Remover problema conhecido',
			'common.changelog_add_known_issue' => 'Adicionar problema conhecido',
			'common.changelog_generate_from_git' => 'Gerar a partir do Git',
			'common.changelog_draft_title' => 'Notas da versão a partir do Git',
			'common.changelog_draft_from' => 'De',
			'common.changelog_draft_to' => 'Até',
			'common.changelog_draft_generate' => 'Gerar rascunho',
			'common.changelog_draft_use' => 'Usar rascunho',
			'common.changelog_draft_commits' => '{{count}} commit(s)',
			'common.changelog_draft_include' => 'Incluir no rascunho',
			'common.changelog_draft_none' => 'Nenhum commit encontrado neste intervalo.',
			'common.template_search_placeholder' => 'Pesquisar templates…',
			'common.template_delete_title' => 'Excluir template?',
			'common.template_delete_desc' => '"{{name}}" será removido permanentemente.',
			'common.templates_tab_local' => 'Templates locais',
			'common.templates_tab_asset' => 'Biblioteca de Assets',
			'common.asset_search_placeholder' => 'Pesquisar assets…',
			'common.asset_all_versions' => 'Todas as versões',
			'common.asset_result_count' => '{{count}} resultados',
			'common.asset_load_error' => 'Não foi possível carregar a Biblioteca de Assets. Verifique sua conexão e tente novamente.',
			'common.asset_no_results' => 'Nenhum asset encontrado. Tente outra pesquisa.',
			'common.asset_by_author' => 'por {{author}}',
			'common.asset_open_page' => 'Abrir no navegador',
			'common.asset_install' => 'Instalar',
			'common.asset_install_inside' => 'Instalar dentro',
			'common.asset_installing' => 'Instalando…',
			'common.asset_installed' => 'Instalado',
			'common.asset_prev_page' => 'Página anterior',
			'common.asset_next_page' => 'Próxima página',
			'common.asset_page_x_of_y' => 'Página {{page}} de {{total}}',
			'common.template_your_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Template', many: 'Templates', other: 'Templates', ), 
			'common.template_imported_count' => 'Importados: {{count}}',
			'common.template_updated_count' => 'Atualizados: {{count}}',
			'common.template_removed_count' => 'Removidos: {{count}}',
			'common.asset_source_all' => 'Todas as fontes',
			'common.asset_source_library' => 'Biblioteca de Assets antiga',
			'common.asset_source_store' => 'Nova loja de assets',
			'common.asset_store_relevance' => 'Relevância',
			'common.asset_store_updated_new' => 'Atualizados mais recentemente',
			'common.asset_store_updated_old' => 'Atualizados há mais tempo',
			'common.asset_store_rating_high' => 'Melhor avaliados',
			'common.asset_store_rating_low' => 'Pior avaliados',
			'common.asset_download_outside' => 'Baixar fora',
			'common.asset_downloaded' => 'Baixado',
			'common.asset_downloaded_to' => 'Baixado em',
			'common.asset_download_error' => 'Não foi possível baixar o asset. Verifique sua conexão e tente novamente.',
			'common.asset_install_modal_title' => 'Instalar {{title}}',
			'common.asset_install_tab_project' => 'Em um projeto',
			'common.asset_install_tab_template' => 'Em um template',
			'common.asset_install_search_projects' => 'Pesquisar projetos…',
			'common.asset_install_no_projects' => 'Ainda não há projetos. Crie ou importe um primeiro.',
			'common.asset_install_no_templates' => 'Nenhum template salvo ainda.',
			'common.asset_install_into' => 'Instalar em {{name}}',
			'common.asset_install_success_project' => 'Instalado em {{target}}',
			'common.asset_install_success_template' => 'Adicionado ao template {{target}}',
			'common.asset_new_template_btn' => 'Salvar como novo template',
			'common.asset_new_template_hint' => 'Cria um novo template a partir deste asset de projeto',
			'common.onboarding_keep_organized' => 'Mantenha todos os projetos organizados em um só lugar.',
			'common.onboarding_download_manage' => 'Baixe e gerencie builds da Godot.',
			'common.onboarding_stay_current' => 'Fique por dentro das novidades do Godot.',
			'common.onboarding_projects_title' => 'Onde estão seus projetos?',
			'common.onboarding_projects_desc' => 'Adicione pastas que o GodotHub deve verificar em busca de projetos existentes do Godot ao iniciar. Marque uma com estrela para torná-la o local padrão ao criar um novo projeto. Você pode pular esta etapa e adicionar pastas depois nas Configurações.',
			'common.onboarding_versions_title' => 'Onde ficam as versões do Godot?',
			'common.onboarding_versions_desc' => 'Adicione pastas que o GodotHub deve verificar em busca de executáveis instalados da Godot. Marque uma com estrela para defini-la como local de download das novas versões instaladas pela aba Versões.',
			'common.onboarding_templates_title' => 'Pasta de templates de projeto',
			'common.onboarding_templates_desc' => 'Opcionalmente, defina uma pasta onde você guarda templates de projeto reutilizáveis. Qualquer subpasta dentro dela será importada como template ao concluir, para aparecer ao criar novos projetos. Você também pode salvar projetos individuais como templates a qualquer momento pela visualização Projetos ou importar mais depois pela aba Templates.',
			'common.onboarding_categories_title' => 'Organize com categorias',
			'common.onboarding_categories_desc_full' => 'Categorias são pastas para sua lista de projetos; organize os projetos nelas da maneira que fizer sentido para você. Adicione algumas categorias iniciais ou crie as suas; você pode renomeá-las, reordená-las ou excluí-las a qualquer momento nas Configurações.',
			'common.onboarding_custom_category_placeholder' => 'Nome da categoria personalizada…',
			'common.onboarding_your_categories' => 'Suas categorias',
			'common.onboarding_customize_title' => 'Deixe com a sua cara',
			'common.onboarding_customize_desc' => 'Escolha um tema completo predefinido ou selecione Personalizado e defina suas próprias cores de destaque e fundo. Arredondamento dos cantos, densidade, tamanho do texto e modo claro/escuro ficam disponíveis nas Configurações sempre que você quiser ajustar mais.',
			'common.onboarding_finish_title' => 'Tudo pronto',
			'common.onboarding_finish_desc' => 'O GodotHub está pronto para uso. Você pode revisar tudo isso, pastas, categorias e aparência, pela aba Configurações a qualquer momento.',
			'common.onboarding_setting_up_title' => 'Configurando tudo',
			'common.onboarding_setting_up_desc' => 'Configurando sua biblioteca… procurando projetos e versões do Godot nas pastas. Isso acontece apenas uma vez e não deve demorar.',
			'common.skipped' => 'Ignorado',
			'common.onboarding_continue' => 'Continuar',
			'common.onboarding_accent_color' => 'Cor de destaque',
			'common.onboarding_bg_color' => 'Cor de fundo',
			'common.onboarding_corner_radius' => 'Arredondamento dos cantos',
			'common.onboarding_discord_rpc' => 'Discord Rich Presence',
			'common.onboarding_discord_rpc_desc' => 'Mostre o que você está fazendo no GodotHub no seu perfil do Discord.',
			'common.version_search_placeholder' => 'Pesquisar versões…',
			'common.version_no_installed' => 'Nenhuma versão instalada. Baixe uma versão abaixo ou arraste e solte aqui a pasta de uma versão existente.',
			'common.version_save_name_aria' => 'Salvar nome',
			'common.version_rename_aria' => 'Renomear versão',
			'common.version_mono_badge' => 'Mono',
			'common.version_uninstall_title' => 'Desinstalar versão?',
			'common.version_uninstall_desc' => '"{{tag}}" e seus arquivos serão movidos para a Lixeira do sistema. Você poderá reinstalá-la depois, se necessário.',
			'common.version_uninstall_confirm' => 'Desinstalar',
			'common.project_remove_title' => 'Remover da biblioteca?',
			'common.project_remove_desc' => '"{{name}}" será removido da lista do GodotHub. Seus arquivos permanecerão intactos no disco; você poderá importá-lo novamente a qualquer momento.',
			'common.project_delete_title' => 'Mover para a Lixeira?',
			'common.project_delete_desc' => '"{{name}}" e tudo dentro dele serão movidos para a Lixeira do sistema. Você poderá restaurá-lo depois, se necessário.',
			'common.project_delete_confirm' => 'Mover para a Lixeira',
			'common.project_template_name_label' => 'Nome do template',
			'common.project_template_desc_label' => 'Descrição',
			'common.project_template_desc_placeholder' => 'O que há neste template?',
			'common.project_save_template_btn' => 'Salvar template',
			'common.template_saved_toast' => 'Template salvo.',
			'common.project_select_aria' => 'Selecionar projeto',
			'common.project_deselect_aria' => 'Desmarcar projeto',
			'common.select_all_visible' => 'Selecionar todos os visíveis',
			'common.selected_count' => '{{count}} selecionados',
			'common.bulk_launch' => 'Abrir',
			'common.bulk_pin' => 'Fixar',
			'common.bulk_remove' => 'Remover',
			'common.bulk_remove_title' => 'Remover {{count}} projetos da biblioteca?',
			'common.bulk_remove_desc' => 'Os projetos selecionados serão removidos da sua biblioteca. Os arquivos permanecerão no disco.',
			'common.bulk_delete_title' => 'Excluir {{count}} projetos?',
			'common.bulk_delete_desc' => 'Os arquivos dos projetos selecionados serão movidos permanentemente para a Lixeira. Esta ação não pode ser desfeita.',
			'common.project_pin_aria' => 'Fixar projeto',
			'common.project_unpin_aria' => 'Desafixar projeto',
			'common.time_today' => 'Hoje',
			'common.time_this_week' => 'Esta semana',
			'common.time_all_time' => 'Todo o período',
			'common.time_tracked_title' => 'Tempo registrado',
			'common.time_weekly_chart' => 'Últimos 7 dias',
			'common.time_week_total' => '{{total}} nesta semana',
			'common.time_weekly_empty' => 'Nenhum tempo registrado nos últimos 7 dias.',
			'common.project_more_aria' => 'Mais ações',
			'common.customize_card_section' => 'Cartão do projeto',
			'common.customize_card_show_size' => 'Tamanho do projeto',
			'common.customize_card_show_time' => 'Tempo registrado',
			'common.customize_card_show_session_timer' => 'Show Session Timer',
			'common.customize_card_blur_path' => 'Desfocar diretório do projeto',
			'common.customize_card_show_path' => 'Diretório do projeto',
			'common.customize_card_show_tags' => 'Tags',
			'common.customize_card_show_last_opened' => 'Última abertura',
			'common.customize_card_show_play' => 'Jogar',
			'common.customize_card_show_console' => 'Abrir com console',
			'common.project_card_remove_library' => 'Remover da biblioteca',
			'common.project_card_delete_files' => 'Excluir arquivos',
			'common.manage_tags' => 'Gerenciar tags',
			'common.tag_input_placeholder' => 'Nome da nova tag…',
			'common.tag_already_exists' => 'Já existe uma tag com este nome.',
			'common.tag_rename_hint' => 'Clique para renomear',
			'common.tag_rename_aria' => 'Renomear tag',
			'common.show_more_tags' => 'Mostrar mais tags',
			'common.show_fewer_tags' => 'Mostrar menos tags',
			'common.clear_tag_filter' => 'Limpar filtro de tag',
			'common.saving_tags' => 'Salvando tags…',
			'common.tag_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} tag', many: '${count} tag(s)', other: '${count} tags', ), 
			'common.no_tags' => 'Ainda não há tags',
			'common.bug_report_describe_label' => 'O que aconteceu?',
			'common.bug_report_describe_placeholder' => 'O que você estava fazendo quando o bug apareceu? Adicione os passos para reproduzir e o que você esperava que acontecesse em comparação com o que realmente aconteceu.',
			'common.bug_report_diagnostics_label' => 'Informações de diagnóstico',
			'common.bug_report_diagnostics_hint' => 'Coletadas automaticamente · incluídas no relatório',
			'common.bug_report_copied' => 'Copiado!',
			'common.bug_report_copy_log' => 'Copiar relatório',
			'common.bug_report_download_log' => 'Baixar relatório',
			'common.bug_report_open_github' => 'Criar issue no GitHub',
			'common.check_updates_title_modal' => 'Verificar atualizações',
			'common.check_updates_version_available' => 'Versão {{version}} disponível',
			'common.check_updates_ask_download' => 'Deseja baixar e instalar agora?',
			'common.check_updates_release_notes' => 'Notas da versão',
			'common.check_updates_failed' => 'Falha ao verificar atualizações',
			'common.check_updates_rate_limited' => 'Limite de requisições do GitHub atingido',
			'common.check_updates_token_rejected' => 'Token do GitHub rejeitado',
			'common.check_updates_rate_limited_hint' => 'O GitHub permite apenas 60 requisições anônimas por hora, compartilhadas com todos na sua rede. Adicionar um token de acesso pessoal nas Configurações aumenta esse limite para 5.000 por hora e ele também é usado para buscar versões do Godot.',
			'common.check_updates_rate_limited_token_hint' => 'Seu token salvo do GitHub foi rejeitado. Ele pode ter expirado ou sido revogado. Teste-o nas Configurações e substitua-o, se necessário.',
			'common.check_updates_add_token' => 'Adicionar token do GitHub',
			'common.check_updates_open_token_settings' => 'Abrir configurações do token',
			'common.check_updates_preview_badge' => 'Prévia',
			'common.check_updates_portable_title' => 'Atualização manual necessária',
			'common.check_updates_portable_desc' => 'Instalações portáteis não podem ser atualizadas automaticamente. Baixe a versão mais recente no GitHub e substitua os arquivos existentes.',
			'common.check_updates_download_from_github' => 'Baixar do GitHub',
			'common.preview_state_checking' => 'Verificando',
			'common.preview_state_available' => 'Disponível',
			'common.preview_state_downloading' => 'Baixando',
			'common.preview_state_done' => 'Concluído',
			'common.preview_state_uptodate' => 'Atualizado',
			'common.preview_state_error' => 'Erro',
			'common.preview_state_portable' => 'Portátil',
			'common.preview_update_modal' => 'Prévia da janela de atualização',
			'common.clone_repo_title' => 'Clonar repositório',
			'common.clone_repo_url_label' => 'URL do repositório',
			'common.clone_repo_url_placeholder' => 'https://github.com/user/my-game.git',
			'common.clone_repo_error_url' => 'Digite a URL de um repositório.',
			'common.clone_repo_error_location' => 'Escolha onde clonar o repositório.',
			'common.clone_repo_open_after' => 'Abrir logo após importar',
			'common.clone_repo_browse_repos' => 'Explorar seus repositórios',
			'common.clone_repo_url_manual' => 'Colar URL manualmente',
			'common.clone_repo_search_repos' => 'Pesquisar seus repositórios...',
			'common.clone_repo_no_repos_found' => 'Nenhum repositório corresponde à sua pesquisa.',
			'common.clone_repo_loading_repos' => 'Carregando repositórios...',
			'common.clone_repo_load_error' => 'Falha ao carregar os repositórios.',
			'common.clone_repo_select' => 'Selecionar',
			'common.clone_repo_no_account' => 'Nenhuma conta do GitHub ou GitLab conectada. Use uma URL para clonar.',
			'common.clone_repo_repos_loaded' => 'repositórios carregados',
			'common.load_more' => 'Carregar mais',
			'common.git_uncommitted' => 'não commitadas',
			'common.git_clean' => 'Sem alterações',
			'common.task_tray_title' => 'Tarefas',
			'common.task_tray_empty' => 'Nenhuma tarefa ativa',
			'common.task_tray_active_count' => '{{active}} ativas, {{recent}} recentes',
			'common.task_tray_only_recent' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} tarefa recente', many: '${count} tarefa recente', other: '${count} tarefas recentes', ), 
			'common.task_tray_aria' => 'Bandeja do sistema',
			'common.task_tray_auto_dismiss' => 'Concluídas são dispensadas automaticamente',
			'common.task_tray_dismiss' => 'Dispensar {{count}}',
			'common.task_error_status' => 'Erro',
			'common.command_palette_title' => 'Menu de comandos',
			'common.command_palette_placeholder' => 'Pesquisar comandos, projetos, versões da Godot e configurações…',
			'common.command_palette_no_results' => 'Nenhum resultado corresponde',
			'common.command_palette_navigate' => 'Navegar',
			'common.command_palette_escape' => 'Esc',
			'common.setting_token_placeholder' => 'ghp_xxxxxxxxxxxxxxxxxxxx',
			'common.setting_project_scan_dirs' => 'Pastas de busca de projetos',
			'common.setting_version_scan_dirs' => 'Pastas de busca de versões',
			'common.setting_default_project_location' => 'Configuração do local padrão dos projetos',
			'common.setting_download_dir' => 'Configuração do local de download das versões',
			'common.setting_scan_depth' => 'Profundidade da busca',
			'common.setting_icon_scan_depth' => 'Profundidade da busca de ícones do projeto',
			'common.setting_download_concurrency' => 'Downloads simultâneos',
			'common.setting_close_on_project_open' => 'Fechar ao abrir projeto',
			'common.setting_minimize_to_tray' => 'Minimizar para a bandeja do sistema',
			'common.setting_reopen_after_godot_closes' => 'Reabrir após fechar o Godot',
			'common.setting_auto_scan_on_startup' => 'Busca automática ao iniciar',
			'common.setting_workspaces_enabled' => 'Usar espaços de trabalho',
			'common.setting_directory_naming_convention' => 'Convenção de nomes de pastas',
			'common.setting_git_init_new_projects' => 'Inicializar Git em novos projetos',
			'common.setting_tooltip_delay' => 'Atraso das dicas',
			'common.setting_command_palette_keybind' => 'Atalho do menu de comandos',
			'common.setting_tray_recent_projects_count' => 'Projetos recentes na bandeja',
			'common.setting_last_opened_time_format' => 'Formato de hora',
			'common.setting_last_opened_date_format' => 'Formato de data',
			'common.setting_theme_mode' => 'Modo do tema',
			'common.setting_accent_color' => 'Cor de destaque',
			_ => null,
		} ?? switch (path) {
			'common.setting_background_color' => 'Cor de fundo',
			'common.setting_corner_radius' => 'Arredondamento dos cantos',
			'common.setting_ui_density' => 'Densidade da interface',
			'common.setting_font_scale' => 'Tamanho do texto',
			'common.setting_animation_intensity' => 'Intensidade das animações',
			'common.setting_view_entrance' => 'Animação de entrada da visualização',
			'common.setting_custom_css' => 'CSS personalizado',
			'common.setting_project_icon_opacity' => 'Opacidade do ícone do projeto',
			'common.setting_show_scrollbars' => 'Mostrar barra de rolagem',
			'common.setting_setup_wizard' => 'Assistente de configuração',
			'common.setting_reset_settings' => 'Redefinir configurações',
			'common.setting_delete_app_data' => 'Excluir dados do aplicativo',
			'common.setting_check_updates' => 'Verificar atualizações',
			'common.setting_show_support_button' => 'Mostrar botão de apoio',
			'common.setting_show_star_button' => 'Mostrar botão de estrela',
			'common.setting_discord_rpc_enabled' => 'Discord Rich Presence',
			'common.setting_discord_app_id' => 'ID do aplicativo do Discord',
			'common.setting_discord_rpc_show_projects' => 'Mostrar nomes de projetos no Discord',
			'common.setting_discord_rpc_excluded_projects' => 'Projetos excluídos do Discord',
			'common.setting_discord_rpc_project_presences' => 'Presença personalizada do Discord',
			'common.active_workspace' => '{{name}} (ativo)',
			'common.current_workspace' => 'Espaço de trabalho atual',
			'common.switch_workspace' => 'Mudar espaço de trabalho',
			'common.opened_recently' => 'Aberto {{label}}',
			'common.recent_section' => 'Recentes',
			'common.installed_versions_section' => 'Versões instaladas',
			'common.settings_label' => 'Configurações → {{tab}}',
			'common.remove_category_aria' => 'Remover {{name}}',
			'common.git_remove_remote' => 'Remover remoto',
			'common.git_commit_placeholder' => 'Mensagem do commit…',
			'common.restart_required_title' => 'Reinicialização necessária',
			'common.restart_required_desc' => 'Esta alteração exige que o GodotHub seja reiniciado para ter efeito completo. A configuração foi salva e será aplicada quando você abrir o aplicativo novamente.',
			'common.found_dismissed_title' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Projeto removido anteriormente encontrado', many: '${count} previously removed projects found', other: '${count} projetos removidos anteriormente encontrados', ), 
			'common.found_dismissed_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'O scanner encontrou 1 projeto que você havia removido da biblioteca. Deseja adicioná-lo novamente?', many: 'Scanner found ${count} projects that you previously removed from the library. Would you like to re-add them?', other: 'O scanner encontrou ${count} projetos que você havia removido da biblioteca. Deseja adicioná-los novamente?', ), 
			'common.readd_all' => 'Readicionar todos',
			'common.skip_all' => 'Ignorar todos',
			'common.project_already_open_title' => 'Projeto já aberto',
			'common.project_already_open_desc' => '{{name}} já está em execução. Abri-lo novamente inicia uma segunda instância do editor. Abrir mesmo assim?',
			'common.project_open_anyway' => 'Abrir mesmo assim',
			'common.git_sidebar' => 'Barra lateral do Git',
			'common.asset_duplicate_title' => 'Template já instalado',
			'common.asset_duplicate_desc' => '"{{name}}" já está nos seus templates. Deseja instalar uma cópia mesmo assim?',
			'common.empty_category' => 'Categoria vazia',
			'common.release_to_drop' => 'Solte para mover',
			'common.preview_release_notes' => '## Novidades da v1.0.0 - Atualização de prévia\\n\\n## Novidades\\n\\n- Reformulação da janela Verificar atualizações com notas da versão estruturadas\\n- Adicionados anúncios para leitores de tela e uma seção de Acessibilidade nas configurações\\n\\n## Correções\\n\\n- Corrigida uma falha ao trocar de espaço de trabalho com projetos fixados\\n- Corrigidas verificações de atualização que falhavam silenciosamente ao atingir o limite de requisições da API do GitHub\\n\\n## Melhorias\\n\\n- Inicialização mais rápida em todas as plataformas\\n- Reformulação das janelas de espaço de trabalho com seletores de estilo compactos\\n\\n## Problemas conhecidos\\n\\n- Linux: o AppImage pode não funcionar em algumas distribuições; use o pacote .rpm ou .deb\\n- Windows: a barra de tarefas pode exibir brevemente um ícone duplicado até que o aplicativo seja reiniciado',
			'common.preview_error' => 'Erro de prévia: o limite de requisições da API do GitHub foi atingido (HTTP 403). Adicione um token nas Configurações para continuar verificando.',
			'common.bug_report_system' => 'Sistema',
			'common.bug_report_version' => 'Versão',
			'common.bug_report_date' => 'Data',
			'common.bug_report_os' => 'Sistema operacional',
			'common.bug_report_platform' => 'Plataforma',
			'common.bug_report_language' => 'Idioma',
			'common.bug_report_cpu_cores' => 'Núcleos da CPU',
			'common.bug_report_ram' => 'RAM',
			'common.bug_report_screen' => 'Tela',
			'common.bug_report_gpu' => 'GPU',
			'common.bug_report_user_agent' => 'Agente do usuário',
			'common.bug_report_recent_errors' => 'Erros recentes',
			'common.bug_report_none_captured' => 'nenhum capturado',
			'common.bug_report_description' => 'Descrição',
			'common.bug_report_no_description' => 'Nenhuma descrição fornecida',
			'common.unknown' => 'desconhecido',
			'common.gpu_webgl_unavailable' => 'WebGL indisponível',
			'common.gpu_info_unavailable' => 'Informações da GPU indisponíveis',
			'common.update_available' => 'Atualização disponível',
			'common.dismiss' => 'Dispensar',
			'common.system_language' => 'Idioma do sistema',
			'common.category_empty_hint' => 'Crie uma acima para organizar seus projetos',
			'common.contributor_pr_merged' => 'Mesclado',
			'common.contributor_pr_open' => 'Aberto',
			'common.contributor_pr_closed' => 'Fechado',
			'common.contributor_pr_loading' => 'Carregando PRs...',
			'common.contributor_pr_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} pull request', many: '${count} pull requests', other: '${count} pull requests', ), 
			'common.contributor_pr_load_failed' => 'Não foi possível carregar os pull requests.',
			'common.contributor_pr_network_hint' => 'Verifique sua conexão com a internet.',
			'common.contributor_pr_empty' => 'Nenhum pull request encontrado.',
			'common.theme_presets_section' => 'Theme presets',
			'common.all_categories' => 'Todas as categorias',
			'common.clear_category_filter' => 'Clear category filter',
			'common.filter_by_category' => 'Filter by category',
			'common.theme_dark' => 'Escuro',
			'common.theme_light' => 'Claro',
			'common.bulk_tags' => 'Tags',
			'common.bulk_tags_title' => 'Edit tags',
			'common.add_tag' => 'Adicionar tag',
			'common.remove_tag' => 'Remover tag',
			'common.no_common_tags' => 'No tags on the selected projects yet.',
			'common.tags_added_to_selection' => 'Added tag to {{count}} projects.',
			'common.tags_removed_from_selection' => 'Removed tag from {{count}} projects.',
			'common.removed_from_library' => 'Removed {{count}} project(s) from library.',
			'common.undo' => 'Undo',
			'common.duplicate_project_title' => 'Duplicate project',
			'common.copy_suffix' => 'copy',
			'common.duplicate' => 'Duplicate',
			'common.destination_folder' => 'Pasta de destino',
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
			'common.project_doctor.summary_errors' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} issue needs attention', many: '${count} issues need attention', other: '${count} issues need attention', ), 
			'common.project_doctor.summary_warnings' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} warning to review', many: '${count} warnings to review', other: '${count} warnings to review', ), 
			'common.project_doctor.summary_ready' => 'No blocking issues found',
			'common.project_doctor.summary_counts' => '{{passed}} checks passed · {{findings}} findings',
			'common.project_doctor.passed_checks' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} passed check', many: '${count} passed checks', other: '${count} passed checks', ), 
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
			'common.cleanup_confirm_btn' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Remove ${count} item', many: 'Remove ${count} items', other: 'Remove ${count} items', ), 
			'common.cleanup_done' => 'Freed {{size}}',
			'common.cleanup_failed' => 'Couldn\'t remove {{label}}: {{error}}',
			'common.cleanup_versions_desc' => 'Full size on disk of every installed Godot version.',
			'common.cleanup_templates_title' => 'Project templates',
			'common.cleanup_export_templates_title' => 'Export templates',
			'common.cleanup_used_by_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} template', many: '${count} templates', other: '${count} templates', ), 
			'common.cleanup_current_badge' => 'Current',
			'common.cleanup_alias_badge' => 'Alias',
			'common.cleanup_unused_badge' => 'Unused',
			'common.cleanup_mise_badge' => 'Managed by mise',
			'common.cleanup_external_badge' => 'External',
			'common.cleanup_orphan_badge' => 'Orphaned',
			'common.cleanup_empty' => 'Nothing here yet.',
			'common.new_badge' => 'New',
			'common.reset' => 'Redefinir',
			'common.git_disconnect' => 'Desconectar',
			'common.git_sign_in_github' => 'Entrar com o GitHub',
			'common.git_connected_as' => 'Conectado como @{{username}}',
			'common.optional' => '(opcional)',
			'common.language_label' => 'Idioma',
			'common.n_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} projeto', many: '${count} projects', other: '${count} projetos', ), 
			'common.vault_item_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Item', many: 'Items', other: 'Items', ), 
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
			'common.vault_conflict_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} file already exists in the project. Overwrite it?', many: '${count} files already exist in the project. Overwrite them?', other: '${count} files already exist in the project. Overwrite them?', ), 
			'common.vault_conflict_summary_desc' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} file already exists across the selected projects. Overwrite it?', many: '${count} files already exist across the selected projects. Overwrite them?', other: '${count} files already exist across the selected projects. Overwrite them?', ), 
			'common.vault_added_toast' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Added ${count} file', many: 'Added ${count} files', other: 'Added ${count} files', ), 
			'common.vault_added_to_projects_toast' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Added to ${count} project', many: 'Added to ${count} projects', other: 'Added to ${count} projects', ), 
			'common.vault_item_empty' => 'This item has no files.',
			'common.kNew' => 'Novo',
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
			'common.project_addons.count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} addon installed', many: '${count} addons installed', other: '${count} addons installed', ), 
			'common.project_addons.empty' => 'This project has no addons folder. Install addons from the Asset Store or copy them into res://addons.',
			'common.project_addons.check_updates' => 'Check for updates',
			'common.project_addons.checking' => 'Checking…',
			'common.project_addons.updates_available' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} update available', many: '${count} updates available', other: '${count} updates available', ), 
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
			'dashboard.greeting_morning' => 'Bom dia',
			'dashboard.greeting_afternoon' => 'Boa tarde',
			'dashboard.greeting_evening' => 'Boa noite',
			'dashboard.greeting_night' => 'Boa noite',
			'dashboard.greeting_name' => '{{greeting}}, {{name}}',
			'dashboard.dashboard_rename_hint' => 'Definir um nome personalizado',
			'dashboard.dashboard_rename_aria' => 'Editar nome na saudação',
			'dashboard.dashboard_rename_save' => 'Salvar nome',
			'dashboard.dashboard_rename_reset' => 'Usar nome do sistema',
			'dashboard.dashboard_name_placeholder' => 'Seu nome',
			'dashboard.dashboard_clock_aria' => 'Hora atual',
			'dashboard.dashboard_new_project' => 'Novo projeto',
			'dashboard.dashboard_import_project' => 'Importar projeto',
			'dashboard.dashboard_scan_projects' => 'Procurar projetos',
			'dashboard.dashboard_stat_projects' => 'Projetos',
			'dashboard.dashboard_stat_templates' => 'Templates',
			'dashboard.dashboard_stat_engines' => 'Versões do Godot',
			'dashboard.dashboard_stat_total_time' => 'Tempo total',
			'dashboard.dashboard_stat_total_time_hint' => 'Tempo gasto em projetos',
			'dashboard.dashboard_recent' => 'Abertos recentemente',
			'dashboard.dashboard_recent_empty' => 'Nada foi aberto ainda. Abra um projeto para vê-lo aqui.',
			'dashboard.dashboard_pinned' => 'Fixados',
			'dashboard.dashboard_pinned_empty' => 'Nenhum projeto fixado ainda. Fixe um projeto para mantê-lo à mão.',
			'dashboard.dashboard_engines' => 'Versões do Godot instaladas',
			'dashboard.dashboard_engines_empty' => 'Nenhuma versão do Godot instalada ainda.',
			'dashboard.dashboard_running' => 'Em execução agora',
			'dashboard.dashboard_running_empty' => 'Nada está em execução no momento.',
			'dashboard.dashboard_opened_at' => 'Aberto às {{time}}',
			'dashboard.dashboard_daily' => 'Atividade diária',
			'dashboard.dashboard_daily_empty' => 'Ainda não há atividade diária.',
			'dashboard.dashboard_weekly' => 'Atividade semanal',
			'dashboard.dashboard_weekly_empty' => 'Ainda não há atividade semanal.',
			'dashboard.dashboard_monthly' => 'Atividade mensal',
			'dashboard.dashboard_monthly_empty' => 'Ainda não há atividade mensal.',
			'dashboard.dashboard_yearly' => 'Atividade anual',
			'dashboard.dashboard_yearly_empty' => 'Ainda não há atividade anual.',
			'dashboard.dashboard_activity_cycle' => 'Mudar para {{next}}',
			'dashboard.dashboard_weekly_aria' => 'Tempo registrado: {{label}}',
			'dashboard.dashboard_top_time' => 'Projetos com mais tempo registrado',
			'dashboard.dashboard_top_time_empty' => 'Ainda não há tempo registrado. Abra um projeto para começar a registrar.',
			'dashboard.dashboard_insights' => 'Insights',
			'dashboard.dashboard_insights_empty' => 'Ainda não há tempo registrado. Abra um projeto para começar uma sequência de dias.',
			'dashboard.dashboard_insights_longest_streak' => 'Maior sequência de dias',
			'dashboard.dashboard_insights_current_streak' => 'Sequência atual de dias',
			'dashboard.dashboard_insights_days' => '{{count}} dias',
			'dashboard.dashboard_insights_productive_day' => 'Dia mais produtivo',
			'dashboard.dashboard_insights_this_month' => 'Este mês',
			'dashboard.dashboard_insights_delta_up' => '{{pct}}% a mais que no mês passado',
			'dashboard.dashboard_insights_delta_down' => '{{pct}}% a menos que no mês passado',
			_ => null,
		} ?? switch (path) {
			'dashboard.dashboard_git' => 'Visão geral do Git',
			'dashboard.dashboard_git_empty' => 'Nenhum repositório Git detectado.',
			'dashboard.dashboard_git_clean' => 'Sem alterações',
			'dashboard.dashboard_git_dirty' => '{{count}} projetos com alterações ainda sem commit',
			'dashboard.dashboard_git_dirty_plural' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '1 projeto com alterações ainda sem commit', many: '${count} projetos com alterações ainda sem commit', other: '${count} projetos com alterações ainda sem commit', ), 
			'dashboard.dashboard_git_branch' => 'Em {{branch}}',
			'dashboard.dashboard_storage' => 'Uso do armazenamento',
			'dashboard.dashboard_storage_empty' => 'Nenhum projeto para analisar.',
			'dashboard.dashboard_storage_loading' => 'Medindo…',
			'dashboard.dashboard_storage_total' => '{{size}} no total',
			'dashboard.dashboard_customize' => 'Personalizar',
			'dashboard.dashboard_done_customizing' => 'Concluir',
			'dashboard.dashboard_customize_hint' => 'Use as setas para reorganizar os blocos ou oculte os que você não precisa.',
			'dashboard.dashboard_tile_move_up' => 'Mover para cima',
			'dashboard.dashboard_tile_move_down' => 'Mover para baixo',
			'dashboard.dashboard_tile_remove' => 'Remover',
			'dashboard.dashboard_tile_span' => 'Largura total',
			'dashboard.dashboard_tile_span_off' => 'Meia largura',
			'dashboard.dashboard_tile_tall' => 'Mais alto',
			'dashboard.dashboard_tile_tall_off' => 'Altura normal',
			'dashboard.dashboard_presets' => 'Predefinições de layout',
			'dashboard.dashboard_preset_default' => 'Padrão',
			'dashboard.dashboard_preset_default_desc' => 'Tudo ativado, na ordem padrão e com tamanho padrão.',
			'dashboard.dashboard_preset_overview' => 'Visão geral',
			'dashboard.dashboard_preset_overview_desc' => 'Projetos abertos recentemente, fixados, versões do Godot e projetos em execução.',
			'dashboard.dashboard_preset_analytics' => 'Análises',
			'dashboard.dashboard_preset_analytics_desc' => 'Atividade semanal, principais projetos, armazenamento e categorias, com gráficos mais altos.',
			'dashboard.dashboard_preset_development' => 'Desenvolvimento',
			'dashboard.dashboard_preset_development_desc' => 'Status do Git em destaque, com projetos em execução e versões do Godot.',
			'dashboard.dashboard_preset_save' => 'Salvar layout atual como predefinição',
			'dashboard.dashboard_preset_save_hint' => 'Dê um nome a este layout para poder voltar a ele quando quiser.',
			'dashboard.dashboard_preset_name_placeholder' => 'Nome da predefinição',
			'dashboard.dashboard_preset_delete' => 'Excluir predefinição',
			'dashboard.dashboard_custom_presets' => 'Suas predefinições',
			'dashboard.dashboard_hidden_tiles' => 'Blocos ocultos',
			'dashboard.dashboard_todos' => 'Due to-dos',
			'dashboard.dashboard_range_daily' => 'Dia',
			'dashboard.dashboard_range_weekly' => 'Semana',
			'dashboard.dashboard_range_monthly' => 'Mês',
			'dashboard.dashboard_range_yearly' => 'Ano',
			'dashboard.dashboard_activity_tracked' => 'Registrado',
			'dashboard.dashboard_activity_peak' => 'Pico',
			'git.remove' => 'Remover',
			'git.changes_title' => 'Alterações',
			'git.pull' => 'Pull',
			'git.push' => 'Push',
			'git.force_push' => 'Forçar push',
			'git.fetch' => 'Fetch',
			'git.change' => 'Alteração',
			'git.commit' => 'Commit',
			'git.committing' => 'Fazendo commit…',
			'git.no_remotes' => 'Nenhum repositório remoto configurado',
			'git.switching' => 'Trocando de branch…',
			'git.no_branches' => 'Nenhuma branch encontrada',
			'git.new_branch_placeholder' => 'Nome da branch',
			'git.delete_branch' => 'Excluir branch',
			'git.publish_branch' => 'Publicar branch',
			'git.publish_branch_to' => 'Publish branch to {{remote}}',
			'git.branch_published' => 'Branch publicada.',
			'git.use_ours' => 'Manter versão atual',
			'git.use_theirs' => 'Aceitar versão recebida',
			'git.i_resolved' => 'Marcar como resolvido',
			'git.undo_last_commit' => 'Desfazer último commit',
			'git.undo_pull' => 'Desfazer pull',
			'git.force_push_confirm_title' => 'Forçar push?',
			'git.force_push_confirm_desc' => 'Isso pode sobrescrever commits de outras pessoas no repositório remoto. Deseja continuar?',
			'git.undo_commit_done' => 'Último commit desfeito.',
			'git.undo_pull_done' => 'Pull desfeito.',
			'git.force_pushed' => 'Push forçado concluído.',
			'git.synced_ok' => 'Sincronizado.',
			'git.fetched_ok' => 'Fetch concluído.',
			'git.pulled_ok' => 'Pull concluído.',
			'git.pushed_ok' => 'Push concluído.',
			'git.branch_created' => 'Branch criada.',
			'git.branch_deleted' => 'Branch excluída.',
			'git.changes_stashed_ok' => 'Alterações salvas no stash.',
			'git.stash_applied_ok' => 'Stash aplicado.',
			'git.stash_popped_ok' => 'Stash aplicado e removido.',
			'git.stash_dropped_ok' => 'Stash descartado.',
			'git.staged_ok' => 'Adicionado ao stage.',
			'git.unstaged_ok' => 'Removido do stage.',
			'git.discarded_ok' => 'Descartado.',
			'git.stage_all_ok' => 'Todas as alterações foram adicionadas ao stage.',
			'git.unstage_all_ok' => 'Todas as alterações foram removidas do stage.',
			'git.discard_all_ok' => 'Todas as alterações foram descartadas.',
			'git.resolved_ours' => 'Resolvido mantendo a versão atual.',
			'git.resolved_theirs' => 'Resolvido aceitando a versão recebida.',
			'git.resolved_manual' => 'Conflito marcado como resolvido.',
			'git.committed_ok' => 'Commit realizado.',
			'git.switched_ok' => 'Agora em {{branch}}.',
			'git.sync' => 'Sincronizar',
			'git.diff_no_diff' => 'Nenhum diff disponível para este arquivo.',
			'git.fetching' => 'Buscando…',
			'git.stashes_title' => 'Stashes',
			'git.stash' => 'Stash',
			'git.stashing' => 'Criando stash…',
			'git.apply_stash' => 'Aplicar stash',
			'git.pop_stash' => 'Aplicar e remover stash',
			'git.drop_stash' => 'Descartar stash',
			'git.merge_aborted' => 'Merge cancelado. As alterações do merge foram desfeitas.',
			'git.new_branch_btn' => '+ Nova',
			'git.abort_merge' => 'Cancelar merge',
			'git.merge_in_progress' => 'Merge em andamento',
			'git.working_tree_clean' => 'Sem alterações locais.',
			'git.staged_changes' => 'Alterações no stage',
			'git.unstage_all_changes' => 'Remover tudo do stage',
			'git.commits_title' => 'Commits',
			'git.stage_file' => 'Adicionar arquivo ao stage',
			'git.discard_file' => 'Descartar arquivo',
			'git.unstage_file' => 'Remover arquivo do stage',
			'git.no_commits_found' => 'Nenhum commit encontrado.',
			'git.stage_all' => 'Adicionar tudo ao stage',
			'git.discard_all' => 'Descartar tudo',
			'git.auth_connected_accounts' => 'Contas conectadas',
			'git.auth_connect_hint' => 'Conecte uma conta do serviço Git desejado para começar. Repositórios configurados com SSH podem ser usados sem uma conta conectada.',
			'git.worktrees_title' => 'Worktrees',
			'git.worktree_current' => 'Atual',
			'git.no_worktrees' => 'Nenhuma worktree adicional',
			'git.switch_worktree' => 'Alternar para esta worktree',
			'git.switched_worktree_ok' => 'Worktree alterada.',
			'git.add_worktree' => 'Nova worktree',
			'git.add_worktree_btn' => 'Adicionar worktree',
			'git.worktree_path_placeholder' => 'Caminho (ex.: ../minha-feature)',
			'git.worktree_branch_placeholder' => 'Nome da branch (opcional)',
			'git.worktree_created_ok' => 'Worktree criada.',
			'git.worktree_dirty' => 'Alterações sem commit',
			'git.remove_worktree' => 'Remover worktree',
			'git.remove_worktree_confirm_desc' => 'Remover a worktree em {{path}}? O diretório será excluído. A branch e os commits serão mantidos.',
			'git.worktree_removed_ok' => 'Worktree removida.',
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
			'nav.dashboard' => 'Painel',
			'nav.projects' => 'Projetos',
			'nav.projects_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Projeto', many: 'Projetos', other: 'Projetos', ), 
			'nav.versions' => 'Versões',
			'nav.templates' => 'Templates',
			'nav.vault' => 'Vault',
			'nav.asset_store' => 'Loja de assets',
			'nav.news' => 'Notícias do Godot',
			'nav.storage_view' => 'Storage',
			'nav.settings' => 'Configurações',
			'nav.changelog' => 'Histórico de alterações',
			'nav.group_workspace' => 'Espaço de trabalho',
			'nav.group_resources' => 'Recursos',
			'nav.group_explore' => 'Explorar',
			'nav.you' => 'You',
			'nav.account_manage' => 'Manage accounts',
			'nav.workspace_tip_title' => 'O seletor de espaços foi movido',
			'nav.workspace_tip_body' => 'Troque e gerencie espaços de trabalho pelo menu da conta abaixo.',
			'nav.workspace_tip_dismiss' => 'Entendi',
			'onboarding.welcome' => 'Boas-vindas',
			'onboarding.finish' => 'Concluir',
			'onboarding.in_progress' => 'Em andamento',
			'onboarding.prototypes' => 'Protótipos',
			'onboarding.finished' => 'Concluídos',
			'onboarding.game_jams' => 'Game Jams',
			'onboarding.project_folders' => 'Pastas de projetos',
			'onboarding.version_folders' => 'Pastas de versões',
			'onboarding.welcome_title' => 'Boas-vindas ao GodotHub',
			'onboarding.welcome_desc' => 'Um só lugar para organizar todos os seus projetos e versões do Godot nesta máquina. Vamos ajustar algumas coisas para deixar tudo do seu jeito. Leva só um minuto. Depois, você também pode ajustar tudo nas Configurações.',
			'onboarding.onboard_empty_projects' => 'Nenhuma pasta adicionada ainda. O GodotHub não encontrará projetos existentes até você adicionar uma. Você também pode adicionar projetos manualmente depois.',
			'onboarding.onboard_empty_versions' => 'Nenhuma pasta adicionada ainda. Novos downloads do Godot serão salvos na pasta de dados do aplicativo até você definir uma pasta abaixo.',
			'onboarding.onboard_no_template_folder' => 'Nenhuma pasta definida. Você também pode configurar isso depois nas Configurações ou salvar templates manualmente.',
			'onboarding.onboard_cloud_heading' => 'Backup na nuvem',
			'onboarding.onboard_cloud_desc' => 'Já tem um backup? Entre com o GitHub e restaure seus espaços de trabalho, projetos e configurações a partir de um gist.',
			'onboarding.discovery_recent_heading' => 'Recent projects from Godot',
			'onboarding.discovery_installs_heading' => 'Godot found on this computer',
			'onboarding.discovery_scanning_projects' => 'Reading Godot\'s project manager list…',
			'onboarding.discovery_scanning_installs' => 'Looking for Godot on your PATH and in Steam…',
			'onboarding.discovery_engine' => 'Godot {{version}}',
			'onboarding.discovery_favorite' => 'Favorite',
			'onboarding.discovery_add_selected' => 'Add selected',
			'onboarding.discovery_add_selected_count' => 'Add selected ({{count}})',
			'onboarding.discovery_added_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Added ${count} project.', many: 'Added ${count} projects.', other: 'Added ${count} projects.', ), 
			'onboarding.discovery_added_versions' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Added ${count} version.', many: 'Added ${count} versions.', other: 'Added ${count} versions.', ), 
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
			'settings.storage' => 'Armazenamento',
			'settings.behavior' => 'Comportamento',
			'settings.display' => 'Exibição',
			'settings.appearance' => 'Aparência',
			'settings.accessibility' => 'Acessibilidade',
			'settings.accessibility_desc' => 'Avisos do leitor de tela e opções de tecnologias assistivas.',
			'settings.app_version_label' => 'GodotHub v{{version}}',
			'settings.landing_dashboard' => 'Painel',
			'settings.landing_projects' => 'Projetos',
			'settings.landing_versions' => 'Versões',
			'settings.landing_news' => 'Notícias do Godot',
			'settings.screen_reader_label' => 'Avisos do leitor de tela',
			'settings.advanced' => 'Avançado',
			'settings.integrations' => 'Integrações',
			'settings.motion' => 'Motion',
			'settings.data' => 'Data & Backup',
			'settings.git_auth_title' => 'Entrar com {{provider}}',
			'settings.git_auth_copy_code' => 'Copiar código',
			'settings.git_auth_copy_link' => 'Copy link',
			'settings.git_auth_waiting' => 'Aguardando sua autorização…',
			'settings.git_sign_in_gitlab' => 'Entrar com o GitLab',
			'settings.git_connected_to' => 'Conectado a {{host}} como @{{username}}',
			'settings.git_self_hosted_title' => 'GitLab em servidor próprio',
			'settings.git_self_hosted_desc' => 'Conecte-se à sua própria instância do GitLab. Crie um aplicativo OAuth na sua instância (escopos: read_repository, write_repository, read_user) e cole a URL base e o ID do aplicativo.',
			'settings.git_self_hosted_url_placeholder' => 'https://gitlab.example.com',
			'settings.git_self_hosted_client_id' => 'ID do aplicativo',
			'settings.git_sign_in_self_hosted' => 'Entrar com esta instância',
			'settings.git_pat_title' => 'Outros hosts (tokens de acesso pessoal)',
			'settings.git_pat_add' => 'Adicionar token',
			'settings.git_pat_host_placeholder' => 'ex.: codeberg.org',
			'settings.git_pat_username' => 'Nome de usuário',
			'settings.git_pat_token' => 'Token',
			'settings.git_pat_save' => 'Salvar token',
			'settings.git_pat_empty' => 'Nenhum token adicionado ainda.',
			'settings.git_pat_remove' => 'Remover token',
			'settings.storage_title' => 'Armazenamento e busca automática',
			'settings.behavior_projects_title' => 'Projetos',
			'settings.file_watchers_title' => 'Monitores de arquivos',
			'settings.last_opened_title' => 'Última abertura',
			'settings.github_token_title' => 'Token da API do GitHub',
			'settings.titlebar_buttons' => 'Botões da barra de título',
			'settings.setup_wizard' => 'Assistente de configuração',
			'settings.setup_wizard_again' => 'Executar assistente de configuração novamente',
			'settings.restart_app' => 'Reiniciar aplicativo',
			'settings.restart_app_confirm_title' => 'Reiniciar o GodotHub?',
			'settings.restart_app_confirm_desc' => 'O aplicativo será fechado e reaberto automaticamente. Operações em andamento e não salvas podem ser interrompidas.',
			'settings.reset_settings' => 'Redefinir configurações',
			'settings.delete_app_data' => 'Excluir dados do aplicativo',
			'settings.new_project_default' => 'padrão',
			'settings.download_folder' => 'padrão',
			'settings.system' => 'Sistema',
			'settings.k12h' => '12 horas (2:30 PM)',
			'settings.k24h' => '24 horas (14:30)',
			'settings.dd_mm_yyyy' => 'DD-MM-AAAA',
			'settings.mm_dd_yyyy' => 'MM-DD-AAAA',
			'settings.yyyy_mm_dd' => 'AAAA-MM-DD',
			'settings.reset_all_title' => 'Redefinir todas as configurações?',
			'settings.reset_all_desc' => 'Isso restaura todas as configurações desta página, pasta de download, pastas configuradas, aparência e comportamento, aos padrões. Esta ação não pode ser desfeita.',
			'settings.delete_all_title' => 'Excluir todos os dados do aplicativo?',
			'settings.delete_all_desc' => 'Isso exclui permanentemente todos os espaços de trabalho, projetos, categorias, registros de versões instaladas e configurações armazenados pelo GodotHub e reinicia o aplicativo na configuração inicial. As pastas dos projetos e instalações do Godot no disco não serão alteradas, a menos que estejam na pasta de download padrão; nesse caso, também serão excluídas. Esta ação não pode ser desfeita.',
			'settings.empty_hint_projects' => 'Nenhuma pasta adicionada. O GodotHub não procurará projetos automaticamente ao iniciar, e você precisará escolher onde salvar cada novo projeto.',
			'settings.empty_hint_versions' => 'Nenhuma pasta adicionada. O GodotHub não procurará versões automaticamente ao iniciar, e novos downloads usarão a pasta de dados do aplicativo.',
			'settings.naming_convention_label' => 'Convenção de nomes de pastas',
			'settings.naming_keep' => 'Manter como digitado (Meu Jogo)',
			'settings.naming_kebab' => 'kebab-case (meu-jogo)',
			'settings.naming_snake' => 'snake_case (meu_jogo)',
			'settings.naming_camel' => 'camelCase (meuJogo)',
			'settings.naming_pascal' => 'PascalCase (MeuJogo)',
			'settings.naming_title' => 'Title Case (Meu Jogo)',
			'settings.theme' => 'Tema',
			'settings.theme_preset_label' => 'Tema predefinido',
			'settings.theme_preset_custom' => 'Personalizado',
			'settings.preset_light_group' => 'Temas claros',
			'settings.preset_dark_group' => 'Temas escuros',
			'settings.test' => 'Testar',
			'settings.testing' => 'Testando…',
			'settings.token_valid' => 'Token válido! Limite de requisições: {{status}}',
			'settings.token_resets_in' => '(resets ~{{minutes}} min)',
			'settings.test_failed' => 'Falha no teste: {{error}}',
			'settings.key_space' => 'Espaço',
			'settings.no_settings_match' => 'Nenhuma configuração corresponde à busca',
			'settings.scan_result' => 'Resultado da busca, Projetos: {{projects}}; versões: {{versions}}.',
			'settings.palette_shortcut' => 'Atalho do menu de comandos',
			'settings.keybind_instruction' => 'Clique no botão abaixo e pressione qualquer tecla para alterar o atalho.',
			'settings.press' => 'Pressione',
			'settings.to_cancel' => 'para cancelar',
			'settings.press_key' => 'Pressione uma tecla…',
			'settings.click_to_rebind' => 'Clique para alterar',
			'settings.close_on_open_label' => 'Fechar aplicativo ao abrir projeto',
			'settings.launch_console_label' => 'Abrir Godot com o console',
			'settings.builtin_console_label' => 'Use the built-in console',
			'settings.minimize_tray_label' => 'Minimizar para a bandeja do sistema ao fechar a janela',
			'settings.reopen_label' => 'Reabrir após fechar o Godot',
			'settings.no_folder_set' => 'Nenhuma pasta definida. Você ainda pode importar manualmente ou usar “Salvar como template”.',
			'settings.ui_density_label' => 'Densidade da interface',
			'settings.text_size_label' => 'Tamanho do texto',
			'settings.section_godot_versions' => 'Versões do Godot',
			'settings.scan_depth_label' => 'Profundidade da busca',
			'settings.icon_scan_depth_label' => 'Profundidade da busca pelo ícone do projeto',
			'settings.download_concurrency_label' => 'Downloads simultâneos',
			'settings.tray_recent_label' => 'Projetos recentes na bandeja',
			'settings.tooltip_delay_label' => 'Tempo para exibir dicas',
			'settings.project_icon_opacity_label' => 'Opacidade do ícone do projeto',
			'settings.time_format_label' => 'Formato de hora (para projetos abertos hoje)',
			'settings.date_format_label' => 'Formato de data (para projetos abertos em outro dia)',
			'settings.auto_scan_label' => 'Busca automática ao iniciar',
			'settings.use_workspaces_label' => 'Usar espaços de trabalho',
			'settings.watch_projects_label' => 'Monitorar pastas de projetos',
			'settings.watch_versions_label' => 'Monitorar pastas de versões',
			'settings.watch_template_label' => 'Monitorar pasta de templates',
			'settings.show_scrollbar_label' => 'Mostrar barra de rolagem',
			'settings.animated_numbers_label' => 'Contadores animados',
			'settings.show_support_label' => 'Apoiar',
			'settings.show_star_label' => 'Estrela no Github',
			'settings.show_bug_label' => 'Reportar bug',
			'settings.show_tray_label' => 'Bandeja do sistema',
			'settings.show_language_label' => 'Idioma',
			'settings.clear' => 'Limpar',
			'settings.reset_to_default' => 'Redefinir para o padrão',
			'settings.reset_appearance' => 'Restaurar aparência padrão',
			'settings.delete_all' => 'Excluir tudo',
			'settings.open_setup' => 'Abrir configuração',
			'settings.reset_colors' => 'Redefinir cores para o padrão',
			'settings.folders_deep' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} nível', many: '${count} folders deep', other: '${count} níveis', ), 
			'settings.at_once' => '{{count}} ao mesmo tempo',
			'settings.animation_speed_label' => 'Animation speed',
			'settings.scroll_reveal_label' => 'Scroll reveal',
			'settings.card_tilt_label' => 'Card tilt on hover',
			'settings.click_ripple_label' => 'Click ripple',
			'settings.press_bounce_label' => 'Press bounce',
			'settings.animation_intensity_label' => 'Intensidade das animações',
			'settings.animation_full' => 'Completa',
			'settings.animation_subtle' => 'Sutil',
			'settings.animation_none' => 'Nenhuma',
			'settings.view_entrance_label' => 'Efeito de transição',
			'settings.entrance_fade' => 'Esmaecer',
			'settings.entrance_slide' => 'Deslizar',
			'settings.entrance_scale' => 'Escala',
			'settings.entrance_none' => 'Nenhuma',
			'settings.custom_css_label' => 'CSS personalizado',
			'settings.custom_css_placeholder' => '/* Seus estilos personalizados, por exemplo: */\n.card { border-radius: 4px !important; }',
			'settings.custom_css_apply' => 'Aplicar CSS',
			'settings.custom_css_applied' => 'CSS aplicado',
			'settings.animation_threshold_label' => 'Limite de animação das listas',
			'settings.time_tracking_title' => 'Backup do acompanhamento de tempo',
			'settings.export_stats_btn' => 'Exportar estatísticas…',
			'settings.import_stats_btn' => 'Importar estatísticas…',
			'settings.stats_exported' => 'Estatísticas de tempo exportadas.',
			'settings.clear_stats_confirm_title' => 'Limpar todos os dados de tempo?',
			'settings.clear_stats_confirm_desc' => 'Isso exclui permanentemente todo o histórico de acompanhamento de tempo, os registros de sessão e os totais por projeto. Esta ação não pode ser desfeita.',
			'settings.clear_stats_confirm_btn' => 'Limpar tudo',
			'settings.stats_cleared' => 'Dados de tempo apagados.',
			'settings.settings_backup_title' => 'Backup das configurações',
			'settings.export_settings_btn' => 'Exportar configurações',
			'settings.import_settings_btn' => 'Importar configurações',
			'settings.workspace_backup_title' => 'Backup do espaço de trabalho',
			'settings.workspace_backup_export_btn' => 'Exportar espaço de trabalho',
			'settings.workspace_backup_restore_btn' => 'Restaurar espaço de trabalho',
			'settings.workspace_backup_exported' => 'Backup do espaço de trabalho exportado.',
			'settings.workspace_backup_imported' => 'Espaço de trabalho restaurado.',
			'settings.app_backup_title' => 'Fazer backup de tudo (todos os espaços de trabalho)',
			'settings.app_backup_export_btn' => 'Exportar tudo',
			'settings.app_backup_restore_btn' => 'Restaurar tudo',
			'settings.app_backup_exported' => 'Backup completo do aplicativo exportado.',
			'settings.app_backup_imported' => 'Todos os espaços de trabalho restaurados.',
			'settings.sync_title' => 'Sincronização na nuvem (GitHub Gist)',
			'settings.sync_push_btn' => 'Enviar backup',
			'settings.sync_pull_btn' => 'Restaurar backup',
			'settings.sync_push_done' => 'Backup enviado para seu GitHub Gist.',
			'settings.sync_open_gist' => 'Abrir Gist',
			'settings.sync_last_pushed' => 'Último backup: {{time}}',
			'settings.sync_manual_hint' => 'Perdeu seus dados locais? Informe a URL ou o ID do Gist para restaurar a partir de qualquer máquina.',
			'settings.sync_manual_placeholder' => 'https://gist.github.com/... ou ID do Gist',
			'settings.sync_manual_pull_btn' => 'Restaurar',
			'settings.restore_modal_title' => 'Restaurar da nuvem',
			'settings.restore_modal_fetching' => 'Buscando backup no GitHub…',
			'settings.restore_modal_applying' => 'Aplicando backup e reiniciando…',
			'settings.restore_modal_preview_desc' => 'Seu backup no Gist contém:',
			'settings.restore_modal_workspaces' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'espaço de trabalho', many: 'workspaces', other: 'espaços de trabalho', ), 
			'settings.restore_modal_projects' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'projeto', many: 'projects', other: 'projetos', ), 
			'settings.restore_modal_categories' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'categoria', many: 'categories', other: 'categorias', ), 
			'settings.restore_modal_templates' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'template', many: 'templates', other: 'templates', ), 
			'settings.restore_modal_time_stats' => 'Inclui dados de acompanhamento de tempo',
			'settings.restore_modal_todos' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Includes ${count} to-do', many: 'Includes ${count} to-dos', other: 'Includes ${count} to-dos', ), 
			'settings.restore_modal_project_scan_dirs' => 'Pastas configuradas para projetos: {{count}}',
			'settings.restore_modal_version_scan_dirs' => 'Pastas configuradas para versões: {{count}}',
			'settings.restore_modal_workspace_list' => 'Espaços de trabalho',
			'settings.restore_modal_warning' => 'Isso substituirá suas configurações atuais e os dados dos espaços de trabalho. Você precisará reiniciar o aplicativo para aplicar as alterações.',
			'settings.restore_modal_apply_btn' => 'Aplicar e reiniciar',
			'settings.restore_modal_done_title' => 'Backup restaurado',
			'settings.restore_modal_done_hint' => 'Clique no botão abaixo para reiniciar e aplicar todas as alterações.',
			'settings.settings_exported' => 'Configurações exportadas.',
			'settings.settings_imported' => 'Configurações importadas.',
			'settings.stats_imported' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Estatísticas importadas para ${count} projeto.', many: 'Imported stats for ${count} projects.', other: 'Estatísticas importadas para ${count} projetos.', ), 
			'settings.raised_contrast_label' => 'Contraste dos componentes',
			'settings.raised_contrast_value' => '{{value}}%',
			'settings.token_help_desc' => 'Crie um token em github.com/settings/tokens. Você só precisa marcar o escopo repo se quiser acesso a repositórios privados; caso contrário, deixe todos os escopos desmarcados. Nenhuma permissão sensível é necessária.',
			'settings.discord_app_id_label' => 'ID do aplicativo do Discord',
			'settings.discord_app_id_placeholder' => 'Deixe vazio para usar o padrão integrado',
			'settings.discord_app_id_desc' => 'Crie um aplicativo no Discord Developer Portal e cole aqui o ID do aplicativo para usar o seu em vez do padrão integrado do GodotHub. A atividade será exibida com o nome desse aplicativo.',
			'settings.discord_developer_portal' => 'Discord Developer Portal',
			'settings.discord_builtin_hint' => 'Usando o aplicativo integrado do GodotHub.',
			'settings.discord_show_projects_label' => 'Mostrar nomes dos projetos',
			'settings.discord_excluded_label' => 'Projetos excluídos',
			'settings.discord_exclude_project' => 'Adicionar projeto',
			'settings.discord_excluded_empty' => 'Nenhum projeto excluído.',
			'settings.discord_excluded_remove' => 'Remover dos projetos excluídos',
			'settings.discord_custom_label' => 'Discord Rich Presence personalizada',
			'settings.discord_custom_add' => 'Adicionar projeto',
			'settings.discord_custom_details_placeholder' => 'Linha de detalhes',
			'settings.discord_custom_state_placeholder' => 'Linha de estado',
			'settings.discord_custom_remove' => 'Remover Discord Rich Presence personalizada',
			'settings.search_placeholder' => 'Pesquisar configurações…',
			'settings.interface_label' => 'Interface',
			'settings.card_layout_label' => 'Layout em cartões',
			'settings.landing_tab_label' => 'Página inicial padrão',
			'settings.language_complete' => 'Completo',
			'settings.language_beta' => 'Beta',
			'settings.language_incomplete' => 'Incompleto',
			'settings.use_os_decorations' => 'Usar decorações de janela do sistema',
			'settings.credits' => 'Créditos',
			'settings.credits_developer' => 'Criado por',
			'settings.credits_built_with' => 'Desenvolvido com',
			'settings.credits_contributors' => 'Colaboradores',
			'settings.experimental' => 'Experimental',
			'settings.customize_view_label' => 'Botão Personalizar modo de exibição',
			'settings.fixed_sidebar_resize_knob_label' => 'Fixed sidebar resize knob',
			'settings.desktop_notifications_label' => 'Desktop notifications',
			'settings.colored_titlebar_buttons_label' => 'Colored window buttons',
			'settings.project_todos_label' => 'Próximos passos dos projetos',
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
			'settings.features_enabled_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} feature on', many: '${count} features on', other: '${count} features on', ), 
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
			'todos.next_steps' => 'Próximos passos',
			'todos.saving_tasks' => 'Salvando tarefas',
			'todos.pending_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} pendente', many: '${count} pending', other: '${count} pendentes', ), 
			'todos.completed_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} concluída', many: '${count} completed', other: '${count} concluídas', ), 
			'todos.new_task' => 'Nova tarefa',
			'todos.hide_next_steps' => 'Ocultar próximos passos',
			'todos.save_changes_failed' => 'Não foi possível salvar as alterações.',
			'todos.loading_tasks' => 'Carregando tarefas...',
			'todos.load_tasks_failed' => 'Não foi possível carregar as tarefas',
			'todos.data_unchanged' => 'Seus dados não foram modificados.',
			'todos.empty_title' => 'Nenhuma tarefa ainda',
			'todos.empty_description' => 'Adicione o primeiro próximo passo deste projeto.',
			'todos.create_task' => 'Criar tarefa',
			'todos.all_completed_title' => 'Tudo concluído',
			'todos.all_completed_description' => 'Você concluiu todos os próximos passos deste projeto.',
			_ => null,
		} ?? switch (path) {
			'todos.footer_hint' => 'Use a lista para acompanhar os próximos passos do projeto.',
			'todos.view_all' => 'Ver todas',
			'todos.delete_task_title' => 'Excluir tarefa?',
			'todos.delete_task_description' => 'A tarefa <strong>“{{title}}”</strong> será excluída. Esta ação não pode ser desfeita.',
			'todos.task' => 'Tarefa',
			'todos.area' => 'Área',
			'todos.status' => 'Status',
			'todos.due_date' => 'Prazo',
			'todos.sort_by_status' => 'Ordenar por status',
			'todos.sort_by_due_date' => 'Ordenar por prazo',
			'todos.change_status' => 'Alterar status: {{status}}',
			'todos.overdue' => 'Prazo vencido',
			'todos.mark_completed' => 'Marcar tarefa como concluída',
			'todos.mark_not_completed' => 'Marcar tarefa como não concluída',
			'todos.view_task_details' => 'Ver detalhes da tarefa: {{title}}',
			'todos.task_actions' => 'Ações da tarefa',
			'todos.edit' => 'Editar',
			'todos.status_todo' => 'A fazer',
			'todos.status_paused' => 'Em pausa',
			'todos.status_in_progress' => 'Em andamento',
			'todos.status_done' => 'Concluída',
			'todos.area_programming' => 'Programação',
			'todos.area_art' => 'Arte',
			'todos.area_audio' => 'Áudio',
			'todos.area_design' => 'Design',
			'todos.area_narrative' => 'Narrativa',
			'todos.area_other' => 'Outro',
			'todos.edit_task' => 'Editar tarefa',
			'todos.title' => 'Título',
			'todos.title_placeholder' => 'Ex.: Criar menu principal',
			'todos.description_placeholder' => 'Adicione mais detalhes sobre o que precisa ser feito...',
			'todos.no_due_date' => 'Sem prazo',
			'todos.remove_due_date' => 'Remover prazo',
			'todos.past_due_date' => 'Este prazo já venceu',
			'todos.save_task_failed' => 'Não foi possível salvar a tarefa. Tente novamente.',
			'todos.add_task' => 'Adicionar tarefa',
			'todos.no_description' => 'Sem descrição',
			'todos.tomorrow' => 'Amanhã',
			'todos.due_in_days' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Vence em ${count} dia', many: 'Due in ${count} days', other: 'Vence em ${count} dias', ), 
			'todos.overdue_yesterday' => 'Venceu ontem',
			'todos.overdue_days' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Venceu há ${count} dia', many: 'Overdue by ${count} days', other: 'Venceu há ${count} dias', ), 
			'todos.scan_code' => 'Scan code',
			'todos.scan_code_hint' => 'Import TODO and FIXME comments from scripts and shaders, and complete to-dos whose comment was removed',
			'todos.comment_scan_summary' => 'Code scan: {{imported}} added, {{closed}} completed, {{reopened}} reopened',
			'todos.comment_scan_none' => 'Code scan found no changes',
			'todos.commit_closed' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Completed ${count} to-do from a commit message', many: 'Completed ${count} to-dos from commit messages', other: 'Completed ${count} to-dos from commit messages', ), 
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
			'todos.open_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} to-do', many: '${count} to-dos', other: '${count} to-dos', ), 
			'todos.overdue_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '${count} overdue', many: '${count} overdue', other: '${count} overdue', ), 
			'todos.tile_summary' => '{{overdue}} overdue · {{soon}} due this week',
			'todos.tile_empty' => 'Nothing overdue or due this week.',
			'todos.due_notification_title' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'To-do due: {{title}}', many: '${count} to-dos are due', other: '${count} to-dos are due', ), 
			'todos.due_notification_more' => 'and {{count}} more',
			'versions.standard' => 'Standard (GDScript)',
			'versions.unbound' => 'Não atribuído',
			'versions.mono' => 'Mono (.NET)',
			'versions.both' => 'Ambos',
			'versions.stable' => 'Estável',
			'versions.unstable' => 'Instável',
			'versions.rename' => 'Renomear',
			'versions.open_editor' => 'Abrir Editor',
			'versions.open_editor_with_console' => 'Abrir Editor com Console',
			'versions.more_editor_launch_options' => 'Mais opções para abrir o editor',
			'versions.open_install_folder' => 'Abrir pasta de instalação',
			'versions.type' => 'Tipo',
			'versions.channel' => 'Canal',
			'versions.fetch_error' => 'Não foi possível buscar as versões disponíveis.',
			'versions.paused_dot' => 'Pausado · ',
			'versions.available_title' => 'VERSÕES DISPONÍVEIS',
			'versions.no_versions_match' => 'Nenhuma versão instalada corresponde à busca',
			'versions.no_available_versions_match' => 'Nenhuma versão disponível corresponde à busca',
			'versions.open' => 'Abrir',
			'versions.install' => 'Instalar',
			'versions.mb' => 'MB',
			'versions.resume_download' => 'Retomar download',
			'versions.pause_download' => 'Pausar download',
			'versions.cancel_download' => 'Cancelar download',
			'versions.installed_count' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, zero: 'Nenhuma instalada', one: 'Instalada', many: 'Installed', other: 'Instaladas', ), 
			'versions.installed_label' => 'Instalado',
			'versions.original_name' => 'Original',
			'versions.source' => 'Origem',
			'versions.source_github' => 'GitHub',
			'versions.source_archive' => 'Godot Archive',
			'versions.source_mise' => 'mise',
			'versions.switch_to_archive' => 'Mudar para Godot Archive',
			'versions.sort_version_latest' => 'Mais recente',
			'versions.sort_version_oldest' => 'Mais antiga',
			'versions.sort_version_recently_installed' => 'Instalada recentemente',
			'versions.sort_version_oldest_installed' => 'Instalada há mais tempo',
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
			'versions.alias_create_all' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: 'Create Alias', many: 'Create ${count} Aliases', other: 'Create ${count} Aliases', ), 
			'versions.aliases_batch_created' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '1 alias created', many: '${count} aliases created', other: '${count} aliases created', ), 
			'versions.aliases_batch_skipped' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '1 alias skipped', many: '${count} aliases skipped', other: '${count} aliases skipped', ), 
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
			'versions.templates_folder' => 'Pasta de modelos',
			'versions.versions_folder' => 'Pasta de versões',
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
			'versions.export_templates_selected' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '1 template selected', many: '${count} templates selected', other: '${count} templates selected', ), 
			'versions.export_templates_size_summary' => '~{{download}} download · {{installed}} on disk',
			'versions.export_templates_download_selected' => 'Download selected',
			'versions.export_templates_loading_options' => 'Checking this release\'s available templates…',
			'versions.export_templates_options_failed' => 'Couldn\'t load the templates for this release.',
			'versions.export_templates_available' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '1 available template group', many: '${count} available template groups', other: '${count} available template groups', ), 
			'versions.export_templates_select_all' => 'Select all',
			'versions.export_templates_files' => ({required num count}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('pt'))(count, one: '1 template file', many: '${count} template files', other: '${count} template files', ), 
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
			'versions.download_failed_title' => 'Falha no download',
			'versions.download_failed_asset_label' => 'Arquivo',
			'versions.download_failed_error_label' => 'Detalhes do erro',
			'versions.download_failed_copy' => 'Copiar detalhes',
			'versions.download_failed_hint' => 'Causas comuns: uma rede ou proxy bloqueado, um antivírus bloqueando o download, uma pasta de download inexistente ou somente leitura, ou pouco espaço em disco.',
			'versions.custom_build_badge' => 'Custom build',
			'versions.add_custom_build' => 'Add custom build…',
			'versions.adding_custom_build' => 'Adding custom build…',
			_ => null,
		};
	}
}
