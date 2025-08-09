# Kanizsa User Management Service

**Version:** 1.1.0  
**Last Updated:** August 9, 2025, 12:05:18 CDT  
**Purpose:** User Management & Authentication Platform for Kanizsa Ecosystem

## 🎯 **Overview**

The Kanizsa User Management Service provides comprehensive user management, authentication, and authorization capabilities for the Kanizsa ecosystem. This service handles user registration, authentication, profile management, and access control across all Kanizsa services.

## 🏗️ **Architecture**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User          │    │   User          │    │   Profile &     │
│   Interface     │───▶│   Management    │───▶│   Preferences   │
│                 │    │   Service       │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │   Authentication│
                       │   & Authorization│
                       └─────────────────┘
```

## 🚀 **Quick Start**

### Prerequisites
- Docker and Docker Compose
- PostgreSQL database
- Redis for session management
- SMTP server for notifications

### Containerized Setup
```bash
# Clone the repository
git clone https://github.com/wcervin/kanizsa-users.git
cd kanizsa-users

# Copy environment variables
cp env.example .env

# Configure SMTP and database settings
# Edit .env with your credentials

# Start the user management stack
docker-compose up -d

# Access services
# User API: http://localhost:8000
# PostgreSQL: localhost:5432
# Redis: localhost:6379
```

## 🔧 **User Management Services**

### **User API**
- **Purpose:** Core user management functionality
- **Port:** 8000
- **Features:**
  - User registration
  - Authentication
  - Profile management
  - Account settings

### **Authentication Service**
- **Purpose:** JWT-based authentication
- **Features:**
  - Token generation
  - Token validation
  - Session management
  - Password hashing

### **Authorization Service**
- **Purpose:** Role-based access control
- **Features:**
  - Permission management
  - Role assignment
  - Access control
  - Policy enforcement

### **Profile Service**
- **Purpose:** User profile management
- **Features:**
  - Profile data storage
  - Avatar management
  - Preference settings
  - Data export

### **Notification Service**
- **Purpose:** Email notifications
- **Features:**
  - Welcome emails
  - Password reset
  - Account verification
  - Security alerts

## 📊 **Configuration**

### Environment Variables
```bash
# Database Configuration
DATABASE_URL=postgresql://users_user:users_password@postgres:5432/kanizsa_users

# JWT Configuration
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production

# Redis Configuration
REDIS_URL=redis://:redis_password@redis:6379/0

# SMTP Configuration
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=notifications@kanizsa.com
SMTP_PASSWORD=your_smtp_password

# Storage Configuration
STORAGE_BUCKET=kanizsa-user-profiles
```

## 🔍 **User Management Capabilities**

### **User Registration**
- Email-based registration
- Email verification
- Password strength validation
- Terms of service acceptance
- Welcome email notifications

### **Authentication**
- JWT token-based authentication
- Password-based login
- Multi-factor authentication (MFA)
- Remember me functionality
- Session management

### **Profile Management**
- User profile creation
- Profile data updates
- Avatar upload and management
- Preference settings
- Data export capabilities

### **Account Management**
- Password changes
- Email address updates
- Account deactivation
- Data deletion requests
- Account recovery

### **Authorization**
- Role-based access control
- Permission management
- API access control
- Service integration
- Audit logging

## 🔒 **Security**

### **Authentication Security**
- Password hashing with bcrypt
- JWT token security
- Session management
- Rate limiting
- Brute force protection

### **Data Protection**
- Encrypted data storage
- Secure data transmission
- GDPR compliance
- Data retention policies
- Privacy controls

### **Access Control**
- Role-based permissions
- API authentication
- Service-to-service auth
- Audit logging
- Security monitoring

## 🚨 **Monitoring**

### **User Activity Monitoring**
- Login attempts
- Failed authentication
- Account changes
- Profile updates
- Security events

### **System Monitoring**
- API performance
- Database performance
- Redis performance
- Email delivery
- Service availability

## 🚀 **Deployment**

### **Production Deployment**
```bash
# Production environment setup
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Scale services
docker-compose up -d --scale user-api=3
```

### **High Availability**
- Load-balanced API instances
- Database replication
- Redis clustering
- Email service redundancy
- Backup and recovery

## 🧪 **Testing**

### **Health Checks**
```bash
# Check service health
curl http://localhost:8000/health

# Test user registration
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123", "name": "Test User"}'
```

### **Authentication Tests**
```bash
# Test user login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'

# Test profile access
curl -X GET http://localhost:8000/users/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 📚 **Documentation**

- [Authentication Guide](docs/authentication.md)
- [API Reference](docs/api-reference.md)
- [Security Guide](docs/security.md)
- [Kanizsa Ecosystem Documentation](../kanizsa-photo-categorizer/README.md)

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Footer:** Kanizsa User Management Service v1.1.0 | Last Updated: August 9, 2025, 12:05:18 CDT
