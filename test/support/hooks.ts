import {label} from 'allure-js-commons'
import {beforeEach} from 'vitest'

beforeEach(async () => {
  await label('nodeVersion', process.version)
})
