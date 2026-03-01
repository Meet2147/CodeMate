import { Router } from "express";
import { AuthenticatedRequest } from "../middleware/auth.js";
import { listPlans } from "../services/sessionService.js";

const router = Router();
const paypalEnv = String(process.env.PAYPAL_ENV || "sandbox").toLowerCase();

const usdPriceByPlan: Record<string, string> = {
  pro_monthly: "29.99",
  pro_yearly: "99.00",
  premium_monthly: "199.00",
  premium_yearly: "349.00",
  lifetime: "499.00"
};

function getPayPalBaseUrl(): string {
  return paypalEnv === "live" ? "https://api-m.paypal.com" : "https://api-m.sandbox.paypal.com";
}

function getClientCredentials(): { clientId: string; clientSecret: string } {
  const clientId = String(process.env.PAYPAL_CLIENT_ID || "").trim();
  const clientSecret = String(process.env.PAYPAL_CLIENT_SECRET || "").trim();
  if (!clientId || !clientSecret) {
    throw new Error("Missing PAYPAL_CLIENT_ID or PAYPAL_CLIENT_SECRET");
  }
  return { clientId, clientSecret };
}

async function getPayPalAccessToken(): Promise<string> {
  const { clientId, clientSecret } = getClientCredentials();
  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString("base64");

  const response = await fetch(`${getPayPalBaseUrl()}/v1/oauth2/token`, {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body: "grant_type=client_credentials"
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload?.error_description || payload?.error || "PayPal auth failed");
  }

  const token = String(payload?.access_token || "").trim();
  if (!token) {
    throw new Error("PayPal access token missing");
  }
  return token;
}

async function createPayPalOrder(params: {
  amountUsd: string;
  userId: string;
  planCode: string;
  returnUrl: string;
  cancelUrl: string;
}): Promise<{ orderId: string; approveUrl: string }> {
  const token = await getPayPalAccessToken();

  const response = await fetch(`${getPayPalBaseUrl()}/v2/checkout/orders`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      intent: "CAPTURE",
      purchase_units: [
        {
          reference_id: params.planCode,
          custom_id: params.userId,
          amount: {
            currency_code: "USD",
            value: params.amountUsd
          }
        }
      ],
      application_context: {
        return_url: params.returnUrl,
        cancel_url: params.cancelUrl,
        user_action: "PAY_NOW",
        shipping_preference: "NO_SHIPPING"
      }
    })
  });

  const payload = await response.json();
  if (!response.ok) {
    throw new Error(payload?.message || "Failed to create PayPal order");
  }

  const orderId = String(payload?.id || "").trim();
  const approveUrl = Array.isArray(payload?.links)
    ? String(
        payload.links.find((link: { rel?: string; href?: string }) => link.rel === "approve")?.href || ""
      ).trim()
    : "";

  if (!orderId || !approveUrl) {
    throw new Error("PayPal order response missing approve URL");
  }

  return { orderId, approveUrl };
}

router.get("/plans", (_req, res) => {
  return res.json({ plans: listPlans() });
});

router.post("/checkout", async (req, res) => {
  const authUserId = (req as AuthenticatedRequest).auth.userId;
  const { planCode } = req.body || {};
  if (!planCode) {
    return res.status(400).json({ error: "planCode is required" });
  }

  const normalizedPlanCode = String(planCode).trim().toLowerCase();
  const amountUsd = usdPriceByPlan[normalizedPlanCode];
  if (!amountUsd) {
    return res.status(400).json({ error: "Unsupported planCode for checkout" });
  }

  try {
    const frontendBase = String(req.headers.origin || process.env.DEFAULT_AUTH_REDIRECT_URI || "http://localhost:5500").replace(
      /\/+$/,
      ""
    );
    const returnUrl = `${frontendBase}/pricing.html?paypal=success&plan=${encodeURIComponent(normalizedPlanCode)}`;
    const cancelUrl = `${frontendBase}/pricing.html?paypal=cancel&plan=${encodeURIComponent(normalizedPlanCode)}`;

    const order = await createPayPalOrder({
      amountUsd,
      userId: authUserId,
      planCode: normalizedPlanCode,
      returnUrl,
      cancelUrl
    });

    return res.json({
      provider: "paypal",
      currency: "USD",
      checkoutUrl: order.approveUrl,
      orderId: order.orderId,
      trialDays: 7,
      planCode: normalizedPlanCode,
      userId: authUserId
    });
  } catch (error) {
    return res.status(500).json({ error: (error as Error).message || "Checkout failed" });
  }
});

router.post("/webhook", (_req, res) => {
  // TODO: verify PayPal webhook signature and update subscriptions in DB.
  return res.status(200).json({ ok: true });
});

export default router;
