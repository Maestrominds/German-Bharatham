import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Eye, EyeOff } from 'lucide-react';
import API_URL from '../config';

const Login = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const response = await fetch(`${API_URL}/api/admin/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      const data = await response.json();

      if (!response.ok) {
        alert(data?.message || 'Login failed');
        return;
      }

      localStorage.setItem('adminToken', data.token);
      onLogin();
      navigate('/dashboard');
    } catch (error) {
      console.error('Login error:', error);
      alert('Unable to connect to server.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-sidebar">
        <div className="login-brand">
          <div className="brand-logo-wrap brand-logo-wrap--lg" aria-hidden="true">
            <img className="brand-logo" src="/app_logo.jpeg" alt="" />
          </div>
          <h1>German Bharatham</h1>
          <p>Admin Panel</p>
        </div>
      </div>

      <div className="login-form-container">
        <div className="login-form">
          <h2>Welcome</h2>
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <input
                type="email"
                placeholder="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="form-group password-group">
              <input
                type={showPassword ? 'text' : 'password'}
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? <Eye size={20} /> : <EyeOff size={20} />}
              </button>
            </div>
            <button type="submit" className="sign-in-btn" disabled={loading}>
              {loading ? 'Signing in...' : 'Sign In'}
            </button>
          </form>
          <p className="auth-notice">
            🔒 Authorized access only. This panel is restricted to platform administrators.
          </p>
        </div>
      </div>
    </div>
  );
};

export default Login;