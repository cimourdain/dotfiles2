import js from "@eslint/js";
import eslintPluginPrettierRecommended from "eslint-plugin-prettier/recommended";

export default [
  js.configs.recommended,
  eslintPluginPrettierRecommended,
  {
    rules: {
      "no-unused-vars": "error",
      "no-undef": "error",
    },
    files: ["src/**/*.ts"],
    ignores: ["dist/", "node_modules/", "**/*.js"],
  },
];
