package market.campus.com.service;

import market.campus.com.dto.AuthResponse;
import market.campus.com.dto.LoginRequest;
import market.campus.com.dto.RegisterRequest;
import market.campus.com.dto.UserResponse;
import market.campus.com.exception.BadRequestException;
import market.campus.com.model.User;
import market.campus.com.repository.UserRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Optional;
<<<<<<< Updated upstream
=======
import java.util.Random;
import java.util.Set;
>>>>>>> Stashed changes
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final Map<String, String> tokenStore = new ConcurrentHashMap<>();

    public AuthServiceImpl(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
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
    public void logout(String token) {
        if (token != null) {
            tokenStore.remove(token);
        }
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