import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../widgets/screen_header.dart';

const _supportEmail = 'hotro@studentmarketplace.vn';
const _supportPhone = '1900 6868';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã sao chép $label')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: Column(
        children: [
          const ScreenHeader(title: 'Trung tâm trợ giúp'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                const _IntroBanner(),
                const SizedBox(height: 20),
                const _HelpSection(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Khó khăn khi mua hàng',
                  steps: [
                    'Kiểm tra thông tin sản phẩm, giá, tình trạng và địa điểm giao dịch trước khi đặt hàng.',
                    'Ưu tiên gặp người bán tại khu vực công cộng trong campus hoặc điểm hẹn đã ghim trên bản đồ.',
                    'Nếu đơn hàng bị huỷ hoặc người bán không phản hồi, vào mục Đơn hàng mua để xem trạng thái và liên hệ qua Chat.',
                    'Chỉ thanh toán sau khi đã kiểm tra sản phẩm. Không chuyển khoản trước nếu chưa xác minh được người bán.',
                    'Nếu vẫn chưa giải quyết được, liên hệ bộ phận hỗ trợ kèm mã đơn hàng và ảnh chụp màn hình.',
                  ],
                ),
                const SizedBox(height: 12),
                const _HelpSection(
                  icon: Icons.storefront_outlined,
                  title: 'Khó khăn khi đăng tin bán',
                  steps: [
                    'Đảm bảo đã đăng nhập bằng email sinh viên và điền đầy đủ tên, mô tả, giá, số lượng còn lại.',
                    'Chọn đúng danh mục, tình trạng sản phẩm và ghim vị trí giao dịch để người mua dễ tìm.',
                    'Cập nhật số lượng hoặc ẩn tin nếu sản phẩm đã bán hết để tránh nhận đơn không cần thiết.',
                    'Theo dõi mục Đơn hàng đã bán để xác nhận, từ chối hoặc hoàn tất đơn kịp thời.',
                    'Nếu không đăng được tin hoặc ảnh không hiển thị, thử đăng lại hoặc liên hệ hỗ trợ qua email/SĐT bên dưới.',
                  ],
                ),
                const SizedBox(height: 12),
                const _HelpSection(
                  icon: Icons.report_gmailerrorred_outlined,
                  title: 'Nghi ngờ bị người bán lừa',
                  steps: [
                    'Ngừng giao dịch ngay nếu người bán yêu cầu chuyển khoản trước, đổi địa điểm giao dịch bất thường hoặc giục trả tiền gấp.',
                    'Lưu lại bằng chứng: tin nhắn Chat, thông tin sản phẩm, mã đơn hàng và ảnh chụp màn hình.',
                    'Huỷ đơn hàng (nếu còn ở trạng thái chờ xác nhận) và báo cáo qua Trung tâm trợ giúp.',
                    'Không tiếp tục chuyển tiền cho người bán nếu sản phẩm không đúng mô tả hoặc không giao hàng.',
                    'Gửi email/SĐT hỗ trợ kèm bằng chứng để được xem xét và hạn chế tài khoản vi phạm.',
                  ],
                ),
                const SizedBox(height: 20),
                _ContactSection(
                  onCopyEmail: () => _copyToClipboard(context, _supportEmail, 'email'),
                  onCopyPhone: () => _copyToClipboard(context, _supportPhone, 'số điện thoại'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroBanner extends StatelessWidget {
  const _IntroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent, color: AppColors.primary, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chúng tôi sẵn sàng hỗ trợ bạn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Tham khảo hướng dẫn bên dưới hoặc liên hệ trực tiếp nếu cần trợ giúp thêm.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.gray700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(steps.length, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.gray700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection({
    required this.onCopyEmail,
    required this.onCopyPhone,
  });

  final VoidCallback onCopyEmail;
  final VoidCallback onCopyPhone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_support_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Liên hệ hỗ trợ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Thời gian phản hồi: 8:00 – 17:00, thứ 2 – thứ 6',
              style: TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
            const SizedBox(height: 16),
            _ContactTile(
              icon: Icons.phone_outlined,
              label: 'Hotline',
              value: _supportPhone,
              onTap: onCopyPhone,
            ),
            const Divider(height: 24, color: AppColors.gray200),
            _ContactTile(
              icon: Icons.mail_outline,
              label: 'Email',
              value: _supportEmail,
              onTap: onCopyEmail,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chạm vào SĐT hoặc email để sao chép và liên hệ.',
              style: TextStyle(fontSize: 12, color: AppColors.gray500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.gray700, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy, size: 18, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
