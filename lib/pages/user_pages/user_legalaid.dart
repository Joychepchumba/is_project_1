import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:is_project_1/components/custom_bootom_navbar.dart';
import 'package:is_project_1/models/legal_aid_models.dart';
import 'package:is_project_1/models/legal_tips_models.dart'
    as tips; // Make sure this is the correct import
import 'package:is_project_1/pages/user_pages/legal_aid_tip_detail';
import 'package:is_project_1/pages/user_pages/legal_requests.dart';
import 'package:is_project_1/pages/user_pages/legal_aid_request_form.dart';
import 'package:is_project_1/services/legal_tips_service.dart' hide LegalTip;
import 'package:timeago/timeago.dart' as timeago;
import '../../models/legal_aid_requests.dart';
import '../../services/legal_aid_service.dart';
import 'legal_aid_provider_detail.dart';

class UserLegalaid extends StatefulWidget {
  const UserLegalaid({super.key});

  @override
  State<UserLegalaid> createState() => _UserLegalaidState();
}

class _UserLegalaidState extends State<UserLegalaid> {
  List<LegalAidProvider> _providers = [];
  List<LegalAidProvider> _legalAidProviders = [];
  bool _isLoading = true;
  String? _error;
  bool _isLoadingTips = true;
  List<tips.LegalTip> _publishedTips =
      []; // Instead of List<Object?> or dynamic
  String? _tipsError;
  final LegalTipsService _legalTipsService = LegalTipsService();
  final LegalAidService _legalAidService = LegalAidService();

  @override
  void initState() {
    super.initState();
    _loadLegalAidProviders();
    _fetchPublishedTips();
  }

  Future<void> _fetchPublishedTips() async {
    setState(() {
      _isLoadingTips = true;
      _tipsError = null;
    });

    try {
      final response = await _legalTipsService.getRecentPublishedTips(limit: 3);

      if (response.success && response.data != null) {
        setState(() {
          _publishedTips = response.data!;
          _isLoadingTips = false;
        });
      } else {
        setState(() {
          _tipsError = response.error ?? 'Failed to fetch legal tips';
          _isLoadingTips = false;
        });
      }
    } catch (e) {
      setState(() {
        _tipsError = 'Network error: $e';
        _isLoadingTips = false;
      });
    }
  }

  Future<void> _loadLegalAidProviders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final providers = await LegalAidService.getLegalAidProviders();

      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Legal Aid',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black87,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions Section
            _buildSectionHeader('Quick Actions'),
            const SizedBox(height: 16),
            _buildQuickActionsRow(context),

            const SizedBox(height: 30),

            // Legal Aid Providers Section
            _buildSectionHeader('Legal Aid Providers'),
            const SizedBox(height: 16),
            _buildBody(),

            const SizedBox(height: 30),

            // Legal Aid Tips Section
            _buildSectionHeader('Legal Aid Tips'),
            const SizedBox(height: 16),
            _buildLegalAidTips(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading providers',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLegalAidProviders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No legal aid providers available',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLegalAidProviders,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.balance, color: Colors.blue[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Legal Aid Providers',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select a qualified legal professional to assist you.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Providers List
            _buildLegalAidProviders(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalAidProviders() {
    return Column(
      children: _providers
          .map(
            (provider) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildProviderCard(provider),
            ),
          )
          .toList(),
    );
  }

  Widget _buildProviderCard(LegalAidProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LegalAidProviderDetail(provider: provider),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile Image
            CircleAvatar(
              radius: 30,
              backgroundImage: provider.profileImage != null
                  ? NetworkImage(provider.profileImage!)
                  : null,
              backgroundColor: Colors.blue[100],
              child: provider.profileImage == null
                  ? Icon(Icons.person, color: Colors.blue[600], size: 30)
                  : null,
            ),

            const SizedBox(width: 16),

            // Provider Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.allExpertiseAreas,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: provider.status == 'active'
                          ? Colors.green[100]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      provider.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: provider.status == 'active'
                            ? Colors.green[800]
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            'My Legal\nRequests',
            'Your requests',
            Colors.blue,
            Icons.request_page_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LegalRequestsScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildQuickActionCard(
            context,
            'Request',
            'Legal Aid\nProvider',
            Colors.blue,
            Icons.person_add_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LegalAidRequestForm()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalAidTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with refresh button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _fetchPublishedTips,
              icon: const Icon(Icons.refresh, color: Colors.grey),
              tooltip: 'Refresh tips',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Content
        if (_isLoadingTips)
          _buildTipsLoadingState()
        else if (_tipsError != null)
          _buildTipsErrorState()
        else if (_publishedTips.isEmpty)
          _buildTipsEmptyState()
        else
          _buildTipsList(),
      ],
    );
  }

  Widget _buildTipsLoadingState() {
    return Container(
      height: 150,
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildTipsErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
          const SizedBox(height: 8),
          Text(
            'Error loading tips',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _tipsError!,
            style: TextStyle(color: Colors.red.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchPublishedTips,
            child: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            'No legal tips available',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back later for new legal tips from our providers.',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsList() {
    return Column(
      children: _publishedTips.map((tip) => _buildTipCard(tip)).toList(),
    );
  }

  Widget _buildTipCard(tips.LegalTip tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToTipDetail(tip),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              _buildTipImage(tip),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      tip.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Description preview
                    Text(
                      tip.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Provider and time
                    Row(
                      children: [
                        Expanded(child: _buildProviderInfo(tip)),
                        Text(
                          timeago.format(tip.publishedAt ?? tip.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipImage(tips.LegalTip tip) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: tip.imageUrl != null && tip.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: tip.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                ),
              )
            : Container(
                color: Colors.blue.shade50,
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue.shade400,
                  size: 32,
                ),
              ),
      ),
    );
  }

  Widget _buildProviderInfo(tips.LegalTip tip) {
    return Row(
      children: [
        Icon(Icons.person, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            tip.legalAidProvider?.fullName ?? 'Legal Provider',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _navigateToTipDetail(tips.LegalTip tip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LegalTipDetailPage(tip: tip)),
    );
  }
}
