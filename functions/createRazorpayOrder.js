const functions = require("firebase-functions");
const Razorpay = require("razorpay");

/**
 * Creates a Razorpay order by instantiating the client inside the function 
 * to ensure Firebase config keys are available at runtime.
 */
module.exports = async function createRazorpayOrder({ orderId, amount }) {
  // 1. Access config inside the function
  const { key_id, key_secret } = functions.config().razorpay;

  // 2. Safety check for environment variables
  if (!key_id || !key_secret) {
    throw new Error("Razorpay keys are missing in Firebase config. Run: firebase functions:config:set razorpay.key_id='...' razorpay.key_secret='...'");
  }

  // 3. Instantiate Razorpay INSIDE the function
  const razorpay = new Razorpay({
    key_id: key_id,
    key_secret: key_secret,
  });

  try {
    // 4. Create the order
    const order = await razorpay.orders.create({
      amount: amount * 100, // Amount in paise (e.g., 500 INR = 50000)
      currency: "INR",
      receipt: orderId,
      payment_capture: 1, // 1 means automatic capture, 0 means manual
    });

    // 5. Return the relevant order details
    return {
      razorpayOrderId: order.id,
      amount: order.amount,
      currency: order.currency,
    };
  } catch (error) {
    console.error("Razorpay Order Creation Failed:", error);
    throw new Error(`Failed to create Razorpay order: ${error.message}`);
  }
};