# Pricing Engine Documentation

## Overview

The pricing engine calculates order prices based on two modes:
1. **Distance-based**: Price calculated from pickup to drop locations
2. **Per-box**: Price calculated from item quantities and unit prices

## Price Card System

Price cards define pricing rules for different vehicle types and pricing modes. They can be:
- **Default**: Applied to all customers (company_id is NULL)
- **Corporate-specific**: Override default pricing for specific companies

### Price Card Structure

```sql
{
  "id": "uuid",
  "company_id": "uuid | null",  -- null for default pricing
  "vehicle_type": "small | medium | large",
  "pricing_mode": "distance_based | per_box",
  "base_price": 500.00,          -- Base price in KES
  "price_per_km": 50.00,         -- For distance_based mode
  "price_per_box": 100.00,       -- For per_box mode
  "min_price": 300.00,           -- Minimum order price
  "is_active": true,
  "valid_from": "2024-01-01T00:00:00Z",
  "valid_to": "2024-12-31T23:59:59Z | null"
}
```

## Pricing Calculation

### Distance-Based Pricing

**Formula:**
```
total_price = base_price + (total_distance_km × price_per_km)
```

**Process:**
1. Get applicable price card (company-specific or default)
2. Calculate total distance from pickup to all drop locations using Google Maps API
3. Apply formula: `base_price + (distance × price_per_km)`
4. Apply minimum price if calculated price is lower

**Example:**
- Base price: 500 KES
- Price per km: 50 KES
- Distance: 15.5 km
- Calculation: 500 + (15.5 × 50) = 1,275 KES
- Minimum price: 300 KES (not applied in this case)
- **Total: 1,275 KES**

### Per-Box Pricing

**Formula:**
```
total_price = Σ(item.quantity × item.unit_price)
```

**Process:**
1. Get applicable price card
2. Sum all item prices: `quantity × unit_price` for each item
3. Apply minimum price if calculated price is lower

**Example:**
- Item 1: 2 boxes × 150 KES = 300 KES
- Item 2: 1 box × 200 KES = 200 KES
- Subtotal: 500 KES
- Minimum price: 300 KES (not applied)
- **Total: 500 KES**

## Driver Payment Calculation

After POD approval, driver payment is calculated with deductions:

**Formula:**
```
net_amount = gross_amount - commission - insurance - withholding_tax
```

**Deductions:**
- **Commission**: `gross_amount × (PLATFORM_COMMISSION_PERCENT / 100)`
- **Insurance**: `gross_amount × (INSURANCE_PERCENT / 100)`
- **Withholding Tax**: `gross_amount × (WITHHOLDING_TAX_PERCENT / 100)`

**Default Percentages:**
- Platform Commission: 10%
- Insurance: 2%
- Withholding Tax: 5%

**Example:**
- Gross amount: 1,000 KES
- Commission: 1,000 × 0.10 = 100 KES
- Insurance: 1,000 × 0.02 = 20 KES
- Withholding Tax: 1,000 × 0.05 = 50 KES
- Net amount: 1,000 - 100 - 20 - 50 = **830 KES**

## Price Card Priority

1. **Corporate-specific price card** (if company_id matches)
2. **Default price card** (company_id is NULL)

If no price card is found, an error is thrown.

## Implementation

See `backend/src/services/pricingService.js` for the implementation.

### Key Functions

- `getPriceCard(companyId, vehicleType, pricingMode)`: Retrieves applicable price card
- `calculateOrderPrice(orderData, companyId, vehicleType, pricingMode)`: Calculates order price
- `calculateDriverPayment(grossAmount)`: Calculates driver net payment

## Configuration

Pricing percentages are configured via environment variables:

```env
PLATFORM_COMMISSION_PERCENT=10
INSURANCE_PERCENT=2
WITHHOLDING_TAX_PERCENT=5
```

