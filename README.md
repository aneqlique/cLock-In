# cLock-In
<p align="center">
  <img src="https://github.com/aneqlique/cLock-In/blob/main/ClockIn.png" alt="ClockIn Preview" width="400"/>
</p>

Inspired by Love Next Door’s “unemployed clock,” this app turns your daily routine or itineraries into an interactive visual schedule. Part clock, part agenda, part diary! Seamlessly track your work hours, manage daily tasks, and visualize productivity — all in one cross-platform app.
 

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.8.1-blue?logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-Enabled-blue?logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Node.js-Express-success?logo=node.js&logoColor=white" />
  <img src="https://img.shields.io/badge/MongoDB-Atlas-green?logo=mongodb&logoColor=white" />
  <img src="https://img.shields.io/badge/License-ISC-lightgrey" />
</p>

---

##  Features

 **Core Functionalities**
-  **User Authentication** – Secure login & registration with JWT  
-  **Time Tracking** – Clock in/out with precise timestamps  
-  **Task Management** – Create, update, and organize daily tasks
-  **Post Timeline** – Users can create a timeline of posts with photos stored via Cloudinary  
-  **Profile Management** – Upload and manage profile pictures (Cloudinary)  
-  **Data Visualization** – Real-time charts and productivity insights  
-  **Secure Storage** – Local data encryption using `flutter_secure_storage`  

---

## Tech Stack

<details>
<summary><b> Frontend (Flutter App)</b></summary>

- **Flutter** ^3.8.1 — Cross-platform UI framework  
- **Dart** — Programming language  
- **Provider** ^6.1.2 — State management  
- **Dio** ^5.4.3+1 — HTTP client  
- **Hive** ^2.2.3 — Local offline database  
- **FL Chart** ^1.1.0 — Data visualization  
- **Image Picker** ^1.1.0 — Camera/gallery access  
- **Cloudinary Flutter** ^1.3.0 — Cloud image storage  
</details>

<details>
<summary><b> Backend (API Server)</b></summary>

- **Node.js** — JavaScript runtime  
- **Express.js** ^5.1.0 — Web framework  
- **MongoDB** (via Mongoose ^8.19.2) — NoSQL database  
- **JWT** ^9.0.2 — Token-based authentication  
- **bcryptjs** ^3.0.2 — Password hashing  
- **Multer** ^2.0.2 — File upload middleware  
- **Cloudinary** ^1.41.3 — Image storage  
- **dotenv** ^17.2.3 — Environment variable management  
</details>





