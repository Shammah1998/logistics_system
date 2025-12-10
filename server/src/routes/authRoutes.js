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

// Helper function to generate driver email (must match driver creation)
function generateDriverEmail(phone) {
  const cleanPhone = normalizePhone(phone);
  return `driver_${cleanPhone.replace(/\+/g, '')}@drivers.xobo.co.ke`;
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

    // Normalize phone number - handle input with or without country code
    let inputPhone = phone.trim();
    
    // If phone doesn't start with +, add country code (default to +254 for Kenya)
    if (!inputPhone.startsWith('+')) {
      if (inputPhone.startsWith('0')) {
        inputPhone = '+254' + inputPhone.substring(1);
      } else {
        inputPhone = '+254' + inputPhone;
      }
    }
    
    const normalizedPhone = normalizePhone(inputPhone);
    const expectedEmail = generateDriverEmail(normalizedPhone);
    
    logger.info('Driver login attempt', { 
      originalPhone: phone, 
      inputPhone: inputPhone,
      normalizedPhone: normalizedPhone,
      expectedEmail: expectedEmail,
      hasPassword: !!password 
    });

    // STRATEGY: Try to authenticate directly with Supabase Auth first
    // This is the most reliable way since auth.users is the source of truth
    logger.info('Attempting direct Supabase auth', { email: expectedEmail });
    
    const authResult = await supabase.auth.signInWithPassword({
      email: expectedEmail,
      password: password,
    });

    if (authResult.error) {
      logger.warn('Direct auth failed', { 
        error: authResult.error.message,
        email: expectedEmail 
      });
      
      // Get available driver phones for error message
      const { data: allDrivers } = await supabase
        .from('users')
        .select('phone')
        .eq('user_type', 'driver');
      
      const availablePhones = allDrivers?.map(d => d.phone).filter(Boolean) || [];
      
      // If auth fails, it's either wrong phone or wrong PIN
      let errorMessage = 'Invalid phone number or PIN.';
      if (authResult.error.message?.includes('Invalid login credentials')) {
        errorMessage = 'Invalid PIN. Please check your PIN and try again.';
      }
      if (availablePhones.length > 0) {
        errorMessage += ` Available driver phones: ${availablePhones.join(', ')}`;
      }
      
      return res.status(401).json({
        success: false,
        message: errorMessage
      });
    }

    const authUser = authResult.data.user;
    const authSession = authResult.data.session;
    
    logger.info('Auth successful, checking public.users', { userId: authUser.id });

    // Auth succeeded! Now get or create the public.users record
    let { data: userData, error: userError } = await supabase
      .from('users')
      .select('id, email, user_type, full_name, phone')
      .eq('id', authUser.id)
      .single();

    // If user doesn't exist in public.users, create it
    if (userError || !userData) {
      logger.info('Creating missing public.users record', { 
        userId: authUser.id,
        email: expectedEmail,
        phone: normalizedPhone
      });
      
      const { data: newUser, error: createError } = await supabase
        .from('users')
        .insert({
          id: authUser.id,
          email: expectedEmail,
          phone: normalizedPhone,
          full_name: authUser.user_metadata?.full_name || 'Driver',
          user_type: 'driver'
        })
        .select()
        .single();
      
      if (createError) {
        logger.error('Failed to create public.users record', { error: createError.message });
        // Continue anyway - we have auth data
        userData = {
          id: authUser.id,
          email: expectedEmail,
          phone: normalizedPhone,
          full_name: authUser.user_metadata?.full_name || 'Driver',
          user_type: 'driver'
        };
      } else {
        userData = newUser;
        logger.info('Created public.users record', { userId: userData.id });
        
        // Invalidate drivers cache since we added a new user record
        try {
          const { cache, CacheKeys } = await import('../services/cacheService.js');
          await cache.invalidateEntity(CacheKeys.DRIVERS);
          logger.info('Invalidated drivers cache after creating user record');
        } catch (cacheError) {
          logger.warn('Failed to invalidate cache', { error: cacheError.message });
        }
      }
    } else {
      // Update phone if it's missing or different
      if (!userData.phone || userData.phone !== normalizedPhone) {
        logger.info('Updating user phone', { oldPhone: userData.phone, newPhone: normalizedPhone });
        await supabase
          .from('users')
          .update({ phone: normalizedPhone })
          .eq('id', authUser.id);
        userData.phone = normalizedPhone;
      }
    }

    // Get driver details (we already authenticated above)
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
        token: authSession.access_token,
        refreshToken: authSession.refresh_token,
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


