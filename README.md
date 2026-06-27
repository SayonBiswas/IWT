# IWT — Online Exam Management System

> A Java-based web application built as part of the Internet & Web Technology (IWT) Lab, implementing a full-featured online examination platform with role-based access for students and administrators — powered by **Google Gemini AI** for intelligent question generation.

---

## 📌 Features

### 👤 Authentication & User Management
- User **registration** and **login** with session management
- Secure **logout** functionality
- Role-based access control — separate views for **Admin** and **Student**

### 🎓 Student Features
- Take exams via an interactive **exam interface**
- View **exam history** with past attempts and scores
- See **results** immediately after submission
- Personal **dashboard** showing progress and activity

### 🛠️ Admin Features
- **Admin dashboard** for managing the platform
- **AI-powered question generation** using the Google Gemini API — automatically create relevant exam questions by providing a topic, difficulty level, and number of questions
- **Exam setup** — configure exam parameters (duration, marks, etc.)
- Monitor student activity and results

### 🤖 AI Integration — Google Gemini
- AI logic is encapsulated in **`AIUtils.java`** (`com.exam.util`), a dedicated utility class that handles all communication with the Google Gemini API
- The `generateQuestion.jsp` page calls `AIUtils.java` on the backend to fetch AI-generated questions
- Admins can input a **subject/topic**, type the **difficulty level** (Easy / Medium / Hard) along with the topic, and specify the **number of questions**
- Gemini returns structured multiple-choice questions which are parsed and stored in the database
- Keeps AI logic cleanly separated from the JSP presentation layer

### 🗄️ Database
- Centralized **database configuration** (`db_config.jsp`) for easy environment setup
- Persistent storage of users, questions, exam history, and results

---

## 🗂️ Project Structure

```
Project3/
├── src/
│   └── main/
│       ├── java/
│       │   └── com/
│       │       └── exam/
│       │           └── util/
│       │               └── AIUtils.java     # Gemini API integration utility
│       └── webapp/
│           ├── META-INF/
│           ├── WEB-INF/
│           ├── admin_dashboard.jsp          # Admin control panel
│           ├── dashboard.jsp                # Student dashboard
│           ├── db_config.jsp                # Database connection config
│           ├── exam.jsp                     # Exam-taking interface
│           ├── exam_history.jsp             # Past exam records
│           ├── generateQuestion.jsp         # AI-powered question generation (calls AIUtils)
│           ├── index.jsp                    # Landing page
│           ├── login.jsp                    # User login
│           ├── logout.jsp                   # Session termination
│           ├── navbar.jsp                   # Shared navigation bar
│           ├── register.jsp                 # New user registration
│           ├── result.jsp                   # Exam result display
│           ├── setup.jsp                    # Exam configuration
│           └── style.css                    # Global styles
├── Dockerfile                               # Container setup
└── pom.xml                                  # Maven dependencies
```

---

## 🛠️ Tech Stack

| Layer | Technology                                   |
|-------|----------------------------------------------|
| Language | Java                                         |
| Frontend | JSP, HTML, CSS                               |
| Build Tool | Maven                                        |
| Deployment | Docker, Java Servlet Container (e.g. Tomcat) |
| Database | PostgreSQL (configured via `db_config.jsp`)  |
| AI API | Google Gemini (via `AIUtils.java`)           |

---

## 🔑 Gemini API Setup

1. Get your API key from [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Add your key to `AIUtils.java` or set it as an environment variable:
   ```java
   private static final String API_KEY = System.getenv("GEMINI_API_KEY");
   ```
3. `AIUtils.java` sends prompts to the Gemini API endpoint:
   ```
   https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=YOUR_API_KEY
   ```
4. The response is parsed and questions are saved to the database for use in exams.

> ⚠️ **Never commit your API key to version control.** Use environment variables or a config file listed in `.gitignore`.

---

## 🚀 Getting Started

### Prerequisites

- Java JDK 21
- Apache Maven
- Apache Tomcat (or any servlet container)
- PostgreSQL
- Google Gemini API key
- Docker *(optional, for containerized deployment)*

### Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/SayonBiswas/IWT.git
   cd IWT/Project3
   ```

2. **Configure the database:**
   - Create a database in PostgreSQL
   - Update the credentials in `src/main/webapp/db_config.jsp`

3. **Set your Gemini API key** as an environment variable:
   ```bash
   export GEMINI_API_KEY=your_api_key_here
   ```

4. **Build the project:**
   ```bash
   mvn clean package
   ```

5. **Deploy to Tomcat:**
   - Copy the generated `.war` file from `target/` into your Tomcat `webapps/` directory
   - Start Tomcat and navigate to `http://localhost:8080/Project3`

### Docker Deployment *(alternative)*

```bash
docker build -t username/examhub:latest .
docker run -p 8080:8080 examhub
```

---

## 👤 Author

**Sayon Biswas**
- GitHub: [@SayonBiswas](https://github.com/SayonBiswas)

**Suranjeet Behera**
- GitHub: 
[@SuranjeetBehera](https://github.com/suran-jeet)

---

## 📄 License

This project was developed for academic purposes as part of the IWT Lab coursework.