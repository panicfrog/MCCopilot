import { NitroModules } from 'react-native-nitro-modules'
import type { MccopilotRN, Argon2Params } from './specs/MccopilotRN.nitro'

export const MccopilotRNModule =
  NitroModules.createHybridObject<MccopilotRN>('MccopilotRN')

export type { MccopilotRN, Argon2Params }
