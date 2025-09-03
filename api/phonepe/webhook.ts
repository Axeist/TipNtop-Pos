// Force Edge Runtime
export const runtime = 'edge';

export default async function handler(req: Request) {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    console.log("📥 PhonePe webhook received:", {
      method: req.method,
      timestamp: new Date().toISOString(),
      url: req.url,
    });

    // Handle headers properly for Edge Runtime
    let headersObj: Record<string, string> = {};
    
    if (req.headers && typeof req.headers.forEach === 'function') {
      // Headers instance (Edge Runtime)
      req.headers.forEach((value, key) => {
        headersObj[key] = value;
      });
    }
    
    console.log("🔐 Headers:", headersObj);

    // Get Authorization header
    const authHeader = req.headers.get('authorization') || req.headers.get('Authorization');
    console.log("🔐 Authorization header:", authHeader);

    const body = await req.text();
    console.log("📄 Webhook payload:", body);

    let webhookData: any = null;
    try {
      webhookData = JSON.parse(body);
      console.log("✅ Parsed webhook:", JSON.stringify(webhookData, null, 2));
    } catch (e) {
      console.error("❌ Failed to parse webhook body:", e);
    }

    if (webhookData) {
      const event = webhookData.event;
      const payload = webhookData.payload;
      
      if (payload) {
        const orderId = payload.merchantOrderId || payload.orderId;
        const state = payload.state;
        const amount = payload.amount;
        
        console.log(`💳 Webhook Event: ${event} | Order: ${orderId} | State: ${state} | Amount: ${amount}`);
        
        // Log different event types
        switch (event) {
          case 'checkout.order.completed':
            console.log("✅ Payment completed successfully");
            break;
          case 'checkout.order.failed':
            console.log("❌ Payment failed or cancelled");
            break;
          case 'pg.refund.accepted':
            console.log("💰 Refund request accepted");
            break;
          case 'pg.refund.completed':
            console.log("✅ Refund completed");
            break;
          case 'pg.refund.failed':
            console.log("❌ Refund failed");
            break;
          default:
            console.log("ℹ️ Unknown event type:", event);
        }
      }
    }

    // Always respond 200 OK quickly
    return new Response("OK", { 
      status: 200,
      headers: {
        'Content-Type': 'text/plain'
      }
    });

  } catch (error) {
    console.error("❌ Webhook error:", error);
    // Still return 200 to prevent PhonePe retries
    return new Response("OK", { status: 200 });
  }
}
