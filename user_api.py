#!/usr/bin/env python3
"""
Kanizsa User Management Service API
Provides user management, authentication, and authorization capabilities
"""

import os
import time
import jwt
import bcrypt
from flask import Flask, jsonify, request
from datetime import datetime, timedelta

app = Flask(__name__)

# Configuration
JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'your-secret-key')
JWT_ALGORITHM = 'HS256'

# Sample user database (in production, use a real database)
USERS_DB = {
    'user1@example.com': {
        'id': 'user1',
        'email': 'user1@example.com',
        'password_hash': bcrypt.hashpw('password123'.encode('utf-8'), bcrypt.gensalt()),
        'name': 'John Doe',
        'role': 'user',
        'created_at': '2025-01-01T00:00:00Z',
        'is_active': True
    }
}

def generate_token(user_id):
    """Generate JWT token"""
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(hours=24),
        'iat': datetime.utcnow()
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

def verify_token(token):
    """Verify JWT token"""
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return payload['user_id']
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': time.time(),
        'service': 'kanizsa-users'
    })

@app.route('/auth/register', methods=['POST'])
def register():
    """Register a new user"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        name = data.get('name')
        
        if email in USERS_DB:
            return jsonify({
                'error': 'User already exists'
            }), 400
        
        # Hash password
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
        
        # Create user
        user_id = f'user{len(USERS_DB) + 1}'
        USERS_DB[email] = {
            'id': user_id,
            'email': email,
            'password_hash': password_hash,
            'name': name,
            'role': 'user',
            'created_at': datetime.utcnow().isoformat() + 'Z',
            'is_active': True
        }
        
        return jsonify({
            'status': 'success',
            'user_id': user_id,
            'message': 'User registered successfully'
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 400

@app.route('/auth/login', methods=['POST'])
def login():
    """Login user"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if email not in USERS_DB:
            return jsonify({
                'error': 'Invalid credentials'
            }), 401
        
        user = USERS_DB[email]
        
        # Verify password
        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash']):
            return jsonify({
                'error': 'Invalid credentials'
            }), 401
        
        # Generate token
        token = generate_token(user['id'])
        
        return jsonify({
            'status': 'success',
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'name': user['name'],
                'role': user['role']
            }
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 400

@app.route('/users/profile', methods=['GET'])
def get_profile():
    """Get user profile"""
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({
            'error': 'Authorization header required'
        }), 401
    
    token = auth_header.split(' ')[1]
    user_id = verify_token(token)
    
    if not user_id:
        return jsonify({
            'error': 'Invalid token'
        }), 401
    
    # Find user by ID
    user = None
    for email, user_data in USERS_DB.items():
        if user_data['id'] == user_id:
            user = user_data
            break
    
    if not user:
        return jsonify({
            'error': 'User not found'
        }), 404
    
    return jsonify({
        'user': {
            'id': user['id'],
            'email': user['email'],
            'name': user['name'],
            'role': user['role'],
            'created_at': user['created_at']
        }
    })

@app.route('/users/profile', methods=['PUT'])
def update_profile():
    """Update user profile"""
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({
            'error': 'Authorization header required'
        }), 401
    
    token = auth_header.split(' ')[1]
    user_id = verify_token(token)
    
    if not user_id:
        return jsonify({
            'error': 'Invalid token'
        }), 401
    
    try:
        data = request.get_json()
        name = data.get('name')
        
        # Find and update user
        for email, user_data in USERS_DB.items():
            if user_data['id'] == user_id:
                user_data['name'] = name
                return jsonify({
                    'status': 'success',
                    'message': 'Profile updated successfully'
                })
        
        return jsonify({
            'error': 'User not found'
        }), 404
    except Exception as e:
        return jsonify({
            'status': 'error',
            'error': str(e)
        }), 400

@app.route('/')
def index():
    """Root endpoint"""
    return jsonify({
        'service': 'Kanizsa User Management Service',
        'version': '1.0.0',
        'endpoints': {
            'health': '/health',
            'register': '/auth/register',
            'login': '/auth/login',
            'profile': '/users/profile'
        }
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)
