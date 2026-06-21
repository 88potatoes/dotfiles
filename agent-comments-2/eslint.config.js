import antfu from '@antfu/eslint-config'
import promise from 'eslint-plugin-promise'
import security from 'eslint-plugin-security'

const additionalNodeRules = {
  'node/no-extraneous-import': 'error',
  'node/no-extraneous-require': 'error',
  'node/no-missing-import': 'error',
  'node/no-missing-require': 'error',
  'node/no-process-exit': 'warn',
  'node/no-unpublished-import': 'error',
  'node/no-unpublished-require': 'error',
  'node/no-unsupported-features/es-builtins': 'error',
  'node/no-unsupported-features/es-syntax': 'error',
  'node/no-unsupported-features/node-builtins': 'error',
  'node/hashbang': 'error',
}

export default antfu(
  {},
  promise.configs['flat/recommended'],
  {
    rules: additionalNodeRules,
  },
  security.configs.recommended,
  {
    files: ['eslint.config.js'],
    rules: {
      'node/no-unpublished-import': 'off',
    },
  },
)
