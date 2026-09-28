const nodeMatcher =
  (versionMajor) =>
  ({labels}) =>
    labels.find((label) => label.name === 'nodeVersion' && label.value.startsWith(`v${versionMajor}.`))

const environments = () =>
  Object.fromEntries([22, 24, 26].map((version) => [`node${version}`, {matcher: nodeMatcher(version)}]))

export default {
  output: 'tmp/allure-report',
  historyPath: 'tmp/history.jsonl',
  plugins: {
    awesome: {
      options: {
        enabled: true,
        singleFile: true,
      },
    },
  },
  environments: environments(),
}
