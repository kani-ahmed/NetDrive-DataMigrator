// firebaseConfig
// Initialize Firebase
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY,
  authDomain: process.env.FIREBASE_AUTH_DOMAIN,
  projectId: process.env.FIREBASE_PROJECT_ID,
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
  appId: process.env.FIREBASE_APP_ID,
  measurementId: process.env.FIREBASE_MEASUREMENT_ID,
};
// Initialize Firebase
firebase.initializeApp(firebaseConfig);

/**
 * User Sign-In Function
 * This function handles user sign-in using Firebase Authentication with email and password.
 * Upon calling `signIn`, it attempts to authenticate the user with the provided credentials.
 *
 * Success Flow:
 * - If authentication is successful, a success message is displayed using toastr.
 * - The `checkAuth` function is called after a 2-second delay to allow the success message to be shown,
 *   which then handles post-authentication processes like redirecting to a secure page.
 *
 * Error Handling:
 * - In case of an authentication error (e.g., incorrect credentials), an error message is displayed,
 *   and no further action is taken (i.e., the user remains on the login page).
 *
 * Parameters:
 * - `email`: The user's email address.
 * - `password`: The user's password.
 *
 * Note: This function uses toastr for displaying success or error notifications to provide immediate feedback to the user.
 */
function signIn(email, password) {
  firebase.auth().signInWithEmailAndPassword(email, password)
    .then(function () {
      toastr.success('Signed in successfully');
      // Delay the checkAuth call by 2 seconds to allow the toastr to be shown
      setTimeout(function () {
        checkAuth(true);
      }, 2000);
    })
    .catch(function (error) {
      // Handle errors
      var errorCode = error.code;
      var errorMessage = error.message;
      toastr.error('Username or Password is incorrect');
    });
}

/**
 * User Sign-Out Function
 * This function manages the user sign-out process using Firebase Authentication.
 * It provides feedback to the user through visual notifications and ensures a smooth sign-out experience.
 *
 * Process Flow:
 * - Initiates with an informational toastr message indicating the sign-out process has begun.
 * - Executes the Firebase `signOut` method after a 2-second delay, allowing the initial toastr message to be visible to the user.
 *
 * Success Flow:
 * - Upon successful sign-out, a success message is displayed, and the `checkAuth` function is called to handle post-sign-out actions,
 *   such as redirecting the user to the login page or updating the UI to reflect the signed-out state.
 *
 * Error Handling:
 * - If an error occurs during the sign-out process, an error message is displayed to inform the user of the issue.
 *
 * Note: The 2-second delay before executing the sign-out function is intended to enhance user experience by providing visual feedback
 * before taking the action, ensuring the user is aware of the ongoing process.
 */
function signOut() {
  toastr.info('Signing out...');
  setTimeout(function () {
    firebase.auth().signOut().then(function () {
      // Sign-out successful.
      toastr.success('Signed out successfully');
      checkAuth(true);
    }).catch(function (error) {
      // An error happened.
      toastr.error('Error encountered while signing out');
    });
  }, 2000); // Delay the sign-out by 2 seconds
}

/**
 * Authentication State Check Function
 * This function monitors the authentication state of the user and takes appropriate actions based on that state.
 * It returns a promise that resolves or rejects based on whether the user is authenticated.
 *
 * Parameters:
 * - `redirect`: A boolean flag that determines whether to redirect unauthenticated users to the login page.
 *
 * Process Flow:
 * - Listens for changes in the authentication state using Firebase's `onAuthStateChanged` method.
 * - If the user is authenticated (`user` object is present), it removes the "hidden" class from the body element, making the UI visible.
 * - Additionally, for authenticated users, it retrieves the user's ID token and then calls `redirectToViewLogs` with the ID token,
 *   which may handle further navigation or actions requiring authentication.
 *
 * Handling Unauthenticated Users:
 * - If the user is not authenticated and `redirect` is `true`, it redirects the user to the login page after a brief delay,
 *   allowing for a smoother user experience. This delay can also be used to display a message or perform other brief actions before redirection.
 * - The function rejects the promise with a message indicating that the user is not signed in, which can be used for error handling or logging.
 *
 * Note: This function is typically called on page load or at specific points where checking the authentication state is crucial,
 * such as before accessing protected resources or pages.
 */
function checkAuth(redirect = false) {
  return new Promise(function (resolve, reject) { // Return a promise for handling the authentication state
    firebase.auth().onAuthStateChanged(function (user) { // Listen for changes in the authentication state
      if (!user && redirect) { // If the user is not signed in and redirection is enabled
        // User is not signed in, redirect to login page
        setTimeout(function () { // Delay the redirection by 2 seconds
          window.location.href = "login.html";
        }, 1500); // Delay the redirection by 2 seconds
        reject("User is not signed in");
      } else {
        // User is signed in, remove the "hidden" class from the body element
        document.body.classList.remove("hidden");

        // Get the ID token and redirect to view_logs page
        if (user) {
          user.getIdToken().then(function (idToken) {
            redirectToViewLogs(idToken); // Redirect to view_logs page with the ID token
            resolve(idToken); // Resolve the promise with the ID token
          });
        } else {
          reject("User is not signed in"); // Reject the promise with an error message
        }
      }
    });
  });
}

/**
 * Redirect to View Logs Page Function
 * This function is responsible for redirecting authenticated users to the view logs page,
 * carrying their ID token for server-side authentication.
 *
 * Process Flow:
 * - The function first stores the provided ID token in the browser's localStorage, which might be used for maintaining session state or for subsequent requests.
 * - It then dynamically creates a form element with a hidden input field containing the ID token.
 * - The form is configured to POST to the '/view_logs' endpoint on the server, which is designed to accept the ID token for authentication.
 *
 * Implementation Details:
 * - A hidden input field named 'id_token' is populated with the user's ID token and appended to the form.
 * - Upon form submission, the browser navigates to the '/view_logs' page, and the server-side logic then validates the ID token.
 *
 * Security Note:
 * - The use of localStorage for storing the ID token has implications for security, particularly concerning XSS attacks.
 * - An attacker might exploit XSS vulnerabilities to steal the ID token and impersonate the user.
 * I used this script on an isolated environment, so I didn't consider the security implications of using localStorage.
 *   Ensure that your application properly sanitizes user input to mitigate these risks.
 *
 * Parameters:
 * - `idToken`: The Firebase ID token obtained from the authenticated user, used for server-side authentication on the view logs page.
 */
function redirectToViewLogs(idToken) {
  // Store the ID token in localStorage
  localStorage.setItem('id_token', idToken);

  // Create a form element
  var form = document.createElement('form');
  form.method = 'POST';
  form.action = 'http://[your-ip-address]:[your-port-number]/view_logs';

  // Create a hidden input field with the ID token
  var idTokenInput = document.createElement('input');
  idTokenInput.type = 'hidden';
  idTokenInput.name = 'id_token';
  idTokenInput.value = idToken;

  // Append the input field to the form
  form.appendChild(idTokenInput);

  // Submit the form, so the Flask server can receive the token and authenticate the user
  document.body.appendChild(form);
  form.submit();
}