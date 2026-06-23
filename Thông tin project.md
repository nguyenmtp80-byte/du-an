App bán đồ sinh viên – Student Marketplace App

Members:
Lê Vũ Văn
Trương Lê Trí Nguyên
Trần Phương Nam

1. Design Database / API Structure
Chức năng này yêu cầu nhóm thiết kế cấu trúc dữ liệu hoặc API phục vụ toàn bộ ứng dụng mua bán đồ dành cho sinh viên. Ứng dụng có thể sử dụng Firebase Firestore, SQLite hoặc REST API backend.
Các dữ liệu chính cần có gồm:
Nhóm dữ liệu
Mô tả   
User / Student
Lưu thông tin tài khoản sinh viên: họ tên, email trường học, số điện thoại, avatar, địa chỉ, mật khẩu hoặc Firebase Auth
Product
Lưu thông tin sản phẩm sinh viên đăng bán: tên sản phẩm, giá, mô tả, hình ảnh, tình trạng sản phẩm, danh mục, trạng thái còn bán
Category
Lưu danh mục sản phẩm như sách, đồ điện tử, phụ kiện, quần áo, đồ học tập
Cart
Lưu các sản phẩm người dùng thêm vào giỏ hàng
Order
Lưu thông tin đơn hàng: người mua, sản phẩm, tổng tiền, trạng thái đơn hàng
Notification
Lưu thông báo khuyến mãi, xác nhận đơn hàng hoặc thông báo hệ thống
Campus Location
Lưu vị trí gặp mặt hoặc khu vực giao dịch trong trường
Message / Chat
Lưu nội dung trò chuyện giữa người mua và người bán

Nhóm cần trình bày rõ:
Sơ đồ database hoặc collection Firestore.
Quan hệ giữa các bảng/collection.
API endpoint nếu dùng REST API.
Cách CRUD dữ liệu.
Dữ liệu được sử dụng ở màn hình nào.

1.1.Mô hình ERD

2. Login Screen
Chức năng này cho phép sinh viên đăng nhập vào ứng dụng để sử dụng các chức năng cá nhân như đăng sản phẩm, nhắn tin, mua hàng và quản lý đơn hàng.
Mục đích
Đảm bảo chỉ người dùng đã có tài khoản mới có thể sử dụng các chức năng của ứng dụng.
Mô tả xử lý
Khi mở ứng dụng, nếu người dùng chưa đăng nhập thì hệ thống sẽ hiển thị màn hình Login.
Người dùng nhập:
Email hoặc số điện thoại.
Mật khẩu.
Ứng dụng kiểm tra:
Đã nhập đủ thông tin chưa.
Email đúng định dạng chưa.
Tài khoản có tồn tại không.
Mật khẩu có chính xác không.
Nếu hợp lệ:
Chuyển sang màn hình Home/Product List.
Nếu sai:
Hiển thị thông báo lỗi như:
“Email hoặc mật khẩu không đúng”.
Input
Email/số điện thoại.
Mật khẩu.
Output
Đăng nhập thành công.
Hoặc hiển thị lỗi.


Yêu cầu đánh giá
Có validate dữ liệu.
Có hiển thị lỗi.
Có lưu trạng thái đăng nhập.
Có giao diện rõ ràng.

3. Product List Screen
Chức năng này hiển thị danh sách sản phẩm sinh viên đang đăng bán.
Mục đích
Giúp người dùng tìm kiếm và xem các sản phẩm đang được bán trong cộng đồng sinh viên.
Mô tả xử lý
Ứng dụng lấy dữ liệu sản phẩm từ Firebase/API và hiển thị dạng danh sách hoặc grid view.
Mỗi sản phẩm gồm:
Hình ảnh sản phẩm.
Tên sản phẩm.
Giá bán.
Danh mục.
Tình trạng sản phẩm.
Người bán.
Người dùng có thể:
Cuộn để xem thêm.
Tìm kiếm theo tên.
Lọc theo danh mục.
Lọc theo khoảng giá.
Lọc theo trạng thái còn bán.
Khi chọn sản phẩm:
Chuyển sang màn hình Product Detail.
Input
Danh sách sản phẩm.
Từ khóa tìm kiếm.
Điều kiện lọc.
Output
Danh sách sản phẩm.
Kết quả tìm kiếm/lọc.
Điều hướng sang chi tiết sản phẩm.


Yêu cầu đánh giá
Hiển thị dữ liệu thật.
Có loading.
Có xử lý empty state.
Có search/filter.

4. Product Detail Screen
Chức năng này hiển thị thông tin chi tiết sản phẩm sinh viên đăng bán.
Mục đích
Giúp người dùng hiểu rõ sản phẩm trước khi mua hoặc liên hệ người bán.
Mô tả xử lý
Khi người dùng chọn sản phẩm, ứng dụng hiển thị:
Hình ảnh.
Tên sản phẩm.
Giá bán.
Mô tả.
Tình trạng sản phẩm:
Mới
Đã sử dụng
Thông tin người bán.
Thời gian đăng bài.
Trạng thái còn bán/hết hàng.
Người dùng có thể:
Add to Cart.
Nhắn tin người bán.
Lưu yêu thích.
Nếu sản phẩm đã bán:
Disable nút mua.
Input
ID sản phẩm.
Số lượng muốn mua.
Output
Hiển thị chi tiết.
Thêm vào giỏ hàng.
Hiển thị thông báo.

Yêu cầu đánh giá
Có đầy đủ thông tin.
Có xử lý còn hàng/hết hàng.
Có cập nhật giỏ hàng.

5. Shopping Cart Screen
Chức năng này cho phép người dùng quản lý các sản phẩm đã thêm vào giỏ hàng.
Mục đích
Giúp người dùng kiểm tra lại sản phẩm trước khi đặt hàng.
Mô tả xử lý
Màn hình giỏ hàng hiển thị:
Hình ảnh sản phẩm.
Tên sản phẩm.
Giá.
Số lượng.
Thành tiền.
Người dùng có thể:
Tăng/giảm số lượng.
Xóa sản phẩm.
Xem tổng tiền.
Chuyển sang Checkout.
Nếu giỏ hàng rỗng:
Hiển thị “Your cart is empty”.
Input
Danh sách sản phẩm trong cart.
Thao tác cập nhật số lượng.
Output
Giỏ hàng được cập nhật.
Tổng tiền thay đổi.
Chuyển sang Checkout.

Yêu cầu đánh giá
Có cập nhật realtime.
Có tính tổng tiền.
Có xử lý cart rỗng.

6. Checkout / Billing Screen
Chức năng này cho phép người dùng xác nhận đơn hàng.
Mục đích
Hoàn tất quá trình mua hàng.
Mô tả xử lý
Ứng dụng hiển thị:
Danh sách sản phẩm.
Tổng tiền.
Thông tin giao nhận.
Người dùng nhập:
Họ tên.
Số điện thoại.
Địa điểm gặp mặt/giao hàng.
Ghi chú.
Phương thức thanh toán:
Tiền mặt.
Chuyển khoản demo.
Sau khi Confirm Order:
Tạo đơn hàng.
Lưu database.
Xóa giỏ hàng.
Hiển thị thành công.
Input
Sản phẩm trong giỏ.
Thông tin nhận hàng.
Output
Đơn hàng mới.
Cart được xóa.
Thông báo thành công.

Yêu cầu đánh giá
Có validate thông tin.
Có tạo order.
Có cập nhật trạng thái đơn hàng.

7. Create Product Listing / Sell Product Screen
Chức năng này cho phép sinh viên đăng bài rao bán sản phẩm lên ứng dụng.
Mục đích
Giúp người dùng dễ dàng đăng bán các sản phẩm cá nhân như:
sách cũ
laptop
điện thoại
phụ kiện
quần áo
đồ học tập
để những sinh viên khác có thể xem và mua.

Mô tả xử lý
Khi người dùng mở chức năng “Sell Product” bằng cách click vào dấu cộng ở giữa, ứng dụng sẽ hiển thị form đăng bài bán sản phẩm.
Người dùng cần nhập:
Hình ảnh sản phẩm.
Tên sản phẩm.
Giá bán.
Danh mục sản phẩm.
Tình trạng sản phẩm.
Mô tả sản phẩm.
Địa điểm giao dịch.
Số điện thoại liên hệ.
Người dùng có thể:
Upload nhiều ảnh.
Chọn category.
Chọn tình trạng:
New
Like New
Used
Sau khi bấm “Post Product”:
Ứng dụng kiểm tra dữ liệu hợp lệ.
Upload ảnh lên Firebase Storage/API.
Lưu thông tin sản phẩm vào database.
Hiển thị thông báo đăng bài thành công.
Chuyển về màn hình danh sách sản phẩm.
Nếu dữ liệu thiếu:
Hiển thị lỗi tương ứng.

Input
Hình ảnh sản phẩm.
Tên sản phẩm.
Giá bán.
Mô tả.
Danh mục.
Thông tin liên hệ.

Output
Bài đăng sản phẩm mới được tạo.
Dữ liệu lưu vào database/API.
Hiển thị thông báo thành công hoặc lỗi.


Yêu cầu đánh giá
Có upload hình ảnh.
Có validate dữ liệu nhập.
Có lưu dữ liệu thật vào database/API.
Có hiển thị loading khi upload.
Có xử lý lỗi upload.
Có tạo sản phẩm mới thành công.
Có cập nhật danh sách sản phẩm sau khi đăng bài.
Có giao diện rõ ràng, dễ sử dụng.
8. Notifications Screen
Chức năng này hiển thị thông báo cho người dùng.
Mục đích
Giúp người dùng nhận thông tin mới.
Mô tả xử lý
Thông báo có thể gồm:
Đơn hàng đã xác nhận.
Có tin nhắn mới.
Khuyến mãi.
Sản phẩm mới.
Mỗi thông báo gồm:
Tiêu đề.
Nội dung.
Thời gian.
Trạng thái đã đọc/chưa đọc.
Người dùng có thể:
Xem chi tiết.
Đánh dấu đã đọc.
Input
Danh sách notification.
Output
Danh sách thông báo. 
Điều hướng liên quan.

Yêu cầu đánh giá
Có phân biệt read/unread.
Có xử lý không có dữ liệu.

9. Messaging / Chat Screen
Chức năng này cho phép người mua và người bán nhắn tin với nhau.
Mục đích
Hỗ trợ trao đổi nhanh về sản phẩm.
Mô tả xử lý
Người dùng có thể:
Gửi tin nhắn.
Xem lịch sử chat.
Nhận phản hồi.
Mỗi tin nhắn gồm:
Nội dung.
Người gửi.
Thời gian gửi.
Ví dụ:
“Sản phẩm còn không?”
“Có thể giảm giá không?”
“Hẹn giao ở thư viện nhé.”
Input
Nội dung tin nhắn.
Output
Tin nhắn hiển thị.
Tin nhắn lưu database.


Yêu cầu đánh giá
Có giao diện chat.
Có lịch sử chat.
Có phân biệt sender/receiver.

10. Apply State Management: Provider / Bloc
Chức năng này yêu cầu nhóm sử dụng state management để quản lý trạng thái ứng dụng.
Mục đích
Giúp ứng dụng:
ổn định
dễ bảo trì
dữ liệu đồng bộ giữa các màn hình.
Mô tả xử lý
Các state chính:
State
Mô tả
Authentication State
Quản lý login/logout
Product State
Danh sách sản phẩm
Cart State
Giỏ hàng
Order State
Đơn hàng
Notification State
Thông báo
Chat State
Tin nhắn

Ví dụ:
Khi Add to Cart:
CartProvider cập nhật dữ liệu.
Badge số lượng cart update ngay.
Input
User actions.
API/database data.
Output
UI cập nhật realtime.
Loading/error/success state.
Yêu cầu đánh giá
Có dùng Provider/Bloc rõ ràng.
Có tách logic khỏi UI.
Có cập nhật UI theo state.
 

Chạy BE: 
cd D:\Git_Push\du-an\market-place-app\marketplace
.\mvnw.cmd spring-boot:run

http://localhost:8080/swagger-ui.html

Chạy FE trên Chrome: 
cd D:\Git_Push\du-an\frontend
flutter run -d chrome --web-browser-flag=--disable-web-security --web-browser-flag=--user-data-dir=C:/temp/flutter_chrome_dev

Chạy FE trên android thật: 
cd D:\Git_Push\du-an\frontend
flutter run

-----Luồng xử lý bán - đăng bán -----

Account A (Seller)
↓
Đăng Macbook Air M2

Account B (Buyer)
↓
Tìm Macbook
↓
Xem chi tiết
↓
Chat (tuỳ chọn)
↓
Add To Cart
↓
Checkout

Account A
↓
My Orders
↓
Accept <xem chi tiết và tình trạng đơn hàng>

Account B
↓
Order Status = Approved <xác nhận đơn cho khách,cập nhật bằng tay thông qua notifications>

Account A
↓
Complete Order <tới địa điểm giao dịch nhận hàng>

Account B
↓
Order Status = Completed <cập nhật bằng tay cho từng đơn>

Sau đó account A có thể nhận được thông báo rằng đơn hàng của bạn đã được hoàn thành.