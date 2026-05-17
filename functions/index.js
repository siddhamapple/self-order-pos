const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const createRazorpayOrder = require("./createRazorpayOrder");

admin.initializeApp();

/**
 * Create Razorpay Order (POS Dynamic QR)
 */
exports.createRazorpayOrder = onRequest(
  { region: "asia-south1" },
  createRazorpayOrder
);
