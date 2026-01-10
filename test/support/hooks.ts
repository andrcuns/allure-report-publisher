import * as allure from 'allure-js-commons'

export const mochaHooks = {
  async beforeEach() {
    await allure.label('nodeVersion', process.version)
  },
}
