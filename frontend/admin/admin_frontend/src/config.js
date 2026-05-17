// API Configuration
const PROD_API_URL = 'https://germanbharatham-production.up.railway.app';
const DEV_API_URL = 'https://germanbharatham-production.up.railway.app';

const API_URL =
	process.env.REACT_APP_API_URL ||
	(process.env.NODE_ENV === 'production' ? PROD_API_URL : DEV_API_URL);

export default API_URL;
