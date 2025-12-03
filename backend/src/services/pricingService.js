import { supabase } from '../server.js';
import { calculateDistance } from '../utils/mapsService.js';

/**
 * Get applicable price card for an order
 * @param {string|null} companyId - Company ID (null for retail/default)
 * @param {string} vehicleType - Vehicle type (small, medium, large)
 * @param {string} pricingMode - Pricing mode (distance_based, per_box)
 * @returns {Promise<Object>} Price card
 */
export const getPriceCard = async (companyId, vehicleType, pricingMode) => {
  try {
    let query = supabase
      .from('price_cards')
      .select('*')
      .eq('vehicle_type', vehicleType)
      .eq('pricing_mode', pricingMode)
      .eq('is_active', true)
      .lte('valid_from', new Date().toISOString())
      .order('valid_from', { ascending: false });

    // If company ID provided, try to get company-specific price card first
    if (companyId) {
      const { data: companyCard, error: companyError } = await query
        .eq('company_id', companyId)
        .maybeSingle();

      if (!companyError && companyCard) {
        return companyCard;
      }
    }

    // Fall back to default price card (company_id is null)
    const { data: defaultCard, error: defaultError } = await query
      .is('company_id', null)
      .maybeSingle();

    if (defaultError) {
      throw new Error(`Failed to fetch price card: ${defaultError.message}`);
    }

    if (!defaultCard) {
      throw new Error(`No price card found for vehicle type: ${vehicleType}, pricing mode: ${pricingMode}`);
    }

    return defaultCard;
  } catch (error) {
    throw new Error(`Price card retrieval failed: ${error.message}`);
  }
};

/**
 * Calculate order price based on pricing mode
 * @param {Object} orderData - Order data including pickup, drops, items
 * @param {string|null} companyId - Company ID
 * @param {string} vehicleType - Vehicle type
 * @param {string} pricingMode - Pricing mode
 * @returns {Promise<Object>} Calculated price details
 */
export const calculateOrderPrice = async (orderData, companyId, vehicleType, pricingMode) => {
  try {
    const priceCard = await getPriceCard(companyId, vehicleType, pricingMode);

    let basePrice = 0;
    let totalPrice = 0;
    let totalDistanceKm = null;

    if (pricingMode === 'distance_based') {
      // Calculate distance from pickup to all drops
      const distanceResult = await calculateDistance(
        orderData.pickup_address,
        orderData.drops
      );

      totalDistanceKm = distanceResult.totalDistanceKm;
      basePrice = parseFloat(priceCard.base_price);
      const distancePrice = totalDistanceKm * parseFloat(priceCard.price_per_km);
      totalPrice = basePrice + distancePrice;
    } else if (pricingMode === 'per_box') {
      // Calculate price based on items
      basePrice = 0;
      totalPrice = orderData.items.reduce((sum, item) => {
        const itemPrice = item.quantity * parseFloat(item.unit_price);
        return sum + itemPrice;
      }, 0);
    } else {
      throw new Error(`Invalid pricing mode: ${pricingMode}`);
    }

    // Apply minimum price
    if (totalPrice < parseFloat(priceCard.min_price)) {
      totalPrice = parseFloat(priceCard.min_price);
    }

    return {
      base_price: parseFloat(basePrice.toFixed(2)),
      total_distance_km: totalDistanceKm ? parseFloat(totalDistanceKm.toFixed(2)) : null,
      total_price: parseFloat(totalPrice.toFixed(2)),
      price_card_id: priceCard.id
    };
  } catch (error) {
    throw new Error(`Price calculation failed: ${error.message}`);
  }
};

/**
 * Calculate driver payment after POD approval
 * @param {number} grossAmount - Gross order amount
 * @returns {Object} Payment breakdown
 */
export const calculateDriverPayment = (grossAmount) => {
  const commissionPercent = parseFloat(process.env.PLATFORM_COMMISSION_PERCENT || '10');
  const insurancePercent = parseFloat(process.env.INSURANCE_PERCENT || '2');
  const withholdingTaxPercent = parseFloat(process.env.WITHHOLDING_TAX_PERCENT || '5');

  const commission = (grossAmount * commissionPercent) / 100;
  const insurance = (grossAmount * insurancePercent) / 100;
  const withholdingTax = (grossAmount * withholdingTaxPercent) / 100;
  const netAmount = grossAmount - commission - insurance - withholdingTax;

  return {
    gross_amount: parseFloat(grossAmount.toFixed(2)),
    commission: parseFloat(commission.toFixed(2)),
    insurance: parseFloat(insurance.toFixed(2)),
    withholding_tax: parseFloat(withholdingTax.toFixed(2)),
    net_amount: parseFloat(netAmount.toFixed(2))
  };
};

