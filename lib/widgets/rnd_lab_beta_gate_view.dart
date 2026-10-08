import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/production_game_service.dart';

/// Futuristic Closed Beta / In-Development Gate for the R&D Lab.
///
/// Displays a teaser screen with community Discord links and an in-place
/// code redemption field to unlock the full laboratory via `RNDBETA2026`.
class RnDLabBetaGateView extends StatefulWidget {
  final ProductionGameService gameService;

  const RnDLabBetaGateView({
    super.key,
    required this.gameService,
  });

  @override
  State<RnDLabBetaGateView> createState() => _RnDLabBetaGateViewState();
}

class _RnDLabBetaGateViewState extends State<RnDLabBetaGateView> {
  final TextEditingController _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter a beta access code.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final result = widget.gameService.redeemCode(code);
    _codeController.clear();
    setState(() => _isSubmitting = false);

    Color snackBarColor;
    switch (result.status) {
      case RedeemCodeResult.rewardClaimed:
      case RedeemCodeResult.devUnlocked:
        snackBarColor = Colors.green;
        HapticFeedback.heavyImpact();
        break;
      case RedeemCodeResult.alreadyRedeemed:
        snackBarColor = Colors.orange;
        break;
      case RedeemCodeResult.invalid:
        snackBarColor = Colors.red;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: snackBarColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _copyDiscordLink() {
    Clipboard.setData(const ClipboardData(text: 'https://discord.gg/production-inc'));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Discord invite link copied to clipboard!'),
        backgroundColor: Colors.indigo,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Teaser Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF28183F), Color(0xFF131D36)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.purpleAccent.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top Protocol Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.purpleAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_clock, size: 14, color: Colors.purpleAccent),
                      SizedBox(width: 6),
                      Text(
                        'EXPERIMENTAL PROTOCOL // CLOSED BETA',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Holographic Lab Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purpleAccent.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.purpleAccent.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.biotech_outlined,
                      size: 42,
                      color: Colors.purpleAccent,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'R&D Facility In Development',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'The engineering department is currently calibrating the Deconstruction Chamber and Factory Tech Matrix.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(color: Colors.white12),
                const SizedBox(height: 20),

                // Discord Community Teaser Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5865F2).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF5865F2).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, color: Color(0xFF7289DA), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Discord Closed Beta Access',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Beta keys are distributed to early testers on our Discord server. Join the community to get your test key!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _copyDiscordLink,
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Copy Discord Invite Link'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8EA1E1),
                          side: const BorderSide(color: Color(0xFF5865F2)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleUri(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // In-Place Redeem Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'HAVE A BETA ACCESS KEY?',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. RNDBETA2026',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                letterSpacing: 0.5,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              prefixIcon: const Icon(Icons.key, color: Colors.purpleAccent, size: 18),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.purpleAccent.withValues(alpha: 0.4),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.purpleAccent.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.purpleAccent,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _submitCode(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Unlock',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoundedRectangleUri extends RoundedRectangleBorder {
  const RoundedRectangleUri({super.borderRadius});
}
