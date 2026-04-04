// API Configuration
const PROD_API_URL = 'https://german-bharatham-backend.onrender.com';
// Default dev URL points to localhost to avoid hitting production during development.
const DEV_API_URL = 'http://localhost:5000';

const API_URL =
	process.env.REACT_APP_API_URL ||
	(process.env.NODE_ENV === 'production' ? PROD_API_URL : DEV_API_URL);

export default API_URL;
