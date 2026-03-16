// lib/screens/voice_transcript_review_screen.dart
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

/// Screen shown after a batch recording session ends (or when reviewing the
/// offline queue).  Lets the user edit, reorder, merge and delete raw
/// transcriptions before sending them to the AI processing pipeline.
///
/// [onSendToAI] is called with the final (possibly edited/merged) list when the
/// user confirms processing.
///
/// [onLeave] is called with the items that are still present whenever the
/// screen is dismissed WITHOUT processing (back button OR "Mantieni in coda").
/// Receives an empty list if the user deleted everything.
/// The parent is responsible for updating the offline queue accordingly.
class VoiceTranscriptReviewScreen extends StatefulWidget {
  final List<String> initialTranscriptions;
  /// Called when the user confirms sending to AI.
  /// Must return [true] if the screen was navigated away from (success),
  /// or [false] if the screen should stay visible (failure / partial retry).
  /// This drives [_processingComplete] so that the back-gesture correctly
  /// invokes [onLeave] only when processing was not already handled.
  final Future<bool> Function(List<String> transcriptions) onSendToAI;
  final void Function(List<String> remaining) onLeave;

  const VoiceTranscriptReviewScreen({
    Key? key,
    required this.initialTranscriptions,
    required this.onSendToAI,
    required this.onLeave,
  }) : super(key: key);

  @override
  State<VoiceTranscriptReviewScreen> createState() =>
      _VoiceTranscriptReviewScreenState();
}

class _VoiceTranscriptReviewScreenState
    extends State<VoiceTranscriptReviewScreen> {
  late List<String> _items;
  late List<TextEditingController> _controllers;
  late List<int> _itemIds;
  int _nextId = 0;

  final Set<int> _mergingIds = {};
  int _editingId = -1;

  bool _isProcessing = false;
  // Set to true when onSendToAI completes so onLeave is not called on pop.
  bool _processingComplete = false;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.initialTranscriptions);
    _controllers =
        _items.map((t) => TextEditingController(text: t)).toList();
    _itemIds = List.generate(_items.length, (_) => _nextId++);
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _indexOf(int id) => _itemIds.indexOf(id);

  List<String> _currentItems() {
    // Flush any pending edit before returning the list.
    final idx = _indexOf(_editingId);
    if (idx >= 0) {
      final t = _controllers[idx].text.trim();
      if (t.isNotEmpty) _items[idx] = t;
    }
    return List<String>.from(_items);
  }

  // ── Edit ──────────────────────────────────────────────────────────────────

  void _startEdit(int index) {
    _commitEdit();
    setState(() => _editingId = _itemIds[index]);
    final c = _controllers[index];
    c.selection =
        TextSelection.fromPosition(TextPosition(offset: c.text.length));
  }

  void _commitEdit() {
    final idx = _indexOf(_editingId);
    if (idx < 0) return;
    final newText = _controllers[idx].text.trim();
    setState(() {
      if (newText.isNotEmpty) _items[idx] = newText;
      _editingId = -1;
    });
  }

  void _deleteItem(int index) {
    final deletedId = _itemIds[index];
    setState(() {
      _controllers[index].dispose();
      _items.removeAt(index);
      _controllers.removeAt(index);
      _itemIds.removeAt(index);
      if (_editingId == deletedId) _editingId = -1;
    });
  }

  // ── Reorder ───────────────────────────────────────────────────────────────

  void _onReorder(int oldIndex, int newIndex) {
    _commitEdit();
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      final ctrl = _controllers.removeAt(oldIndex);
      _controllers.insert(newIndex, ctrl);
      final id = _itemIds.removeAt(oldIndex);
      _itemIds.insert(newIndex, id);
    });
  }

  // ── Merge ─────────────────────────────────────────────────────────────────

  Future<void> _mergeWithNext(int index) async {
    if (index >= _items.length - 1) return;
    _commitEdit();

    final idA = _itemIds[index];
    final idB = _itemIds[index + 1];
    setState(() => _mergingIds.addAll([idA, idB]));

    await Future.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;

    setState(() {
      final merged =
          '${_items[index].trimRight()} ${_items[index + 1].trimLeft()}';
      _items[index] = merged;
      _controllers[index].text = merged;
      _controllers[index + 1].dispose();
      _items.removeAt(index + 1);
      _controllers.removeAt(index + 1);
      _itemIds.removeAt(index + 1);
      _mergingIds.clear();
      if (_editingId == idB) _editingId = idA;
    });
  }

  // ── Send to AI ────────────────────────────────────────────────────────────

  Future<void> _sendToAI() async {
    _commitEdit();
    final toProcess = _currentItems();
    setState(() => _isProcessing = true);
    try {
      // _processingComplete is set to the return value:
      //   true  → onSendToAI popped this screen (success) → onLeave must NOT fire
      //   false → onSendToAI returned early (error) → screen stays open, onLeave WILL fire on back
      _processingComplete = await widget.onSendToAI(toProcess);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Leave without processing ──────────────────────────────────────────────

  void _leave() {
    if (!_processingComplete) {
      widget.onLeave(_currentItems());
    }
    Navigator.of(context).pop();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Intercept hardware/gesture back to call onLeave with remaining items.
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _leave),
          title: Text('Revisione (${_items.length})'),
          actions: [
            if (_items.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Elimina tutto'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Eliminare tutto?'),
                      content: const Text(
                          'Tutte le trascrizioni verranno rimosse dalla lista.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annulla'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              for (final c in _controllers) c.dispose();
                              _items.clear();
                              _controllers.clear();
                              _itemIds.clear();
                              _editingId = -1;
                            });
                          },
                          child: const Text('Elimina tutto',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            _buildInfoBanner(),
            Expanded(
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      onReorder: _onReorder,
                      itemCount: _items.length,
                      itemBuilder: (context, i) =>
                          _buildTranscriptCard(i),
                    ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: ThemeConstants.primaryColor.withOpacity(0.07),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: ThemeConstants.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Trascina ≡ per riordinare, poi unisci le voci adiacenti.',
              style: TextStyle(
                  fontSize: 12,
                  color: ThemeConstants.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline,
              size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Nessuna trascrizione rimasta.',
            style: TextStyle(color: ThemeConstants.textSecondaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Premi "Mantieni in coda" per uscire o torna indietro.',
            style: TextStyle(
                fontSize: 12,
                color: ThemeConstants.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard(int index) {
    final id = _itemIds[index];
    final isMerging = _mergingIds.contains(id);
    final isEditing = _editingId == id;
    final isLast = index == _items.length - 1;

    return Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isMerging ? Colors.amber.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMerging
                ? Colors.amber.shade400
                : isEditing
                    ? ThemeConstants.primaryColor
                    : Colors.grey.shade200,
            width: isMerging || isEditing ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 8, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(4, 2, 6, 0),
                      child: Icon(Icons.drag_handle,
                          color: Colors.grey.shade400, size: 22),
                    ),
                  ),
                  // Number badge
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isMerging
                          ? Colors.amber.shade400
                          : ThemeConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text / edit field
                  Expanded(
                    child: isEditing
                        ? TextField(
                            controller: _controllers[index],
                            maxLines: null,
                            autofocus: true,
                            style: const TextStyle(
                                fontSize: 14, height: 1.45),
                            decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero),
                            onSubmitted: (_) => _commitEdit(),
                          )
                        : GestureDetector(
                            onTap: () => _startEdit(index),
                            child: Text(_items[index],
                                style: const TextStyle(
                                    fontSize: 14, height: 1.45)),
                          ),
                  ),
                  // Edit / confirm + delete
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEditing)
                        IconButton(
                          icon: Icon(Icons.check_circle,
                              color: ThemeConstants.primaryColor,
                              size: 20),
                          onPressed: _commitEdit,
                          tooltip: 'Salva',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.edit_outlined,
                              color: Colors.grey.shade500, size: 18),
                          onPressed: () => _startEdit(index),
                          tooltip: 'Modifica',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade300, size: 18),
                        onPressed: () => _deleteItem(index),
                        tooltip: 'Elimina',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Merge button (not shown on last item)
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(
                    left: 44, right: 12, bottom: 8),
                child: GestureDetector(
                  onTap:
                      isMerging ? null : () => _mergeWithNext(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isMerging
                          ? Colors.amber.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isMerging
                            ? Colors.amber.shade300
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.merge_type,
                            size: 14,
                            color: isMerging
                                ? Colors.amber.shade700
                                : Colors.grey.shade600),
                        const SizedBox(width: 5),
                        Text(
                          isMerging
                              ? 'Unione in corso…'
                              : 'Unisci con la successiva ↓',
                          style: TextStyle(
                            fontSize: 12,
                            color: isMerging
                                ? Colors.amber.shade700
                                : Colors.grey.shade700,
                            fontWeight: isMerging
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.save_outlined),
                label: const Text('Mantieni in coda'),
                onPressed: _isProcessing ? null : _leave,
                style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white)))
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isProcessing
                    ? 'Elaborazione…'
                    : 'Invia all\'elaborazione'
                        '${_items.isNotEmpty ? ' (${_items.length})' : ''}'),
                onPressed: (_isProcessing || _items.isEmpty)
                    ? null
                    : _sendToAI,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
