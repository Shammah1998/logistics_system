import express from 'express';
import bcrypt from 'bcryptjs';
import { authenticate, requireUserType } from '../middleware/auth.js';
import { supabase } from '../server.js';
import { logger } from '../utils/logger.js';

const router = express.Router();

// Get all drivers - admins only (no auth required for listing)
router.get('/', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    // Get all drivers with their user info and credentials
    const { data: drivers, error } = await supabase
      .from('drivers')
      .select(`
        id,
        license_number,
        vehicle_type,
        vehicle_registration,
        status,
        blocked_reason,
        created_at,
        users!inner (
          id,
          email,
          phone,
          full_name,
          user_type
        )
      `)
      .order('created_at', { ascending: false });

    if (error) {
      logger.error('Error fetching drivers', { error: error.message });
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch drivers'
      });
    }

    // Get wallet balances for each driver
    const driverIds = drivers.map(d => d.id);
    const { data: wallets } = await supabase
      .from('wallets')
      .select('driver_id, balance')
      .in('driver_id', driverIds);

    const walletMap = {};
    if (wallets) {
      wallets.forEach(w => {
        walletMap[w.driver_id] = w.balance;
      });
    }

    // Format response
    const formattedDrivers = drivers.map(driver => ({
      id: driver.id,
      name: driver.users?.full_name || 'Unknown',
      phone: driver.users?.phone || '',
      email: driver.users?.email || '',
      status: driver.status,
      vehicleType: driver.vehicle_type,
      vehicleRegistration: driver.vehicle_registration,
      licenseNumber: driver.license_number,
      balance: walletMap[driver.id] || 0,
      createdAt: driver.created_at
    }));

    res.json({
      success: true,
      data: formattedDrivers
    });
  } catch (error) {
    logger.error('Error in get drivers', { error: error.message });
    next(error);
  }
});

// Create a new driver - admins only
router.post('/', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    const { fullName, phone, pin, vehicleType, vehicleRegistration, licenseNumber } = req.body;

    // Validate required fields
    if (!fullName || !phone || !pin) {
      return res.status(400).json({
        success: false,
        message: 'Full name, phone, and PIN are required'
      });
    }

    // Validate PIN (must be 4-6 digits)
    if (!/^\d{4,6}$/.test(pin)) {
      return res.status(400).json({
        success: false,
        message: 'PIN must be 4-6 digits'
      });
    }

    // Normalize phone number (same function as in authRoutes)
    function normalizePhone(phone) {
      if (!phone) return '';
      let cleaned = phone.replace(/[\s\-\(\)]/g, '');
      if (cleaned.startsWith('00')) {
        cleaned = '+' + cleaned.substring(2);
      } else if (cleaned.startsWith('0') && cleaned.length === 10) {
        cleaned = '+254' + cleaned.substring(1);
      } else if (!cleaned.startsWith('+') && cleaned.length >= 9) {
        cleaned = '+' + cleaned;
      }
      return cleaned;
    }

    const cleanPhone = normalizePhone(phone);
    if (!/^\+?\d{10,15}$/.test(cleanPhone)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone number format'
      });
    }

    // Check if phone already exists
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('phone', cleanPhone)
      .single();

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'A user with this phone number already exists'
      });
    }

    // Create email from phone (for Supabase auth)
    const email = `driver_${cleanPhone.replace(/\+/g, '')}@drivers.xobo.co.ke`;

    // Create user in Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: email,
      password: pin, // Using PIN as password
      email_confirm: true, // Auto-confirm email
      user_metadata: {
        full_name: fullName,
        phone: cleanPhone,
        user_type: 'driver'
      }
    });

    if (authError) {
      logger.error('Error creating auth user', { error: authError.message });
      return res.status(500).json({
        success: false,
        message: `Failed to create driver account: ${authError.message}`
      });
    }

    const userId = authData.user.id;

    // Create user record in users table
    const { error: userError } = await supabase
      .from('users')
      .insert({
        id: userId,
        email: email,
        phone: cleanPhone,
        full_name: fullName,
        user_type: 'driver'
      });

    if (userError) {
      logger.error('Error creating user record', { error: userError.message });
      // Try to clean up auth user
      await supabase.auth.admin.deleteUser(userId);
      return res.status(500).json({
        success: false,
        message: 'Failed to create user record'
      });
    }

    // Create driver record
    const { error: driverError } = await supabase
      .from('drivers')
      .insert({
        id: userId,
        vehicle_type: vehicleType || 'small',
        vehicle_registration: vehicleRegistration || null,
        license_number: licenseNumber || null,
        status: 'active'
      });

    if (driverError) {
      logger.error('Error creating driver record', { error: driverError.message });
      // Clean up
      await supabase.from('users').delete().eq('id', userId);
      await supabase.auth.admin.deleteUser(userId);
      return res.status(500).json({
        success: false,
        message: 'Failed to create driver record'
      });
    }

    // Create wallet for driver
    const { error: walletError } = await supabase
      .from('wallets')
      .insert({
        driver_id: userId,
        balance: 0,
        pending_balance: 0,
        total_earned: 0
      });

    if (walletError) {
      logger.warn('Error creating wallet', { error: walletError.message });
      // Non-critical, continue
    }

    // Store driver credentials (phone + hashed PIN)
    const pinHash = await bcrypt.hash(pin, 10);
    const { error: credError } = await supabase
      .from('driver_credentials')
      .insert({
        driver_id: userId,
        phone: cleanPhone,
        pin_hash: pinHash
      });

    if (credError) {
      logger.warn('Error storing driver credentials', { error: credError.message });
      // Non-critical for now, driver can still use email/password
    }

    logger.info('Driver created successfully', { driverId: userId, phone: cleanPhone });

    res.status(201).json({
      success: true,
      message: 'Driver created successfully',
      data: {
        id: userId,
        name: fullName,
        phone: cleanPhone,
        email: email,
        vehicleType: vehicleType || 'small',
        status: 'active'
      }
    });
  } catch (error) {
    logger.error('Error creating driver', { error: error.message });
    next(error);
  }
});

// Update driver - admins only
router.put('/:driverId', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    const { driverId } = req.params;
    const { fullName, phone, pin, vehicleType, vehicleRegistration, licenseNumber, status } = req.body;

    // Update user record if name or phone changed
    if (fullName || phone) {
      const updateData = {};
      if (fullName) updateData.full_name = fullName;
      if (phone) updateData.phone = phone.replace(/\s+/g, '');

      const { error: userError } = await supabase
        .from('users')
        .update(updateData)
        .eq('id', driverId);

      if (userError) {
        logger.error('Error updating user', { error: userError.message });
        return res.status(500).json({
          success: false,
          message: 'Failed to update driver'
        });
      }
    }

    // Update driver record
    const driverUpdate = {};
    if (vehicleType) driverUpdate.vehicle_type = vehicleType;
    if (vehicleRegistration !== undefined) driverUpdate.vehicle_registration = vehicleRegistration;
    if (licenseNumber !== undefined) driverUpdate.license_number = licenseNumber;
    if (status) driverUpdate.status = status;

    if (Object.keys(driverUpdate).length > 0) {
      const { error: driverError } = await supabase
        .from('drivers')
        .update(driverUpdate)
        .eq('id', driverId);

      if (driverError) {
        logger.error('Error updating driver', { error: driverError.message });
        return res.status(500).json({
          success: false,
          message: 'Failed to update driver'
        });
      }
    }

    // Update PIN if provided
    if (pin) {
      if (!/^\d{4,6}$/.test(pin)) {
        return res.status(400).json({
          success: false,
          message: 'PIN must be 4-6 digits'
        });
      }

      // Update password in Supabase Auth
      const { error: authError } = await supabase.auth.admin.updateUserById(driverId, {
        password: pin
      });

      if (authError) {
        logger.warn('Error updating auth password', { error: authError.message });
      }

      // Update PIN hash in credentials
      const pinHash = await bcrypt.hash(pin, 10);
      const { error: credError } = await supabase
        .from('driver_credentials')
        .update({ pin_hash: pinHash })
        .eq('driver_id', driverId);

      if (credError) {
        logger.warn('Error updating credentials', { error: credError.message });
      }
    }

    logger.info('Driver updated successfully', { driverId });

    res.json({
      success: true,
      message: 'Driver updated successfully'
    });
  } catch (error) {
    logger.error('Error updating driver', { error: error.message });
    next(error);
  }
});

// Delete driver - admins only
router.delete('/:driverId', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    const { driverId } = req.params;

    // Delete from Supabase Auth (this will cascade to users and drivers tables)
    const { error: authError } = await supabase.auth.admin.deleteUser(driverId);

    if (authError) {
      logger.error('Error deleting driver', { error: authError.message });
      return res.status(500).json({
        success: false,
        message: 'Failed to delete driver'
      });
    }

    logger.info('Driver deleted successfully', { driverId });

    res.json({
      success: true,
      message: 'Driver deleted successfully'
    });
  } catch (error) {
    logger.error('Error deleting driver', { error: error.message });
    next(error);
  }
});

// Assign order to driver - admins only
router.post('/:driverId/assign-order', authenticate, requireUserType('admin'), async (req, res, next) => {
  try {
    // TODO: Implement driver assignment logic
    res.json({
      success: true,
      message: 'Driver assignment endpoint - to be implemented'
    });
  } catch (error) {
    next(error);
  }
});

// ============================================
// DRIVER SELF-SERVICE ENDPOINTS
// ============================================

// Get driver's own profile
router.get('/me/profile', authenticate, async (req, res, next) => {
  try {
    const driverId = req.user.id;

    // Get user info
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('id, email, phone, full_name')
      .eq('id', driverId)
      .single();

    if (userError || !userData) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Get driver info
    const { data: driverData } = await supabase
      .from('drivers')
      .select('vehicle_type, vehicle_registration, license_number, status')
      .eq('id', driverId)
      .single();

    // Get wallet info
    const { data: walletData } = await supabase
      .from('wallets')
      .select('balance, pending_balance, total_earned')
      .eq('driver_id', driverId)
      .single();

    res.json({
      success: true,
      data: {
        id: userData.id,
        email: userData.email,
        phone: userData.phone,
        fullName: userData.full_name,
        vehicleType: driverData?.vehicle_type,
        vehicleRegistration: driverData?.vehicle_registration,
        licenseNumber: driverData?.license_number,
        status: driverData?.status,
        wallet: {
          balance: walletData?.balance || 0,
          pendingBalance: walletData?.pending_balance || 0,
          totalEarned: walletData?.total_earned || 0
        }
      }
    });
  } catch (error) {
    logger.error('Error fetching driver profile', { error: error.message });
    next(error);
  }
});

// Get driver's orders
router.get('/me/orders', authenticate, async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { status } = req.query;

    let query = supabase
      .from('orders')
      .select(`
        id,
        pickup_address,
        total_amount,
        status,
        created_at,
        drops (
          id,
          recipient_name,
          address,
          status
        )
      `)
      .eq('driver_id', driverId)
      .order('created_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    const { data: orders, error } = await query;

    if (error) {
      logger.error('Error fetching driver orders', { error: error.message });
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch orders'
      });
    }

    res.json({
      success: true,
      data: orders || []
    });
  } catch (error) {
    logger.error('Error in get driver orders', { error: error.message });
    next(error);
  }
});

// Get driver's wallet/earnings
router.get('/me/wallet', authenticate, async (req, res, next) => {
  try {
    const driverId = req.user.id;

    // Get wallet
    const { data: wallet } = await supabase
      .from('wallets')
      .select('balance, pending_balance, total_earned')
      .eq('driver_id', driverId)
      .single();

    // Get recent transactions
    const { data: transactions } = await supabase
      .from('transactions')
      .select('id, amount, type, description, status, created_at')
      .eq('wallet_id', wallet?.id)
      .order('created_at', { ascending: false })
      .limit(10);

    res.json({
      success: true,
      data: {
        balance: wallet?.balance || 0,
        pendingBalance: wallet?.pending_balance || 0,
        totalEarned: wallet?.total_earned || 0,
        transactions: transactions || []
      }
    });
  } catch (error) {
    logger.error('Error fetching wallet', { error: error.message });
    next(error);
  }
});

// Update driver online status
router.post('/me/status', authenticate, async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { isOnline } = req.body;

    // For now, just return success - in production, you'd update a driver_status table
    logger.info('Driver status updated', { driverId, isOnline });

    res.json({
      success: true,
      message: isOnline ? 'You are now online' : 'You are now offline',
      data: { isOnline }
    });
  } catch (error) {
    logger.error('Error updating status', { error: error.message });
    next(error);
  }
});

// Request withdrawal
router.post('/me/withdraw', authenticate, async (req, res, next) => {
  try {
    const driverId = req.user.id;
    const { amount, phoneNumber } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid withdrawal amount'
      });
    }

    // Get wallet
    const { data: wallet } = await supabase
      .from('wallets')
      .select('id, balance')
      .eq('driver_id', driverId)
      .single();

    if (!wallet || wallet.balance < amount) {
      return res.status(400).json({
        success: false,
        message: 'Insufficient balance'
      });
    }

    // Create withdrawal request
    const { data: withdrawal, error } = await supabase
      .from('withdrawal_requests')
      .insert({
        driver_id: driverId,
        amount: amount,
        phone_number: phoneNumber || null,
        status: 'pending'
      })
      .select()
      .single();

    if (error) {
      logger.error('Error creating withdrawal', { error: error.message });
      return res.status(500).json({
        success: false,
        message: 'Failed to create withdrawal request'
      });
    }

    logger.info('Withdrawal requested', { driverId, amount });

    res.json({
      success: true,
      message: 'Withdrawal request submitted',
      data: withdrawal
    });
  } catch (error) {
    logger.error('Error in withdrawal', { error: error.message });
    next(error);
  }
});

export default router;

