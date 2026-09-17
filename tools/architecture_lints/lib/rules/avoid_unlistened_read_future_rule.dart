import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Rule that enforces not calling .read(provider.future) without subscription.
class AvoidUnlistenedReadFutureRule extends AnalysisRule {
  /// Creates the avoid unlistened read future rule.
  new()
    : super(
        name: 'avoid_unlistened_read_future',
        description:
            'Enforces that .future is not read via ref.read or '
            'container.read without active subscription.',
      );

  /// Diagnostic code for avoid unlistened read future violations.
  static const lint = LintCode(
    'avoid_unlistened_read_future',
    'Avoid calling {0}.read({1}.future). '
        'Reading .future on an unlistened auto-disposed provider causes it '
        'to be disposed during loading, throwing StateError. '
        'Query the repository directly or keep a subscription.',
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
    registry.addMethodInvocation(this, _ReadFutureVisitor(this, context));
  }
}

class _ReadFutureVisitor extends SimpleAstVisitor<void> {
  new(this.rule, this.context);

  final AvoidUnlistenedReadFutureRule rule;
  final RuleContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final root = node.root;
    final path = root is CompilationUnit
        ? root.declaredFragment?.source.fullName.replaceAll(r'\', '/')
        : null;
    if (path == null) return;
    if (path.contains('/test/') ||
        path.contains('/integration_test/') ||
        path.endsWith('.g.dart') ||
        path.endsWith('.freezed.dart') ||
        path.contains('/l10n/') ||
        path.endsWith('firebase_options.dart')) {
      return;
    }

    if (node.methodName.name != 'read') return;
    if (node.argumentList.arguments.isEmpty) return;

    final target = node.target;
    if (target == null) return;
    final targetName = target.toString();
    if (!targetName.contains('ref') &&
        !targetName.contains('container') &&
        !targetName.contains('Ref')) {
      return;
    }

    final firstArg = node.argumentList.arguments.first;
    String? providerName;
    if (firstArg is PrefixedIdentifier &&
        firstArg.identifier.name == 'future') {
      providerName = firstArg.prefix.name;
    } else if (firstArg is PropertyAccess &&
        firstArg.propertyName.name == 'future') {
      providerName = firstArg.target?.toString();
    }

    if (providerName != null && providerName.contains('Provider')) {
      rule.reportAtOffset(
        node.offset,
        node.length,
        arguments: [targetName, providerName],
      );
    }
  }
}
