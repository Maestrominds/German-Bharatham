import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import Listings from './components/Listings';
import Categories from './components/Categories';
import AccommodationListings from './components/AccommodationListings';
import FoodListings from './components/FoodListings';
import JobsListings from './components/JobsListings';
import ServicesListings from './components/ServicesListings';
import Users from './components/Users';
import CustomCategoryListings from './components/CustomCategoryListings';
import ContentModeration from './components/ContentModeration';
import Community from './components/Community';
import Settings from './components/Settings';
import Subscriptions from './components/Subscriptions';
import ReportedProblems from './components/ReportedProblems';
import Layout from './components/Layout';
import './App.css';

function App() {
  // Explicit login required; do not auto-authenticate on app start.
  // We rely on the presence of `adminToken` in localStorage for protected routes.
  const handleLogin = () => {};
  const handleLogout = () => {
    localStorage.removeItem('adminToken');
    window.history.replaceState({}, '', '/login');
    window.location.reload();
  };

  return (
    <Router>
      <Routes>
        <Route path="/" element={<Navigate to="/login" replace />} />
        <Route path="/login" element={<Login onLogin={handleLogin} />} />

        {/* Protected routes rendered inside Layout so sidebar/header appear only when authenticated */}
        <Route path="/*" element={<ProtectedLayout onLogout={handleLogout} />} />
      </Routes>
    </Router>
  );
}

function ProtectedLayout({ onLogout }) {
  return (
    <Layout onLogout={onLogout}>
      <Routes>
        <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
        <Route path="/listings" element={<ProtectedRoute><Listings /></ProtectedRoute>} />
        <Route path="/job-listings" element={<ProtectedRoute><JobsListings /></ProtectedRoute>} />
        <Route path="/categories" element={<ProtectedRoute><Categories /></ProtectedRoute>} />
        <Route path="/accommodation-listings" element={<ProtectedRoute><AccommodationListings /></ProtectedRoute>} />
        <Route path="/food-listings" element={<ProtectedRoute><FoodListings /></ProtectedRoute>} />
        <Route path="/jobs-listings" element={<ProtectedRoute><JobsListings /></ProtectedRoute>} />
        <Route path="/services-listings" element={<ProtectedRoute><ServicesListings /></ProtectedRoute>} />
        <Route path="/custom-category/:id" element={<ProtectedRoute><CustomCategoryListings /></ProtectedRoute>} />
        <Route path="/users" element={<ProtectedRoute><Users /></ProtectedRoute>} />
        <Route path="/content-moderation" element={<ProtectedRoute><ContentModeration /></ProtectedRoute>} />
        <Route path="/community" element={<ProtectedRoute><Community /></ProtectedRoute>} />
        <Route path="/subscriptions" element={<ProtectedRoute><Subscriptions /></ProtectedRoute>} />
        <Route path="/settings" element={<ProtectedRoute><Settings /></ProtectedRoute>} />
        <Route path="/reported-problems" element={<ProtectedRoute><ReportedProblems /></ProtectedRoute>} />
      </Routes>
    </Layout>
  );
}

function ProtectedRoute({ children }) {
  const token = typeof window !== 'undefined' ? localStorage.getItem('adminToken') : null;
  if (!token) return <Navigate to="/login" replace />;
  return children;
}

export default App;
