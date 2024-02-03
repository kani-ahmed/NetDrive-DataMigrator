from flask import Flask, request, render_template, send_from_directory, jsonify, request, abort, session, redirect
import json
import os
from flask_cors import CORS
import subprocess
import firebase_admin
from firebase_admin import auth
import base64
#from flask_wtf import CSRFProtect
#from flask_wtf.csrf import CSRFError
from werkzeug.utils import secure_filename


# Initialize the Firebase Admin SDK
cred = firebase_admin.credentials.Certificate(r'your-path-to-service-account-key.json file')
#pass the service account key to the initialize_app method
firebase_admin.initialize_app(cred)

# Initialize the Flask app
app = Flask(__name__)

#csrf = CSRFProtect(app)

# Generate a secure secret key
secret_key = os.urandom(24) # Generate a random 24-byte secret key using os.urandom method

# Convert the secret key to a string
secret_key_str = base64.b64encode(secret_key).decode('utf-8')

# Set the secret key in your Flask app
app.secret_key = secret_key_str

# Configure session type to be filesystem-based (instead of in-memory) for production use cases (optional)
#I am setting this to filesystem-based for the purpose of this tutorial but you can use other session types like Redis, Memcached, etc.
#fine for smaller applications. may not be as scalable or performant as these in-memory stores
app.config['SESSION_TYPE'] = 'filesystem'
"""
-Enable CORS for all routes on the app, which means that the server will accept requests from any origin.
-This is useful when the server is accessed by multiple clients or from different origins.

-For production use cases, you can specify the origins that are allowed to access the server.
-For example, you can use the origins parameter to specify a list of allowed origins.
-Like: app.config['CORS_ORIGINS'] = ['https://example.com', 'https://sub.example.com'], which means that the server will only accept requests from https://example.com and https://sub.example.com.
-Therefore, if user requests are coming from any other origin, the server will return a 403 Forbidden response.
-This prevents unauthorized access to the server from unknown origins.
"""
CORS(app)

"""
-This decorator function `authenticate_request` ensures that only authenticated users can access certain routes.
-It checks for an ID token in the request's Authorization header or form field, verifying it with Firebase Admin SDK.
-On successful verification, the wrapped route function is executed; otherwise, it redirects to the login page.
-This approach accommodates both direct client requests and API tools like (Postman, cURL, etc).
"""
def authenticate_request(func):
    #The authenticate_request function is a decorator that wraps the route function to authenticate the user.
    def authenticate_wrapper(*args, **kwargs):
        # Get the ID token from the request header
        id_token = request.headers.get('Authorization')
        if id_token: #If the ID token is found in the request header, it verifies the token using the Firebase Admin SDK.
            try:
                # Verify the ID token using the Firebase Admin SDK
                decoded_token = auth.verify_id_token(id_token)
                # Check if the user is signed in
                if not decoded_token: #If the user is not signed in, it returns a 401 Unauthorized response.
                    abort(401, 'Invalid ID token')
                    return redirect('/login.html') # and redirects to the login page
            except Exception as e: #If an error occurs during ID token verification, it returns a 401 Unauthorized response.
                abort(401, 'Failed to verify ID token: {}'.format(e))
                return redirect('/login.html') # and redirects to the login page
        else: #If the ID token is not found in the request header, it checks the request form field.
            # Get the ID token from the request form field
            id_token = request.form.get('id_token')
            if id_token: #If the ID token is found in the request form field, it verifies the token using the Firebase Admin SDK.
                try:
                    # Verify the ID token
                    decoded_token = auth.verify_id_token(id_token)
                    # Check if the user is signed in
                    if not decoded_token: #If the user is not signed in, it returns a 401 Unauthorized response.
                        abort(401, 'Invalid ID token')
                        return redirect('/login.html') # and redirects to the login page
                except Exception as e: #If an error occurs during ID token verification, it returns a 401 Unauthorized response.
                    abort(401, 'Failed to verify ID token: {}'.format(e))
                    return redirect('/login.html') # and redirects to the login page
            else:
                # User is not signed in, redirect to login page
                return redirect('/login.html')

        return func(*args, **kwargs) #If the ID token is successfully verified, the wrapped route function is executed.

    return authenticate_wrapper


@app.errorhandler(404)
#helper function that handles 404 errors by redirecting to the login page
def page_not_found(error):
    # Redirect to the login page for non-existent pages
    return redirect('/login.html')

"""
-The log_event route function logs an event message to a log.txt file.
-It expects a JSON payload with a 'message' field.
-If the log.txt file does not exist, it will be created.
"""
@app.route('/log', methods=['POST'], endpoint='log_event')
def log_event():
    # Attempt to parse the JSON payload from the request
    data = request.get_json(silent=True)
    if not data or 'message' not in data:
        # Return an error if the JSON payload is missing or the 'message' field is not present
        return jsonify({'error': 'Invalid request. A JSON payload with a "message" field is required.'}), 400

    # Construct the log message with a timestamp for better traceability
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_message = f"[{timestamp}] - {data['message']}\n"

    # Define the log file path, using an environment variable for the log directory or defaulting to the current directory
    log_dir = os.getenv('LOG_DIRECTORY', default='.')
    log_file_path = os.path.join(log_dir, 'log.txt')

    try:
        # Write the log message to the file, creating the file if it doesn't exist
        with open(log_file_path, 'a') as f:
            f.write(log_message)
    except IOError as e:
        # Return an error response if there's an issue writing to the log file
        # The 500 status code indicates a server error
        return jsonify({'error': f'Failed to write to log file: {str(e)}'}), 500

    # Confirm successful logging
    # The 200 status code indicates a successful request
    return jsonify({'message': 'Log entry added successfully'}), 200

"""
Fetch and return the content of the log file.
- The function locates the log file using a configurable path, defaulting to the current directory.
- It attempts to read and return the entire content of the log file as a plain text response.
- In case of an error (e.g., file not found), it returns a 404 error with a descriptive message.
- This approach is straightforward but may not be efficient for very large log files.
- In production, consider streaming the log file content in chunks to avoid memory issues.
- Consider adding more advanced logging features, including log rotation, log levels, and structured logging.
"""
@app.route('/get_logs', methods=['GET'], endpoint='get_logs')
@authenticate_request
def get_logs():
    # Define the log file path, using an environment variable or a default value
    log_file_path = os.path.join(os.getenv('LOG_DIRECTORY', default='.'), 'log.txt')

    try:
        # Open and read the log file content
        with open(log_file_path, 'r') as f:
            log_content = f.read()
            return log_content  # Return the log content directly in the response body
    except IOError as e:
        # If there's an error (e.g., file not found), return a 404 error
        abort(404, description=f"Log file not found or inaccessible: {str(e)}")

"""
-Endpoint to display the log viewer page (GET and POST)
-This route handler serves the 'log.html' template, which provides a user interface for viewing log entries.
-It supports both GET and POST requests to accommodate different interaction patterns (e.g., refreshing the page or submitting a form).
-Access to this endpoint is secured with the @authenticate_request decorator, ensuring only authenticated users can view the log page.
-The actual log data displayed is fetched separately, typically through AJAX calls to the '/get_logs' endpoint from within the 'log.html'.
-This separation of concerns allows the log viewer to be a single-page application (SPA) that fetches log data asynchronously.
"""
@app.route('/view_logs', methods=['GET', 'POST'])
@authenticate_request
def view_log():
    return render_template('log.html') # Render the 'log.html' template for the log viewer page

"""
-Login Page Route (GET)
-This route serves the login page to the user. It's accessible via a GET request to '/login.html'.
-The function simply renders and returns the 'login.html' template, presenting the login interface to the user.
-This is typically the entry point for users to authenticate themselves before accessing protected areas of the application.
"""
@app.route('/login.html', methods=['GET'])
def login():
    return render_template('login.html')

"""
User Authentication Route (Login)
This route handles user authentication via a POST request to '/login'. It expects an 'id_token' in the request form data.
- The function retrieves the 'id_token' from the form data and attempts to verify it using Firebase's authentication mechanism.
- It first checks for the presence of 'id_token'. If absent, it immediately responds with a 401 Unauthorized status, indicating a missing token.
- If verification is successful, the token is stored in the session to maintain user authentication state, and a success status is returned as JSON.
- If the token is invalid, missing, or if an error occurs during verification, the function aborts the request with a 401 Unauthorized status, indicating authentication failure.
This endpoint is crucial for securing access to the application, ensuring that only authenticated users can proceed to protected routes.
"""
@app.route('/login', methods=['POST'])
def authenticate_user():
    id_token = request.form.get('id_token')
    if not id_token:
        return jsonify({'error': 'ID token is required'}), 400  # Bad Request for missing ID token

    try:
        # Verify the ID token and obtain the corresponding decoded token
        decoded_token = firebase_auth.verify_id_token(id_token)
        if decoded_token:
            # Store the ID token in the session to maintain user state
            session['id_token'] = id_token
            return jsonify({'status': 'success'})

    except firebase_auth.InvalidIdTokenError:
        abort(401, description='Invalid ID token provided.')  # Unauthorized for invalid ID token
    except firebase_auth.ExpiredIdTokenError:
        abort(401, description='ID token has expired.')  # Unauthorized for expired ID token
    except Exception as e:
        # Log the exception details for debugging purposes
        print(f"Error during ID token verification: {e}")
        abort(500, description='Internal server error during ID token verification.')  # Internal Server Error for other exceptions

    # Fallback abort, in case decoded_token is somehow None without raising exceptions
    abort(401, description='Unauthorized access denied.')  # Unauthorized for other cases

"""
User Logout Route
This route facilitates user logout through a POST request to '/logout'. It's designed to clear the user's session, effectively logging them out.
- Upon calling this route, the function clears all session data, including the stored 'id_token', ensuring the user is fully signed out.
- After successfully clearing the session, the function returns a JSON response with a success status, indicating a successful logout.
This endpoint is essential for maintaining secure user sessions, allowing users to confidently terminate their sessions when done.
"""
@app.route('/logout', methods=['POST'])
def logout():
    session.clear()  # Clear all data in the session, including the 'id_token'
    return jsonify({'status': 'success'})  # Indicate successful logout in the response


"""
Referrer Check Decorator
This decorator function `check_referrer` is designed to enhance security by verifying the HTTP referrer header of incoming requests.
- It wraps around route handler functions to check if the request's referrer matches the application's host URL.
- If the referrer is present and does not match the host URL, the request is aborted with a 403 Forbidden status, indicating a potential Cross-Site Request Forgery (CSRF) or other referrer-based attack.
- This check is particularly useful for routes that perform sensitive operations or modifications, adding an extra layer of security by ensuring requests originate from the same site.
"""
def check_referrer(func):
    def check_referrer_wrapper(*args, **kwargs):
        # Get the referrer from the request header
        referrer = request.referrer
        # Get the host URL from the request
        host = request.host_url.rstrip('/')
        # Check if the referrer is present and matches the host URL
        if referrer and not referrer.startswith(host):
            abort(403, 'Forbidden')  # Abort the request if the referrer does not match the host
        return func(*args, **kwargs)  # Proceed with the original function if the referrer is valid

    return check_referrer_wrapper # Return the wrapped function with referrer check

"""
Static File Serving Route
This route securely serves static files from a 'static' directory within the 'kani scripts' folder, ensuring access only to authenticated users.
- Validates the file path to prevent directory traversal attacks.
- Uses Flask's `send_from_directory` for secure file serving, with added error handling for non-existent or inaccessible files.
- Enhances application security by serving project-specific static assets behind user authentication.
"""
@app.route('/static/<path:path>', endpoint='get_route')
@authenticate_request
def send_js(path):
    # Safely join the specified path with the static directory path
    static_dir_path = os.path.join(current_app.root_path, 'directory-name', 'static')
    safe_path = os.path.join(static_dir_path, path)

    # Check if the path is safe and the file exists
    if os.path.commonprefix([safe_path, static_dir_path]) != static_dir_path or not os.path.exists(safe_path):
        abort(404, "File not found") # Return a 404 Not Found error if the path is not safe or the file does not exist

    return send_from_directory(static_dir_path, path) # Return the file from the static directory

if __name__ == "__main__":
    app.run(debug=False, host='your-host-ip', port='your-port-number')
