package market.campus.com.config;

import market.campus.com.model.Category;
import market.campus.com.repository.CategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private CategoryRepository categoryRepository;

    @Override
    public void run(String... args) {
        // Seed categories nếu bảng chưa có dữ liệu
        if (categoryRepository.count() == 0) {
            categoryRepository.save(new Category("Dịch vụ", "Các dịch vụ sinh viên"));
            categoryRepository.save(new Category("Sách giáo trình", "Sách giáo trình, tài liệu học tập"));
            categoryRepository.save(new Category("Điện tử", "Đồ điện tử, công nghệ"));
            categoryRepository.save(new Category("Đồ dùng", "Đồ dùng cá nhân, dụng cụ học tập"));
            System.out.println(">>> Seeded 4 categories: Dịch vụ, Sách giáo trình, Điện tử, Đồ dùng");
        }
    }
}