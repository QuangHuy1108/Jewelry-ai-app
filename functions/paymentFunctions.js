const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

const db = admin.firestore();

// ═══════════════════════════════════════════════════════════════
// PAYMENT WEBHOOK — Generic handler for payment gateways
// Supports: VNPay, MoMo, ZaloPay, Stripe
//
// Usage:
//   POST /paymentWebhook?gateway=vnpay
//   POST /paymentWebhook?gateway=stripe
// ═══════════════════════════════════════════════════════════════
exports.paymentWebhook = functions.https.onRequest(async (req, res) => {
  // CORS
  res.set('Access-Control-Allow-Origin', '*');
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Stripe-Signature');
    return res.status(204).send('');
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const gateway = req.query.gateway || 'unknown';

  try {
    let orderId, paymentStatus, transactionId;

    switch (gateway) {
      case 'stripe':
        ({ orderId, paymentStatus, transactionId } = await handleStripe(req));
        break;
      case 'vnpay':
        ({ orderId, paymentStatus, transactionId } = handleVNPay(req));
        break;
      case 'momo':
        ({ orderId, paymentStatus, transactionId } = handleMoMo(req));
        break;
      case 'zalopay':
        ({ orderId, paymentStatus, transactionId } = handleZaloPay(req));
        break;
      default:
        return res.status(400).json({ error: `Unknown gateway: ${gateway}` });
    }

    if (!orderId) {
      return res.status(400).json({ error: 'Missing orderId from payment data' });
    }

    // Update order status in Firestore
    const orderRef = db.collection('orders').doc(orderId);
    const orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      return res.status(404).json({ error: `Order ${orderId} not found` });
    }

    const newStatus = paymentStatus === 'success' ? 'processing' : 'payment_failed';

    await orderRef.update({
      status: newStatus,
      paymentStatus: paymentStatus,
      paymentGateway: gateway,
      transactionId: transactionId || null,
      paidAt: paymentStatus === 'success' 
        ? admin.firestore.FieldValue.serverTimestamp() 
        : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Also update user's order subcollection
    const userId = orderSnap.data().userId;
    if (userId) {
      await db.collection('users').doc(userId).collection('orders').doc(orderId).update({
        status: newStatus,
        paymentStatus: paymentStatus,
        paidAt: paymentStatus === 'success'
          ? admin.firestore.FieldValue.serverTimestamp()
          : null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    console.log(`Payment webhook [${gateway}]: Order ${orderId} → ${newStatus}`);
    return res.status(200).json({ success: true, orderId, status: newStatus });

  } catch (error) {
    console.error(`Payment webhook error [${gateway}]:`, error);
    return res.status(500).json({ error: 'Internal server error' });
  }
});


// ─── Gateway Handlers ────────────────────────────────────────

function handleVNPay(req) {
  const data = req.body;
  // VNPay sends: vnp_TxnRef (orderId), vnp_ResponseCode, vnp_TransactionNo
  
  // TODO: Verify signature using VNPay secret key
  // const secureHash = data.vnp_SecureHash;
  // Verify with: crypto.createHmac('sha512', VNP_HASH_SECRET).update(signData).digest('hex');

  return {
    orderId: data.vnp_TxnRef || data.orderId,
    paymentStatus: data.vnp_ResponseCode === '00' ? 'success' : 'failed',
    transactionId: data.vnp_TransactionNo,
  };
}

function handleMoMo(req) {
  const data = req.body;
  // MoMo sends: orderId, resultCode, transId
  
  // TODO: Verify signature using MoMo secret key

  return {
    orderId: data.orderId,
    paymentStatus: data.resultCode === 0 ? 'success' : 'failed',
    transactionId: data.transId,
  };
}

function handleZaloPay(req) {
  const data = req.body;
  // ZaloPay sends: data (JSON string), mac
  
  // TODO: Verify HMAC signature
  // const mac = crypto.createHmac('sha256', ZALO_KEY2).update(data.data).digest('hex');

  let parsed = {};
  try {
    parsed = JSON.parse(data.data || '{}');
  } catch (e) { /* ignore */ }

  return {
    orderId: parsed.app_trans_id || data.app_trans_id,
    paymentStatus: data.type === 1 ? 'success' : 'failed',
    transactionId: parsed.zp_trans_id || data.zp_trans_id,
  };
}

async function handleStripe(req) {
  // Stripe sends event in body with signature in header
  const sig = req.headers['stripe-signature'];
  
  // TODO: Verify with stripe.webhooks.constructEvent(req.rawBody, sig, endpointSecret);
  // For now, parse directly:
  const event = req.body;
  
  if (event.type === 'checkout.session.completed' || event.type === 'payment_intent.succeeded') {
    const session = event.data?.object;
    return {
      orderId: session?.metadata?.orderId || session?.client_reference_id,
      paymentStatus: 'success',
      transactionId: session?.payment_intent || session?.id,
    };
  }

  return {
    orderId: event.data?.object?.metadata?.orderId,
    paymentStatus: 'failed',
    transactionId: null,
  };
}
