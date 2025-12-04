import express from 'express';
import bcrypt from 'bcryptjs';
import { supabase } from '../server.js';
import { logger } from '../utils/logger.js';

const router = express.Router();

// Helper function to normalize phone numbers
function normalizePhone(phone) {
  if (!phone) return '';
  // Remove all spaces, dashes, and parentheses
  let cleaned = phone.replace(/[\s\-\(\)]/g, '');
  // Ensure it starts with +, if not add it for international numbers
  if (cleaned.startsWith('00')) {
    cleaned = '+' + cleaned.substring(2);
  } else if (cleaned.startsWith('0') && cleaned.length === 10) {
    // Kenyan number starting with 0, convert to +254
    cleaned = '+254' + cleaned.substring(1);
  } else if (!cleaned.startsWith('+') && cleaned.length >= 9) {
    // If no + and looks like international, add +
    cleaned = '+' + cleaned;
  }
  return cleaned;
}

// Driver login endpoint - supports phone + PIN
router.post('/drivers/login', async (req, res, next) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({
        success: false,
        message: 'Phone and PIN are required'
      });
    }

    // Normalize phone number
    const normalizedPhone = normalizePhone(phone);
    logger.info('Driver login attempt', { 
      originalPhone: phone, 
      normalizedPhone: normalizedPhone,
      hasPassword: !!password 
    });

    // Get all drivers to help with debugging
    const { data: allDrivers } = await supabase
      .from('users')
      .select('phone, full_name, email')
      .eq('user_type', 'driver');
    
    logger.info('Available driver phones', { 
      phones: allDrivers?.map(d => ({ phone: d.phone, name: d.full_name })) 
    });

    // Try multiple phone formats to find the user
    let userData = null;
    let userError = null;
    
    // Try different variations of the phone number
    const phoneVariations = [
      normalizedPhone, // With + as normalized
      normalizedPhone.startsWith('+') ? normalizedPhone.substring(1) : '+' + normalizedPhone, // Opposite
    ];
    
    // Also try the original if different
    if (phone !== normalizedPhone) {
      phoneVariations.push(phone);
    }

    for (const phoneVar of phoneVariations) {
      const result = await supabase
        .from('users')
        .select('id, email, user_type, full_name, phone')
        .eq('phone', phoneVar)
        .eq('user_type', 'driver')
        .single();
      
      if (!result.error && result.data) {
        userData = result.data;
        logger.info('Found driver with phone variation', { tried: phoneVar, found: userData.phone });
        break;
      }
    }

    if (!userData) {
      logger.warn('Driver not found by phone', { 
        originalPhone: phone,
        normalizedPhone: normalizedPhone,
        triedVariations: phoneVariations,
        availablePhones: allDrivers?.map(d => d.phone)
      });
      
      return res.status(401).json({
        success: false,
        message: `Invalid phone number or PIN. Available driver phones: ${allDrivers?.map(d => d.phone).join(', ') || 'none'}`
      });
    }

    // Get the driver's email for Supabase auth
    const driverEmail = userData.email;
    logger.info('Found driver', { userId: userData.id, email: driverEmail, phone: userData.phone });

    // Authenticate with Supabase using email + PIN as password
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: driverEmail,
      password: password, // PIN is used as password
    });

    if (authError || !authData.user) {
      logger.warn('Driver auth failed', { 
        phone: normalizedPhone, 
        email: driverEmail,
        error: authError?.message,
        errorCode: authError?.status 
      });
      return res.status(401).json({
        success: false,
        message: 'Invalid phone number or PIN'
      });
    }

    // Get driver details
    const { data: driverData } = await supabase
      .from('drivers')
      .select('status, vehicle_type')
      .eq('id', userData.id)
      .single();

    // Check if driver is active
    if (driverData?.status === 'blocked') {
      return res.status(403).json({
        success: false,
        message: 'Your account has been blocked. Please contact support.'
      });
    }

    if (driverData?.status === 'inactive') {
      return res.status(403).json({
        success: false,
        message: 'Your account is inactive. Please contact support.'
      });
    }

    logger.info('Driver login successful', { userId: userData.id, phone: userData.phone });

    res.json({
      success: true,
      data: {
        user: {
          id: userData.id,
          email: userData.email,
          fullName: userData.full_name,
          phone: userData.phone,
          userType: userData.user_type,
          vehicleType: driverData?.vehicle_type,
          status: driverData?.status
        },
        token: authData.session.access_token,
        refreshToken: authData.session.refresh_token,
      }
    });
  } catch (error) {
    logger.error('Login error', { error: error.message });
    next(error);
  }
});

// Verify token endpoint
router.get('/verify', async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Token required'
      });
    }

    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token'
      });
    }

    // Get user data
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('id, email, user_type, full_name, phone')
      .eq('id', user.id)
      .single();

    if (userError || !userData) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        user: {
          id: userData.id,
          email: userData.email,
          fullName: userData.full_name,
          phone: userData.phone,
          userType: userData.user_type,
        }
      }
    });
  } catch (error) {
    logger.error('Token verification error', { error: error.message });
    next(error);
  }
});

// Logout endpoint (optional - mainly for token invalidation if needed)
router.post('/logout', async (req, res) => {
  // With JWT tokens, logout is typically handled client-side by removing the token
  // If you need server-side logout, implement token blacklisting here
  res.json({
    success: true,
    message: 'Logged out successfully'
  });
});

export default router;


