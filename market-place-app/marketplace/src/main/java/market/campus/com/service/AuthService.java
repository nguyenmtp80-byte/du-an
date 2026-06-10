package market.campus.com.service;

import market.campus.com.dto.AuthResponse;
import market.campus.com.dto.LoginRequest;
import market.campus.com.dto.RegisterRequest;

public interface AuthService {

    AuthResponse register(RegisterRequest request);

    AuthResponse login(LoginRequest request);

    void logout(String token);
}
