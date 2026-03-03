const queryParams = new URLSearchParams(window.location.search);
const apiBaseFromQuery = (queryParams.get("apiBase") || "").trim();
if (apiBaseFromQuery) {
  localStorage.setItem("codemate_api_base", apiBaseFromQuery);
}

const API_BASE = (
  localStorage.getItem("codemate_api_base") ||
  (typeof window.CODEMATE_API_BASE === "string" ? window.CODEMATE_API_BASE : "") ||
  "http://localhost:8080"
).replace(/\/+$/, "");

const catalog = {
  starter: {
    monthly: {
      code: "starter_monthly",
      title: "Starter Monthly",
      price: "$39",
      inrPrice: "INR 3,299",
      features: [
        "2 users per session",
        "3 sessions per day",
        "50 min per session",
        "Built for students and solo coders"
      ]
    },
    yearly: {
      code: "starter_yearly",
      title: "Starter Yearly",
      price: "$299",
      inrPrice: "INR 24,999",
      features: [
        "2 users per session",
        "3 sessions per day",
        "50 min per session",
        "Best value for individual creators"
      ]
    }
  },
  pro: {
    monthly: {
      code: "pro_monthly",
      title: "Pro Monthly",
      price: "$149",
      inrPrice: "INR 12,499",
      features: [
        "5 users per session",
        "10 sessions per day",
        "100 min per session",
        "Session recording, analytics, and custom branding"
      ]
    },
    yearly: {
      code: "pro_yearly",
      title: "Pro Yearly",
      price: "$1,199",
      inrPrice: "INR 99,999",
      features: [
        "5 users per session",
        "10 sessions per day",
        "100 min per session",
        "Session recording, analytics, and custom branding"
      ]
    }
  },
  team: {
    monthly: {
      code: "team_monthly",
      title: "Team Monthly",
      price: "$499",
      inrPrice: "INR 41,999",
      features: [
        "20 users per session",
        "Unlimited sessions",
        "Unlimited hours",
        "Priority compute + admin dashboard + white-label option"
      ]
    },
    yearly: {
      code: "team_yearly",
      title: "Team Yearly",
      price: "$4,999",
      inrPrice: "INR 4,14,999",
      features: [
        "20 users per session",
        "Unlimited sessions",
        "Unlimited hours",
        "Priority compute + admin dashboard + white-label option"
      ]
    }
  },
  founder_lifetime: {
    code: "founder_lifetime",
    title: "Founder Lifetime",
    price: "$999",
    inrPrice: "INR 82,999"
  }
};

function storeAuthFromUrlIfPresent() {
  const params = new URLSearchParams(window.location.search);
  const token = params.get("token");
  const userId = params.get("user_id");
  const githubUsername = params.get("github_username");

  if (!token || !userId || !githubUsername) return;

  localStorage.setItem("pairpulse_auth", JSON.stringify({ token, userId, githubUsername }));
  window.history.replaceState({}, "", `${window.location.origin}${window.location.pathname}`);
}

function getAuth() {
  const raw = localStorage.getItem("pairpulse_auth");
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function startGitHubAuth() {
  const redirectUri = `${window.location.origin}${window.location.pathname}`;
  window.location.href = `${API_BASE}/auth/github/start?redirect_uri=${encodeURIComponent(redirectUri)}`;
}

let selectedTier = "starter";
let selectedCycle = "monthly";

const planTitleNode = document.querySelector("#planTitle");
const planPriceNode = document.querySelector("#planPrice");
const planLocalPriceNode = document.querySelector("#planLocalPrice");
const planFeaturesNode = document.querySelector("#planFeatures");
const authStatusNode = document.querySelector("#authStatus");
const checkoutNoteNode = document.querySelector("#checkoutNote");

function updateTierButtons() {
  document.querySelector("#starterTab").classList.toggle("active", selectedTier === "starter");
  document.querySelector("#proTab").classList.toggle("active", selectedTier === "pro");
  document.querySelector("#teamTab").classList.toggle("active", selectedTier === "team");
}

function renderPlan() {
  const plan = catalog[selectedTier][selectedCycle];
  planTitleNode.textContent = plan.title;
  planPriceNode.textContent = plan.price;
  planLocalPriceNode.textContent = plan.inrPrice;
  planFeaturesNode.innerHTML = plan.features.map((item) => `<li>${item}</li>`).join("");
}

async function startCheckout(plan) {
  const auth = getAuth();
  if (!auth?.userId) {
    alert("Login first.");
    return;
  }
  try {
    const headers = new Headers({ "Content-Type": "application/json" });
    if (auth?.token) {
      headers.set("Authorization", `Bearer ${auth.token}`);
    }
    const response = await fetch(`${API_BASE}/billing/checkout`, {
      method: "POST",
      headers,
      body: JSON.stringify({ planCode: plan.code, provider: "paypal" })
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Could not start checkout");

    checkoutNoteNode.textContent = "Trial started. Redirecting to PayPal checkout...";
    if (typeof data.checkoutUrl === "string" && data.checkoutUrl.startsWith("http")) {
      window.location.href = data.checkoutUrl;
      return;
    }
    alert("Trial activated. PayPal checkout will be configured in backend.");
  } catch (error) {
    checkoutNoteNode.textContent = `Checkout could not start: ${error.message || "Unknown error"}`;
  }
}

storeAuthFromUrlIfPresent();
const auth = getAuth();
authStatusNode.textContent = auth?.githubUsername ? `Signed in as @${auth.githubUsername}` : "Not signed in";

updateTierButtons();
renderPlan();

document.querySelector("#loginBtn").addEventListener("click", startGitHubAuth);

document.querySelector("#proTab").addEventListener("click", () => {
  selectedTier = "pro";
  updateTierButtons();
  renderPlan();
});

document.querySelector("#starterTab").addEventListener("click", () => {
  selectedTier = "starter";
  updateTierButtons();
  renderPlan();
});

document.querySelector("#teamTab").addEventListener("click", () => {
  selectedTier = "team";
  updateTierButtons();
  renderPlan();
});

document.querySelectorAll('input[name="billing"]').forEach((input) => {
  input.addEventListener("change", (event) => {
    const target = event.target;
    if (!(target instanceof HTMLInputElement)) return;
    selectedCycle = target.value;
    renderPlan();
  });
});

document.querySelector("#checkoutBtn").addEventListener("click", () => {
  const plan = catalog[selectedTier][selectedCycle];
  startCheckout(plan).catch((error) => {
    alert(error.message || "Checkout failed");
  });
});

document.querySelector("#lifetimeCheckoutBtn").addEventListener("click", () => {
  startCheckout(catalog.founder_lifetime).catch((error) => {
    alert(error.message || "Checkout failed");
  });
});
