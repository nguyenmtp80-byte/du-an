package market.campus.com.service;

import market.campus.com.dto.AuthResponse;
import market.campus.com.dto.ForgotPasswordRequest;
import market.campus.com.dto.GoogleLoginRequest;
import market.campus.com.dto.LoginRequest;
import market.campus.com.dto.RegisterRequest;
import market.campus.com.dto.ResetPasswordRequest;

public interface AuthService {

    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    AuthResponse googleLogin(GoogleLoginRequest request);

    void logout(String token);

    String forgotPassword(ForgotPasswordRequest request);

    AuthResponse resetPassword(ResetPasswordRequest request);
}
