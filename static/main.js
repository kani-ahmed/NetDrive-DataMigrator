/**
 * Window Load and Log Fetching Setup
 * Upon window load, this script sets an interval to repeatedly fetch and update the log display in the UI.
 * The `fetchLogs` function is responsible for retrieving and displaying log data from the server.
 *
 * Process Flow:
 * - Once the window is fully loaded, `setInterval` is used to call `fetchLogs` every 500 milliseconds, continuously updating the log display.
 *
 * FetchLogs Function:
 * - Retrieves the 'id_token' stored in localStorage, which is used to authenticate the request to the server.
 * - Makes a fetch request to the '/get_logs' endpoint, including the 'id_token' in the Authorization header for secure access to the log data.
 * - Upon receiving a response, the text content of the response is set as the inner text of the element with the ID 'log', updating the displayed logs.
 *
 * Note: This continuous fetching mechanism ensures that the displayed logs are kept up-to-date with the latest server-side log data, providing real-time feedback to the user.
 */

// Set an interval to fetch logs every 500 milliseconds
window.onload = function() {
    setInterval(fetchLogs, 500); // Fetch logs every half second
}

// Fetch logs from the server and update the log display in the UI
function fetchLogs() {
    // Retrieve the ID token from localStorage
    var id_Token = localStorage.getItem('id_token');
    
    fetch('/get_logs', { // Send a GET request to the server endpoint '/get_logs' to fetch the logs
        headers: {
          'Authorization': id_Token // Include the ID token in the Authorization header of the request for server-side authentication and access control
        }
      })
      .then(response => response.text()) // Parse the response as text data and return a promise
      .then(data => { // When the promise is resolved with the text data ...
        document.getElementById('log').innerText = data; // Set the inner text of the element with the ID 'log' to the received log data
      });
  }
  