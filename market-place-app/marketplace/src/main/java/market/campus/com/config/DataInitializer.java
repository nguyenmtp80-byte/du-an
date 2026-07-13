package market.campus.com.config;

import market.campus.com.model.Category;
import market.campus.com.repository.CategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private CategoryRepository categoryRepository;

    @Override
    public void run(String... args) {
        // Xoá các danh mục cũ (BOOKS, ELECTRICS, FASHION, HOME)
        List<String> oldCategories = List.of("BOOKS", "ELECTRICS", "FASHION", "HOME");
        for (String oldName : oldCategories) {
            categoryRepository.findByName(oldName).ifPresent(category -> {
                categoryRepository.delete(category);
                System.out.println(">>> Deleted old category: " + oldName);
            });
        }

        // Seed 4 categories mới nếu chưa có
        if (categoryRepository.findByName("Dịch vụ").isEmpty()) {
            categoryRepository.save(new Category("Dịch vụ", "Các dịch vụ sinh viên"));
        }
        if (categoryRepository.findByName("Sách giáo trình").isEmpty()) {
            categoryRepository.save(new Category("Sách giáo trình", "Sách giáo trình, tài liệu học tập"));
        }
        if (categoryRepository.findByName("Điện tử").isEmpty()) {
            categoryRepository.save(new Category("Điện tử", "Đồ điện tử, công nghệ"));
        }
        if (categoryRepository.findByName("Đồ dùng").isEmpty()) {
            categoryRepository.save(new Category("Đồ dùng", "Đồ dùng cá nhân, dụng cụ học tập"));
        }
        System.out.println(">>> Seeded 4 categories: Dịch vụ, Sách giáo trình, Điện tử, Đồ dùng");
    }
}