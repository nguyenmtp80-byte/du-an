package market.campus.com.service;

import market.campus.com.dto.AuthResponse;
import market.campus.com.dto.LoginRequest;
import market.campus.com.dto.RegisterRequest;
<<<<<<< Updated upstream
=======
import market.campus.com.dto.ResetPasswordRequest;
import market.campus.com.dto.SendOtpRequest;
import market.campus.com.dto.VerifyRegisterOtpRequest;
>>>>>>> Stashed changes

public interface AuthService {

    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    void logout(String token);
<<<<<<< Updated upstream
=======

    String forgotPassword(ForgotPasswordRequest request);

    AuthResponse resetPassword(ResetPasswordRequest request);

    String sendRegisterOtp(SendOtpRequest request);

    String verifyRegisterOtp(VerifyRegisterOtpRequest request);
>>>>>>> Stashed changes
}
