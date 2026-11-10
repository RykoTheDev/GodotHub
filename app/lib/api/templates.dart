import '../src/rust/api/templates.dart' as rust;
import '../src/rust/api/types.dart';

abstract final class TemplatesApi {
  static Future<List<ProjectTemplate>> list() => rust.listTemplates();

  static Future<ProjectTemplate> saveAsTemplate(
    String projectId,
    String name,
    String description,
  ) => rust.saveProjectAsTemplate(
    projectId: projectId,
    name: name,
    description: description,
  );

  static Future<void> delete(String templateId) =>
      rust.deleteTemplate(templateId: templateId);

  static Future<List<TemplateFileEntry>> getPreview(String templateId) =>
      rust.getTemplatePreview(templateId: templateId);

  static Future<TemplateSyncResult> syncWithScanDir() =>
      rust.syncTemplatesWithScanDir();
}
