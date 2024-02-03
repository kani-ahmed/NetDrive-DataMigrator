### Hi there 👋, I'm Kani. Welcome!!! You have lots to explore

---
#### Welcome to NetDrive-DataMigrator
---

**Overview:**

NetDrive-DataMigrator is a comprehensive tool designed for efficient and secure migration of data from physical storage to network drives. It integrates real-time logging, user authentication, and a web interface for ease of use. This project aims to streamline data management tasks, enhance accessibility, and improve infrastructure optimization.

**Key Features:**

- **Automated Data Migration:** Simplifies the transfer of files, ensuring minimal manual intervention and reduced risk of errors.
- **Real-Time Logging:** Monitors and records the migration process, providing valuable insights and transparency.
- **Secure User Authentication:** Leverages Firebase Authentication to ensure that only authorized users can initiate or manage migrations.
- **User-Friendly Web Interface:** Allows for easy monitoring and control of the migration process through a simple and intuitive dashboard.

**Technologies Used:**

- **Backend:** Python with Flask for a lightweight and efficient server-side application.
- **Authentication:** Firebase Authentication for secure and scalable user management.
- **Frontend:** JavaScript. Could be extended with frameworks like React or Angular for enhanced interactivity.
- **Database:** You can extend to Firebase or other SQL/NoSQL databases for storing logs and user data.
- **Tools:** Git for version control, and GitHub Actions for CI/CD pipelines.

**Skills and Tools:**
*Python, Flask, Firebase Authentication, Git, PowerShell, Microsoft System Center Configuration Manager (SCCM).

The Flask backend serves RESTful API endpoints to interact with the frontend (if applicable) and handles all the logic for data migration, user authentication, and logging.

---
## API Documentation
---

This section outlines the RESTful API endpoints provided by NetDrive-DataMigrator. These endpoints facilitate the management and monitoring of data migrations.

#### Base URL

All API calls should be made to:

http://yourdomain.com/[API] where API is the actual name of the endpoint. 


Replace `http://yourdomain.com` with your actual domain name or use `http://localhost/` for local development.

#### Authentication

Most endpoints require an authenticated user. Include the following header in your requests:
`Authorization: Bearer <Your_Firebase_Token>`


#### Endpoints

---

### Log Event

- **URL:** `/log`
- **Method:** `POST`
- **Description:** Logs an event message. Expects a JSON payload with a 'message' field.
- **Authentication Required:** Yes (`Authorization: Bearer <Your_Firebase_Token>`)
- **Body:**
  ```json
  {
    "message": "Your log message here"
  }
  ```
- **Success Response:**
  - **Code:** 200 OK
  - **Content:** 
    ```json
    [
      "message": "Log entry added successfully"
    ]
    ```
- **Error Response:**
  - **Code:** `400 Bad Request` if the JSON payload is missing or the 'message' field is not present.
  - **Code:** `500 Internal Server Error` if there's an issue writing to the log file.


**Sample cURL Command:**
```bash
curl -X POST "http://yourdomain.com/api/log" \
     -H "Authorization: Bearer <Your_Firebase_Token>" \
     -H "Content-Type: application/json" \
     -d '{"message": "Your log message here"}'
```
---
### Get Logs

- **URL:** `/get_logs`
- **Method:** `GET`
- **Description:** Retrieves the content of the log file.
- **Authentication Required:** Yes (`Authorization: Bearer <Your_Authentication_Token>`)

- ** Success Response:**
  - **Code:** 200 OK
  - **Content:** The content of the log file as a plain text response.

- ** Error Response:**

  - **Code:** 404 Not Found if the log file is not found or inaccessible.
    - **Content:** Error message describing the issue.

**Sample cURL Command:**
  ```bash
  curl -X GET "http://yourdomain.com/api/get_logs" \
      -H "Authorization: Bearer <Your_Authentication_Token>"
  ```
---
### View Logs

- **URL:** `/view_logs`
- **Methods:** `GET`, `POST`
- **Description:** Renders a web page for viewing logs.
- **Authentication Required:** Yes (`Authorization: Bearer <Your_Authentication_Token>`)

- **Request Methods:**
  - `GET`: Displays the log viewer page.
  - `POST`: Performs an action related to log viewing (not specified in this code snippet).

**Sample cURL Command:**
 ```bash
curl -X GET "http://yourdomain.com/api/view_logs" \
     -H "Authorization: Bearer <Your_Authentication_Token>"
 ```
---
### Login Page

- **URL:** `/login.html`
- **Method:** `GET`
- **Description:** Renders a web page for user login.
- **Authentication Required:** No

- **Request Method:**
  - `GET`: Displays the login page.

**Sample cURL Command:**
  ```bash
  curl -X GET "http://yourdomain.com/api/login.html"
  ```
---

### Authenticate User

- **URL:** `/login`
- **Method:** `POST`
- **Description:** Authenticates a user using an ID token and stores it in the session.
- **Authentication Required:** No

- **Request:**
  - **Form Data:** 
    - `id_token` (required): The ID token for user authentication.

  - **Success Response:**
    - **Code:** 200 OK
  - **Content:** 
    ```json
    {
    "status": "success"
    }
    ```
- **Error Responses:**
  - **Code:** 400 Bad Request if the `id_token` is missing in the form data.
  - **Content:**
    ```json
    {
      "error": "ID token is required"
    }
    ```
  - **Code:** 401 Unauthorized for the following cases:
    - Invalid ID token provided.
    - ID token has expired.
    - Other cases of unauthorized access.

  - **Code:** 500 Internal Server Error for exceptions during ID token verification.

#### Sample cURL Command
  ```bash
  curl -X POST "http://yourdomain.com/api/login" \
      -d "id_token=<Your_ID_Token>"
  ```
---
### Logout User

- **URL:** `/logout`
- **Method:** `POST`
- **Description:** Logs the user out by clearing all data in the session, including the 'id_token.'
- **Authentication Required:** No

- **Success Response:**
  - **Code:** 200 OK
  - **Content:** 
    ```json
      {
        "status": "success"
      }
    ```
