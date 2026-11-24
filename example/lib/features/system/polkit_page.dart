import 'package:adwaitter_icons/adwaitter_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:libadwaitter/libadwaitter.dart';

class PolkitPage extends StatefulWidget {
  const PolkitPage({super.key});

  @override
  State<PolkitPage> createState() => _PolkitPageState();
}

class _PolkitPageState extends State<PolkitPage> {
  final TextEditingController _executableController =
      TextEditingController(text: 'id');
  final TextEditingController _argumentsController =
      TextEditingController(text: '-un');

  bool _isAuthorizing = false;
  bool _isRunning = false;
  String _authStatus = 'Not checked yet';
  String _commandStatus = 'No command executed yet';
  int? _lastExitCode;
  String _lastStdout = '';
  String _lastStderr = '';
  String? _lastCommand;

  @override
  void dispose() {
    _executableController.dispose();
    _argumentsController.dispose();
    super.dispose();
  }

  Future<void> _requestAdminAuth(
    BuildContext toastContext, {
    required bool allowUserInteraction,
  }) async {
    if (_isAuthorizing) return;
    setState(() {
      _isAuthorizing = true;
      _authStatus = allowUserInteraction
          ? 'Waiting for Polkit authentication...'
          : 'Checking authorization silently...';
    });

    final res = await AdwPortal.requestAdminAuthorization(
      allowUserInteraction: allowUserInteraction,
    );
    if (!mounted) return;

    final statusText = res.isGranted
        ? 'Authorized (Polkit granted)'
        : '${res.status.name}${res.errorMessage != null ? ' — ${res.errorMessage}' : ''}';

    setState(() {
      _isAuthorizing = false;
      _authStatus = statusText;
    });

    if (toastContext.mounted) {
      AdwToastOverlay.maybeOf(toastContext)?.addToast(
        AdwToast(title: Text('Polkit: $statusText')),
      );
    }
  }

  Future<void> _runCommand(
    BuildContext toastContext, {
    required String executable,
    List<String> arguments = const [],
    bool elevated = false,
    bool detached = false,
  }) async {
    final trimmedExecutable = executable.trim();
    if (trimmedExecutable.isEmpty || _isRunning) return;

    final fullCmd = [
      if (elevated) 'pkexec',
      trimmedExecutable,
      ...arguments,
    ].join(' ');

    setState(() {
      _isRunning = true;
      _lastCommand = detached ? '$fullCmd (detached)' : fullCmd;
      _commandStatus = 'Running $fullCmd...';
      _lastExitCode = null;
      _lastStdout = '';
      _lastStderr = '';
    });

    final res = elevated
        ? await AdwPortal.runElevated(
            trimmedExecutable,
            arguments: arguments,
          )
        : await AdwPortal.runCommand(
            trimmedExecutable,
            arguments: arguments,
            detached: detached,
          );
    if (!mounted) return;

    String statusText;
    int? exitCode;
    String stdoutText = '';
    String stderrText = '';

    if (res.isGranted && res.value != null) {
      exitCode = res.value!.exitCode;
      stdoutText = res.value!.stdout.trimRight();
      stderrText = res.value!.stderr.trimRight();
      statusText = detached
          ? 'Launched detached process'
          : (res.value!.isSuccess
              ? 'Completed successfully (exit 0)'
              : 'Exited with code $exitCode');
    } else {
      statusText =
          '${res.status.name}${res.errorMessage != null ? ' — ${res.errorMessage}' : ''}';
      stderrText = res.errorMessage ?? '';
    }

    setState(() {
      _isRunning = false;
      _commandStatus = statusText;
      _lastExitCode = exitCode;
      _lastStdout = stdoutText;
      _lastStderr = stderrText;
    });

    if (toastContext.mounted) {
      AdwToastOverlay.maybeOf(toastContext)?.addToast(
        AdwToast(title: Text(statusText)),
      );
    }
  }

  Future<void> _runCustomCommand(
    BuildContext toastContext, {
    required bool elevated,
    bool detached = false,
  }) {
    final rawArgs = _argumentsController.text.trim();
    final args = rawArgs.isEmpty
        ? const <String>[]
        : rawArgs.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    return _runCommand(
      toastContext,
      executable: _executableController.text,
      arguments: args,
      elevated: elevated,
      detached: detached,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AdwTheme.of(context);

    return AdwToastOverlay(
      child: Builder(
        builder: (toastContext) => AdwPreferencesPage(
          children: [
            const AdwStatusPage(
              icon: Icon(AdwIcons.security_high_symbolic, size: 64),
              title: Text('Polkit (Superuser)'),
              description: Text(
                'Linux-only bridge to org.freedesktop.PolicyKit1 and pkexec for requesting administrator privileges and running elevated commands.',
              ),
            ),
            const SizedBox(height: 16),
            AdwPreferencesGroup(
              title: const Text('Polkit Authorization'),
              description: const Text(
                'Calls org.freedesktop.PolicyKit1.Authority.CheckAuthorization on the system D-Bus.',
              ),
              children: [
                AdwActionRow(
                  prefix: const Icon(AdwIcons.dialog_password_symbolic, size: 18),
                  title: const Text('Administrator Authorization'),
                  subtitle: Text(_authStatus),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdwButton(
                        onPressed: _isAuthorizing
                            ? null
                            : () => _requestAdminAuth(
                                  toastContext,
                                  allowUserInteraction: false,
                                ),
                        child: const Text('Check'),
                      ),
                      const SizedBox(width: 8),
                      AdwButton.suggested(
                        onPressed: _isAuthorizing
                            ? null
                            : () => _requestAdminAuth(
                                  toastContext,
                                  allowUserInteraction: true,
                                ),
                        child: _isAuthorizing
                            ? const AdwSpinner(size: 16)
                            : const Text('Prompt'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AdwPreferencesGroup(
              title: const Text('Quick Tests (Unprivileged & Elevated)'),
              description: const Text(
                'Safe read-only commands to verify both normal (GSubprocess) and elevated (pkexec) execution.',
              ),
              children: [
                AdwActionRow(
                  prefix: const Icon(AdwIcons.utilities_terminal_symbolic, size: 18),
                  title: const Text('Current User (Normal)'),
                  subtitle: const Text('id -un (no sudo / no prompt)'),
                  trailing: AdwButton(
                    onPressed: _isRunning
                        ? null
                        : () => _runCommand(
                              toastContext,
                              executable: 'id',
                              arguments: const ['-un'],
                            ),
                    child: const Text('Run'),
                  ),
                ),
                AdwActionRow(
                  prefix: const Icon(AdwIcons.utilities_terminal_symbolic, size: 18),
                  title: const Text('Kernel Info (Normal)'),
                  subtitle: const Text('uname -a (no sudo / no prompt)'),
                  trailing: AdwButton(
                    onPressed: _isRunning
                        ? null
                        : () => _runCommand(
                              toastContext,
                              executable: 'uname',
                              arguments: const ['-a'],
                            ),
                    child: const Text('Run'),
                  ),
                ),
                AdwActionRow(
                  prefix: const Icon(AdwIcons.security_high_symbolic, size: 18),
                  title: const Text('Effective User (pkexec)'),
                  subtitle: const Text('pkexec id -un (should output "root")'),
                  trailing: AdwButton.suggested(
                    onPressed: _isRunning
                        ? null
                        : () => _runCommand(
                              toastContext,
                              executable: 'id',
                              arguments: const ['-un'],
                              elevated: true,
                            ),
                    child: const Text('pkexec'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AdwPreferencesGroup(
              title: const Text('Custom Command'),
              children: [
                AdwEntryRow(
                  title: const Text('Executable'),
                  controller: _executableController,
                  placeholder: 'e.g. id, whoami, gnome-calculator',
                ),
                AdwEntryRow(
                  title: const Text('Arguments (space-separated)'),
                  controller: _argumentsController,
                  placeholder: 'e.g. -un',
                  onSubmitted: (_) =>
                      _runCustomCommand(toastContext, elevated: false),
                ),
                AdwActionRow(
                  title: const Text('Execute'),
                  subtitle: Text(_commandStatus),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdwButton(
                        onPressed: _isRunning
                            ? null
                            : () => _runCustomCommand(
                                  toastContext,
                                  elevated: false,
                                ),
                        child: const Text('Normal'),
                      ),
                      const SizedBox(width: 8),
                      AdwButton(
                        onPressed: _isRunning
                            ? null
                            : () => _runCustomCommand(
                                  toastContext,
                                  elevated: false,
                                  detached: true,
                                ),
                        child: const Text('Detached'),
                      ),
                      const SizedBox(width: 8),
                      AdwButton.suggested(
                        onPressed: _isRunning
                            ? null
                            : () => _runCustomCommand(
                                  toastContext,
                                  elevated: true,
                                ),
                        child: _isRunning
                            ? const AdwSpinner(size: 16)
                            : const Text('pkexec'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_lastCommand != null) ...[
              const SizedBox(height: 24),
              AdwPreferencesGroup(
                title: const Text('Last Output'),
                children: [
                  AdwActionRow(
                    title: Text(_lastCommand!),
                    subtitle: Text(
                      _lastExitCode != null
                          ? 'Exit code: $_lastExitCode'
                          : _commandStatus,
                    ),
                  ),
                  if (_lastStdout.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'stdout',
                            style: theme.typography.caption.copyWith(
                              color: theme.colors.secondaryForeground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colors.windowBackground,
                              borderRadius:
                                  BorderRadius.circular(AdwMetrics.buttonRadius),
                              border: Border.all(
                                color: theme.colors.borderColor,
                              ),
                            ),
                            child: Text(
                              _lastStdout,
                              style: theme.typography.body.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_lastStderr.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'stderr',
                            style: theme.typography.caption.copyWith(
                              color: theme.colors.destructiveColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colors.windowBackground,
                              borderRadius:
                                  BorderRadius.circular(AdwMetrics.buttonRadius),
                              border: Border.all(
                                color: theme.colors.destructiveColor
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              _lastStderr,
                              style: theme.typography.body.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: theme.colors.destructiveColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
