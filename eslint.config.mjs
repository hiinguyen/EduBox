import nextCoreWebVitals from "eslint-config-next/core-web-vitals";
import nextTypescript from "eslint-config-next/typescript";

const config = [
  { ignores: [".next/**", "src/generated/**", "node_modules/**", "design/**"] },
  ...nextCoreWebVitals,
  ...nextTypescript,
];

export default config;
