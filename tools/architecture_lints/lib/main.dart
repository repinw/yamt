import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// The entrypoint instance for the plugin.
final plugin = ArchitectureLintsPlugin();

/// Plugin providing custom architecture lints.
class ArchitectureLintsPlugin extends Plugin {
  @override
  String get name => 'architecture_lints';

  @override
  void register(PluginRegistry registry) {
    registry.registerWarningRule(MaxFileLinesRule());
  }
}

/// Rule that enforces files do not exceed 300 lines.
class MaxFileLinesRule extends AnalysisRule {
  /// Creates the max file lines rule.
  MaxFileLinesRule()
      : super(
          name: 'max_file_lines',
          description: 'Enforces that files do not exceed 300 lines.',
        );

  /// Diagnostic code for max file lines violations.
  static const lint = LintCode(
    'max_file_lines',
    'File exceeds the limit of {0} lines ({1} lines). '
    'Split it per architecture.md.',
  );

  @override
  DiagnosticCode get diagnosticCode => lint;

  @override
  bool get canUseParsedResult => true;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final MaxFileLinesRule rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final path = node.declaredFragment?.source.fullName.replaceAll(r'\', '/');
    if (path == null) return;
    if (path.contains('/test/') ||
        path.contains('/integration_test/') ||
        path.endsWith('.g.dart') ||
        path.endsWith('.freezed.dart') ||
        path.contains('/l10n/') ||
        path.endsWith('firebase_options.dart')) {
      return;
    }

    final lineCount = node.lineInfo.lineCount;
    if (lineCount > 300) {
      rule.reportAtOffset(0, 0, arguments: [300, lineCount]);
    }
  }
}
