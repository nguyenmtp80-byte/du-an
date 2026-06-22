package market.campus.com.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI marketplaceOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("Campus Marketplace API")
                        .description("API documentation cho Student Marketplace")
                        .version("1.0.0"))
                .servers(List.of(
                        new Server().url("http://localhost:8080").description("Local")
                ));
    }
}
