package market.campus.com.service;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.EncodeHintType;
import com.google.zxing.WriterException;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Base64;
import java.util.Hashtable;

@Service
public class QrCodeService {

    @Value("${payment.bank.code:970422}")
    private String bankCode;

    @Value("${payment.bank.account:0987654321}")
    private String bankAccountNumber;

    @Value("${payment.bank.name:STUDENT MARKETPLACE}")
    private String bankAccountName;

    /**
     * Tạo nội dung QR theo chuẩn VietQR
     * Tham khảo: https://vietqr.io/
     * Mỗi QR có mã tham chiếu unique = orderId để hệ thống đối soát khi nhận được tiền
     */
    public String generateVietQrContent(String orderId, int amount) {
        // Mã tham chiếu: "MARKET-" + 8 ký tự đầu của orderId
        // Khi ngân hàng báo có giao dịch đến, hệ thống đối soát qua mã này
        String refCode = "MARKET-" + orderId.substring(0, Math.min(8, orderId.length()));
        String transferContent = "TT " + refCode;

        // Merchant Account Information block
        String merchantInfo = "0010A000000727" +           // GUID VietQR
                              "01" + padLength(bankCode) + bankCode +
                              "02" + padLength(bankAccountNumber) + bankAccountNumber;

        // Additional data: content
        String contentField = "08" + padLength(transferContent) + transferContent;
        String additionalData = "62" + padLength(contentField) + contentField;

        // Amount
        String amountStr = String.valueOf(amount);
        String amountField = "54" + padLength(amountStr) + amountStr;

        // Build QR payload
        StringBuilder qr = new StringBuilder();
        qr.append("000201");                                // Payload Format Indicator
        qr.append("010212");                                // Point of Initiation Method (11=static, 12=dynamic)
        qr.append("38" + padLength(merchantInfo) + merchantInfo); // Merchant Account Info
        qr.append("5303704");                               // Merchant Category Code
        qr.append("5802VN");                                // Country Code (VN)
        qr.append(amountField);                             // Transaction Amount
        qr.append(additionalData);                          // Additional Data
        qr.append("6304");                                  // CRC placeholder

        return qr.toString();
    }

    /**
     * Lấy mã tham chiếu từ orderId (dùng để đối soát khi nhận webhook)
     */
    public String getReferenceCode(String orderId) {
        return "MARKET-" + orderId.substring(0, Math.min(8, orderId.length()));
    }

    /**
     * Tạo QR code image dạng Base64 data URL
     */
    public String generateQrCodeBase64(String qrContent, int width, int height) {
        try {
            QRCodeWriter qrCodeWriter = new QRCodeWriter();
            Hashtable<EncodeHintType, Object> hints = new Hashtable<>();
            hints.put(EncodeHintType.CHARACTER_SET, "UTF-8");
            hints.put(EncodeHintType.MARGIN, 2);

            BitMatrix bitMatrix = qrCodeWriter.encode(qrContent, BarcodeFormat.QR_CODE, width, height, hints);
            BufferedImage bufferedImage = MatrixToImageWriter.toBufferedImage(bitMatrix);

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            ImageIO.write(bufferedImage, "PNG", baos);
            byte[] imageBytes = baos.toByteArray();

            return "data:image/png;base64," + Base64.getEncoder().encodeToString(imageBytes);
        } catch (WriterException | IOException e) {
            throw new RuntimeException("Lỗi tạo QR code: " + e.getMessage(), e);
        }
    }

    /**
     * Tạo nội dung QR đơn giản (dạng text) cho các app có thể scan
     */
    public String generateSimpleQrContent(String orderId, int amount) {
        String transferContent = "STUDENT-MARKET-" + orderId.substring(0, Math.min(8, orderId.length()));
        return bankAccountNumber + "|" + amount + "|" + transferContent;
    }

    private String padLength(String value) {
        return String.format("%02d", value.length());
    }

    public String getBankCode() { return bankCode; }
    public String getBankAccountNumber() { return bankAccountNumber; }
    public String getBankAccountName() { return bankAccountName; }
}