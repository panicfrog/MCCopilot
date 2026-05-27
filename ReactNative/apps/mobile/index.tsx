import React, {Suspense} from 'react';
import {AppRegistry} from 'react-native';
import ExampleRNApp from '@mccopilot/app-example';
import {setupChunkResolver} from './src/utils/chunkResolver';
import LoadingFallback from './src/components/LoadingFallback';

// Polyfill: Hermes production mode doesn't include setImmediate
if (typeof globalThis.setImmediate === 'undefined') {
  (globalThis as any).setImmediate = (
    fn: (...args: any[]) => void,
    ...args: any[]
  ) => setTimeout(fn, 0, ...args);
  (globalThis as any).clearImmediate = (id: ReturnType<typeof setTimeout>) =>
    clearTimeout(id);
}

// Lazy load SecondRNApp as a remote chunk
const SecondRNApp = React.lazy(
  () => import(/* webpackChunkName: "SecondRNApp" */ '@mccopilot/app-second'),
);

// Initialize chunk resolver before registering components
setupChunkResolver();

// Wrap SecondRNApp with Suspense
const SecondRNAppWrapper: React.FC = () => (
  <Suspense fallback={<LoadingFallback />}>
    <SecondRNApp />
  </Suspense>
);

// Register React Native app modules
AppRegistry.registerComponent('ExampleRNApp', () => ExampleRNApp);
AppRegistry.registerComponent('SecondRNApp', () => SecondRNAppWrapper);
