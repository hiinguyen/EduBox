import type { NextConfig } from "next";

const isDevelopment = process.env.NODE_ENV !== "production";

// 'unsafe-inline' for scripts/styles is required by Next's inline bootstrap and Tailwind
// without per-request nonces; 'unsafe-eval' is development only (React debugging, HMR).
const CONTENT_SECURITY_POLICY = [
  "default-src 'self'",
  `script-src 'self' 'unsafe-inline'${isDevelopment ? " 'unsafe-eval'" : ""}`,
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob:",
  "font-src 'self' data:",
  `connect-src 'self'${isDevelopment ? " ws: wss:" : ""}`,
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
].join("; ");

const TWO_YEARS_SECONDS = 63_072_000;

const SECURITY_HEADERS = [
  ...(isDevelopment
    ? []
    : [
        {
          key: "Strict-Transport-Security",
          value: `max-age=${TWO_YEARS_SECONDS}; includeSubDomains`,
        },
      ]),
  { key: "Content-Security-Policy", value: CONTENT_SECURITY_POLICY },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
];

const nextConfig: NextConfig = {
  reactStrictMode: true,
  serverExternalPackages: ["pg", "@node-rs/argon2"],
  async headers() {
    return [{ source: "/:path*", headers: SECURITY_HEADERS }];
  },
};

export default nextConfig;
