/**
 * Login Form Submission Handler
 * This section sets up an event listener for the submission of the login form.
 * It captures user input for email and password, and then initiates the sign-in process using these credentials.
 *
 * Process Flow:
 * - The event listener is attached to the 'submit' event of the login form.
 * - When the form is submitted, the default action (page reload) is prevented to handle the submission asynchronously.
 * - The email and password entered by the user are retrieved from the form's input fields.
 * - The `signIn` function is called with the provided email and password, which handles the authentication process.
 *
 * Note: This setup ensures a seamless user experience by avoiding page reloads and providing immediate feedback through the `signIn` function's mechanisms.
 */

// Get form elements from the DOM using their IDs
const loginForm = document.getElementById('login-form');
// Get input elements from the form for email and password fields using their IDs
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');

// Listen for form submit
loginForm.addEventListener('submit', (e) => { // When the form is submitted by the user ...
  e.preventDefault(); // Prevent page reload
  const email = emailInput.value;
  const password = passwordInput.value;

  // Sign in with email and password
  signIn(email, password);
});
