import * as chai from 'chai'
import chaiAsPromised from 'chai-as-promised'

import {globalConfig} from '../../src/utils/global-config'

if (process.env.E2E_TEST !== 'true') globalConfig.initialize({disableOutput: true, debug: true})

chai.use(chaiAsPromised)

export const {expect} = chai
