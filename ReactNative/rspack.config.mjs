import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as Repack from '@callstack/repack';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Rspack configuration enhanced with Re.Pack defaults for React Native.
 *
 * Learn about Rspack configuration: https://rspack.dev/config/
 * Learn about Re.Pack configuration: https://re-pack.dev/docs/guides/configuration
 */

export default Repack.defineRspackConfig({
  context: __dirname,
  entry: './index.tsx',
  resolve: {
    ...Repack.getResolveOptions(),
  },
  module: {
    rules: [
      {
        test: /\.[cm]?[jt]sx?$/,
        type: 'javascript/auto',
        use: {
          loader: '@callstack/repack/babel-swc-loader',
          parallel: true,
          options: {},
        },
      },
      ...Repack.getAssetTransformRules(),
    ],
  },
  optimization: {
    splitChunks: {
      chunks: 'async',
      minSize: 0,
    },
  },
  output: {
    chunkFilename: '[name].chunk.bundle',
  },
  plugins: [
    new Repack.RepackPlugin({
      extraChunks: [
        {
          type: 'remote',
          outputPath: path.resolve(__dirname, 'build/outputs/ios/remotes'),
        },
      ],
    }),
  ],
});
