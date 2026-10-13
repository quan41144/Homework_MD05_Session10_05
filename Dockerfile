# ==========================================
# Giai đoạn 1: Build ứng dụng bằng Gradle Wrapper (gradlew)
# ==========================================
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app

# Copy các file cấu hình Gradle Wrapper trước để tận dụng cache
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle settings.gradle ./

# Cấp quyền thực thi cho script gradlew và tải trước dependencies
RUN chmod +x ./gradlew && ./gradlew dependencies --no-daemon || true

# Copy toàn bộ mã nguồn vào container
COPY src ./src

# Build ứng dụng Spring Boot tạo file jar (bỏ qua unit tests để tối ưu thời gian build)
RUN ./gradlew bootJar -x test --no-daemon

# ==========================================
# Giai đoạn 2: Runtime image tối ưu dung lượng (JRE)
# ==========================================
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Bảo mật: Chạy ứng dụng bằng non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Copy file .jar đã build từ stage builder
COPY --from=builder /app/build/libs/app.jar app.jar

# Port dịch vụ
EXPOSE 8080

# Health check định kỳ
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Khởi chạy ứng dụng Spring Boot
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "app.jar"]
