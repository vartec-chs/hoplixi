import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/features/localsend/utils/network_diagnostics.dart';

class NetworkDiagnosticsScreen extends ConsumerStatefulWidget {
  const NetworkDiagnosticsScreen({super.key});

  @override
  ConsumerState<NetworkDiagnosticsScreen> createState() =>
      _NetworkDiagnosticsScreenState();
}

class _NetworkDiagnosticsScreenState
    extends ConsumerState<NetworkDiagnosticsScreen> {
  NetworkDiagnosticResult? _result;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _result = null;
    });

    try {
      final result = await NetworkDiagnostics.performFullDiagnostic();
      setState(() {
        _result = result;
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Диагностика сети'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          if (!_isRunning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runDiagnostics,
            ),
        ],
      ),
      body: _isRunning
          ? _buildLoadingView()
          : _result != null
          ? _buildResultView()
          : _buildErrorView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Проверяем сетевые настройки...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Не удалось выполнить диагностику'),
          const SizedBox(height: 16),
          SmoothButton(
            type: SmoothButtonType.outlined,
            label: 'Повторить',
            onPressed: _runDiagnostics,
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final result = _result!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Общий статус
          _buildStatusCard(result),
          const SizedBox(height: 16),

          // Сетевые интерфейсы
          _buildInterfacesCard(result),
          const SizedBox(height: 16),

          // Порты
          _buildPortsCard(result),
          const SizedBox(height: 16),

          // Проблемы
          if (result.issues.isNotEmpty) ...[
            _buildIssuesCard(result),
            const SizedBox(height: 16),
          ],

          // Рекомендации
          _buildRecommendationsCard(result),
        ],
      ),
    );
  }

  Widget _buildStatusCard(NetworkDiagnosticResult result) {
    final hasPrivateIp = result.interfaces.any((i) => i.isPrivateRange);
    final hasAvailablePorts = result.portAvailability.values.any(
      (available) => available,
    );
    final criticalIssues = result.issues
        .where((i) => i.severity == IssueSeverity.critical)
        .length;

    final isHealthy = hasPrivateIp && hasAvailablePorts && criticalIssues == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Статус сети',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isHealthy
                  ? 'Сеть готова для LocalSend'
                  : 'Обнаружены проблемы с сетевыми настройками',
              style: TextStyle(
                color: isHealthy ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (result.localIp != null) ...[
              const SizedBox(height: 8),
              Text('Предпочтительный IP: ${result.localIp}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInterfacesCard(NetworkDiagnosticResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Сетевые интерфейсы (${result.interfaces.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (result.interfaces.isEmpty)
              const Text(
                'Нет активных интерфейсов',
                style: TextStyle(color: Colors.red),
              )
            else
              ...result.interfaces.map(
                (interface) => _buildInterfaceItem(interface),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterfaceItem(NetworkInterfaceInfo interface) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            interface.isPrivateRange ? Icons.wifi : Icons.public,
            color: interface.isPrivateRange ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  interface.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  interface.ip,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              interface.isPrivateRange ? 'Приватный' : 'Публичный',
              style: const TextStyle(fontSize: 12),
            ),
            backgroundColor: interface.isPrivateRange
                ? Colors.green.shade100
                : Colors.orange.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildPortsCard(NetworkDiagnosticResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Доступность портов',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...result.portAvailability.entries.map(
              (entry) => _buildPortItem(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortItem(int port, bool available) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text('Порт $port'),
          const Spacer(),
          Text(
            available ? 'Доступен' : 'Занят',
            style: TextStyle(
              color: available ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesCard(NetworkDiagnosticResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Обнаруженные проблемы (${result.issues.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...result.issues.map((issue) => _buildIssueItem(issue)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItem(NetworkIssue issue) {
    Color getColor(IssueSeverity severity) {
      switch (severity) {
        case IssueSeverity.info:
          return Colors.blue;
        case IssueSeverity.warning:
          return Colors.orange;
        case IssueSeverity.critical:
          return Colors.red;
      }
    }

    IconData getIcon(IssueSeverity severity) {
      switch (severity) {
        case IssueSeverity.info:
          return Icons.info;
        case IssueSeverity.warning:
          return Icons.warning;
        case IssueSeverity.critical:
          return Icons.error;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            getIcon(issue.severity),
            color: getColor(issue.severity),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: getColor(issue.severity),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  issue.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(NetworkDiagnosticResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Рекомендации',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.recommendations.isEmpty)
              const Text('Дополнительных рекомендаций нет')
            else
              ...result.recommendations.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key + 1}. '),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
