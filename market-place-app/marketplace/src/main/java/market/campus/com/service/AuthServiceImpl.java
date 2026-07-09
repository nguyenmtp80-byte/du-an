package market.campus.com.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import market.campus.com.dto.*;
import market.campus.com.exception.BadRequestException;
import market.campus.com.model.User;
import market.campus.com.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import java.util.Set;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final GoogleTokenVerifier googleTokenVerifier;
    private final Map<String, String> tokenStore = new ConcurrentHashMap<>();

    public AuthServiceImpl(UserRepository userRepository,
                           PasswordEncoder passwordEncoder,
                           GoogleTokenVerifier googleTokenVerifier) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.googleTokenVerifier = googleTokenVerifier;
    }

    // ==================== REGISTER EMAIL OTP VERIFICATION ====================
    private final Map<String, RegisterOtpEntry> registerOtpStore = new ConcurrentHashMap<>();
    private final Set<String> verifiedEmails = ConcurrentHashMap.newKeySet();

    private static class RegisterOtpEntry {
        String otp;
        String fullName;
        String phone;
        String studentId;
        String password;
        String confirmPassword;
        LocalDateTime expiry;

        RegisterOtpEntry(String otp, String fullName, String phone, String studentId,
                         String password, String confirmPassword, LocalDateTime expiry) {
            this.otp = otp;
            this.fullName = fullName;
            this.phone = phone;
            this.studentId = studentId;
            this.password = password;
            this.confirmPassword = confirmPassword;
            this.expiry = expiry;
        }

        boolean isValid() {
            return LocalDateTime.now().isBefore(expiry);
        }
    }

    @Override
    public String sendRegisterOtp(SendOtpRequest request) {
        String email = request.getEmail();

        // Kiểm tra email hợp lệ
        if (email == null || email.isBlank()) {
            throw new BadRequestException("Email không được để trống");
        }

        email = email.trim().toLowerCase();

        // Tạo OTP 6 chữ số
        String otp = String.format("%06d", new Random().nextInt(999999));
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(5);

        // Xóa OTP cũ nếu có
        registerOtpStore.remove(email);

        // Lưu OTP tạm thời
        registerOtpStore.put(email, new RegisterOtpEntry(otp, null, null, null, null, null, expiry));

        System.out.println("==========================================");
        System.out.println("[REGISTER] OTP for " + email + ": " + otp);
        System.out.println("Expiry: " + expiry);
        System.out.println("==========================================");

        return "Mã OTP đã được gửi đến email " + email + " (sandbox: " + otp + ")";
    }

    @Override
    public String verifyRegisterOtp(VerifyRegisterOtpRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        String otp = request.getOtp().trim();

        // Kiểm tra OTP
        RegisterOtpEntry entry = registerOtpStore.get(email);
        if (entry == null) {
            throw new BadRequestException("Vui lòng yêu cầu OTP trước");
        }
        if (!entry.otp.equals(otp)) {
            throw new BadRequestException("OTP không chính xác");
        }
        if (!entry.isValid()) {
            registerOtpStore.remove(email);
            throw new BadRequestException("OTP đã hết hạn. Vui lòng yêu cầu lại");
        }

        // Đánh dấu email đã được xác thực
        verifiedEmails.add(email);
        registerOtpStore.remove(email);

        return "Email " + email + " đã được xác thực thành công";
    }

    @Override
    public AuthResponse register(RegisterRequest request) {
        String email = request.getEmail().trim().toLowerCase();

        // Kiểm tra email đã được xác thực OTP chưa
        if (!verifiedEmails.contains(email)) {
            throw new BadRequestException("Email chưa được xác thực. Vui lòng xác thực OTP trước");
        }

        if (userRepository.existsByEmail(email)) {
            throw new BadRequestException("Email đã được sử dụng");
        }

        if (request.getId() == null || request.getId().isBlank()) {
            throw new BadRequestException("UID của người dùng không được để trống");
        }

        // Check password vs confirmPassword
        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Mật khẩu xác nhận không khớp");
        }

        // Hash password before saving
        String hashedPassword = passwordEncoder.encode(request.getPassword());

        User user = new User(
                request.getId(),
                email,
                hashedPassword,
                request.getFullName(),
                request.getAvatarUrl(),
                request.getPhone(),
                request.getStudentId()
        );

        User savedUser = userRepository.save(user);
        // Xóa email khỏi danh sách đã xác thực
        verifiedEmails.remove(email);
        return buildAuthResponse(savedUser);
    }

    @Override
    public AuthResponse login(LoginRequest request) {
        Optional<User> optionalUser = userRepository.findById(request.getId());
        if (optionalUser.isEmpty()) {
            optionalUser = userRepository.findByEmail(request.getEmail());
        }

        User user = optionalUser.orElseThrow(() -> new BadRequestException("Người dùng không tồn tại"));

        // Check if user has password set
        if (user.getPassword() == null) {
            throw new BadRequestException("Tài khoản chưa có mật khẩu. Vui lòng đăng ký lại hoặc tạo mật khẩu");
        }

        // Check password
        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadRequestException("Mật khẩu không chính xác");
        }

        return buildAuthResponse(user);
    }

    @Override
    public AuthResponse googleLogin(GoogleLoginRequest request) {
        // Verify Google ID token
        GoogleIdToken.Payload payload = googleTokenVerifier.verify(request.getIdToken());

        // Extract user info from Google payload
        String googleId = payload.getSubject(); // Google's unique user ID (sub)
        String email = payload.getEmail();
        String fullName = (String) payload.get("name");
        String avatarUrl = (String) payload.get("picture");

        // Check if user already exists by Google ID or email
        Optional<User> existingUser = userRepository.findById(googleId);
        if (existingUser.isEmpty()) {
            existingUser = userRepository.findByEmail(email);
        }

        User user;
        if (existingUser.isPresent()) {
            user = existingUser.get();
            // Update info from Google if needed
            boolean updated = false;
            if (fullName != null && !fullName.equals(user.getFullName())) {
                user.setFullName(fullName);
                updated = true;
            }
            if (avatarUrl != null && !avatarUrl.equals(user.getAvatarUrl())) {
                user.setAvatarUrl(avatarUrl);
                updated = true;
            }
            // If user was found by email but has different ID, update the ID to Google ID
            if (!user.getId().equals(googleId)) {
                // We keep the existing ID to avoid FK issues, but update Google info
                // In practice, you'd want to handle this more carefully
            }
            if (updated) {
                userRepository.save(user);
            }
        } else {
            // Create new user from Google info
            user = new User(
                    googleId,
                    email,
                    null, // no password for Google users
                    fullName,
                    avatarUrl,
                    null, // phone
                    null  // studentId
            );
            user = userRepository.save(user);
        }

        return buildAuthResponse(user);
    }

    @Override
    public void logout(String token) {
        if (token != null) {
            tokenStore.remove(token);
        }
    }

    // ==================== FORGOT PASSWORD ====================
    // In-memory OTP store: key=email, value=otp
    private final Map<String, OtpEntry> otpStore = new ConcurrentHashMap<>();

    private static class OtpEntry {
        String otp;
        LocalDateTime expiry;

        OtpEntry(String otp, LocalDateTime expiry) {
            this.otp = otp;
            this.expiry = expiry;
        }

        boolean isValid() {
            return LocalDateTime.now().isBefore(expiry);
        }
    }

    @Override
    public String forgotPassword(ForgotPasswordRequest request) {
        // Kiểm tra email có tồn tại không
        Optional<User> userOpt = userRepository.findByEmail(request.getEmail());
        if (userOpt.isEmpty()) {
            throw new BadRequestException("Email không tồn tại trong hệ thống");
        }

        User user = userOpt.get();

        // Kiểm tra user có password không (Google user không có password)
        if (user.getPassword() == null) {
            throw new BadRequestException("Tài khoản Google không có mật khẩu. Vui lòng đăng nhập bằng Google");
        }

        // Tạo OTP 6 chữ số
        String otp = String.format("%06d", new Random().nextInt(999999));
        LocalDateTime expiry = LocalDateTime.now().plusMinutes(5); // OTP hết hạn sau 5 phút

        otpStore.put(request.getEmail(), new OtpEntry(otp, expiry));

        // Trong môi trường thực, gửi email/SMS chứa OTP
        // Vì sandbox, in ra console để test
        System.out.println("==========================================");
        System.out.println("OTP for " + request.getEmail() + ": " + otp);
        System.out.println("Expiry: " + expiry);
        System.out.println("==========================================");

        return "OTP đã được gửi đến email " + request.getEmail() + " (sandbox: " + otp + ")";
    }

    @Override
    public AuthResponse resetPassword(ResetPasswordRequest request) {
        // Kiểm tra mật khẩu xác nhận
        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new BadRequestException("Mật khẩu xác nhận không khớp");
        }

        // Kiểm tra email
        Optional<User> userOpt = userRepository.findByEmail(request.getEmail());
        if (userOpt.isEmpty()) {
            throw new BadRequestException("Email không tồn tại trong hệ thống");
        }

        // Kiểm tra OTP
        OtpEntry otpEntry = otpStore.get(request.getEmail());
        if (otpEntry == null) {
            throw new BadRequestException("Vui lòng yêu cầu OTP trước");
        }
        if (!otpEntry.otp.equals(request.getOtp())) {
            throw new BadRequestException("OTP không chính xác");
        }
        if (!otpEntry.isValid()) {
            otpStore.remove(request.getEmail());
            throw new BadRequestException("OTP đã hết hạn. Vui lòng yêu cầu lại");
        }

        // Cập nhật mật khẩu mới
        User user = userOpt.get();
        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        // Xóa OTP đã dùng
        otpStore.remove(request.getEmail());

        return buildAuthResponse(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String token = UUID.randomUUID().toString();
        tokenStore.put(token, user.getId());
        UserResponse userResponse = new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.getAvatarUrl(),
                user.getPhone(),
                user.getStudentId(),
                user.getCreatedAt()
        );
        return new AuthResponse(token, userResponse);
    }
}
