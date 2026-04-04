# German Bharatham - Community Platform

A comprehensive platform to help Indians settle in Germany, providing accommodation, food & grocery, jobs, services, and community resources.

## Project Structure

```
german_bharatham_admin/
├── backend/                      # Node.js/Express API server
│   ├── config/                   # Database configuration
│   ├── middleware/               # Auth middleware
│   ├── accommodationModule/      # Accommodation APIs
│   ├── foodGroceryModule/        # Food & Grocery APIs
│   ├── jobsModule/              # Jobs APIs
│   ├── servicesModule/          # Services APIs
│   ├── communityModule/         # Community guides APIs
│   ├── userModule/              # User authentication
│   └── server.js                # Main server file
├── frontend/
│   ├── admin/                   # React admin dashboard
│   │   └── admin_frontend/      # Admin panel (port 3000)
│   └── user/                    # Flutter mobile app
│       ├── lib/                 # Dart source files
│       ├── android/             # Android configuration
│       └── assets/              # Images and resources
└── README.md
```

## Prerequisites

- **Node.js** (v16 or higher)
- **npm** or **yarn**
- **Flutter SDK** (v3.0+) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **MongoDB Atlas** account (or local MongoDB)
- **Android Studio** (for Android development)
- **VS Code** (recommended) with Flutter & Dart extensions

## Setup Instructions

### 1. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Install dependencies
npm install

# Create .env file from example
cp .env.example .env

# Edit .env with your MongoDB credentials
# Required environment variables:
# - MONGO_URI: Your MongoDB connection string
# - JWT_SECRET: Secret key for JWT tokens
# - PORT: Server port (default: 5000)

# Start the backend server
node server.js
```

Backend URLs:
 - Render (production): `https://german-bharatham-backend.onrender.com`

### 2. Admin Frontend Setup

 - Flutter app default API base URL is the Render backend: `https://german-bharatham-backend.onrender.com`

```bash
# Navigate to admin frontend directory
cd frontend/admin/admin_frontend

# Install dependencies
npm install

# Start the development server
npm start
```

The admin panel will be available at `http://localhost:3000`

**Default Admin Credentials:**
- Email: `admin@german.com`
- Password: `admin@123`

### 3. Flutter Mobile App Setup

```bash
# Navigate to user app directory
cd frontend/user

# Get Flutter dependencies
flutter pub get

# Check connected devices
flutter devices

# Run on Android device/emulator
flutter run -d <device-id>

# Or simply run on the first available device
flutter run
```

**Important Configuration:**
- Update API base URL in Flutter app if needed (currently set to `https://german-bharatham-backend.onrender.com`)
- The app requires Material Icons - already configured in `pubspec.yaml`

## Features

### Admin Panel
- **Dashboard**: Overview of all listings and statistics
- **Food & Grocery Management**: CRUD operations for restaurants, cafes, and grocery stores
- **Accommodation Management**: Manage rental listings
- **User Management**: View and manage user accounts
- **Authentication**: Secure JWT-based authentication

### Mobile App
- **Home**: Browse all categories (Accommodation, Food, Jobs, Services, Community)
- **Search**: Search across all listings
- **Saved**: Bookmark favorite listings
- **Profile**: User profile management and settings
- **Food & Grocery**: Browse restaurants, cafes, and grocery stores with filters
- **Accommodation**: Find rental properties
- **Share & Bookmark**: Share listings and save favorites
- **Authentication**: User registration and login

## API Endpoints

### Public Endpoints
- `POST /api/user/register` - User registration
- `POST /api/user/login` - User login
- `GET /api/user/foodgrocery` - Get all food & grocery listings
- `GET /api/accommodation/user` - Get all accommodations

### Admin Endpoints (Requires JWT Token)
- `POST /api/admin/login` - Admin login
- `GET /api/admin/foodgrocery` - Get all food & grocery listings
- `POST /api/admin/foodgrocery` - Create new listing
- `PUT /api/admin/foodgrocery/:id` - Update listing
- `DELETE /api/admin/foodgrocery/:id` - Delete listing

## Environment Variables

### Backend (.env)
```bash
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/database_name
MONGO_URI_FALLBACK=mongodb://localhost:27017/german_bharatham
JWT_SECRET=your_jwt_secret_key_here
PORT=5000
```

**Important**: Never commit the `.env` file to version control!

## MongoDB Collections

- `users` - User accounts
- `admins` - Admin accounts
- `foodgroceries` - Food & Grocery listings
- `accommodations` - Rental listings
- `jobs` - Job postings
- `services` - Service providers
- `guides` - Community guides and resources

## Development Tips

### Backend
- Use `node server.js` to start the server
- API base URL (Render): `https://german-bharatham-backend.onrender.com`
- All admin routes require Bearer token authentication
- CORS should include your deployed admin domain (Render): `https://german-bharatham-admin-2rhc.onrender.com`

### Admin Frontend
- Built with React and Lucide icons
- Uses localStorage for admin token persistence
- Logout clears the token and redirects to login

### Flutter App
- Uses Material Icons (ensure `uses-material-design: true` in pubspec.yaml)
- User session persists using SharedPreferences
- Bookmarks are saved per user
- Hot reload enabled for fast development

## Deployment

### Backend
1. Set environment variables on your hosting platform
2. Update CORS origins in `server.js` to include your frontend domain
3. Deploy to platforms like Heroku, AWS, or DigitalOcean

### Admin Frontend
1. Build production version: `npm run build`
2. Deploy the `build` folder to hosting platforms like Vercel, Netlify, or AWS S3

### Flutter App
1. Build for Android: `flutter build apk`
2. Build for iOS: `flutter build ios`
3. Submit to Google Play Store / Apple App Store

## Troubleshooting

### Backend Issues
- **Port already in use**: Change PORT in .env or kill the process using that port
- **MongoDB connection failed**: Check MONGO_URI in .env
- **Unauthorized errors**: Verify JWT_SECRET matches across all requests

### Flutter Issues
- **Icons showing as boxes**: Ensure `uses-material-design: true` in pubspec.yaml
- **API connection failed**: Update IP address in API base URL
- **Build errors**: Run `flutter clean` then `flutter pub get`

### Admin Frontend Issues
- **API errors**: Ensure backend is running on port 5000
- **Login issues**: Check browser console for errors and verify credentials

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is private and proprietary.

## Support

For issues or questions, please contact the development team.

If you aren't satisfied with the build tool and configuration choices, you can `eject` at any time. This command will remove the single build dependency from your project.

Instead, it will copy all the configuration files and the transitive dependencies (webpack, Babel, ESLint, etc) right into your project so you have full control over them. All of the commands except `eject` will still work, but they will point to the copied scripts so you can tweak them. At this point you're on your own.

You don't have to ever use `eject`. The curated feature set is suitable for small and middle deployments, and you shouldn't feel obligated to use this feature. However we understand that this tool wouldn't be useful if you couldn't customize it when you are ready for it.

## Learn More

You can learn more in the [Create React App documentation](https://facebook.github.io/create-react-app/docs/getting-started).

To learn React, check out the [React documentation](https://reactjs.org/).

### Code Splitting

This section has moved here: [https://facebook.github.io/create-react-app/docs/code-splitting](https://facebook.github.io/create-react-app/docs/code-splitting)

### Analyzing the Bundle Size

This section has moved here: [https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size](https://facebook.github.io/create-react-app/docs/analyzing-the-bundle-size)

### Making a Progressive Web App

This section has moved here: [https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app](https://facebook.github.io/create-react-app/docs/making-a-progressive-web-app)

### Advanced Configuration

This section has moved here: [https://facebook.github.io/create-react-app/docs/advanced-configuration](https://facebook.github.io/create-react-app/docs/advanced-configuration)

### Deployment

This section has moved here: [https://facebook.github.io/create-react-app/docs/deployment](https://facebook.github.io/create-react-app/docs/deployment)

### `npm run build` fails to minify

This section has moved here: [https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify](https://facebook.github.io/create-react-app/docs/troubleshooting#npm-run-build-fails-to-minify)
