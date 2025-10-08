# MQTT Flutter ↔ ESP32

## English README

### Overview

This Flutter project demonstrates how to establish a **two-way communication** between a Flutter application and an **ESP32** board using the **MQTT protocol**. The app connects to an MQTT broker, sends messages to the ESP32, and receives messages back in real-time.

### Features

* MQTT connection using `mqtt_client` package
* Automatic reconnect and exponential backoff
* Real-time message sending and receiving
* Multilingual support (Persian and English)
* Clickable links and logos
* Integration with `.env` for server credentials and settings

### Requirements

* Flutter SDK installed
* MQTT broker (e.g., Mosquitto or EMQX)
* ESP32 configured as an MQTT client
* A `.env` file containing:

  ```env
  SERVER_URL=your_mqtt_broker_url
  PORT=1883
  USER=username
  PASS=password
  ```

### How to Run

1. Clone the repository.
2. Create a `.env` file in the root directory with your MQTT credentials.
3. Run the Flutter app:

   ```bash
   flutter pub get
   flutter run
   ```
4. Make sure your ESP32 is connected to the same MQTT broker.

### Folder Structure

```
/lib
  └── main.dart        # Main Flutter application
.env                    # Environment configuration
```

### Author & Credits

* **Author:** Mahdi Bahram
  Instagram: [@mahdi1bahram](https://www.instagram.com/mahdi1bahram/)

* **Developed by:** Shahtut Electronics Inventors
  Website: [shahtut.com](https://shahtut.com)

* **Commissioned by:** Bahram Kit Co.
  Store: [bahramkit.com](https://www.bahramkit.com)
  Instagram: [@bahramkit](https://www.instagram.com/bahramkit/)
  Tutorial : [Tutorial](https://www.bahramkit.com/%d8%ae%d8%a7%d9%86%d9%87-%d9%87%d9%88%d8%b4%d9%85%d9%86%d8%af-4-2-%d8%a7%d8%b1%d8%b3%d8%a7%d9%84-%d9%88-%d8%af%d8%b1%db%8c%d8%a7%d9%81%d8%aa-%d8%a7%d8%b7%d9%84%d8%a7%d8%b9%d8%a7%d8%aa-%d8%a7%d8%b2/)

---

## فایل README فارسی

### معرفی

این پروژه فلاتر برای برقراری ارتباط **دوطرفه بین اپلیکیشن Flutter و ماژول ESP32 از طریق پروتکل MQTT** طراحی شده است. این برنامه قادر است به سرور MQTT متصل شود، پیام‌هایی به ESP32 ارسال کند و پیام‌های دریافتی را به‌صورت زنده نمایش دهد.

### ویژگی‌ها

* اتصال به سرور MQTT با استفاده از پکیج `mqtt_client`
* قابلیت **اتصال مجدد خودکار** با تاخیر افزایشی (exponential backoff)
* ارسال و دریافت پیام‌ها به صورت لحظه‌ای
* پشتیبانی از دو زبان فارسی و انگلیسی
* لینک‌ها و لوگوهای قابل کلیک
* استفاده از فایل `.env` برای تنظیمات و اطلاعات سرور

### پیش‌نیازها

* نصب Flutter SDK
* وجود یک سرور MQTT (مانند Mosquitto یا EMQX)
* تنظیم ESP32 به عنوان کلاینت MQTT
* ایجاد فایل `.env` در پوشه اصلی پروژه با محتوای زیر:

  ```env
  SERVER_URL=آدرس_سرور_شما
  PORT=1883
  USER=نام_کاربری
  PASS=رمز_عبور
  ```

### نحوه اجرا

1. پروژه را Clone کنید.
2. فایل `.env` را ایجاد و اطلاعات سرور خود را وارد کنید.
3. دستورات زیر را اجرا کنید:

   ```bash
   flutter pub get
   flutter run
   ```
4. اطمینان حاصل کنید که ESP32 به همان سرور MQTT متصل باشد.

### ساختار پروژه

```
/lib
  └── main.dart        # فایل اصلی برنامه فلاتر
.env                    # فایل تنظیمات محیطی
```

### نویسنده و پشتیبانی

* **نویسنده:** مهدی بهرام
  [اینستاگرام](https://www.instagram.com/mahdi1bahram/)

* **طراحی و توسعه توسط:** تیم مخترعین شاتوت الکترونیک
  [وب‌سایت](https://shahtut.com)

* **سفارش داده شده توسط:** شرکت بهرام کیت
  [فروشگاه](https://www.bahramkit.com)
  [اینستاگرام](https://www.instagram.com/bahramkit/)
    [آموزش پروژه](https://www.bahramkit.com/%d8%ae%d8%a7%d9%86%d9%87-%d9%87%d9%88%d8%b4%d9%85%d9%86%d8%af-4-2-%d8%a7%d8%b1%d8%b3%d8%a7%d9%84-%d9%88-%d8%af%d8%b1%db%8c%d8%a7%d9%81%d8%aa-%d8%a7%d8%b7%d9%84%d8%a7%d8%b9%d8%a7%d8%aa-%d8%a7%d8%b2/)

---

📎 [shahtut.com](https://shahtut.com)
