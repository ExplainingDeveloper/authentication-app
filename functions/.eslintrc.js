module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    'ecmaVersion': 2018,
  },
  extends: [
    'eslint:recommended',
    'google',
  ],
  rules: {
    'no-restricted-globals': ['error', 'name', 'length'],
    'prefer-arrow-callback': 'error',

    // 아래 세 규칙은 Firebase 기본값에서 바꾼 것들이다.
    // 기본값이 에디터 자동 포맷터(Prettier 등)와 충돌해서,
    // 파일을 저장할 때마다 lint가 깨지고 배포(predeploy)가 막히기 때문.
    // 포맷터 쪽 스타일에 맞춰두면 저장해도 lint가 통과한다.
    'quotes': ['error', 'single', { 'allowTemplateLiterals': true }],
    'object-curly-spacing': ['error', 'always'],
    'max-len': ['error', { 'code': 100 }],
  },
  overrides: [
    {
      files: ['**/*.spec.*'],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
