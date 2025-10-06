import love from "eslint-config-love";

function convertAllRulesToWarnings(rules) {
   return Object.fromEntries(
      Object.entries(rules || {}).map(([ruleName, ruleValue]) => {
         if (Array.isArray(ruleValue)) {
            ruleValue[0] = "warn";
            return [ruleName, ruleValue];
         }
         return [ruleName, "warn"];
      })
   );
}

export default [
   {
      ...love,
      files: ["**/*.js", "**/*.ts"],

      rules: {
         ...convertAllRulesToWarnings(love.rules),
         "@typescript-eslint/consistent-type-imports": "off",
      },
   },
];
