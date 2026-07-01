import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/payment_qr.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/payment_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/screen_header.dart';

class PaymentQrScreen extends StatefulWidget {
  const PaymentQrScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
  });

  final String orderId;
  final double totalAmount;

  @override
  State<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends State<PaymentQrScreen> {
  final _paymentApiService = PaymentApiService();

  PaymentQr? _paymentQr;
  PaymentInfo? _paymentInfo;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _paymentFinished = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPaymentData());
  }

  Future<void> _loadPaymentData() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _error = 'Vui lòng đăng nhập để thanh toán.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _paymentApiService.getPaymentQr(
          userId: userId,
          orderId: widget.orderId,
        ),
        _paymentApiService.getPaymentInfo(
          userId: userId,
          orderId: widget.orderId,
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _paymentQr = results[0] as PaymentQr;
        _paymentInfo = results[1] as PaymentInfo;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Không thể tải mã QR thanh toán.';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmPayment() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _paymentApiService.confirmQrPayment(
        userId: userId,
        orderId: widget.orderId,
      );

      if (!mounted) {
        return;
      }

      await _showSuccessAndExit(
        title: 'Thanh toán QR thành công!',
        message: 'Đơn hàng đã được xác nhận thanh toán. Người bán sẽ chuẩn bị hàng.',
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage('Không thể xác nhận thanh toán. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _cancelPayment() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy thanh toán'),
        content: const Text(
          'Bạn có chắc muốn hủy thanh toán QR? Đơn hàng sẽ bị huỷ và số lượng sản phẩm được hoàn lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Hủy thanh toán'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) {
      return;
    }

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _paymentApiService.cancelQrPayment(
        userId: userId,
        orderId: widget.orderId,
      );

      if (!mounted) {
        return;
      }

      await _showSuccessAndExit(
        title: 'Đã hủy thanh toán',
        message: 'Đơn hàng đã được huỷ và số lượng sản phẩm đã được hoàn lại.',
        isSuccess: false,
      );
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showMessage('Không thể hủy thanh toán. Vui lòng thử lại.');
      }
    }
  }

  Future<void> _showSuccessAndExit({
    required String title,
    required String message,
    bool isSuccess = true,
  }) async {
    _paymentFinished = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.info_outline,
              size: 48,
              color: isSuccess ? const Color(0xFF16A34A) : AppColors.gray500,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray500, height: 1.5),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<bool> _handleExitAttempt() async {
    if (_paymentFinished || _isSubmitting) {
      return true;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát thanh toán QR?'),
        content: const Text(
          'Đơn hàng vẫn đang chờ thanh toán. Bạn có thể thanh toán sau trong mục Đơn hàng mua, hoặc hủy đơn để hoàn lại số lượng sản phẩm.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('stay'),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('later'),
            child: const Text('Thanh toán sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (action == 'stay' || action == null) {
      return false;
    }

    if (action == 'later') {
      return true;
    }

    if (action == 'cancel') {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId == null || userId.isEmpty) {
        return true;
      }

      setState(() => _isSubmitting = true);

      try {
        await _paymentApiService.cancelQrPayment(
          userId: userId,
          orderId: widget.orderId,
        );
        _paymentFinished = true;
        if (mounted) {
          _showMessage('Đã hủy đơn và hoàn lại số lượng sản phẩm.');
        }
        return true;
      } on ApiException catch (error) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showMessage(error.message);
        }
        return false;
      } catch (_) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showMessage('Không thể hủy đơn hàng. Vui lòng thử lại.');
        }
        return false;
      }
    }

    return false;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _copyText(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showMessage('Đã sao chép $label');
  }

  Uint8List? _decodeQrImage(String qrDataUrl) {
    if (qrDataUrl.isEmpty) {
      return null;
    }

    try {
      final base64Data = qrDataUrl.contains(',')
          ? qrDataUrl.split(',').last
          : qrDataUrl;
      return base64Decode(base64Data);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _paymentFinished,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        final shouldPop = await _handleExitAttempt();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.gray50,
        body: Column(
          children: [
            ScreenHeader(
              title: 'Thanh toán QR VNPay',
              onBack: () async {
                final shouldPop = await _handleExitAttempt();
                if (shouldPop && mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: _loadPaymentData)
                      : _buildContent(),
            ),
          ],
        ),
        bottomNavigationBar: _paymentQr == null || _isLoading || _error != null
            ? null
            : _buildBottomActions(),
      ),
    );
  }

  Widget _buildContent() {
    final paymentQr = _paymentQr!;
    final qrBytes = _decodeQrImage(paymentQr.qrDataUrl);
    final amount = paymentQr.amount > 0
        ? paymentQr.amount.toDouble()
        : widget.totalAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Quét mã bằng app ngân hàng / VNPay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (qrBytes != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Image.memory(
                      qrBytes,
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Container(
                    width: 240,
                    height: 240,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: const Text(
                      'Không tải được mã QR',
                      style: TextStyle(color: AppColors.gray500),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  formatPrice(amount),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã đơn: ${widget.orderId}',
                  style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: 'Thông tin chuyển khoản',
            rows: [
              _InfoRow(
                label: 'Ngân hàng',
                value: paymentQr.bankCode,
                onCopy: () => _copyText(paymentQr.bankCode, 'mã ngân hàng'),
              ),
              _InfoRow(
                label: 'Số tài khoản',
                value: paymentQr.bankAccountNumber,
                onCopy: () =>
                    _copyText(paymentQr.bankAccountNumber, 'số tài khoản'),
              ),
              _InfoRow(
                label: 'Chủ tài khoản',
                value: paymentQr.bankAccountName,
              ),
              _InfoRow(
                label: 'Nội dung CK',
                value: paymentQr.content,
                onCopy: () => _copyText(paymentQr.content, 'nội dung'),
              ),
            ],
          ),
          if (_paymentInfo?.instructions.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primarySoft),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _paymentInfo!.instructions,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.gray700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.gray200.withValues(alpha: 0.8))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _confirmPayment,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Tôi đã thanh toán',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSubmitting ? null : _cancelPayment,
            child: const Text(
              'Hủy thanh toán',
              style: TextStyle(color: AppColors.gray500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray700),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy, size: 18, color: AppColors.gray400),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
