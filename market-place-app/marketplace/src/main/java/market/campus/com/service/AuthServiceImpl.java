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

    @Override
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
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
                request.getEmail(),
                hashedPassword,
                request.getFullName(),
                request.getAvatarUrl(),
                request.getPhone(),
                request.getStudentId()
        );

        User savedUser = userRepository.save(user);
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