package market.campus.com.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;

/**
 * Service xác thực Google ID token.
 * Hỗ trợ sandbox mode để test trên Postman mà không cần token thật.
 */
@Service
public class GoogleTokenVerifier {

    private final GoogleIdTokenVerifier verifier;
    private final boolean sandboxEnabled;

    public GoogleTokenVerifier(@Value("${google.client.id}") String googleClientId,
                               @Value("${google.login.sandbox:true}") boolean sandboxEnabled) {
        this.sandboxEnabled = sandboxEnabled;
        // Nếu là sandbox, dùng client ID giả để tránh crash
        String clientId = sandboxEnabled ? "sandbox-client-id.apps.googleusercontent.com" : googleClientId;
        this.verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
                .setAudience(Collections.singletonList(clientId))
                .build();
    }

    /**
     * Xác thực ID token từ Google.
     * Nếu sandbox mode bật, chấp nhận token có prefix "sandbox_" hoặc "test_"
     * và trả về payload giả để test.
     */
    public GoogleIdToken.Payload verify(String idToken) {
        // Sandbox mode: cho phép test với token giả
        if (sandboxEnabled) {
            return verifySandbox(idToken);
        }

        // Production mode: verify thật với Google API
        try {
            GoogleIdToken token = verifier.verify(idToken);
            if (token == null) {
                throw new IllegalArgumentException("Google ID token không hợp lệ hoặc đã hết hạn");
            }
            return token.getPayload();
        } catch (GeneralSecurityException | IOException e) {
            throw new IllegalArgumentException("Lỗi xác thực Google token: " + e.getMessage(), e);
        }
    }

    /**
     * Sandbox verify: tạo payload giả từ token string.
     * Token format: sandbox_{id}_{email}_{name}
     * Ví dụ: sandbox_user123_test@gmail.com_NguyenVanA
     */
    private GoogleIdToken.Payload verifySandbox(String idToken) {
        GoogleIdToken.Payload payload = new GoogleIdToken.Payload();

        if (idToken == null || idToken.isBlank()) {
            throw new IllegalArgumentException("Token không được để trống");
        }

        // Parse token theo format: sandbox_{id}_{email}_{name}
        String[] parts = idToken.split("_", 4);
        
        if (parts.length >= 1 && parts[0].equals("sandbox")) {
            // sandbox_googleId123_email_name
            String googleId = parts.length >= 2 ? parts[1] : "sandbox-user-" + System.currentTimeMillis();
            String email = parts.length >= 3 ? parts[2] : googleId + "@gmail.com";
            String name = parts.length >= 4 ? parts[3] : "Sandbox User";

            payload.setSubject(googleId);
            payload.setEmail(email);
            payload.set("name", name);
            payload.set("picture", "https://ui-avatars.com/api/?name=" + name + "&background=random");
        } else {
            // Default sandbox user
            payload.setSubject("sandbox-" + System.currentTimeMillis());
            payload.setEmail("sandbox@student-marketplace.com");
            payload.set("name", "Sandbox User");
            payload.set("picture", "https://ui-avatars.com/api/?name=Sandbox+User&background=random");
        }

        return payload;
    }
}
