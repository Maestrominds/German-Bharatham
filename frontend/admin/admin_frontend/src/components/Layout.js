import React from 'react';
import { NavLink } from 'react-router-dom';
import { 
  LayoutDashboard, 
  FileText, 
  FolderOpen, 
  Users, 
  Shield, 
  MessageCircle, 
  CreditCard,
  Settings, 
  LogOut
} from 'lucide-react';

const Layout = ({ children, onLogout }) => {
  const menuItems = [
    { path: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
    { path: '/listings', icon: FileText, label: 'Listings' },
    { path: '/categories', icon: FolderOpen, label: 'Categories' },
    { path: '/users', icon: Users, label: 'Users' },
    { path: '/content-moderation', icon: Shield, label: 'Content Moderation' },
    { path: '/community', icon: MessageCircle, label: 'Community' },
    { path: '/subscriptions', icon: CreditCard, label: 'Subscriptions' },
    { path: '/settings', icon: Settings, label: 'Settings' },
  ];

  return (
    <div className="admin-layout">
      <div className="sidebar">
        <div className="sidebar-header">
          <div className="brand-row">
            <div className="brand-logo-wrap brand-logo-wrap--sm" aria-hidden="true">
              <img className="brand-logo" src="/app_logo.jpeg" alt="" />
            </div>
            <h1>German Bharatham</h1>
          </div>
        </div>
        
        <nav className="sidebar-nav">
          {menuItems.map((item) => (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) => 
                `nav-link ${isActive ? 'active' : ''}`
              }
            >
              <item.icon size={20} />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>
        
        <div className="sidebar-footer">
          <button className="logout-btn" onClick={onLogout}>
            <LogOut size={20} />
            <span>Log out</span>
          </button>
        </div>
      </div>
      
      <div className="main-content">
        {children}
      </div>
    </div>
  );
};

export default Layout;
