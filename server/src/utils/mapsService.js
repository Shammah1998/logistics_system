import axios from 'axios';

const GOOGLE_MAPS_API_KEY = process.env.GOOGLE_MAPS_API_KEY;
const GOOGLE_MAPS_BASE_URL = 'https://maps.googleapis.com/maps/api';

/**
 * Calculate distance between multiple points using Google Maps Distance Matrix API
 * @param {Object} pickup - Pickup location with coordinates
 * @param {Array} drops - Array of drop locations with coordinates
 * @returns {Promise<Object>} Distance and duration information
 */
export const calculateDistance = async (pickup, drops) => {
  try {
    if (!GOOGLE_MAPS_API_KEY) {
      throw new Error('Google Maps API key not configured');
    }

    // Build origins and destinations
    const origins = `${pickup.coordinates.lat},${pickup.coordinates.lng}`;
    const destinations = drops
      .map(drop => `${drop.address.coordinates.lat},${drop.address.coordinates.lng}`)
      .join('|');

    const url = `${GOOGLE_MAPS_BASE_URL}/distancematrix/json`;
    const params = {
      origins,
      destinations,
      key: GOOGLE_MAPS_API_KEY,
      units: 'metric'
    };

    const response = await axios.get(url, { params });

    if (response.data.status !== 'OK') {
      throw new Error(`Google Maps API error: ${response.data.status}`);
    }

    // Calculate total distance
    let totalDistance = 0;
    const elements = response.data.rows[0].elements;

    elements.forEach((element, index) => {
      if (element.status === 'OK') {
        totalDistance += element.distance.value; // Distance in meters
      } else {
        throw new Error(`Failed to calculate distance for drop ${index + 1}: ${element.status}`);
      }
    });

    // Convert meters to kilometers
    const totalDistanceKm = totalDistance / 1000;

    return {
      totalDistanceKm: parseFloat(totalDistanceKm.toFixed(2)),
      details: elements.map((el, idx) => ({
        dropIndex: idx,
        distance: el.distance.value / 1000, // km
        duration: el.duration.value, // seconds
        status: el.status
      }))
    };
  } catch (error) {
    throw new Error(`Distance calculation failed: ${error.message}`);
  }
};

/**
 * Get place details from coordinates (reverse geocoding)
 * @param {number} lat - Latitude
 * @param {number} lng - Longitude
 * @returns {Promise<Object>} Place details
 */
export const getPlaceFromCoordinates = async (lat, lng) => {
  try {
    if (!GOOGLE_MAPS_API_KEY) {
      throw new Error('Google Maps API key not configured');
    }

    const url = `${GOOGLE_MAPS_BASE_URL}/geocode/json`;
    const params = {
      latlng: `${lat},${lng}`,
      key: GOOGLE_MAPS_API_KEY
    };

    const response = await axios.get(url, { params });

    if (response.data.status !== 'OK') {
      throw new Error(`Google Maps Geocoding error: ${response.data.status}`);
    }

    const result = response.data.results[0];
    return {
      formattedAddress: result.formatted_address,
      components: result.address_components,
      placeId: result.place_id,
      geometry: result.geometry
    };
  } catch (error) {
    throw new Error(`Geocoding failed: ${error.message}`);
  }
};

