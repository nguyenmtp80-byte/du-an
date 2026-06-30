package market.campus.com.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
@CrossOrigin(origins = "*", maxAge = 3600)
public class UploadController {

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    /**
     * POST /api/upload/images - Upload nhiều ảnh sản phẩm
     * Trả về danh sách URL có thể truy cập được
     */
    @PostMapping("/images")
    public ResponseEntity<?> uploadImages(@RequestParam("files") List<MultipartFile> files) {
        try {
            if (files == null || files.isEmpty()) {
                return ResponseEntity.badRequest().body(
                        Map.of("message", "Không có file nào được chọn")
                );
            }

            // Tạo thư mục theo ngày để dễ quản lý: uploads/images/YYYY-MM-DD/
            String dateFolder = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
            Path targetDir = Paths.get(uploadDir, "images", dateFolder);
            Files.createDirectories(targetDir);

            List<String> uploadedUrls = new ArrayList<>();

            for (MultipartFile file : files) {
                // Validate file type
                String contentType = file.getContentType();
                if (contentType == null || !contentType.startsWith("image/")) {
                    continue;
                }

                // Validate file size (max 5MB)
                if (file.getSize() > 5 * 1024 * 1024) {
                    continue;
                }

                // Tạo tên file duy nhất
                String originalName = file.getOriginalFilename();
                String extension = "";
                if (originalName != null && originalName.contains(".")) {
                    extension = originalName.substring(originalName.lastIndexOf("."));
                }
                String uniqueName = UUID.randomUUID().toString() + extension;

                // Lưu file
                Path filePath = targetDir.resolve(uniqueName);
                Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

                // Tạo URL có thể truy cập
                String fileUrl = "/uploads/images/" + dateFolder + "/" + uniqueName;
                uploadedUrls.add(fileUrl);
            }

            if (uploadedUrls.isEmpty()) {
                return ResponseEntity.badRequest().body(
                        Map.of("message", "Không có ảnh hợp lệ nào được upload")
                );
            }

            return ResponseEntity.ok(Map.of("urls", uploadedUrls));
        } catch (IOException e) {
            return ResponseEntity.internalServerError().body(
                    Map.of("message", "Lỗi khi upload ảnh: " + e.getMessage())
            );
        }
    }
}