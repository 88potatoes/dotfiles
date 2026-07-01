import js from "@eslint/js";
import tseslint from "typescript-eslint";
import promise from "eslint-plugin-promise";
import importPlugin from "eslint-plugin-import-x";
import { fileURLToPath } from "url";
import { dirname } from "path";

const __dirname = dirname(fileURLToPath(import.meta.url));

export default [
  // Global ignore
  {
    ignores: ["node_modules/", "dist/", "*.d.ts"],
  },

  // Base: ESLint recommended
  js.configs.recommended,

  // TypeScript recommended (non-type-aware)
  ...tseslint.configs.recommended.map((conf) => ({
    ...conf,
    files: ["src/**/*.ts", "tests/**/*.ts"],
  })),

  // Promise plugin
  promise.configs["flat/recommended"],

  // Custom rules — applies to src and test TypeScript files
  {
    files: ["src/**/*.ts", "tests/**/*.ts"],
    plugins: {
      "@typescript-eslint": tseslint.plugin,
      "import-x": importPlugin,
    },
    rules: {
      // ── Style / Best Practices ──
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": ["warn", { argsIgnorePattern: "^_" }],
      "no-console": "off",
      eqeqeq: ["error", "always"],
      curly: ["error", "all"],
      "no-throw-literal": "error",
      "prefer-const": "error",
      "no-var": "error",
      "object-shorthand": "error",
      "prefer-template": "warn",

      // ── Promise rules ──
      "promise/always-return": "warn",
      "promise/no-nesting": "warn",
      "promise/no-promise-in-callback": "warn",
      "promise/no-new-statics": "error",
      "promise/no-return-in-finally": "warn",
      "promise/valid-params": "warn",
      "promise/catch-or-return": ["warn", { allowFinally: true }],

      // ── TypeScript (non-type-aware) ──
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/explicit-function-return-type": "off",

      // ── Imports (no resolver-dependent rules to avoid resolver compat issues) ──
      "import-x/order": [
        "warn",
        {
          groups: ["builtin", "external", "internal", "parent", "sibling", "index"],
          "newlines-between": "always",
          alphabetize: { order: "asc" },
        },
      ],
      "import-x/no-duplicates": "error",
      "import-x/first": "error",
      "import-x/newline-after-import": "warn",
    },
  },

  // Type-aware rules — applies only to src/ TypeScript files
  {
    files: ["src/**/*.ts"],
    languageOptions: {
      parser: tseslint.parser,
      parserOptions: {
        projectService: true,
        tsconfigRootDir: __dirname,
      },
    },
    plugins: {
      "@typescript-eslint": tseslint.plugin,
    },
    rules: {
      "@typescript-eslint/no-floating-promises": "error",
      "@typescript-eslint/await-thenable": "error",
      "@typescript-eslint/no-misused-promises": "error",
      "@typescript-eslint/prefer-optional-chain": "warn",
      "@typescript-eslint/prefer-nullish-coalescing": "warn",
    },
  },

  // Override for test files
  {
    files: ["**/*.test.ts", "**/*.spec.ts", "tests/**/*.ts"],
    rules: {
      "@typescript-eslint/no-explicit-any": "off",
    },
  },
];
