import 'dart:convert';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';

class FirestoreExplorerScreen extends StatefulWidget {
  const FirestoreExplorerScreen({super.key});

  @override
  State<FirestoreExplorerScreen> createState() => _FirestoreExplorerScreenState();
}

class _FirestoreExplorerScreenState extends State<FirestoreExplorerScreen> {
  String _selectedCollection = 'users';
  String _searchQuery = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _docs = [];

  final List<String> _collections = [
    'users',
    'products',
    'orders',
    'crop_plans',
    'soil_reports',
    'machinery_requests',
    'machinery_inventory',
    'notifications',
    'community_posts',
    'scan_history',
    'crop_offers',
    'purchases',
    'login_history',
    'audit_logs',
  ];

  @override
  void initState() {
    super.initState();
    _loadCollectionData();
  }

  Future<void> _loadCollectionData() async {
    setState(() => _isLoading = true);
    try {
      final list = await FirestoreService().getCollectionDocs(_selectedCollection);
      _docs = list;
    } catch (e) {
      debugPrint('[FIRESTORE_EXPLORER] Error loading collection $_selectedCollection: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _docs.where((d) {
      final str = jsonEncode(d).toLowerCase();
      return str.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Firestore Database Explorer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCollectionData,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Collection Selector & Search Bar
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCollection,
                        items: _collections.map((c) => DropdownMenuItem(value: c, child: Text('📁 $c', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCollection = val);
                            _loadCollectionData();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search doc keys & values...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Collection Header Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Collection: $_selectedCollection', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen)),
                  Text('${filtered.length} Documents Found', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 12),

              // Documents List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.dataset_linked_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text('No documents in "$_selectedCollection".', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final doc = filtered[index];
                              final docId = doc['_docId'] ?? doc['id'] ?? 'doc_$index';

                              return Card(
                                color: Colors.white,
                                elevation: 1,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ExpansionTile(
                                  leading: const Icon(Icons.description_rounded, color: AppTheme.primaryGreen),
                                  title: Text('Doc ID: $docId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text('${doc.keys.length} fields logged', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                    onPressed: () => _deleteDocument(_selectedCollection, docId),
                                    tooltip: 'Delete Document',
                                  ),
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      color: Colors.grey.shade50,
                                      child: SelectableText(
                                        const JsonEncoder.withIndent('  ').convert(doc),
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDocument(String collection, String docId) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Firestore Document?'),
        content: Text('Are you sure you want to delete "$docId" from collection "$collection"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirestoreService().deleteCollectionDoc(collection, docId);
              await FirestoreService().logAuditEvent(
                userId: 'ADMIN',
                action: 'Deleted Firestore Doc',
                category: 'ADMIN',
                details: 'Deleted doc $docId from $collection',
              );
              _loadCollectionData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
